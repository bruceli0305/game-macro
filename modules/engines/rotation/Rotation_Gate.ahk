; Rotation_Gate.ahk - 跳轨（From->To + 多条件）
;modules\engines\rotation\Rotation_Gate.ahk
Rotation_ResolveRef(refType, refIndex) {
    global App
    if (refType="Skill" && refIndex>=1 && refIndex<=App["ProfileData"].Skills.Length) {
        s := App["ProfileData"].Skills[refIndex]
        return { X:s.X, Y:s.Y, Color:s.Color, Tol:s.Tol }
    }
    if (refType="Point" && refIndex>=1 && refIndex<=App["ProfileData"].Points.Length) {
        p := App["ProfileData"].Points[refIndex]
        return { X:p.X, Y:p.Y, Color:p.Color, Tol:p.Tol }
    }
    return 0
}
Rotation_PixelOpCompare(cur, tgt, tol, op) {
    tgtInt := Pixel_HexToInt(tgt)
    match := Pixel_ColorMatch(cur, tgtInt, tol)
    return (StrUpper(op)="EQ") ? match : !match
}
Rotation_GateEval_PixelReady(g) {
    global gRot
    ref := Rotation_ResolveRef(g.RefType, g.RefIndex)
    if !ref
        return false
    op := (HasProp(g,"Op") ? g.Op : "NEQ")
    tol := (HasProp(g,"Tol") ? g.Tol : gRot["Cfg"].ColorTolBlack)
    tgt := (HasProp(g,"Color") ? g.Color : "0x000000")
    cur := Pixel_FrameGet(ref.X, ref.Y)
    return Rotation_PixelOpCompare(cur, tgt, tol, op)
}
Rotation_GateEval_RuleQuiet(g) {
    global RE_LastFireTick
    rid := HasProp(g,"RuleId") ? g.RuleId : 0
    quiet := HasProp(g,"QuietMs") ? g.QuietMs : 0
    if (rid<=0 || quiet<=0)
        return false
    last := (RE_LastFireTick.Has(rid) ? RE_LastFireTick[rid] : 0)
    return (A_TickCount - last >= quiet)
}

Rotation_GateEval_Cond(c) {
    if (!c || !HasProp(c, "Kind"))
        return false
    kind := StrUpper(c.Kind)
    if (kind = "PIXELREADY") {
        refType  := HasProp(c, "RefType")  ? c.RefType  : "Skill"
        refIndex := HasProp(c, "RefIndex") ? c.RefIndex : 0
        op       := HasProp(c, "Op")       ? c.Op       : "NEQ"
        color    := HasProp(c, "Color")    ? c.Color    : "0x000000"
        tol      := HasProp(c, "Tol")      ? c.Tol      : 16
        ref := Rotation_ResolveRef(refType, refIndex)
        if !ref
            return false
        cur := Pixel_FrameGet(ref.X, ref.Y)
        return Rotation_PixelOpCompare(cur, color, tol, op)
    } else if (kind = "RULEQUIET") {
        return Rotation_GateEval_RuleQuiet(c)
    } else if (kind = "COUNTER" || kind = "COUNTERREADY") {
        si := HasProp(c, "RefIndex") ? c.RefIndex : 0
        if (si <= 0)
            return false
        cmp := StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE")
        val := HasProp(c, "Value") ? Integer(c.Value) : 1
        cnt := Counters_Get(si)
        switch cmp {
            case "GE": return cnt >= val
            case "EQ": return cnt =  val
            case "GT": return cnt >  val
            case "LE": return cnt <= val
            case "LT": return cnt <  val
        }
        return false
    } else if (kind = "ELAPSED") {
        global gRot
        if !(gRot.Has("RT") && HasProp(gRot["RT"], "PhaseState") && HasProp(gRot["RT"].PhaseState, "StartedAt"))
            return false
        ms := HasProp(c, "ElapsedMs") ? Integer(c.ElapsedMs) : 0
        cmp := StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE")
        elapsed := A_TickCount - gRot["RT"].PhaseState.StartedAt
        switch cmp {
            case "GE": return elapsed >= ms
            case "EQ": return elapsed =  ms
            case "GT": return elapsed >  ms
            case "LE": return elapsed <= ms
            case "LT": return elapsed <  ms
        }
    }
    return false
}

; 移除旧兼容：仅支持 Conds[] + Logic，且必须 FromTrackId/ToTrackId
Rotation_GateEval(g) {
    if !(HasProp(g, "Conds") && IsObject(g.Conds) && g.Conds.Length > 0) {
        return false
    }
    logicAnd := (StrUpper(HasProp(g, "Logic") ? g.Logic : "AND") = "AND")
    anyHit := false
    allTrue := true
    for _, c in g.Conds {
        res := Rotation_GateEval_Cond(c)
        anyHit := anyHit || res
        allTrue := allTrue && res
        if (!logicAnd && anyHit)
            return true
        if (logicAnd && !allTrue)
            return false
    }
    return logicAnd ? allTrue : anyHit
}

Rotation_GateFindMatch() {
    global gRot
    cfg := gRot["Cfg"]
    if !HasProp(cfg, "GatesEnabled") {
        return 0
    }
    if !cfg.GatesEnabled {
        return 0
    }
    if !HasProp(cfg, "Gates") {
        return 0
    }
    if (cfg.Gates.Length = 0) {
        return 0
    }

    curId := gRot["RT"].TrackId
    if (curId <= 0) {
        return 0
    }

    bestTo := 0
    bestPr := 0x7FFFFFFF

    k := 1
    while (k <= cfg.Gates.Length) {
        g := cfg.Gates[k]

        fromId := 0
        toId := 0
        pr := k
        try {
            fromId := HasProp(g, "FromTrackId") ? Integer(g.FromTrackId) : 0
        } catch {
            fromId := 0
        }
        try {
            toId := HasProp(g, "ToTrackId") ? Integer(g.ToTrackId) : 0
        } catch {
            toId := 0
        }
        try {
            if HasProp(g, "Priority") {
                pr := Integer(g.Priority)
            } else {
                pr := k
            }
        } catch {
            pr := k
        }

        okFrom := false
        if (fromId > 0) {
            if (fromId = curId) {
                okFrom := true
            }
        }
        if (okFrom) {
            ok := false
            try {
                ok := Rotation_GateEval(g)
            } catch {
                ok := false
            }
            if (ok) {
                if (pr < bestPr) {
                    bestPr := pr
                    bestTo := toId
                }
            }
        }

        k := k + 1
    }

    if (bestTo > 0) {
        have := false
        try {
            have := (Rotation_GetTrackById(bestTo) != 0)
        } catch {
            have := false
        }
        if (have) {
            try {
                Logger_Info("Rotation", "Gate hit", Map("from", curId, "to", bestTo))
            } catch {
            }
            return bestTo
        }
    }
    return 0
}

Rotation_TryEnterTrackWithSwap(trackId) {
    global gRot
    cfg := gRot["Cfg"]
    if (HasProp(cfg, "SwapKey") && cfg.SwapKey!="") {
        Poller_SendKey(cfg.SwapKey)
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
        if (HasProp(cfg,"VerifySwap") && cfg.VerifySwap) {
            Rotation_VerifySwapPixel(cfg.SwapVerify, (HasProp(cfg,"SwapTimeoutMs")?cfg.SwapTimeoutMs:800), (HasProp(cfg,"SwapRetry")?cfg.SwapRetry:0))
        }
    }
    Rotation_EnterTrack(trackId)
    return true
}
Rotation_VerifySwapPixel(vcfg, timeoutMs := 800, retry := 0) {
    if !vcfg
        return true
    tries := Max(1, retry+1)
    loop tries {
        t0 := A_TickCount
        while (A_TickCount - t0 <= timeoutMs) {
            ref := Rotation_ResolveRef(vcfg.RefType, vcfg.RefIndex)
            if !ref
                break
            cur := PixelGetColor(ref.X, ref.Y, "RGB")
            if Rotation_PixelOpCompare(cur, (HasProp(vcfg,"Color")?vcfg.Color:"0x000000")
                    , (HasProp(vcfg,"Tol")?vcfg.Tol:16), (HasProp(vcfg,"Op")?vcfg.Op:"NEQ")) {
                return true
            }
            Sleep 20
        }
    }
    return false
}