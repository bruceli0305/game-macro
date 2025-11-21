; modules\runtime\Hotkeys.ahk - 热键绑定/切换
Hotkeys_BindStartHotkey(hk) {
    global App
    hk := Trim(hk)
    ; 为鼠标键自动加“~”前缀（穿透，不阻断原点击）
    bind := hk
    if (hk != "") {
        if RegExMatch(hk, "i)^(XButton1|XButton2|MButton)$") {
            if (SubStr(hk, 1, 1) != "~")
                bind := "~" hk
        }
    }
    ; 解绑旧的
    try {
        if App["BoundHotkeys"].Has("Start") {
            old := App["BoundHotkeys"]["Start"]
            Hotkey old, "Off"
        }
    }
    ; 记录本次实际绑定串（用于下次解绑）
    App["BoundHotkeys"]["Start"] := bind
    ; 绑定新的
    if (bind != "") {
        Hotkey bind, Hotkeys_ToggleRunning, "On"
    }
}

Hotkeys_ToggleRunning(*) {
    if Poller_IsRunning()
        Poller_Stop()
    else
        Poller_Start()
}