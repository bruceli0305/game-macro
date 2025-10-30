; RuleEngine.ahk - 技能循环规则引擎（含日志、计数规则模式、发送回执校验、顺序优化）

; ========== 日志与调试开关 ==========
global RE_Debug := true               ; 总开关：日志开/关
global RE_DebugVerbose := true        ; 详细级：打印每个条件细节

RE_LogFilePath() {
    return A_ScriptDir "\Logs\ruleengine.log"
}
RE_Log(msg, level := "INFO") {
    if !RE_Debug
        return
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend ts " [RuleEngine] [" level "] " msg "`r`n", RE_LogFilePath(), "UTF-8"
}
RE_LogV(msg) {
    if RE_DebugVerbose
        RE_Log(msg, "VERB")
}
RE_SkillNameByIndex(prof, idx) {
    return (idx>=1 && idx<=prof.Skills.Length) ? prof.Skills[idx].Name : ("技能#" idx)
}
RE_ColorHex(n) {
    return Format("0x{:06X}", n & 0xFFFFFF)
}
RE_List(arr) {
    out := ""
    for i, v in arr
        out .= (i=1 ? "" : ",") v
    return out
}
; ====================================

; ========== 发送回执校验（高延迟建议启用） ==========
global RE_VerifySend := true              ; 是否启用发送后像素回执校验
global RE_VerifyForCounterOnly := true    ; 仅对含计数条件的规则启用
global RE_VerifyWaitMs := 150             ; 发送后等待首帧反馈的延时
global RE_VerifyTimeoutMs := 600          ; 在此时间内应看到像素由“就绪”变为“非就绪”
global RE_VerifyRetry := 1                ; 失败重试次数（0=不重试）

RuleEngine_SendVerified(thr, idx, ruleName) {
    global App
    s := App["ProfileData"].Skills[idx]
    ; 首发
    ok := WorkerPool_SendSkillIndex(thr, idx, "Rule:" ruleName)
    if !ok {
        RE_Log("  Send initial FAIL for idx=" idx " name=" s.Name, "WARN")
        return false
    }
    if !RE_VerifySend
        return true

    attempt := 0
    loop RE_VerifyRetry + 1 {
        if (attempt > 0) {
            RE_Log("  Verify attempt#" (attempt+1) " (retry send)")
            WorkerPool_SendSkillIndex(thr, idx, "Retry:" ruleName)
        } else {
            RE_Log("  Verify attempt#" (attempt+1))
        }

        Sleep RE_VerifyWaitMs
        t0 := A_TickCount
        tgt := Pixel_HexToInt(s.Color)
        success := false
        while (A_TickCount - t0 <= RE_VerifyTimeoutMs) {
            ; 实时取色，避免帧缓存
            cur := PixelGetColor(s.X, s.Y, "RGB")
            match := Pixel_ColorMatch(cur, tgt, s.Tol)
            if !match {
                success := true
                break
            }
            Sleep 10
        }
        RE_Log("  Verify result -> " (success ? "OK" : "FAIL"))
        if success
            return true
        attempt += 1
        if (attempt > RE_VerifyRetry)
            break
    }
    return false
}
; ==============================================

; 是否包含至少一个计数条件（启用“计数规则模式”）
RuleEngine_HasCounterCond(rule) {
    for _, c in rule.Conditions
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER")
            return true
    return false
}

; 检查某技能的像素就绪（按技能自身 X/Y/Color/Tol），使用帧缓存
RuleEngine_CheckSkillReady(prof, idx) {
    if (idx < 1 || idx > prof.Skills.Length)
        return false
    s := prof.Skills[idx]
    cur := Pixel_FrameGet(s.X, s.Y)
    tgt := Pixel_HexToInt(s.Color)
    ok  := Pixel_ColorMatch(cur, tgt, s.Tol)
    RE_LogV(Format("  ReadyCheck idx={1} name={2} X={3} Y={4} cur={5} tgt={6} tol={7} -> {8}"
        , idx, s.Name, s.X, s.Y, RE_ColorHex(cur), RE_ColorHex(tgt), s.Tol, ok))
    return ok
}

; 返回 true 表示本 Tick 已触发某规则（避免并发触发单技能扫描）
RuleEngine_RunTick() {
    global App
    prof := App["ProfileData"]
    static tick := 0
    tick++

    now := A_TickCount
    if (prof.Rules.Length = 0) {
        RE_Log("Tick#" tick " no rules configured")
        ToolTip "没有配置规则"
        SetTimer () => ToolTip(), -1000
        return false
    }

    RE_Log("Tick#" tick " begin, rules=" prof.Rules.Length " now=" now)

    for _, r in prof.Rules {
        if !r.Enabled {
            RE_LogV("Tick#" tick " skip disabled rule: " r.Name)
            continue
        }
        last := HasProp(r, "LastFire") ? r.LastFire : 0
        remain := r.CooldownMs - (now - last)
        if (remain > 0) {
            RE_LogV("Tick#" tick " skip by cooldown: " r.Name " remain=" remain "ms (cd=" r.CooldownMs ", last=" last ")")
            continue
        }

        ok := RuleEngine_EvalRule(r, prof)
        if !ok {
            RE_LogV("Tick#" tick " rule not matched: " r.Name)
            continue
        }

        RE_Log("Tick#" tick " FIRE rule: " r.Name " thr=" (HasProp(r,"ThreadId")?r.ThreadId:1))
        sent := RuleEngine_Fire(r, prof)   ; 返回是否真的发送了至少一个动作
        if sent {
            r.LastFire := A_TickCount
            RE_Log("Tick#" tick " rule fired, set LastFire=" r.LastFire)
            SetTimer () => ToolTip(), -1000
            return true
        } else {
            RE_Log("Tick#" tick " rule matched but no action sent (no ready) -> no cooldown")
        }
    }

    RE_Log("Tick#" tick " no rule matched")
    ToolTip "没有符合条件的规则"
    SetTimer () => ToolTip(), -1000
    return false
}

; 评估规则：先评估计数条件，后评估像素条件（更高效），保留短路逻辑
RuleEngine_EvalRule(rule, prof) {
    if (rule.Conditions.Length = 0) {
        RE_Log("Rule '" rule.Name "' has no conditions -> false")
        return false
    }
    logicAnd := (StrUpper(rule.Logic) = "AND")
    any := false, all := true
    i := 0

    ; 两段：先 Counter，后 Pixel
    evalList := []
    for _, c in rule.Conditions
        if (HasProp(c,"Kind") && StrUpper(c.Kind)="COUNTER")
            evalList.Push(c)
    for _, c in rule.Conditions
        if !(HasProp(c,"Kind") && StrUpper(c.Kind)="COUNTER")
            evalList.Push(c)

    for _, c in evalList {
        i++
        res := false

        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            si  := HasProp(c,"SkillIndex") ? c.SkillIndex : 1
            cnt := Counters_Get(si)
            cmp := StrUpper(HasProp(c,"Cmp") ? c.Cmp : "GE")
            val := HasProp(c,"Value") ? Integer(c.Value) : 1
            switch cmp {
                case "GE": res := (cnt >= val)
                case "EQ": res := (cnt  = val)
                case "GT": res := (cnt  > val)
                case "LE": res := (cnt <= val)
                case "LT": res := (cnt  < val)
                default:   res := (cnt >= val)
            }
            RE_LogV(Format("Cond#{1} Counter: skill={2}({3}) cnt={4} cmp={5} val={6} -> {7}"
                , i, si, RE_SkillNameByIndex(prof, si), cnt, cmp, val, res))
        } else {
            refType := StrUpper(HasProp(c,"RefType") ? c.RefType : "SKILL")
            refIdx  := HasProp(c,"RefIndex") ? c.RefIndex : 1
            op      := StrUpper(HasProp(c,"Op") ? c.Op : "EQ")
            if (refType = "SKILL") {
                if (refIdx >= 1 && refIdx <= prof.Skills.Length) {
                    s := prof.Skills[refIdx]
                    rx := s.X, ry := s.Y
                    tgt := Pixel_HexToInt(s.Color)
                    tol := s.Tol
                    cur := Pixel_FrameGet(rx, ry)
                    match := Pixel_ColorMatch(cur, tgt, tol)
                    res := (op = "EQ") ? match : !match
                    RE_LogV(Format("Cond#{1} Pixel(Skill): idx={2} name={3} X={4} Y={5} cur={6} tgt={7} tol={8} op={9} -> match={10} res={11}"
                        , i, refIdx, s.Name, rx, ry, RE_ColorHex(cur), RE_ColorHex(tgt), tol, op, match, res))
                } else {
                    RE_LogV(Format("Cond#{1} Pixel(Skill): invalid ref idx={2} -> false", i, refIdx))
                    res := false
                }
            } else { ; POINT
                if (refIdx >= 1 && refIdx <= prof.Points.Length) {
                    p := prof.Points[refIdx]
                    rx := p.X, ry := p.Y
                    tgt := Pixel_HexToInt(p.Color)
                    tol := p.Tol
                    cur := Pixel_FrameGet(rx, ry)
                    match := Pixel_ColorMatch(cur, tgt, tol)
                    res := (op = "EQ") ? match : !match
                    RE_LogV(Format("Cond#{1} Pixel(Point): idx={2} name={3} X={4} Y={5} cur={6} tgt={7} tol={8} op={9} -> match={10} res={11}"
                        , i, refIdx, p.Name, rx, ry, RE_ColorHex(cur), RE_ColorHex(tgt), tol, op, match, res))
                } else {
                    RE_LogV(Format("Cond#{1} Pixel(Point): invalid ref idx={2} -> false", i, refIdx))
                    res := false
                }
            }
        }

        any := any || res
        all := all && res

        if (!logicAnd && any) {
            RE_LogV("Rule '" rule.Name "' logic=OR short-circuit -> true")
            return true
        }
        if (logicAnd && !all) {
            RE_LogV("Rule '" rule.Name "' logic=AND short-circuit -> false")
            return false
        }
    }

    final := logicAnd ? all : any
    RE_Log("Rule '" rule.Name "' eval done: logic=" (logicAnd?"AND":"OR") " -> " final)
    return final
}

; 返回是否真的发送了至少一个动作（用于决定是否进入冷却/清零计数）
RuleEngine_Fire(rule, prof) {
    gap := HasProp(rule, "ActionGapMs") ? rule.ActionGapMs : 60
    thr := HasProp(rule, "ThreadId") ? rule.ThreadId : 1
    isCounterMode := RuleEngine_HasCounterCond(rule)

    RE_Log("Fire: rule=" rule.Name " thr=" thr " actions=" rule.Actions.Length " gap=" gap
        . (isCounterMode ? " (CounterMode: first-ready only)" : ""))

    anySent := false

    if (isCounterMode) {
        ; 计数规则模式：按顺序挑选第一个“就绪”的动作，仅发送这一项
        selAi := 0, selIdx := 0
        for ai, a in rule.Actions {
            if !(HasProp(a, "SkillIndex")) {
                RE_LogV("  Candidate#" ai " invalid (no SkillIndex) -> skip")
                continue
            }
            idx := a.SkillIndex
            if (idx < 1 || idx > prof.Skills.Length) {
                RE_LogV("  Candidate#" ai " invalid skill index=" idx " -> skip")
                continue
            }
            if RuleEngine_CheckSkillReady(prof, idx) {
                selAi := ai, selIdx := idx
                RE_LogV("  Candidate#" ai " READY -> select")
                break
            } else {
                RE_LogV("  Candidate#" ai " not ready -> skip")
            }
        }

        if (selAi = 0) {
            RE_Log("CounterMode: no ready action found -> skip send, no counter reset")
            return false
        }

        a := rule.Actions[selAi]
        if (a.DelayMs > 0) {
            RE_LogV("  Action#" selAi " preDelay=" a.DelayMs "ms")
            Sleep a.DelayMs
        }
        sname := prof.Skills[selIdx].Name
        ok := (RE_VerifyForCounterOnly
            ? RuleEngine_SendVerified(thr, selIdx, rule.Name)
            : WorkerPool_SendSkillIndex(thr, selIdx, "Rule:" rule.Name))
        RE_Log("  Action#" selAi " send idx=" selIdx " name=" sname " -> " (ok ? "OK" : "FAIL"))
        if (ok) {
            anySent := true
            if (gap > 0) {
                RE_LogV("  Action#" selAi " postGap=" gap "ms")
                Sleep gap
            }
        }
    } else {
        ; 非计数规则：依序执行全部动作
        for ai, a in rule.Actions {
            if (a.DelayMs > 0) {
                RE_LogV("  Action#" ai " preDelay=" a.DelayMs "ms")
                Sleep a.DelayMs
            }
            if (a.SkillIndex >= 1 && a.SkillIndex <= prof.Skills.Length) {
                sname := prof.Skills[a.SkillIndex].Name
                RE_Log("  Action#" ai " send idx=" a.SkillIndex " name=" sname)
                if WorkerPool_SendSkillIndex(thr, a.SkillIndex, "Rule:" rule.Name)
                    anySent := true
            } else {
                RE_Log("  Action#" ai " invalid skill index=" a.SkillIndex, "WARN")
            }
            if (gap > 0) {
                RE_LogV("  Action#" ai " postGap=" gap "ms")
                Sleep gap
            }
        }
    }

    ; 仅在“确实发出了至少一个动作”时，按条件配置清零计数
    if (anySent) {
        resetList := []
        for _, c in rule.Conditions {
            if (HasProp(c, "Kind") && StrUpper(c.Kind)="COUNTER" && HasProp(c, "ResetOnTrigger") && c.ResetOnTrigger) {
                if HasProp(c, "SkillIndex")
                    resetList.Push(c.SkillIndex)
            }
        }
        if (resetList.Length) {
            Counters_ResetMany(resetList)
            RE_Log("Counters reset after fire: [" RE_List(resetList) "]")
        }
    } else {
        RE_Log("No action sent -> no counter reset")
    }

    return anySent
}