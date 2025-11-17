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
    RE_LogV(Format("  ReadyCheck idx={1} name={2} X={3} Y={4} cur={5} tgt={6} tol={7} -> {8}"
        , idx, s.Name, s.X, s.Y, RE_ColorHex(cur), RE_ColorHex(tgt), s.Tol, ok))
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
            cur := PixelGetColor(s.X, s.Y, "RGB")
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