; Poller.ahk - 简单轮询逻辑（像素检测 -> Send 键位），集成帧级取色缓存 + ROI 快照 + 默认技能兜底

global gPoller := { running: false, timerBound: 0 }

Poller_Start() {
    global App, gPoller
    if gPoller.running
        return
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
}

Poller_IsRunning() {
    global gPoller
    return gPoller.running
}

Poller_Tick() {
    global App, gPoller
    if !gPoller.running
        return

    ; 先抓 ROI，再清帧缓存（如未启用 ROI，此步骤会自动跳过）
    try Pixel_ROI_BeginSnapshot()
    try Pixel_FrameBegin()

    ; 1) BUFF 引擎（最高优先级）
    try {
        if (BuffEngine_RunTick())
            return
    } catch {
    }

    ; 2) 规则引擎
    try {
        if (RuleEngine_RunTick())
            return
    } catch {
    }

    ; 3) 兜底默认技能（当本 Tick 没有任何规则/BUFF触发）
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
    cd   := HasProp(ds, "CooldownMs") ? ds.CooldownMs : 600
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
        return true
    }
    return false
}

; 统一发键：改为走 WorkerPool 的一次性通道（不再本地 Sleep）
Poller_SendKey(keySpec, holdMs := 0) {
    return WorkerPool_FireAndForget(Trim(keySpec), 0, Max(0, holdMs))
}