; Rotation_Tick.ahk - 主 Tick / OnSkillSent / SwapAndEnter

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
    thr := (curTr && HasProp(curTr, "ThreadId")) ? curTr.ThreadId : 1
    cast := WorkerPool_CastIsLocked(thr)
    freeze := (now < rt.FreezeUntil)
    busy := (now < rt.BusyUntil)
    Logger_Info("Diag", "State", Map(
        "trackId", rt.TrackId,
        "castLocked", (cast.Locked ? 1 : 0),
        "busy", (busy ? 1 : 0),
        "freeze", (freeze ? 1 : 0),
        "busyUntil", rt.BusyUntil,
        "freezeUntil", rt.FreezeUntil,
        "now", now
    ))
    ; RespectCastLock：锁定期间仅允规则执行，不推进 Watch/Gate/切轨
    if (HasProp(cfg, "RespectCastLock") && cfg.RespectCastLock && cast.Locked) {
        acted := Rotation_RunRules_ForCurrentTrack()
        return acted
    }

    ; Busy / Freeze：不推进阶段，仅允规则执行
    if (busy || freeze) {
        try Logger_Info("Diag", "Branch", Map("where", "BusyOrFreeze", "trackId", rt.TrackId))
        acted := Rotation_RunRules_ForCurrentTrack()
        try Logger_Info("Diag", "RunRules.call", Map("where", "BusyOrFreeze", "acted", (acted ? 1 : 0), "trackId", rt.TrackId
        ))
        if (acted)
            return true
        return false
    }

    ; Gate（满足 Gate 冷却与 MinStay）
    elapsed := now - st.StartedAt
    minStay := (curTr && HasProp(curTr, "MinStayMs")) ? curTr.MinStayMs : 0
    Logger_Info("Diag", "Gate.check", Map("trackId", rt.TrackId, "gatesEnabled", cfg.GatesEnabled, "coolOK", now >= rt.GateCooldownUntil,
        "elapsed", elapsed, "minStay", minStay))
    if (HasProp(cfg, "GatesEnabled") && cfg.GatesEnabled) {
        if (now >= rt.GateCooldownUntil && elapsed >= minStay) {
            target := 0
            try {
                target := Rotation_GateFindMatch()
            } catch as e {
                ; 捕获 GateFindMatch 内部异常
                Logger_Exception("Rotation", e, Map("where", "GateFindMatch", "trackId", rt.TrackId))
                return false
            }
            Logger_Info("Diag", "Gate.match", Map("trackId", rt.TrackId, "target", target))
            if (target > 0 && target != rt.TrackId) {
                Rotation_TryEnterTrackWithSwap(target)
                rt.GateCooldownUntil := now + (HasProp(cfg, "GateCooldownMs") ? cfg.GateCooldownMs : 0)
                return true
            }
        }
    }
    try Logger_Info("Diag", "RunRules.call", Map("trackId", rt.TrackId))
    ; 执行当前轨规则
    try Logger_Info("Diag", "RunRules.call", Map("where", "Normal", "trackId", rt.TrackId))
    acted := Rotation_RunRules_ForCurrentTrack()
    if (acted)
        return true

    ; 完成/超时 → 切轨
    trCfg := curTr
    maxDur := (trCfg && HasProp(trCfg, "MaxDurationMs")) ? trCfg.MaxDurationMs : 8000
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
