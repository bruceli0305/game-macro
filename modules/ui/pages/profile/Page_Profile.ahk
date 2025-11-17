; ============================== modules\ui\pages\profile\Page_Profile.ahk ==============================
#Requires AutoHotkey v2
; 概览与配置（紧凑版）
; 兼容：Build(page:=0) / Layout(rc:=0) 双签名；严格块结构；带详细日志

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Page_Profile_Build(page := 0) {
    global UI, UI_Pages, UI_CurrentPage
    UI_Trace("Page_Profile_Build enter")

    rc := 0
    try {
        rc := UI_GetPageRect()
    } catch {
        rc := { X: 244, Y: 10, W: 804, H: 760 }
    }

    pg := 0
    try {
        if (IsObject(page)) {
            pg := page
        } else {
            if (IsSet(UI_Pages) && UI_Pages.Has(UI_CurrentPage)) {
                pg := UI_Pages[UI_CurrentPage]
            }
        }
    } catch {
        pg := 0
    }

    if (IsObject(pg)) {
        try {
            pg.Controls := []
        } catch {
        }
    }

    UI.GB_Profile := UI.Main.Add("GroupBox", Format("x{} y{} w{} h80", rc.X, rc.Y, rc.W), T("group.profile","角色配置"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.GB_Profile)
        } catch {
        }
    }

    UI.ProfilesDD := UI.Main.Add("DropDownList", Format("x{} y{} w280", rc.X + 12, rc.Y + 32))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.ProfilesDD)
        } catch {
        }
    }

    UI.BtnNew := UI.Main.Add("Button", "x+10 w80 h28", T("btn.new","新建"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.BtnNew)
        } catch {
        }
    }

    UI.BtnClone := UI.Main.Add("Button", "x+8 w80 h28", T("btn.clone","复制"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.BtnClone)
        } catch {
        }
    }

    UI.BtnDelete := UI.Main.Add("Button", "x+8 w80 h28", T("btn.delete","删除"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.BtnDelete)
        } catch {
        }
    }

    labelW := 120
    rowH   := 34
    padX   := 12
    padTop := 26
    ctrlGap:= 8

    rows := 9
    genH := padTop + rows * rowH + 14

    gy := rc.Y + 80 + 10
    UI.GB_General := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, gy, rc.W, genH), T("group.general","热键与轮询"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.GB_General)
        } catch {
        }
    }

    xLabel := rc.X + padX
    xCtrl  := xLabel + labelW + ctrlGap
    yLine1 := gy + padTop

    UI.LblStartStop := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, yLine1 + 4, labelW), T("label.startStop","开始/停止："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblStartStop)
        } catch {
        }
    }

    UI.HkStart := UI.Main.Add("Hotkey", Format("x{} y{} w180", xCtrl, yLine1))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.HkStart)
        } catch {
        }
    }
    ; 鼠标热键回显（Hotkey 控件不支持显示鼠标键，这里单独显示）
    UI.LblStartEcho := UI.Main.Add("Text", Format("x{} y{} w120", xCtrl + 180 + 8, yLine1 + 4), "")
    if (IsObject(pg)) {
        try pg.Controls.Push(UI.LblStartEcho)
    }

    ; 当用户在 Hotkey 控件内手动输入/修改键盘热键时，清空鼠标热键回显与缓存
    try UI.HkStart.OnEvent("Change", Profile_OnHotkeyChanged)
    UI.BtnCapStartMouse := UI.Main.Add("Button", Format("x{} y{} w110 h26", xCtrl, yLine1 + rowH - 2), T("btn.captureMouse","捕获鼠标键"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.BtnCapStartMouse)
        } catch {
        }
    }

    y2 := yLine1 + rowH * 2
    UI.LblPoll := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y2 + 4, labelW), T("label.pollMs","轮询(ms)："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblPoll)
        } catch {
        }
    }

    UI.PollEdit := UI.Main.Add("Edit", Format("x{} y{} w180 Number Center", xCtrl, y2))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.PollEdit)
        } catch {
        }
    }

    y3 := y2 + rowH
    UI.LblDelay := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y3 + 4, labelW), T("label.delayMs","全局延迟(ms)："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblDelay)
        } catch {
        }
    }

    UI.CdEdit := UI.Main.Add("Edit", Format("x{} y{} w180 Number Center", xCtrl, y3))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.CdEdit)
        } catch {
        }
    }

    y4 := y3 + rowH
    UI.LblPick := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y4 + 4, labelW), T("label.pickAvoid","取色避让："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblPick)
        } catch {
        }
    }

    UI.ChkPick := UI.Main.Add("CheckBox", Format("x{} y{} w180", xCtrl, y4), T("label.enable","启用"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.ChkPick)
        } catch {
        }
    }

    y5 := y4 + rowH
    UI.LblOffY := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y5 + 4, labelW), T("label.offsetY","Y偏移(px)："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblOffY)
        } catch {
        }
    }

    UI.OffYEdit := UI.Main.Add("Edit", Format("x{} y{} w180 Number Center", xCtrl, y5))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.OffYEdit)
        } catch {
        }
    }

    y6 := y5 + rowH
    UI.LblDwell := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y6 + 4, labelW), T("label.dwellMs","等待(ms)："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblDwell)
        } catch {
        }
    }

    UI.DwellEdit := UI.Main.Add("Edit", Format("x{} y{} w180 Number Center", xCtrl, y6))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.DwellEdit)
        } catch {
        }
    }

    y7 := y6 + rowH
    UI.LblPickKey := UI.Main.Add("Text", Format("x{} y{} w{} Right", xLabel, y7 + 4, labelW), T("label.pickKey","拾色热键："))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblPickKey)
        } catch {
        }
    }

    UI.DdPickKey := UI.Main.Add("DropDownList", Format("x{} y{} w180", xCtrl, y7))
    try {
        UI.DdPickKey.Add(["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"])
    } catch {
    }
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.DdPickKey)
        } catch {
        }
    }

    y8 := y7 + rowH
    UI.BtnApply := UI.Main.Add("Button", Format("x{} y{} w100 h28", xCtrl, y8), T("btn.apply","应用"))
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.BtnApply)
        } catch {
        }
    }

    try {
        UI.ProfilesDD.OnEvent("Change", Profile_OnProfilesChanged)
        UI.BtnNew.OnEvent("Click", Profile_OnNew)
        UI.BtnClone.OnEvent("Click", Profile_OnClone)
        UI.BtnDelete.OnEvent("Click", Profile_OnDelete)
        UI.BtnCapStartMouse.OnEvent("Click", Profile_OnCaptureStartMouse)
        UI.BtnApply.OnEvent("Click", Profile_OnApplyGeneral)
    } catch {
    }

    UI_Trace("Page_Profile_Build exit (controls ready)")
}

Page_Profile_Layout(rc := 0) {
    if (!IsObject(rc)) {
        try {
            rc := UI_GetPageRect()
        } catch {
            rc := { X: 244, Y: 10, W: 804, H: 760 }
        }
    }

    labelW := 120
    rowH   := 34
    padX   := 12
    padTop := 26
    ctrlGap:= 8

    try {
        UI.GB_Profile.Move(rc.X, rc.Y, rc.W)
    } catch {
    }
    try {
        UI.ProfilesDD.Move(rc.X + 12, rc.Y + 32)
    } catch {
    }

    rows := 9
    genH := padTop + rows * rowH + 14
    gy   := rc.Y + 80 + 10

    try {
        UI.GB_General.Move(rc.X, gy, rc.W, genH)
    } catch {
    }

    xLabel := rc.X + padX
    xCtrl  := xLabel + labelW + ctrlGap
    y1     := gy + padTop

    try {
        UI.LblStartStop.Move(xLabel, y1 + 4, labelW)
    } catch {
    }
    try {
        UI.HkStart.Move(xCtrl, y1, 180)
    } catch {
    }
    ; 新增/替换：按钮放在下一行，左对齐 Hotkey
    try {
        UI.BtnCapStartMouse.Move(xCtrl, y1 + rowH - 2, 110, 26)
    } catch {
    }
    try {
        UI.LblStartEcho.Move(xCtrl + 180 + 8, y1 + 4, 120)
    } catch {
    }

    y2 := y1 + rowH * 2
    try {
        UI.LblPoll.Move(xLabel, y2 + 4, labelW)
    } catch {
    }
    try {
        UI.PollEdit.Move(xCtrl, y2, 180)
    } catch {
    }

    y3 := y2 + rowH
    try {
        UI.LblDelay.Move(xLabel, y3 + 4, labelW)
    } catch {
    }
    try {
        UI.CdEdit.Move(xCtrl, y3, 180)
    } catch {
    }

    y4 := y3 + rowH
    try {
        UI.LblPick.Move(xLabel, y4 + 4, labelW)
    } catch {
    }
    try {
        UI.ChkPick.Move(xCtrl, y4, 180)
    } catch {
    }

    y5 := y4 + rowH
    try {
        UI.LblOffY.Move(xLabel, y5 + 4, labelW)
    } catch {
    }
    try {
        UI.OffYEdit.Move(xCtrl, y5, 180)
    } catch {
    }

    y6 := y5 + rowH
    try {
        UI.LblDwell.Move(xLabel, y6 + 4, labelW)
    } catch {
    }
    try {
        UI.DwellEdit.Move(xCtrl, y6, 180)
    } catch {
    }

    y7 := y6 + rowH
    try {
        UI.LblPickKey.Move(xLabel, y7 + 4, labelW)
    } catch {
    }
    try {
        UI.DdPickKey.Move(xCtrl, y7, 180)
    } catch {
    }

    y8 := y7 + rowH
    try {
        UI.BtnApply.Move(xCtrl, y8, 100, 28)
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
    try {
        if IsSet(App) && App.Has("ProfileData") {
            Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        }
    } catch {
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
        if (ok) {
            try Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        }
    } catch as e {
        UI_Trace("ProfilesChanged switch exception: " e.Message)
    }
}

Profile_OnNew(*) {
    global App, UI
    UI_Trace("Profile_OnNew")
    name := ""
    try {
        ib := InputBox(T("label.profileName","配置名称："), T("dlg.newProfile","新建配置"))
        if (ib.Result = "Cancel") {
            return
        }
        name := Trim(ib.Value)
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox T("msg.nameEmpty","名称不可为空")
        return
    }
    try {
        data := Core_DefaultProfileData()
        data.Name := name
        Storage_SaveProfile(data)
        App["CurrentProfile"] := name
        Profile_RefreshAll_Strong()
        Notify(T("msg.created","已创建：") name)
    } catch as e {
        UI_Trace("Profile_OnNew exception: " e.Message)
        MsgBox T("msg.createFail","创建失败：") e.Message
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
        MsgBox T("msg.noProfile","未选择配置")
        return
    }
    newName := ""
    try {
        ib := InputBox(T("label.newProfileName","新配置名称："), T("dlg.cloneProfile","复制配置"), src "_Copy")
        if (ib.Result = "Cancel") {
            return
        }
        newName := Trim(ib.Value)
    } catch {
        newName := src "_Copy"
    }
    if (newName = "") {
        MsgBox T("msg.nameEmpty","名称不可为空")
        return
    }
    try {
        data := Storage_LoadProfile(src)
        data.Name := newName
        Storage_SaveProfile(data)
        App["CurrentProfile"] := newName
        Profile_RefreshAll_Strong()
        Notify(T("msg.cloned","已复制为：") newName)
    } catch as e {
        UI_Trace("Profile_OnClone exception: " e.Message)
        MsgBox T("msg.cloneFail","复制失败：") e.Message
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
        MsgBox T("msg.keepOne","至少保留一个配置。")
        return
    }
    cur := ""
    try {
        cur := App["CurrentProfile"]
    } catch {
        cur := ""
    }
    if (cur = "") {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }
    ok := Confirm(T("confirm.deleteProfile","确定删除配置：") cur "？")
    if (!ok) {
        return
    }
    try {
        Storage_DeleteProfile(cur)
        Notify(T("msg.deleted","已删除：") cur)
        App["CurrentProfile"] := ""
        Profile_RefreshAll_Strong()
    } catch as e {
        UI_Trace("Profile_OnDelete exception: " e.Message)
        MsgBox T("msg.deleteFail","删除失败：") e.Message
    }
}

Profile_OnCaptureStartMouse(*) {
    global UI
    UI_Trace("Profile_OnCaptureStartMouse begin")
    ToolTip T("tip.captureMouse","请按下 鼠标中键/侧键 作为开始/停止热键（Esc取消）")
    key := ""
    Loop {
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
            UI.HkStart.Value := ""
        } catch {
        }
        try {
            UI.HkStart.Tag  := key
        } catch {
        }
        try {
            UI.LblStartEcho.Text := "鼠标: " key
        } catch {
        }
        try {
            Hotkeys_BindStartHotkey(key)
        } catch {
        }
    }
    UI_Trace("Profile_OnCaptureStartMouse end key=" key)
}
Profile_OnHotkeyChanged(*) {
    global UI, g_Profile_Populating
    if (g_Profile_Populating) {
        return
    }
    ; 用户手动输入键盘热键 → 清空鼠标回显与缓存
    try UI.HkStart.Tag := ""
    try UI.LblStartEcho.Text := ""
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

        hk := ""
        try {
            hk := UI.HkStart.Value
        } catch {
        }
        if (hk = "") {
            try hk := UI.HkStart.Tag
        }
        prof.StartHotkey := hk

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
            Profile_UI_SetStartHotkeyEcho(prof.StartHotkey)
        } catch {
        }
        try {
            Hotkeys_BindStartHotkey(prof.StartHotkey)
        } catch {
        }
        try {
            Dup_OnProfileChanged()
        } catch {
        }

        Notify(T("msg.saved","配置已保存"))
    } catch as e {
        UI_Trace("Profile_OnApplyGeneral exception: " e.Message)
        MsgBox T("msg.saveFail","保存失败：") e.Message
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

; 判断是否为鼠标类热键（支持 ~ 前缀）
Profile_IsMouseHotkey(hk) {
    if (hk = "")
        return false
    return RegExMatch(hk, "i)^(~?)(XButton1|XButton2|MButton|Wheel(Up|Down|Left|Right))$")
}

; 按“已保存/指定”的热键更新UI显示（键盘→Hotkey；鼠标→标签）
Profile_UI_SetStartHotkeyEcho(hk) {
    global UI, g_Profile_Populating
    g_Profile_Populating := true
    try {
        if Profile_IsMouseHotkey(hk) {
            try UI.HkStart.Value := ""          ; Hotkey 控件不显示鼠标
            try UI.HkStart.Tag   := hk          ; 在 Tag 里缓存鼠标热键
            try UI.LblStartEcho.Text := "鼠标: " hk
        } else {
            try UI.HkStart.Tag   := ""          ; 清掉鼠标缓存
            try UI.LblStartEcho.Text := ""      ; 清掉回显
            try UI.HkStart.Value := hk          ; 键盘热键回填 Hotkey
        }
    } catch {
    }
    g_Profile_Populating := false
}