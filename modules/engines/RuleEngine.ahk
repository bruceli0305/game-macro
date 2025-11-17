; RuleEngine.ahk - 技能循环规则引擎（日志/过滤/计数规则模式/发送回执校验）
#Requires AutoHotkey v2

; ========== 日志与调试开关 ==========
global RE_Debug := false                 ; 总开关：日志开/关
global RE_DebugVerbose := false          ; 详细级：打印每个条件细节
global RE_ShowTips := false              ; 屏幕提示（默认关）
; 规则过滤（由 Rotation 设置，优先 AllowRuleIds，再用 AllowSkills）
global RE_Filter := { Enabled:false, AllowSkills:0, AllowRuleIds:0 }
; 规则过滤（由 Rotation 设置，优先 AllowRuleIds，再用 AllowSkills）
global RE_Session := { Active:false, RuleId:0, ThreadId:1
                     , Index:1, StartedAt:0, NextAt:0
                     , HadAnySend:false, LockWaitUntil:0
                     , TimeoutAt:0 }

; 规则最后触发时间（供 Gate:RuleQuiet 使用）
global RE_LastFireTick := Map()
; ===== 会话（Session）全局状态（M1，非阻塞驱动） =====
global RE_Session := { Active:false, RuleId:0, ThreadId:1
                     , Index:1, StartedAt:0, NextAt:0
                     , HadAnySend:false, LockWaitUntil:0 }

; 余量/上限参数（可调）
global RE_Session_CastMarginMs := 100     ; LockWaitBudget = 上一动作 CastMs + 余量
global RE_Session_BusyPerActionMax := 120 ; 每动作的建议忙窗上限（M1 不强制使用）
; 会话是否活跃
RE_SessionActive() {
    return (IsObject(RE_Session) && RE_Session.Active)
}

; 开始会话（从规则 rIdx/rule 构建 Session；首动作 Delay 体现在 NextAt）
RuleEngine_SessionBegin(prof, rIdx, rule) {
    global RE_Session
    RE_Session.Active      := true
    RE_Session.RuleId      := rIdx
    RE_Session.ThreadId    := (HasProp(rule,"ThreadId") ? rule.ThreadId : 1)
    RE_Session.Index       := 1
    RE_Session.StartedAt   := A_TickCount
    RE_Session.HadAnySend  := false
    RE_Session.LockWaitUntil := 0

    ; 首动作预延时（DelayMs）
    firstDelay := 0
    try {
        if (rule.Actions.Length >= 1) {
            a1 := rule.Actions[1]
            firstDelay := (HasProp(a1,"DelayMs") ? Max(0, Integer(a1.DelayMs)) : 0)
        }
    }
    RE_Session.NextAt := A_TickCount + firstDelay
    ; 规则级会话超时（0 表示不限制）
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

; 推进一步：若满足条件则发送当前动作；返回本帧是否发出
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
     ; 会话超时
    if (RE_Session.TimeoutAt > 0 && now >= RE_Session.TimeoutAt) {
        RE_Session.Active := false
        return false
    }
    ; 完成判定
    if (RE_Session.Index > acts.Length) {
        ; 会话结束，记 lastFire（与 RuleQuiet 一致）
        if (RE_Session.HadAnySend) {
            try {
                rule.LastFire := now
                RE_LastFireTick[rIdx] := now
            }
        }
        RE_Session.Active := false
        return false
    }

    ; 时间窗（ActionGap/Delay 已转化到 NextAt）
    if (now < RE_Session.NextAt) {
        return false
    }

    ; 施法锁等待
    thr := RE_Session.ThreadId
    lk := WorkerPool_CastIsLocked(thr)
    if (lk.Locked) {
        ; 计算本动作的锁等待预算：上一动作的 CastMs + 余量
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
        ; 超时仍锁 → 中止会话（M1 默认 Critical）
        RE_Session.Active := false
        return false
    } else {
        ; 已解锁，清掉等待点
        RE_Session.LockWaitUntil := 0
    }

    ; 尝试发送当前动作
    idx := RE_Session.Index
    act := acts[idx]
    si  := HasProp(act,"SkillIndex") ? act.SkillIndex : 0
    if (si < 1 || si > prof.Skills.Length) {
        ; 非法动作 → 中止（也可选择跳过；M1 简化为中止）
        RE_Session.Active := false
        return false
    }
    ; M2：需就绪（像素等于技能目标色，使用帧缓存）
    needReady := 0
    try {
        needReady := (HasProp(act, "RequireReady") && act.RequireReady) ? 1 : 0
    }
    if (needReady) {
        ready := RuleEngine_CheckSkillReady(prof, si)
        if (!ready) {
            ; 不阻塞，下一帧再检查（可按需加最小间隔）
            return false
        }
    }
    ; M2：按住时长（holdOverride），未配置则用 -1 表示不覆盖
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
        ; 发送失败（非锁）→ 中止（M1）
        RE_Session.Active := false
        return false
    }

    ; 发送成功：推进
    RE_Session.HadAnySend := true
    RE_Session.Index := idx + 1

    ; 计划下一动作的最早时间点（ActionGap + 下一个动作 Delay）
    gap  := (HasProp(rule,"ActionGapMs") ? Max(0, Integer(rule.ActionGapMs)) : 0)
    nextDelay := 0
    if (RE_Session.Index <= acts.Length) {
        nextAct := acts[RE_Session.Index]
        nextDelay := (HasProp(nextAct,"DelayMs") ? Max(0, Integer(nextAct.DelayMs)) : 0)
    }
    RE_Session.NextAt := now + gap + nextDelay

    return true
}

; RuleEngine_Tick：会话优先；若无会话则扫描并创建会话或走旧路径（计数规则）
RuleEngine_Tick() {
    global App, RE_Filter, RE_LastFireTick
    prof := App["ProfileData"]

    ; 先驱动会话
    if (RE_SessionActive()) {
        return RuleEngine_SessionStep()
    }

    ; 无会话 → 按旧逻辑扫描（但不阻塞；命中非计数规则时开始会话）
    if (prof.Rules.Length = 0) {
        return false
    }

    now := A_TickCount
    for rIdx, r in prof.Rules {
        if !r.Enabled {
            continue
        }
        ; 过滤：RuleIds > AllowSkills
        if (RE_Filter.Enabled) {
            if (RE_Filter.AllowRuleIds) {
                if !RE_Filter.AllowRuleIds.Has(rIdx) {
                    continue
                }
            } else if (RE_Filter.AllowSkills) {
                if (r.Actions.Length = 0) {
                    continue
                }
                a1 := r.Actions[1]
                sIdx1 := HasProp(a1,"SkillIndex") ? a1.SkillIndex : 0
                if !(RE_Filter.AllowSkills.Has(sIdx1)) {
                    continue
                }
            }
        }

        last := HasProp(r, "LastFire") ? r.LastFire : 0
        remain := r.CooldownMs - (now - last)
        if (remain > 0) {
            continue
        }

        ok := RuleEngine_EvalRule(r, prof)
        if !ok {
            continue
        }

        ; 含计数条件 → 保持旧路径（只发首个就绪动作）
        if RuleEngine_HasCounterCond(r) {
            sent := RuleEngine_Fire(r, prof, rIdx)
            if (sent) {
                ; 旧路径内部会更新 LastFire/RE_LastFireTick
                return true
            }
            continue
        }

        ; 非计数 → 开始会话并尝试首动作
        RuleEngine_SessionBegin(prof, rIdx, r)
        acted := RuleEngine_SessionStep()
        return acted
    }
    return false
}

RE_SetAllowedRules(mapRuleIds) {
    global RE_Filter
    RE_Filter.Enabled := true
    RE_Filter.AllowRuleIds := mapRuleIds   ; Map<ruleId,true>
}
RE_SetAllowedSkills(mapSkills) {
    global RE_Filter
    RE_Filter.Enabled := true
    RE_Filter.AllowSkills := mapSkills     ; Map<skillIdx,true>
}
RE_ClearFilter() {
    global RE_Filter
    RE_Filter.Enabled := false
    RE_Filter.AllowRuleIds := 0
    RE_Filter.AllowSkills := 0
}

RE_Tip(msg, ms := 1000) {
    global RE_ShowTips
    if !RE_ShowTips {
        return
    }
    ToolTip msg
    SetTimer () => ToolTip(), -ms
}

RE_LogFilePath() {
    return A_ScriptDir "\Logs\ruleengine.log"
}
RE_Log(msg, level := "INFO") {
    if !RE_Debug {
        return
    }
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend ts " [RuleEngine] [" level "] " msg "`r`n", RE_LogFilePath(), "UTF-8"
}
RE_LogV(msg) {
    if RE_DebugVerbose {
        RE_Log(msg, "VERB")
    }
}

RE_SkillNameByIndex(prof, idx) {
    return (idx >= 1 && idx <= prof.Skills.Length) ? prof.Skills[idx].Name : ("技能#" idx)
}
RE_ColorHex(n) {
    return Format("0x{:06X}", n & 0xFFFFFF)
}
RE_List(arr) {
    out := ""
    for i, v in arr {
        out .= (i = 1 ? "" : ",") v
    }
    return out
}
; ====================================

; ========== 发送回执校验（可选） ==========
global RE_VerifySend := true              ; 是否启用发送后像素回执校验
global RE_VerifyForCounterOnly := true    ; 仅对含计数条件的规则启用
global RE_VerifyWaitMs := 150             ; 发送后等待首帧反馈延时
global RE_VerifyTimeoutMs := 600          ; 在此时间内应看到像素由“就绪”变为“非就绪”
global RE_VerifyRetry := 1                ; 失败重试次数（0=不重试）

RuleEngine_SendVerified(thr, idx, ruleName) {
    global App, RE_VerifySend, RE_VerifyWaitMs, RE_VerifyTimeoutMs, RE_VerifyRetry
    s := App["ProfileData"].Skills[idx]
    ; 首发
    ok := WorkerPool_SendSkillIndex(thr, idx, "Rule:" ruleName)
    if !ok {
        RE_Log("  Send initial FAIL for idx=" idx " name=" s.Name, "WARN")
        return false
    }
    if !RE_VerifySend {
        return true
    }

    attempt := 0
    loop RE_VerifyRetry + 1 {
        if (attempt > 0) {
            RE_Log("  Verify attempt#" (attempt + 1) " (retry send)")
            WorkerPool_SendSkillIndex(thr, idx, "Retry:" ruleName)
        } else {
            RE_Log("  Verify attempt#" (attempt + 1))
        }

        Sleep RE_VerifyWaitMs
        t0 := A_TickCount
        tgt := Pixel_HexToInt(s.Color)
        success := false
        while (A_TickCount - t0 <= RE_VerifyTimeoutMs) {
            cur := PixelGetColor(s.X, s.Y, "RGB")  ; 实时取色
            match := Pixel_ColorMatch(cur, tgt, s.Tol)
            if !match {
                success := true
                break
            }
            Sleep 10
        }
        RE_Log("  Verify result -> " (success ? "OK" : "FAIL"))
        if success {
            return true
        }
        attempt += 1
        if (attempt > RE_VerifyRetry) {
            break
        }
    }
    return false
}
; ==============================================

; 是否包含至少一个计数条件（启用“计数规则模式”）
RuleEngine_HasCounterCond(rule) {
    for _, c in rule.Conditions {
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            return true
        }
    }
    return false
}

; 检查某技能的像素就绪（按技能自身 X/Y/Color/Tol），使用帧缓存
RuleEngine_CheckSkillReady(prof, idx) {
    if (idx < 1 || idx > prof.Skills.Length) {
        return false
    }
    s := prof.Skills[idx]
    cur := Pixel_FrameGet(s.X, s.Y)
    tgt := Pixel_HexToInt(s.Color)
    ok := Pixel_ColorMatch(cur, tgt, s.Tol)
    RE_LogV(Format("  ReadyCheck idx={1} name={2} X={3} Y={4} cur={5} tgt={6} tol={7} -> {8}"
        , idx, s.Name, s.X, s.Y, RE_ColorHex(cur), RE_ColorHex(tgt), s.Tol, ok))
    return ok
}

; 返回 true 表示本 Tick 已触发某规则（避免并发触发单技能扫描）
RuleEngine_RunTick() {
    global App, RE_Filter
    prof := App["ProfileData"]
    static tick := 0
    tick++

    now := A_TickCount
    if (prof.Rules.Length = 0) {
        RE_Log("Tick#" tick " no rules configured")
        RE_Tip("没有配置规则", 1000)
        return false
    }

    RE_Log("Tick#" tick " begin, rules=" prof.Rules.Length " now=" now)

    for rIdx, r in prof.Rules {
        if !r.Enabled {
            RE_LogV("Tick#" tick " skip disabled rule: " r.Name)
            continue
        }

        ; 过滤（优先 RuleIds，其次 AllowSkills）
        if (RE_Filter.Enabled) {
            if (RE_Filter.AllowRuleIds) {
                if !RE_Filter.AllowRuleIds.Has(rIdx) {
                    RE_LogV("filtered by RuleIds -> " r.Name)
                    continue
                }
            } else if (RE_Filter.AllowSkills) {
                if (r.Actions.Length = 0) {
                    RE_LogV("filtered: no action -> " r.Name)
                    continue
                }
                a1 := r.Actions[1]
                sIdx1 := HasProp(a1,"SkillIndex") ? a1.SkillIndex : 0
                if !(RE_Filter.AllowSkills.Has(sIdx1)) {
                    RE_LogV("filtered by AllowSkills -> " r.Name)
                    continue
                }
            }
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

        RE_Log("Tick#" tick " FIRE rule: " r.Name " thr=" (HasProp(r, "ThreadId") ? r.ThreadId : 1))
        sent := RuleEngine_Fire(r, prof, rIdx)   ; 传 rIdx 给 Fire（用于 RuleQuiet）
        if sent {
            r.LastFire := A_TickCount
            RE_Log("Tick#" tick " rule fired, set LastFire=" r.LastFire)
            if RE_ShowTips {
                SetTimer () => ToolTip(), -1000
            }
            return true
        } else {
            RE_Log("Tick#" tick " rule matched but no action sent (no ready) -> no cooldown")
        }
    }

    RE_Log("Tick#" tick " no rule matched")
    RE_Tip("没有符合条件的规则", 1000)
    return false
}

; 评估规则：先评估计数条件，后评估像素条件（更高效），保留短路逻辑
RuleEngine_EvalRule(rule, prof) {
    if (rule.Conditions.Length = 0) {
        RE_Log("Rule '" rule.Name "' has no conditions -> false")
        return false
    }
    logicAnd := (StrUpper(rule.Logic) = "AND")
    anyHit := false
    allTrue := true
    i := 0

    ; 两段：先 Counter，后 Pixel
    evalList := []
    for _, c in rule.Conditions {
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            evalList.Push(c)
        }
    }
    for _, c in rule.Conditions {
        if !(HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            evalList.Push(c)
        }
    }

    for _, c in evalList {
        i++
        res := false

        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            si := HasProp(c, "SkillIndex") ? c.SkillIndex : 1
            cnt := Counters_Get(si)
            cmp := StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE")
            val := HasProp(c, "Value") ? Integer(c.Value) : 1
            switch cmp {
                case "GE": res := (cnt >= val)
                case "EQ": res := (cnt = val)
                case "GT": res := (cnt > val)
                case "LE": res := (cnt <= val)
                case "LT": res := (cnt < val)
                default: res := (cnt >= val)
            }
            RE_LogV(Format("Cond#{1} Counter: skill={2}({3}) cnt={4} cmp={5} val={6} -> {7}"
                , i, si, RE_SkillNameByIndex(prof, si), cnt, cmp, val, res))
        } else {
            refType := StrUpper(HasProp(c, "RefType") ? c.RefType : "SKILL")
            refIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
            op := StrUpper(HasProp(c, "Op") ? c.Op : "EQ")
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
            } else {
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

        anyHit := anyHit || res
        allTrue := allTrue && res

        if (!logicAnd && anyHit) {
            RE_LogV("Rule '" rule.Name "' logic=OR short-circuit -> true")
            return true
        }
        if (logicAnd && !allTrue) {
            RE_LogV("Rule '" rule.Name "' logic=AND short-circuit -> false")
            return false
        }
    }

    final := logicAnd ? allTrue : anyHit
    RE_Log("Rule '" rule.Name "' eval done: logic=" (logicAnd ? "AND" : "OR") " -> " final)
    return final
}

; 返回是否真的发送了至少一个动作（用于决定是否进入冷却/清零计数）
RuleEngine_Fire(rule, prof, ruleIndex := 0) {
    global RE_VerifyForCounterOnly, RE_LastFireTick
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
                if WorkerPool_SendSkillIndex(thr, a.SkillIndex, "Rule:" rule.Name) {
                    anySent := true
                }
            } else {
                RE_Log("  Action#" ai " invalid skill index=" a.SkillIndex, "WARN")
            }
            if (gap > 0) {
                RE_LogV("  Action#" ai " postGap=" gap "ms")
                Sleep gap
            }
        }
    }

    ; 仅在“确实发出了至少一个动作”时，按条件配置清零计数，并记录 lastFire
    if (anySent) {
        try {
            if (ruleIndex > 0) {
                RE_LastFireTick[ruleIndex] := A_TickCount
            }
        }
        resetList := []
        for _, c in rule.Conditions {
            if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER"
             && HasProp(c, "ResetOnTrigger") && c.ResetOnTrigger) {
                if HasProp(c, "SkillIndex") {
                    resetList.Push(c.SkillIndex)
                }
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