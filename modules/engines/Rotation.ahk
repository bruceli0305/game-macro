#Requires AutoHotkey v2
; Rotation.ahk - M1: 起手一次 + 双轨轮换（按次数达成 + 黑框判定 + 超时兜底）
; - 规则仍由 RuleEngine 执行，本模块负责阶段/轨道切换与过滤
; - 黑框防抖 BlackGuard：规避“被控全黑”误判，并与“我们发送的技能时间窗”对齐

global gRot := Map()  ; { Cfg, RT }
global gRotInitBusy := false

Rot_Log(msg, level:="INFO") {
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " [Rotation] [" level "] " msg "`r`n", A_ScriptDir "\Logs\rotengine.log", "UTF-8")
}

; ========== 配置与初始化 ==========

Rotation_IsEnabled() {
    try {
        return !!(gRot.Has("Cfg") ? gRot["Cfg"].Enabled : 0)
    } catch {
        return false
    }
}

Rotation_IsBusyWindowActive() {
    try {
        return Rotation_IsEnabled() && (A_TickCount < gRot["RT"].BusyUntil)
    } catch {
        return false
    }
}

Rotation_InitFromProfile() {
    global App, gRot, gRotInitBusy
    if gRotInitBusy
        return
    gRotInitBusy := true
    try {
        cfg := Rotation_ReadCfg(App["ProfileData"])

        ; 兜底：有 Watch → 自动启用（只影响本次运行）
        try {
            hasWatch := 0
            try hasWatch += (HasProp(cfg,"Opener") && HasProp(cfg.Opener,"Watch")) ? cfg.Opener.Watch.Length : 0
            try hasWatch += (HasProp(cfg,"Track1") && HasProp(cfg.Track1,"Watch")) ? cfg.Track1.Watch.Length : 0
            try hasWatch += (HasProp(cfg,"Track2") && HasProp(cfg.Track2,"Watch")) ? cfg.Track2.Watch.Length : 0
            if (!cfg.Enabled && hasWatch > 0) {
                cfg.Enabled := 1
                Rot_Log("AutoEnable at Init: Watch present, force Enabled=1")
            }
        }

        Rot_Log(Format("Cfg: Enabled={1} T1W={2} T2W={3} OpW={4}"
            , (cfg.Enabled?1:0)
            , (HasProp(cfg,"Track1") && HasProp(cfg.Track1,"Watch")) ? cfg.Track1.Watch.Length : 0
            , (HasProp(cfg,"Track2") && HasProp(cfg.Track2,"Watch")) ? cfg.Track2.Watch.Length : 0
            , (HasProp(cfg,"Opener")  && HasProp(cfg.Opener,"Watch")) ? cfg.Opener.Watch.Length  : 0))

        gRot["Cfg"] := cfg
        gRot["RT"]  := Rotation_NewRT(cfg)

        if !cfg.Enabled {
            Rot_Log("Disabled")
            return
        }
        if (cfg.Opener.Enabled && !gRot["RT"].OpenerDone) {
            Rotation_EnterOpener()
        } else {
            Rotation_EnterTrack(cfg.DefaultTrackId>0 ? cfg.DefaultTrackId : 1)
        }
        Rot_Log(Format("Init -> Phase={1} Track={2}", gRot["RT"].Phase, gRot["RT"].TrackId))
    } catch as e {
        Rot_Log("Init error: " e.Message, "WARN")
    } finally {
        gRotInitBusy := false
    }
}

Rotation_NewRT(cfg) {
    rt := {
        Phase: "Idle"               ; "Opener" | "Track"
      , TrackId: 0
      , BusyUntil: 0
      , OpenerDone: false
      , PhaseState: 0               ; { StartedAt, Baseline:Map, Items:[{si,need,verify,BlackSeen}] }
      , LastSent: Map()             ; SkillIndex -> last tick（用于黑框时间窗）
      , BlackoutUntil: 0            ; 全局黑忽略窗口截止（眩晕/击倒等）
    }
    return rt
}

Rotation_ReadCfg(prof) {
    ; 读取 ProfileData.Rotation（若没有则给默认）
    cfg := HasProp(prof, "Rotation") ? prof.Rotation : {}
    ; 默认
    if !HasProp(cfg, "Enabled") cfg.Enabled := 0
    if !HasProp(cfg, "DefaultTrackId") cfg.DefaultTrackId := 1
    if !HasProp(cfg, "BusyWindowMs") cfg.BusyWindowMs := 200
    if !HasProp(cfg, "ColorTolBlack") cfg.ColorTolBlack := 16
    if !HasProp(cfg, "RespectCastLock") cfg.RespectCastLock := 1
    if !HasProp(cfg, "Opener") cfg.Opener := { Enabled: 0, MaxDurationMs: 4000, Watch: [] }
    if !HasProp(cfg, "Track1") cfg.Track1 := { Id:1, Name:"轨道1", ThreadId:1, MaxDurationMs:8000, Watch:[], RuleRefs:[] }
    if !HasProp(cfg, "Track2") cfg.Track2 := { Id:2, Name:"轨道2", ThreadId:1, MaxDurationMs:8000, Watch:[], RuleRefs:[] }
    ; 黑框防抖 BlackGuard（简化默认）
    if !HasProp(cfg, "BlackGuard") {
        cfg.BlackGuard := {
            Enabled: 1
          , SampleCount: 5
          , BlackRatioThresh: 0.7
          , WindowMs: 120
          , CooldownMs: 600
          , MinAfterSendMs: 60
          , MaxAfterSendMs: 800
          , UniqueRequired: 1
        }
    }
    return cfg
}

; ========== 进入阶段/轨道与构建 PhaseState ==========

Rotation_EnterOpener() {
    global gRot
    gRot["RT"].Phase := "Opener"
    gRot["RT"].TrackId := 0
    gRot["RT"].PhaseState := Rotation_BuildPhaseState_Opener()
    Rot_Log("Enter Opener")
}

Rotation_EnterTrack(trackId) {
    global gRot
    gRot["RT"].Phase := "Track"
    gRot["RT"].TrackId := trackId
    gRot["RT"].PhaseState := Rotation_BuildPhaseState_Track(trackId)
    Rot_Log("Enter Track#" trackId)
}

Rotation_BuildPhaseState_Opener() {
    global App, gRot
    now := A_TickCount
    st := { StartedAt: now, Baseline: Map(), Items: [] }
    for _, w in gRot["Cfg"].Opener.Watch {
        si := w.SkillIndex, need := Max(1, (HasProp(w,"RequireCount") ? w.RequireCount : 1))
        verify := (HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0)
        st.Baseline[si] := Counters_Get(si)
        st.Items.Push({ SkillIndex: si, Require: need, VerifyBlack: verify ? 1 : 0, BlackSeen: false })
    }
    return st
}

Rotation_BuildPhaseState_Track(trackId) {
    global gRot
    now := A_TickCount
    tr := (trackId=1) ? gRot["Cfg"].Track1 : gRot["Cfg"].Track2
    st := { StartedAt: now, Baseline: Map(), Items: [] }
    for _, w in tr.Watch {
        si := w.SkillIndex, need := Max(1, (HasProp(w,"RequireCount") ? w.RequireCount : 1))
        verify := (HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0)
        st.Baseline[si] := Counters_Get(si)
        st.Items.Push({ SkillIndex: si, Require: need, VerifyBlack: verify ? 1 : 0, BlackSeen: false })
    }
    return st
}

; ========== 黑框防抖（简化 M1 版） ==========

Rotation_IsBlack(c, tol := 16) {
    ; c=0xRRGGBB 约等于黑
    r := (c>>16) & 0xFF, g := (c>>8) & 0xFF, b := c & 0xFF
    return (r<=tol && g<=tol && b<=tol)
}

Rotation_DetectBlackout(phaseSt) {
    ; 简化实现：采样 WatchList 的槽，若黑占比>=阈值 → 判为全局黑，设置 BlackoutUntil
    global App, gRot
    bg := gRot["Cfg"].BlackGuard
    if !bg.Enabled
        return false
    now := A_TickCount
    ; 采样点：优先 WatchList 的技能槽
    pts := []
    for _, it in phaseSt.Items {
        si := it.SkillIndex
        if (si>=1 && si<=App["ProfileData"].Skills.Length) {
            s := App["ProfileData"].Skills[si]
            pts.Push([s.X, s.Y])
            if (pts.Length >= bg.SampleCount)
                break
        }
    }
    if (pts.Length = 0)
        return false

    black := 0
    for _, p in pts {
        c := Pixel_FrameGet(p[1], p[2])
        if Rotation_IsBlack(c, gRot["Cfg"].ColorTolBlack)
            black++
    }
    ratio := black / pts.Length
    if (ratio >= bg.BlackRatioThresh) {
        gRot["RT"].BlackoutUntil := now + bg.CooldownMs
        Rot_Log(Format("BLACKOUT ratio={1:0.00} pts={2} until={3}", ratio, pts.Length, gRot["RT"].BlackoutUntil), "WARN")
        return true
    }
    return false
}

Rotation_TimeWindowAccept(si) {
    global gRot
    bg := gRot["Cfg"].BlackGuard

    ts := 0
    try {
        if gRot["RT"].LastSent.Has(si)
            ts := gRot["RT"].LastSent[si]
    }

    if (ts = 0) {
        return false
    }

    dt := A_TickCount - ts
    res := (dt >= bg.MinAfterSendMs && dt <= bg.MaxAfterSendMs)
    return res
}

; ========== Watch 评估：计数 + 黑框（带防抖） ==========

Rotation_WatchEval() {
    global App, gRot
    cfg := gRot["Cfg"]
    st := gRot["RT"].PhaseState
    tol := cfg.ColorTolBlack
    now := A_TickCount

    if (now < gRot["RT"].BlackoutUntil) {
        ; 黑屏忽略窗口内，直接判“黑框条件不成立”，仅用计数推进
    } else {
        ; 尝试侦测全局黑（眩晕/击倒）
        Rotation_DetectBlackout(st)
    }

    allOk := true
    for _, it in st.Items {
        si := it.SkillIndex
        delta := Counters_Get(si) - (st.Baseline.Has(si) ? st.Baseline[si] : 0)
        cntOk := (delta >= it.Require)

        blkOk := true
        if (it.VerifyBlack && !it.BlackSeen) {
            if (A_TickCount < gRot["RT"].BlackoutUntil) {
                blkOk := false
            } else {
                ; 仅在“我方发送时间窗内”接受黑框
                if Rotation_TimeWindowAccept(si) {
                    if (si>=1 && si<=App["ProfileData"].Skills.Length) {
                        s := App["ProfileData"].Skills[si]
                        c := Pixel_FrameGet(s.X, s.Y)
                        if Rotation_IsBlack(c, tol) {
                            ; 目标黑；再做“至少一个参考非黑”（若需要），简化：采样其他 Watch 槽
                            uniqOk := true
                            if gRot["Cfg"].BlackGuard.UniqueRequired {
                                uniqOk := false
                                for _, it2 in st.Items {
                                    if (it2.SkillIndex = si)
                                        continue
                                    if (it2.SkillIndex>=1 && it2.SkillIndex<=App["ProfileData"].Skills.Length) {
                                        s2 := App["ProfileData"].Skills[it2.SkillIndex]
                                        c2 := Pixel_FrameGet(s2.X, s2.Y)
                                        if !Rotation_IsBlack(c2, tol) {
                                            uniqOk := true
                                            break
                                        }
                                    }
                                }
                            }
                            if uniqOk {
                                it.BlackSeen := true
                            }
                        }
                    }
                }
                blkOk := it.BlackSeen
            }
        }

        ok := cntOk && blkOk
        if !ok
            allOk := false
    }
    return allOk
}

; ========== 规则过滤（按当前轨道 WatchList 的技能集合） ==========

Rotation_RunRules_ForCurrentTrack() {
    global App, gRot, RE_Filter
    tr := (gRot["RT"].TrackId=1) ? gRot["Cfg"].Track1 : gRot["Cfg"].Track2

    allow := Map()
    for _, w in tr.Watch {
        if (w.SkillIndex>=1)
            allow[w.SkillIndex] := true
    }
    RE_SetAllowedSkills(allow)

    acted := false
    try {
        acted := RuleEngine_RunTick()
    } catch {
        ; 可选：Rot_Log("RuleEngine exception", "WARN")
    } finally {
        RE_ClearFilter()
    }
    if acted {
        gRot["RT"].BusyUntil := A_TickCount + gRot["Cfg"].BusyWindowMs
    }
    return acted
}

; ========== 主 Tick：Buff(外部) → Rotation → DefaultSkill ==========

Rotation_Tick() {
    global App, gRot
    if !Rotation_IsEnabled()
        return false

    now := A_TickCount
    cfg := gRot["Cfg"]
    rt  := gRot["RT"]
    st  := rt.PhaseState

    ; 1) 起手阶段
    if (rt.Phase = "Opener") {
        opener := cfg.Opener
        done := Rotation_WatchEval()
        timeout := (now - st.StartedAt >= opener.MaxDurationMs)

        if (done || timeout) {
            rt.OpenerDone := true
            nextId := (cfg.DefaultTrackId>0) ? cfg.DefaultTrackId : 1
            Rotation_EnterTrack(nextId)
            Rot_Log("Opener -> Track#" nextId " by " (done?"allOk":"timeout"))
            return true
        }

        ; M1 简化：起手不做专门过滤，放行现有规则（如需更严格可在以后给起手专属规则）
        acted := RuleEngine_RunTick()
        if acted {
            rt.BusyUntil := now + cfg.BusyWindowMs
            return true
        }
        return false
    }

    ; 2) 轨道阶段（Track1/Track2）
    ; 2.1 读条锁期/BusyWindow：仅在当前轨执行规则（避免打断）
    thr := ((rt.TrackId=1) ? cfg.Track1.ThreadId : cfg.Track2.ThreadId)
    cast := WorkerPool_CastIsLocked(thr)    ; {Locked,Remain}
    if (cast.Locked || now < rt.BusyUntil) {
        acted := Rotation_RunRules_ForCurrentTrack()
        if acted
            return true
        ; 没动作也评估完成度（以防进入沉寂）
        if Rotation_WatchEval() {
            nextId := (rt.TrackId=1) ? 2 : 1
            Rotation_SwapAndEnter(nextId)   ; M1：无验证
            return true
        }
        return false
    }

    ; 2.2 执行当前轨规则（带过滤）
    acted := Rotation_RunRules_ForCurrentTrack()
    if acted
        return true

    ; 2.3 评估完成度/超时 → 切轨
    trCfg := (rt.TrackId=1) ? cfg.Track1 : cfg.Track2
    done := Rotation_WatchEval()
    timeout := (now - st.StartedAt >= trCfg.MaxDurationMs)
    if (done || timeout) {
        prevId := rt.TrackId
        nextId := (rt.TrackId=1) ? 2 : 1
        Rotation_SwapAndEnter(nextId)
        Rot_Log("Track#" prevId " -> Track#" nextId " by " (done?"allOk":"timeout"))
        return true
    }

    return false
}

Rotation_SwapAndEnter(trackId) {
    global gRot
    cfg := gRot["Cfg"]
    if HasProp(cfg, "SwapKey") && cfg.SwapKey != "" {
        Poller_SendKey(cfg.SwapKey)
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
    }
    Rotation_EnterTrack(trackId)
}

; ========== 发送事件回调（供 WorkerPool 调用） ==========

Rotation_OnSkillSent(si) {
    if !Rotation_IsEnabled()
        return
    try {
        gRot["RT"].LastSent[si] := A_TickCount
    } catch {
        ; 忽略异常
    }
}