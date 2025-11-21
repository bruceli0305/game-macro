#Requires AutoHotkey v2
; modules\ui\pages\advanced\rotation\Page_RotGates.ahk

#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Gates.ahk"

Page_RotGates_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if (!IsSet(App) || !App.Has("ProfileData")) {
        UI.RGts_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        try {
            page.Controls.Push(UI.RGts_Empty)
        } catch {
        }
        return
    }

    cfg := App["ProfileData"].Rotation
    try {
        REUI_EnsureRotationDefaults(&cfg)
        REUI_Gates_Ensure(&cfg)
    } catch {
    }

    UI.RGts_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
        , ["优先级","来源轨","目标轨","逻辑","条件数"])
    try {
        page.Controls.Push(UI.RGts_LV)
    } catch {
    }

    yBtn := rc.Y + rc.H - 44
    UI.RGts_btnAdd  := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RGts_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RGts_btnDel  := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RGts_btnUp   := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RGts_btnDn   := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RGts_btnSave := UI.Main.Add("Button", "x+20 w110", "保存跳轨")

    arrBtns := [UI.RGts_btnAdd, UI.RGts_btnEdit, UI.RGts_btnDel, UI.RGts_btnUp, UI.RGts_btnDn, UI.RGts_btnSave]
    for ctl in arrBtns {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    try {
        REUI_Gates_FillList(UI.RGts_LV, cfg)
    } catch {
    }

    UI.RGts_btnAdd.OnEvent("Click", Page_RotGates_OnAdd)
    UI.RGts_btnEdit.OnEvent("Click", Page_RotGates_OnEdit)
    UI.RGts_btnDel.OnEvent("Click", Page_RotGates_OnDel)
    UI.RGts_btnUp.OnEvent("Click", (*) => Page_RotGates_OnMove(-1))
    UI.RGts_btnDn.OnEvent("Click", (*) => Page_RotGates_OnMove(1))
    UI.RGts_LV.OnEvent("DoubleClick", Page_RotGates_OnEdit)
    UI.RGts_btnSave.OnEvent("Click", Page_RotGates_OnSave)
}

Page_RotGates_Layout(rc) {
    try {
        UI.RGts_LV.Move(rc.X, rc.Y, rc.W, rc.H - 56)
        yBtn := rc.Y + rc.H - 44
        UI_MoveSafe(UI.RGts_btnAdd,  rc.X, yBtn)
        UI_MoveSafe(UI.RGts_btnEdit, "",   yBtn)
        UI_MoveSafe(UI.RGts_btnDel,  "",   yBtn)
        UI_MoveSafe(UI.RGts_btnUp,   "",   yBtn)
        UI_MoveSafe(UI.RGts_btnDn,   "",   yBtn)
        UI_MoveSafe(UI.RGts_btnSave, "",   yBtn)
    } catch {
    }
}

Page_RotGates_OnEnter(*) {
    try {
        cfg := Page_RotGates_GetCfg()
        if IsObject(cfg) {
            REUI_Gates_Ensure(&cfg)
            REUI_Gates_FillList(UI.RGts_LV, cfg)
        }
    } catch {
    }
}

Page_RotGates_GetCfg() {
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
        REUI_Gates_Ensure(&cfg)
        prof.Rotation := cfg
    } catch {
    }
    return cfg
}

Page_RotGates_OnAdd(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnAdd(cfg, UI.Main, UI.RGts_LV)
    }
}
Page_RotGates_OnEdit(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnEdit(UI.RGts_LV, cfg, UI.Main)
    }
}
Page_RotGates_OnDel(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnDel(UI.RGts_LV, cfg, UI.Main)
    }
}
Page_RotGates_OnMove(dir) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnMove(UI.RGts_LV, cfg, dir)
    }
}

; 模块化保存：索引→Id 映射，写 rotation_gates.ini
Page_RotGates_OnSave(*) {
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

    dbgGates := 0
    try {
        if Logger_IsEnabled(50, "Gates") {
            dbgGates := 1
        } else {
            dbgGates := 0
        }
    } catch {
        dbgGates := 0
    }
    if (dbgGates) {
        f0 := Map()
        try {
            f0["profile"] := name
            Logger_Debug("Gates", "Page_RotGates_OnSave begin", f0)
        } catch {
        }
    }

    cfg := Page_RotGates_GetCfg()
    if !IsObject(cfg) {
        MsgBox "配置不可用。"
        return
    }

    ; 构建索引→稳定 Id 的映射表
    skIdByIdx := Map()
    ptIdByIdx := Map()
    rlIdByIdx := Map()

    try {
        if (p.Has("Skills") && IsObject(p["Skills"])) {
            i := 1
            while (i <= p["Skills"].Length) {
                sid := 0
                try {
                    sid := OM_Get(p["Skills"][i], "Id", 0)
                } catch {
                    sid := 0
                }
                skIdByIdx[i] := sid
                i := i + 1
            }
        }
    } catch {
    }
    try {
        if (p.Has("Points") && IsObject(p["Points"])) {
            i := 1
            while (i <= p["Points"].Length) {
                pid := 0
                try {
                    pid := OM_Get(p["Points"][i], "Id", 0)
                } catch {
                    pid := 0
                }
                ptIdByIdx[i] := pid
                i := i + 1
            }
        }
    } catch {
    }
    try {
        if (p.Has("Rules") && IsObject(p["Rules"])) {
            i := 1
            while (i <= p["Rules"].Length) {
                rid := 0
                try {
                    rid := OM_Get(p["Rules"][i], "Id", 0)
                } catch {
                    rid := 0
                }
                rlIdByIdx[i] := rid
                i := i + 1
            }
        }
    } catch {
    }

    if (dbgGates) {
        f1 := Map()
        i := 1
        while (i <= 5) {
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
            Logger_Debug("Gates", "Skill idx→Id map (sample)", f1)
        } catch {
        }
    }

    ; 运行时 → 文件夹模型（仅 Gates）
    newGates := []
    totG := 0
    badRef := 0

    try {
        if (HasProp(cfg, "Gates") && IsObject(cfg.Gates)) {
            i := 1
            while (i <= cfg.Gates.Length) {
                g0 := cfg.Gates[i]
                g := Map()

                gid := 0
                try {
                    gid := OM_Get(g0, "Id", 0)
                } catch {
                    gid := 0
                }
                try {
                    g["Id"] := gid
                } catch {
                }

                pr := i
                try {
                    pr := OM_Get(g0, "Priority", i)
                } catch {
                    pr := i
                }
                try {
                    g["Priority"] := pr
                } catch {
                }

                fr := 0
                try {
                    fr := OM_Get(g0, "FromTrackId", 0)
                } catch {
                    fr := 0
                }
                try {
                    g["FromTrackId"] := fr
                } catch {
                }

                to := 0
                try {
                    to := OM_Get(g0, "ToTrackId", 0)
                } catch {
                    to := 0
                }
                try {
                    g["ToTrackId"] := to
                } catch {
                }

                lg := "AND"
                try {
                    lg := OM_Get(g0, "Logic", "AND")
                } catch {
                    lg := "AND"
                }
                try {
                    g["Logic"] := lg
                } catch {
                }

                cArr := []
                try {
                    if (HasProp(g0, "Conds") && IsObject(g0.Conds)) {
                        j := 1
                        while (j <= g0.Conds.Length) {
                            c0 := g0.Conds[j]
                            kind := ""
                            try {
                                kind := OM_Get(c0, "Kind", "PixelReady")
                            } catch {
                                kind := "PixelReady"
                            }
                            kU := ""
                            try {
                                kU := StrUpper(kind)
                            } catch {
                                kU := "PIXELREADY"
                            }

                            c := Map()
                            try {
                                c["Kind"] := kU
                            } catch {
                            }

                            if (kU = "PIXELREADY") {
                                rt := "Skill"
                                try {
                                    rt := OM_Get(c0, "RefType", "Skill")
                                } catch {
                                    rt := "Skill"
                                }
                                ri := 0
                                try {
                                    ri := OM_Get(c0, "RefIndex", 0)
                                } catch {
                                    ri := 0
                                }
                                refId := 0
                                if (StrUpper(rt) = "SKILL") {
                                    try {
                                        if (skIdByIdx.Has(ri)) {
                                            refId := skIdByIdx[ri]
                                        } else {
                                            refId := 0
                                        }
                                    } catch {
                                        refId := 0
                                    }
                                } else {
                                    try {
                                        if (ptIdByIdx.Has(ri)) {
                                            refId := ptIdByIdx[ri]
                                        } else {
                                            refId := 0
                                        }
                                    } catch {
                                        refId := 0
                                    }
                                }

                                op := "NEQ"
                                try {
                                    op := OM_Get(c0, "Op", "NEQ")
                                } catch {
                                    op := "NEQ"
                                }
                                col := "0x000000"
                                try {
                                    col := OM_Get(c0, "Color", "0x000000")
                                } catch {
                                    col := "0x000000"
                                }
                                tl := 16
                                try {
                                    tl := OM_Get(c0, "Tol", 16)
                                } catch {
                                    tl := 16
                                }

                                rIdx := 0
                                try {
                                    rIdx := OM_Get(c0, "RuleId", 0)
                                } catch {
                                    rIdx := 0
                                }
                                rId := 0
                                try {
                                    if (rlIdByIdx.Has(rIdx)) {
                                        rId := rlIdByIdx[rIdx]
                                    } else {
                                        rId := 0
                                    }
                                } catch {
                                    rId := 0
                                }

                                q := 0
                                try {
                                    q := OM_Get(c0, "QuietMs", 0)
                                } catch {
                                    q := 0
                                }
                                cmp := "GE"
                                try {
                                    cmp := OM_Get(c0, "Cmp", "GE")
                                } catch {
                                    cmp := "GE"
                                }
                                val := 0
                                try {
                                    val := OM_Get(c0, "Value", 0)
                                } catch {
                                    val := 0
                                }
                                ems := 0
                                try {
                                    ems := OM_Get(c0, "ElapsedMs", 0)
                                } catch {
                                    ems := 0
                                }

                                try {
                                    c["RefType"] := rt
                                    c["RefId"] := refId
                                    c["Op"] := op
                                    c["Color"] := col
                                    c["Tol"] := tl
                                    c["RuleId"] := rId
                                    c["QuietMs"] := q
                                    c["Cmp"] := cmp
                                    c["Value"] := val
                                    c["ElapsedMs"] := ems
                                } catch {
                                }

                                if (refId <= 0) {
                                    badRef := badRef + 1
                                }
                            } else if (kU = "RULEQUIET") {
                                rIdx := 0
                                try {
                                    rIdx := OM_Get(c0, "RuleId", 0)
                                } catch {
                                    rIdx := 0
                                }
                                rId := 0
                                try {
                                    if (rlIdByIdx.Has(rIdx)) {
                                        rId := rlIdByIdx[rIdx]
                                    } else {
                                        rId := 0
                                    }
                                } catch {
                                    rId := 0
                                }
                                q2 := 0
                                try {
                                    q2 := OM_Get(c0, "QuietMs", 0)
                                } catch {
                                    q2 := 0
                                }
                                try {
                                    c["RuleId"] := rId
                                    c["QuietMs"] := q2
                                } catch {
                                }
                                if (rId <= 0) {
                                    badRef := badRef + 1
                                }
                            } else if (kU = "COUNTER") {
                                si := 0
                                try {
                                    si := OM_Get(c0, "RefIndex", 0)
                                } catch {
                                    si := 0
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
                                cp := "GE"
                                try {
                                    cp := OM_Get(c0, "Cmp", "GE")
                                } catch {
                                    cp := "GE"
                                }
                                vv := 1
                                try {
                                    vv := OM_Get(c0, "Value", 1)
                                } catch {
                                    vv := 1
                                }
                                try {
                                    c["SkillId"] := sid
                                    c["Cmp"] := cp
                                    c["Value"] := vv
                                } catch {
                                }
                                if (sid <= 0) {
                                    badRef := badRef + 1
                                }
                            } else if (kU = "ELAPSED") {
                                cp2 := "GE"
                                try {
                                    cp2 := OM_Get(c0, "Cmp", "GE")
                                } catch {
                                    cp2 := "GE"
                                }
                                ms2 := 0
                                try {
                                    ms2 := OM_Get(c0, "ElapsedMs", 0)
                                } catch {
                                    ms2 := 0
                                }
                                try {
                                    c["Cmp"] := cp2
                                    c["ElapsedMs"] := ms2
                                } catch {
                                }
                            } else {
                                rt2 := "Skill"
                                try {
                                    rt2 := OM_Get(c0, "RefType", "Skill")
                                } catch {
                                    rt2 := "Skill"
                                }
                                ri2 := 0
                                try {
                                    ri2 := OM_Get(c0, "RefIndex", 0)
                                } catch {
                                    ri2 := 0
                                }
                                refId2 := 0
                                if (StrUpper(rt2) = "SKILL") {
                                    try {
                                        if (skIdByIdx.Has(ri2)) {
                                            refId2 := skIdByIdx[ri2]
                                        } else {
                                            refId2 := 0
                                        }
                                    } catch {
                                        refId2 := 0
                                    }
                                } else {
                                    try {
                                        if (ptIdByIdx.Has(ri2)) {
                                            refId2 := ptIdByIdx[ri2]
                                        } else {
                                            refId2 := 0
                                        }
                                    } catch {
                                        refId2 := 0
                                    }
                                }
                                op2 := "NEQ"
                                try {
                                    op2 := OM_Get(c0, "Op", "NEQ")
                                } catch {
                                    op2 := "NEQ"
                                }
                                col2 := "0x000000"
                                try {
                                    col2 := OM_Get(c0, "Color", "0x000000")
                                } catch {
                                    col2 := "0x000000"
                                }
                                tl2 := 16
                                try {
                                    tl2 := OM_Get(c0, "Tol", 16)
                                } catch {
                                    tl2 := 16
                                }
                                try {
                                    c["RefType"] := rt2
                                    c["RefId"] := refId2
                                    c["Op"] := op2
                                    c["Color"] := col2
                                    c["Tol"] := tl2
                                } catch {
                                }
                                if (refId2 <= 0) {
                                    badRef := badRef + 1
                                }
                            }

                            cArr.Push(c)
                            j := j + 1
                        }
                    }
                } catch {
                }

                try {
                    g["Conds"] := cArr
                } catch {
                }

                newGates.Push(g)
                totG := totG + 1
                i := i + 1
            }
        }
    } catch {
    }

    if (dbgGates) {
        sm := Map()
        try {
            sm["Gates"] := totG
            sm["BadRefs"] := badRef
            Logger_Warn("Gates", "Page_RotGates_OnSave summary", sm)
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
        p["Rotation"]["Gates"] := newGates
    } catch {
        p["Rotation"] := Map("Gates", newGates)
    }

    ok := false
    try {
        SaveModule_Gates(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        try RE_OnProfileDataReplaced(App["ProfileData"])
    } catch {
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    ; 注意：ByRef 不能传表达式，先放到局部变量再传引用
    rot := 0
    try {
        rot := App["ProfileData"].Rotation
    } catch {
        rot := 0
    }
    try {
        if IsObject(rot) {
            REUI_Gates_Ensure(&rot)
            REUI_Gates_FillList(UI.RGts_LV, rot)
            App["ProfileData"].Rotation := rot
        }
    } catch {
    }

    Notify("跳轨已保存")
}