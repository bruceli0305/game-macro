#Requires AutoHotkey v2
;modules\ui\dialogs\GUI_SkillEditor.ahk

SkillEditor_Open(skill, idx := 0, onSaved := 0) {
    global UI, App

    isNew := (idx = 0)

    ; 默认值增加 LockDuringCast / CastTimeoutMs
    defaults := Map(
          "Name", ""
        , "Key", ""
        , "X", 0
        , "Y", 0
        , "Color", "0x000000"
        , "Tol", 10
        , "CastMs", 0
        , "LockDuringCast", 1
        , "CastTimeoutMs", 0
    )

    if !IsObject(skill) {
        skill := {}
    }
    for k, v in defaults {
        if !HasProp(skill, k) {
            skill.%k% := v
        }
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增技能" : "编辑技能")
    dlg.MarginX := 14
    dlg.MarginY := 12
    dlg.SetFont("s10", "Segoe UI")

    ; 行1：技能名
    dlg.Add("Text", "w70 Right", "技能名：")
    tbName := dlg.Add("Edit", "x+10 w336", skill.Name)

    ; 行2：键位 + 捕获鼠标
    dlg.Add("Text", "xm w70 Right", "键位：")
    hkKey := dlg.Add("Hotkey", "x+10 w336", skill.Key)
    btnMouseKey := dlg.Add("Button", "x+8 w110 h28", "捕获鼠标键")

    ; 行3：坐标 + 拾取像素
    dlg.Add("Text", "xm w70 Right", "坐标X：")
    tbX := dlg.Add("Edit", "x+10 w120 Number", skill.X)
    dlg.Add("Text", "x+16 w70 Right", "坐标Y：")
    tbY := dlg.Add("Edit", "x+10 w120 Number", skill.Y)
    btnPick := dlg.Add("Button", "x+8 w110 h28", "拾取像素")

    ; 行4：颜色 + 容差
    dlg.Add("Text", "xm w70 Right", "颜色：")
    tbColor := dlg.Add("Edit", "x+10 w120", skill.Color)
    dlg.Add("Text", "x+16 w70 Right", "容差：")
    tbTol := dlg.Add("Edit", "x+10 w120 Number", skill.Tol)

    ; 行5：读条 + 施放锁定
    dlg.Add("Text", "xm w70 Right", "读条：")
    tbCast := dlg.Add("Edit", "x+10 w120 Number", (HasProp(skill,"CastMs") ? skill.CastMs : 0))

    dlg.Add("Text", "x+16 w80 Right", "施放锁定：")
    ; 1=锁定（施放期间阻止后续技能），0=不锁定
    tbLock := dlg.Add("CheckBox", "x+6 w120", "施放期间禁止后续技能")
    try {
        tbLock.Value := (HasProp(skill, "LockDuringCast") && skill.LockDuringCast) ? 1 : 0
    } catch {
        tbLock.Value := 1
    }

    ; 行6：超时(ms)
    dlg.Add("Text", "xm w70 Right", "超时(ms)：")
    tbTimeout := dlg.Add("Edit", "x+10 w120 Number"
        , (HasProp(skill, "CastTimeoutMs") ? skill.CastTimeoutMs : 0))

    ; 行7：按钮
    btnSave := dlg.Add("Button", "xm w96 h30", "保存")
    btnCancel := dlg.Add("Button", "x+8 w96 h30", "取消")

    ; 事件绑定
    btnPick.OnEvent("Click", OnPick)
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", OnCancel)
    btnMouseKey.OnEvent("Click", OnCapMouse)

    dlg.Show()

    OnPick(*) {
        offY := 0
        dwell := 0
        try {
            if (HasProp(App["ProfileData"], "PickHoverEnabled") && App["ProfileData"].PickHoverEnabled) {
                try {
                    offY := HasProp(App["ProfileData"], "PickHoverOffsetY") ? App["ProfileData"].PickHoverOffsetY : 0
                } catch {
                    offY := 0
                }
                try {
                    dwell := HasProp(App["ProfileData"], "PickHoverDwellMs") ? App["ProfileData"].PickHoverDwellMs : 0
                } catch {
                    dwell := 0
                }
            }
        } catch {
            offY := 0
            dwell := 0
        }
        res := 0
        try {
            res := Pixel_PickPixel(dlg, offY, dwell)
        } catch {
            res := 0
        }
        if (res) {
            try {
                tbX.Value := res.X
            } catch {
            }
            try {
                tbY.Value := res.Y
            } catch {
            }
            try {
                tbColor.Value := Pixel_ColorToHex(res.Color)
            } catch {
            }
        }
    }

    OnCapMouse(*) {
        ToolTip "请按下 鼠标中键/侧键（Esc 取消）"
        key := ""
        while true {
            if GetKeyState("Esc","P") {
                break
            }
            for k in ["MButton","XButton1","XButton2"] {
                if GetKeyState(k,"P") {
                    key := k
                    while GetKeyState(k,"P") {
                        Sleep 20
                    }
                    break
                }
            }
            if (key != "") {
                break
            }
            Sleep 20
        }
        ToolTip()
        if (key != "") {
            try {
                hkKey.Value := key
            } catch {
            }
        }
    }

    OnSave(*) {
        name := ""
        key := ""
        col := ""
        tol := 10
        x := 0
        y := 0
        cast := 0
        lockVal := 1
        timeout := 0

        try {
            name := Trim(tbName.Value)
        } catch {
            name := ""
        }
        try {
            key := Trim(hkKey.Value)
        } catch {
            key := ""
        }
        try {
            col := Trim(tbColor.Value)
        } catch {
            col := ""
        }
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

        try {
            x := (tbX.Value != "") ? Integer(tbX.Value) : 0
        } catch {
            x := 0
        }
        try {
            y := (tbY.Value != "") ? Integer(tbY.Value) : 0
        } catch {
            y := 0
        }
        try {
            tol := (tbTol.Value != "") ? Integer(tbTol.Value) : 10
        } catch {
            tol := 10
        }
        try {
            cast := (tbCast.Value != "") ? Integer(tbCast.Value) : 0
        } catch {
            cast := 0
        }
        try {
            lockVal := (tbLock.Value ? 1 : 0)
        } catch {
            lockVal := 1
        }
        try {
            timeout := (tbTimeout.Value != "") ? Integer(tbTimeout.Value) : 0
        } catch {
            timeout := 0
        }

        try {
            col := Pixel_ColorToHex(Pixel_HexToInt(col))
        } catch {
            col := "0x000000"
        }

        newSkill := {
              Name: name
            , Key: key
            , X: x
            , Y: y
            , Color: col
            , Tol: tol
            , CastMs: cast
            , LockDuringCast: lockVal
            , CastTimeoutMs: timeout
        }

        if (onSaved) {
            try {
                onSaved(newSkill, idx)
            } catch {
            }
        }

        try {
            dlg.Destroy()
        } catch {
        }
        try {
            UI_ActivateMain()
        } catch {
        }
        try {
            Notify(isNew ? "已新增技能" : "已保存修改")
        } catch {
        }
    }

    OnCancel(*) {
        try {
            dlg.Destroy()
        } catch {
        }
        try {
            UI_ActivateMain()
        } catch {
        }
    }
}