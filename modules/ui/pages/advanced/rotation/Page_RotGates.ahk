#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Gates.ahk"

; 轮换配置 - 跳轨页（轻量化，严格块结构）
; 依赖：Rot_SaveGates / REUI_Gates_* / RotPU_*

Page_RotGates_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.RGts_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
        , ["优先级","来源轨","目标轨","逻辑","条件数"])
    try {
        page.Controls.Push(UI.RGts_LV)
    } catch {
    }

    yBtn := rc.Y + rc.H - 44
    UI.RGts_btnAdd  := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RGts_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RGts_btnDel  := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RGts_btnUp   := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RGts_btnDn   := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RGts_btnSave := UI.Main.Add("Button", "x+20 w110", "保存跳轨")

    ctrls := [UI.RGts_btnAdd, UI.RGts_btnEdit, UI.RGts_btnDel, UI.RGts_btnUp, UI.RGts_btnDn, UI.RGts_btnSave]
    for ctl in ctrls {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    UI.RGts_btnAdd.OnEvent("Click", Page_RotGates_DoAdd)
    UI.RGts_btnEdit.OnEvent("Click", Page_RotGates_DoEdit)
    UI.RGts_btnDel.OnEvent("Click", Page_RotGates_DoDel)
    UI.RGts_btnUp.OnEvent("Click", Page_RotGates_DoUp)
    UI.RGts_btnDn.OnEvent("Click", Page_RotGates_DoDn)
    UI.RGts_LV.OnEvent("DoubleClick", Page_RotGates_DoEdit)
    UI.RGts_btnSave.OnEvent("Click", Page_RotGates_OnSave)

    Page_RotGates_Refresh()
}

Page_RotGates_Layout(rc) {
    try {
        UI.RGts_LV.Move(rc.X, rc.Y, rc.W, rc.H - 56)
        yBtn := rc.Y + rc.H - 44
        UI_MoveSafe(UI.RGts_btnAdd,  rc.X, yBtn)
        UI_MoveSafe(UI.RGts_btnEdit, "",   yBtn)
        UI_MoveSafe(UI.RGts_btnDel,  "",   yBtn)
        UI_MoveSafe(UI.RGts_btnUp,   "",   yBtn)
        UI_MoveSafe(UI.RGts_btnDn,   "",   yBtn)
        UI_MoveSafe(UI.RGts_btnSave, "",   yBtn)
    } catch {
    }
}

Page_RotGates_OnEnter(*) {
    RotPU_LogEnter("RotGates")
    Page_RotGates_Refresh()
}

Page_RotGates_Refresh() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_FillList(UI.RGts_LV, cfg)
    } catch {
    }
}

; —— 列表操作（获取最新 cfg 后转发到 REUI_*） ——
Page_RotGates_DoAdd(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_OnAdd(cfg, UI.Main, UI.RGts_LV)
    } catch {
    }
}

Page_RotGates_DoEdit(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_OnEdit(UI.RGts_LV, cfg, UI.Main)
    } catch {
    }
}

Page_RotGates_DoDel(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_OnDel(UI.RGts_LV, cfg, UI.Main)
    } catch {
    }
}

Page_RotGates_DoUp(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_OnMove(UI.RGts_LV, cfg, -1)
    } catch {
    }
}

Page_RotGates_DoDn(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureGates(cfg)
    try {
        REUI_Gates_OnMove(UI.RGts_LV, cfg, 1)
    } catch {
    }
}

; —— 保存 ——
Page_RotGates_OnSave(*) {
    name := RotPU_CurrentProfileOrMsg()
    if (name = "") {
        return
    }
    try {
        Logger_Info("UI.RotGates", "save_click", Map("page","gates","profile",name))
    } catch {
    }

    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        MsgBox "配置不可用。"
        return
    }

    ok := false
    try {
        RotPU_EnsureGates(cfg)
        ok := Rot_SaveGates(name, cfg)
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    Page_RotGates_Refresh()
    Notify("跳轨已保存")
}