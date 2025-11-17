; Rotation_Filter.ahk - 规则过滤/调用

Rotation_RunRules_ForCurrentTrack() {
    global gRot
    cfg := gRot["Cfg"], rt := gRot["RT"]
    tr := Rotation_CurrentTrackCfg()
    acted := false

    if (tr && HasProp(tr, "RuleRefs") && tr.RuleRefs.Length > 0) {
        allow := Map()
        for _, rid in tr.RuleRefs
            allow[rid] := true
        try {
            Rot_Log("Track#" rt.TrackId " filter=RuleRefs count=" tr.RuleRefs.Length)
            RE_SetAllowedRules(allow)
            acted := RuleEngine_Tick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    } else {
        allowS := Map()
        if (tr && HasProp(tr, "Watch")) {
            for _, w in tr.Watch
                if (w.SkillIndex>=1)
                    allowS[w.SkillIndex] := true
        }
        try {
            Rot_Log("Track#" rt.TrackId " filter=AllowSkills count=" allowS.Count)
            RE_SetAllowedSkills(allowS)
            acted := RuleEngine_Tick()
        } catch {
        } finally {
            try RE_ClearFilter()
        }
    }

    if (acted)
        gRot["RT"].BusyUntil := A_TickCount + cfg.BusyWindowMs
    return acted
}