; RuleEngine_Log.ahk - 日志/提示

RE_Tip(msg, ms := 1000) {
    global RE_ShowTips
    if !RE_ShowTips {
        return
    }
    ToolTip msg
    SetTimer () => ToolTip(), -ms
}