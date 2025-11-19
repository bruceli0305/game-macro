#Requires AutoHotkey v2
; modules\storage\profile\Save_RotationBase.ahk 保存 Rotation 基础模块
; 依赖：OM_Get（modules\util\Obj.ahk）
; 严格块结构

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

    rot := Map()
    try {
        rot := profile["Rotation"]
    } catch {
        rot := Map()
    }

    ; 基础字段
    try {
        IniWrite(OM_Get(rot, "Enabled", 0),           tmp, "Rotation", "Enabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "DefaultTrackId", 0),    tmp, "Rotation", "DefaultTrackId")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "SwapKey", ""),          tmp, "Rotation", "SwapKey")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "BusyWindowMs", 200),    tmp, "Rotation", "BusyWindowMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "ColorTolBlack", 16),    tmp, "Rotation", "ColorTolBlack")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "RespectCastLock", 1),   tmp, "Rotation", "RespectCastLock")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "GatesEnabled", 0),      tmp, "Rotation", "GatesEnabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "GateCooldownMs", 0),    tmp, "Rotation", "GateCooldownMs")
    } catch {
    }

    ; Swap Verify
    sv := Map()
    try {
        sv := OM_Get(rot, "SwapVerify", Map())
    } catch {
        sv := Map()
    }
    try {
        IniWrite(OM_Get(sv, "RefType", "Skill"),      tmp, "Rotation.SwapVerify", "RefType")
    } catch {
    }
    try {
        IniWrite(OM_Get(sv, "RefId", 0),              tmp, "Rotation.SwapVerify", "RefId")
    } catch {
    }
    try {
        IniWrite(OM_Get(sv, "Op", "NEQ"),             tmp, "Rotation.SwapVerify", "Op")
    } catch {
    }
    try {
        IniWrite(OM_Get(sv, "Color", "0x000000"),     tmp, "Rotation.SwapVerify", "Color")
    } catch {
    }
    try {
        IniWrite(OM_Get(sv, "Tol", 16),               tmp, "Rotation.SwapVerify", "Tol")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "VerifySwap", 0),        tmp, "Rotation", "VerifySwap")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "SwapTimeoutMs", 800),   tmp, "Rotation", "SwapTimeoutMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(rot, "SwapRetry", 0),         tmp, "Rotation", "SwapRetry")
    } catch {
    }

    ; BlackGuard
    bg := Map()
    try {
        bg := OM_Get(rot, "BlackGuard", Map())
    } catch {
        bg := Map()
    }
    try {
        IniWrite(OM_Get(bg, "Enabled", 1),            tmp, "Rotation.BlackGuard", "Enabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "SampleCount", 5),        tmp, "Rotation.BlackGuard", "SampleCount")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "BlackRatioThresh", 0.7), tmp, "Rotation.BlackGuard", "BlackRatioThresh")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "WindowMs", 120),         tmp, "Rotation.BlackGuard", "WindowMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "CooldownMs", 600),       tmp, "Rotation.BlackGuard", "CooldownMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "MinAfterSendMs", 60),    tmp, "Rotation.BlackGuard", "MinAfterSendMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "MaxAfterSendMs", 800),   tmp, "Rotation.BlackGuard", "MaxAfterSendMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(bg, "UniqueRequired", 1),     tmp, "Rotation.BlackGuard", "UniqueRequired")
    } catch {
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_RotationBase(profileName, profile) {
    file := FS_ModulePath(profileName, "rotation_base")
    if !FileExist(file) {
        return
    }

    rot := Map()
    try {
        rot := profile["Rotation"]
    } catch {
        rot := Map()
    }

    ; 基础字段（以现有 rot 值作默认）
    try {
        rot["Enabled"] := Integer(IniRead(file, "Rotation", "Enabled", OM_Get(rot, "Enabled", 0)))
    } catch {
    }
    try {
        rot["DefaultTrackId"] := Integer(IniRead(file, "Rotation", "DefaultTrackId", OM_Get(rot, "DefaultTrackId", 0)))
    } catch {
    }
    try {
        rot["SwapKey"] := IniRead(file, "Rotation", "SwapKey", OM_Get(rot, "SwapKey", ""))
    } catch {
    }
    try {
        rot["BusyWindowMs"] := Integer(IniRead(file, "Rotation", "BusyWindowMs", OM_Get(rot, "BusyWindowMs", 200)))
    } catch {
    }
    try {
        rot["ColorTolBlack"] := Integer(IniRead(file, "Rotation", "ColorTolBlack", OM_Get(rot, "ColorTolBlack", 16)))
    } catch {
    }
    try {
        rot["RespectCastLock"] := Integer(IniRead(file, "Rotation", "RespectCastLock", OM_Get(rot, "RespectCastLock", 1)))
    } catch {
    }
    try {
        rot["GatesEnabled"] := Integer(IniRead(file, "Rotation", "GatesEnabled", OM_Get(rot, "GatesEnabled", 0)))
    } catch {
    }
    try {
        rot["GateCooldownMs"] := Integer(IniRead(file, "Rotation", "GateCooldownMs", OM_Get(rot, "GateCooldownMs", 0)))
    } catch {
    }

    ; SwapVerify
    sv := Map()
    try {
        sv := OM_Get(rot, "SwapVerify", Map())
    } catch {
        sv := Map()
    }
    try {
        sv["RefType"] := IniRead(file, "Rotation.SwapVerify", "RefType", OM_Get(sv, "RefType", "Skill"))
    } catch {
    }
    try {
        sv["RefId"] := Integer(IniRead(file, "Rotation.SwapVerify", "RefId", OM_Get(sv, "RefId", 0)))
    } catch {
    }
    try {
        sv["Op"] := IniRead(file, "Rotation.SwapVerify", "Op", OM_Get(sv, "Op", "NEQ"))
    } catch {
    }
    try {
        sv["Color"] := IniRead(file, "Rotation.SwapVerify", "Color", OM_Get(sv, "Color", "0x000000"))
    } catch {
    }
    try {
        sv["Tol"] := Integer(IniRead(file, "Rotation.SwapVerify", "Tol", OM_Get(sv, "Tol", 16)))
    } catch {
    }
    try {
        rot["SwapVerify"] := sv
    } catch {
    }

    ; 其它 swap 选项
    try {
        rot["VerifySwap"] := Integer(IniRead(file, "Rotation", "VerifySwap", OM_Get(rot, "VerifySwap", 0)))
    } catch {
    }
    try {
        rot["SwapTimeoutMs"] := Integer(IniRead(file, "Rotation", "SwapTimeoutMs", OM_Get(rot, "SwapTimeoutMs", 800)))
    } catch {
    }
    try {
        rot["SwapRetry"] := Integer(IniRead(file, "Rotation", "SwapRetry", OM_Get(rot, "SwapRetry", 0)))
    } catch {
    }

    ; BlackGuard
    bg := Map()
    try {
        bg := OM_Get(rot, "BlackGuard", Map())
    } catch {
        bg := Map()
    }
    try {
        bg["Enabled"] := Integer(IniRead(file, "Rotation.BlackGuard", "Enabled", OM_Get(bg, "Enabled", 1)))
    } catch {
    }
    try {
        bg["SampleCount"] := Integer(IniRead(file, "Rotation.BlackGuard", "SampleCount", OM_Get(bg, "SampleCount", 5)))
    } catch {
    }
    try {
        bg["BlackRatioThresh"] := (IniRead(file, "Rotation.BlackGuard", "BlackRatioThresh", OM_Get(bg, "BlackRatioThresh", 0.7)) + 0)
    } catch {
    }
    try {
        bg["WindowMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "WindowMs", OM_Get(bg, "WindowMs", 120)))
    } catch {
    }
    try {
        bg["CooldownMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "CooldownMs", OM_Get(bg, "CooldownMs", 600)))
    } catch {
    }
    try {
        bg["MinAfterSendMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "MinAfterSendMs", OM_Get(bg, "MinAfterSendMs", 60)))
    } catch {
    }
    try {
        bg["MaxAfterSendMs"] := Integer(IniRead(file, "Rotation.BlackGuard", "MaxAfterSendMs", OM_Get(bg, "MaxAfterSendMs", 800)))
    } catch {
    }
    try {
        bg["UniqueRequired"] := Integer(IniRead(file, "Rotation.BlackGuard", "UniqueRequired", OM_Get(bg, "UniqueRequired", 1)))
    } catch {
    }
    try {
        rot["BlackGuard"] := bg
    } catch {
    }

    try {
        profile["Rotation"] := rot
    } catch {
    }
}