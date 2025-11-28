; Rotation_Opener.ahk - 起手 Step 引擎（Skill/Wait/Swap）
;modules\engines\rotation\Rotation_Opener.ahk
Rotation_OpenerHasSteps() {
    global gRot
    try {
        return (gRot["Cfg"].Opener.StepsCount > 0 && gRot["Cfg"].Opener.Steps.Length > 0)
    } catch {
        return false
    }
}

; 返回：1=本帧已消费；-1=全部完成；0=本帧未消费
Rotation_OpenerStepTick() {
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
            try {
                Logger_Info("Rotation", "Opener step", Map("kind","Wait","idx", i))
            } catch {
            }
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
            try {
                Logger_Info("Rotation", "Opener step", Map("kind","Swap","idx", i))
            } catch {
            }
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
            HighPrecisionDelay(stp.PreDelayMs)
        ; 使用默认轨道的线程
        defTid := 1
        try defTid := Rotation_GetTrackById(Rotation_GetDefaultTrackId()).ThreadId
        ; 一次性 Hold 覆盖
        holdOverride := HasProp(stp, "HoldMs") ? Max(0, Integer(stp.HoldMs)) : -1
        ok := WorkerPool_SendSkillIndex(defTid, si, "OpenerStep", holdOverride)
        if (ok) {
            if (HasProp(stp,"Verify") && stp.Verify) {
                ; 若需回执，可在此补充（M1/M2 按最小实现留空）
            }
            try {
                Logger_Info("Rotation", "Opener step", Map("kind","Skill","idx", i, "skillIdx", si))
            } catch {
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