; modules\ui\rotation\RE_UI_Shell.ahk
#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"
#Include "RE_UI_Page_General.ahk"
#Include "RE_UI_Page_Tracks.ahk"
#Include "RE_UI_Page_Gates.ahk"
#Include "RE_UI_Page_Opener.ahk"

RotationEditor_Show() {
    global App
    if !IsObject(App) || !App.Has("ProfileData") {
        MsgBox "Profile 未加载"
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation")
        prof.Rotation := {}
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    prof.Rotation := cfg

    dlg := REUI_CreateOwnedGui("Rotation 配置")
    dlg.MarginX := 12, dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    tab := dlg.Add("Tab3", "xm ym w860 h520", ["常规","轨道","跳轨","起手"])
    ctx := { dlg: dlg, tab: tab, prof: prof, cfg: cfg }

    ; 页面
    pGeneral := REUI_Page_General_Build(ctx)
    pTracks  := REUI_Page_Tracks_Build(ctx)
    pGates   := REUI_Page_Gates_Build(ctx)
    pOpener  := REUI_Page_Opener_Build(ctx)

    tab.UseTab()

    btnSave := dlg.Add("Button", "xm y+12 w110", "保存")
    btnClose:= dlg.Add("Button", "x+8 w110", "关闭")

    btnSave.OnEvent("Click", (*) => (
        pGeneral.Save()
      , pTracks.Save()
      , pGates.Save()
      , pOpener.Save()
      , App["ProfileData"].Rotation := cfg
      , Storage_SaveProfile(App["ProfileData"])
      , Notify("Rotation 配置已保存")
    ))
    btnClose.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())

    dlg.Show()
}