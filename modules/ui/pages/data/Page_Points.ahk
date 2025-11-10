#Requires AutoHotkey v2

; 数据与检测 → 取色点位（嵌入页）
; 不依赖旧 UI_Page_Config_* 函数；全部事件在本页实现
; 严格块结构 if/try/catch，不使用单行语句

Page_Points_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 列表
    UI.PointLV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        , ["ID","名称","X","Y","颜色","容差"])
    page.Controls.Push(UI.PointLV)

    ; 按钮行
    yBtn := rc.Y + rc.H - 30
    UI.BtnAddPoint  := UI.Main.Add("Button", Format("x{} y{} w96 h28", rc.X, yBtn), "新增")
    UI.BtnEditPoint := UI.Main.Add("Button", "x+8 w96 h28", "编辑")
    UI.BtnDelPoint  := UI.Main.Add("Button", "x+8 w96 h28", "删除")
    UI.BtnTestPoint := UI.Main.Add("Button", "x+8 w96 h28", "测试点位")
    UI.BtnSavePoint := UI.Main.Add("Button", "x+8 w96 h28", "保存")
    page.Controls.Push(UI.BtnAddPoint)
    page.Controls.Push(UI.BtnEditPoint)
    page.Controls.Push(UI.BtnDelPoint)
    page.Controls.Push(UI.BtnTestPoint)
    page.Controls.Push(UI.BtnSavePoint)

    ; 事件绑定（全部为本页回调）
    UI.PointLV.OnEvent("DoubleClick", Points_OnEditSelected)
    UI.BtnAddPoint.OnEvent("Click", Points_OnAdd)
    UI.BtnEditPoint.OnEvent("Click", Points_OnEditSelected)
    UI.BtnDelPoint.OnEvent("Click", Points_OnDelete)
    UI.BtnTestPoint.OnEvent("Click", Points_OnTest)
    UI.BtnSavePoint.OnEvent("Click", Points_OnSaveProfile)

    ; 首次填充
    Points_RefreshList()
}

Page_Points_Layout(rc) {
    try {
        UI.PointLV.Move(rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        y := rc.Y + rc.H - 30
        UI.BtnAddPoint.Move(rc.X, y)
        UI.BtnEditPoint.Move(, y)
        UI.BtnDelPoint.Move(, y)
        UI.BtnTestPoint.Move(, y)
        UI.BtnSavePoint.Move(, y)
        loop 6 {
            try {
                UI.PointLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    }
}

Page_Points_OnEnter(*) {
    Points_RefreshList()
}

; ================= 工具与事件 =================

Points_RefreshList() {
    global App, UI
    try {
        UI.PointLV.Opt("-Redraw")
        UI.PointLV.Delete()
    } catch {
    }

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points")) {
            return
        }
        for idx, p in App["ProfileData"].Points {
            name := ""
            x := 0, y := 0, col := "0x000000", tol := 10

            try { 
                name := p.Name 
            } catch { 
                name := "" 
            }
            try { 
                x := p.X 
            } catch { 
                x := 0 
            }
            try { 
                y := p.Y 
            } catch { 
                y := 0 
            }
            try { 
                col := p.Color 
            } catch { 
                col := "0x000000" 
            }
            try { 
                tol := p.Tol 
            } catch { 
                tol := 10 
            }

            UI.PointLV.Add("", idx, name, x, y, col, tol)
        }
        loop 6 {
            try {
                UI.PointLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            UI.PointLV.Opt("+Redraw")
        } catch {
        }
    }
}

Points_GetSelectedIndex() {
    global UI
    row := 0
    try {
        row := UI.PointLV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (row = 0) {
        MsgBox "请先选中一个点位。"
        return 0
    }
    idx := 0
    try {
        idx := Integer(UI.PointLV.GetText(row, 1))
    } catch {
        idx := 0
    }
    return idx
}

; ---- 新增 ----
Points_OnAdd(*) {
    try {
        PointEditor_Open({}, 0, Points_OnSaved_New)
    } catch {
        MsgBox "无法打开点位编辑器。"
    }
}

Points_OnSaved_New(newPoint, idxParam) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points")) {
            return
        }
        App["ProfileData"].Points.Push(newPoint)
        Points_RefreshList()
    } catch {
    }
}

; ---- 编辑 ----
Points_OnEditSelected(*) {
    global App
    idx := Points_GetSelectedIndex()
    if (idx = 0) {
        return
    }
    cur := 0
    try {
        cur := App["ProfileData"].Points[idx]
    } catch {
        cur := 0
    }
    try {
        PointEditor_Open(cur, idx, Points_OnSaved_Edit)
    } catch {
        MsgBox "无法打开点位编辑器。"
    }
}

Points_OnSaved_Edit(newPoint, idx2) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points")) {
            return
        }
        if (idx2 >= 1 && idx2 <= App["ProfileData"].Points.Length) {
            App["ProfileData"].Points[idx2] := newPoint
        }
        Points_RefreshList()
    } catch {
    }
}

; ---- 删除 ----
Points_OnDelete(*) {
    global App
    idx := Points_GetSelectedIndex()
    if (idx = 0) {
        return
    }
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points")) {
            return
        }
        if (idx < 1 || idx > App["ProfileData"].Points.Length) {
            MsgBox "索引异常，列表与配置不同步。"
            return
        }
        App["ProfileData"].Points.RemoveAt(idx)
        Points_RefreshList()
        Notify("已删除点位")
    } catch {
    }
}

; ---- 测试 ----
Points_OnTest(*) {
    global App
    idx := Points_GetSelectedIndex()
    if (idx = 0) {
        return
    }

    p := 0
    try {
        p := App["ProfileData"].Points[idx]
    } catch {
        p := 0
    }
    if !p {
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
        c := Pixel_GetColorWithMouseAway(p.X, p.Y, offY, dwell)
    } catch {
        c := 0
    }

    tgt := 0
    try {
        tgt := Pixel_HexToInt(p.Color)
    } catch {
        tgt := 0
    }
    match := false
    try {
        match := Pixel_ColorMatch(c, tgt, p.Tol)
    } catch {
        match := false
    }

    try {
        MsgBox "检测点: X=" p.X " Y=" p.Y "`n"
            . "当前颜色: " Pixel_ColorToHex(c) "`n"
            . "目标颜色: " p.Color "`n"
            . "容差: " p.Tol "`n"
            . "结果: " (match ? "匹配" : "不匹配")
    } catch {
    }
}

; ---- 保存 ----
Points_OnSaveProfile(*) {
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