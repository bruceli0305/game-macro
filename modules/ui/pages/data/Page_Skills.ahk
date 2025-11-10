#Requires AutoHotkey v2

; 数据与检测 → 技能（嵌入页）
; 不依赖旧 UI_Page_Config_* 函数；全部事件在本页实现
; 严格块结构 if/try/catch，不使用单行语句

Page_Skills_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 列表
    UI.SkillLV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        , ["ID","技能名","键位","X","Y","颜色","容差"])
    page.Controls.Push(UI.SkillLV)

    ; 按钮行
    yBtn := rc.Y + rc.H - 30
    UI.BtnAddSkill  := UI.Main.Add("Button", Format("x{} y{} w96 h28", rc.X, yBtn), "新增")
    UI.BtnEditSkill := UI.Main.Add("Button", "x+8 w96 h28", "编辑")
    UI.BtnDelSkill  := UI.Main.Add("Button", "x+8 w96 h28", "删除")
    UI.BtnTestSkill := UI.Main.Add("Button", "x+8 w96 h28", "测试检测")
    UI.BtnSaveSkill := UI.Main.Add("Button", "x+8 w96 h28", "保存")
    page.Controls.Push(UI.BtnAddSkill)
    page.Controls.Push(UI.BtnEditSkill)
    page.Controls.Push(UI.BtnDelSkill)
    page.Controls.Push(UI.BtnTestSkill)
    page.Controls.Push(UI.BtnSaveSkill)

    ; 事件绑定（全部为本页回调）
    UI.SkillLV.OnEvent("DoubleClick", Skills_OnEditSelected)
    UI.BtnAddSkill.OnEvent("Click", Skills_OnAdd)
    UI.BtnEditSkill.OnEvent("Click", Skills_OnEditSelected)
    UI.BtnDelSkill.OnEvent("Click", Skills_OnDelete)
    UI.BtnTestSkill.OnEvent("Click", Skills_OnTest)
    UI.BtnSaveSkill.OnEvent("Click", Skills_OnSaveProfile)

    ; 首次填充
    Skills_RefreshList()
}

Page_Skills_Layout(rc) {
    try {
        UI.SkillLV.Move(rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        y := rc.Y + rc.H - 30
        UI.BtnAddSkill.Move(rc.X, y)
        UI.BtnEditSkill.Move(, y)
        UI.BtnDelSkill.Move(, y)
        UI.BtnTestSkill.Move(, y)
        UI.BtnSaveSkill.Move(, y)
        loop 7 {
            try {
                UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    }
}

Page_Skills_OnEnter(*) {
    Skills_RefreshList()
}

; ================= 工具与事件 =================

Skills_RefreshList() {
    global App, UI
    try {
        UI.SkillLV.Opt("-Redraw")
        UI.SkillLV.Delete()
    } catch {
    }

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        for idx, s in App["ProfileData"].Skills {
            name := ""
            key  := ""
            x := 0, y := 0, col := "0x000000", tol := 10

            try { 
                name := s.Name 
            } catch { 
                name := "" 
            }
            try { 
                key  := s.Key  
            } catch { 
                key  := "" 
            }
            try { 
                x := s.X 
            } catch { 
                x := 0 
            }
            try { 
                y := s.Y 
            } catch { 
                y := 0 
            }
            try { 
                col := s.Color 
            } catch { 
                col := "0x000000" 
            }
            try { 
                tol := s.Tol 
            } catch { 
                tol := 10 
            }

            UI.SkillLV.Add("", idx, name, key, x, y, col, tol)
        }
        loop 7 {
            try {
                UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            UI.SkillLV.Opt("+Redraw")
        } catch {
        }
    }
}

Skills_GetSelectedIndex() {
    global UI
    row := 0
    try {
        row := UI.SkillLV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (row = 0) {
        MsgBox "请先选中一个技能行。"
        return 0
    }
    idx := 0
    try {
        idx := Integer(UI.SkillLV.GetText(row, 1))
    } catch {
        idx := 0
    }
    return idx
}

; ---- 新增 ----
Skills_OnAdd(*) {
    try {
        SkillEditor_Open({}, 0, Skills_OnSaved_New)
    } catch {
        MsgBox "无法打开技能编辑器。"
    }
}

Skills_OnSaved_New(newSkill, idxParam) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        App["ProfileData"].Skills.Push(newSkill)
        Skills_RefreshList()
    } catch {
    }
    ; 调整 ROI
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 编辑 ----
Skills_OnEditSelected(*) {
    global App, UI
    idx := Skills_GetSelectedIndex()
    if (idx = 0) {
        return
    }
    cur := 0
    try {
        cur := App["ProfileData"].Skills[idx]
    } catch {
        cur := 0
    }
    try {
        SkillEditor_Open(cur, idx, Skills_OnSaved_Edit)
    } catch {
        MsgBox "无法打开技能编辑器。"
    }
}

Skills_OnSaved_Edit(newSkill, idx2) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        if (idx2 >= 1 && idx2 <= App["ProfileData"].Skills.Length) {
            App["ProfileData"].Skills[idx2] := newSkill
        }
        Skills_RefreshList()
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 删除 ----
Skills_OnDelete(*) {
    global App
    idx := Skills_GetSelectedIndex()
    if (idx = 0) {
        return
    }
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
            MsgBox "索引异常，列表与配置不同步。"
            return
        }
        App["ProfileData"].Skills.RemoveAt(idx)
        Skills_RefreshList()
        Notify("已删除技能")
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 测试 ----
Skills_OnTest(*) {
    global App
    idx := Skills_GetSelectedIndex()
    if (idx = 0) {
        return
    }

    s := 0
    try {
        s := App["ProfileData"].Skills[idx]
    } catch {
        s := 0
    }
    if !s {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }

    offY := 0
    dwell := 0
    try {
        if (HasProp(App["ProfileData"], "PickHoverEnabled") && App["ProfileData"].PickHoverEnabled) {
            offY := HasProp(App["ProfileData"], "PickHoverOffsetY") ? App["ProfileData"].PickHoverOffsetY : 0
            dwell := HasProp(App["ProfileData"], "PickHoverDwellMs") ? App["ProfileData"].PickHoverDwellMs : 0
        }
    } catch {
        offY := 0
        dwell := 0
    }

    c := 0
    try {
        c := Pixel_GetColorWithMouseAway(s.X, s.Y, offY, dwell)
    } catch {
        c := 0
    }

    tgt := 0
    try {
        tgt := Pixel_HexToInt(s.Color)
    } catch {
        tgt := 0
    }
    match := false
    try {
        match := Pixel_ColorMatch(c, tgt, s.Tol)
    } catch {
        match := false
    }

    try {
        MsgBox "检测点: X=" s.X " Y=" s.Y "`n"
            . "当前颜色: " Pixel_ColorToHex(c) "`n"
            . "目标颜色: " s.Color "`n"
            . "容差: " s.Tol "`n"
            . "结果: " (match ? "匹配" : "不匹配")
    } catch {
    }
}

; ---- 保存 ----
Skills_OnSaveProfile(*) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData")) {
            return
        }
        Storage_SaveProfile(App["ProfileData"])
        Notify("配置已保存")
    } catch as e {
        MsgBox "保存失败：" e.Message
    }
}