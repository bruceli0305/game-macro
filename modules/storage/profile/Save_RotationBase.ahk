#Requires AutoHotkey v2
;modules\storage\profile\Save_RotationBase.ahk 保存 RotationBase 模块
SaveModule_RotationBase(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rotation_base")
    tmp := FS_AtomicBegin(file)

    rot := profile["Rotation"]

    ; 基础
    IniWrite(rot.Has("Enabled") ? rot["Enabled"] : 0, tmp, "Rotation", "Enabled")
    IniWrite(rot.Has("DefaultTrackId") ? rot["DefaultTrackId"] : 0, tmp, "Rotation", "DefaultTrackId")
    IniWrite(rot.Has("SwapKey") ? rot["SwapKey"] : "", tmp, "Rotation", "SwapKey")
    IniWrite(rot.Has("BusyWindowMs") ? rot["BusyWindowMs"] : 200, tmp, "Rotation", "BusyWindowMs")
    IniWrite(rot.Has("ColorTolBlack") ? rot["ColorTolBlack"] : 16, tmp, "Rotation", "ColorTolBlack")
    IniWrite(rot.Has("RespectCastLock") ? rot["RespectCastLock"] : 1, tmp, "Rotation", "RespectCastLock")
    IniWrite(rot.Has("GatesEnabled") ? rot["GatesEnabled"] : 0, tmp, "Rotation", "GatesEnabled")
    IniWrite(rot.Has("GateCooldownMs") ? rot["GateCooldownMs"] : 0, tmp, "Rotation", "GateCooldownMs")

    ; Swap Verify
    sv := Map()
    try {
        sv := rot["SwapVerify"]
    } catch {
        sv := Map()
    }
    IniWrite(sv.Has("RefType") ? sv["RefType"] : "Skill", tmp, "Rotation.SwapVerify", "RefType")
    IniWrite(sv.Has("RefId") ? sv["RefId"] : 0, tmp, "Rotation.SwapVerify", "RefId")
    IniWrite(sv.Has("Op") ? sv["Op"] : "NEQ", tmp, "Rotation.SwapVerify", "Op")
    IniWrite(sv.Has("Color") ? sv["Color"] : "0x000000", tmp, "Rotation.SwapVerify", "Color")
    IniWrite(sv.Has("Tol") ? sv["Tol"] : 16, tmp, "Rotation.SwapVerify", "Tol")
    IniWrite(rot.Has("VerifySwap") ? rot["VerifySwap"] : 0, tmp, "Rotation", "VerifySwap")
    IniWrite(rot.Has("SwapTimeoutMs") ? rot["SwapTimeoutMs"] : 800, tmp, "Rotation", "SwapTimeoutMs")
    IniWrite(rot.Has("SwapRetry") ? rot["SwapRetry"] : 0, tmp, "Rotation", "SwapRetry")

    ; BlackGuard
    bg := Map()
    try {
        bg := rot["BlackGuard"]
    } catch {
        bg := Map()
    }
    IniWrite(bg.Has("Enabled") ? bg["Enabled"] : 1, tmp, "Rotation.BlackGuard", "Enabled")
    IniWrite(bg.Has("SampleCount") ? bg["SampleCount"] : 5, tmp, "Rotation.BlackGuard", "SampleCount")
    IniWrite(bg.Has("BlackRatioThresh") ? bg["BlackRatioThresh"] : 0.7, tmp, "Rotation.BlackGuard", "BlackRatioThresh")
    IniWrite(bg.Has("WindowMs") ? bg["WindowMs"] : 120, tmp, "Rotation.BlackGuard", "WindowMs")
    IniWrite(bg.Has("CooldownMs") ? bg["CooldownMs"] : 600, tmp, "Rotation.BlackGuard", "CooldownMs")
    IniWrite(bg.Has("MinAfterSendMs") ? bg["MinAfterSendMs"] : 60, tmp, "Rotation.BlackGuard", "MinAfterSendMs")
    IniWrite(bg.Has("MaxAfterSendMs") ? bg["MaxAfterSendMs"] : 800, tmp, "Rotation.BlackGuard", "MaxAfterSendMs")
    IniWrite(bg.Has("UniqueRequired") ? bg["UniqueRequired"] : 1, tmp, "Rotation.BlackGuard", "UniqueRequired")

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_RotationBase(profileName, profile) {
    file := FS_ModulePath(profileName, "rotation_base")
    if !FileExist(file) {
        return
    }

    rot := profile["Rotation"]
    try {
        rot["Enabled"] := Integer(IniRead(file, "Rotation", "Enabled", rot["Enabled"]))
    } catch {
    }
    try {
        rot["DefaultTrackId"] := Integer(IniRead(file, "Rotation", "DefaultTrackId", rot["DefaultTrackId"]))
    } catch {
    }
    try {
        rot["SwapKey"] := IniRead(file, "Rotation", "SwapKey", rot["SwapKey"])
    } catch {
    }
    try {
        rot["BusyWindowMs"] := Integer(IniRead(file, "Rotation", "BusyWindowMs", rot["BusyWindowMs"]))
    } catch {
    }
    try {
        rot["ColorTolBlack"] := Integer(IniRead(file, "Rotation", "ColorTolBlack", rot["ColorTolBlack"]))
    } catch {
    }
    try {
        rot["RespectCastLock"] := Integer(IniRead(file, "Rotation", "RespectCastLock", rot["RespectCastLock"]))
    } catch {
    }
    try {
        rot["GatesEnabled"] := Integer(IniRead(file, "Rotation", "GatesEnabled", rot["GatesEnabled"]))
    } catch {
    }
    try {
        rot["GateCooldownMs"] := Integer(IniRead(file, "Rotation", "GateCooldownMs", rot["GateCooldownMs"]))
    } catch {
    }

    sv := rot["SwapVerify"]
    try {
        sv["RefType"] := IniRead(file, "Rotation.SwapVerify", "RefType", sv["RefType"])
    } catch {
    }
    try {
        sv["RefId"] := Integer(IniRead(file, "Rotation.SwapVerify", "RefId", sv["RefId"]))
    } catch {
    }
    try {
        sv["Op"] := IniRead(file, "Rotation.SwapVerify", "Op", sv["Op"])
    } catch {
    }
    try {
        sv["Color"] := IniRead(file, "Rotation.SwapVerify", "Color", sv["Color"])
    } catch {
    }
    try {
        sv["Tol"] := Integer(IniRead(file, "Rotation.SwapVerify", "Tol", sv["Tol"]))
    } catch {
    }
    rot["SwapVerify"] := sv

    try {
        rot["VerifySwap"] := Integer(IniRead(file, "Rotation", "VerifySwap", rot["VerifySwap"]))
    } catch {
    }
    try {
        rot["SwapTimeoutMs"] := Integer(IniRead(file, "Rotation", "SwapTimeoutMs", rot["SwapTimeoutMs"]))
    } catch {
    }
    try {
        rot["SwapRetry"] := Integer(IniRead(file, "Rotation", "SwapRetry", rot["SwapRetry"]))
    } catch {
    }

    bg := rot["BlackGuard"]
    try {
        bg["Enabled"] := Integer(IniRead(file, "Rotation.BlackGuard", "Enabled", bg["Enabled"]))
    } catch {
    }
    try {
        bg["SampleCount"] := Integer(IniRead(file, "Rotation.BlackGuard", "SampleCount", bg["SampleCount"]))
    } catch {
    }
    try {
        bg["BlackRatioThresh"] := (IniRead(file, "Rotation.BlackGuard", "BlackRatioThresh", bg["BlackRatioThresh"]) + 0)
    } catch {
    }
    try {
        bg["WindowMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "WindowMs", bg["WindowMs"]))
    } catch {
    }
    try {
        bg["CooldownMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "CooldownMs", bg["CooldownMs"]))
    } catch {
    }
    try {
        bg["MinAfterSendMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "MinAfterSendMs", bg["MinAfterSendMs"]))
    } catch {
    }
    try {
        bg["MaxAfterSendMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "MaxAfterSendMs", bg["MaxAfterSendMs"]))
    } catch {
    }
    try {
        bg["UniqueRequired"] := Integer(IniRead(file, "Rotation.BlackGuard", "UniqueRequired", bg["UniqueRequired"]))
    } catch {
    }
    rot["BlackGuard"] := bg

    profile["Rotation"] := rot
}