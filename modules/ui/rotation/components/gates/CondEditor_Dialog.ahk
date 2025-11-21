#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_GateCond_Summary(c) {
    kind := HasProp(c, "Kind") ? StrUpper(c.Kind) : "?"
    if (kind = "PIXELREADY") {
        rt := HasProp(c, "RefType") ? c.RefType : "Skill"
        ri := HasProp(c, "RefIndex") ? c.RefIndex : 0
        op := (StrUpper(HasProp(c, "Op") ? c.Op : "NEQ") = "EQ") ? "等于" : "不等于"
        return "像素就绪 " rt "#" ri " " op
    } else if (kind = "RULEQUIET") {
        rid := HasProp(c, "RuleId") ? c.RuleId : 0
        q := HasProp(c, "QuietMs") ? c.QuietMs : 0
        return "规则静默 规则#" rid " ≥" q "ms"
    } else if (kind = "COUNTER") {
        si := HasProp(c, "RefIndex") ? c.RefIndex : 0
        cmp := HasProp(c, "Cmp") ? c.Cmp : "GE"
        txt := (cmp = "GE") ? ">=" : (cmp = "EQ") ? "==" : (cmp = "GT") ? ">" : (cmp = "LE") ? "<=" : "<"
        v := HasProp(c, "Value") ? c.Value : 1
        return "计数 技能#" si " " txt " " v
    } else if (kind = "ELAPSED") {
        cmp := HasProp(c, "Cmp") ? c.Cmp : "GE"
        txt := (cmp = "GE") ? ">=" : (cmp = "EQ") ? "==" : (cmp = "GT") ? ">" : (cmp = "LE") ? "<=" : "<"
        ms := HasProp(c, "ElapsedMs") ? c.ElapsedMs : 0
        return "阶段用时 " txt " " ms "ms"
    }
    return "?"
}

REUI_CondEditor_OnAdd(lv, owner, cfg, g) {
    OnSaved(saved, i) {
        try {
            g.Conds.Push(saved)
            REUI_GateEditor_FillConds(lv, g)
        } catch {
        }
    }
    nc := {}
    REUI_CondEditor_Open(owner, cfg, nc, 0, OnSaved)
}

REUI_CondEditor_OnEdit(lv, owner, cfg, g) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一个条件"
        return
    }
    cur := g.Conds[row]
    OnSaved(saved, i) {
        try {
            g.Conds[i] := saved
            REUI_GateEditor_FillConds(lv, g)
        } catch {
        }
    }
    REUI_CondEditor_Open(owner, cfg, cur, row, OnSaved)
}

REUI_CondEditor_OnDel(lv, g) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        g.Conds.RemoveAt(row)
    } catch {
    }
    try {
        lv.Delete(row)
    } catch {
    }
}

REUI_CondEditor_Open(owner, cfg, c, idx := 0, onSaved := 0) {
    if !IsObject(c) {
        c := {}
    }
    if !HasProp(c, "Kind") {
        c.Kind := "PixelReady"
    }
    ge2 := Gui("+Owner" owner.Hwnd, (idx = 0) ? "新增条件" : "编辑条件")
    ge2.MarginX := 12
    ge2.MarginY := 10
    ge2.SetFont("s10", "Segoe UI")

    ge2.Add("Text", "w90 Right", "类型：")
    ddKind := ge2.Add("DropDownList", "x+6 w180", ["像素就绪", "规则静默", "计数", "阶段用时"])
    k := StrUpper(c.Kind)
    ddKind.Value := (k = "PIXELREADY") ? 1 : (k = "RULEQUIET") ? 2 : (k = "COUNTER") ? 3 : 4

    grpP1 := ge2.Add("Text", "xm y+10 w90 Right", "引用类型：")
    ddRefType := ge2.Add("DropDownList", "x+6 w140", ["技能", "点位"])
    ddRefType.Value := (StrUpper(HasProp(c, "RefType") ? c.RefType : "Skill") = "POINT") ? 2 : 1
    grpP2 := ge2.Add("Text", "xm y+8 w90 Right", "引用对象：")
    ddRefObj := ge2.Add("DropDownList", "x+6 w260")
    grpP3 := ge2.Add("Text", "xm y+8 w90 Right", "比较：")
    ddOp := ge2.Add("DropDownList", "x+6 w140", ["等于", "不等于"])
    ddOp.Value := (StrUpper(HasProp(c, "Op") ? c.Op : "NEQ") = "EQ") ? 1 : 2
    grpP4 := ge2.Add("Text", "xm y+8 w90 Right", "颜色：")
    edColor := ge2.Add("Edit", "x+6 w140", HasProp(c, "Color") ? c.Color : "0x000000")
    grpP5 := ge2.Add("Text", "x+14 w70 Right", "容差：")
    edTol := ge2.Add("Edit", "x+6 w90 Number", HasProp(c, "Tol") ? c.Tol : 16)
    btnAuto := ge2.Add("Button", "x+14 w110", "取引用颜色")

    grpR1 := ge2.Add("Text", "xm y+10 w90 Right", "规则：")
    ddRule := ge2.Add("DropDownList", "x+6 w260")
    grpR2 := ge2.Add("Text", "xm y+8 w90 Right", "静默(ms)：")
    edQuiet := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "QuietMs") ? c.QuietMs : 0)

    grpC1 := ge2.Add("Text", "xm y+10 w90 Right", "计数技能：")
    ddCSkill := ge2.Add("DropDownList", "x+6 w260")
    grpC2 := ge2.Add("Text", "xm y+8 w90 Right", "比较：")
    ddCCmp := ge2.Add("DropDownList", "x+6 w140", [">=", "==", ">", "<=", "<"])
    grpC3 := ge2.Add("Text", "xm y+8 w90 Right", "阈值：")
    edCVal := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "Value") ? c.Value : 1)

    grpE1 := ge2.Add("Text", "xm y+10 w90 Right", "比较：")
    ddECmp := ge2.Add("DropDownList", "x+6 w140", [">=", "==", ">", "<=", "<"])
    grpE2 := ge2.Add("Text", "xm y+8 w90 Right", "用时(ms)：")
    edEMs := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "ElapsedMs") ? c.ElapsedMs : 0)

    ddKind.OnEvent("Change", (*) => ToggleKind())
    ddRefType.OnEvent("Change", (*) => FillRefObj())
    btnAuto.OnEvent("Click", (*) => AutoColor())

    FillRules()
    FillSkills()
    FillRefObj()
    ToggleKind()

    btnOK := ge2.Add("Button", "xm y+12 w90", "确定")
    btnCA := ge2.Add("Button", "x+8 w90", "取消")
    btnOK.OnEvent("Click", (*) => SaveCond())
    btnCA.OnEvent("Click", (*) => ge2.Destroy())
    ge2.OnEvent("Close", (*) => ge2.Destroy())
    ge2.Show()

    ToggleKind() {
        kcn := ddKind.Text
        ShowP := (kcn = "像素就绪")
        ShowR := (kcn = "规则静默")
        ShowC := (kcn = "计数")
        ShowE := (kcn = "阶段用时")
        for ctl in [grpP1, ddRefType, grpP2, ddRefObj, grpP3, ddOp, grpP4, edColor, grpP5, edTol, btnAuto] {
            ctl.Visible := ShowP
        }
        for ctl in [grpR1, ddRule, grpR2, edQuiet] {
            ctl.Visible := ShowR
        }
        for ctl in [grpC1, ddCSkill, grpC2, ddCCmp, grpC3, edCVal] {
            ctl.Visible := ShowC
        }
        for ctl in [grpE1, ddECmp, grpE2, edEMs] {
            ctl.Visible := ShowE
        }
        if ShowP {
            FillRefObj()
        }
    }

    FillRefObj() {
        ddRefObj.Delete()
        if (ddRefType.Value = 2) {
            cnt := 0
            try {
                cnt := App["ProfileData"].Points.Length
            } catch {
                cnt := 0
            }
            if (cnt > 0) {
                names := []
                for _, p in App["ProfileData"].Points {
                    names.Push(p.Name)
                }
                ddRefObj.Add(names)
                defIdx := 1
                try {
                    defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                } catch {
                    defIdx := 1
                }
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
            } catch {
                cnt := 0
            }
            if (cnt > 0) {
                names := []
                for _, s in App["ProfileData"].Skills {
                    names.Push(s.Name)
                }
                ddRefObj.Add(names)
                defIdx := 1
                try {
                    defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                } catch {
                    defIdx := 1
                }
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
        } catch {
            cnt := 0
        }
        if (cnt > 0) {
            names := []
            for i, r in App["ProfileData"].Rules {
                names.Push(i " - " r.Name)
            }
            ddRule.Add(names)
            defIdx := 1
            try {
                defIdx := HasProp(c, "RuleId") ? c.RuleId : 1
            } catch {
                defIdx := 1
            }
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
        } catch {
            cnt := 0
        }
        if (cnt > 0) {
            names := []
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
            ddCSkill.Add(names)
            defIdx := 1
            try {
                defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
            } catch {
                defIdx := 1
            }
            ddCSkill.Value := REUI_IndexClamp(defIdx, names.Length)
            ddCSkill.Enabled := true
        } else {
            ddCSkill.Add(["（无技能）"])
            ddCSkill.Value := 1
            ddCSkill.Enabled := false
        }
    }

    AutoColor() {
        if (ddRefType.Value = 2) {
            idxP := ddRefObj.Value
            try {
                if (idxP >= 1 && idxP <= App["ProfileData"].Points.Length) {
                    p := App["ProfileData"].Points[idxP]
                    edColor.Value := p.Color
                    edTol.Value := p.Tol
                }
            } catch {
            }
        } else {
            idxS := ddRefObj.Value
            try {
                if (idxS >= 1 && idxS <= App["ProfileData"].Skills.Length) {
                    s := App["ProfileData"].Skills[idxS]
                    edColor.Value := s.Color
                    edTol.Value := s.Tol
                }
            } catch {
            }
        }
    }

    SaveCond() {
        kcn := ddKind.Text
        kindKey := "PixelReady"
        if (kcn = "规则静默") {
            kindKey := "RuleQuiet"
        } else if (kcn = "计数") {
            kindKey := "Counter"
        } else if (kcn = "阶段用时") {
            kindKey := "Elapsed"
        } else {
            kindKey := "PixelReady"
        }

        if (kindKey = "PixelReady") {
            if (!ddRefObj.Enabled) {
                MsgBox ((ddRefType.Value = 2) ? "当前没有可引用的取色点位。" : "当前没有可引用的技能。")
                return
            }
            refType := (ddRefType.Value = 2) ? "Point" : "Skill"
            refIdx := ddRefObj.Value
            opKey := (ddOp.Value = 1) ? "EQ" : "NEQ"
            col := Trim(edColor.Value)
            tol := 16
            try {
                tol := (edTol.Value != "") ? Integer(edTol.Value) : 16
            } catch {
                tol := 16
            }
            nc := { Kind: kindKey, RefType: refType, RefIndex: refIdx, Op: opKey, Color: (col != "" ? col : "0x000000"),
                Tol: tol }
            if onSaved {
                try {
                    onSaved(nc, idx)
                } catch {
                }
            }
            try {
                ge2.Destroy()
            } catch {
            }
            return
        }

        if (kindKey = "RuleQuiet") {
            if (!ddRule.Enabled) {
                MsgBox "当前没有可引用的规则。"
                return
            }
            rid := 1
            try {
                rid := ddRule.Value ? ddRule.Value : 1
            } catch {
                rid := 1
            }
            qms := 0
            try {
                qms := (edQuiet.Value != "") ? Integer(edQuiet.Value) : 0
            } catch {
                qms := 0
            }
            nc := { Kind: kindKey, RuleId: rid, QuietMs: qms }
            if onSaved {
                try {
                    onSaved(nc, idx)
                } catch {
                }
            }
            try {
                ge2.Destroy()
            } catch {
            }
            return
        }

        if (kindKey = "Counter") {
            if (!ddCSkill.Enabled) {
                MsgBox "当前没有可引用的技能。"
                return
            }
            si := 1
            try {
                si := ddCSkill.Value ? ddCSkill.Value : 1
            } catch {
                si := 1
            }
            cmpTxt := ddCCmp.Text
            cmpKey := "GE"
            if (cmpTxt = ">=") {
                cmpKey := "GE"
            } else if (cmpTxt = "==") {
                cmpKey := "EQ"
            } else if (cmpTxt = ">") {
                cmpKey := "GT"
            } else if (cmpTxt = "<=") {
                cmpKey := "LE"
            } else {
                cmpKey := "LT"
            }
            v := 1
            try {
                v := (edCVal.Value != "") ? Integer(edCVal.Value) : 1
            } catch {
                v := 1
            }
            nc := { Kind: kindKey, RefIndex: si, Cmp: cmpKey, Value: v }
            if onSaved {
                try {
                    onSaved(nc, idx)
                } catch {
                }
            }
            try {
                ge2.Destroy()
            } catch {
            }
            return
        }

        cmpTxt2 := ddECmp.Text
        cmpKey2 := "GE"
        if (cmpTxt2 = ">=") {
            cmpKey2 := "GE"
        } else if (cmpTxt2 = "==") {
            cmpKey2 := "EQ"
        } else if (cmpTxt2 = ">") {
            cmpKey2 := "GT"
        } else if (cmpTxt2 = "<=") {
            cmpKey2 := "LE"
        } else {
            cmpKey2 := "LT"
        }
        ms := 0
        try {
            ms := (edEMs.Value != "") ? Integer(edEMs.Value) : 0
        } catch {
            ms := 0
        }
        nc := { Kind: kindKey, Cmp: cmpKey2, ElapsedMs: ms }
        if onSaved {
            try {
                onSaved(nc, idx)
            } catch {
            }
        }
        try {
            ge2.Destroy()
        } catch {
        }
    }
}
