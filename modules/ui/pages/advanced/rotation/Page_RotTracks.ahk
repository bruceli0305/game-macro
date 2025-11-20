#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Tracks.ahk"

Page_RotTracks_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []
    if (!IsSet(App) || !App.Has("ProfileData")) {
        UI.RT_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        try {
            page.Controls.Push(UI.RT_Empty)
        } catch {
        }
        return
    }

    cfg := Page_RotTracks_GetCfg()

    UI.RT_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
    , ["ID", "名称", "线程", "最长ms", "最短停留", "下一轨", "Watch#", "规则#"])
    try {
        page.Controls.Push(UI.RT_LV)
    } catch {
    }

    yBtn := rc.Y + rc.H - 44
    UI.RT_btnAdd := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RT_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RT_btnDel := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RT_btnUp := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RT_btnDn := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RT_btnSave := UI.Main.Add("Button", "x+20 w110", "保存轨道")

    arrBtns := [UI.RT_btnAdd, UI.RT_btnEdit, UI.RT_btnDel, UI.RT_btnUp, UI.RT_btnDn, UI.RT_btnSave]
    for ctl in arrBtns {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    try {
        REUI_Tracks_Ensure(&cfg)
        REUI_Tracks_FillList(UI.RT_LV, cfg)
    } catch {
    }

    UI.RT_btnAdd.OnEvent("Click", Page_RotTracks_OnAdd)
    UI.RT_btnEdit.OnEvent("Click", Page_RotTracks_OnEdit)
    UI.RT_btnDel.OnEvent("Click", Page_RotTracks_OnDel)
    UI.RT_btnUp.OnEvent("Click", (*) => Page_RotTracks_OnMove(-1))
    UI.RT_btnDn.OnEvent("Click", (*) => Page_RotTracks_OnMove(1))
    UI.RT_LV.OnEvent("DoubleClick", Page_RotTracks_OnEdit)
    UI.RT_btnSave.OnEvent("Click", Page_RotTracks_OnSave)
}

Page_RotTracks_Layout(rc) {
    try {
        UI.RT_LV.Move(rc.X, rc.Y, rc.W, rc.H - 56)
        yBtn := rc.Y + rc.H - 44
        UI_MoveSafe(UI.RT_btnAdd, rc.X, yBtn)
        UI_MoveSafe(UI.RT_btnEdit, "", yBtn)
        UI_MoveSafe(UI.RT_btnDel, "", yBtn)
        UI_MoveSafe(UI.RT_btnUp, "", yBtn)
        UI_MoveSafe(UI.RT_btnDn, "", yBtn)
        UI_MoveSafe(UI.RT_btnSave, "", yBtn)
    } catch {
    }
}

Page_RotTracks_OnEnter(*) {
    try {
        cfg := Page_RotTracks_GetCfg()
        if IsObject(cfg) {
            REUI_Tracks_Ensure(&cfg)
            REUI_Tracks_FillList(UI.RT_LV, cfg)
        }
    } catch {
    }
}

Page_RotTracks_GetCfg() {
    global App
    if (!IsSet(App) || !App.Has("ProfileData")) {
        return 0
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    try {
        REUI_EnsureRotationDefaults(&cfg)
    } catch {
    }
    return cfg
}

Page_RotTracks_OnAdd(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnAdd(cfg, UI.Main, UI.RT_LV)
    }
}

Page_RotTracks_OnEdit(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnEdit(UI.RT_LV, cfg, UI.Main)
    }
}

Page_RotTracks_OnDel(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnDel(UI.RT_LV, cfg)
    }
}

Page_RotTracks_OnMove(dir) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnMove(UI.RT_LV, cfg, dir)
    }
}

Page_RotTracks_OnSave(*) {
    global App
    if !(IsSet(App) && App.Has("CurrentProfile") && App.Has("ProfileData")) {
        MsgBox "未选择配置或配置未加载。"
        return
    }
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置。"
        return
    }

    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch {
        MsgBox "加载配置失败。"
        return
    }

    dbgTracks := 0
    try {
        if Logger_IsEnabled(50, "Tracks") {
            dbgTracks := 1
        } else {
            dbgTracks := 0
        }
    } catch {
        dbgTracks := 0
    }
    if (dbgTracks) {
        f0 := Map()
        try {
            f0["profile"] := name
        } catch {
        }
        try {
            Logger_Debug("Tracks", "Page_RotTracks_OnSave begin", f0)
        } catch {
        }
    }

    cfg := Page_RotTracks_GetCfg()
    if !IsObject(cfg) {
        MsgBox "配置不可用。"
        return
    }

    ; 索引 → 稳定 Id 映射（改为 OM_Get 取 Map 字段）
    skIdByIdx := Map()
    rlIdByIdx := Map()

    try {
        if (p.Has("Skills") && IsObject(p["Skills"])) {
            si := 1
            while (si <= p["Skills"].Length) {
                sid := 0
                try {
                    sid := OM_Get(p["Skills"][si], "Id", 0)
                } catch {
                    sid := 0
                }
                skIdByIdx[si] := sid
                si := si + 1
            }
        }
    } catch {
    }
    try {
        if (p.Has("Rules") && IsObject(p["Rules"])) {
            ri := 1
            while (ri <= p["Rules"].Length) {
                rid := 0
                try {
                    rid := OM_Get(p["Rules"][ri], "Id", 0)
                } catch {
                    rid := 0
                }
                rlIdByIdx[ri] := rid
                ri := ri + 1
            }
        }
    } catch {
    }

    if (dbgTracks) {
        f1 := Map()
        i := 1
        while (i <= 10) {
            v := ""
            try {
                if skIdByIdx.Has(i) {
                    v := skIdByIdx[i]
                } else {
                    v := "(none)"
                }
            } catch {
                v := "(err)"
            }
            try {
                f1["s" i] := v
            } catch {
            }
            i := i + 1
        }
        try {
            Logger_Debug("Tracks", "Skill idx→Id map (first 10)", f1)
        } catch {
        }

        f2 := Map()
        i := 1
        while (i <= 10) {
            v2 := ""
            try {
                if rlIdByIdx.Has(i) {
                    v2 := rlIdByIdx[i]
                } else {
                    v2 := "(none)"
                }
            } catch {
                v2 := "(err)"
            }
            try {
                f2["r" i] := v2
            } catch {
            }
            i := i + 1
        }
        try {
            Logger_Debug("Tracks", "Rule idx→Id map (first 10)", f2)
        } catch {
        }
    }

    newTracks := []
    totTracks := 0
    totWatch := 0
    totWatchZero := 0
    totRefs := 0
    totRefsZero := 0

    try {
        if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks)) {
            i := 1
            while (i <= cfg.Tracks.Length) {
                t := cfg.Tracks[i]

                if (dbgTracks) {
                    info := Map()
                    try {
                        info["TrackRow"] := i
                        info["Tid"] := HasProp(t, "Id") ? t.Id : 0
                        info["Name"] := HasProp(t, "Name") ? t.Name : ""
                        info["ThreadId"] := HasProp(t, "ThreadId") ? t.ThreadId : 1
                        info["WatchCount"] := (HasProp(t, "Watch") && IsObject(t.Watch)) ? t.Watch.Length : 0
                            info["RuleRefCount"] := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length :
                                0
                                Logger_Info("Tracks", "Track begin", info)
                    } catch {
                    }
                }

                tr := Map()
                tid := 0
                try {
                    tid := HasProp(t, "Id") ? t.Id : 0
                } catch {
                    tid := 0
                }
                tr["Id"] := tid

                nm := ""
                try {
                    nm := HasProp(t, "Name") ? t.Name : ""
                } catch {
                    nm := ""
                }
                tr["Name"] := nm

                v := 1
                try {
                    v := HasProp(t, "ThreadId") ? t.ThreadId : 1
                } catch {
                    v := 1
                }
                tr["ThreadId"] := v

                v := 8000
                try {
                    v := HasProp(t, "MaxDurationMs") ? t.MaxDurationMs : 8000
                } catch {
                    v := 8000
                }
                tr["MaxDurationMs"] := v

                v := 0
                try {
                    v := HasProp(t, "MinStayMs") ? t.MinStayMs : 0
                } catch {
                    v := 0
                }
                tr["MinStayMs"] := v

                v := 0
                try {
                    v := HasProp(t, "NextTrackId") ? t.NextTrackId : 0
                } catch {
                    v := 0
                }
                tr["NextTrackId"] := v

                wArr := []
                try {
                    if (HasProp(t, "Watch") && IsObject(t.Watch)) {
                        j := 1
                        while (j <= t.Watch.Length) {
                            w := t.Watch[j]
                            si := 0
                            need := 1
                            vb := 0
                            try {
                                si := HasProp(w, "SkillIndex") ? Integer(w.SkillIndex) : 0
                            } catch {
                                si := 0
                            }
                            try {
                                need := HasProp(w, "RequireCount") ? w.RequireCount : 1
                            } catch {
                                need := 1
                            }
                            try {
                                vb := HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0
                            } catch {
                                vb := 0
                            }

                            sid := 0
                            try {
                                if (skIdByIdx.Has(si)) {
                                    sid := skIdByIdx[si]
                                } else {
                                    sid := 0
                                }
                            } catch {
                                sid := 0
                            }

                            if (dbgTracks) {
                                rowLog := Map()
                                try {
                                    rowLog["TrackRow"] := i
                                    rowLog["WatchIdx"] := j
                                    rowLog["SkillIndex"] := si
                                    rowLog["SkillId"] := sid
                                    rowLog["RequireCount"] := need
                                    rowLog["VerifyBlack"] := vb
                                    Logger_Debug("Tracks", "Map Watch SkillIndex→SkillId", rowLog)
                                } catch {
                                }
                            }

                            totWatch := totWatch + 1
                            if (sid <= 0) {
                                totWatchZero := totWatchZero + 1
                            }

                            wArr.Push(Map("SkillId", sid, "RequireCount", need, "VerifyBlack", vb))
                            j := j + 1
                        }
                    }
                } catch {
                }
                tr["Watch"] := wArr

                rArr := []
                try {
                    if (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) {
                        j := 1
                        while (j <= t.RuleRefs.Length) {
                            idx := 0
                            try {
                                idx := Integer(t.RuleRefs[j])
                            } catch {
                                idx := 0
                            }
                            rid := 0
                            try {
                                if (rlIdByIdx.Has(idx)) {
                                    rid := rlIdByIdx[idx]
                                } else {
                                    rid := 0
                                }
                            } catch {
                                rid := 0
                            }

                            if (dbgTracks) {
                                rrLog := Map()
                                try {
                                    rrLog["TrackRow"] := i
                                    rrLog["RuleRefIdx"] := j
                                    rrLog["RuleIndex"] := idx
                                    rrLog["RuleId"] := rid
                                    Logger_Debug("Tracks", "Map RuleIndex→RuleId", rrLog)
                                } catch {
                                }
                            }

                            totRefs := totRefs + 1
                            if (rid <= 0) {
                                totRefsZero := totRefsZero + 1
                            }

                            rArr.Push(rid)
                            j := j + 1
                        }
                    }
                } catch {
                }
                tr["RuleRefs"] := rArr

                newTracks.Push(tr)
                totTracks := totTracks + 1
                i := i + 1
            }
        }
    } catch {
    }

    if (dbgTracks) {
        sum := Map()
        try {
            sum["Tracks"] := totTracks
            sum["WatchTotal"] := totWatch
            sum["WatchZero"] := totWatchZero
            sum["RuleRefTotal"] := totRefs
            sum["RuleRefZero"] := totRefsZero
            Logger_Warn("Tracks", "Save summary", sum)
        } catch {
        }
    }

    try {
        if !(p.Has("Rotation")) {
            p["Rotation"] := Map()
        }
    } catch {
    }
    try {
        p["Rotation"]["Tracks"] := newTracks
    } catch {
        p["Rotation"] := Map("Tracks", newTracks)
    }

    ok := false
    try {
        SaveModule_Tracks(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    needFix := false
    newDef := 0
    try {
        defId := 0
        try {
            defId := App["ProfileData"].Rotation.DefaultTrackId
        } catch {
            defId := 0
        }

        idSet := Map()
        for _, trk in newTracks {
            tid := 0
            try {
                tid := trk.Has("Id") ? trk["Id"] : 0
            } catch {
                tid := 0
            }
            try {
                idSet[tid] := 1
            } catch {
            }
        }

        hasDef := false
        try {
            hasDef := (defId != 0 && idSet.Has(defId))
        } catch {
            hasDef := false
        }

        if (!hasDef) {
            for _, trk in newTracks {
                tid := 0
                try {
                    tid := trk.Has("Id") ? trk["Id"] : 0
                } catch {
                    tid := 0
                }
                if (tid > 0) {
                    newDef := tid
                    break
                }
            }
            needFix := true
        }
    } catch {
        needFix := false
    }

    if (needFix) {
        rot := Map()
        try {
            rot := p["Rotation"]
        } catch {
            rot := Map()
        }
        try {
            rot["DefaultTrackId"] := newDef
        } catch {
        }
        try {
            p["Rotation"] := rot
        } catch {
        }
        try {
            SaveModule_RotationBase(p)
        } catch {
        }
    }

    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
    } catch {
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
    } catch {
    }

    try {
        cfg2 := Page_RotTracks_GetCfg()
        if IsObject(cfg2) {
            REUI_Tracks_Ensure(&cfg2)
            REUI_Tracks_FillList(UI.RT_LV, cfg2)
        }
    } catch {
    }

    Notify("轨道已保存")
}
