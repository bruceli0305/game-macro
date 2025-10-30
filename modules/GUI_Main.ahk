global gMain, gProfilesDD, gHkStart, gPollEdit, gCdEdit, gSkillLV
global gGBProfile, gGBGeneral
global gBtnNew, gBtnClone, gBtnDelete, gBtnExport, gBtnApply
global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave
global gChkPickAway, gPickOffsetEdit, gPickDwellEdit
global gPointLV
global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
global gTabMain
global gGBAuto, gBtnRuleCfg, gBtnBuffCfg
global gBtnThreads  ; 顶部声明
; 预初始化（避免 #Warn）
gTabMain := 0
gSkillLV := 0
gPointLV := 0
gBtnAdd := 0, gBtnEdit := 0, gBtnDel := 0, gBtnTest := 0, gBtnSave := 0
gBtnPAdd := 0, gBtnPEdit := 0, gBtnPDel := 0, gBtnPTest := 0, gBtnPSave := 0
gGBAuto := 0, gBtnRuleCfg := 0, gBtnBuffCfg := 0

GUI_Main_Show() {
    global gMain, gProfilesDD, gHkStart, gPollEdit, gCdEdit, gSkillLV
    global gGBProfile, gGBGeneral
    global gBtnNew, gBtnClone, gBtnDelete, gBtnExport, gBtnApply
    global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave, App
    global gChkPickAway, gPickOffsetEdit, gPickDwellEdit
    global gPointLV
    global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
    global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave
    global gTabMain
    global gGBAuto, gBtnRuleCfg, gBtnBuffCfg
    global gBtnThreads

    gMain := Gui("+Resize", "输出取色宏 - v0.0.1-Alpha-0.1")
    gMain.MarginX := 14
    gMain.MarginY := 12
    gMain.SetFont("s10", "Segoe UI")  ; 常规字号，去掉加粗
    gMain.OnEvent("Close", (*) => ExitApp())

    ; ====== 分组：角色配置（去粗体，略增高度） ======
    gGBProfile := gMain.Add("GroupBox", "xm ym w860 h80", "角色配置")
    gProfilesDD := gMain.Add("DropDownList", "xp+12 yp+32 w280 vProfiles")
    gBtnNew := gMain.Add("Button", "x+10 w80 h28", "新建")
    gBtnClone := gMain.Add("Button", "x+8  w80 h28", "复制")
    gBtnDelete := gMain.Add("Button", "x+8  w80 h28", "删除")
    gBtnExport := gMain.Add("Button", "x+16 w92 h28", "导出打包")
    gBtnNew.OnEvent("Click", (*) => GUI_NewProfile())
    gBtnClone.OnEvent("Click", (*) => GUI_CloneProfile())
    gBtnDelete.OnEvent("Click", (*) => GUI_DeleteProfile())
    gBtnExport.OnEvent("Click", OnExport)

    ; ====== 分组：热键与轮询（两行布局） ======
    gGBGeneral := gMain.Add("GroupBox", "xm y+10 w860 h116", "热键与轮询")

    ; 行1：开始/停止、轮询、冷却、应用
    ; 关键：这里加 Section，作为第二行对齐锚点
    gMain.Add("Text", "xp+12 yp+50 Section", "开始/停止：")
    gHkStart := gMain.Add("Hotkey", "x+6 w180")

    gMain.Add("Text", "x+18", "轮询(ms)：")
    gPollEdit := gMain.Add("Edit", "x+6 w90 Number Center")

    gMain.Add("Text", "x+18", "全局延迟(ms)：")
    gCdEdit := gMain.Add("Edit", "x+6 w100 Number Center")

    gBtnApply := gMain.Add("Button", "x+18 w80 h28", "应用")
    gBtnApply.OnEvent("Click", (*) => GUI_ApplyGeneral())

    ; 行2：取色避让（从分组左起开始）
    ; 关键：xs = X 与 Section 对齐；ys+34 = Y 在 Section 下方 34px
    gMain.Add("Text", "xs ys+34", "取色避让：")
    gChkPickAway := gMain.Add("CheckBox", "x+6 w18 h18")

    gMain.Add("Text", "x+14", "Y偏移(px)：")
    gPickOffsetEdit := gMain.Add("Edit", "x+6 w80 Number Center")

    gMain.Add("Text", "x+14", "等待(ms)：")
    gPickDwellEdit := gMain.Add("Edit", "x+6 w90 Number Center")

    ; ====== 分组：自动化配置（循环/BUFF） ======
    gGBAuto := gMain.Add("GroupBox", "xm y+35 w860 h60", "自动化配置")

    ; 创建控件处：
    gBtnThreads := gMain.Add("Button", "xp+12 yp+28 w100 h28", "线程配置")
    gBtnRuleCfg := gMain.Add("Button", "x+8 w100 h28", "循环配置")
    gBtnBuffCfg := gMain.Add("Button", "x+8 w100 h28", "计时器配置")

    gBtnThreads.OnEvent("Click", (*) => ThreadsManager_Show())
    gBtnRuleCfg.OnEvent("Click", (*) => RulesManager_Show())
    gBtnBuffCfg.OnEvent("Click", (*) => BuffsManager_Show())

    ; ====== Tab：技能列表 / 取色点位 ======
    gTabMain := gMain.Add("Tab3", "xm y+20 w860 h440", ["技能列表", "取色点位"])

    ; 第1页：技能列表
    gTabMain.UseTab(1)
    gSkillLV := gMain.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , ["ID", "技能名", "键位", "X", "Y", "颜色", "容差"])
    gSkillLV.OnEvent("DoubleClick", (*) => GUI_EditSelectedSkill())
    gBtnAdd := gMain.Add("Button", "x12 y+8 w96 h28", "新增技能")
    gBtnEdit := gMain.Add("Button", "x+8 w96 h28", "编辑技能")
    gBtnDel := gMain.Add("Button", "x+8 w96 h28", "删除技能")
    gBtnTest := gMain.Add("Button", "x+8 w96 h28", "测试检测")
    gBtnSave := gMain.Add("Button", "x+8 w96 h28", "保存配置")
    gBtnAdd.OnEvent("Click", (*) => GUI_AddSkill())
    gBtnEdit.OnEvent("Click", (*) => GUI_EditSelectedSkill())
    gBtnDel.OnEvent("Click", (*) => GUI_DeleteSelectedSkill())
    gBtnTest.OnEvent("Click", (*) => GUI_TestSelectedSkill())
    gBtnSave.OnEvent("Click", (*) => GUI_SaveCurrentProfile())

    ; 第2页：取色点位
    gTabMain.UseTab(2)
    gPointLV := gMain.Add("ListView", "x12 y12 w100 h100 +Grid +AltSubmit"
        , ["ID", "名称", "X", "Y", "颜色", "容差"])
    gPointLV.OnEvent("DoubleClick", (*) => GUI_EditSelectedPoint())
    gBtnPAdd := gMain.Add("Button", "x12 y+8 w96 h28", "新增点位")
    gBtnPEdit := gMain.Add("Button", "x+8 w96 h28", "编辑点位")
    gBtnPDel := gMain.Add("Button", "x+8 w96 h28", "删除点位")
    gBtnPTest := gMain.Add("Button", "x+8 w96 h28", "测试点位")
    gBtnPSave := gMain.Add("Button", "x+8 w96 h28", "保存配置")
    gBtnPAdd.OnEvent("Click", (*) => GUI_AddPoint())
    gBtnPEdit.OnEvent("Click", (*) => GUI_EditSelectedPoint())
    gBtnPDel.OnEvent("Click", (*) => GUI_DeleteSelectedPoint())
    gBtnPTest.OnEvent("Click", (*) => GUI_TestSelectedPoint())
    gBtnPSave.OnEvent("Click", (*) => GUI_SaveCurrentProfile())

    ; 退出 Tab 上下文
    gTabMain.UseTab()

    ; 现在再绑定 Size，Show，并做第一次布局
    gMain.OnEvent("Size", GUI_OnResize)
    gMain.Show("w890 h750")
    GUI_ReloadProfiles()
    gProfilesDD.OnEvent("Change", (*) => GUI_ProfileChanged())
    WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " gMain.Hwnd
    GUI_OnResize(gMain, 0, cw, ch)
}
OnExport(*) {
    global App
    Exporter_ExportProfile(App["CurrentProfile"])
}
; 自适应布局：窗口大小变化时重算尺寸
GUI_OnResize(gui, minmax, w, h) {
    global gGBProfile, gGBGeneral, gGBAuto, gBtnThreads, gBtnRuleCfg, gBtnBuffCfg
    global gTabMain, gSkillLV, gPointLV
    global gBtnAdd, gBtnEdit, gBtnDel, gBtnTest, gBtnSave
    global gBtnPAdd, gBtnPEdit, gBtnPDel, gBtnPTest, gBtnPSave

    marginX := gui.MarginX
    marginY := gui.MarginY
    profileH := 80
    generalH := 116
    autoH := 60
    gapY := 10
    gbW := Max(w - marginX * 2, 420)

    ; 顶部三组
    gGBProfile.Move(marginX, marginY, gbW, profileH)
    gGBGeneral.Move(marginX, marginY + profileH + gapY, gbW, generalH)

    ; 自动化配置分组
    autoTop := marginY + profileH + gapY + generalH + gapY
    if IsObject(gGBAuto) {
        gGBAuto.Move(marginX, autoTop, gbW, autoH)
        gGBAuto.GetPos(&ax, &ay, &aw, &ah)

        pad := 12
        btnW := 100
        btnH := 28
        gap := 8
        btnY := ay + ah - pad - btnH

        if IsObject(gBtnThreads) {
            gBtnThreads.Move(ax + pad, btnY, btnW, btnH)
        }
        if IsObject(gBtnRuleCfg) {
            gBtnRuleCfg.Move(ax + pad + (btnW + gap) * 1, btnY, btnW, btnH)
        }
        if IsObject(gBtnBuffCfg) {
            gBtnBuffCfg.Move(ax + pad + (btnW + gap) * 2, btnY, btnW, btnH)
        }
    }

    ; Tab 放在“自动化配置”之下
    if !IsObject(gTabMain)
        return
    tabTop := autoTop + autoH + gapY
    tabH := Max(h - tabTop - marginY, 260)
    gTabMain.Move(marginX, tabTop, gbW, tabH)

    ; 计算 Tab 页内容区域（扣除页眉/边框），返回父GUI坐标
    rc := GUI_TabPageRect(gTabMain)
    innerPad := 10
    btnBarH := 36   ; 列表下方按钮条高度（28 + 间距）
    lvX := rc.X + innerPad
    lvY := rc.Y + innerPad
    lvW := Max(rc.W - innerPad * 2, 100)
    lvH := Max(rc.H - innerPad * 2 - btnBarH, 80)

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

    ; 取色点位页内容
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
    try Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
}

GUI_RefreshSkillList() {
    global gSkillLV, App
    gSkillLV.Opt("-Redraw")
    gSkillLV.Delete()
    for idx, s in App["ProfileData"].Skills
        gSkillLV.Add("", idx, s.Name, s.Key, s.X, s.Y, s.Color, s.Tol)
    ; 提升可读性：适配列宽
    loop 7
        gSkillLV.ModifyCol(A_Index, "AutoHdr")
    gSkillLV.Opt("+Redraw")
}

GUI_SaveCurrentProfile() {
    global App
    Storage_SaveProfile(App["ProfileData"])
    Notify("配置已保存")
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
    App["ProfileData"].SendCooldownMs := delay   ; 现在代表“全局延迟(ms)”
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
        MsgBox "请先选中一个点位。"
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
        MsgBox "请先选中一个点位。"
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Points.Length) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    App["ProfileData"].Points.RemoveAt(idx)
    GUI_Points_RefreshList()
    Notify("已删除点位")
}

GUI_TestSelectedPoint() {
    global gPointLV, App
    row := gPointLV.GetNext(0, "Focused")
    if !row {
        MsgBox "请先选中一个点位。"
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Points.Length) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    p := App["ProfileData"].Points[idx]
    offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
    dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
    c := Pixel_GetColorWithMouseAway(p.X, p.Y, offY, dwell)
    match := Pixel_ColorMatch(c, Pixel_HexToInt(p.Color), p.Tol)
    MsgBox "检测点: X=" p.X " Y=" p.Y "`n当前颜色: " Pixel_ColorToHex(c)
    . "`n目标颜色: " p.Color "`n容差: " p.Tol
    . "`n结果: " (match ? "匹配" : "不匹配")
}

GUI_NewProfile() {
    dlg := Gui(, "新建配置")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , "配置名称：")
    nameEdit := dlg.Add("Edit", "w260")
    btnCreate := dlg.Add("Button", "xm w88", "创建")
    btnCancel := dlg.Add("Button", "x+8 w88", "取消")

    btnCreate.OnEvent("Click", OnCreate)
    btnCancel.OnEvent("Click", OnCancel)
    dlg.Show()

    OnCreate(*) {
        name := Trim(nameEdit.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        data := Core_DefaultProfileData()
        data.Name := name
        Storage_SaveProfile(data)
        Notify("已创建：" name)
        dlg.Destroy()
        GUI_ReloadProfiles()
    }
    OnCancel(*) => dlg.Destroy()
}

GUI_CloneProfile() {
    global App
    if App["CurrentProfile"] = "" {
        MsgBox "未选择配置"
        return
    }
    src := App["CurrentProfile"]

    dlg := Gui(, "复制配置")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.Add("Text", , "新配置名称：")
    nameEdit := dlg.Add("Edit", "w260", src "_Copy")
    btnCopy := dlg.Add("Button", "xm w88", "复制")
    btnCancel := dlg.Add("Button", "x+8 w88", "取消")

    btnCopy.OnEvent("Click", OnCopy)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()

    OnCopy(*) {
        name := Trim(nameEdit.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        data := Storage_LoadProfile(src)
        data.Name := name
        Storage_SaveProfile(data)
        Notify("已复制为：" name)
        dlg.Destroy()
        GUI_ReloadProfiles()
    }
}

GUI_DeleteProfile() {
    global App
    if App["CurrentProfile"] = "" {
        MsgBox "未选择配置"
        return
    }
    if App["Profiles"].Length <= 1 {
        MsgBox "至少保留一个配置。"
        return
    }
    if Confirm("确定删除配置：" App["CurrentProfile"] "？") {
        Storage_DeleteProfile(App["CurrentProfile"])
        Notify("已删除：" App["CurrentProfile"])
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
        MsgBox "请先选中一个技能行。"
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
        MsgBox "请先选中一个技能行。"
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    App["ProfileData"].Skills.RemoveAt(idx)
    GUI_RefreshSkillList()
    Notify("已删除技能")
}

GUI_TestSelectedSkill() {
    global gSkillLV, App
    row := gSkillLV.GetNext(0, "Focused")
    if !row {
        MsgBox "请先选中一个技能行。"
        return
    }
    idx := row
    if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    s := App["ProfileData"].Skills[idx]
    ; 若启用避让则带参数，否则直取
    offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
    dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
    c := Pixel_GetColorWithMouseAway(s.X, s.Y, offY, dwell)
    match := Pixel_ColorMatch(c, Pixel_HexToInt(s.Color), s.Tol)
    MsgBox "检测点: X=" s.X " Y=" s.Y "`n当前颜色: " Pixel_ColorToHex(c)
    . "`n目标颜色: " s.Color "`n容差: " s.Tol
    . "`n结果: " (match ? "匹配" : "不匹配")
}

; 返回 Tab 页内容区域（父GUI坐标），已扣除页眉/边框
GUI_TabPageRect(tabCtrl) {
    ; 1) 取 Tab 客户区 rect（0,0,tw,th）
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "ptr", tabCtrl.Hwnd, "ptr", rc.Ptr)

    ; 2) TCM_ADJUSTRECT：wParam=FALSE，把“窗口矩形(客户区)”转换为“显示矩形(页内容)”
    DllCall("SendMessage", "ptr", tabCtrl.Hwnd, "uint", 0x1328, "ptr", 0, "ptr", rc.Ptr)

    ; 3) 从 Tab 客户区坐标映射到父 GUI 坐标
    parent := DllCall("GetParent", "ptr", tabCtrl.Hwnd, "ptr")
    DllCall("MapWindowPoints", "ptr", tabCtrl.Hwnd, "ptr", parent, "ptr", rc.Ptr, "uint", 2)

    x := NumGet(rc, 0, "Int")
    y := NumGet(rc, 4, "Int")
    w := NumGet(rc, 8, "Int") - x
    h := NumGet(rc, 12, "Int") - y
    return { X: x, Y: y, W: w, H: h }
}
