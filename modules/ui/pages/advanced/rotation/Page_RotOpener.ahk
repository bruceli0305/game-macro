; modules\ui\pages\advanced\rotation\Page_RotOpener.ahk
#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Opener.ahk"

; 轮换配置 - 起手页（嵌入主界面，绝对布局 + 运行时获取 cfg）
Page_RotOpener_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if !IsSet(App) || !App.Has("ProfileData") {
        UI.RO_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        page.Controls.Push(UI.RO_Empty)
        return
    }

    ; 确保 cfg 完整
    cfg := Page_RotOpener_GetCfg()

    ; 顶部区域
    UI.RO_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w160", rc.X, rc.Y + 8), "启用起手")
    page.Controls.Push(UI.RO_cbEnable)

    UI.RO_labMax := UI.Main.Add("Text", Format("x{} y{} w110 Right", rc.X, rc.Y + 44), "最大时长(ms)：")
    UI.RO_edMax  := UI.Main.Add("Edit",  "x+6 w120 Number Center")
    page.Controls.Push(UI.RO_labMax), page.Controls.Push(UI.RO_edMax)

    UI.RO_labThr := UI.Main.Add("Text", "x+20 w80 Right", "线程：")
    UI.RO_ddThr  := UI.Main.Add("DropDownList", "x+6 w200")
    page.Controls.Push(UI.RO_labThr), page.Controls.Push(UI.RO_ddThr)

    ; Watch 区域
    UI.RO_labW := UI.Main.Add("Text", Format("x{} y{}", rc.X, rc.Y + 86), "Watch（技能计数/黑框确认）：")
    page.Controls.Push(UI.RO_labW)

    UI.RO_lvW := UI.Main.Add("ListView", Format("x{} y{} w{} r7 +Grid", rc.X, rc.Y + 108, Max(560, rc.W - 84 - 8 - 20)), ["技能","Require","VerifyBlack"])
    page.Controls.Push(UI.RO_lvW)

    ; 右侧按钮列（先放置，Layout 中精确定位）
    UI.RO_btnWAdd  := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnWEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnWDel  := UI.Main.Add("Button", "w84", "删除")
    for ctl in [UI.RO_btnWAdd, UI.RO_btnWEdit, UI.RO_btnWDel] {
        page.Controls.Push(ctl)
    }

    ; Steps 区域（同样绝对布局）
    UI.RO_labS := UI.Main.Add("Text", "w200", "Steps（按序执行）：")
    page.Controls.Push(UI.RO_labS)

    UI.RO_lvS := UI.Main.Add("ListView", "w700 r8 +Grid"
        , ["序","类型","详情","就绪","预延时","按住","验证","超时","时长"])
    page.Controls.Push(UI.RO_lvS)

    UI.RO_btnSAdd  := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnSEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnSDel  := UI.Main.Add("Button", "w84", "删除")
    UI.RO_btnSUp   := UI.Main.Add("Button", "w84", "上移")
    UI.RO_btnSDn   := UI.Main.Add("Button", "w84", "下移")
    for ctl in [UI.RO_btnSAdd, UI.RO_btnSEdit, UI.RO_btnSDel, UI.RO_btnSUp, UI.RO_btnSDn] {
        page.Controls.Push(ctl)
    }

    ; 底部保存
    UI.RO_btnSave := UI.Main.Add("Button", "w120", "保存起手")
    page.Controls.Push(UI.RO_btnSave)

    ; 填充数据
    Page_RotOpener_Refresh()

    ; 事件（全部通过包装函数在运行时获取最新 cfg）
    UI.RO_btnWAdd.OnEvent("Click", Page_RotOpener_OnWAdd)
    UI.RO_btnWEdit.OnEvent("Click", Page_RotOpener_OnWEdit)
    UI.RO_btnWDel.OnEvent("Click", Page_RotOpener_OnWDel)
    UI.RO_lvW.OnEvent("DoubleClick", Page_RotOpener_OnWEdit)

    UI.RO_btnSAdd.OnEvent("Click", Page_RotOpener_OnSAdd)
    UI.RO_btnSEdit.OnEvent("Click", Page_RotOpener_OnSEdit)
    UI.RO_btnSDel.OnEvent("Click", Page_RotOpener_OnSDel)
    UI.RO_btnSUp.OnEvent("Click", (*) => Page_RotOpener_OnSMove(-1))
    UI.RO_btnSDn.OnEvent("Click", (*) => Page_RotOpener_OnSMove(1))
    UI.RO_lvS.OnEvent("DoubleClick", Page_RotOpener_OnSEdit)

    UI.RO_btnSave.OnEvent("Click", Page_RotOpener_OnSave)
}

Page_RotOpener_Layout(rc) {
    try {
        x := rc.X
        y := rc.Y

        ; 顶部第二行控件自动横向铺开，无需 Move

        ; Watch 区域布局
        btnW := 84
        gap  := 8
        minW := 560
        listW := Max(minW, rc.W - btnW - gap - 20)
        UI_MoveSafe(UI.RO_labW, x, y + 86)
        UI.RO_lvW.Move(x, y + 108, listW)
        UI.RO_lvW.GetPos(&lx, &ly, &lw, &lh)
        btnX := lx + lw + gap
        UI_MoveSafe(UI.RO_btnWAdd,  btnX, ly)
        UI_MoveSafe(UI.RO_btnWEdit, btnX, ly + 34)
        UI_MoveSafe(UI.RO_btnWDel,  btnX, ly + 68)

        ; Steps 区域紧随 Watch
        stepsLabelY := ly + lh + 16
        UI_MoveSafe(UI.RO_labS, x, stepsLabelY)
        ; Steps 列表高度占用到底部上方 56px
        UI.RO_lvS.Move(x, stepsLabelY + 16, listW, rc.Y + rc.H - (stepsLabelY + 16) - 56)
        UI.RO_lvS.GetPos(&sx, &sy, &sw, &sh)
        UI_MoveSafe(UI.RO_btnSAdd,  btnX, sy)
        UI_MoveSafe(UI.RO_btnSEdit, btnX, sy + 34)
        UI_MoveSafe(UI.RO_btnSDel,  btnX, sy + 68)
        UI_MoveSafe(UI.RO_btnSUp,   btnX, sy + 102)
        UI_MoveSafe(UI.RO_btnSDn,   btnX, sy + 136)

        ; 保存按钮靠底
        UI_MoveSafe(UI.RO_btnSave, x, rc.Y + rc.H - 36)
    } catch {
    }
}

Page_RotOpener_OnEnter(*) {
    Page_RotOpener_Refresh()
}

; 统一获取最新 cfg，保证与旧弹窗一致
Page_RotOpener_GetCfg() {
    global App
    if !IsSet(App) || !App.Has("ProfileData") {
        return {}
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    REUI_Opener_Ensure(&cfg)
    prof.Rotation := cfg
    return cfg
}

; 填充
Page_RotOpener_Refresh() {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if !IsObject(cfg) {
        return
    }
    ; 顶部
    UI.RO_cbEnable.Value := cfg.Opener.Enabled ? 1 : 0
    UI.RO_edMax.Value := HasProp(cfg.Opener,"MaxDurationMs") ? cfg.Opener.MaxDurationMs : 4000
    Page_RotOpener_FillThreads(cfg)
    ; 列表
    REUI_Opener_FillWatch(UI.RO_lvW, cfg)
    REUI_Opener_FillSteps(UI.RO_lvS, cfg)
}

; 线程下拉（含兜底）
Page_RotOpener_FillThreads(cfg) {
    global UI, App
    ; 清空
    try DllCall("user32\SendMessageW", "ptr", UI.RO_ddThr.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)
    thrNames := []
    thrIds   := []
    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")
            && IsObject(App["ProfileData"].Threads) && App["ProfileData"].Threads.Length) {
            for _, th in App["ProfileData"].Threads {
                if (HasProp(th, "Name") && HasProp(th, "Id")) {
                    thrNames.Push(th.Name)
                    thrIds.Push(th.Id)
                }
            }
        }
    }
    if (thrNames.Length = 0) {
        thrNames := ["默认线程"]
        thrIds   := [1]
    }
    UI.RO_thrIds := thrIds
    UI.RO_ddThr.Add(thrNames)
    curTid := HasProp(cfg.Opener,"ThreadId") ? cfg.Opener.ThreadId : 1
    pos := 1
    for i, id in UI.RO_thrIds {
        if (id = curTid) {
            pos := i
            break
        }
    }
    UI.RO_ddThr.Value := pos
    UI.RO_ddThr.Enabled := true
}

; 事件包装：运行时取 cfg，避免闭包引用旧对象
Page_RotOpener_OnWAdd(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchAdd(UI.Main, cfg, UI.RO_lvW)
    }
}
Page_RotOpener_OnWEdit(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchEdit(UI.Main, cfg, UI.RO_lvW)
    }
}
Page_RotOpener_OnWDel(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchDel(cfg, UI.RO_lvW)
    }
}

Page_RotOpener_OnSAdd(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepAdd(UI.Main, cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSEdit(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepEdit(UI.Main, cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSDel(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepDel(cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSMove(dir) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepMove(cfg, UI.RO_lvS, dir)
    }
}

Page_RotOpener_OnSave(*) {
    global UI, App
    if !IsSet(App) || !App.Has("ProfileData") {
        MsgBox "未加载配置，无法保存。"
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    REUI_Opener_Ensure(&cfg)

    cfg.Opener.Enabled := UI.RO_cbEnable.Value ? 1 : 0
    cfg.Opener.MaxDurationMs := (UI.RO_edMax.Value != "") ? Integer(UI.RO_edMax.Value) : 4000

    if (HasProp(UI, "RO_thrIds") && IsObject(UI.RO_thrIds) && UI.RO_thrIds.Length >= 1) {
        idx := UI.RO_ddThr.Value
        if (idx >= 1 && idx <= UI.RO_thrIds.Length) {
            cfg.Opener.ThreadId := UI.RO_thrIds[idx]
        } else {
            cfg.Opener.ThreadId := 1
        }
    } else {
        cfg.Opener.ThreadId := 1
    }

    cfg.Opener.StepsCount := (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) ? cfg.Opener.Steps.Length : 0

    prof.Rotation := cfg
    Storage_SaveProfile(prof)
    Page_RotOpener_Refresh()
    Notify("起手已保存")
}