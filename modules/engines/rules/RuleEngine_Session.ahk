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
    } catch {
        firstDelay := 0
    }

    ; 若启用施法条且配置为忽略动作延迟，则不使用首个 DelayMs
    ignoreDelay := 0
    try {
        if HasProp(prof, "CastBar") {
            if (prof.CastBar.Enabled && HasProp(prof.CastBar, "IgnoreActionDelay")) {
                if (prof.CastBar.IgnoreActionDelay) {
                    ignoreDelay := 1
                }
            }
        }
    } catch {
        ignoreDelay := 0
    }
    if (ignoreDelay) {
        firstDelay := 0
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
    global App
    global RE_Session
    global RE_LastFireTick
    global RE_Session_CastMarginMs

    if (!RE_Session.Active) {
        return false
    }

    prof := App["ProfileData"]
    rIdx := RE_Session.RuleId
    rule := prof.Rules[rIdx]
    acts := rule.Actions
    now  := A_TickCount

    ; CastBar 与 IgnoreActionDelay 标志
    castUse     := 0
    ignoreDelay := 0
    try {
        if HasProp(prof, "CastBar") {
            if (prof.CastBar.Enabled) {
                castUse := 1
                if HasProp(prof.CastBar, "IgnoreActionDelay") {
                    if (prof.CastBar.IgnoreActionDelay) {
                        ignoreDelay := 1
                    }
                }
            }
        }
    } catch {
        castUse     := 0
        ignoreDelay := 0
    }

    ; 1) 会话整体超时 / 中止冷却
    if (RE_Session.TimeoutAt > 0) {
        if (now >= RE_Session.TimeoutAt) {
            abortCd := 0
            try {
                if HasProp(rule, "AbortCooldownMs") {
                    abortCd := Max(0, Integer(rule.AbortCooldownMs))
                }
            } catch {
                abortCd := 0
            }

            if (abortCd > 0) {
                try {
                    rule.LastFire := now - rule.CooldownMs + abortCd
                    RE_LastFireTick[rIdx] := rule.LastFire
                } catch {
                }
            }

            ; 日志：Session timeout
            try {
                f := Map()
                f["ruleId"]   := rIdx
                f["threadId"] := RE_Session.ThreadId
                f["timeoutAt"]:= RE_Session.TimeoutAt
                f["elapsed"]  := now - RE_Session.StartedAt
                Logger_Warn("RuleEngine", "Session timeout", f)
            } catch {
            }

            ; Cast 引擎调试日志
            try {
                CastEngine_LogCurrentRuleIfNeeded("SessionTimeout")
            } catch {
            }

            RE_Session.Active := false
            return false
        }
    }

    ; 2) 验证阶段（跨帧）
    if (RE_Session.VerActive) {
        ; 冻结窗（黑屏）保护
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

        ; ========= CastBar 优先：快速失败 / 成功判定 =========
        if (castUse) {
            actIdx := RE_Session.Index
            siCast := RE_Session.VerSkillIndex
            ce := 0
            try {
                ce := CastEngine_GetEntry(rIdx, actIdx, siCast)
            } catch {
                ce := 0
            }

            if IsObject(ce) {
                st := 0
                try {
                    st := ce.State
                } catch {
                    st := 0
                }

                ; CastEngine 认为本次尝试 FAILED（条未亮 / 接受窗口超时 / 读条卡死）
                if (st = CAST_STATE_FAILED) {
                    if (RE_Session.VerRetryLeft > 0) {
                        RE_Session.VerRetryLeft := RE_Session.VerRetryLeft - 1
                        RE_Session.VerElapsed   := 0
                        RE_Session.VerLastTick  := now
                        RE_Session.VerActive    := false
                        RE_Session.NextAt       := now + RE_Session.VerRetryGapMs

                        ; 日志：Verify retry scheduled (CastBar)
                        try {
                            fcb := Map()
                            fcb["ruleId"]    := rIdx
                            fcb["actIdx"]    := RE_Session.Index
                            fcb["threadId"]  := RE_Session.ThreadId
                            fcb["retryLeft"] := RE_Session.VerRetryLeft
                            fcb["gapMs"]     := RE_Session.VerRetryGapMs
                            Logger_Info("RuleEngine", "Verify retry scheduled (CastBar)", fcb)
                        } catch {
                        }

                        return false
                    } else {
                        ; 无剩余重试 -> 视为验证失败，中止本次会话
                        abortCd2 := 0
                        try {
                            if HasProp(rule, "AbortCooldownMs") {
                                abortCd2 := Max(0, Integer(rule.AbortCooldownMs))
                            }
                        } catch {
                            abortCd2 := 0
                        }

                        if (abortCd2 > 0) {
                            try {
                                rule.LastFire := now - rule.CooldownMs + abortCd2
                                RE_LastFireTick[rIdx] := rule.LastFire
                            } catch {
                            }
                        }

                        ; 日志：Verify timeout abort (CastBar)
                        try {
                            f2 := Map()
                            f2["ruleId"]    := rIdx
                            f2["actIdx"]    := RE_Session.Index
                            f2["threadId"]  := RE_Session.ThreadId
                            f2["skillIdx"]  := RE_Session.VerSkillIndex
                            f2["elapsed"]   := RE_Session.VerElapsed
                            f2["timeoutMs"] := RE_Session.VerTimeoutMs
                            Logger_Warn("RuleEngine", "Verify timeout abort (CastBar)", f2)
                        } catch {
                        }

                        ; Cast 引擎调试日志
                        try {
                            CastEngine_LogCurrentRuleIfNeeded("VerifyTimeoutAbort")
                        } catch {
                        }

                        RE_Session.Active := false
                        return false
                    }
                }

                ; CastEngine 认为 DONE（条亮过并正常结束） -> 直接视为本次尝试成功
                if (st = CAST_STATE_DONE) {
                    RE_Session.VerActive     := false
                    RE_Session.VerSkillIndex := 0
                    RE_Session.VerTargetInt  := 0
                    RE_Session.VerTol        := 0

                    RE_Session.Index := RE_Session.Index + 1

                    gap := 0
                    try {
                        if HasProp(rule, "ActionGapMs") {
                            gap := Max(0, Integer(rule.ActionGapMs))
                        } else {
                            gap := 0
                        }
                    } catch {
                        gap := 0
                    }

                    nextDelay := 0
                    if (RE_Session.Index <= acts.Length) {
                        nextAct := acts[RE_Session.Index]
                        try {
                            if HasProp(nextAct, "DelayMs") {
                                nextDelay := Max(0, Integer(nextAct.DelayMs))
                            } else {
                                nextDelay := 0
                            }
                        } catch {
                            nextDelay := 0
                        }
                    }

                    if (ignoreDelay) {
                        gap       := 0
                        nextDelay := 0
                    }

                    RE_Session.NextAt := now + gap + nextDelay
                    return false
                }
            }
        }

        ; ========= 原有：技能格子颜色 Verify（兜底） =========
        si := RE_Session.VerSkillIndex
        if (si >= 1) {
            if (si <= prof.Skills.Length) {
                s := prof.Skills[si]
                cur := Pixel_FrameGet(s.X, s.Y)
                match := Pixel_ColorMatch(cur, RE_Session.VerTargetInt, s.Tol)
                if (!match) {
                    ; 通过（颜色变了）
                    RE_Session.VerActive     := false
                    RE_Session.VerSkillIndex := 0
                    RE_Session.VerTargetInt  := 0
                    RE_Session.VerTol        := 0

                    RE_Session.Index := RE_Session.Index + 1

                    gap2 := 0
                    try {
                        if HasProp(rule, "ActionGapMs") {
                            gap2 := Max(0, Integer(rule.ActionGapMs))
                        } else {
                            gap2 := 0
                        }
                    } catch {
                        gap2 := 0
                    }

                    nextDelay2 := 0
                    if (RE_Session.Index <= acts.Length) {
                        nextAct2 := acts[RE_Session.Index]
                        try {
                            if HasProp(nextAct2, "DelayMs") {
                                nextDelay2 := Max(0, Integer(nextAct2.DelayMs))
                            } else {
                                nextDelay2 := 0
                            }
                        } catch {
                            nextDelay2 := 0
                        }
                    }

                    if (ignoreDelay) {
                        gap2       := 0
                        nextDelay2 := 0
                    }

                    RE_Session.NextAt := now + gap2 + nextDelay2
                    return false
                }
            }
        }

        ; 颜色未变，检查是否超出本次 Verify 的最大等待
        if (RE_Session.VerElapsed >= RE_Session.VerTimeoutMs) {
            if (RE_Session.VerRetryLeft > 0) {
                RE_Session.VerRetryLeft := RE_Session.VerRetryLeft - 1
                RE_Session.VerElapsed   := 0
                RE_Session.VerLastTick  := now
                RE_Session.VerActive    := false
                RE_Session.NextAt       := now + RE_Session.VerRetryGapMs

                ; 日志：Verify retry scheduled
                try {
                    f3 := Map()
                    f3["ruleId"]    := rIdx
                    f3["actIdx"]    := RE_Session.Index
                    f3["threadId"]  := RE_Session.ThreadId
                    f3["retryLeft"] := RE_Session.VerRetryLeft
                    f3["gapMs"]     := RE_Session.VerRetryGapMs
                    Logger_Info("RuleEngine", "Verify retry scheduled", f3)
                } catch {
                }

                return false
            } else {
                abortCd3 := 0
                try {
                    if HasProp(rule, "AbortCooldownMs") {
                        abortCd3 := Max(0, Integer(rule.AbortCooldownMs))
                    }
                } catch {
                    abortCd3 := 0
                }

                if (abortCd3 > 0) {
                    try {
                        rule.LastFire := now - rule.CooldownMs + abortCd3
                        RE_LastFireTick[rIdx] := rule.LastFire
                    } catch {
                    }
                }

                ; 日志：Verify timeout abort
                try {
                    f4 := Map()
                    f4["ruleId"]    := rIdx
                    f4["actIdx"]    := RE_Session.Index
                    f4["threadId"]  := RE_Session.ThreadId
                    f4["skillIdx"]  := RE_Session.VerSkillIndex
                    f4["elapsed"]   := RE_Session.VerElapsed
                    f4["timeoutMs"] := RE_Session.VerTimeoutMs
                    Logger_Warn("RuleEngine", "Verify timeout abort", f4)
                } catch {
                }

                ; Cast 引擎调试日志
                try {
                    CastEngine_LogCurrentRuleIfNeeded("VerifyTimeoutAbort")
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
            } catch {
            }
        }

        ; 日志：Session end
        try {
            f5 := Map()
            f5["ruleId"] := rIdx
            Logger_Info("RuleEngine", "Session end", f5)
        } catch {
        }

        ; Cast 引擎调试日志
        try {
            CastEngine_LogCurrentRuleIfNeeded("SessionEnd")
        } catch {
        }

        RE_Session.Active := false
        return false
    }

    if (now < RE_Session.NextAt) {
        return false
    }

    ; CastBar + LockDuringCast：若前置动作有锁定中的技能，则等待
    if (castUse) {
        canProceed := true
        try {
            canProceed := RuleEngine_CanProceedNextActionByCastBar(RE_Session.Index, rIdx)
        } catch {
            canProceed := true
        }
        if (!canProceed) {
            return false
        }
    }

    thr := RE_Session.ThreadId
    lk  := WorkerPool_CastIsLocked(thr)
    if (lk.Locked) {
        budget := 0
        if (RE_Session.Index > 1) {
            prevAct := acts[RE_Session.Index - 1]
            prevSi  := 0
            if HasProp(prevAct, "SkillIndex") {
                prevSi := prevAct.SkillIndex
            }
            if (prevSi >= 1) {
                if (prevSi <= prof.Skills.Length) {
                    try {
                        if HasProp(prof.Skills[prevSi], "CastMs") {
                            budget := Max(0, Integer(prof.Skills[prevSi].CastMs))
                        } else {
                            budget := 0
                        }
                    } catch {
                        budget := 0
                    }
                }
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

        abortCd4 := 0
        try {
            if HasProp(rule, "AbortCooldownMs") {
                abortCd4 := Max(0, Integer(rule.AbortCooldownMs))
            }
        } catch {
            abortCd4 := 0
        }

        if (abortCd4 > 0) {
            try {
                rule.LastFire := now - rule.CooldownMs + abortCd4
                RE_LastFireTick[rIdx] := rule.LastFire
            } catch {
            }
        }

        ; 日志：Cast lock abort
        try {
            f6 := Map()
            f6["ruleId"]   := rIdx
            f6["actIdx"]   := RE_Session.Index
            f6["threadId"] := thr
            f6["budgetMs"] := budget
            f6["locked"]   := 1
            Logger_Warn("RuleEngine", "Cast lock abort", f6)
        } catch {
        }

        ; Cast 引擎调试日志
        try {
            CastEngine_LogCurrentRuleIfNeeded("CastLockAbort")
        } catch {
        }

        RE_Session.Active := false
        return false
    } else {
        RE_Session.LockWaitUntil := 0
    }

    idx := RE_Session.Index
    act := acts[idx]
    si2 := 0
    if HasProp(act, "SkillIndex") {
        si2 := act.SkillIndex
    }

    if (si2 < 1) {
        RE_Session.Active := false
        return false
    }
    if (si2 > prof.Skills.Length) {
        RE_Session.Active := false
        return false
    }

    needReady := 0
    try {
        if HasProp(act, "RequireReady") {
            if act.RequireReady {
                needReady := 1
            } else {
                needReady := 0
            }
        } else {
            needReady := 0
        }
    } catch {
        needReady := 0
    }

    if (needReady) {
        if (!RuleEngine_CheckSkillReady(prof, si2)) {
            return false
        }
    }

    holdOverride := -1
    try {
        if HasProp(act, "HoldMs") {
            hm := Integer(act.HoldMs)
            if (hm >= 0) {
                holdOverride := hm
            }
        }
    } catch {
        holdOverride := -1
    }

    sent := WorkerPool_SendSkillIndex(thr, si2, "RuleSession:" rule.Name, holdOverride)
    if (!sent) {
        retryLeft2 := 0
        retryGap2  := 150

        try {
            if HasProp(act, "Retry") {
                retryLeft2 := Max(0, Integer(act.Retry))
            } else {
                retryLeft2 := 0
            }
        } catch {
            retryLeft2 := 0
        }

        try {
            if HasProp(act, "RetryGapMs") {
                retryGap2 := Max(0, Integer(act.RetryGapMs))
            } else {
                retryGap2 := 150
            }
        } catch {
            retryGap2 := 150
        }

        if (retryLeft2 > 0) {
            RE_Session.NextAt := now + retryGap2
            return false
        }

        abortCd5 := 0
        try {
            if HasProp(rule, "AbortCooldownMs") {
                abortCd5 := Max(0, Integer(rule.AbortCooldownMs))
            }
        } catch {
            abortCd5 := 0
        }

        if (abortCd5 > 0) {
            try {
                rule.LastFire := now - rule.CooldownMs + abortCd5
                RE_LastFireTick[rIdx] := rule.LastFire
            } catch {
            }
        }

        ; 日志：Send fail abort
        try {
            f7 := Map()
            f7["ruleId"]   := rIdx
            f7["actIdx"]   := idx
            f7["skillIdx"] := si2
            f7["threadId"] := thr
            Logger_Warn("RuleEngine", "Send fail abort", f7)
        } catch {
        }

        ; Cast 引擎调试日志
        try {
            CastEngine_LogCurrentRuleIfNeeded("SendFailAbort")
        } catch {
        }

        RE_Session.Active := false
        return false
    }

    RE_Session.HadAnySend := true

    ; 日志：Action sent
    try {
        f8 := Map()
        f8["ruleId"]   := rIdx
        f8["actIdx"]   := idx
        f8["skillIdx"] := si2
        f8["threadId"] := thr
        f8["hold"]     := holdOverride
        Logger_Info("RuleEngine", "Action sent", f8)
    } catch {
    }

    needVerify := 0
    try {
        if HasProp(act, "Verify") {
            if act.Verify {
                needVerify := 1
            } else {
                needVerify := 0
            }
        } else {
            needVerify := 0
        }
    } catch {
        needVerify := 0
    }

    if (needVerify) {
        s2 := prof.Skills[si2]
        RE_Session.VerActive      := true
        RE_Session.VerSkillIndex  := si2
        RE_Session.VerTargetInt   := Pixel_HexToInt(s2.Color)
        RE_Session.VerTol         := s2.Tol
        RE_Session.VerLastTick    := now
        RE_Session.VerElapsed     := 0

        try {
            if HasProp(act, "VerifyTimeoutMs") {
                RE_Session.VerTimeoutMs := Max(0, Integer(act.VerifyTimeoutMs))
            } else {
                RE_Session.VerTimeoutMs := 600
            }
        } catch {
            RE_Session.VerTimeoutMs := 600
        }

        try {
            if HasProp(act, "Retry") {
                RE_Session.VerRetryLeft := Max(0, Integer(act.Retry))
            } else {
                RE_Session.VerRetryLeft := 0
            }
        } catch {
            RE_Session.VerRetryLeft := 0
        }

        try {
            if HasProp(act, "RetryGapMs") {
                RE_Session.VerRetryGapMs := Max(0, Integer(act.RetryGapMs))
            } else {
                RE_Session.VerRetryGapMs := 150
            }
        } catch {
            RE_Session.VerRetryGapMs := 150
        }

        return true
    }

    ; 不需要验证 -> 推进到下一个动作
    RE_Session.Index := idx + 1

    gap3 := 0
    try {
        if HasProp(rule, "ActionGapMs") {
            gap3 := Max(0, Integer(rule.ActionGapMs))
        } else {
            gap3 := 0
        }
    } catch {
        gap3 := 0
    }

    nextDelay3 := 0
    if (RE_Session.Index <= acts.Length) {
        nextAct3 := acts[RE_Session.Index]
        try {
            if HasProp(nextAct3, "DelayMs") {
                nextDelay3 := Max(0, Integer(nextAct3.DelayMs))
            } else {
                nextDelay3 := 0
            }
        } catch {
            nextDelay3 := 0
        }
    }

    if (ignoreDelay) {
        gap3       := 0
        nextDelay3 := 0
    }

    RE_Session.NextAt := now + gap3 + nextDelay3
    return true
}

RuleEngine_CanProceedNextActionByCastBar(currActionIndex, ruleIndex) {
    global gCast, CAST_STATE_CASTING

    ; 若当前无 Cast 会话或规则不匹配，则不做限制
    if !IsObject(gCast) {
        return true
    }
    if !gCast.Active {
        return true
    }
    try {
        if (gCast.RuleIndex != ruleIndex) {
            return true
        }
    } catch {
        return true
    }

    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]

        actIdx := 0
        lockFlag := 0
        st := 0
        try {
            actIdx := e.ActionIndex
        } catch {
            actIdx := 0
        }
        try {
            lockFlag := e.LockDuringCast
        } catch {
            lockFlag := 0
        }
        try {
            st := e.State
        } catch {
            st := 0
        }

        ; 若某个前置动作的技能仍在 CASTING 且配置为锁定施放，则当前动作不得发送
        if (actIdx < currActionIndex && lockFlag && st = CAST_STATE_CASTING) {
            return false
        }

        i := i + 1
    }
    return true
}