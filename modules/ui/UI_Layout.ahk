#Requires AutoHotkey v2
; 自适应布局与切页显隐（无内层 Tab，按钮切换两个面板）
; 修复：最小化/恢复后子控件未重绘 -> 在恢复时强制 RedrawWindow

; 计算 Tab 当前页的内容矩形（父 GUI 坐标）
UI_TabPageRect(tabCtrl) {
    rc := Buffer(16, 0)
    DllCall("user32\GetClientRect", "ptr", tabCtrl.Hwnd, "ptr", rc.Ptr)
    ; TCM_ADJUSTRECT: 把客户区矩形转换为“显示矩形”
    DllCall("user32\SendMessage", "ptr", tabCtrl.Hwnd, "uint", 0x1328, "ptr", 0, "ptr", rc.Ptr)
    parent := DllCall("user32\GetParent", "ptr", tabCtrl.Hwnd, "ptr")
    DllCall("user32\MapWindowPoints", "ptr", tabCtrl.Hwnd, "ptr", parent, "ptr", rc.Ptr, "uint", 2)
    x := NumGet(rc, 0, "Int"), y := NumGet(rc, 4, "Int")
    w := NumGet(rc, 8, "Int") - x, h := NumGet(rc, 12, "Int") - y
    return { X: x, Y: y, W: w, H: h }
}

; 顶层 Tab 切换：显隐两页控件
UI_OnTopTabChange(ctrl, *) {
    val := ctrl.Value
    if (val <= 0)
        val := 1
    UI_ToggleMainPage(val = 1)
    UI_ToggleSettingsPage(val = 2)
    ; 已无内层 Tab
}

; 显隐：配置页
UI_ToggleMainPage(vis) {
    global UI
    for ctl in [
        UI.GB_Profile, UI.ProfilesDD, UI.BtnNew, UI.BtnClone, UI.BtnDelete, UI.BtnExport
      , UI.GB_General, UI.LblStartStop, UI.HkStart, UI.LblPoll, UI.PollEdit, UI.LblDelay, UI.CdEdit, UI.BtnApply
      , UI.LblPick, UI.ChkPick, UI.LblOffY, UI.OffYEdit, UI.LblDwell, UI.DwellEdit
      , UI.GB_Auto, UI.BtnThreads, UI.BtnRules, UI.BtnBuffs, UI.BtnDefault
      , UI.BtnPaneSkills, UI.BtnPanePoints
      , UI.SkillLV, UI.BtnAddSkill, UI.BtnEditSkill, UI.BtnDelSkill, UI.BtnTestSkill, UI.BtnSaveSkill
      , UI.PointLV, UI.BtnAddPoint, UI.BtnEditPoint, UI.BtnDelPoint, UI.BtnTestPoint, UI.BtnSavePoint
    ] {
        try ctl.Visible := vis
    }
    ; 恢复当前页（避免切页后两个面板同时显示）
    pane := 1
    try pane := UI["InnerPane"]
    UI_Page_Config_ShowPane(pane)
}

; 显隐：设置页
UI_ToggleSettingsPage(vis) {
    global UI
    for ctl in [ UI.LblLang, UI.DdLang, UI.BtnApplyLang, UI.BtnOpenLang, UI.LblNote ] {
        try ctl.Visible := vis
    }
}

; 统一 Move（安全包装）
_UI_Move(ctrl, x, y, w := "", h := "") {
    try {
        if (w = "" && h = "")
            ctrl.Move(x, y)
        else if (h = "")
            ctrl.Move(x, y, w)
        else
            ctrl.Move(x, y, w, h)
    }
}

; 强制重绘主窗体及全部子控件（修复恢复后未重绘）
UI_ForceRedrawAll() {
    global UI
    try {
        flags := 0x0001 | 0x0080 | 0x0100   ; RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_UPDATENOW
        DllCall("user32\RedrawWindow", "ptr", UI.Main.Hwnd, "ptr", 0, "ptr", 0, "uint", flags)
    }
}

; 自适应布局
UI_OnResize(gui, minmax, w, h) {
    global UI
    ; 最小化时不进行布局，避免 0x0 尺寸/无效移动导致的绘制问题
    if (minmax = 1)  ; SIZE_MINIMIZED
        return

    mX := gui.MarginX, mY := gui.MarginY
    if !IsObject(UI.TopTab)
        return

    ; 顶层 Tab 占满窗口
    UI.TopTab.Move(mX, mY, Max(w - mX*2, 420), Max(h - mY*2, 320))
    rcTop := UI_TabPageRect(UI.TopTab)
    pad := 10

    ; ---------- 第1页（配置）三大分组 ----------
    profH := 80, genH := 116, autoH := 60, gapY := 10
    gbW := Max(rcTop.W - pad*2, 420)
    x0 := rcTop.X + pad
    y0 := rcTop.Y + pad

    ; 角色配置分组及内部控件
    if IsObject(UI.GB_Profile) {
        UI.GB_Profile.Move(x0, y0, gbW, profH)
        UI.GB_Profile.GetPos(&px, &py, &pw, &ph)
        ip := 12
        ddW := 280, ddH := 24
        btnW := 80, btnH := 28, gap := 8
        btnY := py + 28

        _UI_Move(UI.ProfilesDD, px + ip, py + 32, ddW, ddH)
        UI.ProfilesDD.GetPos(&dx, &dy, &dw, &dh)
        bx := dx + dw + 10
        _UI_Move(UI.BtnNew,    bx + (btnW+gap)*0, btnY, btnW, btnH)
        _UI_Move(UI.BtnClone,  bx + (btnW+gap)*1, btnY, btnW, btnH)
        _UI_Move(UI.BtnDelete, bx + (btnW+gap)*2, btnY, btnW, btnH)
        _UI_Move(UI.BtnExport, bx + (btnW+gap)*3, btnY, 92, 28)
    }

    ; 热键与轮询
    if IsObject(UI.GB_General) {
        UI.GB_General.Move(x0, y0 + profH + gapY, gbW, genH)
        UI.GB_General.GetPos(&gx, &gy, &gw, &gh)
        ip := 12

        ; 行1
        line1Y := gy + 50
        _UI_Move(UI.LblStartStop, gx + ip, line1Y)
        UI.LblStartStop.GetPos(&sx, &sy, &sw, &sh)
        _UI_Move(UI.HkStart, sx + sw + 6, line1Y - 4, 180, 24)
        UI.HkStart.GetPos(&hkx, &hky, &hkw, &hkh)

        _UI_Move(UI.LblPoll, hkx + hkw + 18, line1Y)
        UI.LblPoll.GetPos(&plx, &ply, &plw, &plh)
        _UI_Move(UI.PollEdit, plx + plw + 6, line1Y - 2, 90, 24)
        UI.PollEdit.GetPos(&pex, &pey, &pew, &peh)

        _UI_Move(UI.LblDelay, pex + pew + 18, line1Y)
        UI.LblDelay.GetPos(&dlx, &dly, &dlw, &dlh)
        _UI_Move(UI.CdEdit, dlx + dlw + 6, line1Y - 2, 100, 24)
        UI.CdEdit.GetPos(&cdx, &cdy, &cdw, &cdh)

        _UI_Move(UI.BtnApply, cdx + cdw + 18, line1Y - 6, 80, 28)

        ; 行2
        line2Y := line1Y + 34
        _UI_Move(UI.LblPick, gx + ip, line2Y)
        UI.LblPick.GetPos(&pkx, &pky, &pkw, &pkh)
        _UI_Move(UI.ChkPick, pkx + pkw + 6, line2Y - 2, 18, 18)

        UI.ChkPick.GetPos(&ckx, &cky, &ckw, &ckh)
        _UI_Move(UI.LblOffY, ckx + ckw + 14, line2Y)
        UI.LblOffY.GetPos(&ofx, &ofy, &ofw, &ofh)
        _UI_Move(UI.OffYEdit, ofx + ofw + 6, line2Y - 2, 80, 24)

        UI.OffYEdit.GetPos(&ox, &oy, &ow, &oh)
        _UI_Move(UI.LblDwell, ox + ow + 14, line2Y)
        UI.LblDwell.GetPos(&dwx, &dwy, &dww, &dwh)
        _UI_Move(UI.DwellEdit, dwx + dww + 6, line2Y - 2, 90, 24)
    }

    ; 自动化配置分组
    autoTop := y0 + profH + gapY + genH + gapY
    if IsObject(UI.GB_Auto) {
        UI.GB_Auto.Move(x0, autoTop, gbW, autoH)
        UI.GB_Auto.GetPos(&ax, &ay, &aw, &ah)
        inPad := 12, btnW := 100, btnH := 28, gap := 8
        btnY := ay + ah - inPad - btnH
        _UI_Move(UI.BtnThreads, ax + inPad, btnY, btnW, btnH)
        _UI_Move(UI.BtnRules,   ax + inPad + (btnW+gap)*1, btnY, btnW, btnH)
        _UI_Move(UI.BtnBuffs,   ax + inPad + (btnW+gap)*2, btnY, btnW, btnH)
        _UI_Move(UI.BtnDefault, ax + inPad + (btnW+gap)*3, btnY, btnW, btnH)
    }

    ; ---------- 下方区域：按钮切换 + 两套面板 ----------
    tabTop := autoTop + autoH + gapY
    tabH := Max(rcTop.H - (tabTop - rcTop.Y) - pad, 260)

    ; 页眉按钮
    if IsObject(UI.BtnPaneSkills) {
        _UI_Move(UI.BtnPaneSkills, x0, tabTop, 120, 28)
        _UI_Move(UI.BtnPanePoints, x0 + 120 + 8, tabTop, 120, 28)
    }

    ; 列表区尺寸
    bar := 36
    lvX := x0
    lvY := tabTop + bar
    lvW := Max(gbW, 100)
    lvH := Max(tabH - bar - 8, 80)

    ; 技能页
    if IsObject(UI.SkillLV) {
        _UI_Move(UI.SkillLV, lvX, lvY, lvW, lvH)
        btnY := lvY + lvH + 8
        btnW := 96, btnH := 28, gap := 8, startX := lvX
        _UI_Move(UI.BtnAddSkill,  startX + (btnW+gap)*0, btnY, btnW, btnH)
        _UI_Move(UI.BtnEditSkill, startX + (btnW+gap)*1, btnY, btnW, btnH)
        _UI_Move(UI.BtnDelSkill,  startX + (btnW+gap)*2, btnY, btnW, btnH)
        _UI_Move(UI.BtnTestSkill, startX + (btnW+gap)*3, btnY, btnW, btnH)
        _UI_Move(UI.BtnSaveSkill, startX + (btnW+gap)*4, btnY, btnW, btnH)
        loop 7
            try UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
    }

    ; 点位页
    if IsObject(UI.PointLV) {
        _UI_Move(UI.PointLV, lvX, lvY, lvW, lvH)
        pY := lvY + lvH + 8
        btnW := 96, btnH := 28, gap := 8, startX := lvX
        _UI_Move(UI.BtnAddPoint,  startX + (btnW+gap)*0, pY, btnW, btnH)
        _UI_Move(UI.BtnEditPoint, startX + (btnW+gap)*1, pY, btnW, btnH)
        _UI_Move(UI.BtnDelPoint,  startX + (btnW+gap)*2, pY, btnW, btnH)
        _UI_Move(UI.BtnTestPoint, startX + (btnW+gap)*3, pY, btnW, btnH)
        _UI_Move(UI.BtnSavePoint, startX + (btnW+gap)*4, pY, btnW, btnH)
        loop 6
            try UI.PointLV.ModifyCol(A_Index, "AutoHdr")
    }

    ; 若当前是“配置”页，则再次应用当前面板的显隐，防止恢复后状态错乱
    try {
        if (UI.TopTab.Value = 1) {
            pane := 1
            try pane := UI["InnerPane"]
            UI_Page_Config_ShowPane(pane)
        }
    }

    ; 强制整窗与子控件重绘，解决恢复后不刷新的现象
    UI_ForceRedrawAll()
}