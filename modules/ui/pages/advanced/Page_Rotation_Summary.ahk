#Requires AutoHotkey v2
;Page_Rotation_Summary.ahk
; 轮换配置概要页
; 严格块结构

Page_Rotation_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.RS_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h220", rc.X, rc.Y, rc.W), T("rot.summary","轮换配置概要"))
    page.Controls.Push(UI.RS_GB)

    UI.RS_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r8 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.RS_Info)

    ; 将原“打开编辑器”改为四个快捷跳转按钮
    yBtns := rc.Y + 26 + 8*22 + 10
    UI.RS_BtnGen  := UI.Main.Add("Button", Format("x{} y{} w120 h28", rc.X + 12, yBtns), "常规")
    UI.RS_BtnTrk  := UI.Main.Add("Button", "x+8 w120 h28", "轨道")
    UI.RS_BtnGate := UI.Main.Add("Button", "x+8 w120 h28", "跳轨")
    UI.RS_BtnOp   := UI.Main.Add("Button", "x+8 w120 h28", "起手")
    page.Controls.Push(UI.RS_BtnGen)
    page.Controls.Push(UI.RS_BtnTrk)
    page.Controls.Push(UI.RS_BtnGate)
    page.Controls.Push(UI.RS_BtnOp)

    UI.RS_BtnGen.OnEvent("Click", (*) => UI_SwitchPage("adv_rotation_general"))
    UI.RS_BtnTrk.OnEvent("Click", (*) => UI_SwitchPage("adv_rotation_tracks"))
    UI.RS_BtnGate.OnEvent("Click", (*) => UI_SwitchPage("adv_rotation_gates"))
    UI.RS_BtnOp.OnEvent("Click", (*) => UI_SwitchPage("adv_rotation_opener"))

    UI.RS_BtnRefresh := UI.Main.Add("Button", "x+20 w100 h28", T("btn.refresh","刷新"))
    page.Controls.Push(UI.RS_BtnRefresh)
    UI.RS_BtnRefresh.OnEvent("Click", Page_Rotation_Refresh)

    Page_Rotation_Refresh()
}

Page_Rotation_Layout(rc) {
    try {
        UI.RS_GB.Move(rc.X, rc.Y, rc.W)
        UI.RS_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        yBtns := rc.Y + 26 + 8*22 + 10
        UI_MoveSafe(UI.RS_BtnGen,  rc.X + 12, yBtns)
        UI_MoveSafe(UI.RS_BtnTrk,  "",        yBtns)
        UI_MoveSafe(UI.RS_BtnGate, "",        yBtns)
        UI_MoveSafe(UI.RS_BtnOp,   "",        yBtns)
        UI_MoveSafe(UI.RS_BtnRefresh, "",     yBtns)
    } catch {
    }
}

Page_Rotation_OnEnter(*) {
    Page_Rotation_Refresh()
}

Page_Rotation_Refresh(*) {
    global App, UI
    text := ""
    try {
        if !IsSet(App) {
            App := Map()
        }
        if !App.Has("ProfileData") {
            text := "尚未加载配置。"
        } else {
            rot := HasProp(App["ProfileData"], "Rotation") ? App["ProfileData"].Rotation : {}
            en  := HasProp(rot,"Enabled") ? rot.Enabled : 0
            def := HasProp(rot,"DefaultTrackId") ? rot.DefaultTrackId : 0
            busy:= HasProp(rot,"BusyWindowMs") ? rot.BusyWindowMs : 200
            tol := HasProp(rot,"ColorTolBlack") ? rot.ColorTolBlack : 16
            swap:= HasProp(rot,"SwapKey") ? rot.SwapKey : ""
            tracks := (HasProp(rot,"Tracks") && IsObject(rot.Tracks)) ? rot.Tracks.Length : 0
            gates  := (HasProp(rot,"Gates")  && IsObject(rot.Gates))  ? rot.Gates.Length  : 0

            text := ""
            text .= "Enabled: " en "`r`n"
            text .= "DefaultTrackId: " def "`r`n"
            text .= "Tracks: " tracks "`r`n"
            text .= "Gates: " gates "`r`n"
            text .= "SwapKey: " swap "`r`n"
            text .= "BusyWindowMs: " busy "`r`n"
            text .= "ColorTolBlack: " tol "`r`n"
        }
    } catch {
        text := "读取概要失败。"
    }

    try {
        UI.RS_Info.Value := text
    } catch {
    }
}