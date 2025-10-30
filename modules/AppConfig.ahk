#Requires AutoHotkey v2

; AppConfig - 程序级配置（独立于 Profile）
global gAppCfg := Map()

AppConfig_Init() {
    global App, gAppCfg
    if !IsSet(App)
        global App := Map()
    App["ConfigDir"] := A_ScriptDir "\Config"
    DirCreate(App["ConfigDir"])
    App["AppConfigPath"] := App["ConfigDir"] "\AppConfig.ini"

    ; 默认值
    gAppCfg := Map("Language", "zh-CN")

    if FileExist(App["AppConfigPath"]) {
        try {
            lang := IniRead(App["AppConfigPath"], "General", "Language", gAppCfg["Language"])
            gAppCfg["Language"] := lang
        } catch {
            ; 忽略读取异常，使用默认
        }
    } else {
        AppConfig_Save()
    }
}

AppConfig_Save() {
    global App, gAppCfg
    IniWrite(gAppCfg["Language"], App["AppConfigPath"], "General", "Language")
}

AppConfig_Get(key, def := "") {
    global gAppCfg
    return gAppCfg.Has(key) ? gAppCfg[key] : def
}

AppConfig_Set(key, value) {
    global gAppCfg
    gAppCfg[key] := value
}