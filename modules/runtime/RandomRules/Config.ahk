#Requires AutoHotkey v2

; ini 读写：每 Profile 一份 Profiles\<ProfileName>\random_rules.ini
; 使用 FS_ModulePath 来统一路径

RandomRules_ConfigPath(profileName := "") {
    global App

    name := profileName
    if (name = "") {
        try {
            if IsObject(App) && App.Has("CurrentProfile") {
                name := App["CurrentProfile"]
            }
        } catch {
            name := ""
        }
    }

    if (name = "") {
        return ""
    }

    file := ""
    try {
        file := FS_ModulePath(name, "random_rules")
    } catch {
        file := ""
    }
    return file
}

RandomRules_LoadConfig(profileName := "") {
    global RR

    file := RandomRules_ConfigPath(profileName)
    if (file = "") {
        return
    }

    if !FileExist(file) {
        RandomRules_SaveConfig(profileName)
        if (profileName != "") {
            RR.ProfileName := profileName
        }
        return
    }

    try {
        mode := IniRead(file, "RandomRules", "RuleSelectMode", RR.Mode)
        if (mode != "") {
            RR.Mode := mode
        }
    } catch {
    }

    try {
        v := IniRead(file, "RandomRules", "RuleMinIntervalMs", RR.RuleMinMs)
        RR.RuleMinMs := Integer(v)
    } catch {
    }

    try {
        v := IniRead(file, "RandomRules", "RuleMaxIntervalMs", RR.RuleMaxMs)
        RR.RuleMaxMs := Integer(v)
    } catch {
    }

    try {
        v := IniRead(file, "RandomRules", "EnableRandomActionRand", RR.ActRandEnabled)
        RR.ActRandEnabled := Integer(v)
    } catch {
    }

    try {
        v := IniRead(file, "RandomRules", "ActionMinIntervalMs", RR.ActMinMs)
        RR.ActMinMs := Integer(v)
    } catch {
    }

    try {
        v := IniRead(file, "RandomRules", "ActionMaxIntervalMs", RR.ActMaxMs)
        RR.ActMaxMs := Integer(v)
    } catch {
    }

    ; 新增：启动延迟
    try {
        v := IniRead(file, "RandomRules", "StartDelayMs", RR.StartDelayMs)
        RR.StartDelayMs := Integer(v)
    } catch {
    }

    RandomRules_NormalizeRanges()

    if (profileName != "") {
        RR.ProfileName := profileName
    }

    try {
        Logger_Info("RandomRules", "ConfigLoaded", Map(
              "profile", RR.ProfileName
            , "Mode", RR.Mode
            , "RuleMinMs", RR.RuleMinMs
            , "RuleMaxMs", RR.RuleMaxMs
            , "ActRandEnabled", RR.ActRandEnabled
            , "ActMinMs", RR.ActMinMs
            , "ActMaxMs", RR.ActMaxMs
            , "StartDelayMs", RR.StartDelayMs
        ))
    } catch {
    }
}

RandomRules_SaveConfig(profileName := "") {
    global RR

    file := RandomRules_ConfigPath(profileName)
    if (file = "") {
        return
    }

    RandomRules_NormalizeRanges()

    try {
        IniWrite(RR.Mode,          file, "RandomRules", "RuleSelectMode")
    } catch {
    }
    try {
        IniWrite(RR.RuleMinMs,     file, "RandomRules", "RuleMinIntervalMs")
    } catch {
    }
    try {
        IniWrite(RR.RuleMaxMs,     file, "RandomRules", "RuleMaxIntervalMs")
    } catch {
    }
    try {
        IniWrite(RR.ActRandEnabled,file, "RandomRules", "EnableRandomActionRand")
    } catch {
    }
    try {
        IniWrite(RR.ActMinMs,      file, "RandomRules", "ActionMinIntervalMs")
    } catch {
    }
    try {
        IniWrite(RR.ActMaxMs,      file, "RandomRules", "ActionMaxIntervalMs")
    } catch {
    }
    try {
        IniWrite(RR.StartDelayMs,  file, "RandomRules", "StartDelayMs")
    } catch {
    }

    if (profileName != "") {
        RR.ProfileName := profileName
    }
}