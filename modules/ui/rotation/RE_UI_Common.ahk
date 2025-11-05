; modules\ui\rotation\RE_UI_Common.ahk
#Requires AutoHotkey v2

; 日志
REUI_Log(msg) {
    try {
        DirCreate(A_ScriptDir "\Logs")
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [RotationUI] " msg "`r`n"
            , A_ScriptDir "\Logs\ui_rotation_editor.log", "UTF-8")
    }
}

; 创建带 Owner 的 GUI（若主窗存在）
REUI_CreateOwnedGui(title := "Rotation 配置") {
    try {
        if IsSet(UI) && IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd
            return Gui("+Owner" UI.Main.Hwnd, title)
    }
    return Gui(, title)
}

; 统一兜底 Rotation 配置（在 UI 侧保证键齐备）
REUI_EnsureRotationDefaults(&cfg) {
    if !IsObject(cfg)
        cfg := {}
    if !HasProp(cfg, "Enabled")         cfg.Enabled := 0
    if !HasProp(cfg, "DefaultTrackId")  cfg.DefaultTrackId := 1
    if !HasProp(cfg, "BusyWindowMs")    cfg.BusyWindowMs := 200
    if !HasProp(cfg, "ColorTolBlack")   cfg.ColorTolBlack := 16
    if !HasProp(cfg, "RespectCastLock") cfg.RespectCastLock := 1
    if !HasProp(cfg, "SwapKey")         cfg.SwapKey := ""
    if !HasProp(cfg, "VerifySwap")      cfg.VerifySwap := 0
    if !HasProp(cfg, "SwapTimeoutMs")   cfg.SwapTimeoutMs := 800
    if !HasProp(cfg, "SwapRetry")       cfg.SwapRetry := 0
    if !HasProp(cfg, "GatesEnabled")    cfg.GatesEnabled := 0
    if !HasProp(cfg, "GateCooldownMs")  cfg.GateCooldownMs := 0
    if !HasProp(cfg, "BlackGuard")
        cfg.BlackGuard := { Enabled:1, SampleCount:5, BlackRatioThresh:0.7
                          , WindowMs:120, CooldownMs:600
                          , MinAfterSendMs:60, MaxAfterSendMs:800
                          , UniqueRequired:1 }
    if !HasProp(cfg, "Tracks") && HasProp(cfg, "Track1") {
        t1 := cfg.Track1, t2 := (HasProp(cfg,"Track2") ? cfg.Track2 : 0)
        cfg.Tracks := []
        if t1
            cfg.Tracks.Push(t1)
        if t2
            cfg.Tracks.Push(t2)
    }
}

; 轨道ID列表（若无 Tracks 则回退 [1,2]）
REUI_ListTrackIds(cfg) {
    ids := []
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length>0 {
            for _, t in cfg.Tracks
                ids.Push(t.Id)
            return ids
        }
    }
    ids.Push(1), ids.Push(2)
    return ids
}

; 线程名
REUI_ThreadNameById(id) {
    try {
        for _, th in App["ProfileData"].Threads
            if (th.Id = id)
                return th.Name
    }
    return (id=1) ? "默认线程" : "线程#" id
}

; 工具
REUI_IndexClamp(v, max) {
    v := Integer(v)
    max := Integer(max)
    return (max<=0) ? 0 : Min(Max(v,1), max)
}