#Requires AutoHotkey v2
; modules\ui\rotation\RE_UI_Page_Gates.ahk
#Include "RE_UI_Common.ahk"

REUI_Page_Gates_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(3)
    try {
        REUI_Gates_Ensure(&cfg)
    } catch {
    }

    lv := dlg.Add("ListView", "xm y+8 w820 r12 +Grid", ["优先级","来源轨","目标轨","逻辑","条件数"])
    btnAdd  := dlg.Add("Button", "xm y+8 w90", "新增")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnDel  := dlg.Add("Button", "x+8 w90", "删除")
    btnUp   := dlg.Add("Button", "x+8 w90", "上移")
    btnDn   := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w110", "保存跳轨")

    try {
        REUI_Gates_FillList(lv, cfg)
    } catch {
    }

    btnAdd.OnEvent("Click", (*) => REUI_Gates_OnAdd(cfg, dlg, lv))
    btnEdit.OnEvent("Click", (*) => REUI_Gates_OnEdit(lv, cfg, dlg))
    btnDel.OnEvent("Click", (*) => REUI_Gates_OnDel(lv, cfg, dlg))
    btnUp.OnEvent("Click", (*) => REUI_Gates_OnMove(lv, cfg, -1))
    btnDn.OnEvent("Click", (*) => REUI_Gates_OnMove(lv, cfg, 1))
    lv.OnEvent("DoubleClick", (*) => REUI_Gates_OnEdit(lv, cfg, dlg))
    btnSave.OnEvent("Click", SaveGates)

    SaveGates(*) {
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

        dbgG := 0
        try {
            if Logger_IsEnabled(50, "Gates") {
                dbgG := 1
            } else {
                dbgG := 0
            }
        } catch {
            dbgG := 0
        }
        if (dbgG) {
            f0 := Map()
            try {
                f0["profile"] := name
                Logger_Debug("Gates", "REUI_Page_Gates.SaveGates begin", f0)
            } catch {
            }
        }

        ; 映射索引→Id
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

        if (dbgG) {
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
                Logger_Debug("Gates", "Skill idx→Id map (first 10)", f1)
            } catch {
            }
        }

        cfg := ctx.cfg
        newGates := []
        tot := 0
        bad := 0

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
                    pri := i
                    try {
                        pri := OM_Get(g0, "Priority", i)
                    } catch {
                        pri := i
                    }
                    try {
                        g["Priority"] := pri
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
                                        bad := bad + 1
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
                                        bad := bad + 1
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
                                        bad := bad + 1
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
                                    try {
                                        c["RefType"] := rt2
                                        c["RefId"] := refId2
                                        c["Op"] := OM_Get(c0, "Op", "NEQ")
                                        c["Color"] := OM_Get(c0, "Color", "0x000000")
                                        c["Tol"] := OM_Get(c0, "Tol", 16)
                                    } catch {
                                    }
                                    if (refId2 <= 0) {
                                        bad := bad + 1
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
                    tot := tot + 1
                    i := i + 1
                }
            }
        } catch {
        }

        if (dbgG) {
            sm := Map()
            try {
                sm["Gates"] := tot
                sm["BadRefs"] := bad
                Logger_Warn("Gates", "REUI_Page_Gates.SaveGates summary", sm)
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
        } catch {
            MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
            return
        }

        try {
            cfg2 := App["ProfileData"].Rotation
            REUI_Gates_Ensure(&cfg2)
            REUI_Gates_FillList(lv, cfg2)
        } catch {
        }

        Notify("跳轨已保存")
    }

    return { Save: () => 0 }
}

;------------------------------ 列表/数据 ------------------------------
REUI_Gates_Ensure(&cfg) {
    if (!HasProp(cfg, "Gates") || !IsObject(cfg.Gates)) {
        cfg.Gates := []
    }
    if (cfg.Gates.Length = 0) {
        cfg.Gates.Push({ Priority: 1, FromTrackId: 0, ToTrackId: 0, Logic: "AND", Conds: [] })
    }
    for i, g in cfg.Gates {
        if (!HasProp(g, "Priority")) {
            g.Priority := i
        }
        if (!HasProp(g, "FromTrackId")) {
            g.FromTrackId := 0
        }
        if (!HasProp(g, "ToTrackId")) {
            g.ToTrackId := 0
        }
        if (!HasProp(g, "Logic")) {
            g.Logic := "AND"
        }
        if (!HasProp(g, "Conds") || !IsObject(g.Conds)) {
            g.Conds := []
        }
    }
}
REUI_Gates_FillList(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if HasProp(cfg,"Gates") && IsObject(cfg.Gates) {
            for _, g in cfg.Gates {
                pri := HasProp(g,"Priority")    ? g.Priority    : 0
                frm := HasProp(g,"FromTrackId") ? g.FromTrackId : 0
                tgt := HasProp(g,"ToTrackId")   ? g.ToTrackId   : 0
                lgc := HasProp(g,"Logic")       ? g.Logic       : "AND"
                cnt := 0
                try {
                    cnt := (HasProp(g,"Conds") && IsObject(g.Conds)) ? g.Conds.Length : 0
                } catch {
                    cnt := 0
                }
                try {
                    lv.Add("", pri, frm, tgt, lgc, cnt)
                } catch {
                }
            }
        }
        Loop 5 {
            try {
                lv.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            lv.Opt("+Redraw")
        } catch {
        }
    }
}
REUI_Gates_Renum(cfg) {
    if HasProp(cfg,"Gates") && IsObject(cfg.Gates) {
        for i, g in cfg.Gates {
            g.Priority := i
        }
    }
}
REUI_Gates_OnAdd(cfg, owner, lv) {
    OnSaved(ng, idx) {
        try {
            cfg.Gates.Push(ng)
            REUI_Gates_Renum(cfg)
            REUI_Gates_FillList(lv, cfg)
        } catch {
        }
    }
    g := { Priority: (HasProp(cfg,"Gates")?cfg.Gates.Length:0)+1, FromTrackId: 0, ToTrackId: 0, Logic:"AND", Conds:[] }
    REUI_GateEditor_Open(owner, cfg, g, 0, OnSaved)
}
REUI_Gates_OnEdit(lv, cfg, owner) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if !row {
        MsgBox "请选择一个跳轨规则"
        return
    }
    if (row < 1 || row > cfg.Gates.Length) {
        return
    }
    cur := cfg.Gates[row]
    OnSaved(ng, i) {
        try {
            cfg.Gates[i] := ng
            REUI_Gates_Renum(cfg)
            REUI_Gates_FillList(lv, cfg)
        } catch {
        }
    }
    REUI_GateEditor_Open(owner, cfg, cur, row, OnSaved)
}
REUI_Gates_OnDel(lv, cfg, owner) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if !row {
        MsgBox "请选择一个跳轨规则"
        return
    }
    try {
        cfg.Gates.RemoveAt(row)
    } catch {
    }
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    Notify("已删除跳轨规则")
}
REUI_Gates_OnMove(lv, cfg, dir) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if !row {
        return
    }
    from := row
    to := from + dir
    if (to < 1 || to > cfg.Gates.Length) {
        return
    }
    item := cfg.Gates[from]
    try {
        cfg.Gates.RemoveAt(from)
    } catch {
    }
    try {
        cfg.Gates.InsertAt(to, item)
    } catch {
    }
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    try {
        lv.Modify(to, "Select Focus Vis")
    } catch {
    }
}
;------------------------------ Gate 编辑器（保持索引引用） ------------------------------
REUI_GateEditor_Open(owner, cfg, g, idx := 0, onSaved := 0) {
    global UI
    isNew := (idx = 0)

    if (!IsObject(g)) {
        g := {}
    }
    if (!HasProp(g, "Priority")) {
        len := 0
        try {
            len := (HasProp(cfg, "Gates") && IsObject(cfg.Gates)) ? cfg.Gates.Length : 0
        } catch {
            len := 0
        }
        g.Priority := isNew ? (len + 1) : idx
    }
    if (!HasProp(g, "FromTrackId")) {
        g.FromTrackId := 0
    }
    if (!HasProp(g, "ToTrackId")) {
        g.ToTrackId := 0
    }
    if (!HasProp(g, "Logic")) {
        g.Logic := "AND"
    }
    if (!HasProp(g, "Conds") || !IsObject(g.Conds)) {
        g.Conds := []
    }

    ownHwnd := 0
    try {
        ownHwnd := owner.Hwnd
    } catch {
        try {
            ownHwnd := UI.Main.Hwnd
        } catch {
            ownHwnd := 0
        }
    }
    ge := Gui(ownHwnd ? Format("+Owner {}", ownHwnd) : "", isNew ? "新增跳轨" : "编辑跳轨")
    ge.MarginX := 12
    ge.MarginY := 10
    ge.SetFont("s10", "Segoe UI")

    ge.Add("Text", "w90 Right", "优先级：")
    edPri := ge.Add("Edit", "x+6 w120 Number", g.Priority)

    ; 来源轨
    ge.Add("Text", "xm y+8 w90 Right", "来源轨：")
    ddFrom := ge.Add("DropDownList", "x+6 w120")
    trackIds := REUI_ListTrackIds(cfg)
    arrFrom := []
    for _, id in trackIds {
        arrFrom.Push(id)
    }
    if (arrFrom.Length) {
        ddFrom.Add(arrFrom)
    }
    selFrom := 1
    for i, v in arrFrom {
        if (Integer(v) = Integer(g.FromTrackId)) {
            selFrom := i
            break
        }
    }
    ddFrom.Value := selFrom

    ; 目标轨
    ge.Add("Text", "x+20 w90 Right", "目标轨：")
    ddTo := ge.Add("DropDownList", "x+6 w120")
    arrTo := []
    for _, id in trackIds {
        arrTo.Push(id)
    }
    if (arrTo.Length) {
        ddTo.Add(arrTo)
    }
    selTo := 1
    for i, v in arrTo {
        if (Integer(v) = Integer(g.ToTrackId)) {
            selTo := i
            break
        }
    }
    ddTo.Value := selTo

    ge.Add("Text", "xm y+8 w90 Right", "逻辑：")
    ddLogic := ge.Add("DropDownList", "x+6 w120", ["AND", "OR"])
    ddLogic.Value := (StrUpper(g.Logic) = "OR") ? 2 : 1

    ge.Add("Text", "xm y+8", "条件：")
    lvC := ge.Add("ListView", "xm w760 r9 +Grid", ["类型", "摘要"])
    btnCAdd := ge.Add("Button", "xm y+8 w90", "新增")
    btnCEdit := ge.Add("Button", "x+8 w90", "编辑")
    btnCDel := ge.Add("Button", "x+8 w90", "删除")

    REUI_GateEditor_FillConds(lvC, g)

    btnCAdd.OnEvent("Click", (*) => REUI_CondEditor_OnAdd(lvC, ge, cfg, g))
    btnCEdit.OnEvent("Click", (*) => REUI_CondEditor_OnEdit(lvC, ge, cfg, g))
    btnCDel.OnEvent("Click", (*) => REUI_CondEditor_OnDel(lvC, g))
    lvC.OnEvent("DoubleClick", (*) => REUI_CondEditor_OnEdit(lvC, ge, cfg, g))

    btnOK := ge.Add("Button", "xm y+12 w100", "保存")
    btnCA := ge.Add("Button", "x+8 w100", "取消")
    btnOK.OnEvent("Click", SaveGate)
    btnCA.OnEvent("Click", (*) => ge.Destroy())
    ge.OnEvent("Close", (*) => ge.Destroy())
    ge.Show()

    SaveGate(*) {
        p := (edPri.Value != "") ? Integer(edPri.Value) : (idx = 0 ? 1 : idx)
        g.Priority := Max(1, p)

        if (ddFrom.Value < 1 || ddFrom.Value > arrFrom.Length) {
            MsgBox "请选择来源轨。"
            return
        }
        if (ddTo.Value < 1 || ddTo.Value > arrTo.Length) {
            MsgBox "请选择目标轨。"
            return
        }

        g.FromTrackId := Integer(arrFrom[ddFrom.Value])
        g.ToTrackId   := Integer(arrTo[ddTo.Value])
        g.Logic := (ddLogic.Value = 2) ? "OR" : "AND"

        if onSaved {
            onSaved(g, (idx = 0 ? 0 : idx))
        }
        ge.Destroy()
        Notify(isNew ? "已新增跳轨" : "已保存跳轨")
    }
}

REUI_GateEditor_FillConds(lv, g) {
    lv.Opt("-Redraw")
    lv.Delete()
    if HasProp(g,"Conds") && IsObject(g.Conds) {
        for _, c in g.Conds {
            lv.Add("", HasProp(c,"Kind")?c.Kind:"?", REUI_GateCond_Summary(c))
        }
    }
    Loop 2 {
        lv.ModifyCol(A_Index, "AutoHdr")
    }
    lv.Opt("+Redraw")
}
REUI_GateCond_Summary(c) {
    kind := HasProp(c,"Kind") ? StrUpper(c.Kind) : "?"
    if (kind="PIXELREADY") {
        rt := HasProp(c,"RefType")?c.RefType:"Skill"
        ri := HasProp(c,"RefIndex")?c.RefIndex:0
        op := (StrUpper(HasProp(c,"Op")?c.Op:"NEQ")="EQ") ? "等于" : "不等于"
        return "像素就绪 " rt "#" ri " " op
    } else if (kind="RULEQUIET") {
        rid := HasProp(c,"RuleId")?c.RuleId:0
        q := HasProp(c,"QuietMs")?c.QuietMs:0
        return "规则静默 规则#" rid " ≥" q "ms"
    } else if (kind="COUNTER") {
        si := HasProp(c,"RefIndex")?c.RefIndex:0
        cmp:= HasProp(c,"Cmp")?c.Cmp:"GE"
        txt := (cmp="GE")?">=":(cmp="EQ")?"==":(cmp="GT")?">":(cmp="LE")?"<=":"<"
        v := HasProp(c,"Value")?c.Value:1
        return "计数 技能#" si " " txt " " v
    } else if (kind="ELAPSED") {
        cmp:= HasProp(c,"Cmp")?c.Cmp:"GE"
        txt := (cmp="GE")?">=":(cmp="EQ")?"==":(cmp="GT")?">":(cmp="LE")?"<=":"<"
        ms := HasProp(c,"ElapsedMs")?c.ElapsedMs:0
        return "阶段用时 " txt " " ms "ms"
    }
    return "?"
}

;------------------------------ 条件编辑器 ------------------------------
REUI_CondEditor_OnAdd(lv, owner, cfg, g) {
    OnSaved(saved, i) {
        g.Conds.Push(saved)
        REUI_GateEditor_FillConds(lv, g)
    }
    nc := {}
    REUI_CondEditor_Open(owner, cfg, nc, 0, OnSaved)
}
REUI_CondEditor_OnEdit(lv, owner, cfg, g) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一个条件"
        return
    }
    cur := g.Conds[row]
    OnSaved(saved, i) {
        g.Conds[i] := saved
        REUI_GateEditor_FillConds(lv, g)
    }
    REUI_CondEditor_Open(owner, cfg, cur, row, OnSaved)
}
REUI_CondEditor_OnDel(lv, g) {
    row := lv.GetNext(0, "Focused")
    if !row {
        return
    }
    g.Conds.RemoveAt(row)
    lv.Delete(row)
}

REUI_CondEditor_Open(owner, cfg, c, idx := 0, onSaved := 0) {
    if !IsObject(c) {
        c := {}
    }
    if !HasProp(c,"Kind") {
        c.Kind := "PixelReady"
    }

    ge2 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增条件" : "编辑条件")
    ge2.MarginX := 12
    ge2.MarginY := 10
    ge2.SetFont("s10","Segoe UI")

    ge2.Add("Text","w90 Right","类型：")
    ddKind := ge2.Add("DropDownList","x+6 w180", ["像素就绪","规则静默","计数","阶段用时"])
    k := StrUpper(c.Kind)
    ddKind.Value := (k="PIXELREADY")?1:(k="RULEQUIET")?2:(k="COUNTER")?3:4

    ; PixelReady
    grpP1 := ge2.Add("Text","xm y+10 w90 Right","引用类型：")
    ddRefType := ge2.Add("DropDownList","x+6 w140", ["技能","点位"])
    ddRefType.Value := (StrUpper(HasProp(c,"RefType")?c.RefType:"Skill")="POINT") ? 2 : 1
    grpP2 := ge2.Add("Text","xm y+8 w90 Right","引用对象：")
    ddRefObj := ge2.Add("DropDownList","x+6 w260")
    grpP3 := ge2.Add("Text","xm y+8 w90 Right","比较：")
    ddOp := ge2.Add("DropDownList","x+6 w140", ["等于","不等于"])
    ddOp.Value := (StrUpper(HasProp(c,"Op")?c.Op:"NEQ")="EQ") ? 1 : 2
    grpP4 := ge2.Add("Text","xm y+8 w90 Right","颜色：")
    edColor := ge2.Add("Edit","x+6 w140", HasProp(c,"Color")?c.Color:"0x000000")
    grpP5 := ge2.Add("Text","x+14 w70 Right","容差：")
    edTol := ge2.Add("Edit","x+6 w90 Number", HasProp(c,"Tol")?c.Tol:16)
    btnAuto := ge2.Add("Button","x+14 w110","取引用颜色")

    ; RuleQuiet
    grpR1 := ge2.Add("Text","xm y+10 w90 Right","规则：")
    ddRule := ge2.Add("DropDownList","x+6 w260")
    grpR2 := ge2.Add("Text","xm y+8 w90 Right","静默(ms)：")
    edQuiet := ge2.Add("Edit","x+6 w140 Number", HasProp(c,"QuietMs")?c.QuietMs:0)

    ; Counter
    grpC1 := ge2.Add("Text","xm y+10 w90 Right","计数技能：")
    ddCSkill := ge2.Add("DropDownList","x+6 w260")
    grpC2 := ge2.Add("Text","xm y+8 w90 Right","比较：")
    ddCCmp := ge2.Add("DropDownList","x+6 w140", [">=","==",">","<=","<"])
    grpC3 := ge2.Add("Text","xm y+8 w90 Right","阈值：")
    edCVal := ge2.Add("Edit","x+6 w140 Number", HasProp(c,"Value")?c.Value:1)
    ddCCmp.Value := (StrUpper(HasProp(c,"Cmp")?c.Cmp:"GE")="GE")?1:(StrUpper(c.Cmp)="EQ")?2:(StrUpper(c.Cmp)="GT")?3:(StrUpper(c.Cmp)="LE")?4:(StrUpper(c.Cmp)="LT")?5:1

    ; Elapsed
    grpE1 := ge2.Add("Text","xm y+10 w90 Right","比较：")
    ddECmp := ge2.Add("DropDownList","x+6 w140", [">=","==",">","<=","<"])
    grpE2 := ge2.Add("Text","xm y+8 w90 Right","用时(ms)：")
    edEMs := ge2.Add("Edit","x+6 w140 Number", HasProp(c,"ElapsedMs")?c.ElapsedMs:0)
    ddECmp.Value := (StrUpper(HasProp(c,"Cmp")?c.Cmp:"GE")="GE")?1:(StrUpper(c.Cmp)="EQ")?2:(StrUpper(c.Cmp)="GT")?3:(StrUpper(c.Cmp)="LE")?4:(StrUpper(c.Cmp)="LT")?5:1

    ; 事件
    ddKind.OnEvent("Change", (*) => ToggleKind())
    ddRefType.OnEvent("Change", (*) => FillRefObj())
    btnAuto.OnEvent("Click", (*) => AutoColor())

    FillRules()
    FillSkills()
    FillRefObj()
    ToggleKind()

    btnOK := ge2.Add("Button","xm y+12 w90","确定")
    btnCA := ge2.Add("Button","x+8 w90","取消")
    btnOK.OnEvent("Click", (*) => SaveCond())
    btnCA.OnEvent("Click", (*) => ge2.Destroy())
    ge2.OnEvent("Close", (*) => ge2.Destroy())
    ge2.Show()

    ToggleKind() {
        kcn := ddKind.Text
        ShowP := (kcn="像素就绪")
        ShowR := (kcn="规则静默")
        ShowC := (kcn="计数")
        ShowE := (kcn="阶段用时")
        for ctl in [grpP1,ddRefType,grpP2,ddRefObj,grpP3,ddOp,grpP4,edColor,grpP5,edTol,btnAuto] {
            ctl.Visible := ShowP
        }
        for ctl in [grpR1,ddRule,grpR2,edQuiet] {
            ctl.Visible := ShowR
        }
        for ctl in [grpC1,ddCSkill,grpC2,ddCCmp,grpC3,edCVal] {
            ctl.Visible := ShowC
        }
        for ctl in [grpE1,ddECmp,grpE2,edEMs] {
            ctl.Visible := ShowE
        }
        if ShowP {
            FillRefObj()
        }
    }
    FillRefObj() {
        ddRefObj.Delete()
        if (ddRefType.Value=2) {
            cnt := 0
            try {
                cnt := App["ProfileData"].Points.Length
            }
            if (cnt > 0) {
                names := []
                for _, p in App["ProfileData"].Points {
                    names.Push(p.Name)
                }
                ddRefObj.Add(names)
                defIdx := HasProp(c,"RefIndex") ? c.RefIndex : 1
                ddRefObj.Value := REUI_IndexClamp(defIdx, names.Length)
                ddRefObj.Enabled := true
            } else {
                ddRefObj.Add(["（无点位）"])
                ddRefObj.Value := 1
                ddRefObj.Enabled := false
            }
        } else {
            cnt := 0
            try {
                cnt := App["ProfileData"].Skills.Length
            }
            if (cnt > 0) {
                names := []
                for _, s in App["ProfileData"].Skills {
                    names.Push(s.Name)
                }
                ddRefObj.Add(names)
                defIdx := HasProp(c,"RefIndex") ? c.RefIndex : 1
                ddRefObj.Value := REUI_IndexClamp(defIdx, names.Length)
                ddRefObj.Enabled := true
            } else {
                ddRefObj.Add(["（无技能）"])
                ddRefObj.Value := 1
                ddRefObj.Enabled := false
            }
        }
    }
    FillRules() {
        ddRule.Delete()
        cnt := 0
        try {
            cnt := App["ProfileData"].Rules.Length
        }
        if (cnt > 0) {
            names := []
            for i, r in App["ProfileData"].Rules {
                names.Push(i " - " r.Name)
            }
            ddRule.Add(names)
            defIdx := HasProp(c,"RuleId") ? c.RuleId : 1
            ddRule.Value := REUI_IndexClamp(defIdx, names.Length)
            ddRule.Enabled := true
        } else {
            ddRule.Add(["（无规则）"])
            ddRule.Value := 1
            ddRule.Enabled := false
        }
    }
    FillSkills() {
        ddCSkill.Delete()
        cnt := 0
        try {
            cnt := App["ProfileData"].Skills.Length
        }
        if (cnt > 0) {
            names := []
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
            ddCSkill.Add(names)
            defIdx := HasProp(c,"RefIndex") ? c.RefIndex : 1
            ddCSkill.Value := REUI_IndexClamp(defIdx, names.Length)
            ddCSkill.Enabled := true
        } else {
            ddCSkill.Add(["（无技能）"])
            ddCSkill.Value := 1
            ddCSkill.Enabled := false
        }
    }
    AutoColor() {
        if (ddRefType.Value=2) {
            idxP := ddRefObj.Value
            if (idxP>=1 && idxP<=App["ProfileData"].Points.Length) {
                p := App["ProfileData"].Points[idxP]
                edColor.Value := p.Color
                edTol.Value := p.Tol
            }
        } else {
            idxS := ddRefObj.Value
            if (idxS>=1 && idxS<=App["ProfileData"].Skills.Length) {
                s := App["ProfileData"].Skills[idxS]
                edColor.Value := s.Color
                edTol.Value := s.Tol
            }
        }
    }
    SaveCond() {
        kcn := ddKind.Text
        kindKey := (kcn="像素就绪") ? "PixelReady" : (kcn="规则静默") ? "RuleQuiet" : (kcn="计数") ? "Counter" : "Elapsed"

        if (kindKey="PixelReady") {
            if (!ddRefObj.Enabled) {
                MsgBox ((ddRefType.Value=2) ? "当前没有可引用的取色点位。" : "当前没有可引用的技能。")
                return
            }
            refType := (ddRefType.Value=2) ? "Point" : "Skill"
            refIdx := ddRefObj.Value
            opKey := (ddOp.Value=1) ? "EQ" : "NEQ"
            col := Trim(edColor.Value)
            tol := (edTol.Value!="") ? Integer(edTol.Value) : 16
            nc := { Kind:kindKey, RefType:refType, RefIndex:refIdx, Op:opKey, Color:(col!=""?col:"0x000000"), Tol:tol }
            if onSaved {
                onSaved(nc, idx)
            }
            ge2.Destroy()
            return
        }
        if (kindKey="RuleQuiet") {
            if (!ddRule.Enabled) {
                MsgBox "当前没有可引用的规则。"
                return
            }
            rid := ddRule.Value ? ddRule.Value : 1
            qms := (edQuiet.Value!="") ? Integer(edQuiet.Value) : 0
            nc := { Kind:kindKey, RuleId: rid, QuietMs: qms }
            if onSaved {
                onSaved(nc, idx)
            }
            ge2.Destroy()
            return
        }
        if (kindKey="Counter") {
            if (!ddCSkill.Enabled) {
                MsgBox "当前没有可引用的技能。"
                return
            }
            si := ddCSkill.Value ? ddCSkill.Value : 1
            cmpTxt := ddCCmp.Text
            cmpKey := (cmpTxt=">=")?"GE":(cmpTxt="==")?"EQ":(cmpTxt=">")?"GT":(cmpTxt="<=")?"LE":"LT"
            v := (edCVal.Value!="") ? Integer(edCVal.Value) : 1
            nc := { Kind:kindKey, RefIndex: si, Cmp: cmpKey, Value: v }
            if onSaved {
                onSaved(nc, idx)
            }
            ge2.Destroy()
            return
        }
        ; Elapsed
        cmpTxt := ddECmp.Text
        cmpKey := (cmpTxt=">=")?"GE":(cmpTxt="==")?"EQ":(cmpTxt=">")?"GT":(cmpTxt="<=")?"LE":"LT"
        ms := (edEMs.Value!="") ? Integer(edEMs.Value) : 0
        nc := { Kind:kindKey, Cmp: cmpKey, ElapsedMs: ms }
        if onSaved {
            onSaved(nc, idx)
        }
        ge2.Destroy()
    }
}