#Requires AutoHotkey v2
;modules\ui\rotation\components\common\REUI_Tools.ahk
; 通用工具（供 Tracks/Gates/Opener 复用）
; 严格块结构，禁止单行 if/try/catch，禁止 ByRef

REUI_CreateOwnedGui(title := "Rotation 配置") {
    global UI
    try {
        if (IsSet(UI) && IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd) {
            return Gui("+Owner" UI.Main.Hwnd, title)
        }
    } catch {
    }
    return Gui(, title)
}

; clamp 到 [1, vmax]；若 vmax<=0 则返回 0
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

; 通用技能名
REUI_SkillName(idx) {
    try {
        if (idx >= 1 && IsSet(App) && App.Has("ProfileData")
        && HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)
        && idx <= App["ProfileData"].Skills.Length) {
            return App["ProfileData"].Skills[idx].Name
        }
    } catch {
    }
    return "技能#" idx
}

; 为兼容保留（Opener 用到）
REUI_Opener_SkillName(idx) {
    return REUI_SkillName(idx)
}

; 轨道 ID 列表；过滤 Id<=0；若无则回退 [1,2]
REUI_ListTrackIds(cfg) {
    ids := []
    try {
        if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length > 0) {
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

; Rotation 基本默认值（无 ByRef 版本）
REUI_Rotation_Ensure(cfg) {
    if (!IsObject(cfg)) {
        cfg := {}
    }
    if (!HasProp(cfg, "Enabled")) {
        cfg.Enabled := 0
    }
    if (!HasProp(cfg, "DefaultTrackId")) {
        cfg.DefaultTrackId := 1
    }
    if (!HasProp(cfg, "BusyWindowMs")) {
        cfg.BusyWindowMs := 200
    }
    if (!HasProp(cfg, "ColorTolBlack")) {
        cfg.ColorTolBlack := 16
    }
    if (!HasProp(cfg, "RespectCastLock")) {
        cfg.RespectCastLock := 1
    }
    if (!HasProp(cfg, "SwapKey")) {
        cfg.SwapKey := ""
    }
    if (!HasProp(cfg, "VerifySwap")) {
        cfg.VerifySwap := 0
    }
    if (!HasProp(cfg, "SwapTimeoutMs")) {
        cfg.SwapTimeoutMs := 800
    }
    if (!HasProp(cfg, "SwapRetry")) {
        cfg.SwapRetry := 0
    }
    if (!HasProp(cfg, "GatesEnabled")) {
        cfg.GatesEnabled := 0
    }
    if (!HasProp(cfg, "GateCooldownMs")) {
        cfg.GateCooldownMs := 0
    }
    if (!HasProp(cfg, "BlackGuard")) {
        cfg.BlackGuard := { Enabled:1, SampleCount:5, BlackRatioThresh:0.7
                          , WindowMs:120, CooldownMs:600
                          , MinAfterSendMs:60, MaxAfterSendMs:800
                          , UniqueRequired:1 }
    }
    if (!HasProp(cfg, "Tracks") && HasProp(cfg, "Track1")) {
        t1 := cfg.Track1
        t2 := 0
        try {
            t2 := (HasProp(cfg, "Track2") ? cfg.Track2 : 0)
        } catch {
            t2 := 0
        }
        cfg.Tracks := []
        if (t1) {
            cfg.Tracks.Push(t1)
        }
        if (t2) {
            cfg.Tracks.Push(t2)
        }
    }
    return cfg
}

; 兼容旧名（移除 ByRef）
REUI_EnsureRotationDefaults(cfg) {
    return REUI_Rotation_Ensure(cfg)
}
; 确保 Profile 的 IdMap 构建好（用 PM_BuildIdMaps）
REUI_EnsureIdMaps() {
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            pd := App["ProfileData"]
            need := true
            try {
                need := (!pd.Has("IdMap")) || (!IsObject(pd["IdMap"])) || (pd["IdMap"].Count = 0)
            } catch {
                need := true
            }
            if (need) {
                PM_BuildIdMaps(pd)
            }
        }
    } catch {
    }
}

; 通过 index 取技能 Id（Index -> Id）
REUI_SkillIdByIndex(idx) {
    try {
        if (IsSet(App) && App.Has("ProfileData")
        && HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
            if (idx >= 1 && idx <= App["ProfileData"].Skills.Length) {
                sk := App["ProfileData"].Skills[idx]
                sid := 0
                try {
                    sid := HasProp(sk, "Id") ? sk.Id : 0
                } catch {
                    sid := 0
                }
                if (sid = 0) {
                    try {
                        sid := sk["Id"]
                    } catch {
                        sid := 0
                    }
                }
                return sid
            }
        }
    } catch {
    }
    return 0
}

; 通过 Id 查找技能在数组中的 index（优先用 PM_*，否则回退扫描）
REUI_SkillIndexById(id) {
    if (id <= 0) {
        return 0
    }
    REUI_EnsureIdMaps()
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            pd := App["ProfileData"]
            ; 优先用 PM 映射（O(1)）
            idxPM := 0
            try {
                idxPM := PM_SkillIndexById(pd, id)
            } catch {
                idxPM := 0
            }
            if (idxPM > 0) {
                return idxPM
            }
            ; 回退扫描
            if (HasProp(pd, "Skills") && IsObject(pd.Skills)) {
                i := 1
                while (i <= pd.Skills.Length) {
                    sk := pd.Skills[i]
                    sid := 0
                    try {
                        sid := HasProp(sk, "Id") ? sk.Id : 0
                    } catch {
                        sid := 0
                    }
                    if (sid = 0) {
                        try {
                            sid := sk["Id"]
                        } catch {
                            sid := 0
                        }
                    }
                    if (sid = id) {
                        return i
                    }
                    i := i + 1
                }
            }
        }
    } catch {
    }
    return 0
}

; 通过 Id 取名称（找不到回退“技能#id”）
REUI_SkillNameById(id) {
    idx := 0
    try {
        idx := REUI_SkillIndexById(id)
    } catch {
        idx := 0
    }
    if (idx >= 1) {
        return REUI_SkillName(idx)
    }
    return "技能#" id
}
; 通过 Id 取轨道名称；找不到时回退“轨道#id”
REUI_TrackNameById(cfg, id) {
    if (!IsObject(cfg)) {
        return "轨道#" id
    }
    try {
        if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks)) {
            for _, t in cfg.Tracks {
                tid := 0
                try {
                    tid := HasProp(t, "Id") ? Integer(t.Id) : 0
                } catch {
                    tid := 0
                }
                if (tid = Integer(id)) {
                    nm := ""
                    try {
                        nm := HasProp(t, "Name") ? t.Name : ""
                    } catch {
                        nm := ""
                    }
                    if (nm != "") {
                        return nm
                    } else {
                        return "轨道#" id
                    }
                }
            }
        }
    } catch {
    }
    return "轨道#" id
}

; 用于下拉框显示的标签：[id] 名称
REUI_TrackLabelById(cfg, id) {
    nm := ""
    try {
        nm := REUI_TrackNameById(cfg, id)
    } catch {
        nm := "轨道#" id
    }
    return "[" id "] " nm
}