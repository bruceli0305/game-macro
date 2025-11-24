#Requires AutoHotkey v2
; 保存 Gates：索引→稳定 Id，写盘→重载→重建

Rot_SaveGates(profileName, cfg) {
    global App

    if !(IsSet(profileName) && profileName != "") {
        try {
            Logger_Error("Gates", "save_begin_fail", Map("reason", "empty_profile"))
        } catch {
        }
        return false
    }

    try {
        Logger_Info("Gates", "save_begin", Map("profile", profileName))
    } catch {
    }
    t0 := A_TickCount

    p := 0
    try {
        p := Storage_Profile_LoadFull(profileName)
    } catch as e {
        try {
            Logger_Exception("Gates", e, Map("when","load_full","profile",profileName))
        } catch {
        }
        return false
    }

    maps := Rot_BuildIndexMaps(p)
    skByIdx := Map()
    ptByIdx := Map()
    rlByIdx := Map()

    try {
        skByIdx := maps["SkByIdx"]
    } catch {
        skByIdx := Map()
    }
    try {
        ptByIdx := maps["PtByIdx"]
    } catch {
        ptByIdx := Map()
    }
    try {
        rlByIdx := maps["RlByIdx"]
    } catch {
        rlByIdx := Map()
    }

    try {
        Logger_Debug("Gates", "map_counters", Map("map_sk", skByIdx.Count, "map_pt", ptByIdx.Count, "map_rl", rlByIdx.Count))
    } catch {
    }

    newGates := []
    condTotal := 0
    kindPR := 0
    kindRQ := 0
    kindCT := 0
    kindEL := 0
    badRefs := 0

    try {
        if (HasProp(cfg,"Gates") && IsObject(cfg.Gates)) {
            i := 1
            while (i <= cfg.Gates.Length) {
                g0 := cfg.Gates[i]
                g := Map()

                g["Id"] := OM_Get(g0, "Id", 0)
                g["Priority"] := OM_Get(g0, "Priority", i)
                g["FromTrackId"] := OM_Get(g0, "FromTrackId", 0)
                g["ToTrackId"]   := OM_Get(g0, "ToTrackId", 0)
                g["Logic"] := OM_Get(g0, "Logic", "AND")

                carr := []
                try {
                    if (HasProp(g0,"Conds") && IsObject(g0.Conds)) {
                        j := 1
                        while (j <= g0.Conds.Length) {
                            c0 := g0.Conds[j]
                            k  := "PIXELREADY"
                            try {
                                k := StrUpper(OM_Get(c0, "Kind", "PixelReady"))
                            } catch {
                                k := "PIXELREADY"
                            }

                            c := Map()
                            c["Kind"] := k

                            if (k = "PIXELREADY") {
                                kindPR := kindPR + 1
                                rt := OM_Get(c0, "RefType", "Skill")
                                ri := OM_Get(c0, "RefIndex", 0)
                                refId := 0
                                if (StrUpper(rt) = "SKILL") {
                                    if (skByIdx.Has(ri)) {
                                        refId := skByIdx[ri]
                                    } else {
                                        refId := 0
                                    }
                                } else {
                                    if (ptByIdx.Has(ri)) {
                                        refId := ptByIdx[ri]
                                    } else {
                                        refId := 0
                                    }
                                }
                                c["RefType"] := rt
                                c["RefId"] := refId
                                c["Op"] := OM_Get(c0, "Op", "NEQ")
                                c["Color"] := OM_Get(c0, "Color", "0x000000")
                                c["Tol"] := OM_Get(c0, "Tol", 16)

                                rIdx := OM_Get(c0, "RuleId", 0)
                                rId := 0
                                if (rlByIdx.Has(rIdx)) {
                                    rId := rlByIdx[rIdx]
                                } else {
                                    rId := 0
                                }
                                c["RuleId"] := rId
                                c["QuietMs"] := OM_Get(c0, "QuietMs", 0)
                                c["Cmp"] := OM_Get(c0, "Cmp", "GE")
                                c["Value"] := OM_Get(c0, "Value", 0)
                                c["ElapsedMs"] := OM_Get(c0, "ElapsedMs", 0)

                                if (refId <= 0) {
                                    badRefs := badRefs + 1
                                }
                            } else if (k = "RULEQUIET") {
                                kindRQ := kindRQ + 1
                                rIdx2 := OM_Get(c0, "RuleId", 0)
                                rId2 := 0
                                if (rlByIdx.Has(rIdx2)) {
                                    rId2 := rlByIdx[rIdx2]
                                } else {
                                    rId2 := 0
                                }
                                c["RuleId"] := rId2
                                c["QuietMs"] := OM_Get(c0, "QuietMs", 0)
                                if (rId2 <= 0) {
                                    badRefs := badRefs + 1
                                }
                            } else if (k = "COUNTER") {
                                kindCT := kindCT + 1
                                si := OM_Get(c0, "RefIndex", 0)
                                sid := 0
                                if (skByIdx.Has(si)) {
                                    sid := skByIdx[si]
                                } else {
                                    sid := 0
                                }
                                c["SkillId"] := sid
                                c["Cmp"] := OM_Get(c0, "Cmp", "GE")
                                c["Value"] := OM_Get(c0, "Value", 1)
                                if (sid <= 0) {
                                    badRefs := badRefs + 1
                                }
                            } else if (k = "ELAPSED") {
                                kindEL := kindEL + 1
                                c["Cmp"] := OM_Get(c0, "Cmp", "GE")
                                c["ElapsedMs"] := OM_Get(c0, "ElapsedMs", 0)
                            } else {
                                kindPR := kindPR + 1
                                rt2 := OM_Get(c0, "RefType", "Skill")
                                ri2 := OM_Get(c0, "RefIndex", 0)
                                refId2 := 0
                                if (StrUpper(rt2) = "SKILL") {
                                    if (skByIdx.Has(ri2)) {
                                        refId2 := skByIdx[ri2]
                                    } else {
                                        refId2 := 0
                                    }
                                } else {
                                    if (ptByIdx.Has(ri2)) {
                                        refId2 := ptByIdx[ri2]
                                    } else {
                                        refId2 := 0
                                    }
                                }
                                c["RefType"] := rt2
                                c["RefId"] := refId2
                                c["Op"] := OM_Get(c0, "Op", "NEQ")
                                c["Color"] := OM_Get(c0, "Color", "0x000000")
                                c["Tol"] := OM_Get(c0, "Tol", 16)
                                if (refId2 <= 0) {
                                    badRefs := badRefs + 1
                                }
                            }

                            carr.Push(c)
                            condTotal := condTotal + 1
                            j := j + 1
                        }
                    }
                } catch {
                }
                g["Conds"] := carr
                newGates.Push(g)
                i := i + 1
            }
        }
    } catch {
    }

    try {
        Logger_Warn("Gates", "prewrite_check", Map(
            "cond_total", condTotal
          , "cond_pixelready", kindPR
          , "cond_rulequiet",  kindRQ
          , "cond_counter",    kindCT
          , "cond_elapsed",    kindEL
          , "bad_refs",        badRefs
        ))
    } catch {
    }

    ok := false
    try {
        if !(p.Has("Rotation")) {
            p["Rotation"] := Map()
        }
        p["Rotation"]["Gates"] := newGates
        SaveModule_Gates(p)
        ok := true
    } catch as e2 {
        ok := false
        try {
            Logger_Exception("Gates", e2, Map("when","save","profile",profileName))
        } catch {
        }
    }
    if (!ok) {
        return false
    }

    try {
        Logger_Info("Storage", "save_ok", Map("module","gates","profile",profileName,"elapsed_ms",A_TickCount - t0))
    } catch {
    }

    ; Reload + 重建
    t1 := A_TickCount
    try {
        p2 := Storage_Profile_LoadFull(profileName)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        Logger_Info("Runtime", "reload_ok", Map("profile", profileName, "elapsed_ms", A_TickCount - t1))
    } catch as e3 {
        try {
            Logger_Exception("Gates", e3, Map("when","reload","profile",profileName))
        } catch {
        }
        return false
    }

    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
        Logger_Info("Gates", "runtime_reset", Map("actions", "Rotation_Reset,Rotation_InitFromProfile"))
    } catch {
    }

    return true
}