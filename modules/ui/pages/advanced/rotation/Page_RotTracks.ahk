#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Tracks.ahk"

; 轮换配置 - 轨道页（轻量化，严格块结构）
; 依赖：Rot_SaveTracks / REUI_Tracks_* / RotPU_*

Page_RotTracks_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.RT_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
        , ["ID","名称","线程","最长ms","最短停留","下一轨","监视数","规则数"])
    try {
        page.Controls.Push(UI.RT_LV)
    } catch {
    }

    yBtn := rc.Y + rc.H - 44
    UI.RT_btnAdd  := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RT_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RT_btnDel  := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RT_btnUp   := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RT_btnDn   := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RT_btnSave := UI.Main.Add("Button", "x+20 w110", "保存轨道")

    ctrls := [UI.RT_btnAdd, UI.RT_btnEdit, UI.RT_btnDel, UI.RT_btnUp, UI.RT_btnDn, UI.RT_btnSave]
    for ctl in ctrls {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    UI.RT_btnAdd.OnEvent("Click", Page_RotTracks_DoAdd)
    UI.RT_btnEdit.OnEvent("Click", Page_RotTracks_DoEdit)
    UI.RT_btnDel.OnEvent("Click", Page_RotTracks_DoDel)
    UI.RT_btnUp.OnEvent("Click", Page_RotTracks_DoUp)
    UI.RT_btnDn.OnEvent("Click", Page_RotTracks_DoDn)
    UI.RT_LV.OnEvent("DoubleClick", Page_RotTracks_DoEdit)
    UI.RT_btnSave.OnEvent("Click", Page_RotTracks_OnSave)

    Page_RotTracks_Refresh()
}

Page_RotTracks_Layout(rc) {
    try {
        UI.RT_LV.Move(rc.X, rc.Y, rc.W, rc.H - 56)
        yBtn := rc.Y + rc.H - 44
        UI_MoveSafe(UI.RT_btnAdd,  rc.X, yBtn)
        UI_MoveSafe(UI.RT_btnEdit, "",   yBtn)
        UI_MoveSafe(UI.RT_btnDel,  "",   yBtn)
        UI_MoveSafe(UI.RT_btnUp,   "",   yBtn)
        UI_MoveSafe(UI.RT_btnDn,   "",   yBtn)
        UI_MoveSafe(UI.RT_btnSave, "",   yBtn)
    } catch {
    }
}

Page_RotTracks_OnEnter(*) {
    RotPU_LogEnter("RotTracks")
    Page_RotTracks_Refresh()
}

Page_RotTracks_Refresh() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_FillList(UI.RT_LV, cfg)
    } catch {
    }
}

; —— 列表操作（获取最新 cfg 后转发到 REUI_*） ——
Page_RotTracks_DoAdd(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_OnAdd(cfg, UI.Main, UI.RT_LV)
    } catch {
    }
}

Page_RotTracks_DoEdit(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_OnEdit(UI.RT_LV, cfg, UI.Main)
    } catch {
    }
}

Page_RotTracks_DoDel(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_OnDel(UI.RT_LV, cfg)
    } catch {
    }
}

Page_RotTracks_DoUp(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_OnMove(UI.RT_LV, cfg, -1)
    } catch {
    }
}

Page_RotTracks_DoDn(*) {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }
    RotPU_EnsureTracks(cfg)
    try {
        REUI_Tracks_OnMove(UI.RT_LV, cfg, 1)
    } catch {
    }
}

; —— 保存 ——
Page_RotTracks_OnSave(*) {
    name := RotPU_CurrentProfileOrMsg()
    if (name = "") {
        return
    }
    try {
        Logger_Info("UI.RotTracks", "save_click", Map("page","tracks","profile",name))
    } catch {
    }

    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        MsgBox "配置不可用。"
        return
    }

    ok := false
    try {
        RotPU_EnsureTracks(cfg)
        ok := Rot_SaveTracks(name, cfg)
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    Page_RotTracks_Refresh()
    Notify("轨道已保存")
}