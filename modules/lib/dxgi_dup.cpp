// dxgi_dup.cpp - build as x64 DLL
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <atomic>
#include <vector>
#include <string>
#include <cstdio>
#include <algorithm>  // (std::min)/(std::max)

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

// ================= 原生日志（写到 %TEMP%\dxgi_dup_native.log） =================
static std::wstring LogFilePath() {
    wchar_t tmp[MAX_PATH], fn[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    swprintf(fn, MAX_PATH, L"%s\\dxgi_dup_native.log", tmp);
    return fn;
}
static void Logf(const wchar_t* fmt, ...) {
    wchar_t buffer[768];
    va_list ap; va_start(ap, fmt);
    _vsnwprintf_s(buffer, _countof(buffer), _TRUNCATE, fmt, ap);
    va_end(ap);
    auto path = LogFilePath();
    HANDLE h = CreateFileW(path.c_str(), FILE_APPEND_DATA, FILE_SHARE_READ, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h != INVALID_HANDLE_VALUE) {
        SYSTEMTIME st; GetLocalTime(&st);
        wchar_t line[1024];
        swprintf(line, _countof(line), L"%04u-%02u-%02u %02u:%02u:%02u.%03u %s\r\n",
                 st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, buffer);
        DWORD bytes = 0;
        WriteFile(h, line, (DWORD)(wcslen(line) * sizeof(wchar_t)), &bytes, nullptr);
        CloseHandle(h);
    }
}
static void LogHr(const wchar_t* where, HRESULT hr) {
    Logf(L"%s hr=0x%08X", where, (unsigned)hr);
}

// ================= 全局状态 =================
struct DupState {
    // D3D/DXGI
    ID3D11Device*           dev   = nullptr;
    ID3D11DeviceContext*    ctx   = nullptr;
    IDXGIOutputDuplication* dup   = nullptr;
    ID3D11Texture2D*        staging = nullptr;

    // 帧缓冲（BGRA8，顶向下）
    UINT                    w = 0, h = 0, stride = 0;
    std::vector<BYTE>       buf;
    std::atomic<UINT>       frameId{ 0 };

    // 线程
    HANDLE                  th = nullptr;
    HANDLE                  stopEvt = nullptr;
    int                     fps = 60;

    // 当前选择（“全局输出索引” -> 适配器/适配器内输出）
    int                     globalOut = 0;
    int                     adpIndex   = -1;
    int                     outInAdp   = -1;

    // 错误记录
    HRESULT                 lastHr = S_OK;
    std::wstring            lastMsg;

    // 同步
    CRITICAL_SECTION        cs;
    bool                    csInit = false;
} g;

static void SafeRelease(IUnknown* p) { if (p) p->Release(); }

static void SetLastHR(HRESULT hr, const wchar_t* where) {
    g.lastHr = hr;
    wchar_t buf[256];
    swprintf(buf, 256, L"%s hr=0x%08X", where, (unsigned)hr);
    g.lastMsg = buf;
    LogHr(where, hr);
}

// ================= DXGI 跨适配器枚举 =================
struct OutputPair { UINT adp; UINT out; DXGI_OUTPUT_DESC desc; };

static bool BuildAllOutputs(std::vector<OutputPair>& outs) {
    outs.clear();
    Logf(L"BuildAllOutputs: begin");
    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    LogHr(L"CreateDXGIFactory1", hr);
    if (FAILED(hr) || !fac) return false;

    for (UINT ai = 0; ; ++ai) {
        IDXGIAdapter1* adp = nullptr;
        hr = fac->EnumAdapters1(ai, &adp);
        if (hr == DXGI_ERROR_NOT_FOUND) break;
        if (!adp) continue;

        DXGI_ADAPTER_DESC1 ad{};
        adp->GetDesc1(&ad);
        Logf(L"Adapter[%u] Desc=%s Flags=0x%X", ai, ad.Description, ad.Flags);

        for (UINT oi = 0; ; ++oi) {
            IDXGIOutput* out = nullptr;
            hr = adp->EnumOutputs(oi, &out);
            if (hr == DXGI_ERROR_NOT_FOUND) break;
            if (!out) continue;
            DXGI_OUTPUT_DESC d{};
            if (SUCCEEDED(out->GetDesc(&d))) {
                Logf(L"  Output[%u] Name=%s HMONITOR=0x%p Attached=%d",
                     oi, d.DeviceName, d.Monitor, d.AttachedToDesktop);
                OutputPair p; p.adp = ai; p.out = oi; p.desc = d;
                outs.push_back(p);
            }
            out->Release();
        }
        adp->Release();
    }
    fac->Release();

    if (outs.empty()) {
        Logf(L"BuildAllOutputs returns empty. Try GDI EnumDisplayMonitors:");
        int monCount = 0;
        EnumDisplayMonitors(nullptr, nullptr,
            [](HMONITOR, HDC, LPRECT, LPARAM p)->BOOL { *(int*)p += 1; return TRUE; }, (LPARAM)&monCount);
        Logf(L"GDI monitors: %d", monCount);
    }
    Logf(L"BuildAllOutputs: total=%zu", outs.size());
    return true;
}

static int CountAllOutputs() {
    std::vector<OutputPair> v;
    if (!BuildAllOutputs(v)) return 0;
    return (int)v.size();
}

static bool ResolveGlobalIndex(int globalIdx, UINT& adpIdx, UINT& outIdx, DXGI_OUTPUT_DESC* descOut = nullptr) {
    std::vector<OutputPair> v;
    if (!BuildAllOutputs(v) || v.empty()) return false;
    if (globalIdx < 0 || (size_t)globalIdx >= v.size()) globalIdx = 0;
    adpIdx = v[globalIdx].adp;
    outIdx = v[globalIdx].out;
    if (descOut) *descOut = v[globalIdx].desc;
    Logf(L"ResolveGlobalIndex: global=%d -> adp=%u out=%u name=%s",
         globalIdx, adpIdx, outIdx, v[globalIdx].desc.DeviceName);
    return true;
}

static bool GetOutputNameByGlobal(int globalIdx, std::wstring& name) {
    UINT ai=0, oi=0; DXGI_OUTPUT_DESC d{};
    if (!ResolveGlobalIndex(globalIdx, ai, oi, &d)) return false;
    name = d.DeviceName; // \\.\DISPLAY1
    return true;
}

// ================= 设备/duplication 构建 =================
static HRESULT CreateDeviceOnAdapter(UINT adpIndex, ID3D11Device** outDev, ID3D11DeviceContext** outCtx) {
    *outDev = nullptr; *outCtx = nullptr;

    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    LogHr(L"CreateDXGIFactory1(for device)", hr);
    if (FAILED(hr) || !fac) { SetLastHR(hr, L"CreateDXGIFactory1(device)"); return hr; }

    IDXGIAdapter1* adp = nullptr;
    hr = fac->EnumAdapters1(adpIndex, &adp);
    fac->Release();
    LogHr(L"EnumAdapters1(device)", hr);
    if (FAILED(hr) || !adp) { SetLastHR(hr, L"EnumAdapters1(device)"); return hr; }

    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
#if defined(_DEBUG)
    // flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    D3D_FEATURE_LEVEL fls[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    // 指定适配器创建设备（D3D_DRIVER_TYPE_UNKNOWN）
    hr = D3D11CreateDevice(adp, D3D_DRIVER_TYPE_UNKNOWN, nullptr, flags, fls, ARRAYSIZE(fls),
                           D3D11_SDK_VERSION, outDev, nullptr, outCtx);
    LogHr(L"D3D11CreateDevice(adp)", hr);
    adp->Release();
    if (FAILED(hr)) SetLastHR(hr, L"D3D11CreateDevice(adp)");
    return hr;
}

static HRESULT RecreateDuplicationOnPair(UINT adpIndex, UINT outIndex) {
    SafeRelease(g.dup);

    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    LogHr(L"CreateDXGIFactory1(redup)", hr);
    if (FAILED(hr) || !fac) { SetLastHR(hr, L"CreateDXGIFactory1(redup)"); return hr; }

    IDXGIAdapter1* adp = nullptr;
    hr = fac->EnumAdapters1(adpIndex, &adp);
    fac->Release();
    LogHr(L"EnumAdapters1(redup)", hr);
    if (FAILED(hr) || !adp) { SetLastHR(hr, L"EnumAdapters1(redup)"); return hr; }

    IDXGIOutput* out = nullptr;
    hr = adp->EnumOutputs(outIndex, &out);
    LogHr(L"EnumOutputs(redup)", hr);
    if (FAILED(hr) || !out) { SetLastHR(hr, L"EnumOutputs(redup)"); adp->Release(); return hr; }

    IDXGIOutput1* out1 = nullptr;
    hr = out->QueryInterface(__uuidof(IDXGIOutput1), (void**)&out1);
    LogHr(L"QI IDXGIOutput1(redup)", hr);
    if (FAILED(hr) || !out1) { SetLastHR(hr, L"QI IDXGIOutput1(redup)"); out->Release(); adp->Release(); return hr; }

    hr = out1->DuplicateOutput(g.dev, &g.dup);
    LogHr(L"DuplicateOutput", hr);
    if (FAILED(hr)) SetLastHR(hr, L"DuplicateOutput");

    out1->Release();
    out->Release();
    adp->Release();
    return hr;
}

static HRESULT EnsureStaging(UINT w, UINT h) {
    if (g.staging) {
        D3D11_TEXTURE2D_DESC d{};
        g.staging->GetDesc(&d);
        if (d.Width == w && d.Height == h) return S_OK;
        SafeRelease(g.staging);
    }
    D3D11_TEXTURE2D_DESC td = {};
    td.Width = w; td.Height = h;
    td.MipLevels = 1; td.ArraySize = 1;
    td.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    td.SampleDesc.Count = 1;
    td.Usage = D3D11_USAGE_STAGING;
    td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    HRESULT hr = g.dev->CreateTexture2D(&td, nullptr, &g.staging);
    LogHr(L"CreateTexture2D(staging)", hr);
    if (FAILED(hr)) SetLastHR(hr, L"CreateTexture2D(staging)");
    return hr;
}

static DWORD WINAPI CaptureThread(LPVOID) {
    const int base = (std::max)(1, 1000 / (std::max)(1, g.fps));
    Logf(L"CaptureThread start: interval=%dms", base);
    for (;;) {
        if (WaitForSingleObject(g.stopEvt, 0) == WAIT_OBJECT_0) break;

        if (!g.dup) {
            if (FAILED(RecreateDuplicationOnPair((UINT)g.adpIndex, (UINT)g.outInAdp))) { Sleep(200); continue; }
        }

        IDXGIResource* res = nullptr;
        DXGI_OUTDUPL_FRAME_INFO info{};
        HRESULT hr = g.dup->AcquireNextFrame(base, &info, &res);
        if (hr == DXGI_ERROR_WAIT_TIMEOUT) continue;
        if (hr == DXGI_ERROR_ACCESS_LOST || hr == DXGI_ERROR_INVALID_CALL || hr == DXGI_ERROR_DEVICE_REMOVED) {
            SetLastHR(hr, L"AcquireNextFrame(lost)");
            LogHr(L"AcquireNextFrame lost", hr);
            SafeRelease(g.dup);
            continue;
        }
        if (FAILED(hr)) {
            SetLastHR(hr, L"AcquireNextFrame");
            LogHr(L"AcquireNextFrame failed", hr);
            Sleep(50);
            continue;
        }

        ID3D11Texture2D* tex = nullptr;
        res->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&tex);
        res->Release();

        if (tex) {
            D3D11_TEXTURE2D_DESC td{};
            tex->GetDesc(&td);
            UINT w = td.Width, h = td.Height, stride = w * 4;

            if (FAILED(EnsureStaging(w, h))) {
                tex->Release();
                g.dup->ReleaseFrame();
                Sleep(50);
                continue;
            }

            g.ctx->CopyResource(g.staging, tex);
            tex->Release();

            D3D11_MAPPED_SUBRESOURCE m{};
            hr = g.ctx->Map(g.staging, 0, D3D11_MAP_READ, 0, &m);
            if (SUCCEEDED(hr)) {
                EnterCriticalSection(&g.cs);
                g.w = w; g.h = h; g.stride = stride;
                g.buf.resize((size_t)h * stride);
                const BYTE* src = reinterpret_cast<const BYTE*>(m.pData);
                const UINT srcPitch = m.RowPitch;
                const UINT copy = (std::min)(srcPitch, stride);
                BYTE* dst = g.buf.data();
                for (UINT y = 0; y < h; ++y) {
                    memcpy(dst + (size_t)y * stride, src + (size_t)y * srcPitch, copy);
                }
                g.frameId.fetch_add(1, std::memory_order_relaxed);
                LeaveCriticalSection(&g.cs);
                g.ctx->Unmap(g.staging, 0);
            } else {
                SetLastHR(hr, L"Map(staging)");
                LogHr(L"Map(staging) failed", hr);
            }
        }

        g.dup->ReleaseFrame();
    }
    Logf(L"CaptureThread exit");
    return 0;
}

// ================= C 导出（保持你的签名不变） =================
// 前置声明
extern "C" __declspec(dllexport) void WINAPI DupShutdown();

extern "C" __declspec(dllexport) int WINAPI DupInit(int outputIndex, int fps) {
    Logf(L"DupInit request: globalOut=%d fps=%d", outputIndex, fps);
    DupShutdown(); // cleanup previous

    // 初始化 CS
    InitializeCriticalSection(&g.cs);
    g.csInit = true;

    g.fps = fps > 0 ? fps : 60;
    g.lastHr = S_OK; g.lastMsg.clear();

    // 解析“全局输出索引” -> 适配器/适配器内输出
    UINT ai = 0, oi = 0; DXGI_OUTPUT_DESC d{};
    if (!ResolveGlobalIndex(outputIndex, ai, oi, &d)) {
        g.globalOut = 0; g.adpIndex = -1; g.outInAdp = -1;
        SetLastHR(DXGI_ERROR_NOT_CURRENTLY_AVAILABLE, L"No outputs enumerated");
        Logf(L"DupInit fail: ResolveGlobalIndex -> no outputs.");
        if (g.csInit) { DeleteCriticalSection(&g.cs); g.csInit = false; }
        return 0;
    }
    g.globalOut = outputIndex;
    g.adpIndex = (int)ai;
    g.outInAdp = (int)oi;
    Logf(L"Resolve -> Adapter=%u OutputInAdapter=%u Name=%s", ai, oi, d.DeviceName);

    // 在该适配器上创建设备
    HRESULT hr = CreateDeviceOnAdapter(ai, &g.dev, &g.ctx);
    if (FAILED(hr)) {
        DupShutdown();
        return 0;
    }

    // 在该输出上建立 duplication
    if (FAILED(RecreateDuplicationOnPair(ai, oi))) {
        DupShutdown();
        return 0;
    }

    g.stopEvt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g.th = CreateThread(nullptr, 0, CaptureThread, nullptr, 0, nullptr);
    if (!g.th) {
        DupShutdown();
        return 0;
    }
    Logf(L"DupInit OK");
    return 1;
}

extern "C" __declspec(dllexport) void WINAPI DupShutdown() {
    Logf(L"DupShutdown");
    if (g.th) {
        SetEvent(g.stopEvt);
        WaitForSingleObject(g.th, 3000);
        CloseHandle(g.th); g.th = nullptr;
    }
    if (g.stopEvt) { CloseHandle(g.stopEvt); g.stopEvt = nullptr; }
    SafeRelease(g.staging);
    SafeRelease(g.dup);
    SafeRelease(g.ctx);
    SafeRelease(g.dev);

    if (g.csInit) {
        EnterCriticalSection(&g.cs);
        g.buf.clear(); g.w = g.h = g.stride = 0; g.frameId = 0;
        LeaveCriticalSection(&g.cs);
        DeleteCriticalSection(&g.cs);
        g.csInit = false;
    } else {
        g.buf.clear(); g.w = g.h = g.stride = 0; g.frameId = 0;
    }
}

extern "C" __declspec(dllexport) int WINAPI DupIsReady() {
    return (g.dup && g.w && g.h && !g.buf.empty()) ? 1 : 0;
}

extern "C" __declspec(dllexport) void WINAPI DupGetSize(int* w, int* h, int* stride) {
    if (!g.csInit) { if (w)*w=0; if (h)*h=0; if (stride)*stride=0; return; }
    EnterCriticalSection(&g.cs);
    if (w) *w = (int)g.w;
    if (h) *h = (int)g.h;
    if (stride) *stride = (int)g.stride;
    LeaveCriticalSection(&g.cs);
}

extern "C" __declspec(dllexport) unsigned int WINAPI DupGetPixel(int x, int y) {
    if (!g.csInit) return 0;
    EnterCriticalSection(&g.cs);
    unsigned int rgb = 0;
    if (x >= 0 && y >= 0 && (UINT)x < g.w && (UINT)y < g.h && !g.buf.empty()) {
        size_t off = (size_t)y * g.stride + (size_t)x * 4;
        BYTE b = g.buf[off + 0];
        BYTE g8 = g.buf[off + 1];
        BYTE r = g.buf[off + 2];
        rgb = (r << 16) | (g8 << 8) | b;
    }
    LeaveCriticalSection(&g.cs);
    return rgb;
}

extern "C" __declspec(dllexport) unsigned int WINAPI DupGetFrameId() {
    return g.frameId.load(std::memory_order_relaxed);
}

extern "C" __declspec(dllexport) int WINAPI DupCopyFrameBGRA(void* dest, int destStride, int destBytes) {
    if (!dest || destStride <= 0 || destBytes <= 0 || !g.csInit) return 0;
    EnterCriticalSection(&g.cs);
    int copied = 0;
    if (g.w && g.h && !g.buf.empty()) {
        BYTE* out = (BYTE*)dest;
        const BYTE* src = g.buf.data();
        int rowCopy = (std::min)((int)g.stride, destStride);
        int need = (int)g.h * destStride;
        if (destBytes >= need) {
            for (UINT y = 0; y < g.h; ++y) {
                memcpy(out + (size_t)y * destStride, src + (size_t)y * g.stride, rowCopy);
            }
            copied = (int)g.h * destStride;
        }
    }
    LeaveCriticalSection(&g.cs);
    return copied; // bytes copied or 0
}

// 返回 1 成功；指针仅在解锁前有效；锁持有期间采集线程将阻塞在 CS
extern "C" __declspec(dllexport) int WINAPI DupLockFrame(void** outPtr, int* stride, int* w, int* h) {
    if (!outPtr || !g.csInit) return 0;
    EnterCriticalSection(&g.cs);
    if (g.w && g.h && !g.buf.empty()) {
        *outPtr = (void*)g.buf.data();
        if (stride) *stride = (int)g.stride;
        if (w) *w = (int)g.w;
        if (h) *h = (int)g.h;
        return 1;
    } else {
        LeaveCriticalSection(&g.cs);
        return 0;
    }
}

extern "C" __declspec(dllexport) void WINAPI DupUnlockFrame() {
    if (!g.csInit) return;
    LeaveCriticalSection(&g.cs);
}

extern "C" __declspec(dllexport) int WINAPI DupEnumOutputs() {
    int cnt = CountAllOutputs();
    Logf(L"DupEnumOutputs -> %d", cnt);
    return cnt;
}

extern "C" __declspec(dllexport) int WINAPI DupGetOutputName(int idx, wchar_t* buf, int bufChars) {
    if (!buf || bufChars <= 0) return 0;
    std::wstring name;
    if (!GetOutputNameByGlobal(idx, name)) return 0;
    wcsncpy_s(buf, bufChars, name.c_str(), _TRUNCATE);
    return 1;
}

extern "C" __declspec(dllexport) int WINAPI DupSelectOutput(int idx) {
    Logf(L"DupSelectOutput request: %d", idx);
    // 解析新索引 -> 适配器/输出
    UINT ai=0, oi=0;
    if (!ResolveGlobalIndex(idx, ai, oi, nullptr)) {
        SetLastHR(DXGI_ERROR_INVALID_CALL, L"DupSelectOutput(resolve)");
        return 0;
    }
    // 停线程+释放
    if (g.th) {
        SetEvent(g.stopEvt);
        WaitForSingleObject(g.th, 2000);
        CloseHandle(g.th); g.th = nullptr;
    }
    if (g.stopEvt) { CloseHandle(g.stopEvt); g.stopEvt = nullptr; }
    SafeRelease(g.staging);
    SafeRelease(g.dup);
    SafeRelease(g.ctx);
    SafeRelease(g.dev);

    g.globalOut = idx;
    g.adpIndex = (int)ai;
    g.outInAdp = (int)oi;

    HRESULT hr = CreateDeviceOnAdapter(ai, &g.dev, &g.ctx);
    if (FAILED(hr)) { LogHr(L"CreateDeviceOnAdapter(select) fail", hr); return 0; }
    hr = RecreateDuplicationOnPair(ai, oi);
    if (FAILED(hr)) { LogHr(L"RecreateDuplicationOnPair(select) fail", hr); SafeRelease(g.ctx); SafeRelease(g.dev); return 0; }

    g.stopEvt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g.th = CreateThread(nullptr, 0, CaptureThread, nullptr, 0, nullptr);
    Logf(L"DupSelectOutput OK -> adp=%u out=%u", ai, oi);
    return g.th ? 1 : 0;
}

extern "C" __declspec(dllexport) void WINAPI DupSetFPS(int fps) {
    g.fps = fps > 0 ? fps : 60;
    Logf(L"DupSetFPS -> %d", g.fps);
}

extern "C" __declspec(dllexport) int WINAPI DupGetLastErrorCode() {
    return (int)g.lastHr;
}

extern "C" __declspec(dllexport) int WINAPI DupGetLastErrorText(wchar_t* buf, int bufChars) {
    if (!buf || bufChars <= 0) return 0;
    if (g.lastMsg.empty()) { buf[0] = 0; return 1; }
    wcsncpy_s(buf, bufChars, g.lastMsg.c_str(), _TRUNCATE);
    return 1;
}