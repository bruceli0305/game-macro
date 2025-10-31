// dxgi_dup.cpp - build as x64 DLL
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <atomic>
#include <vector>
#include <string>
#include <cstdio>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

struct DupState {
    // D3D/DXGI
    ID3D11Device*           dev   = nullptr;
    ID3D11DeviceContext*    ctx   = nullptr;
    IDXGIOutputDuplication* dup   = nullptr;
    ID3D11Texture2D*        staging = nullptr;

    // Frame buffer (BGRA8, top-down)
    UINT                    w = 0, h = 0, stride = 0;
    std::vector<BYTE>       buf;
    std::atomic<UINT>       frameId{ 0 };

    // Threading
    HANDLE                  th = nullptr;
    HANDLE                  stopEvt = nullptr;
    int                     fps = 60;
    int                     outputIndex = 0;

    // Errors
    HRESULT                 lastHr = S_OK;
    std::wstring            lastMsg;

    CRITICAL_SECTION        cs;
} g;

static void SafeRelease(IUnknown* p) { if (p) p->Release(); }

static void SetLastHR(HRESULT hr, const wchar_t* where) {
    g.lastHr = hr;
    wchar_t buf[256];
    swprintf(buf, 256, L"%s hr=0x%08X", where, (unsigned)hr);
    g.lastMsg = buf;
}

static HRESULT CreateDevice(bool warp, ID3D11Device** outDev, ID3D11DeviceContext** outCtx) {
    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
#if defined(_DEBUG)
    // flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    D3D_FEATURE_LEVEL fls[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    return D3D11CreateDevice(nullptr, warp ? D3D_DRIVER_TYPE_WARP : D3D_DRIVER_TYPE_HARDWARE,
                             nullptr, flags, fls, ARRAYSIZE(fls), D3D11_SDK_VERSION, outDev, nullptr, outCtx);
}

static HRESULT RecreateDuplication() {
    SafeRelease(g.dup);
    IDXGIDevice* dxgiDev = nullptr;
    IDXGIAdapter* adp = nullptr;
    IDXGIOutput*  out = nullptr;
    IDXGIOutput1* out1 = nullptr;
    HRESULT hr = g.dev->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgiDev);
    if (FAILED(hr)) { SetLastHR(hr, L"QI IDXGIDevice"); goto L_END; }
    hr = dxgiDev->GetAdapter(&adp);
    if (FAILED(hr)) { SetLastHR(hr, L"GetAdapter"); goto L_END; }
    hr = adp->EnumOutputs(g.outputIndex, &out);
    if (FAILED(hr)) { SetLastHR(hr, L"EnumOutputs"); goto L_END; }
    hr = out->QueryInterface(__uuidof(IDXGIOutput1), (void**)&out1);
    if (FAILED(hr)) { SetLastHR(hr, L"QI IDXGIOutput1"); goto L_END; }
    hr = out1->DuplicateOutput(g.dev, &g.dup);
    if (FAILED(hr)) { SetLastHR(hr, L"Duplication"); }

L_END:
    SafeRelease(out1);
    SafeRelease(out);
    SafeRelease(adp);
    SafeRelease(dxgiDev);
    return hr;
}

static HRESULT EnsureStaging(UINT w, UINT h) {
    if (g.staging) {
        D3D11_TEXTURE2D_DESC d;
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
    if (FAILED(hr)) SetLastHR(hr, L"CreateTexture2D(staging)");
    return hr;
}

static DWORD WINAPI CaptureThread(LPVOID) {
    const int base = max(1, 1000 / max(1, g.fps));
    for (;;) {
        if (WaitForSingleObject(g.stopEvt, 0) == WAIT_OBJECT_0) break;

        if (!g.dup) {
            if (FAILED(RecreateDuplication())) { Sleep(200); continue; }
        }

        IDXGIResource* res = nullptr;
        DXGI_OUTDUPL_FRAME_INFO info{};
        HRESULT hr = g.dup->AcquireNextFrame(base, &info, &res);
        if (hr == DXGI_ERROR_WAIT_TIMEOUT) continue;
        if (hr == DXGI_ERROR_ACCESS_LOST || hr == DXGI_ERROR_INVALID_CALL || hr == DXGI_ERROR_DEVICE_REMOVED) {
            SetLastHR(hr, L"AcquireNextFrame(lost)");
            SafeRelease(g.dup);
            continue;
        }
        if (FAILED(hr)) {
            SetLastHR(hr, L"AcquireNextFrame");
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
                const UINT copy = min(srcPitch, stride);
                BYTE* dst = g.buf.data();
                for (UINT y = 0; y < h; ++y) {
                    memcpy(dst + (size_t)y * stride, src + (size_t)y * srcPitch, copy);
                }
                g.frameId.fetch_add(1, std::memory_order_relaxed);
                LeaveCriticalSection(&g.cs);
                g.ctx->Unmap(g.staging, 0);
            } else {
                SetLastHR(hr, L"Map(staging)");
            }
        }

        g.dup->ReleaseFrame();
    }
    return 0;
}

// ========== helpers for DXGI enumeration ==========
static int EnumOutputsCount() {
    IDXGIFactory1* fac = nullptr;
    int count = 0;
    if (SUCCEEDED(CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac)) && fac) {
        IDXGIAdapter1* adp = nullptr;
        if (SUCCEEDED(fac->EnumAdapters1(0, &adp)) && adp) {
            for (UINT i = 0;; ++i) {
                IDXGIOutput* out = nullptr;
                if (adp->EnumOutputs(i, &out) == DXGI_ERROR_NOT_FOUND) break;
                if (out) { ++count; out->Release(); }
            }
            adp->Release();
        }
        fac->Release();
    }
    return count;
}

static bool GetOutputNameW(int idx, std::wstring& outName) {
    IDXGIFactory1* fac = nullptr;
    if (FAILED(CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&fac)) || !fac) return false;
    bool ok = false;
    IDXGIAdapter1* adp = nullptr;
    if (SUCCEEDED(fac->EnumAdapters1(0, &adp)) && adp) {
        IDXGIOutput* out = nullptr;
        if (SUCCEEDED(adp->EnumOutputs(idx, &out)) && out) {
            DXGI_OUTPUT_DESC d{};
            if (SUCCEEDED(out->GetDesc(&d))) {
                outName = d.DeviceName; // e.g. L"\\.\DISPLAY1"
                ok = true;
            }
            out->Release();
        }
        adp->Release();
    }
    fac->Release();
    return ok;
}

// ========== C 导出 ==========
extern "C" __declspec(dllexport) int WINAPI DupInit(int outputIndex, int fps) {
    DupShutdown(); // cleanup any previous
    InitializeCriticalSection(&g.cs);
    g.outputIndex = outputIndex;
    g.fps = fps > 0 ? fps : 60;
    g.lastHr = S_OK; g.lastMsg.clear();

    HRESULT hr = CreateDevice(false, &g.dev, &g.ctx);
    if (FAILED(hr)) {
        SetLastHR(hr, L"D3D11CreateDevice(HW)");
        hr = CreateDevice(true, &g.dev, &g.ctx); // WARP fallback
        if (FAILED(hr)) {
            SetLastHR(hr, L"D3D11CreateDevice(WARP)");
            DeleteCriticalSection(&g.cs);
            return 0;
        }
    }
    if (FAILED(RecreateDuplication())) {
        DupShutdown();
        return 0;
    }
    g.stopEvt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g.th = CreateThread(nullptr, 0, CaptureThread, nullptr, 0, nullptr);
    if (!g.th) {
        DupShutdown();
        return 0;
    }
    return 1;
}

extern "C" __declspec(dllexport) void WINAPI DupShutdown() {
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
    EnterCriticalSection(&g.cs);
    g.buf.clear(); g.w = g.h = g.stride = 0; g.frameId = 0;
    LeaveCriticalSection(&g.cs);
    DeleteCriticalSection(&g.cs);
}

extern "C" __declspec(dllexport) int WINAPI DupIsReady() {
    return (g.dup && g.w && g.h && !g.buf.empty()) ? 1 : 0;
}

extern "C" __declspec(dllexport) void WINAPI DupGetSize(int* w, int* h, int* stride) {
    EnterCriticalSection(&g.cs);
    if (w) *w = (int)g.w;
    if (h) *h = (int)g.h;
    if (stride) *stride = (int)g.stride;
    LeaveCriticalSection(&g.cs);
}

extern "C" __declspec(dllexport) unsigned int WINAPI DupGetPixel(int x, int y) {
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
    if (!dest || destStride <= 0 || destBytes <= 0) return 0;
    EnterCriticalSection(&g.cs);
    int copied = 0;
    if (g.w && g.h && !g.buf.empty()) {
        BYTE* out = (BYTE*)dest;
        const BYTE* src = g.buf.data();
        int rowCopy = min((int)g.stride, destStride);
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
    if (!outPtr) return 0;
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
    LeaveCriticalSection(&g.cs);
}

extern "C" __declspec(dllexport) int WINAPI DupEnumOutputs() {
    return EnumOutputsCount();
}

extern "C" __declspec(dllexport) int WINAPI DupGetOutputName(int idx, wchar_t* buf, int bufChars) {
    if (!buf || bufChars <= 0) return 0;
    std::wstring name;
    if (!GetOutputNameW(idx, name)) return 0;
    wcsncpy_s(buf, bufChars, name.c_str(), _TRUNCATE);
    return 1;
}

extern "C" __declspec(dllexport) int WINAPI DupSelectOutput(int idx) {
    g.outputIndex = idx;
    // 触发重建：下一轮采集会发现 g.dup为空 或直接置空
    SafeRelease(g.dup);
    return 1;
}

extern "C" __declspec(dllexport) void WINAPI DupSetFPS(int fps) {
    g.fps = fps > 0 ? fps : 60;
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