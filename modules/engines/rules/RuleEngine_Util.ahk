; RuleEngine_Util.ahk - 常用工具/判定

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

; 是否包含计数条件
RuleEngine_HasCounterCond(rule) {
    for _, c in rule.Conditions {
        if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
            return true
        }
    }
    return false
}

; 帧缓存就绪：技能像素等于目标色
RuleEngine_CheckSkillReady(prof, idx) {
    if (idx < 1 || idx > prof.Skills.Length) {
        return false
    }
    s := prof.Skills[idx]
    cur := Pixel_FrameGet(s.X, s.Y)
    tgt := Pixel_HexToInt(s.Color)
    ok := Pixel_ColorMatch(cur, tgt, s.Tol)
    return ok
}

; 冻结窗是否激活（黑屏防抖）
RE_Session_FreezeActive() {
    try {
        global gRot
        if (IsObject(gRot) && gRot.Has("RT")) {
            return (A_TickCount < gRot["RT"].FreezeUntil)
        }
    } catch {
    }
    return false
}

; 旧式“阻塞回执”校验，仅在计数模式下可选启用
RuleEngine_SendVerified(thr, idx, ruleName) {
    global App, RE_VerifySend, RE_VerifyWaitMs, RE_VerifyTimeoutMs, RE_VerifyRetry
    s := App["ProfileData"].Skills[idx]
    ok := WorkerPool_SendSkillIndex(thr, idx, "Rule:" ruleName)
    if !ok {
        return false
    }
    if !RE_VerifySend {
        return true
    }

    attempt := 0
    loop RE_VerifyRetry + 1 {
        if (attempt > 0) {
            WorkerPool_SendSkillIndex(thr, idx, "Retry:" ruleName)
        }
        Sleep RE_VerifyWaitMs
        t0 := A_TickCount
        tgt := Pixel_HexToInt(s.Color)
        success := false
        while (A_TickCount - t0 <= RE_VerifyTimeoutMs) {
            cur := PixelGetColor(s.X, s.Y, "RGB")
            match := Pixel_ColorMatch(cur, tgt, s.Tol)
            if !match {
                success := true
                break
            }
            Sleep 10
        }
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
; 按稳定 RuleId 列表设置允许规则（内部转为运行时索引）
RE_SetAllowedRulesByStableIds(prof, ruleIdArr) {
    if !IsObject(prof) {
        return
    }
    if !IsObject(ruleIdArr) {
        return
    }
    idxMap := Map()
    i := 1
    while (i <= prof.Rules.Length) {
        rid := 0
        try {
            rid := HasProp(prof.Rules[i], "Id") ? prof.Rules[i].Id : 0
        } catch {
            rid := 0
        }
        if (rid > 0) {
            idxMap[rid] := i
        }
        i := i + 1
    }

    allow := Map()
    j := 1
    while (j <= ruleIdArr.Length) {
        rid2 := 0
        try {
            rid2 := Integer(ruleIdArr[j])
        } catch {
            rid2 := 0
        }
        if (idxMap.Has(rid2)) {
            try {
                allow[idxMap[rid2]] := 1
            } catch {
            }
        }
        j := j + 1
    }
    RE_SetAllowedRules(allow)  ; 仍沿用原有接口，键=运行时规则索引
}

; 按稳定 SkillId 列表设置允许技能（内部转为运行时索引）
RE_SetAllowedSkillsByStableIds(prof, skillIdArr) {
    if !IsObject(prof) {
        return
    }
    if !IsObject(skillIdArr) {
        return
    }
    idxMap := Map()
    i := 1
    while (i <= prof.Skills.Length) {
        sid := 0
        try {
            sid := HasProp(prof.Skills[i], "Id") ? prof.Skills[i].Id : 0
        } catch {
            sid := 0
        }
        if (sid > 0) {
            idxMap[sid] := i
        }
        i := i + 1
    }

    allow := Map()
    j := 1
    while (j <= skillIdArr.Length) {
        sid2 := 0
        try {
            sid2 := Integer(skillIdArr[j])
        } catch {
            sid2 := 0
        }
        if (idxMap.Has(sid2)) {
            try {
                allow[idxMap[sid2]] := 1
            } catch {
            }
        }
        j := j + 1
    }
    RE_SetAllowedSkills(allow) ; 键=运行时技能索引
}

; 可选工具：按稳定 RuleId 列表注入扫描顺序（若调用方只有稳定 Id）
RE_SetScanOrderByStableIds(prof, ruleIdArr) {
    if !IsObject(prof) {
        return
    }
    if !IsObject(ruleIdArr) {
        return
    }
    idxMap := Map()
    i := 1
    while (i <= prof.Rules.Length) {
        rid := 0
        try {
            rid := HasProp(prof.Rules[i], "Id") ? prof.Rules[i].Id : 0
        } catch {
            rid := 0
        }
        if (rid > 0) {
            idxMap[rid] := i
        }
        i := i + 1
    }

    order := []
    j := 1
    while (j <= ruleIdArr.Length) {
        rid2 := 0
        try {
            rid2 := Integer(ruleIdArr[j])
        } catch {
            rid2 := 0
        }
        if (idxMap.Has(rid2)) {
            try {
                order.Push(idxMap[rid2])
            } catch {
            }
        }
        j := j + 1
    }
    RE_SetScanOrder(order) ; 仍传运行时索引数组
}