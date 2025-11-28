; Rotation_Tick.ahk - 主 Tick / OnSkillSent / SwapAndEnter
;modules\engines\rotation\Rotation_Tick.ahk
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
                return true
            }
            return false
        } else {
            done := Rotation_WatchEval()
            timeout := (A_TickCount - rt.PhaseState.StartedAt >= opener.MaxDurationMs)
            if (done || timeout) {
                nextId := Rotation_GetDefaultTrackId()
                Rotation_EnterTrack(nextId)
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

    ; RespectCastLock：锁定期间仅允规则执行，不推进 Watch/Gate/切轨
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

    ; Gate（满足 Gate 冷却与 MinStay）
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

    ; 完成/超时 → 切轨
    trCfg := curTr
    maxDur := (trCfg && HasProp(trCfg,"MaxDurationMs")) ? trCfg.MaxDurationMs : 8000
    done := Rotation_WatchEval()
    timeout := (now - st.StartedAt >= maxDur)
    if (done || timeout) {
        prevId := rt.TrackId
        nextId := Rotation_GetNextTrackId(prevId)
        Rotation_SwapAndEnter(nextId)
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
Rotation_OnSkillSent(si) {
    if !Rotation_IsEnabled()
        return
    try {
        gRot["RT"].LastSent[si] := A_TickCount
    } catch {
    }
}