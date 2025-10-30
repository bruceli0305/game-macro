#Requires AutoHotkey v2
; “配置”页：角色配置、热键与轮询、自动化配置、技能/点位两套面板（按钮切换）

UI_Page_Config_Build() {
    global UI

    ; ===== 角色配置 =====
    UI.GB_Profile := UI.Main.Add("GroupBox", "xm ym w860 h80", T("group.profile","角色配置"))
    UI.ProfilesDD := UI.Main.Add("DropDownList", "xp+12 yp+32 w280 vProfiles")
    UI.BtnNew     := UI.Main.Add("Button", "x+10 w80 h28", T("btn.new","新建"))
    UI.BtnClone   := UI.Main.Add("Button", "x+8  w80 h28", T("btn.clone","复制"))
    UI.BtnDelete  := UI.Main.Add("Button", "x+8  w80 h28", T("btn.delete","删除"))
    UI.BtnExport  := UI.Main.Add("Button", "x+16 w92 h28", T("btn.export","导出打包"))

    UI.BtnNew.OnEvent("Click", (*) => UI_Page_Config_NewProfile())
    UI.BtnClone.OnEvent("Click", (*) => UI_Page_Config_CloneProfile())
    UI.BtnDelete.OnEvent("Click", (*) => UI_Page_Config_DeleteProfile())
    UI.BtnExport.OnEvent("Click", (*) => UI_Page_Config_OnExport())

    ; ===== 热键与轮询 =====
    UI.GB_General := UI.Main.Add("GroupBox", "xm y+10 w860 h116", T("group.general","热键与轮询"))
    UI.LblStartStop := UI.Main.Add("Text", "xp+12 yp+50 Section", T("label.startStop","开始/停止："))
    UI.HkStart := UI.Main.Add("Hotkey", "x+6 w180")
    UI.LblPoll  := UI.Main.Add("Text", "x+18", T("label.pollMs","轮询(ms)："))
    UI.PollEdit := UI.Main.Add("Edit", "x+6 w90 Number Center")
    UI.LblDelay := UI.Main.Add("Text", "x+18", T("label.delayMs","全局延迟(ms)："))
    UI.CdEdit   := UI.Main.Add("Edit", "x+6 w100 Number Center")
    UI.BtnApply := UI.Main.Add("Button", "x+18 w80 h28", T("btn.apply","应用"))
    UI.BtnApply.OnEvent("Click", (*) => UI_Page_Config_ApplyGeneral())

    UI.LblPick := UI.Main.Add("Text", "xs ys+34", T("label.pickAvoid","取色避让："))
    UI.ChkPick := UI.Main.Add("CheckBox", "x+6 w18 h18")
    UI.LblOffY := UI.Main.Add("Text", "x+14", T("label.offsetY","Y偏移(px)："))
    UI.OffYEdit:= UI.Main.Add("Edit", "x+6 w80 Number Center")
    UI.LblDwell:= UI.Main.Add("Text", "x+14", T("label.dwellMs","等待(ms)："))
    UI.DwellEdit:=UI.Main.Add("Edit", "x+6 w90 Number Center")

    ; ===== 自动化配置 =====
    UI.GB_Auto := UI.Main.Add("GroupBox", "xm y+35 w860 h60", T("group.auto","自动化配置"))
    UI.BtnThreads := UI.Main.Add("Button", "xp+12 yp+28 w100 h28", T("btn.threads","线程配置"))
    UI.BtnRules   := UI.Main.Add("Button", "x+8 w100 h28", T("btn.rules","循环配置"))
    UI.BtnBuffs   := UI.Main.Add("Button", "x+8 w100 h28", T("btn.buffs","计时器配置"))
    UI.BtnDefault := UI.Main.Add("Button", "x+8 w100 h28", T("btn.default","默认技能"))
    UI.BtnThreads.OnEvent("Click", (*) => ThreadsManager_Show())
    UI.BtnRules.OnEvent("Click", (*) => RulesManager_Show())
    UI.BtnBuffs.OnEvent("Click", (*) => BuffsManager_Show())
    UI.BtnDefault.OnEvent("Click", (*) => DefaultSkillEditor_Show())

    ; ===== 页内切换按钮（替代内层 Tab）=====
    UI.BtnPaneSkills := UI.Main.Add("Button", "xm y+20 w120 h28", T("tab.skills","技能列表"))
    UI.BtnPanePoints := UI.Main.Add("Button", "x+8 w120 h28", T("tab.points","取色点位"))
    UI.BtnPaneSkills.OnEvent("Click", (*) => UI_Page_Config_ShowPane(1))
    UI.BtnPanePoints.OnEvent("Click", (*) => UI_Page_Config_ShowPane(2))

    ; -- 技能页控件 --
    UI.SkillLV := UI.Main.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , [ T("col.skill.id","ID"), T("col.skill.name","技能名"), T("col.skill.key","键位")
          , T("col.skill.x","X"), T("col.skill.y","Y"), T("col.skill.color","颜色"), T("col.skill.tol","容差") ])
    UI.SkillLV.OnEvent("DoubleClick", (*) => UI_Page_Config_EditSelectedSkill())

    UI.BtnAddSkill  := UI.Main.Add("Button", "x12 y+8 w96 h28", T("btn.addSkill","新增技能"))
    UI.BtnEditSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.editSkill","编辑技能"))
    UI.BtnDelSkill  := UI.Main.Add("Button", "x+8 w96 h28", T("btn.delSkill","删除技能"))
    UI.BtnTestSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.testSkill","测试检测"))
    UI.BtnSaveSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    UI.BtnAddSkill.OnEvent("Click", (*) => UI_Page_Config_AddSkill())
    UI.BtnEditSkill.OnEvent("Click", (*) => UI_Page_Config_EditSelectedSkill())
    UI.BtnDelSkill.OnEvent("Click", (*) => UI_Page_Config_DeleteSelectedSkill())
    UI.BtnTestSkill.OnEvent("Click", (*) => UI_Page_Config_TestSelectedSkill())
    UI.BtnSaveSkill.OnEvent("Click", (*) => UI_Page_Config_SaveProfile())

    ; -- 点位页控件 --
    UI.PointLV := UI.Main.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , [ T("col.point.id","ID"), T("col.point.name","名称"), T("col.point.x","X")
          , T("col.point.y","Y"), T("col.point.color","颜色"), T("col.point.tol","容差") ])
    UI.PointLV.OnEvent("DoubleClick", (*) => UI_Page_Config_EditSelectedPoint())

    UI.BtnAddPoint  := UI.Main.Add("Button", "x12 y+8 w96 h28", T("btn.addPoint","新增点位"))
    UI.BtnEditPoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.editPoint","编辑点位"))
    UI.BtnDelPoint  := UI.Main.Add("Button", "x+8 w96 h28", T("btn.delPoint","删除点位"))
    UI.BtnTestPoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.testPoint","测试点位"))
    UI.BtnSavePoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    UI.BtnAddPoint.OnEvent("Click", (*) => UI_Page_Config_AddPoint())
    UI.BtnEditPoint.OnEvent("Click", (*) => UI_Page_Config_EditSelectedPoint())
    UI.BtnDelPoint.OnEvent("Click", (*) => UI_Page_Config_DeleteSelectedPoint())
    UI.BtnTestPoint.OnEvent("Click", (*) => UI_Page_Config_TestSelectedPoint())
    UI.BtnSavePoint.OnEvent("Click", (*) => UI_Page_Config_SaveProfile())

    ; 初始仅显示“技能”面板
    UI_Page_Config_ShowPane(1)

    ; 变更事件
    UI.ProfilesDD.OnEvent("Change", (*) => UI_Page_Config_ProfileChanged())
}

; 面板显隐切换
UI_Page_Config_ShowPane(pane := 1) {
    global UI
    pane := (pane=2) ? 2 : 1
    UI["InnerPane"] := pane

    ; 切换按钮：当前页按钮禁用（提供“选中”感）
    try UI.BtnPaneSkills.Enabled := (pane != 1)
    try UI.BtnPanePoints.Enabled := (pane != 2)

    ; 技能面板
    for ctl in [UI.SkillLV, UI.BtnAddSkill, UI.BtnEditSkill, UI.BtnDelSkill, UI.BtnTestSkill, UI.BtnSaveSkill]
        try ctl.Visible := (pane = 1)

    ; 点位面板
    for ctl in [UI.PointLV, UI.BtnAddPoint, UI.BtnEditPoint, UI.BtnDelPoint, UI.BtnTestPoint, UI.BtnSavePoint]
        try ctl.Visible := (pane = 2)
}

; ================= Profiles =================
UI_Page_Config_ReloadProfiles() {
    global UI, App
    App["Profiles"] := Storage_ListProfiles()
    if App["Profiles"].Length = 0 {
        data := Core_DefaultProfileData()
        Storage_SaveProfile(data)
        App["Profiles"] := Storage_ListProfiles()
    }
    UI.ProfilesDD.Delete()
    if App["Profiles"].Length
        UI.ProfilesDD.Add(App["Profiles"])
    target := App["CurrentProfile"] != "" ? App["CurrentProfile"] : App["Profiles"][1]
    sel := 1
    for i, name in App["Profiles"] {
        if (name = target) {
            sel := i
            break
        }
    }
    UI.ProfilesDD.Value := sel
    UI_Page_Config_SwitchProfile(UI.ProfilesDD.Text)
}
UI_Page_Config_ProfileChanged() {
    UI_Page_Config_SwitchProfile(UI.ProfilesDD.Text)
}

UI_Page_Config_SwitchProfile(name) {
    global UI, App
    App["CurrentProfile"] := name
    App["ProfileData"] := Storage_LoadProfile(name)

    UI.HkStart.Value := App["ProfileData"].StartHotkey
    UI.PollEdit.Value := App["ProfileData"].PollIntervalMs
    UI.CdEdit.Value := App["ProfileData"].SendCooldownMs
    UI.ChkPick.Value := App["ProfileData"].PickHoverEnabled ? 1 : 0
    UI.OffYEdit.Value := App["ProfileData"].PickHoverOffsetY
    UI.DwellEdit.Value := App["ProfileData"].PickHoverDwellMs

    Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    UI_Page_Config_RefreshSkillList()
    UI_Page_Config_RefreshPointList()
    if Poller_IsRunning() {
        Poller_Stop()
        Poller_Start()
    }
    WorkerPool_Rebuild()
    Counters_Init()
    try Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
}

; ================= Skills =================
UI_Page_Config_RefreshSkillList() {
    global UI, App
    UI.SkillLV.Opt("-Redraw")
    UI.SkillLV.Delete()
    for idx, s in App["ProfileData"].Skills
        UI.SkillLV.Add("", idx, s.Name, s.Key, s.X, s.Y, s.Color, s.Tol)
    loop 7
        UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
    UI.SkillLV.Opt("+Redraw")
}
UI_Page_Config_AddSkill() {
    SkillEditor_Open({}, 0, (newSkill, idx) => (
        App["ProfileData"].Skills.Push(newSkill),
        UI_Page_Config_RefreshSkillList()
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    ))
}
UI_Page_Config_EditSelectedSkill() {
    global UI, App
    row := UI.SkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := Integer(UI.SkillLV.GetText(row, 1))
    cur := App["ProfileData"].Skills[idx]
    SkillEditor_Open(cur, idx, (newSkill, idx2) => (
        App["ProfileData"].Skills[idx2] := newSkill,
        UI_Page_Config_RefreshSkillList()
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    ))
}
UI_Page_Config_DeleteSelectedSkill() {
    global UI, App
    row := UI.SkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := Integer(UI.SkillLV.GetText(row, 1))
    if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    App["ProfileData"].Skills.RemoveAt(idx)
    UI_Page_Config_RefreshSkillList()
    Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    Notify(T("msg.skillDeleted","已删除技能"))
}
UI_Page_Config_TestSelectedSkill() {
    global UI, App
    row := UI.SkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := Integer(UI.SkillLV.GetText(row, 1))
    if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    s := App["ProfileData"].Skills[idx]
    offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
    dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
    c := Pixel_GetColorWithMouseAway(s.X, s.Y, offY, dwell)
    match := Pixel_ColorMatch(c, Pixel_HexToInt(s.Color), s.Tol)
    MsgBox T("msg.pointInfo","检测点:") " X=" s.X " Y=" s.Y "`n"
        . T("msg.current","当前颜色: ") Pixel_ColorToHex(c) "`n"
        . T("msg.target","目标颜色: ") s.Color "`n"
        . T("msg.tol","容差: ") s.Tol "`n"
        . T("msg.result","结果: ") (match ? T("msg.match","匹配") : T("msg.nomatch","不匹配"))
}

; ================= Points =================
UI_Page_Config_RefreshPointList() {
    global UI, App
    UI.PointLV.Opt("-Redraw")
    UI.PointLV.Delete()
    for idx, p in App["ProfileData"].Points
        UI.PointLV.Add("", idx, p.Name, p.X, p.Y, p.Color, p.Tol)
    loop 6
        UI.PointLV.ModifyCol(A_Index, "AutoHdr")
    UI.PointLV.Opt("+Redraw")
}
UI_Page_Config_AddPoint() {
    PointEditor_Open({}, 0, (newPoint, idx) => (
        App["ProfileData"].Points.Push(newPoint),
        UI_Page_Config_RefreshPointList()
    ))
}
UI_Page_Config_EditSelectedPoint() {
    global UI, App
    row := UI.PointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := Integer(UI.PointLV.GetText(row, 1))
    cur := App["ProfileData"].Points[idx]
    PointEditor_Open(cur, idx, (newPoint, idx2) => (
        App["ProfileData"].Points[idx2] := newPoint,
        UI_Page_Config_RefreshPointList()
    ))
}
UI_Page_Config_DeleteSelectedPoint() {
    global UI, App
    row := UI.PointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := Integer(UI.PointLV.GetText(row, 1))
    if (idx < 1 || idx > App["ProfileData"].Points.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    App["ProfileData"].Points.RemoveAt(idx)
    UI_Page_Config_RefreshPointList()
    Notify(T("msg.pointDeleted","已删除点位"))
}
UI_Page_Config_TestSelectedPoint() {
    global UI, App
    row := UI.PointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := Integer(UI.PointLV.GetText(row, 1))
    if (idx < 1 || idx > App["ProfileData"].Points.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    p := App["ProfileData"].Points[idx]
    offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
    dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
    c := Pixel_GetColorWithMouseAway(p.X, p.Y, offY, dwell)
    match := Pixel_ColorMatch(c, Pixel_HexToInt(p.Color), p.Tol)
    MsgBox T("msg.pointInfo","检测点:") " X=" p.X " Y=" p.Y "`n"
        . T("msg.current","当前颜色: ") Pixel_ColorToHex(c) "`n"
        . T("msg.target","目标颜色: ") p.Color "`n"
        . T("msg.tol","容差: ") p.Tol "`n"
        . T("msg.result","结果: ") (match ? T("msg.match","匹配") : T("msg.nomatch","不匹配"))
}

; ================= New/Clone/Delete/Export（下略：保持不变） =================
UI_Page_Config_NewProfile() {
    dlg := Gui("+Owner" UI.Main.Hwnd, T("dlg.newProfile","新建配置"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , T("label.profileName","配置名称："))
    nameEdit := dlg.Add("Edit", "w260")
    btnCreate := dlg.Add("Button", "xm w88", T("btn.create","创建"))
    btnCancel := dlg.Add("Button", "x+8 w88", T("btn.cancel","取消"))
    btnCreate.OnEvent("Click", (*) => (
        (Trim(nameEdit.Value)="")
            ? (MsgBox T("msg.nameEmpty","名称不可为空"))
            : ( (data := Core_DefaultProfileData()
                , data.Name := Trim(nameEdit.Value)
                , Storage_SaveProfile(data)
                , Notify(T("msg.created","已创建：") data.Name)
                , dlg.Destroy()
                , UI_Page_Config_ReloadProfiles())
              )
    ))
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()
}

UI_Page_Config_CloneProfile() {
    global App
    if App["CurrentProfile"] = "" {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }
    src := App["CurrentProfile"]
    dlg := Gui("+Owner" UI.Main.Hwnd, T("dlg.cloneProfile","复制配置"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , T("label.newProfileName","新配置名称："))
    nameEdit := dlg.Add("Edit", "w260", src "_Copy")
    btnCopy := dlg.Add("Button", "xm w88", T("btn.copy","复制"))
    btnCancel := dlg.Add("Button", "x+8 w88", T("btn.cancel","取消"))
    btnCopy.OnEvent("Click", (*) => (
        (Trim(nameEdit.Value)="")
            ? (MsgBox T("msg.nameEmpty","名称不可为空"))
            : ( data := Storage_LoadProfile(src)
              , data.Name := Trim(nameEdit.Value)
              , Storage_SaveProfile(data)
              , Notify(T("msg.cloned","已复制为：") data.Name)
              , dlg.Destroy()
              , UI_Page_Config_ReloadProfiles() )
    ))
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()
}

UI_Page_Config_DeleteProfile() {
    global App
    if App["CurrentProfile"] = "" {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }
    if App["Profiles"].Length <= 1 {
        MsgBox T("msg.keepOne","至少保留一个配置。")
        return
    }
    if Confirm(T("confirm.deleteProfile","确定删除配置：") App["CurrentProfile"] "？") {
        Storage_DeleteProfile(App["CurrentProfile"])
        Notify(T("msg.deleted","已删除：") App["CurrentProfile"])
        App["CurrentProfile"] := ""
        UI_Page_Config_ReloadProfiles()
    }
}

UI_Page_Config_OnExport() {
    global App
    Exporter_ExportProfile(App["CurrentProfile"])
}

UI_Page_Config_SaveProfile() {
    global App
    Storage_SaveProfile(App["ProfileData"])
    Notify(T("msg.saved","配置已保存"))
    UI_Page_Config_ReloadProfiles()
}

UI_Page_Config_ApplyGeneral() {
    global UI, App
    delay := (UI.CdEdit.Value != "") ? Integer(UI.CdEdit.Value) : 0
    App["ProfileData"].StartHotkey := UI.HkStart.Value
    App["ProfileData"].PollIntervalMs := (UI.PollEdit.Value != "") ? Integer(UI.PollEdit.Value) : 25
    App["ProfileData"].SendCooldownMs := delay
    App["ProfileData"].PickHoverEnabled := UI.ChkPick.Value ? 1 : 0
    App["ProfileData"].PickHoverOffsetY := (UI.OffYEdit.Value != "") ? Integer(UI.OffYEdit.Value) : -60
    App["ProfileData"].PickHoverDwellMs := (UI.DwellEdit.Value != "") ? Integer(UI.DwellEdit.Value) : 120
    Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    UI_Page_Config_SaveProfile()
}