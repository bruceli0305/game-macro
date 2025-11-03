; Poller.ahk - 简单轮询逻辑（像素检测 -> Send 键位），集成帧级取色缓存 + ROI 快照 + 默认技能兜底

global gPoller := { running: false, timerBound: 0 }


; 判定当前环境下是否能正确采样屏幕（独占全屏多数会失败）
Poller_CaptureReady() {
    ; 在屏幕四角采样一圈，若全为同色或返回异常，认为不可用
    pts := [[10,10],[A_ScreenWidth-10,10],[10,A_ScreenHeight-10],[A_ScreenWidth-10,A_ScreenHeight-10]]
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
    ; 隐藏任何屏幕提示，避免轮询时在鼠标旁出现 ToolTip
    try ToolTip()
    ; 先抓 ROI，再清帧缓存（如未启用 ROI，此步骤会自动跳过）
    ; 先抓 ROI（DXGI 可用则跳过），再清帧缓存
    try if !DX_IsReady()
        Pixel_ROI_BeginSnapshot()
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
    return WorkerPool_FireAndForget(s, delay, Max(0, holdMs))
}