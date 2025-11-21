#Requires AutoHotkey v2

; AppConfig - 程序级配置（独立于 Profile）
global gAppCfg := Map()

AppConfig_Init() {
    global App, gAppCfg
    if !IsSet(App)
        App := Map()
    App["ConfigDir"] := A_ScriptDir "\Config"
    DirCreate(App["ConfigDir"])
    App["AppConfigPath"] := App["ConfigDir"] "\AppConfig.ini"

    ; 默认值
    gAppCfg := Map("Language", "zh-CN")

    gAppCfg["Logging"] := Map()
    gAppCfg["Logging"]["Level"] := "INFO"
    gAppCfg["Logging"]["RotateSizeMB"] := 10
    gAppCfg["Logging"]["RotateKeep"] := 5
    gAppCfg["Logging"]["PerCategory"] := ""          ; 形如 "RuleEngine=DEBUG,DXGI=INFO"
    gAppCfg["Logging"]["ThrottlePerSec"] := 5

    if FileExist(App["AppConfigPath"]) {
        try {
            lang := IniRead(App["AppConfigPath"], "General", "Language", gAppCfg["Language"])
            version := IniRead(App["AppConfigPath"], "General", "Version", gAppCfg["Version"])
            gAppCfg["Version"] := version
            gAppCfg["Language"] := lang
        } catch {
        }
        ; 读取
        try {
            lv := IniRead(App["AppConfigPath"], "Logging", "Level", gAppCfg["Logging"]["Level"])
            gAppCfg["Logging"]["Level"] := lv
        } catch {
        }
        try {
            rs := IniRead(App["AppConfigPath"], "Logging", "RotateSizeMB", gAppCfg["Logging"]["RotateSizeMB"])
            gAppCfg["Logging"]["RotateSizeMB"] := Integer(rs)
        } catch {
        }
        try {
            rk := IniRead(App["AppConfigPath"], "Logging", "RotateKeep", gAppCfg["Logging"]["RotateKeep"])
            gAppCfg["Logging"]["RotateKeep"] := Integer(rk)
        } catch {
        }
        try {
            pc := IniRead(App["AppConfigPath"], "Logging", "PerCategory", gAppCfg["Logging"]["PerCategory"])
            gAppCfg["Logging"]["PerCategory"] := pc
        } catch {
        }
        try {
            tp := IniRead(App["AppConfigPath"], "Logging", "ThrottlePerSec", gAppCfg["Logging"]["ThrottlePerSec"])
            gAppCfg["Logging"]["ThrottlePerSec"] := Integer(tp)
        } catch {
        }
    } else {
        AppConfig_Save()
    }
}

AppConfig_Save() {
    global App, gAppCfg
    IniWrite(gAppCfg["Language"], App["AppConfigPath"], "General", "Language")
    try {
        IniWrite(gAppCfg["Logging"]["Level"], App["AppConfigPath"], "Logging", "Level")
    } catch {
    }
    try {
        IniWrite(gAppCfg["Logging"]["RotateSizeMB"], App["AppConfigPath"], "Logging", "RotateSizeMB")
    } catch {
    }
    try {
        IniWrite(gAppCfg["Logging"]["RotateKeep"], App["AppConfigPath"], "Logging", "RotateKeep")
    } catch {
    }
    try {
        IniWrite(gAppCfg["Logging"]["PerCategory"], App["AppConfigPath"], "Logging", "PerCategory")
    } catch {
    }
    try {
        IniWrite(gAppCfg["Logging"]["ThrottlePerSec"], App["AppConfigPath"], "Logging", "ThrottlePerSec")
    } catch {
    }
}

AppConfig_Get(key, def := "") {
    global gAppCfg
    return gAppCfg.Has(key) ? gAppCfg[key] : def
}

AppConfig_Set(key, value) {
    global gAppCfg
    gAppCfg[key] := value
}

; 读取 Logging 分组下的键；若不存在则返回 def
AppConfig_GetLog(key, def := "") {
    global gAppCfg

    if !IsObject(gAppCfg) {
        return def
    }
    if !gAppCfg.Has("Logging") {
        return def
    }

    val := def
    try {
        if gAppCfg["Logging"].Has(key) {
            val := gAppCfg["Logging"][key]
        }
    } catch {
        val := def
    }
    return val
}

; 设置 Logging 分组的键值（仅写入内存；落盘请调用 AppConfig_Save）
AppConfig_SetLog(key, value) {
    global gAppCfg

    if !IsObject(gAppCfg) {
        gAppCfg := Map()
    }
    if !gAppCfg.Has("Logging") {
        gAppCfg["Logging"] := Map()
    }
    gAppCfg["Logging"][key] := value
}