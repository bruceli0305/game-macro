#Requires AutoHotkey v2

; 工具 -> 随机规则触发

Page_RandomRules_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ===== 上半：当前规则摘要 =====
    infoH := 150
    UI.RR_GB_Info := UI.Main.Add("GroupBox"
        , Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, infoH)
        , "当前规则摘要")
    page.Controls.Push(UI.RR_GB_Info)

    UI.RR_Info := UI.Main.Add("Edit"
        , Format("x{} y{} w{} h{} ReadOnly"
            , rc.X + 12, rc.Y + 26, rc.W - 24, infoH - 34))
    page.Controls.Push(UI.RR_Info)

    ; ===== 中间：随机参数 =====
    cfgY := rc.Y + infoH + 10
    cfgH := 230
    UI.RR_GB_Cfg := UI.Main.Add("GroupBox"
        , Format("x{} y{} w{} h{}", rc.X, cfgY, rc.W, cfgH)
        , "随机参数")
    page.Controls.Push(UI.RR_GB_Cfg)

    y := cfgY + 26

    ; 规则选择模式
    UI.RR_Lab_Mode := UI.Main.Add("Text"
        , Format("x{} y{} w100 Right", rc.X + 12, y)
        , "规则选择：")
    page.Controls.Push(UI.RR_Lab_Mode)

    UI.RR_DD_Mode := UI.Main.Add("DropDownList"
        , "x+6 w260"
        , ["每次随机选择启用规则", "轮次洗牌（本轮用完再洗牌）"])
    page.Controls.Push(UI.RR_DD_Mode)

    ; 启动延迟
    y += 34
    UI.RR_Lab_StartDelay := UI.Main.Add("Text"
        , Format("x{} y{} w100 Right", rc.X + 12, y)
        , "启动延迟(ms)：")
    page.Controls.Push(UI.RR_Lab_StartDelay)

    UI.RR_Ed_StartDelay := UI.Main.Add("Edit", "x+6 w100 Number")
    page.Controls.Push(UI.RR_Ed_StartDelay)

    ; 规则间隔
    y += 34
    UI.RR_Lab_RuleInt := UI.Main.Add("Text"
        , Format("x{} y{} w140 Right", rc.X + 12, y)
        , "规则间隔(ms)：")
    page.Controls.Push(UI.RR_Lab_RuleInt)

    UI.RR_Ed_RuleMin := UI.Main.Add("Edit", "x+6 w80 Number")
    page.Controls.Push(UI.RR_Ed_RuleMin)

    UI.RR_Lab_RuleTo := UI.Main.Add("Text", "x+6 w20 Center", "~")
    page.Controls.Push(UI.RR_Lab_RuleTo)

    UI.RR_Ed_RuleMax := UI.Main.Add("Edit", "x+6 w80 Number")
    page.Controls.Push(UI.RR_Ed_RuleMax)

    ; 动作随机间隔
    y += 34
    UI.RR_Chk_ActRand := UI.Main.Add("CheckBox"
        , Format("x{} y{} w200", rc.X + 20, y)
        , "启用随机动作间隔")
    page.Controls.Push(UI.RR_Chk_ActRand)

    y += 30
    UI.RR_Lab_ActInt := UI.Main.Add("Text"
        , Format("x{} y{} w140 Right", rc.X + 12, y)
        , "动作间隔(ms)：")
    page.Controls.Push(UI.RR_Lab_ActInt)

    UI.RR_Ed_ActMin := UI.Main.Add("Edit", "x+6 w80 Number")
    page.Controls.Push(UI.RR_Ed_ActMin)

    UI.RR_Lab_ActTo := UI.Main.Add("Text", "x+6 w20 Center", "~")
    page.Controls.Push(UI.RR_Lab_ActTo)

    UI.RR_Ed_ActMax := UI.Main.Add("Edit", "x+6 w80 Number")
    page.Controls.Push(UI.RR_Ed_ActMax)

    ; ===== 底部：控制按钮 + 状态 =====
    ctrlY := cfgY + cfgH + 16

    UI.RR_BtnSave := UI.Main.Add("Button"
        , Format("x{} y{} w100 h28", rc.X + 12, ctrlY)
        , "保存设置")
    page.Controls.Push(UI.RR_BtnSave)

    UI.RR_BtnStart := UI.Main.Add("Button", "x+8 w100 h28", "开始")
    page.Controls.Push(UI.RR_BtnStart)

    UI.RR_BtnStop := UI.Main.Add("Button", "x+8 w100 h28", "停止")
    page.Controls.Push(UI.RR_BtnStop)

    UI.RR_Lab_State := UI.Main.Add("Text"
        , "x+20 w260 h28 0x200"
        , "状态：-")
    page.Controls.Push(UI.RR_Lab_State)

    ; 事件绑定
    UI.RR_BtnSave.OnEvent("Click", RR_UI_OnSave)
    UI.RR_BtnStart.OnEvent("Click", RR_UI_OnStart)
    UI.RR_BtnStop.OnEvent("Click", RR_UI_OnStop)

    RR_UI_RefreshAll()
}

Page_RandomRules_Layout(rc) {
    try {
        infoH := 150
        UI_MoveSafe(UI.RR_GB_Info, rc.X, rc.Y, rc.W, infoH)
        UI_MoveSafe(UI.RR_Info, rc.X + 12, rc.Y + 26, rc.W - 24, infoH - 34)

        cfgY := rc.Y + infoH + 10
        cfgH := 230
        UI_MoveSafe(UI.RR_GB_Cfg, rc.X, cfgY, rc.W, cfgH)

        y := cfgY + 26
        UI_MoveSafe(UI.RR_Lab_Mode, rc.X + 12, y)
        UI_MoveSafe(UI.RR_DD_Mode, UI.RR_Lab_Mode.Pos.X + UI.RR_Lab_Mode.Pos.W + 6, y)

        y += 34
        UI_MoveSafe(UI.RR_Lab_StartDelay, rc.X + 12, y)
        UI_MoveSafe(UI.RR_Ed_StartDelay, UI.RR_Lab_StartDelay.Pos.X + UI.RR_Lab_StartDelay.Pos.W + 6, y)

        y += 34
        UI_MoveSafe(UI.RR_Lab_RuleInt, rc.X + 12, y)
        UI_MoveSafe(UI.RR_Ed_RuleMin, UI.RR_Lab_RuleInt.Pos.X + UI.RR_Lab_RuleInt.Pos.W + 6, y)
        UI_MoveSafe(UI.RR_Lab_RuleTo,  UI.RR_Ed_RuleMin.Pos.X + UI.RR_Ed_RuleMin.Pos.W + 6, y)
        UI_MoveSafe(UI.RR_Ed_RuleMax,  UI.RR_Lab_RuleTo.Pos.X + UI.RR_Lab_RuleTo.Pos.W + 6, y)

        y += 34
        UI_MoveSafe(UI.RR_Chk_ActRand, rc.X + 20, y)

        y += 30
        UI_MoveSafe(UI.RR_Lab_ActInt, rc.X + 12, y)
        UI_MoveSafe(UI.RR_Ed_ActMin,  UI.RR_Lab_ActInt.Pos.X + UI.RR_Lab_ActInt.Pos.W + 6, y)
        UI_MoveSafe(UI.RR_Lab_ActTo,  UI.RR_Ed_ActMin.Pos.X + UI.RR_Ed_ActMin.Pos.W + 6, y)
        UI_MoveSafe(UI.RR_Ed_ActMax,  UI.RR_Lab_ActTo.Pos.X + UI.RR_Lab_ActTo.Pos.W + 6, y)

        ctrlY := cfgY + cfgH + 16
        UI_MoveSafe(UI.RR_BtnSave,  rc.X + 12, ctrlY)
        UI_MoveSafe(UI.RR_BtnStart, UI.RR_BtnSave.Pos.X + UI.RR_BtnSave.Pos.W + 8, ctrlY)
        UI_MoveSafe(UI.RR_BtnStop,  UI.RR_BtnStart.Pos.X + UI.RR_BtnStart.Pos.W + 8, ctrlY)
        UI_MoveSafe(UI.RR_Lab_State
            , UI.RR_BtnStop.Pos.X + UI.RR_BtnStop.Pos.W + 20
            , ctrlY
            , rc.W - (UI.RR_BtnStop.Pos.X - rc.X) - 200
            , 28)
    } catch {
    }
}

Page_RandomRules_OnEnter(*) {
    RR_UI_RefreshAll()
}

;================ 工具函数与事件 =================

RR_UI_RefreshAll() {
    RR_UI_LoadConfigForCurrentProfile()
    RR_UI_RefreshInfo()
    RR_UI_RefreshControlsFromRR()
    RR_UI_RefreshState()
}

RR_UI_LoadConfigForCurrentProfile() {
    global App
    name := ""
    try {
        if IsObject(App) && App.Has("CurrentProfile") {
            name := App["CurrentProfile"]
        }
    } catch {
        name := ""
    }
    if (name = "") {
        return
    }
    try {
        RandomRules_LoadConfig(name)
    } catch {
    }
}

RR_UI_RefreshInfo() {
    global App, UI

    txt := ""
    profName := ""
    try {
        if IsObject(App) && App.Has("CurrentProfile") {
            profName := App["CurrentProfile"]
        }
    } catch {
        profName := ""
    }

    if (profName = "") {
        txt := "当前配置：<未选择>`r`n规则总数：0`r`n启用规则：0"
        try {
            UI.RR_Info.Value := txt
        } catch {
        }
        return
    }

    total := 0
    enabled := 0

    try {
        if (App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            if (IsObject(App["ProfileData"].Rules)) {
                i := 1
                while (i <= App["ProfileData"].Rules.Length) {
                    r := App["ProfileData"].Rules[i]
                    total := total + 1
                    en := 0
                    try {
                        en := (HasProp(r, "Enabled") && r.Enabled) ? 1 : 0
                    } catch {
                        en := 0
                    }
                    if (en) {
                        enabled := enabled + 1
                    }
                    i := i + 1
                }
            }
        }
    } catch {
    }

    txt := "当前配置：" profName "`r`n规则总数：" total "`r`n启用规则：" enabled

    try {
        UI.RR_Info.Value := txt
    } catch {
    }
}

RR_UI_RefreshControlsFromRR() {
    global UI, RR

    ; 模式
    try {
        if (RR.Mode = "ShuffleRound") {
            UI.RR_DD_Mode.Value := 2
        } else {
            UI.RR_DD_Mode.Value := 1
        }
    } catch {
    }

    ; 启动延迟
    try {
        UI.RR_Ed_StartDelay.Value := RR.StartDelayMs
    } catch {
    }

    ; 规则间隔
    try {
        UI.RR_Ed_RuleMin.Value := RR.RuleMinMs
    } catch {
    }
    try {
        UI.RR_Ed_RuleMax.Value := RR.RuleMaxMs
    } catch {
    }

    ; 动作随机
    try {
        UI.RR_Chk_ActRand.Value := (RR.ActRandEnabled ? 1 : 0)
    } catch {
    }

    try {
        UI.RR_Ed_ActMin.Value := RR.ActMinMs
    } catch {
    }
    try {
        UI.RR_Ed_ActMax.Value := RR.ActMaxMs
    } catch {
    }
}

RR_UI_ReadControlsToRR() {
    global UI, RR

    ; 模式
    modeIdx := 1
    try {
        modeIdx := UI.RR_DD_Mode.Value
    } catch {
        modeIdx := 1
    }
    try {
        if (modeIdx = 2) {
            RR.Mode := "ShuffleRound"
        } else {
            RR.Mode := "RandomEach"
        }
    } catch {
        RR.Mode := "RandomEach"
    }

    ; 启动延迟
    v := 0
    try {
        v := (UI.RR_Ed_StartDelay.Value != "") ? Integer(UI.RR_Ed_StartDelay.Value) : 0
        RR.StartDelayMs := v
    } catch {
    }

    ; 规则间隔
    try {
        v := (UI.RR_Ed_RuleMin.Value != "") ? Integer(UI.RR_Ed_RuleMin.Value) : 0
        RR.RuleMinMs := v
    } catch {
    }

    try {
        v := (UI.RR_Ed_RuleMax.Value != "") ? Integer(UI.RR_Ed_RuleMax.Value) : RR.RuleMinMs
        RR.RuleMaxMs := v
    } catch {
    }

    ; 动作间隔
    try {
        RR.ActRandEnabled := (UI.RR_Chk_ActRand.Value ? 1 : 0)
    } catch {
        RR.ActRandEnabled := 1
    }

    try {
        v := (UI.RR_Ed_ActMin.Value != "") ? Integer(UI.RR_Ed_ActMin.Value) : 0
        RR.ActMinMs := v
    } catch {
    }

    try {
        v := (UI.RR_Ed_ActMax.Value != "") ? Integer(UI.RR_Ed_ActMax.Value) : RR.ActMinMs
        RR.ActMaxMs := v
    } catch {
    }

    RandomRules_NormalizeRanges()
    RR_UI_RefreshControlsFromRR()
}

RR_UI_RefreshState() {
    global UI, RR

    txt := "状态："
    if (RR.Running) {
        txt .= "运行中"
    } else {
        txt .= "已停止"
    }
    try {
        UI.RR_Lab_State.Text := txt
    } catch {
    }
}

RR_UI_OnSave(*) {
    global App

    RR_UI_ReadControlsToRR()

    name := ""
    try {
        if IsObject(App) && App.Has("CurrentProfile") {
            name := App["CurrentProfile"]
        }
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "当前未选择配置，无法保存随机设置。"
        return
    }

    ok := true
    try {
        RandomRules_SaveConfig(name)
    } catch {
        ok := false
    }

    if (!ok) {
        MsgBox "保存随机设置失败。"
        return
    }

    Notify("随机规则参数已保存")
}

RR_UI_OnStart(*) {
    global App

    RR_UI_ReadControlsToRR()

    name := ""
    try {
        if IsObject(App) && App.Has("CurrentProfile") {
            name := App["CurrentProfile"]
        }
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "当前未选择配置，无法启动随机规则触发。"
        return
    }

    try {
        RandomRules_SaveConfig(name)
    } catch {
        ; 保存失败不阻止启动
    }

    ok := false
    try {
        ok := RandomRules_Start()
    } catch {
        ok := false
    }

    RR_UI_RefreshState()
    if (!ok) {
        return
    }
}

RR_UI_OnStop(*) {
    try {
        RandomRules_Stop()
    } catch {
    }
    RR_UI_RefreshState()
}