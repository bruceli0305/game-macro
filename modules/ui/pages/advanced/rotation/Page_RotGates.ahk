#Requires AutoHotkey v2
;modules\ui\pages\advanced\rotation\Page_RotGates.ahk

#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Gates.ahk"

Page_RotGates_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if (!IsSet(App) || !App.Has("ProfileData")) {
        UI.RGts_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        page.Controls.Push(UI.RGts_Empty)
        return
    }

    cfg := App["ProfileData"].Rotation
    REUI_EnsureRotationDefaults(&cfg)
    REUI_Gates_Ensure(&cfg)

    UI.RGts_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 56)
        , ["优先级","来源轨","目标轨","逻辑","条件数"])
    page.Controls.Push(UI.RGts_LV)

    yBtn := rc.Y + rc.H - 44
    UI.RGts_btnAdd  := UI.Main.Add("Button", Format("x{} y{} w90", rc.X, yBtn), "新增")
    UI.RGts_btnEdit := UI.Main.Add("Button", "x+8 w90", "编辑")
    UI.RGts_btnDel  := UI.Main.Add("Button", "x+8 w90", "删除")
    UI.RGts_btnUp   := UI.Main.Add("Button", "x+8 w90", "上移")
    UI.RGts_btnDn   := UI.Main.Add("Button", "x+8 w90", "下移")
    UI.RGts_btnSave := UI.Main.Add("Button", "x+20 w110", "保存跳轨")
    for ctl in [UI.RGts_btnAdd, UI.RGts_btnEdit, UI.RGts_btnDel, UI.RGts_btnUp, UI.RGts_btnDn, UI.RGts_btnSave] {
        page.Controls.Push(ctl)
    }

    REUI_Gates_FillList(UI.RGts_LV, cfg)

    UI.RGts_btnAdd.OnEvent("Click", Page_RotGates_OnAdd)
    UI.RGts_btnEdit.OnEvent("Click", Page_RotGates_OnEdit)
    UI.RGts_btnDel.OnEvent("Click", Page_RotGates_OnDel)
    UI.RGts_btnUp.OnEvent("Click", (*) => Page_RotGates_OnMove(-1))
    UI.RGts_btnDn.OnEvent("Click", (*) => Page_RotGates_OnMove(1))
    UI.RGts_LV.OnEvent("DoubleClick", Page_RotGates_OnEdit)

    UI.RGts_btnSave.OnEvent("Click", Page_RotGates_OnSave)
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
    try {
        cfg := Page_RotGates_GetCfg()
        if IsObject(cfg) {
            REUI_Gates_Ensure(&cfg)
            REUI_Gates_FillList(UI.RGts_LV, cfg)
        }
    } catch {
    }
}

Page_RotGates_GetCfg() {
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
    REUI_Gates_Ensure(&cfg)
    prof.Rotation := cfg
    return cfg
}

Page_RotGates_OnAdd(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnAdd(cfg, UI.Main, UI.RGts_LV)
    }
}
Page_RotGates_OnEdit(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnEdit(UI.RGts_LV, cfg, UI.Main)
    }
}
Page_RotGates_OnDel(*) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnDel(UI.RGts_LV, cfg, UI.Main)
    }
}
Page_RotGates_OnMove(dir) {
    global UI
    cfg := Page_RotGates_GetCfg()
    if IsObject(cfg) {
        REUI_Gates_OnMove(UI.RGts_LV, cfg, dir)
    }
}
Page_RotGates_OnSave(*) {
    global App
    Storage_SaveProfile(App["ProfileData"])
    Notify("跳轨已保存")
}