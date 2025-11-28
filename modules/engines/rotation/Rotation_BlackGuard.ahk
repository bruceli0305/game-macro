; Rotation_BlackGuard.ahk - 黑屏防抖/时间窗
;modules\engines\rotation\Rotation_BlackGuard.ahk
Rotation_IsBlack(c, tol := 16) {
    r := (c>>16) & 0xFF, g := (c>>8) & 0xFF, b := c & 0xFF
    return (r<=tol && g<=tol && b<=tol)
}
Rotation_DetectBlackout(phaseSt) {
    global App, gRot
    bg := gRot["Cfg"].BlackGuard
    if !bg.Enabled
        return false
    now := A_TickCount
    pts := []
    for _, it in phaseSt.Items {
        si := it.SkillIndex
        if (si>=1 && si<=App["ProfileData"].Skills.Length) {
            s := App["ProfileData"].Skills[si]
            pts.Push([s.X, s.Y])
            if (pts.Length >= bg.SampleCount)
                break
        }
    }
    if (pts.Length = 0)
        return false
    black := 0
    for _, p in pts {
        c := Pixel_FrameGet(p[1], p[2])
        if Rotation_IsBlack(c, gRot["Cfg"].ColorTolBlack)
            black++
    }
    ratio := black / pts.Length
    if (ratio >= bg.BlackRatioThresh) {
        gRot["RT"].BlackoutUntil := now + bg.CooldownMs
        try {
            win := HasProp(bg, "WindowMs") ? Integer(bg.WindowMs) : 0
            if (win > 0)
                gRot["RT"].FreezeUntil := Max(gRot["RT"].FreezeUntil, now + win)
        }
        return true
    }
    return false
}
Rotation_TimeWindowAccept(si) {
    global gRot
    bg := gRot["Cfg"].BlackGuard
    ts := 0
    try {
        if gRot["RT"].LastSent.Has(si)
            ts := gRot["RT"].LastSent[si]
    }
    if (ts = 0) {
        return false
    }
    dt := A_TickCount - ts
    res := (dt >= bg.MinAfterSendMs && dt <= bg.MaxAfterSendMs)
    return res
}