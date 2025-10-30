; Hotkeys.ahk - 热键绑定/切换
Hotkeys_BindStartHotkey(hk) {
    global App
    try {
        if App["BoundHotkeys"].Has("Start") {
            old := App["BoundHotkeys"]["Start"]
            Hotkey old, "Off"
        }
    }
    App["BoundHotkeys"]["Start"] := hk
    if hk != "" {
        Hotkey hk, Hotkeys_ToggleRunning, "On"
    }
}

Hotkeys_ToggleRunning(*) {
    if Poller_IsRunning()
        Poller_Stop()
    else
        Poller_Start()
}