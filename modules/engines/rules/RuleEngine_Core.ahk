; RuleEngine_Core.ahk - 扫描/会话优先/过滤/旧路径（计数模式）

RE_SetAllowedRules(mapRuleIds) {
    global RE_Filter
    RE_Filter.Enabled := true
    RE_Filter.AllowRuleIds := mapRuleIds
}
RE_SetAllowedSkills(mapSkills) {
    global RE_Filter
    RE_Filter.Enabled := true
    RE_Filter.AllowSkills := mapSkills
}
RE_ClearFilter() {
    global RE_Filter
    RE_Filter.Enabled := false
    RE_Filter.AllowRuleIds := 0
    RE_Filter.AllowSkills := 0
}

; 会话优先；无会话则扫描命中：非计数→开启会话；计数→走旧路径 Fire
RuleEngine_Tick() {
    global App, RE_ScanOrder, RE_Filter
    if (RE_SessionActive()) {
        return RuleEngine_SessionStep()
    }
    prof := App["ProfileData"]
    if (prof.Rules.Length = 0) {
        return false
    }

    now := A_TickCount

    TryEvalRule(rIdx) {
        r := prof.Rules[rIdx]
        if !r.Enabled
            return false

        ; 冷却
        last := HasProp(r, "LastFire") ? r.LastFire : 0
        if (r.CooldownMs - (now - last) > 0)
            return false

        ; 过滤（若外部仍开启）
        if (RE_Filter.Enabled) {
            if (RE_Filter.AllowRuleIds) {
                if !RE_Filter.AllowRuleIds.Has(rIdx)
                    return false
            } else if (RE_Filter.AllowSkills) {
                if (r.Actions.Length = 0)
                    return false
                a1 := r.Actions[1]
                sIdx1 := HasProp(a1,"SkillIndex") ? a1.SkillIndex : 0
                if !(RE_Filter.AllowSkills.Has(sIdx1))
                    return false
            }
        }

        if !RuleEngine_EvalRule(r, prof)
            return false

        if RuleEngine_HasCounterCond(r) {
            return RuleEngine_Fire(r, prof, rIdx)
        }
        RuleEngine_SessionBegin(prof, rIdx, r)
        return RuleEngine_SessionStep()
    }

    ; 若注入了扫描顺序，仅按该顺序评估
    if (IsObject(RE_ScanOrder) && RE_ScanOrder.Length > 0) {
        for _, id in RE_ScanOrder {
            if (id >= 1 && id <= prof.Rules.Length) {
                if (TryEvalRule(id))
                    return true
            }
        }
        return false
    }

    ; 否则按全局顺序
    for rIdx, _ in prof.Rules {
        if (TryEvalRule(rIdx))
            return true
    }
    return false
}

; 评估规则（先 Counter 后 Pixel；短路）
RuleEngine_EvalRule(rule, prof) {
    if (rule.Conditions.Length = 0) {
        RE_Log("Rule '" rule.Name "' has no conditions -> false")
        return false
    }
    logicAnd := (StrUpper(rule.Logic) = "AND")
    anyHit := false, allTrue := true

    evalList := []
    for _, c in rule.Conditions
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER")
            evalList.Push(c)
    for _, c in rule.Conditions
        if !(HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER")
            evalList.Push(c)

    i := 0
    for _, c in evalList {
        i++
        res := false
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            si := HasProp(c,"SkillIndex") ? c.SkillIndex : 1
            cnt := Counters_Get(si)
            cmp := StrUpper(HasProp(c,"Cmp") ? c.Cmp : "GE")
            val := HasProp(c,"Value") ? Integer(c.Value) : 1
            switch cmp {
                case "GE": res := (cnt >= val)
                case "EQ": res := (cnt = val)
                case "GT": res := (cnt > val)
                case "LE": res := (cnt <= val)
                case "LT": res := (cnt < val)
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
                    rx := s.X, ry := s.Y, tgt := Pixel_HexToInt(s.Color), tol := s.Tol
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
                    rx := p.X, ry := p.Y, tgt := Pixel_HexToInt(p.Color), tol := p.Tol
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

; 仅用于“含计数条件”的旧路径（一次发一个）
RuleEngine_Fire(rule, prof, ruleIndex := 0) {
    global RE_VerifyForCounterOnly, RE_LastFireTick
    gap := HasProp(rule, "ActionGapMs") ? rule.ActionGapMs : 60
    thr := HasProp(rule, "ThreadId") ? rule.ThreadId : 1
    isCounterMode := RuleEngine_HasCounterCond(rule)

    RE_Log("Fire: rule=" rule.Name " thr=" thr " actions=" rule.Actions.Length " gap=" gap
        . (isCounterMode ? " (CounterMode: first-ready only)" : ""))

    anySent := false

    if (isCounterMode) {
        selAi := 0, selIdx := 0
        for ai, a in rule.Actions {
            if !(HasProp(a, "SkillIndex"))
                continue
            idx := a.SkillIndex
            if (idx < 1 || idx > prof.Skills.Length)
                continue
            if RuleEngine_CheckSkillReady(prof, idx) {
                selAi := ai, selIdx := idx
                break
            }
        }
        if (selAi = 0) {
            return false
        }
        a := rule.Actions[selAi]
        if (a.DelayMs > 0)
            Sleep a.DelayMs
        sname := prof.Skills[selIdx].Name
        ok := (RE_VerifyForCounterOnly
            ? RuleEngine_SendVerified(thr, selIdx, rule.Name)
            : WorkerPool_SendSkillIndex(thr, selIdx, "Rule:" rule.Name))
        if (ok) {
            anySent := true
            if (gap > 0)
                Sleep gap
        }
    }

    if (anySent && ruleIndex > 0) {
        RE_LastFireTick[ruleIndex] := A_TickCount
        resetList := []
        for _, c in rule.Conditions
            if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER"
             && HasProp(c, "ResetOnTrigger") && c.ResetOnTrigger)
                if HasProp(c, "SkillIndex")
                    resetList.Push(c.SkillIndex)
        if (resetList.Length)
            Counters_ResetMany(resetList)
    }
    return anySent
}
RE_SetScanOrder(arr) {
    global RE_ScanOrder
    RE_ScanOrder := IsObject(arr) ? arr.Clone() : []
}
RE_ClearScanOrder() {
    global RE_ScanOrder
    RE_ScanOrder := []
}