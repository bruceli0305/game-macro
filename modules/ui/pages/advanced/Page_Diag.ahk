#Requires AutoHotkey v2

; 采集诊断（DXGI/ROI）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：DG_

Page_Diag_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ========= DXGI 区 =========
    UI.DG_GB_DX := UI.Main.Add("GroupBox", Format("x{} y{} w{} h245", rc.X, rc.Y, rc.W), "DXGI 状态")
    page.Controls.Push(UI.DG_GB_DX)

    UI.DG_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r8 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.DG_Info)

    UI.DG_L_Out := UI.Main.Add("Text", Format("x{} y{} w70 Right", rc.X + 12, rc.Y + 26 + 8*22 + 12), "输出索引：")
    page.Controls.Push(UI.DG_L_Out)
    UI.DG_DdOut := UI.Main.Add("DropDownList", "x+6 w260")
    page.Controls.Push(UI.DG_DdOut)

    UI.DG_BtnApplyOut := UI.Main.Add("Button", "x+8 w100 h26", "应用输出")
    page.Controls.Push(UI.DG_BtnApplyOut)

    UI.DG_BtnRefresh := UI.Main.Add("Button", "x+12 w100 h26", "刷新")
    page.Controls.Push(UI.DG_BtnRefresh)

    ; ========= ROI 区 =========
    ry := rc.Y + 245 + 10
    UI.DG_GB_ROI := UI.Main.Add("GroupBox", Format("x{} y{} w{} h130", rc.X, ry, rc.W), "ROI 状态")
    page.Controls.Push(UI.DG_GB_ROI)

    UI.DG_ROI_Info := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, ry + 26, rc.W - 24), "")
    page.Controls.Push(UI.DG_ROI_Info)

    UI.DG_BtnROISnap := UI.Main.Add("Button", Format("x{} y{} w120 h26", rc.X + 12, ry + 60), "抓取快照")
    page.Controls.Push(UI.DG_BtnROISnap)

    UI.DG_BtnROIAuto := UI.Main.Add("Button", "x+8 w160 h26", "根据配置重建 ROI")
    page.Controls.Push(UI.DG_BtnROIAuto)

    ; ========= 取色测试 =========
    ty := ry + 130 + 10
    UI.DG_GB_Pick := UI.Main.Add("GroupBox", Format("x{} y{} w{} h120", rc.X, ty, rc.W), "取色测试（DX 优先）")
    page.Controls.Push(UI.DG_GB_Pick)

    UI.DG_L_X := UI.Main.Add("Text", Format("x{} y{} w50 Right", rc.X + 12, ty + 28), "X：")
    UI.DG_EdX := UI.Main.Add("Edit", "x+6 w100 Number")
    UI.DG_L_Y := UI.Main.Add("Text", "x+16 w50 Right", "Y：")
    UI.DG_EdY := UI.Main.Add("Edit", "x+6 w100 Number")
    page.Controls.Push(UI.DG_L_X), page.Controls.Push(UI.DG_EdX), page.Controls.Push(UI.DG_L_Y), page.Controls.Push(UI.DG_EdY)

    UI.DG_BtnPick := UI.Main.Add("Button", "x+16 w100 h26", "取色")
    page.Controls.Push(UI.DG_BtnPick)

    UI.DG_L_Res := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, ty + 62, rc.W - 24), "Hex: -")
    page.Controls.Push(UI.DG_L_Res)

    ; ========= 统计与日志 =========
    sy := ty + 120 + 10
    UI.DG_GB_Stats := UI.Main.Add("GroupBox", Format("x{} y{} w{} h120", rc.X, sy, rc.W), "统计与日志")
    page.Controls.Push(UI.DG_GB_Stats)

    UI.DG_L_Stats := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, sy + 26, rc.W - 24), "Stats: -")
    page.Controls.Push(UI.DG_L_Stats)

    UI.DG_BtnClrStats := UI.Main.Add("Button", Format("x{} y{} w120 h26", rc.X + 12, sy + 60), "清零统计")
    UI.DG_BtnOpenLogs := UI.Main.Add("Button", "x+8 w120 h26", "打开 Logs 目录")
    UI.DG_BtnOpenNative := UI.Main.Add("Button", "x+8 w150 h26", "打开原生日志")
    page.Controls.Push(UI.DG_BtnClrStats), page.Controls.Push(UI.DG_BtnOpenLogs), page.Controls.Push(UI.DG_BtnOpenNative)

    ; 事件
    UI.DG_BtnRefresh.OnEvent("Click", Diag_OnRefresh)
    UI.DG_BtnApplyOut.OnEvent("Click", Diag_OnApplyOutput)
    UI.DG_BtnROISnap.OnEvent("Click", Diag_OnROISnap)
    UI.DG_BtnROIAuto.OnEvent("Click", Diag_OnROIAuto)
    UI.DG_BtnPick.OnEvent("Click", Diag_OnPick)
    UI.DG_BtnClrStats.OnEvent("Click", Diag_OnClearStats)
    UI.DG_BtnOpenLogs.OnEvent("Click", Diag_OnOpenLogs)
    UI.DG_BtnOpenNative.OnEvent("Click", Diag_OnOpenNative)

    ; 首次填充
    Diag_FillOutputs()
    Diag_OnRefresh()
}

Page_Diag_Layout(rc) {
    try {
        UI.DG_GB_DX.Move(rc.X, rc.Y, rc.W)
        UI.DG_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)

        yb := rc.Y + 26 + 8*22 + 12
        UI.DG_L_Out.Move(rc.X + 12, yb + 4)
        UI.DG_DdOut.Move(rc.X + 12 + 70 + 6, yb)
        UI.DG_BtnApplyOut.Move(UI.DG_DdOut.Pos.X + UI.DG_DdOut.Pos.W + 8, yb)
        UI.DG_BtnRefresh.Move(UI.DG_BtnApplyOut.Pos.X + UI.DG_BtnApplyOut.Pos.W + 12, yb)

        ry := rc.Y + 245 + 10
        UI.DG_GB_ROI.Move(rc.X, ry, rc.W)
        UI.DG_ROI_Info.Move(rc.X + 12, ry + 26, rc.W - 24)
        UI.DG_BtnROISnap.Move(rc.X + 12, ry + 60)
        UI.DG_BtnROIAuto.Move(UI.DG_BtnROISnap.Pos.X + UI.DG_BtnROISnap.Pos.W + 8, ry + 60)

        ty := ry + 130 + 10
        UI.DG_GB_Pick.Move(rc.X, ty, rc.W)
        UI.DG_L_X.Move(rc.X + 12, ty + 28 + 4)
        UI.DG_EdX.Move(UI.DG_L_X.Pos.X + UI.DG_L_X.Pos.W + 6, ty + 26)
        UI.DG_L_Y.Move(UI.DG_EdX.Pos.X + UI.DG_EdX.Pos.W + 16, ty + 28 + 4)
        UI.DG_EdY.Move(UI.DG_L_Y.Pos.X + UI.DG_L_Y.Pos.W + 6, ty + 26)
        UI.DG_BtnPick.Move(UI.DG_EdY.Pos.X + UI.DG_EdY.Pos.W + 16, ty + 24)
        UI.DG_L_Res.Move(rc.X + 12, ty + 62)

        sy := ty + 120 + 10
        UI.DG_GB_Stats.Move(rc.X, sy, rc.W)
        UI.DG_L_Stats.Move(rc.X + 12, sy + 26)
        UI.DG_BtnClrStats.Move(rc.X + 12, sy + 60)
        UI.DG_BtnOpenLogs.Move(UI.DG_BtnClrStats.Pos.X + UI.DG_BtnClrStats.Pos.W + 8, sy + 60)
        UI.DG_BtnOpenNative.Move(UI.DG_BtnOpenLogs.Pos.X + UI.DG_BtnOpenLogs.Pos.W + 8, sy + 60)
    } catch {
    }
}

; ====== 内部工具 ======

Diag_FillOutputs() {
    global UI
    UI.DG_DdOut.Delete()
    cnt := 0
    names := []

    try {
        cnt := DX_EnumOutputs()
    } catch {
        cnt := 0
    }

    if (cnt <= 0) {
        UI.DG_DdOut.Add(["（无输出）"])
        UI.DG_DdOut.Value := 1
        return
    }

    i := 0
    loop cnt {
        idx := A_Index - 1
        nm := ""
        try {
            nm := DX_GetOutputName(idx)
        } catch {
            nm := ""
        }
        if (nm = "") {
            nm := "Output#" idx
        }
        names.Push(idx " - " nm)
    }
    UI.DG_DdOut.Add(names)

    ; 选中当前 OutIdx
    sel := 1
    cur := 0
    try {
        cur := gDX.OutIdx
    } catch {
        cur := 0
    }
    i := 0
    for _, row in names {
        i += 1
        p := InStr(row, " - ")
        if (p > 0) {
            left := SubStr(row, 1, p - 1)
            val := Integer(left)
            if (val = cur) {
                sel := i
                break
            }
        }
    }
    UI.DG_DdOut.Value := sel
}

Diag_BuildDXSummary() {
    out := ""
    try {
        en := 0
        rd := 0
        idx := 0
        fps := 0
        name := ""
        l := 0, t := 0, r := 0, b := 0

        try {
            en := gDX.Enabled ? 1 : 0
        } catch {
            en := 0
        }
        ready := 0
        try {
            ready := DX_IsReady()
        } catch {
            ready := 0
        }
        try {
            idx := gDX.OutIdx
            fps := gDX.FPS
            name := gDX.MonName
            l := gDX.L
            t := gDX.T
            r := gDX.R
            b := gDX.B
        } catch {
        }

        out .= "Enabled: " en "`r`n"
        out .= "Ready: " ready "`r`n"
        out .= "OutIdx: " idx "  Name: " name "`r`n"
        out .= "Rect: (" l "," t ") - (" r "," b ")" "`r`n"
        out .= "FPS: " fps "`r`n"
    } catch {
        out := "读取 DXGI 状态失败。"
    }
    return out
}

Diag_BuildROISummary() {
    txt := ""
    try {
        en := 0
        try {
            en := gROI.enabled ? 1 : 0
        } catch {
            en := 0
        }
        cnt := 0
        try {
            cnt := gROI.rects.Length
        } catch {
            cnt := 0
        }
        txt .= "ROI Enabled: " en "  Rects: " cnt
        if (cnt >= 1) {
            try {
                r := gROI.rects[1]
                txt .= "  First: (" r.L "," r.T ")  " r.W "x" r.H
            } catch {
            }
        }
    } catch {
        txt := "读取 ROI 状态失败。"
    }
    return txt
}

Diag_BuildStatsSummary() {
    s := ""
    try {
        dx := 0, roi := 0, gdi := 0
        try {
            dx := gDX.Stats.Dx
            roi := gDX.Stats.Roi
            gdi := gDX.Stats.Gdi
        } catch {
        }
        s := "Path Hits => DXGI: " dx "   ROI: " roi "   GDI: " gdi
    } catch {
        s := "读取统计失败。"
    }
    return s
}

; ====== 事件处理 ======

Diag_OnRefresh(*) {
    try {
        UI.DG_Info.Value := Diag_BuildDXSummary()
    } catch {
    }
    try {
        UI.DG_ROI_Info.Text := Diag_BuildROISummary()
    } catch {
    }
    try {
        UI.DG_L_Stats.Text := Diag_BuildStatsSummary()
    } catch {
    }
}

Diag_OnApplyOutput(*) {
    sel := UI.DG_DdOut.Value
    if (sel < 1) {
        return
    }
    txt := UI.DG_DdOut.Text
    idx := 0
    try {
        p := InStr(txt, " - ")
        if (p > 0) {
            left := SubStr(txt, 1, p - 1)
            idx := Integer(left)
        } else {
            idx := Integer(txt)
        }
    } catch {
        idx := 0
    }

    ok := 0
    try {
        ok := Dup_SelectOutputIdx(idx)
    } catch {
        ok := 0
    }
    if (ok = 1) {
        Notify("输出已切换到 #" idx)
    } else {
        Notify("切换失败（可能 DXGI 未准备）")
    }
    Diag_OnRefresh()
}

Diag_OnROISnap(*) {
    try {
        Pixel_ROI_BeginSnapshot()
        Notify("已抓取 ROI 快照")
    } catch {
        Notify("抓取 ROI 失败")
    }
    Diag_OnRefresh()
}

Diag_OnROIAuto(*) {
    global App
    ok := false
    try {
        ok := Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
        ok := false
    }
    if (ok) {
        Notify("已根据配置重建 ROI")
    } else {
        Notify("重建 ROI 失败或未满足条件")
    }
    Diag_OnRefresh()
}

Diag_OnPick(*) {
    x := 0
    y := 0
    try {
        if (UI.DG_EdX.Value != "") {
            x := Integer(UI.DG_EdX.Value)
        }
        if (UI.DG_EdY.Value != "") {
            y := Integer(UI.DG_EdY.Value)
        }
    } catch {
        x := 0
        y := 0
    }

    ; 使用帧缓存路径：先开一帧，再取色
    c := 0
    try {
        Pixel_FrameBegin()
        c := Pixel_FrameGet(x, y)
    } catch {
        try {
            c := PixelGetColor(x, y, "RGB")
        } catch {
            c := 0
        }
    }
    hex := ""
    try {
        hex := Pixel_ColorToHex(c)
    } catch {
        hex := "0x000000"
    }
    try {
        UI.DG_L_Res.Text := "Hex: " hex "    (X=" x ", Y=" y ")"
    } catch {
    }
}

Diag_OnClearStats(*) {
    try {
        gDX.Stats.Dx := 0
        gDX.Stats.Roi := 0
        gDX.Stats.Gdi := 0
        gDX.Stats.LastLog := 0
        Notify("统计已清零")
    } catch {
        Notify("统计清零失败")
    }
    Diag_OnRefresh()
}

Diag_OnOpenLogs(*) {
    dir := A_ScriptDir "\Logs"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox "无法打开目录：" dir
    }
}

Diag_OnOpenNative(*) {
    ; 原生日志在 %TEMP%\dxgi_dup_native.log
    path := ""
    try {
        tmp := A_Temp
        path := tmp "\dxgi_dup_native.log"
    } catch {
        path := ""
    }
    if (path = "") {
        return
    }
    try {
        Run path
    } catch {
        MsgBox "无法打开日志：" path
    }
}