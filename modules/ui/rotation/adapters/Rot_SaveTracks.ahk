#Requires AutoHotkey v2
; 保存 Tracks：索引→稳定 Id，写盘→默认轨道修正→重载→重建（严格块结构）

Rot_SaveTracks(profileName, cfg) {
    global App
    if !(IsSet(profileName) && profileName != "") {
        try {
            Logger_Error("Tracks", "save_begin_fail", Map("reason", "empty_profile"))
        } catch {
        }
        return false
    }

    t0 := A_TickCount
    try {
        Logger_Info("Tracks", "save_begin", Map("profile", profileName))
    } catch {
    }

    p := 0
    try {
        p := Storage_Profile_LoadFull(profileName)
    } catch as eLoad {
        try {
            Logger_Exception("Tracks", eLoad, Map("when", "load_full", "profile", profileName))
        } catch {
        }
        return false
    }

    maps := Rot_BuildIndexMaps(p)
    skByIdx := Map()
    rlByIdx := Map()
    try {
        skByIdx := maps["SkByIdx"]
    } catch {
        skByIdx := Map()
    }
    try {
        rlByIdx := maps["RlByIdx"]
    } catch {
        rlByIdx := Map()
    }

    try {
        Logger_Debug("Tracks", "map_counters", Map("map_sk", skByIdx.Count, "map_rl", rlByIdx.Count))
    } catch {
    }

    newTracks := []
    totTracks := 0
    totWatch := 0
    totWatchZero := 0
    totRefs := 0
    totRefsZero := 0

    try {
        if HasProp(cfg, "Tracks") {
            if IsObject(cfg.Tracks) {
                i := 1
                while (i <= cfg.Tracks.Length) {
                    t := cfg.Tracks[i]
                    tr := Map()

                    idv := 0
                    nm := ""
                    th := 1
                    mx := 8000
                    mn := 0
                    nx := 0

                    try {
                        if HasProp(t, "Id") {
                            idv := t.Id
                        } else {
                            idv := 0
                        }
                    } catch {
                        idv := 0
                    }
                    try {
                        if HasProp(t, "Name") {
                            nm := t.Name
                        } else {
                            nm := ""
                        }
                    } catch {
                        nm := ""
                    }
                    try {
                        if HasProp(t, "ThreadId") {
                            th := t.ThreadId
                        } else {
                            th := 1
                        }
                    } catch {
                        th := 1
                    }
                    try {
                        if HasProp(t, "MaxDurationMs") {
                            mx := t.MaxDurationMs
                        } else {
                            mx := 8000
                        }
                    } catch {
                        mx := 8000
                    }
                    try {
                        if HasProp(t, "MinStayMs") {
                            mn := t.MinStayMs
                        } else {
                            mn := 0
                        }
                    } catch {
                        mn := 0
                    }
                    try {
                        if HasProp(t, "NextTrackId") {
                            nx := t.NextTrackId
                        } else {
                            nx := 0
                        }
                    } catch {
                        nx := 0
                    }

                    tr["Id"] := idv
                    tr["Name"] := nm
                    tr["ThreadId"] := th
                    tr["MaxDurationMs"] := mx
                    tr["MinStayMs"] := mn
                    tr["NextTrackId"] := nx

                    ; Watch（SkillIndex -> SkillId）
                    wArr := []
                    try {
                        if HasProp(t, "Watch") {
                            if IsObject(t.Watch) {
                                j := 1
                                while (j <= t.Watch.Length) {
                                    w := t.Watch[j]
                                    si := 0
                                    need := 1
                                    vb := 0

                                    try {
                                        if HasProp(w, "SkillIndex") {
                                            si := Integer(w.SkillIndex)
                                        } else {
                                            si := 0
                                        }
                                    } catch {
                                        si := 0
                                    }
                                    try {
                                        if HasProp(w, "RequireCount") {
                                            need := w.RequireCount
                                        } else {
                                            need := 1
                                        }
                                    } catch {
                                        need := 1
                                    }
                                    try {
                                        if HasProp(w, "VerifyBlack") {
                                            vb := w.VerifyBlack
                                        } else {
                                            vb := 0
                                        }
                                    } catch {
                                        vb := 0
                                    }

                                    sid := 0
                                    if (skByIdx.Has(si)) {
                                        sid := skByIdx[si]
                                    } else {
                                        sid := 0
                                    }

                                    totWatch := totWatch + 1
                                    if (sid <= 0) {
                                        totWatchZero := totWatchZero + 1
                                    }

                                    try {
                                        wArr.Push(Map("SkillId", sid, "RequireCount", need, "VerifyBlack", vb))
                                    } catch {
                                    }

                                    j := j + 1
                                }
                            }
                        }
                    } catch {
                    }
                    tr["Watch"] := wArr

                    ; RuleRefs（rule index -> RuleId）
                    rArr := []
                    try {
                        if HasProp(t, "RuleRefs") {
                            if IsObject(t.RuleRefs) {
                                j := 1
                                while (j <= t.RuleRefs.Length) {
                                    idx := 0
                                    try {
                                        idx := Integer(t.RuleRefs[j])
                                    } catch {
                                        idx := 0
                                    }
                                    rid := 0
                                    if (rlByIdx.Has(idx)) {
                                        rid := rlByIdx[idx]
                                    } else {
                                        rid := 0
                                    }

                                    totRefs := totRefs + 1
                                    if (rid <= 0) {
                                        totRefsZero := totRefsZero + 1
                                    }

                                    try {
                                        rArr.Push(rid)
                                    } catch {
                                    }
                                    j := j + 1
                                }
                            }
                        }
                    } catch {
                    }
                    tr["RuleRefs"] := rArr

                    try {
                        newTracks.Push(tr)
                    } catch {
                    }
                    totTracks := totTracks + 1
                    i := i + 1
                }
            }
        }
    } catch {
    }

    try {
        Logger_Warn("Tracks", "prewrite_check", Map(
            "tracks", totTracks
            , "watch_total", totWatch
            , "watch_zero", totWatchZero
            , "rule_total", totRefs
            , "rule_zero", totRefsZero
        ))
    } catch {
    }

    ok := false
    try {
        if !(p.Has("Rotation")) {
            p["Rotation"] := Map()
        }
        p["Rotation"]["Tracks"] := newTracks
        SaveModule_Tracks(p)
        ok := true
    } catch as eSave {
        ok := false
        try {
            Logger_Exception("Tracks", eSave, Map("when", "save", "profile", profileName))
        } catch {
        }
    }
    if (!ok) {
        return false
    }

    try {
        Logger_Info("Storage", "save_ok", Map("module", "tracks", "profile", profileName, "elapsed_ms", A_TickCount -
            t0))
    } catch {
    }

    ; 默认轨道修正（如失效）
    needFix := false
    newDef := 0
    oldDef := 0

    try {
        if IsSet(App) {
            if App.Has("ProfileData") {
                if HasProp(App["ProfileData"], "Rotation") {
                    oldDef := OM_Get(App["ProfileData"].Rotation, "DefaultTrackId", 0)
                } else {
                    oldDef := 0
                }
            } else {
                oldDef := 0
            }
        } else {
            oldDef := 0
        }
    } catch {
        oldDef := 0
    }

    idSet := Map()
    i := 1
    while (i <= newTracks.Length) {
        tid := 0
        try {
            if newTracks[i].Has("Id") {
                tid := newTracks[i]["Id"]
            } else {
                tid := 0
            }
        } catch {
            tid := 0
        }
        if (tid > 0) {
            try {
                idSet[tid] := 1
            } catch {
            }
        }
        i := i + 1
    }

    try {
        if !(oldDef != 0 && idSet.Has(oldDef)) {
            i := 1
            while (i <= newTracks.Length) {
                tid := 0
                try {
                    if newTracks[i].Has("Id") {
                        tid := newTracks[i]["Id"]
                    } else {
                        tid := 0
                    }
                } catch {
                    tid := 0
                }
                if (tid > 0) {
                    newDef := tid
                    break
                }
                i := i + 1
            }
            needFix := true
        }
    } catch {
        needFix := false
    }

    if (needFix) {
        try {
            rot0 := Map()
            if p.Has("Rotation") {
                rot0 := p["Rotation"]
            }
            rot0["DefaultTrackId"] := newDef
            p["Rotation"] := rot0
            SaveModule_RotationBase(p)
            Logger_Warn("RotationBase", "default_track_fix", Map("profile", profileName, "default_fix_old", oldDef,
                "default_fix_new", newDef))
        } catch {
        }
    }

    ; 重载 + 重建
    t1 := A_TickCount
    try {
        p2 := Storage_Profile_LoadFull(profileName)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        try {
            RE_OnProfileDataReplaced(App["ProfileData"])
        } catch {
        }
        Logger_Info("Runtime", "reload_ok", Map("profile", profileName, "elapsed_ms", A_TickCount - t1))
    } catch as eReload {
        try {
            Logger_Exception("Tracks", eReload, Map("when", "reload", "profile", profileName))
        } catch {
        }
        return false
    }

    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
        Logger_Info("Tracks", "runtime_reset", Map("actions", "Rotation_Reset,Rotation_InitFromProfile"))
    } catch {
    }

    return true
}
