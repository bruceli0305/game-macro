#Requires AutoHotkey v2
;modules\ui\pages\profile\Page_Profile.ahk 角色配置页面
; 概览与配置（紧凑版）
; 严格块结构：所有 if/try/catch 使用块语法，不使用单行形式

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Page_Profile_Build(page := 0) {
    global UI, UI_Pages, UI_CurrentPage

    rc := 0
    try {
        rc := UI_GetPageRect()
    } catch {
        rc := { X: 244, Y: 10, W: 804, H: 760 }
    }
    try {
        Logger_Info("UI", "Profile_Build begin", Map("x", rc.X, "y", rc.Y, "w", rc.W, "h", rc.H))
    } catch {
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

    ; 鼠标热键回显
    UI.LblStartEcho := UI.Main.Add("Text", Format("x{} y{} w120", xCtrl + 180 + 8, yLine1 + 4), "")
    if (IsObject(pg)) {
        try {
            pg.Controls.Push(UI.LblStartEcho)
        } catch {
        }
    }

    ; 当用户手动输入键盘热键时，清空鼠标回显与缓存
    try {
        UI.HkStart.OnEvent("Change", Profile_OnHotkeyChanged)
    } catch {
    }

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

    ; 构建完成后立即填充下拉
    try {
        ok := Profile_UI_PopulateProfilesDD()
        Logger_Info("UI", "PopulateProfilesDD after build", Map("ok", ok ? 1 : 0))
    } catch {
    }

    try {
        Logger_Info("UI", "Profile_Build end", Map())
    } catch {
    }
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
    try {
        Logger_Info("UI", "Profile_OnEnter", Map())
    } catch {
    }

    ok := false
    try {
        ok := Profile_RefreshAll_Strong()
    } catch {
        ok := false
    }
    try {
        Logger_Info("UI", "Profile_OnEnter RefreshAll", Map("ok", ok ? 1 : 0))
    } catch {
    }

    ; 保底：再次填充下拉为当前配置
    try {
        cur := ""
        try {
            cur := App["CurrentProfile"]
        } catch {
            cur := ""
        }
        ok2 := Profile_UI_PopulateProfilesDD(cur)
        Logger_Info("UI", "PopulateProfilesDD on enter", Map("ok", ok2 ? 1 : 0, "cur", cur))
    } catch {
    }

    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        }
    } catch {
    }
}

Profile_OnProfilesChanged(*) {
    global g_Profile_Populating
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

    if (name = "" || cur = name) {
        return
    }

    ok := false
    try {
        ok := Profile_SwitchProfile_Strong(name)
    } catch {
        ok := false
    }

    try {
        Logger_Info("UI", "ProfilesChanged", Map("name", name, "ok", ok ? 1 : 0))
    } catch {
    }

    if (ok) {
        try {
            Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        } catch {
        }
    }
}

Profile_OnNew(*) {
    global App, UI

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

    ok := false
    try {
        Storage_Profile_Create(name)
        ok := true
    } catch as e {
        ok := false
        try {
            Logger_Exception("UI", e, Map("where", "Profile_OnNew", "name", name))
        } catch {
        }
    }

    if (!ok) {
        MsgBox T("msg.createFail","创建失败")
        return
    }

    try {
        App["CurrentProfile"] := name
    } catch {
    }

    try {
        Profile_RefreshAll_Strong()
        Profile_UI_PopulateProfilesDD(name)
        Notify(T("msg.created","已创建：") name)
        Logger_Info("UI", "ProfileNew", Map("name", name))
    } catch {
    }
}

Profile_OnClone(*) {
    global App

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

    ok := false
    try {
        ; 读取源配置，修改名称，写入新文件夹（全模块）
        p := Storage_Profile_LoadFull(src)
        p["Name"] := newName
        try {
            p["Meta"]["DisplayName"] := newName
        } catch {
        }
        FS_Meta_Write(p)
        SaveModule_General(p)
        SaveModule_Skills(p)
        SaveModule_Points(p)
        SaveModule_Rules(p)
        SaveModule_Buffs(p)
        SaveModule_RotationBase(p)
        SaveModule_Tracks(p)
        SaveModule_Gates(p)
        SaveModule_Opener(p)
        ok := true
    } catch as e {
        ok := false
        try {
            Logger_Exception("UI", e, Map("where", "Profile_OnClone", "src", src, "dst", newName))
        } catch {
        }
    }

    if (!ok) {
        MsgBox T("msg.cloneFail","复制失败")
        return
    }

    try {
        App["CurrentProfile"] := newName
        Profile_RefreshAll_Strong()
        Profile_UI_PopulateProfilesDD(newName)
        Notify(T("msg.cloned","已复制为：") newName)
        Logger_Info("UI", "ProfileClone", Map("src", src, "dst", newName))
    } catch {
    }
}

Profile_OnDelete(*) {
    global App

    names := []
    try {
        names := FS_ListProfilesValid()
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

    success := false
    try {
        FS_DeleteProfile(cur)
        success := true
    } catch as e {
        success := false
        try {
            Logger_Exception("UI", e, Map("where", "Profile_OnDelete", "name", cur))
        } catch {
        }
    }

    if (!success) {
        MsgBox T("msg.deleteFail","删除失败")
        return
    }

    try {
        App["CurrentProfile"] := ""
        Profile_RefreshAll_Strong()
        Profile_UI_PopulateProfilesDD()
        Notify(T("msg.deleted","已删除：") cur)
        Logger_Info("UI", "ProfileDelete", Map("name", cur))
    } catch {
    }
}

Profile_OnCaptureStartMouse(*) {
    global UI

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
}

Profile_OnHotkeyChanged(*) {
    global UI, g_Profile_Populating

    if (g_Profile_Populating) {
        return
    }

    try {
        UI.HkStart.Tag := ""
    } catch {
    }
    try {
        UI.LblStartEcho.Text := ""
    } catch {
    }
}

; 新版：保存到新存储（general.ini），不再调用旧 Storage_SaveProfile
Profile_OnApplyGeneral(*) {
    global App, UI

    try {
        Logger_Info("UI", "ApplyGeneral begin", Map())
    } catch {
    }

    ; 取当前 Profile 名称
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }

    ; 读 UI 值
    hk := ""
    try {
        hk := UI.HkStart.Value
    } catch {
        hk := ""
    }
    if (hk = "") {
        try {
            hk := UI.HkStart.Tag
        } catch {
            hk := ""
        }
    }

    pi := 25
    try {
        if (UI.PollEdit.Value != "") {
            pi := Integer(UI.PollEdit.Value)
        }
    } catch {
        pi := 25
    }
    if (pi < 10) {
        pi := 10
    }

    delay := 0
    try {
        if (UI.CdEdit.Value != "") {
            delay := Integer(UI.CdEdit.Value)
        }
    } catch {
        delay := 0
    }
    if (delay < 0) {
        delay := 0
    }

    chPick := 1
    try {
        chPick := (UI.ChkPick.Value ? 1 : 0)
    } catch {
        chPick := 1
    }

    offY := -60
    try {
        if (UI.OffYEdit.Value != "") {
            offY := Integer(UI.OffYEdit.Value)
        }
    } catch {
        offY := -60
    }

    dwell := 120
    try {
        if (UI.DwellEdit.Value != "") {
            dwell := Integer(UI.DwellEdit.Value)
        }
    } catch {
        dwell := 120
    }

    pk := "LButton"
    try {
        pk := UI.DdPickKey.Text
    } catch {
        pk := "LButton"
    }

    ; 加载文件夹模型 → 写 General → 保存模块 → 规范化到运行时
    ok := false
    try {
        p := Storage_Profile_LoadFull(name)
        g := p["General"]
        g["StartHotkey"] := hk
        g["PollIntervalMs"] := pi
        g["SendCooldownMs"] := delay
        g["PickHoverEnabled"] := chPick
        g["PickHoverOffsetY"] := offY
        g["PickHoverDwellMs"] := dwell
        g["PickConfirmKey"] := pk
        p["General"] := g

        SaveModule_General(p)
        rt := PM_ToRuntime(p)
        App["ProfileData"] := rt
        try {
            CastEngine_InitFromProfile()
        } catch {
        }
        try {
            if HasProp(App["ProfileData"], "CastDebug") {
                CastDebug_RebindHotkey(App["ProfileData"].CastDebug.Hotkey)
                CastDebug_ApplyConfigFromProfile()
            }
        } catch {
        }
        ok := true
    } catch as e {
        ok := false
        try {
            Logger_Exception("UI", e, Map("where","ApplyGeneral_Save", "profile", name))
        } catch {
        }
    }

    ; 运行时后续
    if (ok) {
        try {
            Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        } catch {
        }
        try {
            Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
        } catch {
        }
        try {
            Logger_Info("UI", "ApplyGeneral end", Map("hk", hk, "poll", pi, "delay", delay))
        } catch {
        }
        Notify(T("msg.saved","配置已保存"))
    } else {
        MsgBox T("msg.saveFail","保存失败")
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

Profile_IsMouseHotkey(hk) {
    if (hk = "") {
        return false
    }
    return RegExMatch(hk, "i)^(~?)(XButton1|XButton2|MButton|Wheel(Up|Down|Left|Right))$")
}

Profile_UI_SetStartHotkeyEcho(hk) {
    global UI, g_Profile_Populating

    g_Profile_Populating := true
    try {
        if Profile_IsMouseHotkey(hk) {
            try {
                UI.HkStart.Value := ""
            } catch {
            }
            try {
                UI.HkStart.Tag := hk
            } catch {
            }
            try {
                UI.LblStartEcho.Text := "鼠标: " hk
            } catch {
            }
        } else {
            try {
                UI.HkStart.Tag := ""
            } catch {
            }
            try {
                UI.LblStartEcho.Text := ""
            } catch {
            }
            try {
                UI.HkStart.Value := hk
            } catch {
            }
        }
    } catch {
    }
    g_Profile_Populating := false
}