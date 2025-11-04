#Requires AutoHotkey v2
; Rotation.ahk - M1/M2 集成：起手一次 + 轨道轮换（次数/黑框/超时）+ Gate 条件跳轨 + Swap 验证 + 起手步骤
; - 规则仍由 RuleEngine 执行，本模块负责阶段/轨道切换与过滤
; - 黑框防抖 BlackGuard：规避“被控全黑”误判，并与“我们发送的技能时间窗”对齐
; - 规则过滤：优先 RuleRefs（按 RuleId），否则回退到“Watch 技能集合”

global gRot := Map()             ; { Cfg, RT }
global gRotInitBusy := false     ; 防并发 init
global gRotInitialized := false  ; 防重复 init

Rot_Log(msg, level:="INFO") {
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " [Rotation] [" level "] " msg "`r`n", A_ScriptDir "\Logs\rotengine.log", "UTF-8")
}

; ========== 配置/状态 ==========
Rotation_IsEnabled() {
    try {
        return !!(gRot.Has("Cfg") ? gRot["Cfg"].Enabled : 0)
    } catch {
        return false
    }
}
Rotation_IsBusyWindowActive() {
    try {
        return Rotation_IsEnabled() && gRot.Has("RT") && (A_TickCount < gRot["RT"].BusyUntil)
    } catch {
        return false
    }
}

Rotation_InitFromProfile() {
    global App, gRot, gRotInitBusy, gRotInitialized
    if gRotInitBusy
        return
    gRotInitBusy := true
    try {
        if (gRotInitialized) {
            Rot_Log("Skip init (already initialized)")
            return
        }
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
        gRotInitialized := true
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
      , GateCooldownUntil: 0
      , OpenerDone: false
      , PhaseState: 0               ; { StartedAt, Baseline:Map, Items:[{si,need,verify,BlackSeen}] }
      , LastSent: Map()             ; SkillIndex -> last tick（用于黑框时间窗）
      , BlackoutUntil: 0            ; 全局黑忽略窗口截止（眩晕/击倒等）
      , OpStep: {
          Index: 1
        , StepStarted: 0
        , StepWaiting: 0
      }
    }
    return rt
}

Rotation_ReadCfg(prof) {
    cfg := HasProp(prof, "Rotation") ? prof.Rotation : {}
    if !HasProp(cfg, "Enabled") cfg.Enabled := 0
    if !HasProp(cfg, "DefaultTrackId") cfg.DefaultTrackId := 1
    if !HasProp(cfg, "BusyWindowMs") cfg.BusyWindowMs := 200
    if !HasProp(cfg, "ColorTolBlack") cfg.ColorTolBlack := 16
    if !HasProp(cfg, "RespectCastLock") cfg.RespectCastLock := 1
    if !HasProp(cfg, "Opener") cfg.Opener := { Enabled: 0, MaxDurationMs: 4000, Watch: [], StepsCount: 0, Steps: [] }
    if !HasProp(cfg, "Track1") cfg.Track1 := { Id:1, Name:"轨道1", ThreadId:1, MaxDurationMs:8000, Watch:[], RuleRefs:[] }
    if !HasProp(cfg, "Track2") cfg.Track2 := { Id:2, Name:"轨道2", ThreadId:1, MaxDurationMs:8000, Watch:[], RuleRefs:[] }
    ; Gates（可选）
    if !HasProp(cfg, "GatesEnabled") cfg.GatesEnabled := 0
    if !HasProp(cfg, "Gates") cfg.Gates := []
    if !HasProp(cfg, "GateCooldownMs") cfg.GateCooldownMs := 0

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

; ========== 状态进入/构建 ==========
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

; ========== 黑框防抖 ==========
Rotation_IsBlack(c, tol := 16) {
    r := (c>>16) & 0xFF, g := (c>>8) & 0xFF, b := c & 0xFF
    return (r<=tol && g<=tol && b<=tol)
}
Rotation_DetectBlackout(phaseSt) {
    global App, gRot
    bg := gRot["Cfg"].BlackGuard
    if !bg.Enabled
        return false
    now := A_TickCount
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

; ========== Watch 评估 ==========
Rotation_WatchEval() {
    global App, gRot
    cfg := gRot["Cfg"], st := gRot["RT"].PhaseState
    tol := cfg.ColorTolBlack
    now := A_TickCount

    if (now >= gRot["RT"].BlackoutUntil) {
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
                if Rotation_TimeWindowAccept(si) {
                    if (si>=1 && si<=App["ProfileData"].Skills.Length) {
                        s := App["ProfileData"].Skills[si]
                        c := Pixel_FrameGet(s.X, s.Y)
                        if Rotation_IsBlack(c, tol) {
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
                            if uniqOk
                                it.BlackSeen := true
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

; ========== 规则过滤 ==========
Rotation_RunRules_ForCurrentTrack() {
    global gRot
    cfg := gRot["Cfg"], rt := gRot["RT"]
    tr := (rt.TrackId=1) ? cfg.Track1 : cfg.Track2
    acted := false

    if HasProp(tr, "RuleRefs") && tr.RuleRefs.Length>0 {
        allow := Map()
        for i, rid in tr.RuleRefs
            allow[rid] := true
        try {
            RE_SetAllowedRules(allow)
            acted := RuleEngine_RunTick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    } else {
        allowS := Map()
        for _, w in tr.Watch
            if (w.SkillIndex>=1)
                allowS[w.SkillIndex] := true
        try {
            RE_SetAllowedSkills(allowS)
            acted := RuleEngine_RunTick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    }

    if acted
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
    return acted
}

; ========== 主 Tick ==========
Rotation_Tick() {
    global gRot
    if !Rotation_IsEnabled()
        return false

    now := A_TickCount
    cfg := gRot["Cfg"], rt := gRot["RT"], st := rt.PhaseState

    ; 起手阶段
    if (rt.Phase = "Opener") {
        opener := cfg.Opener
        if Rotation_OpenerHasSteps() {
            res := Rotation_OpenerStepTick()
            if (res = -1) {
                nextId := (cfg.DefaultTrackId > 0) ? cfg.DefaultTrackId : 1
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener(Steps) -> Track#" nextId)
                return true
            }
            if (res = 1) {
                return true
            }
            acted := false
            try acted := RuleEngine_RunTick()
            catch
            if (acted) {
                rt.BusyUntil := A_TickCount + cfg.BusyWindowMs
                return true
            }
            if (A_TickCount - rt.PhaseState.StartedAt >= opener.MaxDurationMs) {
                nextId := (cfg.DefaultTrackId > 0) ? cfg.DefaultTrackId : 1
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener(Steps) timeout -> Track#" nextId)
                return true
            }
            return false
        } else {
            done := Rotation_WatchEval()
            timeout := (A_TickCount - rt.PhaseState.StartedAt >= opener.MaxDurationMs)
            if (done || timeout) {
                nextId := (cfg.DefaultTrackId>0) ? cfg.DefaultTrackId : 1
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener -> Track#" nextId " by " (done?"allOk":"timeout"))
                return true
            }
            acted := false
            try acted := RuleEngine_RunTick()
            catch
            if (acted) {
                rt.BusyUntil := A_TickCount + cfg.BusyWindowMs
                return true
            }
            return false
        }
    }

    ; 轨道阶段
    thr := ((rt.TrackId=1) ? cfg.Track1.ThreadId : cfg.Track2.ThreadId)
    cast := WorkerPool_CastIsLocked(thr)
    if (cast.Locked || now < rt.BusyUntil) {
        acted := Rotation_RunRules_ForCurrentTrack()
        if acted
            return true
        if Rotation_WatchEval() {
            prevId := rt.TrackId
            nextId := (rt.TrackId=1) ? 2 : 1
            Rotation_SwapAndEnter(nextId)
            Rot_Log("Track#" prevId " -> Track#" nextId " by allOk")
            return true
        }
        return false
    }

    ; Gate（非锁+非 BusyWindow，且满足 Gate 冷却与 MinStay）
    elapsed := now - st.StartedAt
    curTr := (rt.TrackId=1) ? cfg.Track1 : cfg.Track2
    minStay := HasProp(curTr,"MinStayMs") ? curTr.MinStayMs : 0
    if (HasProp(cfg,"GatesEnabled") && cfg.GatesEnabled) {
        if (now >= rt.GateCooldownUntil && elapsed >= minStay) {
            target := Rotation_GateFindMatch()
            if (target > 0 && target != rt.TrackId) {
                Rotation_TryEnterTrackWithSwap(target)
                rt.GateCooldownUntil := now + (HasProp(cfg,"GateCooldownMs") ? cfg.GateCooldownMs : 0)
                Rot_Log("GATE hit -> Track#" target)
                return true
            }
        }
    }

    ; 执行当前轨规则
    acted := Rotation_RunRules_ForCurrentTrack()
    if acted
        return true

    ; 完成/超时 → 切轨
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

; ========== WorkerPool 回调 ==========
Rotation_OnSkillSent(si) {
    if !Rotation_IsEnabled()
        return
    try {
        gRot["RT"].LastSent[si] := A_TickCount
    } catch {
    }
}

; ========== Gate/验证/工具 ==========
Rotation_ResolveRef(refType, refIndex) {
    global App
    if (refType="Skill" && refIndex>=1 && refIndex<=App["ProfileData"].Skills.Length) {
        s := App["ProfileData"].Skills[refIndex]
        return { X:s.X, Y:s.Y, Color:s.Color, Tol:s.Tol }
    }
    if (refType="Point" && refIndex>=1 && refIndex<=App["ProfileData"].Points.Length) {
        p := App["ProfileData"].Points[refIndex]
        return { X:p.X, Y:p.Y, Color:p.Color, Tol:p.Tol }
    }
    return 0
}
Rotation_PixelOpCompare(cur, tgt, tol, op) {
    tgtInt := Pixel_HexToInt(tgt)
    match := Pixel_ColorMatch(cur, tgtInt, tol)
    if (StrUpper(op)="EQ")
        return match
    else
        return !match
}
Rotation_GateEval_PixelReady(g) {
    global gRot
    ref := Rotation_ResolveRef(g.RefType, g.RefIndex)
    if !ref
        return false
    op := (HasProp(g,"Op") ? g.Op : "NEQ")
    tol := (HasProp(g,"Tol") ? g.Tol : gRot["Cfg"].ColorTolBlack)
    tgt := (HasProp(g,"Color") ? g.Color : "0x000000")
    cur := Pixel_FrameGet(ref.X, ref.Y)
    return Rotation_PixelOpCompare(cur, tgt, tol, op)
}
Rotation_GateEval_RuleQuiet(g) {
    global RE_LastFireTick
    rid := HasProp(g,"RuleId") ? g.RuleId : 0
    quiet := HasProp(g,"QuietMs") ? g.QuietMs : 0
    if (rid<=0 || quiet<=0)
        return false
    last := (RE_LastFireTick.Has(rid) ? RE_LastFireTick[rid] : 0)
    return (A_TickCount - last >= quiet)
}
Rotation_GateFindMatch() {
    global gRot
    cfg := gRot["Cfg"]
    if !HasProp(cfg,"GatesEnabled") || !cfg.GatesEnabled
        return 0
    if !HasProp(cfg,"Gates") || cfg.Gates.Length=0
        return 0
    for _, g in cfg.Gates {
        kind := StrUpper(g.Kind)
        ok := false
        if (kind = "PIXELREADY") {
            ok := Rotation_GateEval_PixelReady(g)
            if ok
                return (HasProp(g,"TargetTrackId") ? g.TargetTrackId : 0)
        } else if (kind = "RULEQUIET") {
            ok := Rotation_GateEval_RuleQuiet(g)
            if ok
                return (HasProp(g,"TargetTrackId") ? g.TargetTrackId : 0)
        } else {
            ; 扩展：Counter/Timer（M3+）
        }
    }
    return 0
}
Rotation_TryEnterTrackWithSwap(trackId) {
    global gRot
    cfg := gRot["Cfg"]
    if HasProp(cfg, "SwapKey") && cfg.SwapKey!="" {
        Poller_SendKey(cfg.SwapKey)
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
        if (HasProp(cfg,"VerifySwap") && cfg.VerifySwap) {
            Rotation_VerifySwapPixel(cfg.SwapVerify, (HasProp(cfg,"SwapTimeoutMs")?cfg.SwapTimeoutMs:800), (HasProp(cfg,"SwapRetry")?cfg.SwapRetry:0))
        }
    }
    Rotation_EnterTrack(trackId)
    return true
}
Rotation_VerifySwapPixel(vcfg, timeoutMs := 800, retry := 0) {
    if !vcfg
        return true
    tries := Max(1, retry+1)
    loop tries {
        t0 := A_TickCount
        while (A_TickCount - t0 <= timeoutMs) {
            ref := Rotation_ResolveRef(vcfg.RefType, vcfg.RefIndex)
            if !ref
                break
            cur := PixelGetColor(ref.X, ref.Y, "RGB")
            if Rotation_PixelOpCompare(cur, (HasProp(vcfg,"Color")?vcfg.Color:"0x000000")
                    , (HasProp(vcfg,"Tol")?vcfg.Tol:16), (HasProp(vcfg,"Op")?vcfg.Op:"NEQ")) {
                Rot_Log("Swap verify OK")
                return true
            }
            Sleep 20
        }
        if (A_Index < tries)
            Rot_Log("Swap verify retry")
    }
    Rot_Log("Swap verify FAIL", "WARN")
    return false
}

; ========== 起手 Step 引擎（Skill/Wait/Swap） ==========
Rotation_OpenerHasSteps() {
    global gRot
    try {
        return (gRot["Cfg"].Opener.StepsCount > 0 && gRot["Cfg"].Opener.Steps.Length > 0)
    } catch {
        return false
    }
}
Rotation_OpenerStepTick() {
    ; 返回：1=本帧已消费；-1=全部完成；0=本帧未消费
    global gRot, App
    cfg := gRot["Cfg"], rt := gRot["RT"]
    steps := cfg.Opener.Steps
    if !steps || steps.Length=0
        return 0
    if !HasProp(rt, "OpStep") {
        rt.OpStep := { Index:1, StepStarted:0 }
    }
    i := rt.OpStep.Index
    if (i < 1 || i > steps.Length)
        return -1
    stp := steps[i]
    now := A_TickCount

    if (stp.Kind = "Wait") {
        if (rt.OpStep.StepStarted = 0)
            rt.OpStep.StepStarted := now
        if (now - rt.OpStep.StepStarted >= (HasProp(stp,"DurationMs")?stp.DurationMs:0)) {
            rt.OpStep.Index := i + 1
            rt.OpStep.StepStarted := 0
            return 0
        }
        return 0
    } else if (stp.Kind = "Swap") {
        if (rt.OpStep.StepStarted = 0) {
            if HasProp(cfg, "SwapKey") && cfg.SwapKey!="" {
                Poller_SendKey(cfg.SwapKey)
                rt.BusyUntil := now + cfg.BusyWindowMs
                if (HasProp(cfg,"VerifySwap") && cfg.VerifySwap)
                    Rotation_VerifySwapPixel(cfg.SwapVerify, (HasProp(stp,"TimeoutMs")?stp.TimeoutMs:800), (HasProp(stp,"Retry")?stp.Retry:0))
            }
            rt.OpStep.Index := i + 1
            rt.OpStep.StepStarted := 0
            return 1
        }
        return 0
    } else if (stp.Kind = "Skill") {
        si := HasProp(stp,"SkillIndex") ? stp.SkillIndex : 0
        if (si < 1)
            return 0
        if (HasProp(stp,"RequireReady") && stp.RequireReady) {
            ready := false
            try {
                s := App["ProfileData"].Skills[si]
                c := Pixel_FrameGet(s.X, s.Y)
                tol := cfg.ColorTolBlack
                ready := !Rotation_IsBlack(c, tol)
            }
            if !ready
                return 0
        }
        if (HasProp(stp,"PreDelayMs") && stp.PreDelayMs > 0)
            Sleep stp.PreDelayMs
        thr := (cfg.Track1.ThreadId)  ; 简化：用 Track1 线程；需要时可扩展 OpenerThreadId
        ok := WorkerPool_SendSkillIndex(thr, si, "OpenerStep")
        if (ok) {
            if (HasProp(stp,"Verify") && stp.Verify) {
                ; 可对接 RuleEngine_SendVerified 或轻量像素反馈
            }
            rt.BusyUntil := A_TickCount + cfg.BusyWindowMs
            rt.OpStep.Index := i + 1
            rt.OpStep.StepStarted := 0
            return 1
        }
        return 0
    }
    return 0
}