#Requires AutoHotkey v2
; Rotation.ahk - M1/M2/M3 集成：起手 + 轨道轮换 + Gate + 多轨
; - M1：黑框防抖/BusyWindow/规则过滤
; - M2：Gate 条件跳轨、Swap 验证、起手步骤
; - M3：Tracks[] 通用调度 + NextTrackId + Gate 多条件(AND/OR) + Priority

global gRot := Map()             ; { Cfg, RT }
global gRotInitBusy := false     ; 防并发 init
global gRotInitialized := false  ; 防重复 init

; 新增：切换 Profile 时调用，清空轮换引擎状态
Rotation_Reset() {
    global gRot, gRotInitialized, gRotInitBusy
    try gRot.Clear()
    gRot := Map()
    gRotInitBusy := false
    gRotInitialized := false
}

Rot_Log(msg, level := "INFO") {
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
    if (gRotInitBusy)
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
            ; 若存在 Tracks[]，也统计
            try {
                if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks)) {
                    for _, __t in cfg.Tracks {
                        try hasWatch += (HasProp(__t,"Watch") ? __t.Watch.Length : 0)
                    }
                }
            }
            if (!cfg.Enabled && hasWatch > 0) {
                cfg.Enabled := 1
                Rot_Log("AutoEnable at Init: Watch present, force Enabled=1")
            }
        }

        Rot_Log(Format("Cfg: Enabled={1} T1W={2} T2W={3} OpW={4} TrackCount={5}"
            , (cfg.Enabled?1:0)
            , (HasProp(cfg,"Track1") && HasProp(cfg.Track1,"Watch")) ? cfg.Track1.Watch.Length : 0
            , (HasProp(cfg,"Track2") && HasProp(cfg.Track2,"Watch")) ? cfg.Track2.Watch.Length : 0
            , (HasProp(cfg,"Opener")  && HasProp(cfg.Opener,"Watch")) ? cfg.Opener.Watch.Length  : 0
            , (HasProp(cfg,"Tracks")  && IsObject(cfg.Tracks)) ? cfg.Tracks.Length : 0))

        gRot["Cfg"] := cfg
        gRot["RT"]  := Rotation_NewRT(cfg)

        if (!cfg.Enabled) {
            Rot_Log("Disabled")
            return
        }
        if (cfg.Opener.Enabled && !gRot["RT"].OpenerDone) {
            Rotation_EnterOpener()
        } else {
            Rotation_EnterTrack(Rotation_GetDefaultTrackId())
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
      , FreezeUntil: 0              ; 新增：黑屏后冻结（WindowMs）
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

; ---------- M3 轨道辅助 ----------
Rotation_UseTracks() {
    global gRot
    try {
        return HasProp(gRot["Cfg"], "Tracks")
            && IsObject(gRot["Cfg"].Tracks)
            && gRot["Cfg"].Tracks.Length > 0
    } catch {
        return false
    }
}
Rotation_GetTrackById(id) {
    global gRot
    if (id <= 0)
        return 0
    if (Rotation_UseTracks()) {
        for _, t in gRot["Cfg"].Tracks {
            if (HasProp(t, "Id") && t.Id = id)
                return t
        }
        try {
            return gRot["Cfg"].Tracks[1]
        } catch {
            return 0
        }
    }
    if (id = 1)
        return gRot["Cfg"].Track1
    if (id = 2)
        return gRot["Cfg"].Track2
    return 0
}
Rotation_GetDefaultTrackId() {
    global gRot
    try {
        id := HasProp(gRot["Cfg"], "DefaultTrackId") ? gRot["Cfg"].DefaultTrackId : 1
        if (Rotation_UseTracks()) {
            if (id > 0 && Rotation_GetTrackById(id))
                return id
            return gRot["Cfg"].Tracks[1].Id
        }
        return (id > 0 ? id : 1)
    } catch {
        return 1
    }
}
Rotation_GetNextTrackId(curId) {
    global gRot
    if (Rotation_UseTracks()) {
        cur := Rotation_GetTrackById(curId)
        if (cur && HasProp(cur, "NextTrackId") && cur.NextTrackId > 0 && Rotation_GetTrackById(cur.NextTrackId))
            return cur.NextTrackId
        arr := gRot["Cfg"].Tracks
        pos := 1
        for i, t in arr {
            if (t.Id = curId) {
                pos := i
                break
            }
        }
        nxt := (pos >= arr.Length) ? 1 : (pos + 1)
        return arr[nxt].Id
    }
    return (curId = 1) ? 2 : 1
}
Rotation_CurrentTrackCfg() {
    global gRot
    return Rotation_GetTrackById(gRot["RT"].TrackId)
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
    tr := Rotation_GetTrackById(trackId)
    st := { StartedAt: now, Baseline: Map(), Items: [] }
    if (tr && HasProp(tr, "Watch") && IsObject(tr.Watch)) {
        for _, w in tr.Watch {
            si := w.SkillIndex, need := Max(1, (HasProp(w,"RequireCount") ? w.RequireCount : 1))
            verify := (HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0)
            st.Baseline[si] := Counters_Get(si)
            st.Items.Push({ SkillIndex: si, Require: need, VerifyBlack: verify ? 1 : 0, BlackSeen: false })
        }
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
        ; 使用 WindowMs 作为“冻结期”，冻结期间不推进阶段/切轨/Gate
        try {
            win := HasProp(bg, "WindowMs") ? Integer(bg.WindowMs) : 0
            if (win > 0)
                gRot["RT"].FreezeUntil := Max(gRot["RT"].FreezeUntil, now + win)
        }
        Rot_Log(Format("BLACKOUT ratio={1:0.00} pts={2} blackoutUntil={3} freezeUntil={4}"
            , ratio, pts.Length, gRot["RT"].BlackoutUntil, gRot["RT"].FreezeUntil), "WARN")
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
                if (Rotation_TimeWindowAccept(si)) {
                    if (si>=1 && si<=App["ProfileData"].Skills.Length) {
                        s := App["ProfileData"].Skills[si]
                        c := Pixel_FrameGet(s.X, s.Y)
                        if Rotation_IsBlack(c, tol) {
                            uniqOk := true
                            if (gRot["Cfg"].BlackGuard.UniqueRequired) {
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
                            if (uniqOk)
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
    tr := Rotation_CurrentTrackCfg()
    acted := false

    if (tr && HasProp(tr, "RuleRefs") && tr.RuleRefs.Length > 0) {
        allow := Map()
        for _, rid in tr.RuleRefs
            allow[rid] := true
        try {
            Rot_Log("Track#" rt.TrackId " filter=RuleRefs count=" tr.RuleRefs.Length)
            RE_SetAllowedRules(allow)
            acted := RuleEngine_Tick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    } else {
        allowS := Map()
        if (tr && HasProp(tr, "Watch")) {
            for _, w in tr.Watch
                if (w.SkillIndex>=1)
                    allowS[w.SkillIndex] := true
        }
        try {
            Rot_Log("Track#" rt.TrackId " filter=AllowSkills count=" allowS.Count)
            RE_SetAllowedSkills(allowS)
            acted := RuleEngine_Tick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    }

    if (acted)
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
    return acted
}

; ---------- Gate 多条件求值 ----------
Rotation_GateEval_Cond(c) {
    if (!c || !HasProp(c, "Kind"))
        return false
    kind := StrUpper(c.Kind)
    if (kind = "PIXELREADY") {
        refType  := HasProp(c, "RefType")  ? c.RefType  : "Skill"
        refIndex := HasProp(c, "RefIndex") ? c.RefIndex : 0
        op       := HasProp(c, "Op")       ? c.Op       : "NEQ"
        color    := HasProp(c, "Color")    ? c.Color    : "0x000000"
        tol      := HasProp(c, "Tol")      ? c.Tol      : 16
        ref := Rotation_ResolveRef(refType, refIndex)
        if !ref
            return false
        cur := Pixel_FrameGet(ref.X, ref.Y)
        return Rotation_PixelOpCompare(cur, color, tol, op)
    } else if (kind = "RULEQUIET") {
        rid := HasProp(c, "RuleId")  ? c.RuleId  : 0
        qms := HasProp(c, "QuietMs") ? c.QuietMs : 0
        return Rotation_GateEval_RuleQuiet({ RuleId: rid, QuietMs: qms })
    } else if (kind = "COUNTER" || kind = "COUNTERREADY") {
        ; 支持 Gate 中的计数条件（RefIndex=技能索引）
        si := HasProp(c, "RefIndex") ? c.RefIndex : 0
        if (si <= 0)
            return false
        cmp := StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE")
        val := HasProp(c, "Value") ? Integer(c.Value) : 1
        cnt := Counters_Get(si)
        switch cmp {
            case "GE": return cnt >= val
            case "EQ": return cnt =  val
            case "GT": return cnt >  val
            case "LE": return cnt <= val
            case "LT": return cnt <  val
        }
        return false
    } else if (kind = "ELAPSED") {
        ; 阶段用时比较（基于当前 PhaseState.StartedAt）
        global gRot
        if !(gRot.Has("RT") && HasProp(gRot["RT"], "PhaseState") && HasProp(gRot["RT"].PhaseState, "StartedAt"))
            return false
        ms := HasProp(c, "ElapsedMs") ? Integer(c.ElapsedMs) : 0
        cmp := StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE")
        elapsed := A_TickCount - gRot["RT"].PhaseState.StartedAt
        switch cmp {
            case "GE": return elapsed >= ms
            case "EQ": return elapsed =  ms
            case "GT": return elapsed >  ms
            case "LE": return elapsed <= ms
            case "LT": return elapsed <  ms
        }
    }
    ; 预留：Counter/Timer 等
    return false
}
Rotation_GateEval(g) {
    ; 兼容两种格式：
    ; - M3: g.Conds[] + g.Logic
    ; - M2: 单条件写在 g.Kind 等字段
    if (HasProp(g, "Conds") && IsObject(g.Conds) && g.Conds.Length > 0) {
        logicAnd := (StrUpper(HasProp(g, "Logic") ? g.Logic : "AND") = "AND")
        anyHit := false
        allTrue := true
        for _, c in g.Conds {
            res := Rotation_GateEval_Cond(c)
            anyHit := anyHit || res
            allTrue := allTrue && res
            if (!logicAnd && anyHit)
                return true
            if (logicAnd && !allTrue)
                return false
        }
        return logicAnd ? allTrue : anyHit
    } else {
        ; 旧式单条件
        return Rotation_GateEval_Cond(g)
    }
}

Rotation_GateFindMatch() {
    global gRot
    cfg := gRot["Cfg"]
    if !HasProp(cfg, "GatesEnabled") || !cfg.GatesEnabled
        return 0
    if !HasProp(cfg, "Gates") || cfg.Gates.Length = 0
        return 0

    curId := gRot["RT"].TrackId
    if (curId <= 0)
        return 0

    ; 复制并按 Priority 升序
    gates := []
    for _, g in cfg.Gates
        gates.Push(g)
    gates.Sort((a, b, *) => ((HasProp(a,"Priority")?a.Priority:0) - (HasProp(b,"Priority")?b.Priority:0)))

    for _, g in gates {
        ; 新增：来源轨限制（必须在 FromTrackId 上才评估）
        fromId := HasProp(g, "FromTrackId") ? Integer(g.FromTrackId) : 0
        toId   := HasProp(g, "ToTrackId")   ? Integer(g.ToTrackId)   : 0
        if (fromId <= 0 || toId <= 0) {
            ; 未配置 From/To，视为无效 Gate
            continue
        }
        if (fromId != curId) {
            continue
        }

        ok := Rotation_GateEval(g)
        if (ok) {
            ; 目标轨必须存在
            if (Rotation_GetTrackById(toId)) {
                Rot_Log("GATE hit From#" fromId " -> To#" toId)
                return toId
            } else {
                Rot_Log("GATE hit but To#" toId " not found", "WARN")
            }
        }
    }
    return 0
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
        if (Rotation_OpenerHasSteps()) {
            res := Rotation_OpenerStepTick()
            if (res = -1) {
                nextId := Rotation_GetDefaultTrackId()
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener(Steps) -> Track#" nextId)
                return true
            }
            if (res = 1) {
                return true
            }
            acted := false
            try acted := RuleEngine_Tick()
            catch
            if (acted) {
                rt.BusyUntil := A_TickCount + cfg.BusyWindowMs
                return true
            }
            if (A_TickCount - rt.PhaseState.StartedAt >= opener.MaxDurationMs) {
                nextId := Rotation_GetDefaultTrackId()
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener(Steps) timeout -> Track#" nextId)
                return true
            }
            return false
        } else {
            done := Rotation_WatchEval()
            timeout := (A_TickCount - rt.PhaseState.StartedAt >= opener.MaxDurationMs)
            if (done || timeout) {
                nextId := Rotation_GetDefaultTrackId()
                Rotation_EnterTrack(nextId)
                Rot_Log("Opener -> Track#" nextId " by " (done?"allOk":"timeout"))
                return true
            }
            acted := false
            try acted := RuleEngine_Tick()
            catch
            if (acted) {
                rt.BusyUntil := A_TickCount + cfg.BusyWindowMs
                return true
            }
            return false
        }
    }

    ; 轨道阶段
    curTr := Rotation_CurrentTrackCfg()
    thr := (curTr && HasProp(curTr,"ThreadId")) ? curTr.ThreadId : 1
    cast := WorkerPool_CastIsLocked(thr)
    freeze := (now < rt.FreezeUntil)
    busy := (now < rt.BusyUntil)

    ; RespectCastLock：=1 时，锁定期间仅允规则执行，不推进 Watch/Gate/切轨
    if (HasProp(cfg,"RespectCastLock") && cfg.RespectCastLock && cast.Locked) {
        acted := Rotation_RunRules_ForCurrentTrack()
        return acted
    }

    ; Busy / Freeze：不推进阶段，仅允规则执行
    if (busy || freeze) {
        acted := Rotation_RunRules_ForCurrentTrack()
        if (acted)
            return true
        return false
    }

    ; Gate（非锁+非 Busy/Frozen，且满足 Gate 冷却与 MinStay）
    elapsed := now - st.StartedAt
    minStay := (curTr && HasProp(curTr,"MinStayMs")) ? curTr.MinStayMs : 0
    if (HasProp(cfg,"GatesEnabled") && cfg.GatesEnabled) {
        if (now >= rt.GateCooldownUntil && elapsed >= minStay) {
            target := Rotation_GateFindMatch()
            if (target > 0 && target != rt.TrackId) {
                Rotation_TryEnterTrackWithSwap(target)
                rt.GateCooldownUntil := now + (HasProp(cfg,"GateCooldownMs") ? cfg.GateCooldownMs : 0)
                return true
            }
        }
    }

    ; 执行当前轨规则
    acted := Rotation_RunRules_ForCurrentTrack()
    if (acted)
        return true

    ; 完成/超时 → 切轨（多轨/NextTrackId）
    trCfg := curTr
    maxDur := (trCfg && HasProp(trCfg,"MaxDurationMs")) ? trCfg.MaxDurationMs : 8000
    done := Rotation_WatchEval()
    timeout := (now - st.StartedAt >= maxDur)
    if (done || timeout) {
        prevId := rt.TrackId
        nextId := Rotation_GetNextTrackId(prevId)
        Rotation_SwapAndEnter(nextId)
        Rot_Log("Track#" prevId " -> Track#" nextId " by " (done?"allOk":"timeout"))
        return true
    }

    return false
}

Rotation_SwapAndEnter(trackId) {
    global gRot
    cfg := gRot["Cfg"]
    if (HasProp(cfg, "SwapKey") && cfg.SwapKey != "") {
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
Rotation_TryEnterTrackWithSwap(trackId) {
    global gRot
    cfg := gRot["Cfg"]
    if (HasProp(cfg, "SwapKey") && cfg.SwapKey!="") {
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
    if (!steps || steps.Length=0)
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
            if (HasProp(cfg, "SwapKey") && cfg.SwapKey!="") {
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
        ; 使用默认轨道的线程（更合理）
        defTid := 1
        try {
            defTid := Rotation_GetTrackById(Rotation_GetDefaultTrackId()).ThreadId
        }
        ; 一次性 Hold 覆盖（按 Step.HoldMs），不改 Skills 本体
        holdOverride := HasProp(stp, "HoldMs") ? Max(0, Integer(stp.HoldMs)) : -1
        ok := WorkerPool_SendSkillIndex(defTid, si, "OpenerStep", holdOverride)
        if (ok) {
            if (HasProp(stp,"Verify") && stp.Verify) {
                ; 可接 RuleEngine_SendVerified 或轻量像素反馈（留空，保持最小改动）
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