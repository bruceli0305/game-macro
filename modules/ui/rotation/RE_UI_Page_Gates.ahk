; modules\ui\rotation\RE_UI_Page_Gates.ahk
#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

; 构建“跳轨”页（完整：列表 + Gate 编辑器 + 条件编辑器），无逗号链、无单行多语句
REUI_Page_Gates_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(3)
    REUI_Gates_Ensure(&cfg)

    lv := dlg.Add("ListView", "xm y+8 w820 r12 +Grid", ["优先级","目标轨","逻辑","条件数"])
    btnAdd  := dlg.Add("Button", "xm y+8 w90", "新增")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnDel  := dlg.Add("Button", "x+8 w90", "删除")
    btnUp   := dlg.Add("Button", "x+8 w90", "上移")
    btnDn   := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w110", "保存跳轨")

    REUI_Gates_FillList(lv, cfg)

    btnAdd.OnEvent("Click", (*) => REUI_Gates_OnAdd(cfg, dlg, lv))
    btnEdit.OnEvent("Click", (*) => REUI_Gates_OnEdit(lv, cfg, dlg))
    btnDel.OnEvent("Click", (*) => REUI_Gates_OnDel(lv, cfg, dlg))
    btnUp.OnEvent("Click", (*) => REUI_Gates_OnMove(lv, cfg, -1))
    btnDn.OnEvent("Click", (*) => REUI_Gates_OnMove(lv, cfg, 1))
    lv.OnEvent("DoubleClick", (*) => REUI_Gates_OnEdit(lv, cfg, dlg))
    btnSave.OnEvent("Click", SaveGates)

    SaveGates(*) {
        Storage_SaveProfile(App["ProfileData"])
        Notify("跳轨已保存")
    }

    return { Save: () => 0 }
}

;------------------------------ 列表/数据 ------------------------------
; 替换整个函数：REUI_Gates_Ensure(&cfg)
REUI_Gates_Ensure(&cfg) {
    if (!HasProp(cfg, "Gates") || !IsObject(cfg.Gates)) {
        cfg.Gates := []
    }
    if (cfg.Gates.Length = 0) {
        cfg.Gates.Push({ Priority: 1, TargetTrackId: 0, Logic: "AND", Conds: [] })
    }
    for i, g in cfg.Gates {
        if (!HasProp(g, "Priority")) {
            g.Priority := i
        }
        if (!HasProp(g, "TargetTrackId")) {
            g.TargetTrackId := 0
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
    lv.Opt("-Redraw")
    lv.Delete()
    if HasProp(cfg,"Gates") && IsObject(cfg.Gates) {
        for _, g in cfg.Gates {
            pri := HasProp(g,"Priority") ? g.Priority : 0
            tgt := HasProp(g,"TargetTrackId") ? g.TargetTrackId : 0
            lgc := HasProp(g,"Logic") ? g.Logic : "AND"
            cnt := (HasProp(g,"Conds") && IsObject(g.Conds)) ? g.Conds.Length : 0
            lv.Add("", pri, tgt, lgc, cnt)
        }
    }
    Loop 4 {
        lv.ModifyCol(A_Index, "AutoHdr")
    }
    lv.Opt("+Redraw")
}
REUI_Gates_Renum(cfg) {
    if HasProp(cfg,"Gates") && IsObject(cfg.Gates) {
        for i, g in cfg.Gates
            g.Priority := i
    }
}
REUI_Gates_OnAdd(cfg, owner, lv) {
    g := { Priority: (HasProp(cfg,"Gates")?cfg.Gates.Length:0)+1, TargetTrackId: 0, Logic:"AND", Conds:[] }
    REUI_GateEditor_Open(owner, cfg, g, 0, OnSaved)
    OnSaved(ng, idx) {
        cfg.Gates.Push(ng)
        REUI_Gates_Renum(cfg)
        REUI_Gates_FillList(lv, cfg)
    }
}
REUI_Gates_OnEdit(lv, cfg, owner) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一个跳轨规则"
        return
    }
    if (row < 1 || row > cfg.Gates.Length)
        return
    cur := cfg.Gates[row]
    REUI_GateEditor_Open(owner, cfg, cur, row, OnSaved)
    OnSaved(ng, i) {
        cfg.Gates[i] := ng
        REUI_Gates_Renum(cfg)
        REUI_Gates_FillList(lv, cfg)
    }
}
REUI_Gates_OnDel(lv, cfg, owner) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一个跳轨规则"
        return
    }
    cfg.Gates.RemoveAt(row)
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    Notify("已删除跳轨规则")
}
REUI_Gates_OnMove(lv, cfg, dir) {
    row := lv.GetNext(0, "Focused")
    if !row
        return
    from := row
    to := from + dir
    if (to < 1 || to > cfg.Gates.Length)
        return
    item := cfg.Gates[from]
    cfg.Gates.RemoveAt(from)
    cfg.Gates.InsertAt(to, item)
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    lv.Modify(to, "Select Focus Vis")
}

;------------------------------ Gate 编辑器 ------------------------------
REUI_GateEditor_Open(owner, cfg, g, idx := 0, onSaved := 0) {
    global UI
    isNew := (idx = 0)

    ; 规范化 g
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
    if (!HasProp(g, "TargetTrackId")) {
        g.TargetTrackId := 0
    }
    if (!HasProp(g, "Logic")) {
        g.Logic := "AND"
    }
    if (!HasProp(g, "Conds") || !IsObject(g.Conds)) {
        g.Conds := []
    }

    ; Owner 处理（避免把对象错当字符串）
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

    ge.Add("Text", "w80 Right", "优先级：")
    edPri := ge.Add("Edit", "x+6 w120 Number", g.Priority)

    ge.Add("Text", "xm y+8 w100 Right", "目标轨：")
    ddTarget := ge.Add("DropDownList", "x+6 w160")
    trackIds := REUI_ListTrackIds(cfg)
    arrTargets := ["0"]
    for _, id in trackIds {
        arrTargets.Push(Format("{:}", id))
    }
    if (arrTargets.Length) {
        ddTarget.Add(arrTargets)
    }
    allTargets := arrTargets
    sel := 1
    for i, v in allTargets {
        if (Integer(v) = Integer(g.TargetTrackId)) {
            sel := i
            break
        }
    }
    ddTarget.Value := sel

    ge.Add("Text", "xm y+8 w70 Right", "逻辑：")
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

        tidx := ddTarget.Value
        if (tidx >= 1 && tidx <= allTargets.Length) {
            g.TargetTrackId := Integer(allTargets[tidx])
        } else {
            g.TargetTrackId := 0
        }

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
    nc := {}
    REUI_CondEditor_Open(owner, cfg, nc, 0, OnSaved)
    OnSaved(saved, i) {
        g.Conds.Push(saved)
        REUI_GateEditor_FillConds(lv, g)
    }
}
REUI_CondEditor_OnEdit(lv, owner, cfg, g) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一个条件"
        return
    }
    cur := g.Conds[row]
    REUI_CondEditor_Open(owner, cfg, cur, row, OnSaved)
    OnSaved(saved, i) {
        g.Conds[i] := saved
        REUI_GateEditor_FillConds(lv, g)
    }
}
REUI_CondEditor_OnDel(lv, g) {
    row := lv.GetNext(0, "Focused")
    if !row
        return
    g.Conds.RemoveAt(row)
    lv.Delete(row)
}

REUI_CondEditor_Open(owner, cfg, c, idx := 0, onSaved := 0) {
    if !IsObject(c)
        c := {}
    if !HasProp(c,"Kind")
        c.Kind := "PixelReady"

    ge2 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增条件" : "编辑条件")
    ge2.MarginX := 12, ge2.MarginY := 10
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
        for ctl in [grpP1,ddRefType,grpP2,ddRefObj,grpP3,ddOp,grpP4,edColor,grpP5,edTol,btnAuto]
            ctl.Visible := ShowP
        for ctl in [grpR1,ddRule,grpR2,edQuiet]
            ctl.Visible := ShowR
        for ctl in [grpC1,ddCSkill,grpC2,ddCCmp,grpC3,edCVal]
            ctl.Visible := ShowC
        for ctl in [grpE1,ddECmp,grpE2,edEMs]
            ctl.Visible := ShowE
        if ShowP
            FillRefObj()
    }
    FillRefObj() {
        ddRefObj.Delete()
        if (ddRefType.Value=2) { ; 点位
            cnt := 0
            try cnt := App["ProfileData"].Points.Length
            if (cnt > 0) {
                names := []
                for _, p in App["ProfileData"].Points
                    names.Push(p.Name)
                ddRefObj.Add(names)
                defIdx := HasProp(c,"RefIndex") ? c.RefIndex : 1
                ddRefObj.Value := REUI_IndexClamp(defIdx, names.Length)
                ddRefObj.Enabled := true
            } else {
                ddRefObj.Add(["（无点位）"])
                ddRefObj.Value := 1
                ddRefObj.Enabled := false
            }
        } else { ; 技能
            cnt := 0
            try cnt := App["ProfileData"].Skills.Length
            if (cnt > 0) {
                names := []
                for _, s in App["ProfileData"].Skills
                    names.Push(s.Name)
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
        try cnt := App["ProfileData"].Rules.Length
        if (cnt > 0) {
            names := []
            for i, r in App["ProfileData"].Rules
                names.Push(i " - " r.Name)
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
        try cnt := App["ProfileData"].Skills.Length
        if (cnt > 0) {
            names := []
            for _, s in App["ProfileData"].Skills
                names.Push(s.Name)
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
            if onSaved
                onSaved(nc, idx)
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
            if onSaved
                onSaved(nc, idx)
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
            if onSaved
                onSaved(nc, idx)
            ge2.Destroy()
            return
        }
        ; Elapsed
        cmpTxt := ddECmp.Text
        cmpKey := (cmpTxt=">=")?"GE":(cmpTxt="==")?"EQ":(cmpTxt=">")?"GT":(cmpTxt="<=")?"LE":"LT"
        ms := (edEMs.Value!="") ? Integer(edEMs.Value) : 0
        nc := { Kind:kindKey, Cmp: cmpKey, ElapsedMs: ms }
        if onSaved
            onSaved(nc, idx)
        ge2.Destroy()
    }
}