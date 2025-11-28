; Rotation_Filter.ahk - 规则过滤/调用
;modules\engines\rotation\Rotation_Filter.ahk
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
            RE_SetAllowedRules(allow)
            RE_SetScanOrder(tr.RuleRefs)          ; 新增：按轨道顺序扫描
            acted := RuleEngine_Tick()
        } catch as e {
            
        } finally {
            try RE_ClearFilter()
            try RE_ClearScanOrder()               ; 新增：清理
        }
    } else {
        allowS := Map()
        if (tr && HasProp(tr, "Watch")) {
            for _, w in tr.Watch
                if (w.SkillIndex>=1)
                    allowS[w.SkillIndex] := true
        }
        try {
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