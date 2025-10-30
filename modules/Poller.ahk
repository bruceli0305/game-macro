; Poller.ahk - 简单轮询逻辑（像素检测 -> Send 键位），集成帧级取色缓存

global gPoller := { running: false, timerBound: 0 }

Poller_Start() {
    global App, gPoller
    if gPoller.running
        return
    gPoller.running := true
    Notify("状态：运行中")
    ; 绑定定时器
    gPoller.timerBound := Poller_Tick  ; 函数对象
    SetTimer(gPoller.timerBound, App["ProfileData"].PollIntervalMs)
}

Poller_Stop() {
    global gPoller
    if !gPoller.running
        return
    gPoller.running := false
    try SetTimer(gPoller.timerBound, 0)
    Notify("状态：已停止")
}

Poller_IsRunning() {
    global gPoller
    return gPoller.running
}

Poller_Tick() {
    global App, gPoller
    if !gPoller.running
        return

    ; 帧开始：清空本帧取色缓存
    try Pixel_FrameBegin()

    ; 1) BUFF 引擎（最高优先级）
    try {
        if (BuffEngine_RunTick())
            return
    } catch {
        ; 忽略异常，继续后续规则
    }

    ; 2) 规则引擎（按优先级逐条评估）
    try {
        if (RuleEngine_RunTick())
            return
    } catch {
        ; 忽略异常
    }

    ; 3) 空转
}

; 统一发键：在真正发送前等待“全局延迟(ms)”；支持可选按住时长 holdMs
Poller_SendKey(keySpec, holdMs := 0) {
    global App
    delay := 0
    try {
        if HasProp(App, "ProfileData") && HasProp(App["ProfileData"], "SendCooldownMs") {
            delay := Integer(App["ProfileData"].SendCooldownMs)
        }
    } catch {
        delay := 0
    }
    if (delay > 0)
        Sleep delay

    s := Trim(keySpec)
    if (s = "")
        return false

    ; 如果是 Send 语法/修饰键已包含，按原样发送
    if RegExMatch(s, "[\{\}\^\!\+#]") {
        if (holdMs > 0) {
            SendEvent "{" s " down}"
            Sleep holdMs
            SendEvent "{" s " up}"
        } else {
            SendEvent s
        }
        return true
    }

    ; 常见特殊键统一加花括号
    if RegExMatch(s, "i)^(F([1-9]|1[0-9]|2[0-4])|Tab|Enter|Space|Backspace|Delete|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|Esc|Escape|AppsKey|PrintScreen|Pause|ScrollLock|CapsLock|NumLock|LWin|RWin|Numpad(Enter|Add|Sub|Mult|Div|\d+))$") {
        if (holdMs > 0) {
            SendEvent "{" s " down}"
            Sleep holdMs
            SendEvent "{" s " up}"
        } else {
            SendEvent "{" s "}"
        }
        return true
    }

    ; 其余视为普通字符
    if (holdMs > 0) {
        SendEvent "{" s " down}"
        Sleep holdMs
        SendEvent "{" s " up}"
    } else {
        SendEvent s
    }
    return true
}