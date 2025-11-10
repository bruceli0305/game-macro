#Requires AutoHotkey v2

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

    UI.RS_BtnOpen := UI.Main.Add("Button", Format("x{} y{} w160 h28", rc.X + 12, rc.Y + 26 + 8*22 + 10), T("rot.open","打开轮换配置编辑器"))
    UI.RS_BtnRefresh := UI.Main.Add("Button", "x+8 w100 h28", T("btn.refresh","刷新"))
    page.Controls.Push(UI.RS_BtnOpen)
    page.Controls.Push(UI.RS_BtnRefresh)

    UI.RS_BtnOpen.OnEvent("Click", Page_Rotation_OpenEditor)
    UI.RS_BtnRefresh.OnEvent("Click", Page_Rotation_Refresh)

    Page_Rotation_Refresh()
}

Page_Rotation_Layout(rc) {
    try {
        UI.RS_GB.Move(rc.X, rc.Y, rc.W)
        UI.RS_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.RS_BtnOpen.Move(rc.X + 12, rc.Y + 26 + 8*22 + 10)
        UI.RS_BtnRefresh.Move(, rc.Y + 26 + 8*22 + 10)
    } catch {
    }
}

Page_Rotation_OnEnter(*) {
    Page_Rotation_Refresh()
}

Page_Rotation_OpenEditor(*) {
    RotationEditor_Show()
}

Page_Rotation_Refresh(*) {
    global App
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
            def := HasProp(rot,"DefaultTrackId") ? rot.DefaultTrackId : 1
            busy:= HasProp(rot,"BusyWindowMs") ? rot.BusyWindowMs : 200
            tol := HasProp(rot,"ColorTolBlack") ? rot.ColorTolBlack : 16
            swap:= HasProp(rot,"SwapKey") ? rot.SwapKey : ""
            tracks := 0
            gates  := 0

            if (HasProp(rot,"Tracks") && IsObject(rot.Tracks)) {
                tracks := rot.Tracks.Length
            } else {
                tracks := 0
                if HasProp(rot,"Track1") {
                    tracks += 1
                }
                if HasProp(rot,"Track2") {
                    tracks += 1
                }
            }

            if (HasProp(rot,"Gates") && IsObject(rot.Gates)) {
                gates := rot.Gates.Length
            } else {
                gates := 0
            }

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