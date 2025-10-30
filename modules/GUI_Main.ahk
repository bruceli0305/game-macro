; GUI_Main.ahk - 顶层Tab布局（第1页=配置；第2页=设置）

; 全局控件句柄
global gMain, gProfilesDD, gHkStart, gPollEdit, gCdEdit, gSkillLV
global gGBProfile, gGBGeneral
global gBtnNew, gBtnClone, gBtnDelete, gBtnExport, gBtnApply
global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave
global gChkPickAway, gPickOffsetEdit, gPickDwellEdit
global gPointLV
global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
global gTabMain
global gGBAuto, gBtnRuleCfg, gBtnBuffCfg
global gBtnThreads
global gBtnDefaultCfg
global gTopTab
global gDdLang, gBtnApplyLang, gBtnOpenLang, gLblLang, gLblNote

; General 分组内标签（用于显隐）
global gLblStartStop, gLblPoll, gLblDelay
global gLblPickAvoid, gLblOffsetY, gLblDwell

; 预初始化（避免 #Warn）
gTopTab := 0
gBtnDefaultCfg := 0
gTabMain := 0
gSkillLV := 0
gPointLV := 0
gBtnAdd := 0, gBtnEdit := 0, gBtnDel := 0, gBtnTest := 0, gBtnSave := 0
gBtnPAdd := 0, gBtnPEdit := 0, gBtnPDel := 0, gBtnPTest := 0, gBtnPSave := 0
gGBAuto := 0, gBtnRuleCfg := 0, gBtnBuffCfg := 0
gDdLang := 0, gBtnApplyLang := 0, gBtnOpenLang := 0, gLblLang := 0, gLblNote := 0
gLblStartStop := 0, gLblPoll := 0, gLblDelay := 0
gLblPickAvoid := 0, gLblOffsetY := 0, gLblDwell := 0

GUI_Main_Show() {
    global gMain, gProfilesDD, gHkStart, gPollEdit, gCdEdit, gSkillLV
    global gGBProfile, gGBGeneral
    global gBtnNew, gBtnClone, gBtnDelete, gBtnExport, gBtnApply, App
    global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave
    global gChkPickAway, gPickOffsetEdit, gPickDwellEdit
    global gPointLV
    global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
    global gTabMain
    global gGBAuto, gBtnRuleCfg, gBtnBuffCfg
    global gBtnThreads, gBtnDefaultCfg
    global gTopTab
    global gDdLang, gBtnApplyLang, gBtnOpenLang, gLblLang, gLblNote
    global gLblStartStop, gLblPoll, gLblDelay
    global gLblPickAvoid, gLblOffsetY, gLblDwell

    ; 若语言未初始化，则兜底
    try {
        if !(IsSet(gLang) && gLang.Has("Code"))
            Lang_Init("zh-CN")
    } catch {
        Lang_Init("zh-CN")
    }

    gMain := Gui("+Resize", T("app.title", "输出取色宏 - v0.0.1-Alpha-0.1"))
    gMain.MarginX := 14
    gMain.MarginY := 12
    gMain.SetFont("s10", "Segoe UI")
    gMain.OnEvent("Close", (*) => ExitApp())

    ; 顶层 Tab：第1页=配置，第2页=设置
    gTopTab := gMain.Add("Tab3", "xm ym w860 h720"
        , [ T("tab.main","配置"), T("tab.settings","设置") ])

    ; 顶层Tab 第1页：原整页
    gTopTab.UseTab(1)

    ; ====== 分组：角色配置 ======
    gGBProfile := gMain.Add("GroupBox", "xm ym w860 h80", T("group.profile","角色配置"))
    gProfilesDD := gMain.Add("DropDownList", "xp+12 yp+32 w280 vProfiles")
    gBtnNew    := gMain.Add("Button", "x+10 w80 h28", T("btn.new","新建"))
    gBtnClone  := gMain.Add("Button", "x+8  w80 h28", T("btn.clone","复制"))
    gBtnDelete := gMain.Add("Button", "x+8  w80 h28", T("btn.delete","删除"))
    gBtnExport := gMain.Add("Button", "x+16 w92 h28", T("btn.export","导出打包"))
    gBtnNew.OnEvent("Click", (*) => GUI_NewProfile())
    gBtnClone.OnEvent("Click", (*) => GUI_CloneProfile())
    gBtnDelete.OnEvent("Click", (*) => GUI_DeleteProfile())
    gBtnExport.OnEvent("Click", OnExport)

    ; ====== 分组：热键与轮询 ======
    gGBGeneral := gMain.Add("GroupBox", "xm y+10 w860 h116", T("group.general","热键与轮询"))

    ; 行1
    gLblStartStop := gMain.Add("Text", "xp+12 yp+50 Section", T("label.startStop","开始/停止："))
    gHkStart := gMain.Add("Hotkey", "x+6 w180")
    gLblPoll := gMain.Add("Text", "x+18", T("label.pollMs","轮询(ms)："))
    gPollEdit := gMain.Add("Edit", "x+6 w90 Number Center")
    gLblDelay := gMain.Add("Text", "x+18", T("label.delayMs","全局延迟(ms)："))
    gCdEdit := gMain.Add("Edit", "x+6 w100 Number Center")
    gBtnApply := gMain.Add("Button", "x+18 w80 h28", T("btn.apply","应用"))
    gBtnApply.OnEvent("Click", (*) => GUI_ApplyGeneral())

    ; 行2
    gLblPickAvoid := gMain.Add("Text", "xs ys+34", T("label.pickAvoid","取色避让："))
    gChkPickAway := gMain.Add("CheckBox", "x+6 w18 h18")
    gLblOffsetY := gMain.Add("Text", "x+14", T("label.offsetY","Y偏移(px)："))
    gPickOffsetEdit := gMain.Add("Edit", "x+6 w80 Number Center")
    gLblDwell := gMain.Add("Text", "x+14", T("label.dwellMs","等待(ms)："))
    gPickDwellEdit := gMain.Add("Edit", "x+6 w90 Number Center")

    ; ====== 分组：自动化配置 ======
    gGBAuto := gMain.Add("GroupBox", "xm y+35 w860 h60", T("group.auto","自动化配置"))
    gBtnThreads    := gMain.Add("Button", "xp+12 yp+28 w100 h28", T("btn.threads","线程配置"))
    gBtnRuleCfg    := gMain.Add("Button", "x+8 w100 h28", T("btn.rules","循环配置"))
    gBtnBuffCfg    := gMain.Add("Button", "x+8 w100 h28", T("btn.buffs","计时器配置"))
    gBtnDefaultCfg := gMain.Add("Button", "x+8 w100 h28", T("btn.default","默认技能"))
    gBtnThreads.OnEvent("Click", (*) => ThreadsManager_Show())
    gBtnRuleCfg.OnEvent("Click", (*) => RulesManager_Show())
    gBtnBuffCfg.OnEvent("Click", (*) => BuffsManager_Show())
    gBtnDefaultCfg.OnEvent("Click", (*) => DefaultSkillEditor_Show())

    ; ====== 内层 Tab：技能列表 / 取色点位 ======
    ; 重要：内层改用 Tab2 并关闭主题，解决嵌套页眉不显示
    gTabMain := gMain.Add("Tab2", "xm y+20 w860 h440"
        , [ T("tab.skills","技能列表"), T("tab.points","取色点位") ])
    gTabMain.Opt("-Theme")

    ; 技能页
    gTabMain.UseTab(1)
    gSkillLV := gMain.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , [ T("col.skill.id","ID"), T("col.skill.name","技能名"), T("col.skill.key","键位")
          , T("col.skill.x","X"), T("col.skill.y","Y"), T("col.skill.color","颜色"), T("col.skill.tol","容差") ])
    gSkillLV.OnEvent("DoubleClick", (*) => GUI_EditSelectedSkill())
    gBtnAdd  := gMain.Add("Button", "x12 y+8 w96 h28", T("btn.addSkill","新增技能"))
    gBtnEdit := gMain.Add("Button", "x+8 w96 h28", T("btn.editSkill","编辑技能"))
    gBtnDel  := gMain.Add("Button", "x+8 w96 h28", T("btn.delSkill","删除技能"))
    gBtnTest := gMain.Add("Button", "x+8 w96 h28", T("btn.testSkill","测试检测"))
    gBtnSave := gMain.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    gBtnAdd.OnEvent("Click", (*) => GUI_AddSkill())
    gBtnEdit.OnEvent("Click", (*) => GUI_EditSelectedSkill())
    gBtnDel.OnEvent("Click", (*) => GUI_DeleteSelectedSkill())
    gBtnTest.OnEvent("Click", (*) => GUI_TestSelectedSkill())
    gBtnSave.OnEvent("Click", (*) => GUI_SaveCurrentProfile())

    ; 点位页
    gTabMain.UseTab(2)
    gPointLV := gMain.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , [ T("col.point.id","ID"), T("col.point.name","名称"), T("col.point.x","X")
          , T("col.point.y","Y"), T("col.point.color","颜色"), T("col.point.tol","容差") ])
    gPointLV.OnEvent("DoubleClick", (*) => GUI_EditSelectedPoint())
    gBtnPAdd  := gMain.Add("Button", "x12 y+8 w96 h28", T("btn.addPoint","新增点位"))
    gBtnPEdit := gMain.Add("Button", "x+8 w96 h28", T("btn.editPoint","编辑点位"))
    gBtnPDel  := gMain.Add("Button", "x+8 w96 h28", T("btn.delPoint","删除点位"))
    gBtnPTest := gMain.Add("Button", "x+8 w96 h28", T("btn.testPoint","测试点位"))
    gBtnPSave := gMain.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    gBtnPAdd.OnEvent("Click", (*) => GUI_AddPoint())
    gBtnPEdit.OnEvent("Click", (*) => GUI_EditSelectedPoint())
    gBtnPDel.OnEvent("Click", (*) => GUI_DeleteSelectedPoint())
    gBtnPTest.OnEvent("Click", (*) => GUI_TestSelectedPoint())
    gBtnPSave.OnEvent("Click", (*) => GUI_SaveCurrentProfile())

    ; 退出内层 Tab 上下文
    gTabMain.UseTab()

    ; 顶层Tab 第2页：设置（语言切换）
    gTopTab.UseTab(2)
    gLblLang := gMain.Add("Text", "x12 y12 w120", T("label.language","界面语言："))
    gDdLang := gMain.Add("DropDownList", "x+6 w220")
    packs := Lang_ListPackages()
    langNames := []
    for _, p in packs
        langNames.Push(p.Name " (" p.Code ")")
    if langNames.Length
        gDdLang.Add(langNames)
    curCode := gLang.Has("Code") ? gLang["Code"] : "zh-CN"
    sel := 1
    for i, p in packs
        if (p.Code = curCode) {
            sel := i
            break
        }
    gDdLang.Value := sel

    gBtnApplyLang := gMain.Add("Button", "xm y+10 w120", T("btn.applyLang","应用语言"))
    gBtnOpenLang  := gMain.Add("Button", "x+8 w140", T("btn.openLangDir","打开语言目录"))
    gLblNote      := gMain.Add("Text", "xm y+8", T("label.noteRestart","应用后将重建界面"))
    gBtnApplyLang.OnEvent("Click", (*) => GUI_ApplyLanguage(gDdLang, packs))
    gBtnOpenLang.OnEvent("Click", (*) => Run(A_ScriptDir "\Languages"))

    ; 退出顶层 Tab 上下文
    gTopTab.UseTab()

    ; 顶层 Tab 切换：只显示当前页控件
    gTopTab.OnEvent("Change", GUI_OnTopTabChange)

    ; 自适应布局：先隐藏显示再布局，避免首屏覆盖
    gMain.OnEvent("Size", GUI_OnResize)

    ; 强制选中第1页（配置页），避免 Value=0 导致首页被隐藏
    gTopTab.Value := 1

    ; 先隐藏窗口，获取客户区并首轮布局
    gMain.Show("w890 h750 Hide")
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "ptr", gMain.Hwnd, "ptr", rc.Ptr)
    cw := NumGet(rc, 8, "Int"), ch := NumGet(rc, 12, "Int")
    GUI_OnResize(gMain, 0, cw, ch)

    ; 初始化显隐：只显示第1页控件，隐藏设置页控件
    GUI_ToggleSettingsPage(false)
    GUI_ToggleMainPage(true)

    ; 再显示窗口
    gMain.Show()

    ; 加载配置
    GUI_ReloadProfiles()
    gProfilesDD.OnEvent("Change", (*) => GUI_ProfileChanged())
}

OnExport(*) {
    global App
    Exporter_ExportProfile(App["CurrentProfile"])
}

; 顶层Tab切换：显隐两页控件
GUI_OnTopTabChange(ctrl, *) {
    val := ctrl.Value
    if (val <= 0)
        val := 1
    showMain := (val = 1)
    GUI_ToggleMainPage(showMain)
    GUI_ToggleSettingsPage(!showMain)
    ; 强制重绘内层Tab，保险
    try DllCall("user32\UpdateWindow", "ptr", gTabMain.Hwnd)
}

GUI_ToggleMainPage(vis) {
    for ctl in [
        gGBProfile, gProfilesDD, gBtnNew, gBtnClone, gBtnDelete, gBtnExport
      , gGBGeneral, gLblStartStop, gHkStart, gLblPoll, gPollEdit, gLblDelay, gCdEdit, gBtnApply
      , gLblPickAvoid, gChkPickAway, gLblOffsetY, gPickOffsetEdit, gLblDwell, gPickDwellEdit
      , gGBAuto, gBtnThreads, gBtnRuleCfg, gBtnBuffCfg, gBtnDefaultCfg
      , gTabMain
    ] {
        try ctl.Visible := vis
    }
}

GUI_ToggleSettingsPage(vis) {
    for ctl in [gLblLang, gDdLang, gBtnApplyLang, gBtnOpenLang, gLblNote] {
        try ctl.Visible := vis
    }
}

; 自适应布局：窗口大小变化时重算尺寸
GUI_OnResize(gui, minmax, w, h) {
    global gTopTab
    global gGBProfile, gGBGeneral, gGBAuto, gBtnThreads, gBtnRuleCfg, gBtnBuffCfg, gBtnDefaultCfg
    global gTabMain, gSkillLV, gPointLV
    global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave
    global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
    global gDdLang, gBtnApplyLang, gBtnOpenLang, gLblLang, gLblNote

    marginX := gui.MarginX
    marginY := gui.MarginY

    ; 顶层 Tab 占满窗口
    if IsObject(gTopTab) {
        gTopTab.Move(marginX, marginY, Max(w - marginX*2, 420), Max(h - marginY*2, 320))
    } else {
        return
    }

    rcTop := GUI_TabPageRect(gTopTab)  ; 顶层Tab当前页内容区域
    innerPad := 10

    ; 第1页（原整页）：三大分组 + 内层Tab（技能/点位）
    profileH := 80
    generalH := 116
    autoH := 60
    gapY := 10
    gbW := Max(rcTop.W - innerPad*2, 420)
    x0 := rcTop.X + innerPad
    y0 := rcTop.Y + innerPad

    if IsObject(gGBProfile) {
        gGBProfile.Move(x0, y0, gbW, profileH)
    }
    if IsObject(gGBGeneral) {
        gGBGeneral.Move(x0, y0 + profileH + gapY, gbW, generalH)
    }

    ; 自动化配置分组
    autoTop := y0 + profileH + gapY + generalH + gapY
    if IsObject(gGBAuto) {
        gGBAuto.Move(x0, autoTop, gbW, autoH)
        gGBAuto.GetPos(&ax, &ay, &aw, &ah)
        pad := 12, btnW := 100, btnH := 28, gap := 8, btnY := ay + ah - pad - btnH
        if IsObject(gBtnThreads)
            gBtnThreads.Move(ax + pad, btnY, btnW, btnH)
        if IsObject(gBtnRuleCfg)
            gBtnRuleCfg.Move(ax + pad + (btnW + gap) * 1, btnY, btnW, btnH)
        if IsObject(gBtnBuffCfg)
            gBtnBuffCfg.Move(ax + pad + (btnW + gap) * 2, btnY, btnW, btnH)
        if IsObject(gBtnDefaultCfg)
            gBtnDefaultCfg.Move(ax + pad + (btnW + gap) * 3, btnY, btnW, btnH)
    }

    ; 内层 Tab（技能/点位）
    if IsObject(gTabMain) {
        tabTop := autoTop + autoH + gapY
        tabH := Max(rcTop.H - (tabTop - rcTop.Y) - innerPad, 260)
        gTabMain.Move(x0, tabTop, gbW, tabH)

        ; 内层Tab页内容区域
        rc := GUI_TabPageRect(gTabMain)
        innerPad2 := 10
        btnBarH := 36
        lvX := rc.X + innerPad2
        lvY := rc.Y + innerPad2
        lvW := Max(rc.W - innerPad2 * 2, 100)
        lvH := Max(rc.H - innerPad2 * 2 - btnBarH, 80)

        ; 技能页内容
        if IsObject(gSkillLV) {
            gSkillLV.Move(lvX, lvY, lvW, lvH)
            btnY := lvY + lvH + 8
            btnW := 96, btnH := 28, gap := 8, startX := lvX
            if IsObject(gBtnAdd) {
                gBtnAdd.Move(startX, btnY, btnW, btnH)
                gBtnEdit.Move(startX + (btnW + gap) * 1, btnY, btnW, btnH)
                gBtnDel.Move(startX + (btnW + gap) * 2, btnY, btnW, btnH)
                gBtnTest.Move(startX + (btnW + gap) * 3, btnY, btnW, btnH)
                gBtnSave.Move(startX + (btnW + gap) * 4, btnY, btnW, btnH)
            }
            loop 7
                gSkillLV.ModifyCol(A_Index, "AutoHdr")
        }

        ; 点位页内容
        if IsObject(gPointLV) {
            gPointLV.Move(lvX, lvY, lvW, lvH)
            pbtnY := lvY + lvH + 8
            btnW := 96, btnH := 28, gap := 8, startX := lvX
            if IsObject(gBtnPAdd) {
                gBtnPAdd.Move(startX, pbtnY, btnW, btnH)
                gBtnPEdit.Move(startX + (btnW + gap) * 1, pbtnY, btnW, btnH)
                gBtnPDel.Move(startX + (btnW + gap) * 2, pbtnY, btnW, btnH)
                gBtnPTest.Move(startX + (btnW + gap) * 3, pbtnY, btnW, btnH)
                gBtnPSave.Move(startX + (btnW + gap) * 4, pbtnY, btnW, btnH)
            }
            loop 6
                gPointLV.ModifyCol(A_Index, "AutoHdr")
        }
    }

    ; 顶层Tab 第2页（设置）控件的布局
    if IsObject(gDdLang) {
        gLblLang.Move(x0, y0, 120, 24)
        gDdLang.Move(x0 + 120 + 6, y0, 220, 24)
        gBtnApplyLang.Move(x0, y0 + 40, 120, 28)
        gBtnOpenLang.Move(x0 + 120 + 8, y0 + 40, 140, 28)
        gLblNote.Move(x0, y0 + 78, Max(gbW, 200), 24)
    }
}

GUI_ReloadProfiles() {
    global App, gProfilesDD
    App["Profiles"] := Storage_ListProfiles()
    if App["Profiles"].Length = 0 {
        data := Core_DefaultProfileData()
        Storage_SaveProfile(data)
        App["Profiles"] := Storage_ListProfiles()
    }

    gProfilesDD.Delete()
    if App["Profiles"].Length
        gProfilesDD.Add(App["Profiles"])  ; v2 需数组

    target := App["CurrentProfile"] != "" ? App["CurrentProfile"] : App["Profiles"][1]
    selIndex := 1
    for i, name in App["Profiles"] {
        if (name = target) {
            selIndex := i
            break
        }
    }
    gProfilesDD.Value := selIndex
    GUI_SwitchProfile(gProfilesDD.Text)
}

GUI_ProfileChanged() {
    global gProfilesDD
    GUI_SwitchProfile(gProfilesDD.Text)
}

GUI_SwitchProfile(name) {
    global App, gHkStart, gPollEdit, gCdEdit
    global gChkPickAway, gPickOffsetEdit, gPickDwellEdit

    App["CurrentProfile"] := name
    App["ProfileData"] := Storage_LoadProfile(name)

    gHkStart.Value := App["ProfileData"].StartHotkey
    gPollEdit.Value := App["ProfileData"].PollIntervalMs
    gCdEdit.Value := App["ProfileData"].SendCooldownMs
    gChkPickAway.Value := App["ProfileData"].PickHoverEnabled ? 1 : 0
    gPickOffsetEdit.Value := App["ProfileData"].PickHoverOffsetY
    gPickDwellEdit.Value := App["ProfileData"].PickHoverDwellMs

    Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    GUI_RefreshSkillList()
    GUI_Points_RefreshList()
    if Poller_IsRunning() {
        Poller_Stop()
        Poller_Start()
    }
    WorkerPool_Rebuild()
    Counters_Init()
    ; 自动 ROI（如未引入 ROI 模块也不报错）
    try Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
}

GUI_RefreshSkillList() {
    global gSkillLV, App
    gSkillLV.Opt("-Redraw")
    gSkillLV.Delete()
    for idx, s in App["ProfileData"].Skills
        gSkillLV.Add("", idx, s.Name, s.Key, s.X, s.Y, s.Color, s.Tol)
    loop 7
        gSkillLV.ModifyCol(A_Index, "AutoHdr")
    gSkillLV.Opt("+Redraw")
}

GUI_SaveCurrentProfile() {
    global App
    Storage_SaveProfile(App["ProfileData"])
    Notify(T("msg.saved","配置已保存"))
    GUI_ReloadProfiles()
    global gProfilesDD
    for i, n in App["Profiles"]
        if n = App["CurrentProfile"]
            gProfilesDD.Value := i
}

GUI_ApplyGeneral() {
    global App, gHkStart, gPollEdit, gCdEdit
    global gChkPickAway, gPickOffsetEdit, gPickDwellEdit
    delay := (gCdEdit.Value != "") ? Integer(gCdEdit.Value) : 0
    App["ProfileData"].StartHotkey := gHkStart.Value
    App["ProfileData"].PollIntervalMs := (gPollEdit.Value != "") ? Integer(gPollEdit.Value) : 25
    App["ProfileData"].SendCooldownMs := delay
    App["ProfileData"].PickHoverEnabled := gChkPickAway.Value ? 1 : 0
    App["ProfileData"].PickHoverOffsetY := (gPickOffsetEdit.Value != "") ? Integer(gPickOffsetEdit.Value) : -60
    App["ProfileData"].PickHoverDwellMs := (gPickDwellEdit.Value != "") ? Integer(gPickDwellEdit.Value) : 120

    Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    GUI_SaveCurrentProfile()
}

GUI_Points_RefreshList() {
    global gPointLV, App
    gPointLV.Opt("-Redraw")
    gPointLV.Delete()
    for idx, p in App["ProfileData"].Points
        gPointLV.Add("", idx, p.Name, p.X, p.Y, p.Color, p.Tol)
    loop 6
        gPointLV.ModifyCol(A_Index, "AutoHdr")
    gPointLV.Opt("+Redraw")
}

GUI_AddPoint() {
    PointEditor_Open({}, 0, OnNewPoint)
    OnNewPoint(newPoint, idx) {
        global App
        App["ProfileData"].Points.Push(newPoint)
        GUI_Points_RefreshList()
    }
}

GUI_EditSelectedPoint() {
    global gPointLV, App
    row := gPointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := row
    cur := App["ProfileData"].Points[idx]
    PointEditor_Open(cur, idx, OnSaved)
    OnSaved(newPoint, idx2) {
        global App
        App["ProfileData"].Points[idx2] := newPoint
        GUI_Points_RefreshList()
    }
}

GUI_DeleteSelectedPoint() {
    global gPointLV, App
    row := gPointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Points.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    App["ProfileData"].Points.RemoveAt(idx)
    GUI_Points_RefreshList()
    Notify(T("msg.pointDeleted","已删除点位"))
}

GUI_TestSelectedPoint() {
    global gPointLV, App
    row := gPointLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectPoint","请先选中一个点位。")
        return
    }
    idx := row
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

GUI_NewProfile() {
    dlg := Gui(, T("dlg.newProfile","新建配置"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , T("label.profileName","配置名称："))
    nameEdit := dlg.Add("Edit", "w260")
    btnCreate := dlg.Add("Button", "xm w88", T("btn.create","创建"))
    btnCancel := dlg.Add("Button", "x+8 w88", T("btn.cancel","取消"))

    btnCreate.OnEvent("Click", OnCreate)
    btnCancel.OnEvent("Click", OnCancel)
    dlg.Show()

    OnCreate(*) {
        name := Trim(nameEdit.Value)
        if (name = "") {
            MsgBox T("msg.nameEmpty","名称不可为空")
            return
        }
        data := Core_DefaultProfileData()
        data.Name := name
        Storage_SaveProfile(data)
        Notify(T("msg.created","已创建：") name)
        dlg.Destroy()
        GUI_ReloadProfiles()
    }
    OnCancel(*) => dlg.Destroy()
}

GUI_CloneProfile() {
    global App
    if App["CurrentProfile"] = "" {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }
    src := App["CurrentProfile"]

    dlg := Gui(, T("dlg.cloneProfile","复制配置"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , T("label.newProfileName","新配置名称："))
    nameEdit := dlg.Add("Edit", "w260", src "_Copy")
    btnCopy := dlg.Add("Button", "xm w88", T("btn.copy","复制"))
    btnCancel := dlg.Add("Button", "x+8 w88", T("btn.cancel","取消"))

    btnCopy.OnEvent("Click", OnCopy)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()

    OnCopy(*) {
        name := Trim(nameEdit.Value)
        if (name = "") {
            MsgBox T("msg.nameEmpty","名称不可为空")
            return
        }
        data := Storage_LoadProfile(src)
        data.Name := name
        Storage_SaveProfile(data)
        Notify(T("msg.cloned","已复制为：") name)
        dlg.Destroy()
        GUI_ReloadProfiles()
    }
}

GUI_DeleteProfile() {
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
        GUI_ReloadProfiles()
    }
}

GUI_AddSkill() {
    SkillEditor_Open({}, 0, OnNewSkill)
    OnNewSkill(newSkill, idx) {
        global App
        App["ProfileData"].Skills.Push(newSkill)
        GUI_RefreshSkillList()
    }
}

GUI_EditSelectedSkill() {
    global gSkillLV, App
    row := gSkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := row
    cur := App["ProfileData"].Skills[idx]
    SkillEditor_Open(cur, idx, OnSaved)

    OnSaved(newSkill, idx2) {
        global App
        App["ProfileData"].Skills[idx2] := newSkill
        GUI_RefreshSkillList()
    }
}

GUI_DeleteSelectedSkill() {
    global gSkillLV, App
    row := gSkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
        MsgBox T("msg.indexMismatch","索引异常，列表与配置不同步。")
        return
    }
    App["ProfileData"].Skills.RemoveAt(idx)
    GUI_RefreshSkillList()
    Notify(T("msg.skillDeleted","已删除技能"))
}

GUI_TestSelectedSkill() {
    global gSkillLV, App
    row := gSkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox T("msg.selectSkill","请先选中一个技能行。")
        return
    }
    idx := row
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

; 应用语言并重建界面
GUI_ApplyLanguage(ddLang, packs) {
    global gMain
    idx := ddLang.Value
    if (idx < 1 || idx > packs.Length)
        return
    code := packs[idx].Code
    try Lang_SetLanguage(code)
    try AppConfig_Set("Language", code)
    try AppConfig_Save()
    try gMain.Destroy()
    GUI_Main_Show()
    Notify("Language: " code)
}

; 返回 Tab 页内容区域（父GUI坐标），已扣除页眉/边框
GUI_TabPageRect(tabCtrl) {
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "ptr", tabCtrl.Hwnd, "ptr", rc.Ptr)
    DllCall("SendMessage", "ptr", tabCtrl.Hwnd, "uint", 0x1328, "ptr", 0, "ptr", rc.Ptr) ; TCM_ADJUSTRECT
    parent := DllCall("GetParent", "ptr", tabCtrl.Hwnd, "ptr")
    DllCall("MapWindowPoints", "ptr", tabCtrl.Hwnd, "ptr", parent, "ptr", rc.Ptr, "uint", 2)
    x := NumGet(rc, 0, "Int")
    y := NumGet(rc, 4, "Int")
    w := NumGet(rc, 8, "Int") - x
    h := NumGet(rc, 12, "Int") - y
    return { X: x, Y: y, W: w, H: h }
}

; 默认技能配置对话
DefaultSkillEditor_Show() {
    global App
    ds := HasProp(App["ProfileData"], "DefaultSkill") ? App["ProfileData"].DefaultSkill : 0
    if !ds {
        App["ProfileData"].DefaultSkill := { Enabled:0, SkillIndex:0, CheckReady:1, ThreadId:1, CooldownMs:600, PreDelayMs:0, LastFire:0 }
        ds := App["ProfileData"].DefaultSkill
    }

    dlg := Gui(, T("dlg.defaultSkill","默认技能（兜底触发）"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    cbEn := dlg.Add("CheckBox", "xm w160", T("label.enableDefault","启用默认技能"))
    cbEn.Value := ds.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w70", T("label.skill","技能："))
    names := []
    for _, s in App["ProfileData"].Skills
        names.Push(s.Name)
    ddSkill := dlg.Add("DropDownList", "x+6 w260")
    if names.Length
        ddSkill.Add(names)
    ddSkill.Value := (ds.SkillIndex >= 1 && ds.SkillIndex <= names.Length) ? ds.SkillIndex : (names.Length ? 1 : 0)

    cbReady := dlg.Add("CheckBox", "xm y+8 w150", T("label.checkReady","检测就绪(像素)"))
    cbReady.Value := ds.CheckReady ? 1 : 0

    dlg.Add("Text", "xm y+8 w60", T("label.thread","线程："))
    ddThread := dlg.Add("DropDownList", "x+6 w200")
    threadIds := []
    tnames := []
    for _, t in App["ProfileData"].Threads {
        tnames.Push(t.Name)
        threadIds.Push(t.Id)
    }
    if tnames.Length
        ddThread.Add(tnames)
    sel := 1
    for i, id in threadIds
        if (id = (HasProp(ds,"ThreadId") ? ds.ThreadId : 1)) {
            sel := i
            break
        }
    ddThread.Value := sel

    dlg.Add("Text", "xm y+8 w80", T("label.cooldown","冷却(ms)："))
    edCd := dlg.Add("Edit", "x+6 w120 Number", HasProp(ds,"CooldownMs") ? ds.CooldownMs : 600)

    dlg.Add("Text", "x+20 w90", T("label.predelay","预延时(ms)："))
    edPre := dlg.Add("Edit", "x+6 w120 Number", HasProp(ds,"PreDelayMs") ? ds.PreDelayMs : 0)

    btnSave := dlg.Add("Button", "xm y+12 w100", T("btn.save","保存"))
    btnCancel := dlg.Add("Button", "x+8 w100", T("btn.cancel","取消"))
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    OnSave(*) {
        en  := cbEn.Value ? 1 : 0
        si  := ddSkill.Value ? ddSkill.Value : 0
        rdy := cbReady.Value ? 1 : 0
        tid := (ddThread.Value >= 1 && ddThread.Value <= threadIds.Length) ? threadIds[ddThread.Value] : 1
        cd  := (edCd.Value != "") ? Integer(edCd.Value) : 600
        pre := (edPre.Value != "") ? Integer(edPre.Value) : 0

        if (en = 1 && (si < 1 || si > App["ProfileData"].Skills.Length)) {
            MsgBox T("msg.chooseSkill","请先选择一个技能。")
            return
        }

        last := HasProp(ds, "LastFire") ? ds.LastFire : 0
        App["ProfileData"].DefaultSkill.Enabled := en
        App["ProfileData"].DefaultSkill.SkillIndex := si
        App["ProfileData"].DefaultSkill.CheckReady := rdy
        App["ProfileData"].DefaultSkill.ThreadId := tid
        App["ProfileData"].DefaultSkill.CooldownMs := cd
        App["ProfileData"].DefaultSkill.PreDelayMs := pre
        App["ProfileData"].DefaultSkill.LastFire := last

        Storage_SaveProfile(App["ProfileData"])
        dlg.Destroy()
        Notify(T("msg.defaultSaved","默认技能配置已保存"))
    }
}