; Rotation_Watch.ahk - Watch 列表判定
;modules\engines\rotation\Rotation_Watch.ahk
Rotation_WatchEval() {
    global App, gRot
    cfg := gRot["Cfg"], st := gRot["RT"].PhaseState
    tol := cfg.ColorTolBlack
    now := A_TickCount

    if (now >= gRot["RT"].BlackoutUntil) {
        Rotation_DetectBlackout(st)
    }
    allOk := true
    for _, it in st.Items {
        si := it.SkillIndex
        delta := Counters_Get(si) - (st.Baseline.Has(si) ? st.Baseline[si] : 0)
        cntOk := (delta >= it.Require)

        blkOk := true
        if (it.VerifyBlack && !it.BlackSeen) {
            if (A_TickCount < gRot["RT"].BlackoutUntil) {
                blkOk := false
            } else {
                if (Rotation_TimeWindowAccept(si)) {
                    if (si>=1 && si<=App["ProfileData"].Skills.Length) {
                        s := App["ProfileData"].Skills[si]
                        c := Pixel_FrameGet(s.X, s.Y)
                        if Rotation_IsBlack(c, tol) {
                            uniqOk := true
                            if (gRot["Cfg"].BlackGuard.UniqueRequired) {
                                uniqOk := false
                                for _, it2 in st.Items {
                                    if (it2.SkillIndex = si)
                                        continue
                                    if (it2.SkillIndex>=1 && it2.SkillIndex<=App["ProfileData"].Skills.Length) {
                                        s2 := App["ProfileData"].Skills[it2.SkillIndex]
                                        c2 := Pixel_FrameGet(s2.X, s2.Y)
                                        if !Rotation_IsBlack(c2, tol) {
                                            uniqOk := true
                                            break
                                        }
                                    }
                                }
                            }
                            if (uniqOk)
                                it.BlackSeen := true
                        }
                    }
                }
                blkOk := it.BlackSeen
            }
        }

        ok := cntOk && blkOk
        if !ok
            allOk := false
    }
    return allOk
}