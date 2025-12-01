#Requires AutoHotkey v2
; modules\ui\pages\data\Page_Points.ahk
; 数据与检测 → 取色点位（嵌入页）
; 严格块结构，不使用单行语句
; 依赖：OM_Get（modules\util\Obj.ahk 已由 Main.ahk 全局引入）

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
    UI.BtnBatchPoint := UI.Main.Add("Button", "x+8 w96 h28", "批量取色")
    UI.BtnSavePoint := UI.Main.Add("Button", "x+8 w96 h28", "保存")
    page.Controls.Push(UI.BtnAddPoint)
    page.Controls.Push(UI.BtnEditPoint)
    page.Controls.Push(UI.BtnDelPoint)
    page.Controls.Push(UI.BtnTestPoint)
    page.Controls.Push(UI.BtnBatchPoint)
    page.Controls.Push(UI.BtnSavePoint)

    ; 事件绑定
    UI.PointLV.OnEvent("DoubleClick", Points_OnEditSelected)
    UI.BtnAddPoint.OnEvent("Click", Points_OnAdd)
    UI.BtnEditPoint.OnEvent("Click", Points_OnEditSelected)
    UI.BtnDelPoint.OnEvent("Click", Points_OnDelete)
    UI.BtnTestPoint.OnEvent("Click", Points_OnTest)
    UI.BtnBatchPoint.OnEvent("Click", Points_OnBatchRecolor)
    UI.BtnSavePoint.OnEvent("Click", Points_OnSaveProfile)

    Points_RefreshList()
}

Page_Points_Layout(rc) {
    try {
        btnH := 28
        try {
            UI.BtnAddPoint.GetPos(,,, &btnH)
        } catch {
        }

        gap := 8
        listH := rc.H - btnH - gap
        if (listH < 120) {
            listH := 120
        }

        UI.PointLV.Move(rc.X, rc.Y, rc.W, listH)

        yBtn := rc.Y + rc.H - btnH
        UI.BtnAddPoint.Move(rc.X, yBtn)
        UI.BtnEditPoint.Move(,     yBtn)
        UI.BtnDelPoint.Move(,      yBtn)
        UI.BtnTestPoint.Move(,     yBtn)
        UI.BtnBatchPoint.Move(,    yBtn)
        UI.BtnSavePoint.Move(,     yBtn)

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
            id  := OM_Get(p, "Id", 0)
            name:= OM_Get(p, "Name", "")
            x   := OM_Get(p, "X", 0)
            y   := OM_Get(p, "Y", 0)
            col := OM_Get(p, "Color", "0x000000")
            tol := OM_Get(p, "Tol", 10)

            UI.PointLV.Add("", id, name, x, y, col, tol)
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

; 从列表选中行读取稳定 Id（列 1）
Points_GetSelectedId() {
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
    id := 0
    try {
        id := Integer(UI.PointLV.GetText(row, 1))
    } catch {
        id := 0
    }
    return id
}

; 按稳定 Id 查找当前运行时索引
Points_IndexById(id) {
    global App
    if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Points")) {
        return 0
    }

    i := 1
    while (i <= App["ProfileData"].Points.Length) {
        pid := 0
        try {
            pid := OM_Get(App["ProfileData"].Points[i], "Id", 0)
        } catch {
            pid := 0
        }
        if (pid = id) {
            return i
        }
        i := i + 1
    }
    return 0
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
        if !HasProp(newPoint, "Id") {
            try {
                newPoint.Id := 0
            } catch {
            }
        }
        App["ProfileData"].Points.Push(newPoint)
        Points_RefreshList()
    } catch {
    }
}

; ---- 编辑 ----
Points_OnEditSelected(*) {
    global App
    id := Points_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Points_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
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
            old := 0
            try {
                old := App["ProfileData"].Points[idx2]
            } catch {
                old := 0
            }
            try {
                if (old && HasProp(old, "Id")) {
                    newPoint.Id := old.Id
                }
            } catch {
            }
            App["ProfileData"].Points[idx2] := newPoint
        }
        Points_RefreshList()
    } catch {
    }
}

; ---- 删除 ----
Points_OnDelete(*) {
    global App
    id := Points_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Points_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
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
    id := Points_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Points_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }

    p := 0
    try {
        p := App["ProfileData"].Points[idx]
    } catch {
        p := 0
    }
    if (!p) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }

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

    x   := OM_Get(p, "X", 0)
    y   := OM_Get(p, "Y", 0)
    col := OM_Get(p, "Color", "0x000000")
    tol := OM_Get(p, "Tol", 10)

    c := 0
    try {
        c := Pixel_GetColorWithMouseAway(x, y, offY, dwell)
    } catch {
        c := 0
    }

    tgt := 0
    try {
        tgt := Pixel_HexToInt(col)
    } catch {
        tgt := 0
    }
    match := false
    try {
        match := Pixel_ColorMatch(c, tgt, tol)
    } catch {
        match := false
    }

    try {
        MsgBox "检测点: X=" x " Y=" y "`n"
            . "当前颜色: " Pixel_ColorToHex(c) "`n"
            . "目标颜色: " col "`n"
            . "容差: " tol "`n"
            . "结果: " (match ? "匹配" : "不匹配")
    } catch {
    }
}

; ---- 保存（新存储） ----
Points_OnSaveProfile(*) {
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

    ; 1) 加载文件夹模型
    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch as e1 {
        try {
            Logger_Exception("Points", e1, Map("where", "LoadFull", "profile", name))
        } catch {
        }
        MsgBox "加载配置失败。"
        return
    }

    ; 2) 合并运行时到文件夹模型（按 Id）
    newArr := []
    try {
        if (HasProp(App["ProfileData"], "Points") && IsObject(App["ProfileData"].Points)) {
            i := 1
            while (i <= App["ProfileData"].Points.Length) {
                rp := App["ProfileData"].Points[i]
                pid := OM_Get(rp, "Id", 0)
                nm  := OM_Get(rp, "Name", "")
                x   := OM_Get(rp, "X", 0)
                y   := OM_Get(rp, "Y", 0)
                col := OM_Get(rp, "Color", "0x000000")
                tol := OM_Get(rp, "Tol", 10)

                pp := PM_NewPoint(nm)
                try {
                    pp["Id"] := pid
                } catch {
                }
                pp["Name"]  := nm
                pp["X"]     := x
                pp["Y"]     := y
                pp["Color"] := col
                pp["Tol"]   := tol

                newArr.Push(pp)
                i := i + 1
            }
        }
    } catch {
    }

    p["Points"] := newArr

    ; 3) 保存（分配新 Id 给 pid=0 的项）
    ok := false
    try {
        SaveModule_Points(p)
        ok := true
    } catch as e2 {
        ok := false
        try {
            Logger_Exception("Points", e2, Map("where","SaveModule_Points", "profile", name))
        } catch {
        }
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    ; 4) 重载 → 规范化 → 刷新
    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
    } catch as e3 {
        try {
            Logger_Exception("Points", e3, Map("where","ReloadNormalize", "profile", name))
        } catch {
        }
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    try {
        Points_RefreshList()
    } catch {
    }

    Notify("配置已保存")
}
Points_OnBatchRecolor(*) {
    try {
        PointBatchRecolor_Open()
    } catch as e {
        try {
            Logger_Exception("BatchRecolor", e, Map("where", "Points_OnBatchRecolor"))
        } catch {
        }
        MsgBox "无法打开点位批量取色对话框。"
    }
}