#Requires AutoHotkey v2
; modules\ui\rotation\adapters\Rot_PageUtil.ahk
; 页面通用工具 + 无 ByRef 的 Ensure 实现（对象引用语义）

RotPU_CurrentProfileOrMsg() {
    global App
    if !IsSet(App) {
        MsgBox "未加载配置，无法保存。"
        return ""
    }
    if !App.Has("CurrentProfile") {
        MsgBox "未选择配置，无法保存。"
        return ""
    }
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置，无法保存。"
        return ""
    }
    return name
}

RotPU_GetRotationCfg() {
    global App
    if !IsSet(App) {
        return 0
    }
    if !App.Has("ProfileData") {
        return 0
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    try {
        REUI_Rotation_Ensure(cfg)
    } catch {
    }
    prof.Rotation := cfg
    return cfg
}

; ——— Ensure（无 ByRef） ———
RotPU_EnsureTracks(cfg) {
    if !IsObject(cfg) {
        return
    }
    if !HasProp(cfg, "Tracks") || !IsObject(cfg.Tracks) {
        cfg.Tracks := []
    }
    if (cfg.Tracks.Length = 0) {
        if HasProp(cfg, "Track1") {
            cfg.Tracks.Push(cfg.Track1)
        }
        if HasProp(cfg, "Track2") {
            cfg.Tracks.Push(cfg.Track2)
        }
    }
    if (cfg.Tracks.Length = 0) {
        cfg.Tracks.Push({ Id: 0, Name: "轨道1", ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [],
            RuleRefs: [] })
    }
}

RotPU_EnsureGates(cfg) {
    if !IsObject(cfg) {
        return
    }
    if (!HasProp(cfg, "Gates") || !IsObject(cfg.Gates)) {
        cfg.Gates := []
    }
    if (cfg.Gates.Length = 0) {
        cfg.Gates.Push({ Priority: 1, FromTrackId: 0, ToTrackId: 0, Logic: "AND", Conds: [] })
    }
    i := 1
    while (i <= cfg.Gates.Length) {
        g := cfg.Gates[i]
        if !HasProp(g, "Priority") {
            g.Priority := i
        }
        if !HasProp(g, "FromTrackId") {
            g.FromTrackId := 0
        }
        if !HasProp(g, "ToTrackId") {
            g.ToTrackId := 0
        }
        if !HasProp(g, "Logic") {
            g.Logic := "AND"
        }
        if !HasProp(g, "Conds") || !IsObject(g.Conds) {
            g.Conds := []
        }
        i := i + 1
    }
}

RotPU_EnsureOpener(cfg) {
    if !IsObject(cfg) {
        return
    }
    if !HasProp(cfg, "Opener") || !IsObject(cfg.Opener) {
        cfg.Opener := {}
    }
    if !HasProp(cfg.Opener, "Enabled") {
        cfg.Opener.Enabled := 0
    }
    if !HasProp(cfg.Opener, "MaxDurationMs") {
        cfg.Opener.MaxDurationMs := 4000
    }
    if !HasProp(cfg.Opener, "ThreadId") {
        cfg.Opener.ThreadId := 1
    }
    if !HasProp(cfg.Opener, "StepsCount") {
        cfg.Opener.StepsCount := 0
    }
    if !HasProp(cfg.Opener, "Watch") || !IsObject(cfg.Opener.Watch) {
        cfg.Opener.Watch := []
    }
    if !HasProp(cfg.Opener, "Steps") || !IsObject(cfg.Opener.Steps) {
        cfg.Opener.Steps := []
    }
}

; ——— 日志工具（UI 级） ———
RotPU_LogEnter(page) {
    try {
        prof := ""
        try {
            prof := App["CurrentProfile"]
        }
        Logger_Debug("UI." page, "enter", Map("page", page, "profile", prof))
    } catch {
    }
}
