#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Tracks.ahk"

Page_RotTracks_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if (!IsSet(App) || !App.Has("ProfileData")) {
        UI.RT_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        page.Controls.Push(UI.RT_Empty)
        return
    }

    cfg := App["ProfileData"].Rotation
    REUI_EnsureRotationDefaults(&cfg)

    UI.RT_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
        , ["ID","名称","线程","最长ms","最短停留","下一轨","Watch#","规则#"])
    page.Controls.Push(UI.RT_LV)

    yBtn := rc.Y + rc.H - 44
    UI.RT_btnAdd  := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RT_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RT_btnDel  := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RT_btnUp   := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RT_btnDn   := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RT_btnSave := UI.Main.Add("Button", "x+20 w110", "保存轨道")
    for ctl in [UI.RT_btnAdd, UI.RT_btnEdit, UI.RT_btnDel, UI.RT_btnUp, UI.RT_btnDn, UI.RT_btnSave] {
        page.Controls.Push(ctl)
    }

    REUI_Tracks_Ensure(&cfg)
    REUI_Tracks_FillList(UI.RT_LV, cfg)

    ; 事件包装（运行时获取 cfg）
    UI.RT_btnAdd.OnEvent("Click", Page_RotTracks_OnAdd)
    UI.RT_btnEdit.OnEvent("Click", Page_RotTracks_OnEdit)
    UI.RT_btnDel.OnEvent("Click", Page_RotTracks_OnDel)
    UI.RT_btnUp.OnEvent("Click", (*) => Page_RotTracks_OnMove(-1))
    UI.RT_btnDn.OnEvent("Click", (*) => Page_RotTracks_OnMove(1))
    UI.RT_LV.OnEvent("DoubleClick", Page_RotTracks_OnEdit)

    UI.RT_btnSave.OnEvent("Click", Page_RotTracks_OnSave)
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
    try {
        cfg := Page_RotTracks_GetCfg()
        if IsObject(cfg) {
            REUI_Tracks_Ensure(&cfg)
            REUI_Tracks_FillList(UI.RT_LV, cfg)
        }
    } catch {
    }
}

Page_RotTracks_GetCfg() {
    global App
    if (!IsSet(App) || !App.Has("ProfileData")) {
        return 0
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    prof.Rotation := cfg
    return cfg
}

Page_RotTracks_OnAdd(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnAdd(cfg, UI.Main, UI.RT_LV)
    }
}
Page_RotTracks_OnEdit(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnEdit(UI.RT_LV, cfg, UI.Main)
    }
}
Page_RotTracks_OnDel(*) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnDel(UI.RT_LV, cfg)
    }
}
Page_RotTracks_OnMove(dir) {
    global UI
    cfg := Page_RotTracks_GetCfg()
    if IsObject(cfg) {
        REUI_Tracks_OnMove(UI.RT_LV, cfg, dir)
    }
}
Page_RotTracks_OnSave(*) {
    global App
    Storage_SaveProfile(App["ProfileData"])
    Notify("轨道已保存")
}