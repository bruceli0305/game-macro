; GUI_SkillEditor.ahk - 调整字号与布局

SkillEditor_Open(skill, idx := 0, onSaved := 0) {
    isNew := (idx = 0)

    defaults := Map("Name","", "Key","", "X",0, "Y",0, "Color","0x000000", "Tol",10, "CastMs",0)
    if !IsObject(skill)
        skill := {}
    for k, v in defaults
        if !HasProp(skill, k)
            skill.%k% := v

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增技能" : "编辑技能")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.SetFont("s10", "Segoe UI")

    dlg.Add("Text", "w70", "技能名：")
    tbName := dlg.Add("Edit", "x+10 w260", skill.Name)

    dlg.Add("Text", "xm w70", "键位：")
    hkKey := dlg.Add("Hotkey", "x+10 w160", skill.Key)
    
    btnMouseKey := dlg.Add("Button", "x+8 w110 h28", "捕获鼠标键")   ; 新增

    dlg.Add("Text", "xm w70", "坐标X：")
    tbX := dlg.Add("Edit", "x+10 w120 Number", skill.X)
    dlg.Add("Text", "x+16 w70", "坐标Y：")
    tbY := dlg.Add("Edit", "x+10 w120 Number", skill.Y)
    btnPick := dlg.Add("Button", "x+16 w96 h28", "拾取像素")

    dlg.Add("Text", "xm w70", "颜色：")
    tbColor := dlg.Add("Edit", "x+10 w160", skill.Color)
    dlg.Add("Text", "x+16 w70", "容差：")
    tbTol := dlg.Add("Edit", "x+10 w96 Number", skill.Tol)
    dlg.Add("Text", "x+16 w70", "读条(ms)：")
    tbCast := dlg.Add("Edit", "x+10 w96 Number", HasProp(skill,"CastMs") ? skill.CastMs : 0)

    btnSave := dlg.Add("Button", "xm w96 h30", "保存")
    btnCancel := dlg.Add("Button", "x+8 w96 h30", "取消")

    btnPick.OnEvent("Click", OnPick)
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    btnMouseKey.OnEvent("Click", OnCapMouse)                      ; 新增

    dlg.Show()

    OnPick(*) {
        global App
        offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
        dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
        res := Pixel_PickPixel(dlg, offY, dwell)   ; 修正：传入避让参数
        if res {
            tbX.Value := res.X
            tbY.Value := res.Y
            tbColor.Value := Pixel_ColorToHex(res.Color)
        }
    }
    ; 新增：捕获 MButton / XButton1 / XButton2
    OnCapMouse(*) {
        ToolTip "请按下 鼠标中键/侧键（Esc 取消）"
        key := ""
        while true {
            if GetKeyState("Esc","P")
                break
            for k in ["MButton","XButton1","XButton2"] {
                if GetKeyState(k,"P") {
                    key := k
                    while GetKeyState(k,"P")
                        Sleep 20
                    break
                }
            }
            if (key != "")
                break
            Sleep 20
        }
        ToolTip()
        if (key != "")
            hkKey.Value := key
    }
    
    OnSave(*) {
        name := Trim(tbName.Value)
        key := Trim(hkKey.Value)
        ; 数值字段做容错：空值则给默认
        x := (tbX.Value != "") ? Integer(tbX.Value) : 0
        y := (tbY.Value != "") ? Integer(tbY.Value) : 0
        col := Trim(tbColor.Value)
        tol := (tbTol.Value != "") ? Integer(tbTol.Value) : 10

        if (name = "") {
            MsgBox "技能名不可为空"
            return
        }
        if (key = "") {
            MsgBox "请设置键位"
            return
        }
        if (col = "") {
            MsgBox "请设置颜色"
            return
        }

        col := Pixel_ColorToHex(Pixel_HexToInt(col))
        cast := (tbCast.Value != "") ? Integer(tbCast.Value) : 0
        newSkill := { Name: name, Key: key, X: x, Y: y, Color: col, Tol: tol, CastMs: cast }

        if onSaved
            onSaved(newSkill, idx)

        dlg.Destroy()
        UI_ActivateMain()                 ; 新增：回到主窗
        Notify(isNew ? "已新增技能" : "已保存修改")
    }
}
