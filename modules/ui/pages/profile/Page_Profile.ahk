#Requires AutoHotkey v2
;Page_Profile.ahk
; 概览与配置（紧凑版）
; 加日志：Build/OnEnter/Change 等关键点
; 严格块结构 if/try/catch，不使用单行形式

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Page_Profile_Build(page) {
    global UI
    UI_Trace("Page_Profile_Build enter")
    rc := UI_GetPageRect()
    page.Controls := []
    UI.GB_Profile := UI.Main.Add("GroupBox", Format("x{} y{} w{} h80", rc.X, rc.Y, rc.W), T("group.profile", "角色配置"))
    page.Controls.Push(UI.GB_Profile)

    UI.ProfilesDD := UI.Main.Add("DropDownList", Format("x{} y{} w280", rc.X + 12, rc.Y + 32))
    page.Controls.Push(UI.ProfilesDD)

    UI.BtnNew := UI.Main.Add("Button", "x+10 w80 h28", T("btn.new", "新建"))
    UI.BtnClone := UI.Main.Add("Button", "x+8 w80 h28", T("btn.clone", "复制"))
    UI.BtnDelete := UI.Main.Add("Button", "x+8 w80 h28", T("btn.delete", "删除"))
    UI.BtnExport := UI.Main.Add("Button", "x+16 w92 h28", T("btn.export", "导出打包"))
    page.Controls.Push(UI.BtnNew)
    page.Controls.Push(UI.BtnClone)
    page.Controls.Push(UI.BtnDelete)
    page.Controls.Push(UI.BtnExport)

    labelW := 120
    rowH := 34
    padX := 12
    padTop := 26
    ctrlGap := 8

    rows := 8
    genH := padTop + rows * rowH + 14

    gy := rc.Y + 80 + 10
    UI.GB_General := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, gy, rc.W, genH), T("group.general",
        "热键与轮询"))
    page.Controls.Push(UI.GB_General)

    xLabel := rc.X + padX
    xCtrl := xLabel + labelW + ctrlGap
    yLine1 := gy + padTop

    UI.LblStartStop := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, yLine1 + 4, labelW), T("label.startStop",
        "开始/停止："))
    page.Controls.Push(UI.LblStartStop)
    UI.HkStart := UI.Main.Add("Hotkey", Format("x{} y{} w200", xCtrl, yLine1))
    page.Controls.Push(UI.HkStart)
    UI.BtnCapStartMouse := UI.Main.Add("Button", Format("x{} y{} w110 h26", xCtrl + 210, yLine1 - 2), T(
        "btn.captureMouse", "捕获鼠标键"))
    page.Controls.Push(UI.BtnCapStartMouse)

    y2 := yLine1 + rowH
    UI.LblPoll := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y2 + 4, labelW), T("label.pollMs", "轮询(ms)："))
    page.Controls.Push(UI.LblPoll)
    UI.PollEdit := UI.Main.Add("Edit", Format("x{} y{} w200 Number Center", xCtrl, y2))
    page.Controls.Push(UI.PollEdit)

    y3 := y2 + rowH
    UI.LblDelay := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y3 + 4, labelW), T("label.delayMs",
        "全局延迟(ms)："))
    page.Controls.Push(UI.LblDelay)
    UI.CdEdit := UI.Main.Add("Edit", Format("x{} y{} w200 Number Center", xCtrl, y3))
    page.Controls.Push(UI.CdEdit)

    y4 := y3 + rowH
    UI.LblPick := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y4 + 4, labelW), T("label.pickAvoid", "取色避让："
    ))
    page.Controls.Push(UI.LblPick)
    UI.ChkPick := UI.Main.Add("CheckBox", Format("x{} y{} w200", xCtrl, y4), T("label.enable", "启用"))
    page.Controls.Push(UI.ChkPick)

    y5 := y4 + rowH
    UI.LblOffY := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y5 + 4, labelW), T("label.offsetY",
        "Y偏移(px)："))
    page.Controls.Push(UI.LblOffY)
    UI.OffYEdit := UI.Main.Add("Edit", Format("x{} y{} w200 Number Center", xCtrl, y5))
    page.Controls.Push(UI.OffYEdit)

    y6 := y5 + rowH
    UI.LblDwell := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y6 + 4, labelW), T("label.dwellMs",
        "等待(ms)："))
    page.Controls.Push(UI.LblDwell)
    UI.DwellEdit := UI.Main.Add("Edit", Format("x{} y{} w200 Number Center", xCtrl, y6))
    page.Controls.Push(UI.DwellEdit)

    y7 := y6 + rowH
    UI.LblPickKey := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y7 + 4, labelW), T("label.pickKey",
        "拾色热键："))
    page.Controls.Push(UI.LblPickKey)
    UI.DdPickKey := UI.Main.Add("DropDownList", Format("x{} y{} w200", xCtrl, y7))
    UI.DdPickKey.Add(["LButton", "MButton", "RButton", "XButton1", "XButton2", "F10", "F11", "F12"])
    page.Controls.Push(UI.DdPickKey)

    y8 := y7 + rowH
    UI.BtnApply := UI.Main.Add("Button", Format("x{} y{} w100 h28", xCtrl, y8 - 2), T("btn.apply", "应用"))
    page.Controls.Push(UI.BtnApply)

    UI.ProfilesDD.OnEvent("Change", Profile_OnProfilesChanged)
    UI.BtnNew.OnEvent("Click", Profile_OnNew)
    UI.BtnClone.OnEvent("Click", Profile_OnClone)
    UI.BtnDelete.OnEvent("Click", Profile_OnDelete)
    UI.BtnExport.OnEvent("Click", Profile_OnExport)
    UI.BtnCapStartMouse.OnEvent("Click", Profile_OnCaptureStartMouse)
    UI.BtnApply.OnEvent("Click", Profile_OnApplyGeneral)

    UI_Trace("Page_Profile_Build exit (controls ready)")
}

Page_Profile_Layout(rc) {
    labelW := 100
    rowH := 34
    padX := 12
    padTop := 26
    ctrlGap := 8
    try {
        UI.GB_Profile.Move(rc.X, rc.Y, rc.W)
        UI.ProfilesDD.Move(rc.X + 12, rc.Y + 32)

        rows := 8
        genH := padTop + rows * rowH + 14
        gy := rc.Y + 80 + 10
        UI.GB_General.Move(rc.X, gy, rc.W, genH)

        xLabel := rc.X + padX
        xCtrl := xLabel + labelW + ctrlGap
        y1 := gy + padTop

        UI.LblStartStop.Move(xLabel, y1 + 4, labelW)
        UI.HkStart.Move(xCtrl, y1, 200)
        UI.BtnCapStartMouse.Move(xCtrl + 210, y1 - 2)

        y2 := y1 + rowH
        UI.LblPoll.Move(xLabel, y2 + 4, labelW)
        UI.PollEdit.Move(xCtrl, y2, 100)

        y3 := y2 + rowH
        UI.LblDelay.Move(xLabel, y3 + 4, labelW)
        UI.CdEdit.Move(xCtrl, y3, 120)

        y4 := y3 + rowH
        UI.LblPick.Move(xLabel, y4 + 4, labelW)
        UI.ChkPick.Move(xCtrl, y4, 100)

        y5 := y4 + rowH
        UI.LblOffY.Move(xLabel, y5 + 4, labelW)
        UI.OffYEdit.Move(xCtrl, y5, 120)

        y6 := y5 + rowH
        UI.LblDwell.Move(xLabel, y6 + 4, labelW)
        UI.DwellEdit.Move(xCtrl, y6, 120)

        y7 := y6 + rowH
        UI.LblPickKey.Move(xLabel, y7 + 4, labelW)
        UI.DdPickKey.Move(xCtrl, y7, 140)

        y8 := y7 + rowH
        UI.BtnApply.Move(xCtrl, y8 - 2, 100, 28)
    } catch {
    }
}

Page_Profile_OnEnter(*) {
    UI_Trace("Page_Profile_OnEnter -> Profile_RefreshAll_Strong")
    try {
        Profile_RefreshAll_Strong()
    } catch as e {
        UI_Trace("Page_Profile_OnEnter exception: " e.Message)
    }
}

Profile_OnProfilesChanged(*) {
    global g_Profile_Populating
    UI_Trace("Profile_OnProfilesChanged populating=" (g_Profile_Populating ? 1 : 0))
    if (g_Profile_Populating) {
        return
    }
    name := ""
    try {
        name := UI.ProfilesDD.Text
    } catch {
        name := ""
    }
    cur := ""
    try {
        cur := App["CurrentProfile"]
    } catch {
        cur := ""
    }
    UI_Trace("ProfilesChanged sel=" name " cur=" cur)
    if (name = "" || cur = name) {
        return
    }
    try {
        ok := Profile_SwitchProfile_Strong(name)
        UI_Trace("ProfilesChanged switched ok=" ok)
    } catch as e {
        UI_Trace("ProfilesChanged switch exception: " e.Message)
    }
}

Profile_OnNew(*) {
    global App, UI
    UI_Trace("Profile_OnNew")
    name := ""
    try {
        ib := InputBox(T("label.profileName", "配置名称："), T("dlg.newProfile", "新建配置"))
        if (ib.Result = "Cancel") {
            return
        }
        name := Trim(ib.Value)
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox T("msg.nameEmpty", "名称不可为空")
        return
    }
    try {
        data := Core_DefaultProfileData()
        data.Name := name
        Storage_SaveProfile(data)
        App["CurrentProfile"] := name
        Profile_RefreshAll_Strong()
        Notify(T("msg.created", "已创建：") name)
    } catch as e {
        UI_Trace("Profile_OnNew exception: " e.Message)
        MsgBox T("msg.createFail", "创建失败：") e.Message
    }
}

Profile_OnClone(*) {
    global App
    UI_Trace("Profile_OnClone")
    src := ""
    try {
        src := App["CurrentProfile"]
    } catch {
        src := ""
    }
    if (src = "") {
        MsgBox T("msg.noProfile", "未选择配置")
        return
    }
    newName := ""
    try {
        ib := InputBox(T("label.newProfileName", "新配置名称："), T("dlg.cloneProfile", "复制配置"), src "_Copy")
        if (ib.Result = "Cancel") {
            return
        }
        newName := Trim(ib.Value)
    } catch {
        newName := src "_Copy"
    }
    if (newName = "") {
        MsgBox T("msg.nameEmpty", "名称不可为空")
        return
    }
    try {
        data := Storage_LoadProfile(src)
        data.Name := newName
        Storage_SaveProfile(data)
        App["CurrentProfile"] := newName
        Profile_RefreshAll_Strong()
        Notify(T("msg.cloned", "已复制为：") newName)
    } catch as e {
        UI_Trace("Profile_OnClone exception: " e.Message)
        MsgBox T("msg.cloneFail", "复制失败：") e.Message
    }
}

Profile_OnDelete(*) {
    global App
    UI_Trace("Profile_OnDelete")
    names := []
    try {
        names := Storage_ListProfiles()
    } catch {
        names := []
    }
    if (names.Length <= 1) {
        MsgBox T("msg.keepOne", "至少保留一个配置。")
        return
    }
    cur := ""
    try {
        cur := App["CurrentProfile"]
    } catch {
        cur := ""
    }
    if (cur = "") {
        MsgBox T("msg.noProfile", "未选择配置")
        return
    }
    ok := Confirm(T("confirm.deleteProfile", "确定删除配置：") cur "？")
    if (!ok) {
        return
    }
    try {
        Storage_DeleteProfile(cur)
        Notify(T("msg.deleted", "已删除：") cur)
        App["CurrentProfile"] := ""
        Profile_RefreshAll_Strong()
    } catch as e {
        UI_Trace("Profile_OnDelete exception: " e.Message)
        MsgBox T("msg.deleteFail", "删除失败：") e.Message
    }
}

Profile_OnExport(*) {
    global App
    UI_Trace("Profile_OnExport")
    cur := ""
    try {
        cur := App["CurrentProfile"]
    } catch {
        cur := ""
    }
    if (cur = "") {
        MsgBox T("msg.noProfile", "未选择配置")
        return
    }
    try {
        Exporter_ExportProfile(cur)
    } catch as e {
        UI_Trace("Profile_OnExport exception: " e.Message)
        MsgBox T("msg.exportFail", "导出失败：") e.Message
    }
}

Profile_OnCaptureStartMouse(*) {
    global UI
    UI_Trace("Profile_OnCaptureStartMouse begin")
    ToolTip T("tip.captureMouse", "请按下 鼠标中键/侧键 作为开始/停止热键（Esc取消）")
    key := ""
    loop {
        if GetKeyState("Esc", "P") {
            break
        }
        for k in ["XButton1", "XButton2", "MButton"] {
            if GetKeyState(k, "P") {
                key := k
                while GetKeyState(k, "P") {
                    Sleep 20
                }
                break
            }
        }
        if (key != "") {
            break
        }
        Sleep 20
    }
    ToolTip()
    if (key != "") {
        try {
            UI.HkStart.Value := key
        } catch {
        }
        try {
            Hotkeys_BindStartHotkey(key)
        } catch {
        }
    }
    UI_Trace("Profile_OnCaptureStartMouse end key=" key)
}

Profile_OnApplyGeneral(*) {
    global App, UI
    UI_Trace("Profile_OnApplyGeneral")
    try {
        if !IsSet(App) {
            App := Map()
        }
        if !App.Has("ProfileData") {
            App["ProfileData"] := Core_DefaultProfileData()
        }
        prof := App["ProfileData"]
        prof.StartHotkey := UI.HkStart.Value

        pi := 25
        if (UI.PollEdit.Value != "") {
            pi := Integer(UI.PollEdit.Value)
        }
        if (pi < 10) {
            pi := 10
        }
        prof.PollIntervalMs := pi

        delay := 0
        if (UI.CdEdit.Value != "") {
            delay := Integer(UI.CdEdit.Value)
        }
        if (delay < 0) {
            delay := 0
        }
        prof.SendCooldownMs := delay

        prof.PickHoverEnabled := UI.ChkPick.Value ? 1 : 0

        offY := -60
        if (UI.OffYEdit.Value != "") {
            offY := Integer(UI.OffYEdit.Value)
        }
        prof.PickHoverOffsetY := offY

        dwell := 120
        if (UI.DwellEdit.Value != "") {
            dwell := Integer(UI.DwellEdit.Value)
        }
        prof.PickHoverDwellMs := dwell

        prof.PickConfirmKey := UI.DdPickKey.Text

        Storage_SaveProfile(prof)

        try {
            Hotkeys_BindStartHotkey(prof.StartHotkey)
        } catch {
        }
        try {
            Dup_OnProfileChanged()
        } catch {
        }

        Notify(T("msg.saved", "配置已保存"))
    } catch as e {
        UI_Trace("Profile_OnApplyGeneral exception: " e.Message)
        MsgBox T("msg.saveFail", "保存失败：") e.Message
    }
}

UI_Profile_FallbackRect() {
    global UI
    navW := 220
    mX := 12
    mY := 10
    try {
        mX := UI.Main.MarginX
        mY := UI.Main.MarginY
    } catch {
        mX := 12
        mY := 10
    }
    rc := Buffer(16, 0)
    try {
        DllCall("user32\GetClientRect", "ptr", UI.Main.Hwnd, "ptr", rc.Ptr)
        cw := NumGet(rc, 8, "Int")
        ch := NumGet(rc, 12, "Int")
        x := mX + navW + 12
        y := mY
        w := Max(cw - x - mX, 320)
        h := Max(ch - mY * 2, 300)
        return { X: x, Y: y, W: w, H: h }
    } catch {
        return { X: 12, Y: 10, W: 700, H: 500 }
    }
}
