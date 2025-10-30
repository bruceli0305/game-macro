; Utils.ahk - 常用工具函数
Notify(msg, ms := 1200) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

Confirm(msg) {
    return MsgBox(msg, , "YesNo") = "Yes"
}