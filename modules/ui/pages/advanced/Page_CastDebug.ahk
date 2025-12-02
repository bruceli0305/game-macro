#Requires AutoHotkey v2

; 高级 → 技能调试 / 施法条
; 负责编辑 General.CastBar* 与 General.CastDebug* 字段
; 以及打开/关闭调试窗口

Page_CastDebug_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ==== 施法条配置 ====
    gbH := 230
    UI.CD_GB_Cast := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, gbH), "施法条配置")
    page.Controls.Push(UI.CD_GB_Cast)

    xLabel := rc.X + 32
    rowH   := 32
    yLine  := rc.Y + 32

    ; 启用
    UI.CD_ChkEnable := UI.Main.Add("CheckBox", Format("x{} y{} w260", xLabel, yLine), "启用施法条检测")
    page.Controls.Push(UI.CD_ChkEnable)

    ; 坐标 X/Y（独立一行）
    y2 := yLine + rowH
    UI.CD_LblX := UI.Main.Add("Text", Format("x{} y{} w70 Right", xLabel, y2 + 8), "坐标X：")
    page.Controls.Push(UI.CD_LblX)
    UI.CD_EdX := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.CD_EdX)

    UI.CD_LblY := UI.Main.Add("Text", "x+12 w70 Right", "坐标Y：")
    page.Controls.Push(UI.CD_LblY)
    UI.CD_EdY := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.CD_EdY)

    ; 颜色 + 容差（独立一行）
    y3 := y2 + rowH
    UI.CD_LblColor := UI.Main.Add("Text", Format("x{} y{} w70 Right", xLabel, y3 + 4), "颜色：")
    page.Controls.Push(UI.CD_LblColor)
    UI.CD_EdColor := UI.Main.Add("Edit", "x+6 w120")
    page.Controls.Push(UI.CD_EdColor)

    UI.CD_LblTol := UI.Main.Add("Text", "x+12 w70 Right", "容差：")
    page.Controls.Push(UI.CD_LblTol)
    UI.CD_EdTol := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.CD_EdTol)

    ; 拾取按钮单独一行
    y4 := y3 + rowH
    UI.CD_BtnPick := UI.Main.Add("Button", Format("x{} y{} w140 h24", xLabel + 90 + 6, y4), "拾取施法条像素")
    page.Controls.Push(UI.CD_BtnPick)

    ; 忽略延时 / 调试日志，各自一行，避免右侧挤压
    y5 := y4 + rowH
    UI.CD_ChkIgnore := UI.Main.Add("CheckBox", Format("x{} y{} w360", xLabel, y5)
        , "忽略规则动作延时 (DelayMs / ActionGapMs)")
    page.Controls.Push(UI.CD_ChkIgnore)

    y6 := y5 + rowH
    UI.CD_ChkDebugLog := UI.Main.Add("CheckBox", Format("x{} y{} w360", xLabel, y6)
        , "规则结束时写技能状态日志")
    page.Controls.Push(UI.CD_ChkDebugLog)

    ; ==== 调试窗口配置 ====
    gy2 := rc.Y + gbH + 10
    gb2H := 140
    UI.CD_GB_Debug := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, gy2, rc.W, gb2H), "调试窗口配置")
    page.Controls.Push(UI.CD_GB_Debug)

    x2Label := rc.X + 16
    yD1     := gy2 + 26

    ; 热键（单行）
    UI.CD_LblHotkey := UI.Main.Add("Text", Format("x{} y{} w90 Right", x2Label, yD1 + 4), "调试热键：")
    page.Controls.Push(UI.CD_LblHotkey)
    UI.CD_EdHotkey := UI.Main.Add("Edit", "x+6 w160")
    page.Controls.Push(UI.CD_EdHotkey)

    ; 置顶单独一行
    yD2 := yD1 + rowH
    UI.CD_ChkTopmost := UI.Main.Add("CheckBox", Format("x{} y{} w160", x2Label, yD2), "调试窗口置顶")
    page.Controls.Push(UI.CD_ChkTopmost)

    ; 透明度单独一行
    yD3 := yD2 + rowH
    UI.CD_LblAlpha := UI.Main.Add("Text", Format("x{} y{} w90 Right", x2Label, yD3 + 4), "透明度(0-255)：")
    page.Controls.Push(UI.CD_LblAlpha)
    UI.CD_EdAlpha := UI.Main.Add("Edit", "x+6 w80 Number")
    page.Controls.Push(UI.CD_EdAlpha)

    ; 三个按钮放在分组框外部，位于分组框下方，左对齐
    btnY := gy2 + gb2H + 10
    xButton := x2Label ; 与调试窗口配置分组内控件左对齐
    UI.CD_BtnApply := UI.Main.Add("Button", Format("x{} y{} w120 h28", xButton, btnY), "应用配置")
    page.Controls.Push(UI.CD_BtnApply)
    UI.CD_BtnShow := UI.Main.Add("Button", Format("x{} y{} w120 h28", xButton + 120 + 8, btnY), "打开调试窗口")
    page.Controls.Push(UI.CD_BtnShow)
    UI.CD_BtnHide := UI.Main.Add("Button", Format("x{} y{} w120 h28", xButton + (120 + 8) * 2, btnY), "关闭调试窗口")
    page.Controls.Push(UI.CD_BtnHide)

    ; 事件
    UI.CD_BtnPick.OnEvent("Click", CastDebug_OnPickCastPixel)
    UI.CD_BtnApply.OnEvent("Click", CastDebug_OnApply)
    UI.CD_BtnShow.OnEvent("Click", CastDebug_OnShow)
    UI.CD_BtnHide.OnEvent("Click", CastDebug_OnHide)

    ; 初次进入时加载一次
    CastDebug_LoadFromApp()
}

Page_CastDebug_Layout(rc) {
    try {
        gbH := 230
        UI.CD_GB_Cast.Move(rc.X, rc.Y, rc.W, gbH)

        xLabel := rc.X + 32
        rowH   := 32
        yLine  := rc.Y + 32

        UI.CD_ChkEnable.Move(xLabel, yLine, 260)

        y2 := yLine + rowH
        UI.CD_LblX.Move(xLabel, y2 + 8, 70)
        UI.CD_EdX.Move(UI.CD_LblX.Pos.X + UI.CD_LblX.Pos.W + 6, y2, 80)
        UI.CD_LblY.Move(UI.CD_EdX.Pos.X + UI.CD_EdX.Pos.W + 12, y2 + 4, 40)
        UI.CD_EdY.Move(UI.CD_LblY.Pos.X + UI.CD_LblY.Pos.W + 6, y2, 80)

        y3 := y2 + rowH
        UI.CD_LblColor.Move(xLabel, y3 + 4, 70)
        UI.CD_EdColor.Move(UI.CD_LblColor.Pos.X + UI.CD_LblColor.Pos.W + 6, y3, 120)
        UI.CD_LblTol.Move(UI.CD_EdColor.Pos.X + UI.CD_EdColor.Pos.W + 12, y3 + 4, 60)
        UI.CD_EdTol.Move(UI.CD_LblTol.Pos.X + UI.CD_LblTol.Pos.W + 6, y3, 60)

        y4 := y3 + rowH
        UI.CD_BtnPick.Move(UI.CD_LblColor.Pos.X + UI.CD_LblColor.Pos.W + 6, y4, 90, 24)

        y5 := y4 + rowH
        UI.CD_ChkIgnore.Move(xLabel, y5, rc.W - 40)

        y6 := y5 + rowH
        UI.CD_ChkDebugLog.Move(xLabel, y6, rc.W - 40)

        gy2 := rc.Y + gbH + 10
        gb2H := 140
        UI.CD_GB_Debug.Move(rc.X, gy2, rc.W, gb2H)

        x2Label := rc.X + 16
        yD1     := gy2 + 26

        UI.CD_LblHotkey.Move(x2Label, yD1 + 4, 90)
        UI.CD_EdHotkey.Move(UI.CD_LblHotkey.Pos.X + UI.CD_LblHotkey.Pos.W + 6, yD1, 160)

        yD2 := yD1 + rowH
        UI.CD_ChkTopmost.Move(x2Label, yD2, 160)

        yD3 := yD2 + rowH
        UI.CD_LblAlpha.Move(x2Label, yD3 + 4, 90)
        UI.CD_EdAlpha.Move(UI.CD_LblAlpha.Pos.X + UI.CD_LblAlpha.Pos.W + 6, yD3, 80)

        ; 三个按钮放在分组框外部，位于分组框下方，左对齐
        btnY := gy2 + gb2H + 10
        xButton := x2Label ; 与调试窗口配置分组内控件左对齐
        UI.CD_BtnApply.Move(xButton, btnY, 120, 28)
        UI.CD_BtnShow.Move(xButton + 120 + 8, btnY, 120, 28)
        UI.CD_BtnHide.Move(xButton + (120 + 8) * 2, btnY, 120, 28)
    } catch {
    }
}

Page_CastDebug_OnEnter(*) {
    CastDebug_LoadFromApp()
}

CastDebug_LoadFromApp() {
    global App, UI

    if !(IsSet(App) && App.Has("ProfileData")) {
        return
    }
    prof := App["ProfileData"]

    ; CastBar
    cb := Map()
    try {
        cb := prof.CastBar
    } catch {
        cb := Map()
    }

    try {
        UI.CD_ChkEnable.Value := (HasProp(cb, "Enabled") && cb.Enabled) ? 1 : 0
    } catch {
        UI.CD_ChkEnable.Value := 0
    }

    try {
        UI.CD_EdX.Value := HasProp(cb, "X") ? cb.X : 0
    } catch {
        UI.CD_EdX.Value := 0
    }
    try {
        UI.CD_EdY.Value := HasProp(cb, "Y") ? cb.Y : 0
    } catch {
        UI.CD_EdY.Value := 0
    }
    try {
        UI.CD_EdColor.Value := HasProp(cb, "Color") ? cb.Color : "0x000000"
    } catch {
        UI.CD_EdColor.Value := "0x000000"
    }
    try {
        UI.CD_EdTol.Value := HasProp(cb, "Tol") ? cb.Tol : 10
    } catch {
        UI.CD_EdTol.Value := 10
    }

    try {
        UI.CD_ChkIgnore.Value := (HasProp(cb, "IgnoreActionDelay") && cb.IgnoreActionDelay) ? 1 : 0
    } catch {
        UI.CD_ChkIgnore.Value := 0
    }
    try {
        UI.CD_ChkDebugLog.Value := (HasProp(cb, "DebugLog") && cb.DebugLog) ? 1 : 0
    } catch {
        UI.CD_ChkDebugLog.Value := 0
    }

    ; 调试窗口 CastDebug
    cd := Map()
    try {
        cd := prof.CastDebug
    } catch {
        cd := Map()
    }

    try {
        UI.CD_EdHotkey.Value := HasProp(cd, "Hotkey") ? cd.Hotkey : ""
    } catch {
        UI.CD_EdHotkey.Value := ""
    }
    try {
        UI.CD_ChkTopmost.Value := (HasProp(cd, "Topmost") && cd.Topmost) ? 1 : 0
    } catch {
        UI.CD_ChkTopmost.Value := 1
    }
    try {
        UI.CD_EdAlpha.Value := HasProp(cd, "Alpha") ? cd.Alpha : 230
    } catch {
        UI.CD_EdAlpha.Value := 230
    }

    ; 同步调试窗口配置
    try {
        CastDebug_ApplyConfigFromProfile()
    } catch {
    }
}

CastDebug_OnPickCastPixel(*) {
    x := 0
    y := 0
    col := ""
    res := 0
    try {
        res := Pixel_PickPixel()
    } catch {
        res := 0
    }
    if (res) {
        try {
            UI.CD_EdX.Value := res.X
        } catch {
        }
        try {
            UI.CD_EdY.Value := res.Y
        } catch {
        }
        try {
            UI.CD_EdColor.Value := Pixel_ColorToHex(res.Color)
        } catch {
        }
    }
}

CastDebug_OnApply(*) {
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

    ; 读 UI 值
    enable := 0
    try {
        enable := (UI.CD_ChkEnable.Value ? 1 : 0)
    } catch {
        enable := 0
    }

    x := 0
    y := 0
    tol := 10
    color := "0x000000"
    ignore := 0
    dbgLog := 0
    hk := ""
    topmost := 1
    alpha := 230

    try {
        if (UI.CD_EdX.Value != "") {
            x := Integer(UI.CD_EdX.Value)
        }
    } catch {
        x := 0
    }
    try {
        if (UI.CD_EdY.Value != "") {
            y := Integer(UI.CD_EdY.Value)
        }
    } catch {
        y := 0
    }
    try {
        color := Trim(UI.CD_EdColor.Value)
        if (color != "") {
            color := Pixel_ColorToHex(Pixel_HexToInt(color))
        } else {
            color := "0x000000"
        }
    } catch {
        color := "0x000000"
    }
    try {
        if (UI.CD_EdTol.Value != "") {
            tol := Integer(UI.CD_EdTol.Value)
        } else {
            tol := 10
        }
    } catch {
        tol := 10
    }

    try {
        ignore := (UI.CD_ChkIgnore.Value ? 1 : 0)
    } catch {
        ignore := 0
    }
    try {
        dbgLog := (UI.CD_ChkDebugLog.Value ? 1 : 0)
    } catch {
        dbgLog := 0
    }

    try {
        hk := Trim(UI.CD_EdHotkey.Value)
    } catch {
        hk := ""
    }
    try {
        topmost := (UI.CD_ChkTopmost.Value ? 1 : 0)
    } catch {
        topmost := 1
    }
    try {
        if (UI.CD_EdAlpha.Value != "") {
            alpha := Integer(UI.CD_EdAlpha.Value)
        } else {
            alpha := 230
        }
    } catch {
        alpha := 230
    }
    if (alpha < 0) {
        alpha := 0
    }
    if (alpha > 255) {
        alpha := 255
    }

    ; 写回文件夹模型
    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch {
        MsgBox "加载配置失败。"
        return
    }

    g := Map()
    try {
        g := p["General"]
    } catch {
        g := Map()
    }

    try {
        g["CastBarEnabled"] := enable
    } catch {
    }
    try {
        g["CastBarX"] := x
    } catch {
    }
    try {
        g["CastBarY"] := y
    } catch {
    }
    try {
        g["CastBarColor"] := color
    } catch {
    }
    try {
        g["CastBarTol"] := tol
    } catch {
    }
    try {
        g["CastBarDebugLog"] := dbgLog
    } catch {
    }
    try {
        g["CastBarIgnoreActionDelay"] := ignore
    } catch {
    }

    try {
        g["CastDebugHotkey"] := hk
    } catch {
    }
    try {
        g["CastDebugTopmost"] := topmost
    } catch {
    }
    try {
        g["CastDebugAlpha"] := alpha
    } catch {
    }

    try {
        p["General"] := g
    } catch {
    }

    ok := false
    try {
        SaveModule_General(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    ; 重新规范化到运行时
    try {
        rt := PM_ToRuntime(p)
        App["ProfileData"] := rt
    } catch {
        MsgBox "保存成功，但重新加载失败。"
        return
    }

    ; 重建 CastEngine 和调试窗口热键/配置
    try {
        CastEngine_InitFromProfile()
    } catch {
    }
    try {
        if HasProp(App["ProfileData"], "CastDebug") {
            CastDebug_RebindHotkey(App["ProfileData"].CastDebug.Hotkey)
            CastDebug_ApplyConfigFromProfile()
        }
    } catch {
    }

    Notify("施法条与调试配置已保存")
}

CastDebug_OnShow(*) {
    try {
        CastDebug_Show()
    } catch {
    }
}

CastDebug_OnHide(*) {
    try {
        CastDebug_Hide()
    } catch {
    }
}