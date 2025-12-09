; modules\runtime\Poller.ahk - 简单轮询逻辑（像素检测 -> Send 键位），集成帧级取色缓存 + ROI 快照 + 默认技能兜底

global gPoller := { running: false, timerBound: 0 }

; 判定当前环境下是否能正确采样屏幕（独占全屏多数会失败）
Poller_CaptureReady() {
    ; 在屏幕四角采样一圈，若全为同色或返回异常，认为不可用
    pts := [[10, 10], [A_ScreenWidth - 10, 10], [10, A_ScreenHeight - 10], [A_ScreenWidth - 10, A_ScreenHeight - 10]]
    cols := []
    try {
        Pixel_FrameBegin()
        for _, p in pts {
            c := PixelGetColor(p[1], p[2], "RGB")
            cols.Push(c)
        }
    } catch {
        return false
    }
    ; 全相同/全黑可判为无效，但避免误判：允许有1~2个重复
    uniq := Map()
    for _, c in cols
        uniq[c] := true
    return uniq.Count > 2
}
; 在 Poller_Start 里加判定
Poller_Start() {
    global App, gPoller
    if gPoller.running
        return
    if !Poller_CaptureReady() {
        Notify("检测到独占全屏或无法取色，请切换为“无边框窗口化”后再启动。")
        return
    }
    try Rotation_InitFromProfile()
    Logger_Info("Poller", "start", Map("intervalMs", App["ProfileData"].PollIntervalMs))
    gPoller.running := true
    Notify("状态：运行中")
    gPoller.timerBound := Poller_Tick
    SetTimer(gPoller.timerBound, App["ProfileData"].PollIntervalMs)
}

Poller_Stop() {
    global gPoller
    if !gPoller.running
        return
    gPoller.running := false
    try SetTimer(gPoller.timerBound, 0)
    Notify("状态：已停止")
    Logger_Info("Poller", "stop", Map())
}

Poller_IsRunning() {
    global gPoller
    return gPoller.running
}

Poller_Tick() {
    global App, gPoller
    if !gPoller.running
        return
    try ToolTip()
    try if !DX_IsReady()
        Pixel_ROI_BeginSnapshot()
    try Pixel_FrameBegin()
    ; 更新施法条驱动的技能状态机（如启用）
    try {
        CastEngine_Tick()
    } catch {
    }
    ; 会话优先：若会话活跃，跳过 BUFF/Rotation，直接驱动会话并返回
    try {
        if RE_SessionActive() {
            RuleEngine_Tick()
            return
        }
    } catch {
    }

    ; 1) BUFF 引擎（会话活跃时已提前 return，不会走到这里）
    try {
        if !Rotation_IsBusyWindowActive() {
            if (BuffEngine_RunTick())
                return
        }
    } catch {
    }

    ; 2) 规则/轮换
    try {
        if Rotation_IsEnabled() {
            if (Rotation_Tick())
                return
        } else {
            ; 旧式：直接跑规则（使用会话优先的 Tick）
            if (RuleEngine_Tick())
                return
        }
    } catch {
    }

    ; 3) 默认技能兜底
    try {
        if (Poller_TryDefaultSkill())
            return
    } catch {
    }
}

; 默认技能兜底：当 BUFF/规则均未触发时调用
Poller_TryDefaultSkill() {
    global App
    if !HasProp(App["ProfileData"], "DefaultSkill")
        return false
    ds := App["ProfileData"].DefaultSkill
    if !ds.Enabled
        return false

    idx := HasProp(ds, "SkillIndex") ? ds.SkillIndex : 0
    if (idx < 1 || idx > App["ProfileData"].Skills.Length)
        return false

    ; 冷却判定
    now := A_TickCount
    last := HasProp(ds, "LastFire") ? ds.LastFire : 0
    cd := HasProp(ds, "CooldownMs") ? ds.CooldownMs : 600
    if (now - last < cd)
        return false

    s := App["ProfileData"].Skills[idx]

    ; 可选就绪检测（使用帧缓存）
    if (HasProp(ds, "CheckReady") ? ds.CheckReady : 1) {
        cur := Pixel_FrameGet(s.X, s.Y)
        tgt := Pixel_HexToInt(s.Color)
        if !Pixel_ColorMatch(cur, tgt, s.Tol)
            return false
    }

    ; 预延时
    pre := HasProp(ds, "PreDelayMs") ? ds.PreDelayMs : 0
    if (pre > 0)
        Sleep pre

    thr := HasProp(ds, "ThreadId") ? ds.ThreadId : 1
    if WorkerPool_SendSkillIndex(thr, idx, "Default") {
        App["ProfileData"].DefaultSkill.LastFire := A_TickCount
        try {
            f := Map()
            f["idx"] := idx
            f["key"] := s.Key
            f["threadId"] := ds.ThreadId
            Logger_Info("Poller", "Default skill fired", f)
        } catch {
        }
        return true
    }
    return false
}
; 统一发键：走 WorkerPool 的一次性通道（延迟下放到 WorkerHost）
Poller_SendKey(keySpec, holdMs := 0) {
    global App
    s := Trim(keySpec)
    if (s = "")
        return false
    delay := 0
    try {
        if IsObject(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "SendCooldownMs")
            delay := Max(0, Integer(App["ProfileData"].SendCooldownMs))
    }
    return KeyOut_Send(s, delay, Max(0, holdMs))
}
