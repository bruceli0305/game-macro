// dxgi_dup.cpp - build as x64 DLL (MSVC)
// Key fix: use _beginthreadex instead of CreateThread to safely use CRT in threads.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <objbase.h>
#include <process.h>    // _beginthreadex
#include <d3d11.h>
#include <dxgi1_2.h>
#include <atomic>
#include <vector>
#include <string>
#include <algorithm>
#include <cstdarg>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "ole32.lib")

// ================= native log (%TEMP%\dxgi_dup_native.log) =================
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
        swprintf(line, _countof(line),
            L"%04u-%02u-%02u %02u:%02u:%02u.%03u %s\r\n",
            st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, buffer);
        DWORD bytes = 0;
        WriteFile(h, line, (DWORD)(wcslen(line) * sizeof(wchar_t)), &bytes, nullptr);
        CloseHandle(h);
    }
}

static void LogHr(const wchar_t* where, HRESULT hr) {
    Logf(L"%s hr=0x%08X", where, (unsigned)hr);
}

template <typename T>
static void SafeRelease(T*& p) { if (p) { p->Release(); p = nullptr; } }

// ================= Global DXGI lock (avoid concurrent DXGI factory/enums) =================
static INIT_ONCE gDxgiInitOnce = INIT_ONCE_STATIC_INIT;
static CRITICAL_SECTION gDxgiCs;

static BOOL CALLBACK InitDxgiCsOnce(PINIT_ONCE, PVOID, PVOID*) {
    InitializeCriticalSection(&gDxgiCs);
    return TRUE;
}

static void DxgiLock() {
    InitOnceExecuteOnce(&gDxgiInitOnce, InitDxgiCsOnce, nullptr, nullptr);
    EnterCriticalSection(&gDxgiCs);
}

static void DxgiUnlock() {
    LeaveCriticalSection(&gDxgiCs);
}

// ================= DXGI cross-adapter outputs enumeration =================
struct OutputPair { UINT adp; UINT out; DXGI_OUTPUT_DESC desc; };

static bool BuildAllOutputs(std::vector<OutputPair>& outs) {
    outs.clear();
    Logf(L"BuildAllOutputs: begin");

    DxgiLock();
    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    DxgiUnlock();

    LogHr(L"CreateDXGIFactory1", hr);
    if (FAILED(hr) || !fac) return false;

    DxgiLock();
    for (UINT ai = 0;; ++ai) {
        IDXGIAdapter1* adp = nullptr;
        hr = fac->EnumAdapters1(ai, &adp);
        if (hr == DXGI_ERROR_NOT_FOUND) break;
        if (!adp) continue;

        DXGI_ADAPTER_DESC1 ad{};
        adp->GetDesc1(&ad);
        Logf(L"Adapter[%u] Desc=%s Flags=0x%X", ai, ad.Description, ad.Flags);

        for (UINT oi = 0;; ++oi) {
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
    DxgiUnlock();

    fac->Release();
    Logf(L"BuildAllOutputs: total=%zu", outs.size());
    return !outs.empty();
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
    UINT ai = 0, oi = 0; DXGI_OUTPUT_DESC d{};
    if (!ResolveGlobalIndex(globalIdx, ai, oi, &d)) return false;
    name = d.DeviceName; // \\.\DISPLAY1
    return true;
}

// ================= Device + Duplication build =================
static HRESULT CreateDeviceOnAdapter(UINT adpIndex, ID3D11Device** outDev, ID3D11DeviceContext** outCtx) {
    *outDev = nullptr; *outCtx = nullptr;

    DxgiLock();
    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    DxgiUnlock();

    LogHr(L"CreateDXGIFactory1(for device)", hr);
    if (FAILED(hr) || !fac) return hr;

    DxgiLock();
    IDXGIAdapter1* adp = nullptr;
    hr = fac->EnumAdapters1(adpIndex, &adp);
    DxgiUnlock();

    fac->Release();
    LogHr(L"EnumAdapters1(device)", hr);
    if (FAILED(hr) || !adp) { SafeRelease(adp); return hr; }

    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    D3D_FEATURE_LEVEL fls[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };

    DxgiLock();
    hr = D3D11CreateDevice(adp, D3D_DRIVER_TYPE_UNKNOWN, nullptr, flags,
        fls, ARRAYSIZE(fls), D3D11_SDK_VERSION, outDev, nullptr, outCtx);
    DxgiUnlock();

    LogHr(L"D3D11CreateDevice(adp)", hr);
    adp->Release();
    return hr;
}

static HRESULT CreateDuplication(UINT adpIndex, UINT outIndex, ID3D11Device* dev, IDXGIOutputDuplication** outDup) {
    *outDup = nullptr;

    DxgiLock();
    IDXGIFactory1* fac = nullptr;
    HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac);
    DxgiUnlock();

    LogHr(L"CreateDXGIFactory1(redup)", hr);
    if (FAILED(hr) || !fac) return hr;

    DxgiLock();
    IDXGIAdapter1* adp = nullptr;
    hr = fac->EnumAdapters1(adpIndex, &adp);
    DxgiUnlock();

    fac->Release();
    LogHr(L"EnumAdapters1(redup)", hr);
    if (FAILED(hr) || !adp) { SafeRelease(adp); return hr; }

    DxgiLock();
    IDXGIOutput* out = nullptr;
    hr = adp->EnumOutputs(outIndex, &out);
    DxgiUnlock();

    LogHr(L"EnumOutputs(redup)", hr);
    if (FAILED(hr) || !out) { adp->Release(); SafeRelease(out); return hr; }

    IDXGIOutput1* out1 = nullptr;
    hr = out->QueryInterface(__uuidof(IDXGIOutput1), (void**)&out1);
    LogHr(L"QI IDXGIOutput1(redup)", hr);
    if (FAILED(hr) || !out1) { out->Release(); adp->Release(); SafeRelease(out1); return hr; }

    DxgiLock();
    hr = out1->DuplicateOutput(dev, outDup);
    DxgiUnlock();

    LogHr(L"DuplicateOutput", hr);

    out1->Release();
    out->Release();
    adp->Release();
    return hr;
}

static HRESULT EnsureStaging(ID3D11Device* dev, ID3D11Texture2D** ioStaging, UINT w, UINT h) {
    if (*ioStaging) {
        D3D11_TEXTURE2D_DESC d{};
        (*ioStaging)->GetDesc(&d);
        if (d.Width == w && d.Height == h) return S_OK;
        SafeRelease(*ioStaging);
    }

    D3D11_TEXTURE2D_DESC td{};
    td.Width = w; td.Height = h;
    td.MipLevels = 1; td.ArraySize = 1;
    td.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    td.SampleDesc.Count = 1;
    td.Usage = D3D11_USAGE_STAGING;
    td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;

    HRESULT hr = dev->CreateTexture2D(&td, nullptr, ioStaging);
    LogHr(L"CreateTexture2D(staging)", hr);
    return hr;
}

// ================= Global state =================
struct DupState {
    HANDLE stopEvt = nullptr;
    HANDLE th = nullptr;

    std::atomic<int> fps{ 60 };
    std::atomic<UINT> wantAdp{ 0 };
    std::atomic<UINT> wantOutInAdp{ 0 };
    std::atomic<bool> needRebuild{ false };

    CRITICAL_SECTION cs;
    bool csInit = false;

    UINT w = 0, h = 0, stride = 0;
    std::vector<BYTE> buf;
    std::atomic<UINT> frameId{ 0 };

    std::atomic<HRESULT> lastHr{ S_OK };
    std::wstring lastMsg;
} g;

static void SetLastErrorHR(HRESULT hr, const wchar_t* where) {
    g.lastHr.store(hr, std::memory_order_relaxed);
    wchar_t t[256];
    swprintf(t, 256, L"%s hr=0x%08X", where, (unsigned)hr);
    g.lastMsg = t;
    LogHr(where, hr);
}

static void CleanupLocal(ID3D11Device*& dev, ID3D11DeviceContext*& ctx, IDXGIOutputDuplication*& dup, ID3D11Texture2D*& staging) {
    SafeRelease(staging);
    SafeRelease(dup);
    SafeRelease(ctx);
    SafeRelease(dev);
}

static unsigned __stdcall CaptureThread(void*) {
    __try {
        Logf(L"CaptureThread entry");

        HRESULT hrCo = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
        LogHr(L"CoInitializeEx", hrCo);
        bool coInited = (hrCo == S_OK || hrCo == S_FALSE);

        ID3D11Device* dev = nullptr;
        ID3D11DeviceContext* ctx = nullptr;
        IDXGIOutputDuplication* dup = nullptr;
        ID3D11Texture2D* staging = nullptr;

        Logf(L"CaptureThread loop begin");

        for (;;) {
            if (!g.stopEvt) break;
            if (WaitForSingleObject(g.stopEvt, 0) == WAIT_OBJECT_0) break;

            if (g.needRebuild.load(std::memory_order_relaxed) || !dev || !ctx || !dup) {
                g.needRebuild.store(false, std::memory_order_relaxed);

                UINT ai = g.wantAdp.load(std::memory_order_relaxed);
                UINT oi = g.wantOutInAdp.load(std::memory_order_relaxed);
                Logf(L"Rebuild begin: adp=%u out=%u", ai, oi);

                CleanupLocal(dev, ctx, dup, staging);

                HRESULT hrDev = CreateDeviceOnAdapter(ai, &dev, &ctx);
                if (FAILED(hrDev)) {
                    SetLastErrorHR(hrDev, L"CreateDeviceOnAdapter(rebuild)");
                    Sleep(200);
                    continue;
                }

                HRESULT hrDup = CreateDuplication(ai, oi, dev, &dup);
                if (FAILED(hrDup)) {
                    SetLastErrorHR(hrDup, L"CreateDuplication(rebuild)");
                    CleanupLocal(dev, ctx, dup, staging);
                    Sleep(200);
                    continue;
                }

                Logf(L"Rebuild OK: adp=%u out=%u", ai, oi);
            }

            int fps = g.fps.load(std::memory_order_relaxed);
            int base = (std::max)(1, 1000 / (std::max)(1, fps));

            IDXGIResource* res = nullptr;
            DXGI_OUTDUPL_FRAME_INFO info{};
            HRESULT hr = dup->AcquireNextFrame(base, &info, &res);

            if (hr == DXGI_ERROR_WAIT_TIMEOUT) {
                continue;
            }

            if (hr == DXGI_ERROR_ACCESS_LOST || hr == DXGI_ERROR_DEVICE_REMOVED || hr == DXGI_ERROR_INVALID_CALL) {
                SetLastErrorHR(hr, L"AcquireNextFrame(lost)");
                SafeRelease(dup);
                SafeRelease(staging);
                g.needRebuild.store(true, std::memory_order_relaxed);
                Sleep(50);
                continue;
            }

            if (FAILED(hr)) {
                SetLastErrorHR(hr, L"AcquireNextFrame");
                Sleep(10);
                continue;
            }

            ID3D11Texture2D* tex = nullptr;
            if (res) {
                res->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&tex);
                res->Release();
                res = nullptr;
            }

            if (tex) {
                D3D11_TEXTURE2D_DESC td{};
                tex->GetDesc(&td);

                UINT w = td.Width;
                UINT h = td.Height;
                UINT stride = w * 4;

                HRESULT hrSt = EnsureStaging(dev, &staging, w, h);
                if (FAILED(hrSt)) {
                    SetLastErrorHR(hrSt, L"EnsureStaging");
                    tex->Release();
                    dup->ReleaseFrame();
                    continue;
                }

                ctx->CopyResource(staging, tex);
                tex->Release();

                D3D11_MAPPED_SUBRESOURCE m{};
                HRESULT hrMap = ctx->Map(staging, 0, D3D11_MAP_READ, 0, &m);
                if (SUCCEEDED(hrMap)) {
                    EnterCriticalSection(&g.cs);

                    g.w = w; g.h = h; g.stride = stride;
                    const size_t need = (size_t)h * (size_t)stride;
                    if (g.buf.size() != need) g.buf.resize(need);

                    const BYTE* src = (const BYTE*)m.pData;
                    UINT srcPitch = m.RowPitch;
                    UINT copy = (std::min)(srcPitch, stride);

                    BYTE* dst = g.buf.data();
                    for (UINT y = 0; y < h; ++y) {
                        memcpy(dst + (size_t)y * stride, src + (size_t)y * srcPitch, copy);
                    }

                    g.frameId.fetch_add(1, std::memory_order_relaxed);
                    LeaveCriticalSection(&g.cs);

                    ctx->Unmap(staging, 0);
                }
                else {
                    SetLastErrorHR(hrMap, L"Map(staging)");
                }
            }

            dup->ReleaseFrame();
        }

        CleanupLocal(dev, ctx, dup, staging);

        if (coInited) CoUninitialize();
        Logf(L"CaptureThread exit normal");
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        DWORD code = GetExceptionCode();
        Logf(L"CaptureThread SEH crash! code=0x%08X", (unsigned)code);
        if (g.csInit) {
            EnterCriticalSection(&g.cs);
            g.buf.clear();
            g.w = g.h = g.stride = 0;
            LeaveCriticalSection(&g.cs);
        }
    }
    return 0;
}

// ================= Exports (signature unchanged) =================
extern "C" __declspec(dllexport) void WINAPI DupShutdown();

extern "C" __declspec(dllexport) int WINAPI DupInit(int outputIndex, int fps) {
    Logf(L"DupInit request: globalOut=%d fps=%d", outputIndex, fps);
    DupShutdown();

    InitializeCriticalSection(&g.cs);
    g.csInit = true;

    g.fps.store((fps > 0 ? fps : 60), std::memory_order_relaxed);

    UINT ai = 0, oi = 0; DXGI_OUTPUT_DESC d{};
    if (!ResolveGlobalIndex(outputIndex, ai, oi, &d)) {
        SetLastErrorHR(DXGI_ERROR_NOT_CURRENTLY_AVAILABLE, L"ResolveGlobalIndex");
        Logf(L"DupInit fail: ResolveGlobalIndex -> no outputs.");
        DeleteCriticalSection(&g.cs);
        g.csInit = false;
        return 0;
    }

    g.wantAdp.store(ai, std::memory_order_relaxed);
    g.wantOutInAdp.store(oi, std::memory_order_relaxed);
    g.needRebuild.store(true, std::memory_order_relaxed);

    g.stopEvt = CreateEventW(nullptr, TRUE, FALSE, nullptr);

    unsigned tid = 0;
    g.th = (HANDLE)_beginthreadex(nullptr, 0, &CaptureThread, nullptr, 0, &tid);
    if (!g.th) {
        Logf(L"DupInit fail: _beginthreadex");
        CloseHandle(g.stopEvt); g.stopEvt = nullptr;
        DeleteCriticalSection(&g.cs);
        g.csInit = false;
        return 0;
    }

    Logf(L"DupInit OK (thread started) adp=%u out=%u name=%s", ai, oi, d.DeviceName);
    return 1;
}

extern "C" __declspec(dllexport) void WINAPI DupShutdown() {
    Logf(L"DupShutdown");

    if (g.th) {
        if (g.stopEvt) SetEvent(g.stopEvt);
        WaitForSingleObject(g.th, INFINITE);
        CloseHandle(g.th);
        g.th = nullptr;
    }
    if (g.stopEvt) {
        CloseHandle(g.stopEvt);
        g.stopEvt = nullptr;
    }

    if (g.csInit) {
        EnterCriticalSection(&g.cs);
        g.buf.clear();
        g.w = g.h = g.stride = 0;
        g.frameId.store(0, std::memory_order_relaxed);
        LeaveCriticalSection(&g.cs);

        DeleteCriticalSection(&g.cs);
        g.csInit = false;
    }
    else {
        g.buf.clear();
        g.w = g.h = g.stride = 0;
        g.frameId.store(0, std::memory_order_relaxed);
    }
}

extern "C" __declspec(dllexport) int WINAPI DupIsReady() {
    if (!g.csInit) return 0;
    EnterCriticalSection(&g.cs);
    int ok = (!g.buf.empty() && g.w && g.h) ? 1 : 0;
    LeaveCriticalSection(&g.cs);
    return ok;
}

extern "C" __declspec(dllexport) void WINAPI DupGetSize(int* w, int* h, int* stride) {
    if (!g.csInit) { if (w)*w = 0; if (h)*h = 0; if (stride)*stride = 0; return; }
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
            copied = need;
        }
    }

    LeaveCriticalSection(&g.cs);
    return copied;
}

extern "C" __declspec(dllexport) int WINAPI DupLockFrame(void** outPtr, int* stride, int* w, int* h) {
    if (!outPtr || !g.csInit) return 0;
    EnterCriticalSection(&g.cs);
    if (g.w && g.h && !g.buf.empty()) {
        *outPtr = (void*)g.buf.data();
        if (stride) *stride = (int)g.stride;
        if (w) *w = (int)g.w;
        if (h) *h = (int)g.h;
        return 1;
    }
    LeaveCriticalSection(&g.cs);
    return 0;
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

    UINT ai = 0, oi = 0;
    if (!ResolveGlobalIndex(idx, ai, oi, nullptr)) {
        SetLastErrorHR(DXGI_ERROR_INVALID_CALL, L"DupSelectOutput(resolve)");
        return 0;
    }

    g.wantAdp.store(ai, std::memory_order_relaxed);
    g.wantOutInAdp.store(oi, std::memory_order_relaxed);
    g.needRebuild.store(true, std::memory_order_relaxed);
    return 1;
}

extern "C" __declspec(dllexport) void WINAPI DupSetFPS(int fps) {
    int v = (fps > 0 ? fps : 60);
    g.fps.store(v, std::memory_order_relaxed);
    Logf(L"DupSetFPS -> %d", v);
}

extern "C" __declspec(dllexport) int WINAPI DupGetLastErrorCode() {
    return (int)g.lastHr.load(std::memory_order_relaxed);
}

extern "C" __declspec(dllexport) int WINAPI DupGetLastErrorText(wchar_t* buf, int bufChars) {
    if (!buf || bufChars <= 0) return 0;
    if (g.lastMsg.empty()) { buf[0] = 0; return 1; }
    wcsncpy_s(buf, bufChars, g.lastMsg.c_str(), _TRUNCATE);
    return 1;
}
