#Requires AutoHotkey v2
; modules\engines\Dup.ahk
; DXGI Dup AHK 封装（P1 修复版）
; - 修复 outputName 偶发为空：Init 后强制取名 + 更强 fallback
; - 多屏坐标：使用 VirtualScreen fallback（支持负坐标）
; - Ready 检查降频：用 FrameId 作为心跳，卡住才重查 DupIsReady
; - 保持：DXGI 不可用/不就绪 -> 返回 -1 让 Pixel/ROI/GDI 兜底

global DX_dll := ""
global gDX := {
    Enabled: true,
    Ready: false,
    OutIdx: 0,
    FPS: 60,
    MonName: "",
    L: 0, T: 0, R: 0, B: 0,
    Stats: {
        FrameNo: 0,
        Dx: 0,
        Roi: 0,
        Gdi: 0,
        LastPath: "",
        LastLog: 0,
        LastReady: -1,
        LastFrameId: 0,
        LastFrameTick: 0,
        LastReadyCheck: 0
    }
}

; ---------- 环境 ----------
Dup_IsRemoteSession() {
    return DllCall("user32\GetSystemMetrics", "int", 0x1000, "int") != 0 ; SM_REMOTESESSION
}

; ---------- DLL 导出 ----------
DX_LoadDll(dllPath := "") {
    global DX_dll
    if (dllPath = "") {
        dllPath := A_ScriptDir "\modules\lib\dxgi_dup.dll"
    }
    DX_dll := dllPath
    if (DX_dll = "" || !FileExist(DX_dll)) {
        return 0
    }
    return 1
}

DX_Init(output := 0, fps := 60, dllPath := "") {
    global DX_dll
    if (dllPath = "") {
        dllPath := A_ScriptDir "\modules\lib\dxgi_dup.dll"
    }
    DX_dll := dllPath
    return DllCall(DX_dll "\DupInit", "int", output, "int", fps, "int")
}

DX_Shutdown() {
    global DX_dll, gDX
    try {
        if (DX_dll != "") {
            DllCall(DX_dll "\DupShutdown")
        }
    } catch {
    }
    gDX.Ready := false
}

DX_IsReady() {
    global DX_dll
    if (DX_dll = "") {
        return false
    }
    try {
        return DllCall(DX_dll "\DupIsReady", "int") = 1
    } catch {
        return false
    }
}

DX_GetFrameId() {
    global DX_dll
    if (DX_dll = "") {
        return 0
    }
    try {
        return DllCall(DX_dll "\DupGetFrameId", "uint")
    } catch {
        return 0
    }
}

DX_GetPixel(x, y) {
    global DX_dll
    if (DX_dll = "") {
        return 0
    }
    return DllCall(DX_dll "\DupGetPixel", "int", x, "int", y, "uint")
}

DX_EnumOutputs() {
    global DX_dll
    if (DX_dll = "") {
        return 0
    }
    try {
        return DllCall(DX_dll "\DupEnumOutputs", "int")
    } catch {
        return 0
    }
}

DX_GetOutputName(idx) {
    global DX_dll
    if (DX_dll = "") {
        return ""
    }
    buf := Buffer(128 * 2, 0)
    ok := 0
    try {
        ok := DllCall(DX_dll "\DupGetOutputName", "int", idx, "ptr", buf.Ptr, "int", 128, "int")
    } catch {
        ok := 0
    }
    if (!ok) {
        return ""
    }
    try {
        return StrGet(buf.Ptr, "UTF-16")
    } catch {
        return ""
    }
}

DX_SelectOutput(idx) {
    global DX_dll
    if (DX_dll = "") {
        return 0
    }
    try {
        return DllCall(DX_dll "\DupSelectOutput", "int", idx, "int")
    } catch {
        return 0
    }
}

DX_SetFPS(fps) {
    global DX_dll
    try {
        if (DX_dll != "") {
            DllCall(DX_dll "\DupSetFPS", "int", fps)
        }
    } catch {
    }
}

DX_LastError() {
    global DX_dll
    if (DX_dll = "") {
        return { Code: 0, Text: "" }
    }
    code := 0
    txt := ""
    try {
        code := DllCall(DX_dll "\DupGetLastErrorCode", "int")
    } catch {
        code := 0
    }
    buf := Buffer(256 * 2, 0)
    ok := 0
    try {
        ok := DllCall(DX_dll "\DupGetLastErrorText", "ptr", buf.Ptr, "int", 256, "int")
    } catch {
        ok := 0
    }
    if (ok) {
        try {
            txt := StrGet(buf.Ptr, "UTF-16")
        } catch {
            txt := ""
        }
    }
    return { Code: code, Text: txt }
}

; ---------- 高层：自动初始化 ----------
Dup_InitAuto(outputIdx := 0, fps := 0) {
    global gDX, App, DX_dll

    if (!gDX.Enabled) {
        gDX.Ready := false
        return false
    }

    ; 估算 FPS（按轮询间隔）
    if (fps <= 0) {
        try {
            pi := (IsSet(App) && IsObject(App) && App.Has("ProfileData")) ? App["ProfileData"].PollIntervalMs : 25
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
        } catch {
            fps := 60
        }
    }

    try {
        Logger_Info("DXGI", "InitAuto begin", Map("outIdx", outputIdx, "fps", fps))
    } catch {
    }

    dllOk := DX_LoadDll()
    if (!dllOk) {
        gDX.Ready := false
        try {
            Logger_Error("DXGI", "dxgi_dup.dll not found", Map("dll", DX_dll))
        } catch {
        }
        return false
    }

    cnt := DX_EnumOutputs()
    if (cnt <= 0) {
        gDX.Ready := false
        try {
            le := DX_LastError()
            Logger_Error("DXGI", "EnumOutputs failed", Map("cnt", cnt, "code", le.Code, "err", le.Text))
        } catch {
        }
        return false
    }

    ; 构造尝试序列：优先用户指定 outputIdx，其余依次尝试
    attempts := []
    attempts.Push(outputIdx)
    Loop cnt {
        i := A_Index - 1
        if (i != outputIdx) {
            attempts.Push(i)
        }
    }

    ok := 0
    chosen := -1
    for _, idx in attempts {
        ok := 0
        try {
            ok := DX_Init(idx, fps)
        } catch {
            ok := 0
        }
        if (ok = 1) {
            chosen := idx
            break
        } else {
            try {
                DX_Shutdown()
            } catch {
            }
        }
    }

    if (chosen < 0) {
        gDX.Ready := false
        try {
            le := DX_LastError()
            Logger_Warn("DXGI", "Init FAIL, fallback ROI/GDI", Map("code", le.Code, "err", le.Text))
        } catch {
        }
        return false
    }

    gDX.Ready := true
    gDX.OutIdx := chosen
    gDX.FPS := fps

    ; 关键：初始化后强制取名 + 更新 rect
    Dup_UpdateMonitorRect()

    if (gDX.MonName = "") {
        ; 再补一次（避免偶发空名）
        try {
            gDX.MonName := DX_GetOutputName(gDX.OutIdx)
        } catch {
            gDX.MonName := ""
        }
    }

    try {
        Logger_Info("DXGI", "Init OK", Map(
            "outIdx", gDX.OutIdx,
            "name", gDX.MonName,
            "l", gDX.L, "t", gDX.T, "r", gDX.R, "b", gDX.B,
            "fps", gDX.FPS
        ))
    } catch {
    }
    return true
}

; ---------- 多屏 rect 更新 ----------
Dup__GetVirtualScreenRect(&l, &t, &r, &b) {
    ; GetSystemMetrics: SM_XVIRTUALSCREEN=76, SM_YVIRTUALSCREEN=77, SM_CXVIRTUALSCREEN=78, SM_CYVIRTUALSCREEN=79
    vx := DllCall("user32\GetSystemMetrics", "int", 76, "int")
    vy := DllCall("user32\GetSystemMetrics", "int", 77, "int")
    vw := DllCall("user32\GetSystemMetrics", "int", 78, "int")
    vh := DllCall("user32\GetSystemMetrics", "int", 79, "int")
    l := vx
    t := vy
    r := vx + vw - 1
    b := vy + vh - 1
}

Dup_UpdateMonitorRect() {
    global gDX

    name := ""
    try {
        name := DX_GetOutputName(gDX.OutIdx)
    } catch {
        name := ""
    }
    gDX.MonName := name

    cnt := 0
    try {
        cnt := MonitorGetCount()
    } catch {
        cnt := 0
    }

    found := false
    l := 0, t := 0, r := 0, b := 0

    if (cnt > 0 && name != "") {
        Loop cnt {
            i := A_Index
            mname := ""
            try {
                mname := MonitorGetName(i)
            } catch {
                mname := ""
            }
            if (mname != "") {
                if (StrLower(mname) = StrLower(name)) {
                    try {
                        MonitorGet(i, &l, &t, &r, &b)
                        found := true
                    } catch {
                        found := false
                    }
                    break
                }
            }
        }
    }

    if (!found) {
        ; fallback 1：按 outIdx+1 尝试
        if (cnt > 0) {
            idx := gDX.OutIdx + 1
            if (idx < 1 || idx > cnt) {
                idx := 1
            }
            try {
                MonitorGet(idx, &l, &t, &r, &b)
                found := true
            } catch {
                found := false
            }
        }
    }

    if (!found) {
        ; fallback 2：虚拟屏幕（支持负坐标）
        try {
            Dup__GetVirtualScreenRect(&l, &t, &r, &b)
            found := true
        } catch {
            found := false
        }
    }

    if (!found) {
        ; 最后兜底：给一个安全范围
        l := 0, t := 0, r := 1920 - 1, b := 1080 - 1
    }

    gDX.L := l
    gDX.T := t
    gDX.R := r
    gDX.B := b

    if (gDX.MonName = "") {
        try {
            le := DX_LastError()
            Logger_Warn("DXGI", "Output name empty", Map("code", le.Code, "err", le.Text, "outIdx", gDX.OutIdx))
        } catch {
        }
    }
}

Dup_ScreenToOutput(x, y) {
    global gDX
    if (x < gDX.L || y < gDX.T || x > gDX.R || y > gDX.B) {
        return { ok: false }
    }
    return { ok: true, X: x - gDX.L, Y: y - gDX.T }
}

; ---------- 取色（优先 DXGI） ----------
Dup_GetPixelAtScreen(x, y) {
    global gDX

    if (!gDX.Enabled) {
        return -1
    }
    if (!gDX.Ready) {
        return -1
    }

    m := Dup_ScreenToOutput(x, y)
    if (!m.ok) {
        return -1
    }

    ; P1：低开销就绪检查：用 FrameId 作为心跳
    now := A_TickCount
    fid := 0
    try {
        fid := DX_GetFrameId()
    } catch {
        fid := 0
    }

    if (fid = 0) {
        ; 还没出帧：每 250ms 才重查一次 DupIsReady
        if (now - gDX.Stats.LastReadyCheck >= 250) {
            gDX.Stats.LastReadyCheck := now
            if (!DX_IsReady()) {
                return -1
            }
        } else {
            return -1
        }
    } else {
        if (fid != gDX.Stats.LastFrameId) {
            gDX.Stats.LastFrameId := fid
            gDX.Stats.LastFrameTick := now
        } else {
            ; frameId 卡住超过 700ms 才重查 ready
            if (now - gDX.Stats.LastFrameTick >= 700) {
                if (now - gDX.Stats.LastReadyCheck >= 250) {
                    gDX.Stats.LastReadyCheck := now
                    if (!DX_IsReady()) {
                        return -1
                    }
                } else {
                    return -1
                }
            }
        }
    }

    ; 注意：0 也是有效色，失败用 -1
    try {
        return DX_GetPixel(m.X, m.Y)
    } catch {
        return -1
    }
}

; ---------- 轮询间隔变化/切换配置时调用（动态 FPS） ----------
Dup_OnProfileChanged() {
    global gDX, App
    try {
        if (IsSet(App) && IsObject(App) && App.Has("ProfileData")) {
            pi := App["ProfileData"].PollIntervalMs
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
            if (fps != gDX.FPS) {
                gDX.FPS := fps
                DX_SetFPS(fps)
            }
        }
    } catch {
    }
}

; ---------- 运行中切换输出（0-based） ----------
Dup_SelectOutputIdx(idx) {
    global gDX
    if (!gDX.Enabled) {
        return 0
    }
    gDX.OutIdx := Max(0, idx)

    ok := 0
    try {
        ok := DX_SelectOutput(gDX.OutIdx)
    } catch {
        ok := 0
    }

    if (ok = 1) {
        Dup_UpdateMonitorRect()
        try {
            Logger_Info("DXGI", "SelectOutput", Map("outIdx", gDX.OutIdx, "name", gDX.MonName))
        } catch {
        }
        return 1
    } else {
        try {
            le := DX_LastError()
            Logger_Error("DXGI", "SelectOutput FAIL", Map("outIdx", idx, "code", le.Code, "err", le.Text))
        } catch {
        }
        return 0
    }
}
Dup_FrameBegin() {
    global gDX

    if !IsObject(gDX) {
        return
    }
    if !gDX.HasOwnProp("Stats") || !IsObject(gDX.Stats) {
        gDX.Stats := {
            FrameNo: 0,
            Dx: 0,
            Roi: 0,
            Gdi: 0,
            LastPath: "",
            LastLog: 0,
            LastReady: -1,
            LastFrameId: 0,
            LastFrameTick: 0,
            LastReadyCheck: 0
        }
    }

    s := gDX.Stats
    s.FrameNo += 1
    s.Dx := 0
    s.Roi := 0
    s.Gdi := 0
}
Dup_NotifyPath(path) {
    global gDX
    if !IsObject(gDX) || !gDX.HasOwnProp("Stats") || !IsObject(gDX.Stats) {
        return
    }
    s := gDX.Stats
    switch path {
        case "DX":
            s.Dx += 1
        case "ROI":
            s.Roi += 1
        case "GDI":
            s.Gdi += 1
    }
}
Dup_Shutdown() {
    DX_Shutdown()
}
