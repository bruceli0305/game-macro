; Utils.ahk - 常用工具函数
Notify(msg, ms := 1200) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

Confirm(msg) {
    return MsgBox(msg, , "YesNo") = "Yes"
}

; 让主窗口获得焦点与前台激活
UI_ActivateMain() {
    try {
        global UI
        if IsObject(UI) && HasProp(UI, "Main") && UI.Main && UI.Main.Hwnd {
            WinActivate "ahk_id " UI.Main.Hwnd
            DllCall("user32\SetForegroundWindow", "ptr", UI.Main.Hwnd)
        }
    }
}