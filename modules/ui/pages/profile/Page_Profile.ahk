#Requires AutoHotkey v2

; 概览与配置（仅保留 角色配置 + 热键与轮询/拾色）
; 不再依赖 UI_Page_Config_* 外部函数，全部事件在本页实现
; 严格块结构写法；包含强力回退刷新，确保下拉与参数可用

Page_Profile_Build(page) {
    global UI

    ; 安全获取右侧面板区域：优先 UI_GetPageRect，失败回退
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== Group: 角色配置 ======
    UI.GB_Profile := UI.Main.Add("GroupBox", Format("x{} y{} w{} h80", rc.X, rc.Y, rc.W), T("group.profile","角色配置"))
    page.Controls.Push(UI.GB_Profile)

    UI.ProfilesDD := UI.Main.Add("DropDownList", Format("x{} y{} w280", rc.X + 12, rc.Y + 32))
    page.Controls.Push(UI.ProfilesDD)

    UI.BtnNew := UI.Main.Add("Button", "x+10 w80 h28", T("btn.new","新建"))
    UI.BtnClone := UI.Main.Add("Button", "x+8 w80 h28", T("btn.clone","复制"))
    UI.BtnDelete := UI.Main.Add("Button", "x+8 w80 h28", T("btn.delete","删除"))
    UI.BtnExport := UI.Main.Add("Button", "x+16 w92 h28", T("btn.export","导出打包"))
    page.Controls.Push(UI.BtnNew)
    page.Controls.Push(UI.BtnClone)
    page.Controls.Push(UI.BtnDelete)
    page.Controls.Push(UI.BtnExport)

    ; ====== Group: 热键与轮询/拾色 ======
    gy := rc.Y + 80 + 10
    UI.GB_General := UI.Main.Add("GroupBox", Format("x{} y{} w{} h152", rc.X, gy, rc.W), T("group.general","热键与轮询"))
    page.Controls.Push(UI.GB_General)

    ; 行1：开始/停止 + 捕获鼠标键 + 轮询/延迟
    UI.LblStartStop := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12, gy + 50), T("label.startStop","开始/停止："))
    page.Controls.Push(UI.LblStartStop)

    UI.HkStart := UI.Main.Add("Hotkey", Format("x{} y{} w180", rc.X + 12 + 90, gy + 46))
    page.Controls.Push(UI.HkStart)

    UI.BtnCapStartMouse := UI.Main.Add("Button", Format("x{} y{} w110 h28", rc.X + 12 + 90 + 186, gy + 44), T("btn.captureMouse","捕获鼠标键"))
    page.Controls.Push(UI.BtnCapStartMouse)

    UI.LblPoll  := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12 + 90 + 186 + 116, gy + 50), T("label.pollMs","轮询(ms)："))
    page.Controls.Push(UI.LblPoll)
    UI.PollEdit := UI.Main.Add("Edit", "x+6 w90 Number Center")
    page.Controls.Push(UI.PollEdit)

    UI.LblDelay := UI.Main.Add("Text", "x+18", T("label.delayMs","全局延迟(ms)："))
    page.Controls.Push(UI.LblDelay)
    UI.CdEdit   := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.CdEdit)

    UI.BtnApply := UI.Main.Add("Button", "x+18 w80 h28", T("btn.apply","应用"))
    page.Controls.Push(UI.BtnApply)

    ; 行2：取色避让与拾色确认键
    UI.LblPick := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12, gy + 84), T("label.pickAvoid","取色避让："))
    page.Controls.Push(UI.LblPick)

    UI.ChkPick := UI.Main.Add("CheckBox", "x+6 w18 h18")
    page.Controls.Push(UI.ChkPick)

    UI.LblOffY  := UI.Main.Add("Text", "x+14", T("label.offsetY","Y偏移(px)："))
    page.Controls.Push(UI.LblOffY)

    UI.OffYEdit := UI.Main.Add("Edit", "x+6 w80 Number Center")
    page.Controls.Push(UI.OffYEdit)

    UI.LblDwell := UI.Main.Add("Text", "x+14", T("label.dwellMs","等待(ms)："))
    page.Controls.Push(UI.LblDwell)

    UI.DwellEdit:= UI.Main.Add("Edit", "x+6 w90 Number Center")
    page.Controls.Push(UI.DwellEdit)

    UI.LblPickKey := UI.Main.Add("Text", "x+14", T("label.pickKey","拾色热键："))
    page.Controls.Push(UI.LblPickKey)

    UI.DdPickKey  := UI.Main.Add("DropDownList", "x+6 w120")
    UI.DdPickKey.Add(["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"])
    page.Controls.Push(UI.DdPickKey)

    ; ====== 事件绑定（全部改为本页回调） ======
    UI.ProfilesDD.OnEvent("Change", Profile_OnProfilesChanged)
    UI.BtnNew.OnEvent("Click", Profile_OnNew)
    UI.BtnClone.OnEvent("Click", Profile_OnClone)
    UI.BtnDelete.OnEvent("Click", Profile_OnDelete)
    UI.BtnExport.OnEvent("Click", Profile_OnExport)
    UI.BtnCapStartMouse.OnEvent("Click", Profile_OnCaptureStartMouse)
    UI.BtnApply.OnEvent("Click", Profile_OnApplyGeneral)

    ; ====== 首次刷新（强力回退） ======
    Profile_RefreshAll_Strong()
}

Page_Profile_Layout(rc) {
    try {
        UI.GB_Profile.Move(rc.X, rc.Y, rc.W)
        UI.GB_General.Move(rc.X, rc.Y + 90, rc.W)
    } catch {
    }
}

; ====== 本页内部：事件与强力回退 ======

Profile_OnProfilesChanged(*) {
    try {
        name := UI.ProfilesDD.Text
        if (name != "") {
            Profile_SwitchProfile_Strong(name)
        }
    } catch {
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
    try {
        data := Core_DefaultProfileData()
        data.Name := name
        Storage_SaveProfile(data)
        App["CurrentProfile"] := name
        Profile_RefreshAll_Strong()
        Notify(T("msg.created","已创建：") name)
    } catch as e {
        MsgBox T("msg.createFail","创建失败：") e.Message
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
    try {
        data := Storage_LoadProfile(src)
        data.Name := newName
        Storage_SaveProfile(data)
        App["CurrentProfile"] := newName
        Profile_RefreshAll_Strong()
        Notify(T("msg.cloned","已复制为：") newName)
    } catch as e {
        MsgBox T("msg.cloneFail","复制失败：") e.Message
    }
}

Profile_OnDelete(*) {
    global App
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
        MsgBox T("msg.deleteFail","删除失败：") e.Message
    }
}

Profile_OnExport(*) {
    global App
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
    try {
        Exporter_ExportProfile(cur)
    } catch as e {
        MsgBox T("msg.exportFail","导出失败：") e.Message
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
            UI.HkStart.Value := key
        } catch {
        }
        try {
            Hotkeys_BindStartHotkey(key)
        } catch {
        }
    }
}

Profile_OnApplyGeneral(*) {
    global App, UI
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

        Notify(T("msg.saved","配置已保存"))
    } catch as e {
        MsgBox T("msg.saveFail","保存失败：") e.Message
    }
}
; ====== Fallback：计算右侧面板区域（当 UI_GetPageRect 不可用时） ======
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