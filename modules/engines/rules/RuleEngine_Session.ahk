; RuleEngine_Session.ahk - 非阻塞会话（M1/M2/M3）

RuleEngine_SessionBegin(prof, rIdx, rule) {
    global RE_Session
    RE_Session.Active      := true
    RE_Session.RuleId      := rIdx
    RE_Session.ThreadId    := (HasProp(rule,"ThreadId") ? rule.ThreadId : 1)
    RE_Session.Index       := 1
    RE_Session.StartedAt   := A_TickCount
    RE_Session.HadAnySend  := false
    RE_Session.LockWaitUntil := 0

    try {
        f := Map()
        f["ruleId"] := rIdx
        f["threadId"] := RE_Session.ThreadId
        Logger_Info("RuleEngine", "Session begin", f)
    } catch {
    }

    firstDelay := 0
    try {
        if (rule.Actions.Length >= 1) {
            a1 := rule.Actions[1]
            firstDelay := (HasProp(a1,"DelayMs") ? Max(0, Integer(a1.DelayMs)) : 0)
        }
    }
    RE_Session.NextAt := A_TickCount + firstDelay

    ; 清空验证状态
    RE_Session.VerActive := false
    RE_Session.VerSkillIndex := 0
    RE_Session.VerTargetInt := 0
    RE_Session.VerTol := 0
    RE_Session.VerLastTick := 0
    RE_Session.VerElapsed := 0
    RE_Session.VerTimeoutMs := 0
    RE_Session.VerRetryLeft := 0
    RE_Session.VerRetryGapMs := 150

    ; 会话超时（0=无限）
    sessTo := 0
    try {
        if (HasProp(rule, "SessionTimeoutMs")) {
            sessTo := Max(0, Integer(rule.SessionTimeoutMs))
        }
    }
    if (sessTo > 0) {
        RE_Session.TimeoutAt := A_TickCount + sessTo
    } else {
        RE_Session.TimeoutAt := 0
    }
}

RuleEngine_SessionStep() {
    global App, RE_Session, RE_LastFireTick, RE_Session_CastMarginMs
    if (!RE_Session.Active) {
        return false
    }
    prof := App["ProfileData"]
    rIdx := RE_Session.RuleId
    rule := prof.Rules[rIdx]
    acts := rule.Actions
    now := A_TickCount

    ; 1) 会话超时/中止冷却
    if (RE_Session.TimeoutAt > 0 && now >= RE_Session.TimeoutAt) {
        abortCd := 0
        try if (HasProp(rule, "AbortCooldownMs")) abortCd := Max(0, Integer(rule.AbortCooldownMs))
        if (abortCd > 0) {
            try {
                rule.LastFire := now - rule.CooldownMs + abortCd
                RE_LastFireTick[rIdx] := rule.LastFire
            }
        }
        ; 日志：Session timeout
        try {
            f := Map()
            f["ruleId"] := rIdx
            f["threadId"] := RE_Session.ThreadId
            f["timeoutAt"] := RE_Session.TimeoutAt
            f["elapsed"] := now - RE_Session.StartedAt
            Logger_Warn("RuleEngine", "Session timeout", f)
        } catch {
        }
        RE_Session.Active := false
        return false
    }

    ; 2) 验证（跨帧）
    if (RE_Session.VerActive) {
        if (RE_Session_FreezeActive()) {
            RE_Session.VerLastTick := now
            return false
        }
        if (RE_Session.VerLastTick = 0) {
            RE_Session.VerLastTick := now
            return false
        }
        dt := now - RE_Session.VerLastTick
        if (dt > 0) {
            RE_Session.VerElapsed := RE_Session.VerElapsed + dt
            RE_Session.VerLastTick := now
        }
        si := RE_Session.VerSkillIndex
        if (si >= 1 && si <= prof.Skills.Length) {
            s := prof.Skills[si]
            cur := Pixel_FrameGet(s.X, s.Y)
            match := Pixel_ColorMatch(cur, RE_Session.VerTargetInt, s.Tol)
            if (!match) {
                ; 通过
                RE_Session.VerActive := false
                RE_Session.VerSkillIndex := 0
                RE_Session.VerTargetInt := 0
                RE_Session.VerTol := 0
                RE_Session.Index := RE_Session.Index + 1
                gap := (HasProp(rule,"ActionGapMs") ? Max(0, Integer(rule.ActionGapMs)) : 0)
                nextDelay := 0
                if (RE_Session.Index <= acts.Length) {
                    nextAct := acts[RE_Session.Index]
                    nextDelay := (HasProp(nextAct,"DelayMs") ? Max(0, Integer(nextAct.DelayMs)) : 0)
                }
                RE_Session.NextAt := now + gap + nextDelay
                return false
            }
        }
        if (RE_Session.VerElapsed >= RE_Session.VerTimeoutMs) {
            if (RE_Session.VerRetryLeft > 0) {
                RE_Session.VerRetryLeft := RE_Session.VerRetryLeft - 1
                RE_Session.VerElapsed := 0
                RE_Session.VerLastTick := now
                RE_Session.VerActive := false
                RE_Session.NextAt := now + RE_Session.VerRetryGapMs
                 ; 日志：Verify retry scheduled
                try {
                    f := Map()
                    f["ruleId"] := rIdx
                    f["actIdx"] := RE_Session.Index
                    f["threadId"] := RE_Session.ThreadId
                    f["retryLeft"] := RE_Session.VerRetryLeft
                    f["gapMs"] := RE_Session.VerRetryGapMs
                    Logger_Info("RuleEngine", "Verify retry scheduled", f)
                } catch {
                }
                return false
            } else {
                abortCd := 0
                try if (HasProp(rule, "AbortCooldownMs")) abortCd := Max(0, Integer(rule.AbortCooldownMs))
                if (abortCd > 0) {
                    try {
                        rule.LastFire := now - rule.CooldownMs + abortCd
                        RE_LastFireTick[rIdx] := rule.LastFire
                    }
                }
                ; 日志：Verify timeout abort
                try {
                    f := Map()
                    f["ruleId"] := rIdx
                    f["actIdx"] := RE_Session.Index
                    f["threadId"] := RE_Session.ThreadId
                    f["skillIdx"] := RE_Session.VerSkillIndex
                    f["elapsed"] := RE_Session.VerElapsed
                    f["timeoutMs"] := RE_Session.VerTimeoutMs
                    Logger_Warn("RuleEngine", "Verify timeout abort", f)
                } catch {
                }
                RE_Session.Active := false
                return false
            }
        }
        return false
    }

    ; 3) 发送阶段
    if (RE_Session.Index > acts.Length) {
        if (RE_Session.HadAnySend) {
            try {
                rule.LastFire := now
                RE_LastFireTick[rIdx] := now
            }
        }
         ; 日志：Session end
        try {
            f := Map()
            f["ruleId"] := rIdx
            Logger_Info("RuleEngine", "Session end", f)
        } catch {
        }
        RE_Session.Active := false
        return false
    }
    if (now < RE_Session.NextAt) {
        return false
    }

    thr := RE_Session.ThreadId
    lk := WorkerPool_CastIsLocked(thr)
    if (lk.Locked) {
        budget := 0
        if (RE_Session.Index > 1) {
            prevAct := acts[RE_Session.Index - 1]
            prevSi  := HasProp(prevAct,"SkillIndex") ? prevAct.SkillIndex : 0
            if (prevSi >= 1 && prevSi <= prof.Skills.Length) {
                try budget := Max(0, Integer(HasProp(prof.Skills[prevSi],"CastMs") ? prof.Skills[prevSi].CastMs : 0))
            }
        }
        budget := budget + RE_Session_CastMarginMs
        if (RE_Session.LockWaitUntil = 0) {
            RE_Session.LockWaitUntil := now + budget
            return false
        }
        if (now < RE_Session.LockWaitUntil) {
            return false
        }
        abortCd := 0
        try if (HasProp(rule, "AbortCooldownMs")) abortCd := Max(0, Integer(rule.AbortCooldownMs))
        if (abortCd > 0) {
            try {
                rule.LastFire := now - rule.CooldownMs + abortCd
                RE_LastFireTick[rIdx] := rule.LastFire
            }
        }
         ; 日志：Cast lock abort
        try {
            f := Map()
            f["ruleId"] := rIdx
            f["actIdx"] := RE_Session.Index
            f["threadId"] := thr
            f["budgetMs"] := budget
            f["locked"] := 1
            Logger_Warn("RuleEngine", "Cast lock abort", f)
        } catch {
        }
        RE_Session.Active := false
        return false
    } else {
        RE_Session.LockWaitUntil := 0
    }

    idx := RE_Session.Index
    act := acts[idx]
    si  := HasProp(act,"SkillIndex") ? act.SkillIndex : 0
    if (si < 1 || si > prof.Skills.Length) {
        RE_Session.Active := false
        return false
    }

    needReady := 0
    try needReady := (HasProp(act, "RequireReady") && act.RequireReady) ? 1 : 0
    if (needReady) {
        if (!RuleEngine_CheckSkillReady(prof, si)) {
            return false
        }
    }

    holdOverride := -1
    try {
        if (HasProp(act, "HoldMs")) {
            hm := Integer(act.HoldMs)
            if (hm >= 0)
                holdOverride := hm
        }
    }

    sent := WorkerPool_SendSkillIndex(thr, si, "RuleSession:" rule.Name, holdOverride)
    if (!sent) {
        retryLeft := 0, retryGap := 150
        try retryLeft := Max(0, Integer(HasProp(act,"Retry") ? act.Retry : 0))
        try retryGap := Max(0, Integer(HasProp(act,"RetryGapMs") ? act.RetryGapMs : 150))
        if (retryLeft > 0) {
            RE_Session.NextAt := now + retryGap
            return false
        }
        abortCd := 0
        try if (HasProp(rule, "AbortCooldownMs")) abortCd := Max(0, Integer(rule.AbortCooldownMs))
        if (abortCd > 0) {
            try {
                rule.LastFire := now - rule.CooldownMs + abortCd
                RE_LastFireTick[rIdx] := rule.LastFire
            }
        }
        ; 日志：Send fail abort
        try {
            f := Map()
            f["ruleId"] := rIdx
            f["actIdx"] := idx
            f["skillIdx"] := si
            f["threadId"] := thr
            Logger_Warn("RuleEngine", "Send fail abort", f)
        } catch {
        }
        RE_Session.Active := false
        return false
    }

    RE_Session.HadAnySend := true

    ; 日志：Action sent
    try {
        f := Map()
        f["ruleId"] := rIdx
        f["actIdx"] := idx
        f["skillIdx"] := si
        f["threadId"] := thr
        f["hold"] := holdOverride
        Logger_Info("RuleEngine", "Action sent", f)
    } catch {
    }

    needVerify := 0
    try needVerify := (HasProp(act, "Verify") && act.Verify) ? 1 : 0
    if (needVerify) {
        s := prof.Skills[si]
        RE_Session.VerActive := true
        RE_Session.VerSkillIndex := si
        RE_Session.VerTargetInt := Pixel_HexToInt(s.Color)
        RE_Session.VerTol := s.Tol
        RE_Session.VerLastTick := now
        RE_Session.VerElapsed := 0
        try {
            RE_Session.VerTimeoutMs := Max(0, Integer(HasProp(act,"VerifyTimeoutMs") ? act.VerifyTimeoutMs : 600))
            RE_Session.VerRetryLeft := Max(0, Integer(HasProp(act,"Retry") ? act.Retry : 0))
            RE_Session.VerRetryGapMs := Max(0, Integer(HasProp(act,"RetryGapMs") ? act.RetryGapMs : 150))
        }
        return true
    }

    ; 不需要验证 -> 推进到下一个动作
    RE_Session.Index := idx + 1
    gap := (HasProp(rule,"ActionGapMs") ? Max(0, Integer(rule.ActionGapMs)) : 0)
    nextDelay := 0
    if (RE_Session.Index <= acts.Length) {
        nextAct := acts[RE_Session.Index]
        nextDelay := (HasProp(nextAct,"DelayMs") ? Max(0, Integer(nextAct.DelayMs)) : 0)
    }
    RE_Session.NextAt := now + gap + nextDelay

    return true
}