#Requires AutoHotkey v2
; modules\ui\rotation\RE_UI_Common.ahk

REUI_CreateOwnedGui(title := "Rotation 配置") {
    global UI
    try {
        if IsSet(UI) && IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd {
            return Gui("+Owner" UI.Main.Hwnd, title)
        }
    } catch {
    }
    return Gui(, title)
}

REUI_EnsureRotationDefaults(&cfg) {
    if !IsObject(cfg) {
        cfg := {}
    }
    if !HasProp(cfg, "Enabled") {
        cfg.Enabled := 0
    }
    if !HasProp(cfg, "DefaultTrackId") {
        cfg.DefaultTrackId := 1
    }
    if !HasProp(cfg, "BusyWindowMs") {
        cfg.BusyWindowMs := 200
    }
    if !HasProp(cfg, "ColorTolBlack") {
        cfg.ColorTolBlack := 16
    }
    if !HasProp(cfg, "RespectCastLock") {
        cfg.RespectCastLock := 1
    }
    if !HasProp(cfg, "SwapKey") {
        cfg.SwapKey := ""
    }
    if !HasProp(cfg, "VerifySwap") {
        cfg.VerifySwap := 0
    }
    if !HasProp(cfg, "SwapTimeoutMs") {
        cfg.SwapTimeoutMs := 800
    }
    if !HasProp(cfg, "SwapRetry") {
        cfg.SwapRetry := 0
    }
    if !HasProp(cfg, "GatesEnabled") {
        cfg.GatesEnabled := 0
    }
    if !HasProp(cfg, "GateCooldownMs") {
        cfg.GateCooldownMs := 0
    }
    if !HasProp(cfg, "BlackGuard") {
        cfg.BlackGuard := { Enabled:1, SampleCount:5, BlackRatioThresh:0.7
                          , WindowMs:120, CooldownMs:600
                          , MinAfterSendMs:60, MaxAfterSendMs:800
                          , UniqueRequired:1 }
    }
    if !HasProp(cfg, "Tracks") && HasProp(cfg, "Track1") {
        t1 := cfg.Track1
        t2 := 0
        try {
            t2 := (HasProp(cfg,"Track2") ? cfg.Track2 : 0)
        } catch {
            t2 := 0
        }
        cfg.Tracks := []
        if t1 {
            cfg.Tracks.Push(t1)
        }
        if t2 {
            cfg.Tracks.Push(t2)
        }
    }
}

; 轨道ID列表：过滤 Id<=0；若无则回退 [1,2]
REUI_ListTrackIds(cfg) {
    ids := []
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length > 0 {
            for _, t in cfg.Tracks {
                idv := 0
                try {
                    idv := HasProp(t, "Id") ? Integer(t.Id) : 0
                } catch {
                    idv := 0
                }
                if (idv > 0) {
                    ids.Push(idv)
                }
            }
            if (ids.Length > 0) {
                return ids
            }
        }
    } catch {
    }

    ids.Push(1)
    ids.Push(2)
    return ids
}

REUI_ThreadNameById(id) {
    try {
        for _, th in App["ProfileData"].Threads {
            if (th.Id = id) {
                return th.Name
            }
        }
    } catch {
    }
    if (id = 1) {
        return "默认线程"
    }
    return "线程#" id
}

REUI_IndexClamp(v, vmax) {
    v := Integer(v)
    vmax := Integer(vmax)
    if (vmax <= 0) {
        return 0
    }
    if (v < 1) {
        return 1
    }
    if (v > vmax) {
        return vmax
    }
    return v
}

REUI_ArrayIndexOf(arr, value) {
    if (!IsObject(arr)) {
        return 0
    }
    for i, v in arr {
        same := false
        try {
            same := (Integer(v) = Integer(value))
        } catch {
            same := (v = value)
        }
        if (same) {
            return i
        }
    }
    return 0
}

REUI_ArrayContains(arr, value) {
    return REUI_ArrayIndexOf(arr, value) != 0
}