; RuleEngine_Log.ahk - 日志/提示

RE_Tip(msg, ms := 1000) {
    global RE_ShowTips
    if !RE_ShowTips {
        return
    }
    ToolTip msg
    SetTimer () => ToolTip(), -ms
}

RE_LogFilePath() {
    return A_ScriptDir "\Logs\ruleengine.log"
}
RE_Log(msg, level := "INFO") {
    global RE_Debug
    if !RE_Debug {
        return
    }
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend ts " [RuleEngine] [" level "] " msg "`r`n", RE_LogFilePath(), "UTF-8"
}
RE_LogV(msg) {
    global RE_DebugVerbose
    if RE_DebugVerbose {
        RE_Log(msg, "VERB")
    }
}