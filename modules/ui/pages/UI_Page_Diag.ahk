#Requires AutoHotkey v2

; 采集诊断（DXGI/ROI）
; 前缀：DIAG_
; 功能：
; - 显示 DXGI 状态、输出列表、矩形等
; - 显示 ROI 状态、重建 ROI
; - 简单取色测试（支持拾取/手输坐标）

Page_Diag_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ===== DXGI 状态 =====
    UI.DIAG_GB_DX := UI.Main.Add("GroupBox", Format("x{} y{} w{} h160", rc.X, rc.Y, rc.W), "DXGI 状态")
    page.Controls.Push(UI.DIAG_GB_DX)

    UI.DIAG_L_DXEnabled := UI.Main.Add("Text", Format("x{} y{} w140", rc.X + 12, rc.Y + 26), "启用：")
    page.Controls.Push(UI.DIAG_L_DXEnabled)
    UI.DIAG_L_DXReady := UI.Main.Add("Text", "x+20 w160", "就绪：")
    page.Controls.Push(UI.DIAG_L_DXReady)
    UI.DIAG_L_FPS := UI.Main.Add("Text", "x+20 w160", "FPS：")
    page.Controls.Push(UI.DIAG_L_FPS)

    UI.DIAG_L_Out := UI.Main.Add("Text", Format("x{} y{} w80 Right", rc.X + 12, rc.Y + 26 + 28), "输出：")
    page.Controls.Push(UI.DIAG_L_Out)
    UI.DIAG_DdOut := UI.Main.Add("DropDownList", "x+6 w260")
    page.Controls.Push(UI.DIAG_DdOut)
    UI.DIAG_BtnApplyOut := UI.Main.Add("Button", "x+8 w100 h24", "应用输出")
    page.Controls.Push(UI.DIAG_BtnApplyOut)

    UI.DIAG_L_Name := UI.Main.Add("Text", Format("x{} y{} w450", rc.X + 12, rc.Y + 26 + 56), "名称：")
    page.Controls.Push(UI.DIAG_L_Name)
    UI.DIAG_L_Rect := UI.Main.Add("Text", "x+20 w380", "矩形：")
    page.Controls.Push(UI.DIAG_L_Rect)

    UI.DIAG_BtnDXRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h24", rc.X + 12, rc.Y + 26 + 84), "刷新")
    page.Controls.Push(UI.DIAG_BtnDXRefresh)

    ; ===== ROI 状态 =====
    yRoi := rc.Y + 170
    UI.DIAG_GB_ROI := UI.Main.Add("GroupBox", Format("x{} y{} w{} h120", rc.X, yRoi, rc.W), "ROI 状态")
    page.Controls.Push(UI.DIAG_GB_ROI)

    UI.DIAG_L_ROIEnabled := UI.Main.Add("Text", Format("x{} y{} w160", rc.X + 12, yRoi + 26), "启用：")
    page.Controls.Push(UI.DIAG_L_ROIEnabled)
    UI.DIAG_L_ROIRects := UI.Main.Add("Text", "x+20 w220", "矩形数：")
    page.Controls.Push(UI.DIAG_L_ROIRects)
    UI.DIAG_L_ROIRect0 := UI.Main.Add("Text", "x+20 w380", "第一个矩形：")
    page.Controls.Push(UI.DIAG_L_ROIRect0)

    UI.DIAG_BtnRebuildROI := UI.Main.Add("Button", Format("x{} y{} w120 h24", rc.X + 12, yRoi + 26 + 28), "重建 ROI")
    page.Controls.Push(UI.DIAG_BtnRebuildROI)

    ; ===== 取色测试 =====
    yTest := yRoi + 130
    UI.DIAG_GB_Test := UI.Main.Add("GroupBox", Format("x{} y{} w{} h140", rc.X, yTest, rc.W), "取色测试")
    page.Controls.Push(UI.DIAG_GB_Test)

    UI.DIAG_L_X := UI.Main.Add("Text", Format("x{} y{} w60 Right", rc.X + 12, yTest + 26), "X：")
    page.Controls.Push(UI.DIAG_L_X)
    UI.DIAG_EdX := UI.Main.Add("Edit", "x+6 w90 Number")
    page.Controls.Push(UI.DIAG_EdX)

    UI.DIAG_L_Y := UI.Main.Add("Text", "x+18 w60 Right", "Y：")
    page.Controls.Push(UI.DIAG_L_Y)
    UI.DIAG_EdY := UI.Main.Add("Edit", "x+6 w90 Number")
    page.Controls.Push(UI.DIAG_EdY)

    UI.DIAG_BtnPick := UI.Main.Add("Button", "x+14 w110 h24", "拾取坐标")
    page.Controls.Push(UI.DIAG_BtnPick)
    UI.DIAG_BtnTest := UI.Main.Add("Button", "x+8 w100 h24", "测试取色")
    page.Controls.Push(UI.DIAG_BtnTest)

    UI.DIAG_L_Color := UI.Main.Add("Text", Format("x{} y{} w80 Right", rc.X + 12, yTest + 26 + 36), "颜色：")
    page.Controls.Push(UI.DIAG_L_Color)
    UI.DIAG_EdColor := UI.Main.Add("Edit", "x+6 w160 ReadOnly")
    page.Controls.Push(UI.DIAG_EdColor)

    ; 事件
    UI.DIAG_BtnDXRefresh.OnEvent("Click", Diag_OnRefresh)
    UI.DIAG_BtnApplyOut.OnEvent("Click", Diag_OnApplyOutput)
    UI.DIAG_BtnRebuildROI.OnEvent("Click", Diag_OnRebuildROI)
    UI.DIAG_BtnPick.OnEvent("Click", Diag_OnPickCoord)
    UI.DIAG_BtnTest.OnEvent("Click", Diag_OnTestPixel)

    ; 首次刷新
    Diag_OnRefresh()
}

Page_Diag_Layout(rc) {
    try {
        UI.DIAG_GB_DX.Move(rc.X, rc.Y, rc.W)
        UI.DIAG_GB_ROI.Move(rc.X, rc.Y + 170, rc.W)
        UI.DIAG_GB_Test.Move(rc.X, rc.Y + 170 + 130, rc.W)
    } catch {
    }
}

Page_Diag_OnEnter(*) {
    Diag_OnRefresh()
}

Diag_OnRefresh(*) {
    global gDX, UI

    ; DXGI 概要
    readyTxt := ""
    try {
        dxReady := DX_IsReady()
        if (dxReady) {
            readyTxt := "是"
        } else {
            readyTxt := "否"
        }
    } catch {
        readyTxt := "未知"
    }

    try {
        enabledTxt := gDX.Enabled ? "是" : "否"
        UI.DIAG_L_DXEnabled.Text := "启用：" enabledTxt
    } catch {
        UI.DIAG_L_DXEnabled.Text := "启用：未知"
    }

    try {
        UI.DIAG_L_DXReady.Text := "就绪：" readyTxt
    } catch {
    }

    try {
        UI.DIAG_L_FPS.Text := "FPS：" gDX.FPS
    } catch {
        UI.DIAG_L_FPS.Text := "FPS：未知"
    }

    ; 输出枚举
    outs := []
    try {
        UI.DIAG_DdOut.Delete()
    } catch {
    }
    try {
        cnt := DX_EnumOutputs()
        if (cnt < 0) {
            cnt := 0
        }
        i := 0
        while (i < cnt) {
            i := i + 1
            idx0 := i - 1
            name := DX_GetOutputName(idx0)
            if (name = "") {
                name := "Output " idx0
            }
            outs.Push({Idx: idx0, Name: name})
        }
        if (outs.Length > 0) {
            names := []
            for _, o in outs {
                names.Push(o.Name " (#" o.Idx ")")
            }
            UI.DIAG_DdOut.Add(names)
            sel := 1
            i2 := 0
            for _, o2 in outs {
                i2 := i2 + 1
                if (o2.Idx = gDX.OutIdx) {
                    sel := i2
                    break
                }
            }
            UI.DIAG_DdOut.Value := sel
        } else {
            UI.DIAG_DdOut.Add(["（无输出）"])
            UI.DIAG_DdOut.Value := 1
        }
    } catch {
        UI.DIAG_DdOut.Add(["（枚举失败）"])
        UI.DIAG_DdOut.Value := 1
    }

    ; 名称/矩形
    try {
        UI.DIAG_L_Name.Text := "名称：" gDX.MonName
    } catch {
        UI.DIAG_L_Name.Text := "名称：未知"
    }
    try {
        UI.DIAG_L_Rect.Text := "矩形：(" gDX.L "," gDX.T ") - (" gDX.R "," gDX.B ")"
    } catch {
        UI.DIAG_L_Rect.Text := "矩形：未知"
    }

    ; ROI 概要
    try {
        global gROI
        enableRoi := gROI.enabled ? "是" : "否"
        UI.DIAG_L_ROIEnabled.Text := "启用：" enableRoi

        rcnt := 0
        if (IsObject(gROI) and HasProp(gROI, "rects")) {
            rcnt := gROI.rects.Length
        }
        UI.DIAG_L_ROIRects.Text := "矩形数：" rcnt

        first := "无"
        if (rcnt > 0) {
            r := gROI.rects[1]
            first := "(" r.L "," r.T ") " r.W "x" r.H
        }
        UI.DIAG_L_ROIRect0.Text := "第一个矩形：" first
    } catch {
    }
}

Diag_OnApplyOutput(*) {
    global UI

    try {
        sel := UI.DIAG_DdOut.Value
        if (sel <= 0) {
            return
        }
        text := UI.DIAG_DdOut.Text
        pos := InStr(text, "(#")
        if (pos <= 0) {
            return
        }
        idxText := SubStr(text, pos + 2)
        pos2 := InStr(idxText, ")")
        if (pos2 <= 0) {
            return
        }
        idxStr := SubStr(idxText, 1, pos2 - 1)
        idx := Integer(idxStr)
        ok := Dup_SelectOutputIdx(idx)
        if (ok = 1) {
            Notify("已切换 DXGI 输出到 #" idx)
        } else {
            Notify("切换输出失败")
        }
        Diag_OnRefresh()
    } catch {
    }
}

Diag_OnRebuildROI(*) {
    global App
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
    Diag_OnRefresh()
}

Diag_OnPickCoord(*) {
    global UI, App
    offY := 0
    dwell := 0
    try {
        if (HasProp(App["ProfileData"], "PickHoverEnabled") and App["ProfileData"].PickHoverEnabled) {
            offY := App["ProfileData"].PickHoverOffsetY
            dwell := App["ProfileData"].PickHoverDwellMs
        }
    } catch {
    }
    res := 0
    try {
        res := Pixel_PickPixel(UI.Main, offY, dwell)
    } catch {
        res := 0
    }
    if (res) {
        UI.DIAG_EdX.Value := res.X
        UI.DIAG_EdY.Value := res.Y
        UI.DIAG_EdColor.Value := Pixel_ColorToHex(res.Color)
    }
}

Diag_OnTestPixel(*) {
    global UI

    x := 0
    y := 0
    try {
        if (UI.DIAG_EdX.Value != "") {
            x := Integer(UI.DIAG_EdX.Value)
        }
        if (UI.DIAG_EdY.Value != "") {
            y := Integer(UI.DIAG_EdY.Value)
        }
    } catch {
        x := 0
        y := 0
    }

    try {
        if !DX_IsReady() {
            Pixel_ROI_BeginSnapshot()
        }
        Pixel_FrameBegin()
    } catch {
    }

    c := 0
    try {
        c := Pixel_FrameGet(x, y)
    } catch {
        c := 0
    }
    try {
        UI.DIAG_EdColor.Value := Pixel_ColorToHex(c)
    } catch {
    }
}