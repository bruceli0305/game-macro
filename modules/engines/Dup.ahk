#Requires AutoHotkey v2
; DXGI Dup AHK 封装 + 屏幕坐标映射 + 调试日志/路径统计 + 启动回退与环境打印
; dll: modules\lib\dxgi_dup.dll
; 日志：Logs\dxgi_dup.log

global DX_dll := ""
global gDX := {
    Ready: false
  , OutIdx: 0
  , FPS: 60
  , MonName: ""
  , L: 0, T: 0, R: 0, B: 0
  , Debug: true
  , Stats: { FrameNo: 0, Dx: 0, Roi: 0, Gdi: 0, LastPath: "", LastLog: 0, LastReady: -1 }
}

; ---------- 日志 ----------
DUP_Log(msg, level := "INFO") {
    if !gDX.Debug
        return
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " [DXGI] [" level "] " msg "`r`n", A_ScriptDir "\Logs\dxgi_dup.log", "UTF-8")
}
Dup_LogLastError(ctx := "") {
    err := DX_LastError()
    if (err.Code != 0 || err.Text != "") {
        part := (ctx != "" ? " (" ctx ")" : "")
        msg := "LastError" part " code=0x" Format("{:08X}", err.Code) " msg=" err.Text
        DUP_Log(msg, "ERR")
    }
}
Dup_SetDebug(flag := true) {
    gDX.Debug := !!flag
    DUP_Log("Debug=" (gDX.Debug ? "ON" : "OFF"))
}

; ---------- 环境与输出枚举 ----------
Dup_IsRemoteSession() {
    return DllCall("user32\GetSystemMetrics", "int", 0x1000, "int") != 0    ; SM_REMOTESESSION
}
Dup_DumpEnv() {
    arch := (A_PtrSize=8 ? "x64" : "x86")
    admin := (A_IsAdmin ? "Admin" : "User")
    remote := (Dup_IsRemoteSession() ? "RemoteSession" : "Local")
    os := A_OSVersion
    DUP_Log(Format("Env: ahk={1} perm={2} session={3} os={4}", arch, admin, remote, os))
    if Dup_IsRemoteSession()
        DUP_Log("Warning: Remote session may block DXGI duplication", "WARN")
}
Dup_LogOutputs() {
    cnt := 0
    try cnt := DX_EnumOutputs()
    DUP_Log("EnumOutputs count=" cnt)
    loop cnt {
        i := A_Index - 1
        name := ""
        try name := DX_GetOutputName(i)
        ; 映射到 AHK Monitor（按设备名）
        mapIdx := 0
        monCnt := 0
        try monCnt := MonitorGetCount()
        loop monCnt {
            mi := A_Index
            mname := ""
            try {
                mname := MonitorGetName(mi)
            } catch {
                mname := ""
            }
            if (mname != "" && name != "" && mname = name) {
                mapIdx := mi
                break
            }
        }
        DUP_Log(Format("Output[{1}] Name={2} MapToMonitor={3}", i, (name!=""?name:"<unknown>"), mapIdx))
    }
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

; ---------- 高层：自动初始化 / 映射 / 屏幕取色 ----------
; 尝试指定 outIdx；若失败，枚举其余输出逐一尝试，并记录每次失败的 LastError
Dup_InitAuto(outputIdx := 0, fps := 0) {
    Dup_DumpEnv()
    Dup_LogOutputs()

    if (fps <= 0) {
        try {
            global App
            pi := (IsObject(App) && App.Has("ProfileData")) ? App["ProfileData"].PollIntervalMs : 25
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
        } catch {
            fps := 60
        }
    }
    DUP_Log("InitAuto: dll=" A_ScriptDir "\modules\lib\dxgi_dup.dll out=" outputIdx " fps=" fps)

    ; 构建尝试序列：先用户指定，再其它输出
    attempts := []
    cnt := 0
    try cnt := DX_EnumOutputs()
    if (cnt <= 0)
        DUP_Log("EnumOutputs returned 0 (no outputs?)", "WARN")
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
        DUP_Log(Format("Try Init on Output[{1}] Name={2}", idx, (name!=""?name:"<unknown>")))
        try {
            ok := DX_Init(idx, fps)
        } catch {
            ok := 0
            ; 可选：记录抛异常的 init 失败
            Dup_LogLastError(Format("Init@{1}-throw", idx))
        }
        if (ok = 1) {
            chosen := idx
            break
        } else {
            Dup_LogLastError(Format("Init@{1}", idx))
            ; 防止占用未释放：确保彻底关闭
            try DX_Shutdown()
        }
    }

    if (chosen >= 0) {
        gDX.Ready := true
        gDX.OutIdx := chosen
        gDX.FPS := fps
        Dup_UpdateMonitorRect()
        ready := DX_IsReady()
        gDX.Stats.LastReady := ready ? 1 : 0
        DUP_Log(Format("Init OK on Output[{1}] Ready={2} Name={3} Rect=({4},{5})-({6},{7}) FPS={8}"
            , chosen, (ready?1:0), gDX.MonName, gDX.L, gDX.T, gDX.R, gDX.B, gDX.FPS))
        if (!ready)
            Dup_LogLastError("PostInit")
        return true
    } else {
        gDX.Ready := false
        DUP_Log("Init FAIL after trying all outputs", "ERR")
        Dup_LogLastError("Final")
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
            try MonitorGet(1, &l, &t, &r, &b)
        }
        gDX.L := l, gDX.T := t, gDX.R := r, gDX.B := b
    }
    DUP_Log(Format("MapOutput: OutIdx={1} Name={2} Rect=({3},{4})-({5},{6})"
        , gDX.OutIdx, gDX.MonName, gDX.L, gDX.T, gDX.R, gDX.B))
}

Dup_ScreenToOutput(x, y) {
    if (x < gDX.L || y < gDX.T || x > gDX.R || y > gDX.B)
        return { ok:false }
    return { ok:true, X: x - gDX.L, Y: y - gDX.T }
}

Dup_GetPixelAtScreen(x, y) {
    if (!gDX.Ready || !DX_IsReady())
        return -1
    m := Dup_ScreenToOutput(x, y)
    if !m.ok
        return -1
    return DX_GetPixel(m.X, m.Y)
}

Dup_OnProfileChanged() {
    try {
        global App
        if (IsObject(App) && App.Has("ProfileData")) {
            pi := App["ProfileData"].PollIntervalMs
            fps := Max(20, Min(120, Floor(1000 / Max(10, pi))))
            if (fps != gDX.FPS) {
                gDX.FPS := fps
                DX_SetFPS(fps)
                DUP_Log("FPS update -> " fps)
            }
        }
    }
}

Dup_SelectOutputIdx(idx) {
    gDX.OutIdx := Max(0, idx)
    DX_SelectOutput(gDX.OutIdx)
    Dup_UpdateMonitorRect()
    DUP_Log("SelectOutput -> " gDX.OutIdx " (" gDX.MonName ")")
}

; ---------- 帧级统计 ----------
Dup_FrameBegin() {
    s := gDX.Stats
    if !IsObject(s) {
        gDX.Stats := { FrameNo: 0, Dx: 0, Roi: 0, Gdi: 0, LastPath: "", LastLog: 0, LastReady: -1 }
        s := gDX.Stats
    }
    if gDX.Debug {
        readyNow := DX_IsReady() ? 1 : 0
        if (s.FrameNo = 0) {
            s.LastReady := readyNow
            DUP_Log(Format("State: Ready={1} Out={2} Name={3} Rect=({4},{5})-({6},{7}) FPS={8}"
                , readyNow, gDX.OutIdx, gDX.MonName, gDX.L, gDX.T, gDX.R, gDX.B, gDX.FPS))
            if (!readyNow)
                Dup_LogLastError("FirstFrame")
        } else {
            path := (s.Dx>0 ? "DXGI" : (s.Roi>0 ? "ROI" : (s.Gdi>0 ? "GDI" : "None")))
            need := false
            if (path != s.LastPath) {
                s.LastPath := path
                need := true
            }
            last := s.LastReady
            if (last != readyNow) {
                s.LastReady := readyNow
                DUP_Log("Ready -> " (readyNow ? "READY" : "NOT_READY"))
                if (!readyNow)
                    Dup_LogLastError("FrameBegin")
                need := true
            }
            if (need || (s.FrameNo - s.LastLog >= 120)) {
                DUP_Log(Format("Frame#{1} path={2} hits: dx={3} roi={4} gdi={5}"
                    , s.FrameNo, path, s.Dx, s.Roi, s.Gdi))
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