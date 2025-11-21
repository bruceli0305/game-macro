#Requires AutoHotkey v2
; CondEditor_Dialog.ahk
; 条件编辑器（Pixel / Counter）
; 导出：CondEditor_Open(cond, idx := 0, onSaved := 0)

#Include "Rules_UI_Common.ahk"

CondEditor_Open(cond, idx := 0, onSaved := 0) {
    global App
    if !IsObject(cond) {
        cond := {}
    }
    if !HasProp(cond, "Kind") {
        cond.Kind := "Pixel"
    }

    isCounter := (StrUpper(cond.Kind) = "COUNTER")

    dlg := Gui("+Owner" UI.Main.Hwnd, "编辑条件")
    dlg.MarginX := 12
    dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    ; 条件类型
    dlg.Add("Text", "w90 Right", "条件类型：")
    ddKind := dlg.Add("DropDownList", "x+6 w160", ["像素(Pixel)", "计数(Counter)"])
    try ddKind.Value := (isCounter ? 2 : 1)

    ; ---------- Pixel 区 ----------
    txtType := dlg.Add("Text", "xm y+10 w90 Right", "引用类型：")
    ddType := dlg.Add("DropDownList", "x+6 w160", ["Skill", "Point"])
    try ddType.Value := (StrUpper(OM_Get(cond, "RefType", "Skill")) = "POINT") ? 2 : 1

    txtObj := dlg.Add("Text", "xm w90 Right", "引用对象：")
    ddObj := dlg.Add("DropDownList", "x+6 w200")

    txtOp := dlg.Add("Text", "xm w90 Right", "操作：")
    ddOp := dlg.Add("DropDownList", "x+6 w160", ["等于", "不等于"])
    try ddOp.Value := (StrUpper(OM_Get(cond, "Op", "EQ")) = "NEQ") ? 2 : 1

    txtInfo := dlg.Add("Text", "xm y+10 w90 Right", "对象详情：")
    labX := dlg.Add("Text", "xm w48 Right", "X:")
    edRefX := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labY := dlg.Add("Text", "x+18 w48 Right", "Y:")
    edRefY := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labC := dlg.Add("Text", "x+18 w48 Right", "颜色:")
    edRefCol := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labT := dlg.Add("Text", "x+18 w48 Right", "容差:")
    edRefTol := dlg.Add("Edit", "x+6 w100 ReadOnly Center")

    grpPixel := [txtType, ddType, txtObj, ddObj, txtOp, ddOp, txtInfo, labX, edRefX, labY, edRefY, labC, edRefCol, labT, edRefTol]

    ; ---------- Counter 区 ----------
    txtCntSkill := dlg.Add("Text", "xm y+10 w90 Right", "计数技能：")
    ddCntSkill := dlg.Add("DropDownList", "x+6 w240")
    cntSk := RE_Rules_FillSkills(ddCntSkill)
    defSi := RE_Rules_ClampIndex(OM_Get(cond, "SkillIndex", 1), Max(cntSk, 1))
    try ddCntSkill.Value := (defSi > 0 ? defSi : 1)

    txtCmp := dlg.Add("Text", "xm w90 Right", "比较：")
    ddCmp := dlg.Add("DropDownList", "x+6 w120", [">=", "==", ">", "<=", "<"])
    try {
        defK := StrUpper(OM_Get(cond, "Cmp", "GE"))
        ddCmp.Value := (defK = "GE") ? 1 : (defK = "EQ") ? 2 : (defK = "GT") ? 3 : (defK = "LE") ? 4 : 5
    }

    txtVal := dlg.Add("Text", "xm w90 Right", "阈值：")
    edVal := dlg.Add("Edit", "x+6 w120 Number", OM_Get(cond, "Value", 1))

    cbReset := dlg.Add("CheckBox", "xm y+8", "触发后清零")
    try cbReset.Value := OM_Get(cond, "ResetOnTrigger", 0) ? 1 : 0

    grpCounter := [txtCntSkill, ddCntSkill, txtCmp, ddCmp, txtVal, edVal, cbReset]

    ; 底部按钮
    btnSave := dlg.Add("Button", "xm y+12 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    ; 事件
    ddKind.OnEvent("Change", ToggleKind)
    ddType.OnEvent("Change", (*) => (FillObj(), UpdateInfo()))
    ddObj.OnEvent("Change", (*) => UpdateInfo())
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    ; 初始化
    FillObj()
    UpdateInfo()
    ToggleKind(0)
    PlaceButtons()

    dlg.Show()

    ToggleKind(*) {
        isC := (ddKind.Value = 2)
        for _, ctl in grpPixel {
            try ctl.Visible := !isC
        }
        for _, ctl in grpCounter {
            try ctl.Visible := isC
        }
        PlaceButtons()
    }

    PlaceButtons() {
        isC := (ddKind.Value = 2)
        minX := 0, minY := 0, maxX := 0, maxY := 0
        if (isC) {
            Group_GetBounds(grpCounter, &minX, &minY, &maxX, &maxY)
        } else {
            Group_GetBounds(grpPixel, &minX, &minY, &maxX, &maxY)
        }
        btnY := maxY + 12
        try btnSave.Move(, btnY)
        try btnCancel.Move(, btnY)
        try dlg.Show("AutoSize")
    }

    FillObj() {
        try ddObj.Delete()
        if (ddType.Value = 2) {
            cnt := RE_Rules_FillPoints(ddObj)
            defIdx := RE_Rules_ClampIndex(OM_Get(cond, "RefIndex", 1), Max(cnt, 1))
            try ddObj.Value := (defIdx > 0 ? defIdx : 1)
        } else {
            cnt := RE_Rules_FillSkills(ddObj)
            defIdx := RE_Rules_ClampIndex(OM_Get(cond, "RefIndex", 1), Max(cnt, 1))
            try ddObj.Value := (defIdx > 0 ? defIdx : 1)
        }
    }

    UpdateInfo() {
        if (ddType.Value = 2) {
            idxSel := ddObj.Value
            try {
                if (idxSel >= 1 && idxSel <= App["ProfileData"].Points.Length) {
                    p := App["ProfileData"].Points[idxSel]
                    edRefX.Value := p.X
                    edRefY.Value := p.Y
                    edRefCol.Value := Pixel_ColorToHex(Pixel_HexToInt(p.Color))
                    edRefTol.Value := p.Tol
                } else {
                    edRefX.Value := 0
                    edRefY.Value := 0
                    edRefCol.Value := "0x000000"
                    edRefTol.Value := 10
                }
            }
        } else {
            idxSel := ddObj.Value
            try {
                if (idxSel >= 1 && idxSel <= App["ProfileData"].Skills.Length) {
                    s := App["ProfileData"].Skills[idxSel]
                    edRefX.Value := s.X
                    edRefY.Value := s.Y
                    edRefCol.Value := Pixel_ColorToHex(Pixel_HexToInt(s.Color))
                    edRefTol.Value := s.Tol
                } else {
                    edRefX.Value := 0
                    edRefY.Value := 0
                    edRefCol.Value := "0x000000"
                    edRefTol.Value := 10
                }
            }
        }
    }

    OnSave(*) {
        if (ddKind.Value = 2) {
            ; Counter
            if (!(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills") && App["ProfileData"].Skills.Length > 0)) {
                MsgBox "没有可引用的技能"
                return
            }
            si := 1
            try si := (ddCntSkill.Value ? ddCntSkill.Value : 1)
            cmpText := ""
            try cmpText := ddCmp.Text
            cmpKey := RE_Cmp_TextToKey(cmpText)
            val := 1
            try val := (edVal.Value != "") ? Integer(edVal.Value) : 1
            rst := 0
            try rst := cbReset.Value ? 1 : 0

            newC := { Kind: "Counter", SkillIndex: si, Cmp: cmpKey, Value: val, ResetOnTrigger: rst }
            if onSaved {
                try onSaved(newC, idx)
            }
            try dlg.Destroy()
            Notify("已保存计数条件")
            return
        }

        ; Pixel
        refType := (ddType.Value = 2) ? "Point" : "Skill"
        if (refType = "Point") {
            if (!(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points") && App["ProfileData"].Points.Length > 0)) {
                MsgBox "没有可引用的取色点位"
                return
            }
        } else {
            if (!(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills") && App["ProfileData"].Skills.Length > 0)) {
                MsgBox "没有可引用的技能"
                return
            }
        }
        refIdx := 1
        try refIdx := (ddObj.Value ? ddObj.Value : 1)
        op := "EQ"
        try op := (ddOp.Value = 2) ? "NEQ" : "EQ"
        x := 0
        y := 0
        try x := Integer(edRefX.Value)
        try y := Integer(edRefY.Value)

        newC := { Kind: "Pixel", RefType: refType, RefIndex: refIdx, Op: op, UseRefXY: 1, X: x, Y: y }
        if onSaved {
            try onSaved(newC, idx)
        }
        try dlg.Destroy()
        Notify("已保存条件")
    }

    Group_GetBounds(grp, &minX, &minY, &maxX, &maxY) {
        first := true
        for ctl in grp {
            ctl.GetPos(&x, &y, &w, &h)
            if (first) {
                minX := x
                minY := y
                maxX := x + w
                maxY := y + h
                first := false
            } else {
                if (x < minX) {
                    minX := x
                }
                if (y < minY) {
                    minY := y
                }
                if (x + w > maxX) {
                    maxX := x + w
                }
                if (y + h > maxY) {
                    maxY := y + h
                }
            }
        }
    }
}