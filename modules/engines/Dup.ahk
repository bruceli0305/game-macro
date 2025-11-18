#Requires AutoHotkey v2
; DXGI Dup AHK 封装 + 安全兜底（无输出/异常时绝不创建线程）+ 日志
; dll: modules\lib\dxgi_dup.dll

global DX_dll := ""
global gDX := {
    Enabled: true,                 ; 总开关（可用 Dup_Enable(false) 强制关闭）
    Ready: false,
    OutIdx: 0,
    FPS: 60,
    MonName: "",
    L: 0, T: 0, R: 0, B: 0,
    Debug: true,
    Stats: { FrameNo: 0, Dx: 0, Roi: 0, Gdi: 0, LastPath: "", LastLog: 0, LastReady: -1 }
}

; ---------- 环境信息 ----------
Dup_IsRemoteSession() {
    return DllCall("user32\GetSystemMetrics", "int", 0x1000, "int") != 0    ; SM_REMOTESESSION
}
Dup_DumpEnv() {
    arch := (A_PtrSize=8 ? "x64" : "x86")
    admin := (A_IsAdmin ? "Admin" : "User")
    remote := (Dup_IsRemoteSession() ? "RemoteSession" : "Local")
    os := A_OSVersion
}

; ---------- DLL 导出 ----------
DX_Init(output := 0, fps := 60, dllPath := "") {
    global DX_dll
    if (dllPath = "")
        dllPath := A_ScriptDir "\modules\lib\dxgi_dup.dll"
    DX_dll := dllPath
    return DllCall(DX_dll "\DupInit", "int", output, "int", fps, "int")
}
DX_Shutdown() {
    global DX_dll, gDX
    if (DX_dll != "")
        DllCall(DX_dll "\DupShutdown")
    gDX.Ready := false
}
DX_IsReady() {
    global DX_dll
    return (DX_dll != "" && DllCall(DX_dll "\DupIsReady", "int") = 1)
}
DX_GetPixel(x, y) {
    global DX_dll
    return (DX_dll = "") ? 0 : DllCall(DX_dll "\DupGetPixel", "int", x, "int", y, "uint")
}
DX_EnumOutputs() {
    global DX_dll
    return (DX_dll = "") ? 0 : DllCall(DX_dll "\DupEnumOutputs", "int")
}
DX_GetOutputName(idx) {
    global DX_dll
    buf := Buffer(128*2, 0)
    ok := (DX_dll != "") ? DllCall(DX_dll "\DupGetOutputName", "int", idx, "ptr", buf.Ptr, "int", 128, "int") : 0
    return ok ? StrGet(buf.Ptr, "UTF-16") : ""
}
DX_SelectOutput(idx) {
    global DX_dll
    return (DX_dll = "") ? 0 : DllCall(DX_dll "\DupSelectOutput", "int", idx, "int")
}
DX_SetFPS(fps) {
    global DX_dll
    if (DX_dll != "")
        DllCall(DX_dll "\DupSetFPS", "int", fps)
}
DX_LastError() {
    global DX_dll
    if (DX_dll = "") {
        return { Code: 0, Text: "" }
    }
    code := DllCall(DX_dll "\DupGetLastErrorCode", "int")
    buf := Buffer(256*2, 0)
    DllCall(DX_dll "\DupGetLastErrorText", "ptr", buf.Ptr, "int", 256, "int")
    return { Code: code, Text: StrGet(buf.Ptr, "UTF-16") }
}

; ---------- 高层：自动初始化 / 映射 / 取色（兜底防闪退版本） ----------
Dup_InitAuto(outputIdx := 0, fps := 0) {
    ; 关掉就不走任何 DLL
    if (!gDX.Enabled) {
        gDX.Ready := false
        return false
    }

    Dup_DumpEnv()

    ; 估算 FPS（按轮询间隔）
    if (fps <= 0) {
        try {
            global App
            pi := (IsObject(App) && App.Has("ProfileData")) ? App["ProfileData"].PollIntervalMs : 25
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
        } catch {
            fps := 60
        }
    }
    ; 先探测输出数量（若为0，绝不创建线程）
    cnt := 0
    try cnt := DX_EnumOutputs()
    if (cnt <= 0) {
        gDX.Ready := false
        return false
    }

    ; 构造尝试序列
    attempts := []
    attempts.Push(outputIdx)
    loop cnt {
        i := A_Index - 1
        if (i != outputIdx)
            attempts.Push(i)
    }

    ok := 0, chosen := -1
    for _, idx in attempts {
        name := ""
        try name := DX_GetOutputName(idx)
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
            try DX_Shutdown()
        }
    }

    if (chosen >= 0) {
        gDX.Ready := true
        gDX.OutIdx := chosen
        gDX.FPS := fps
        Dup_UpdateMonitorRect()
        ready := 0
        try ready := DX_IsReady() ? 1 : 0
        gDX.Stats.LastReady := ready
        return true
    } else {
        gDX.Ready := false
        return false
    }
}

Dup_UpdateMonitorRect() {
    name := ""
    try name := DX_GetOutputName(gDX.OutIdx)
    gDX.MonName := name

    cnt := 0
    try cnt := MonitorGetCount()
    found := false
    l := 0, t := 0, r := A_ScreenWidth - 1, b := A_ScreenHeight - 1

    loop cnt {
        i := A_Index
        mname := ""
        try {
            mname := MonitorGetName(i)
        } catch {
            mname := ""
        }
        if (mname != "" && name != "" && mname = name) {
            try MonitorGet(i, &l, &t, &r, &b)
            gDX.L := l, gDX.T := t, gDX.R := r, gDX.B := b
            found := true
            break
        }
    }
    if !found {
        idx := gDX.OutIdx + 1
        if (idx >= 1 && idx <= cnt) {
            try MonitorGet(idx, &l, &t, &r, &b)
        } else {
            try MonitorGet(1, &l, &t, &r, &b)   ; 主屏兜底
        }
        gDX.L := l, gDX.T := t, gDX.R := r, gDX.B := b
    }
}

Dup_ScreenToOutput(x, y) {
    if (x < gDX.L || y < gDX.T || x > gDX.R || y > gDX.B)
        return { ok:false }
    return { ok:true, X: x - gDX.L, Y: y - gDX.T }
}

; 屏幕取色（优先 DXGI），返回 0xRRGGBB；不在当前输出或未就绪 -> -1
Dup_GetPixelAtScreen(x, y) {
    if (!gDX.Enabled || !gDX.Ready)
        return -1
    ready := 0
    try ready := DX_IsReady() ? 1 : 0
    if (!ready)
        return -1
    m := Dup_ScreenToOutput(x, y)
    if !m.ok
        return -1
    return DX_GetPixel(m.X, m.Y)   ; 注意：0 也是有效色(黑)，-1 才表示失败
}

; 轮询间隔变化/切换配置时调用（动态 FPS）
Dup_OnProfileChanged() {
    try {
        global App
        if (IsObject(App) && App.Has("ProfileData")) {
            pi := App["ProfileData"].PollIntervalMs
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
            if (fps != gDX.FPS) {
                gDX.FPS := fps
                DX_SetFPS(fps)
            }
        }
    }
}

; 运行中切换输出（0-based）
Dup_SelectOutputIdx(idx) {
    if (!gDX.Enabled)
        return 0
    gDX.OutIdx := Max(0, idx)
    ok := 0
    try ok := DX_SelectOutput(gDX.OutIdx)
    if (ok = 1) {
        Dup_UpdateMonitorRect()
        return 1
    } else {
        return 0
    }
}

; ---------- 帧统计（可选：如果你已接入） ----------
Dup_FrameBegin() {
    s := gDX.Stats
    if !IsObject(s) {
        gDX.Stats := { FrameNo: 0, Dx: 0, Roi: 0, Gdi: 0, LastPath: "", LastLog: 0, LastReady: -1 }
        s := gDX.Stats
    }
    if gDX.Debug {
        readyNow := 0
        try readyNow := DX_IsReady() ? 1 : 0
        if (s.FrameNo = 0) {
            s.LastReady := readyNow
        } else {
            path := (s.Dx>0 ? "DXGI" : (s.Roi>0 ? "ROI" : (s.Gdi>0 ? "GDI" : "None")))
            need := false
            if (path != s.LastPath) {
                s.LastPath := path
                need := true
            }
            if (s.LastReady != readyNow) {
                s.LastReady := readyNow
                need := true
            }
            if (need || (s.FrameNo - s.LastLog >= 120)) {
                s.LastLog := s.FrameNo
            }
        }
    }
    s.Dx := 0, s.Roi := 0, s.Gdi := 0
    s.FrameNo++
}
Dup_NotifyPath(path) {
    s := gDX.Stats
    if !IsObject(s) {
        gDX.Stats := { FrameNo: 0, Dx: 0, Roi: 0, Gdi: 0, LastPath: "", LastLog: 0, LastReady: -1 }
        s := gDX.Stats
    }
    switch path {
        case "DX":  s.Dx  += 1
        case "ROI": s.Roi += 1
        case "GDI": s.Gdi += 1
    }
}

; --- Back-compat ---
Dup_Shutdown() {
    DX_Shutdown()
}