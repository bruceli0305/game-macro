#Requires AutoHotkey v2
; 保存 Rotation 基础配置（常规页）：落盘+重载+重建（统一日志）

Rot_SaveBase(profileName, cfg) {
    global App

    if !(IsSet(profileName) && profileName != "") {
        try {
            Logger_Error("RotationBase", "save_begin_fail", Map("reason", "empty_profile"))
        } catch {
        }
        return false
    }

    t0 := A_TickCount
    try {
        Logger_Info("RotationBase", "save_begin", Map("profile", profileName))
    } catch {
    }

    p := 0
    try {
        p := Storage_Profile_LoadFull(profileName)
    } catch as e {
        try {
            Logger_Exception("RotationBase", e, Map("when", "load_full", "profile", profileName))
        } catch {
        }
        return false
    }

    ; 确保默认值
    try {
        REUI_Rotation_Ensure(cfg)
    } catch {
    }

    ; 构造文件夹模型 rot
    rot := Map()
    rot["Enabled"]        := OM_Get(cfg, "Enabled", 0)
    rot["DefaultTrackId"] := OM_Get(cfg, "DefaultTrackId", 0)
    rot["SwapKey"]        := OM_Get(cfg, "SwapKey", "")
    rot["BusyWindowMs"]   := OM_Get(cfg, "BusyWindowMs", 200)
    rot["ColorTolBlack"]  := OM_Get(cfg, "ColorTolBlack", 16)
    rot["RespectCastLock"]:= OM_Get(cfg, "RespectCastLock", 1)
    rot["GatesEnabled"]   := OM_Get(cfg, "GatesEnabled", 0)
    rot["GateCooldownMs"] := OM_Get(cfg, "GateCooldownMs", 0)

    ; SwapVerify + 其它 swap
    sv := Map()
    sv0 := OM_Get(cfg, "SwapVerify", Map())
    sv["RefType"] := OM_Get(sv0, "RefType", "Skill")
    sv["RefId"]   := OM_Get(sv0, "RefId", 0)
    sv["Op"]      := OM_Get(sv0, "Op", "NEQ")
    sv["Color"]   := OM_Get(sv0, "Color", "0x000000")
    sv["Tol"]     := OM_Get(sv0, "Tol", 16)
    rot["SwapVerify"] := sv
    rot["VerifySwap"]    := OM_Get(cfg, "VerifySwap", 0)
    rot["SwapTimeoutMs"] := OM_Get(cfg, "SwapTimeoutMs", 800)
    rot["SwapRetry"]     := OM_Get(cfg, "SwapRetry", 0)

    ; BlackGuard
    bg := Map()
    bg0 := OM_Get(cfg, "BlackGuard", Map())
    bg["Enabled"]          := OM_Get(bg0, "Enabled", 1)
    bg["SampleCount"]      := OM_Get(bg0, "SampleCount", 5)
    bg["BlackRatioThresh"] := OM_Get(bg0, "BlackRatioThresh", 0.7)
    bg["WindowMs"]         := OM_Get(bg0, "WindowMs", 120)
    bg["CooldownMs"]       := OM_Get(bg0, "CooldownMs", 600)
    bg["MinAfterSendMs"]   := OM_Get(bg0, "MinAfterSendMs", 60)
    bg["MaxAfterSendMs"]   := OM_Get(bg0, "MaxAfterSendMs", 800)
    bg["UniqueRequired"]   := OM_Get(bg0, "UniqueRequired", 1)
    rot["BlackGuard"] := bg

    ; 调试值
    try {
        Logger_Debug("RotationBase", "values", Map(
            "enabled", OM_Get(rot,"Enabled",0)
          , "default_track_id", OM_Get(rot,"DefaultTrackId",0)
          , "swap_key", OM_Get(rot,"SwapKey","")
          , "busy_ms", OM_Get(rot,"BusyWindowMs",200)
          , "tol_black", OM_Get(rot,"ColorTolBlack",16)
          , "respect_cast", OM_Get(rot,"RespectCastLock",1)
          , "gates_enabled", OM_Get(rot,"GatesEnabled",0)
          , "gate_cd", OM_Get(rot,"GateCooldownMs",0)
        ))
    } catch {
    }

    ; 写文件
    ok := false
    try {
        p["Rotation"] := rot
        SaveModule_RotationBase(p)
        ok := true
    } catch as e2 {
        ok := false
        try {
            Logger_Exception("RotationBase", e2, Map("when", "save", "profile", profileName))
        } catch {
        }
    }
    if (!ok) {
        return false
    }

    try {
        Logger_Info("Storage", "save_ok", Map("module", "rotation_base", "profile", profileName, "elapsed_ms", A_TickCount - t0))
    } catch {
    }

    ; Reload + 引擎重建
    t1 := A_TickCount
    try {
        p2 := Storage_Profile_LoadFull(profileName)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        try {
            RE_OnProfileDataReplaced(App["ProfileData"])
        } catch {
        }
        Logger_Info("Runtime", "reload_ok", Map("profile", profileName, "elapsed_ms", A_TickCount - t1))
    } catch as e3 {
        try {
            Logger_Exception("RotationBase", e3, Map("when","reload","profile",profileName))
        } catch {
        }
        return false
    }

    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
        Logger_Info("RotationBase", "runtime_reset", Map("actions", "Rotation_Reset,Rotation_InitFromProfile"))
    } catch {
    }

    return true
}