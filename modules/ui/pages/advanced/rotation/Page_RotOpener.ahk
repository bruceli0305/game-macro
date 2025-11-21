#Requires AutoHotkey v2
;modules\ui\pages\advanced\rotation\Page_RotOpener.ahk
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Opener.ahk"
; 轮换配置 - 起手页（轻量化）
; 依赖：Rot_SaveOpener / REUI_Opener_* / RotPU_*

Page_RotOpener_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []
    UI.RO_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w160", rc.X, rc.Y + 8), "启用起手")
    page.Controls.Push(UI.RO_cbEnable)

    UI.RO_labMax := UI.Main.Add("Text", Format("x{} y{} w110 Right", rc.X, rc.Y + 44), "最大时长(ms)：")
    UI.RO_edMax := UI.Main.Add("Edit", "x+6 w120 Number Center")
    UI.RO_labThr := UI.Main.Add("Text", "x+20 w80 Right", "线程：")
    UI.RO_ddThr := UI.Main.Add("DropDownList", "x+6 w200")
    page.Controls.Push(UI.RO_labMax)
    page.Controls.Push(UI.RO_edMax)
    page.Controls.Push(UI.RO_labThr)
    page.Controls.Push(UI.RO_ddThr)

    UI.RO_labW := UI.Main.Add("Text", Format("x{} y{}", rc.X, rc.Y + 86), "Watch（技能计数/黑框确认）：")
    page.Controls.Push(UI.RO_labW)

    listW := Max(560, rc.W - 84 - 8 - 20)
    UI.RO_lvW := UI.Main.Add("ListView", Format("x{} y{} w{} r7 +Grid", rc.X, rc.Y + 108, listW), ["技能", "计数", "黑框确认"])
    page.Controls.Push(UI.RO_lvW)

    UI.RO_btnWAdd := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnWEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnWDel := UI.Main.Add("Button", "w84", "删除")
    page.Controls.Push(UI.RO_btnWAdd)
    page.Controls.Push(UI.RO_btnWEdit)
    page.Controls.Push(UI.RO_btnWDel)

    UI.RO_labS := UI.Main.Add("Text", "w200", "Steps（按序执行）：")
    page.Controls.Push(UI.RO_labS)

    UI.RO_lvS := UI.Main.Add("ListView", "w700 r8 +Grid", ["序", "类型", "详情", "就绪", "预延时", "按住", "验证", "超时", "时长"])
    page.Controls.Push(UI.RO_lvS)

    UI.RO_btnSAdd := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnSEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnSDel := UI.Main.Add("Button", "w84", "删除")
    UI.RO_btnSUp := UI.Main.Add("Button", "w84", "上移")
    UI.RO_btnSDn := UI.Main.Add("Button", "w84", "下移")
    page.Controls.Push(UI.RO_btnSAdd)
    page.Controls.Push(UI.RO_btnSEdit)
    page.Controls.Push(UI.RO_btnSDel)
    page.Controls.Push(UI.RO_btnSUp)
    page.Controls.Push(UI.RO_btnSDn)

    UI.RO_btnSave := UI.Main.Add("Button", "w120", "保存起手")
    page.Controls.Push(UI.RO_btnSave)

    ; 绑定事件
    UI.RO_btnWAdd.OnEvent("Click", Page_RotOpener_DoWAdd)
    UI.RO_btnWEdit.OnEvent("Click", Page_RotOpener_DoWEdit)
    UI.RO_btnWDel.OnEvent("Click", Page_RotOpener_DoWDel)
    UI.RO_lvW.OnEvent("DoubleClick", Page_RotOpener_DoWEdit)

    UI.RO_btnSAdd.OnEvent("Click", Page_RotOpener_DoSAdd)
    UI.RO_btnSEdit.OnEvent("Click", Page_RotOpener_DoSEdit)
    UI.RO_btnSDel.OnEvent("Click", Page_RotOpener_DoSDel)
    UI.RO_btnSUp.OnEvent("Click", Page_RotOpener_DoSUp)
    UI.RO_btnSDn.OnEvent("Click", Page_RotOpener_DoSDn)
    UI.RO_lvS.OnEvent("DoubleClick", Page_RotOpener_DoSEdit)

    UI.RO_btnSave.OnEvent("Click", Page_RotOpener_OnSave)

    Page_RotOpener_Refresh()
}

Page_RotOpener_Layout(rc) {
    try {
        x := rc.X
        y := rc.Y
        btnW := 84
        gap := 8
        minW := 560
        listW := Max(minW, rc.W - btnW - gap - 20)

        UI_MoveSafe(UI.RO_labW, x, y + 86)
        UI.RO_lvW.Move(x, y + 108, listW)
        UI.RO_lvW.GetPos(&lx, &ly, &lw, &lh)
        btnX := lx + lw + gap
        UI_MoveSafe(UI.RO_btnWAdd, btnX, ly)
        UI_MoveSafe(UI.RO_btnWEdit, btnX, ly + 34)
        UI_MoveSafe(UI.RO_btnWDel, btnX, ly + 68)

        stepsLabelY := ly + lh + 16
        UI_MoveSafe(UI.RO_labS, x, stepsLabelY)

        UI.RO_lvS.Move(x, stepsLabelY + 16, listW, rc.Y + rc.H - (stepsLabelY + 16) - 56)
        UI.RO_lvS.GetPos(&sx, &sy, &sw, &sh)
        UI_MoveSafe(UI.RO_btnSAdd, btnX, sy)
        UI_MoveSafe(UI.RO_btnSEdit, btnX, sy + 34)
        UI_MoveSafe(UI.RO_btnSDel, btnX, sy + 68)
        UI_MoveSafe(UI.RO_btnSUp, btnX, sy + 102)
        UI_MoveSafe(UI.RO_btnSDn, btnX, sy + 136)

        UI_MoveSafe(UI.RO_btnSave, x, rc.Y + rc.H - 36)
    } catch {
    }
}

Page_RotOpener_OnEnter(*) {
    RotPU_LogEnter("RotOpener")
    Page_RotOpener_Refresh()
}

Page_RotOpener_Refresh() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    ; 顶部控件
    UI.RO_cbEnable.Value := (OM_Get(cfg.Opener, "Enabled", 0) ? 1 : 0)
    UI.RO_edMax.Value := OM_Get(cfg.Opener, "MaxDurationMs", 4000)

    Page_RotOpener_FillThreads(cfg)

    ; 列表
    REUI_Opener_FillWatch(UI.RO_lvW, cfg)
    REUI_Opener_FillSteps(UI.RO_lvS, cfg)
}

Page_RotOpener_FillThreads(cfg) {
    global UI, App
    try {
        DllCall("user32\SendMessageW", "ptr", UI.RO_ddThr.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)
    } catch {
    }
    thrNames := []
    thrIds := []
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
    } catch {
    }
    if (thrNames.Length = 0) {
        thrNames := ["默认线程"]
        thrIds := [1]
    }
    UI.RO_thrIds := thrIds
    UI.RO_ddThr.Add(thrNames)

    curTid := 1
    try {
        curTid := HasProp(cfg.Opener, "ThreadId") ? cfg.Opener.ThreadId : 1
    } catch {
        curTid := 1
    }

    pos := 1
    i := 1
    while (i <= UI.RO_thrIds.Length) {
        v := 0
        try {
            v := UI.RO_thrIds[i]
        } catch {
            v := 0
        }
        if (v = curTid) {
            pos := i
            break
        }
        i := i + 1
    }
    UI.RO_ddThr.Value := pos
    UI.RO_ddThr.Enabled := true
}

; —— 事件（直接转发到 REUI_） ——
Page_RotOpener_DoWAdd() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_WatchAdd(UI.Main, cfg, UI.RO_lvW)
}
Page_RotOpener_DoWEdit() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_WatchEdit(UI.Main, cfg, UI.RO_lvW)
}
Page_RotOpener_DoWDel() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_WatchDel(cfg, UI.RO_lvW)
}

Page_RotOpener_DoSAdd() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_StepAdd(UI.Main, cfg, UI.RO_lvS)
}
Page_RotOpener_DoSEdit() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_StepEdit(UI.Main, cfg, UI.RO_lvS)
}
Page_RotOpener_DoSDel() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_StepDel(cfg, UI.RO_lvS)
}
Page_RotOpener_DoSUp() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_StepMove(cfg, UI.RO_lvS, -1)
}
Page_RotOpener_DoSDn(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureOpener(cfg)
    REUI_Opener_StepMove(cfg, UI.RO_lvS, 1)
}

Page_RotOpener_OnSave(*) {
    name := RotPU_CurrentProfileOrMsg()
    if (name = "") {
        return
    }
    try {
        Logger_Info("UI.RotOpener", "save_click", Map("page", "opener", "profile", name))
    } catch {
    }
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        MsgBox "未加载配置，无法保存。"
        return
    }
    RotPU_EnsureOpener(cfg)

    ; 顶部字段稳妥写回
    cfg.Opener.Enabled := UI.RO_cbEnable.Value ? 1 : 0
    try {
        if (UI.RO_edMax.Value != "") {
            cfg.Opener.MaxDurationMs := Integer(UI.RO_edMax.Value)
        }
    } catch {
    }
    try {
        if (HasProp(UI, "RO_thrIds") && IsObject(UI.RO_thrIds) && UI.RO_thrIds.Length >= 1) {
            idx := UI.RO_ddThr.Value
            if (idx >= 1 && idx <= UI.RO_thrIds.Length) {
                cfg.Opener.ThreadId := UI.RO_thrIds[idx]
            }
        }
    } catch {
    }

    ok := false
    try {
        ok := Rot_SaveOpener(name, cfg)
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    Page_RotOpener_Refresh()
    Notify("起手已保存")
}
