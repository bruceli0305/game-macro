; Utils.ahk - 常用工具函数
Notify(msg, ms := 1200) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

Confirm(msg) {
    return MsgBox(msg, , "YesNo") = "Yes"
}

; 顶层兜底，确保 UI 在解析期已被赋值（后续 UI_Framework 会把它置为 Map）
if !IsSet(UI) {
    UI := Map()
}

UI_ActivateMain() {
    global UI
    try {
        if IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd {
            hwnd := UI.Main.Hwnd
            try {
                WinActivate "ahk_id " hwnd
            } catch {
            }
            try {
                DllCall("user32\SetForegroundWindow", "ptr", hwnd)
            } catch {
            }
        }
    } catch {
    }
}
global HP_Timer := { Inited: false, Freq: 0 }

HP_Init() {
    if HP_Timer.Inited
        return
    ; 全局提升系统定时器精度到 1ms
    DllCall("winmm\timeBeginPeriod", "UInt", 1)
    HP_Timer.Inited := true

    ; 正确写法：先声明局部变量，再用 & 取地址
    freq := 0
    DllCall("QueryPerformanceFrequency", "Int64*", &freq)
    HP_Timer.Freq := freq
}

HighPrecisionDelay(ms) {
    if !HP_Timer.Inited
        HP_Init()

    if (ms <= 0)
        return

    ; 长延迟用 Sleep 扛大头，短延迟用 QPC 精确补足
    if (ms > 38) {
        Sleep(ms - 18)        ; 预留 18ms 给 QPC 补
        ms := 18
    }
    if (ms <= 0)
        return

    ; QPC 忙等（局部变量才能 &）
    start := 0
    DllCall("QueryPerformanceCounter", "Int64*", &start)
    target := start + Integer(HP_Timer.Freq * ms / 1000.0 + 0.5)

    loop {
        cur := 0
        DllCall("QueryPerformanceCounter", "Int64*", &cur)
        if (cur >= target)
            break
        ; 剩余时间 > 0.25ms 时让出时间片，防止 100% 单核
        if (cur + HP_Timer.Freq // 4000 < target)
            Sleep 1
    }
}

HP_OnExit(*) {
    if HP_Timer.Inited
        DllCall("winmm\timeEndPeriod", "UInt", 1)
}
OnExit(HP_OnExit)
