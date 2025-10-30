#Requires AutoHotkey v2
; 自适应布局与切页显隐

UI_TabPageRect(tabCtrl) {
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "ptr", tabCtrl.Hwnd, "ptr", rc.Ptr)
    DllCall("SendMessage", "ptr", tabCtrl.Hwnd, "uint", 0x1328, "ptr", 0, "ptr", rc.Ptr) ; TCM_ADJUSTRECT
    parent := DllCall("GetParent", "ptr", tabCtrl.Hwnd, "ptr")
    DllCall("MapWindowPoints", "ptr", tabCtrl.Hwnd, "ptr", parent, "ptr", rc.Ptr, "uint", 2)
    x := NumGet(rc, 0, "Int"), y := NumGet(rc, 4, "Int")
    w := NumGet(rc, 8, "Int") - x, h := NumGet(rc, 12, "Int") - y
    return { X: x, Y: y, W: w, H: h }
}

UI_OnTopTabChange(ctrl, *) {
    val := ctrl.Value
    if (val <= 0)
        val := 1
    UI_ToggleMainPage(val = 1)
    UI_ToggleSettingsPage(val = 2)
    ; 保险：强制重绘内层Tab（存在时）
    try DllCall("user32\UpdateWindow", "ptr", UI.TabInner.Hwnd)
}

UI_ToggleMainPage(vis) {
    global UI
    for ctl in [
        UI.GB_Profile, UI.ProfilesDD, UI.BtnNew, UI.BtnClone, UI.BtnDelete, UI.BtnExport
      , UI.GB_General, UI.LblStartStop, UI.HkStart, UI.LblPoll, UI.PollEdit, UI.LblDelay, UI.CdEdit, UI.BtnApply
      , UI.LblPick, UI.ChkPick, UI.LblOffY, UI.OffYEdit, UI.LblDwell, UI.DwellEdit
      , UI.GB_Auto, UI.BtnThreads, UI.BtnRules, UI.BtnBuffs, UI.BtnDefault
      , UI.TabInner
    ] {
        try ctl.Visible := vis
    }
}

UI_ToggleSettingsPage(vis) {
    global UI
    for ctl in [ UI.LblLang, UI.DdLang, UI.BtnApplyLang, UI.BtnOpenLang, UI.LblNote ] {
        try ctl.Visible := vis
    }
}

UI_OnResize(gui, minmax, w, h) {
    global UI
    mX := gui.MarginX, mY := gui.MarginY
    if !IsObject(UI.TopTab)
        return

    ; 顶层Tab占满
    UI.TopTab.Move(mX, mY, Max(w - mX*2, 420), Max(h - mY*2, 320))
    rcTop := UI_TabPageRect(UI.TopTab)
    pad := 10

    ; 第1页（配置）三大分组
    profH := 80, genH := 116, autoH := 60, gapY := 10
    gbW := Max(rcTop.W - pad*2, 420)
    x0 := rcTop.X + pad
    y0 := rcTop.Y + pad

    try UI.GB_Profile.Move(x0, y0, gbW, profH)
    try UI.GB_General.Move(x0, y0 + profH + gapY, gbW, genH)

    ; 自动化分组 + 按钮
    autoTop := y0 + profH + gapY + genH + gapY
    try UI.GB_Auto.Move(x0, autoTop, gbW, autoH)
    if IsObject(UI.GB_Auto) {
        UI.GB_Auto.GetPos(&ax, &ay, &aw, &ah)
        inPad := 12, btnW := 100, btnH := 28, gap := 8, btnY := ay + ah - inPad - btnH
        try UI.BtnThreads.Move(ax+inPad, btnY, btnW, btnH)
        try UI.BtnRules.Move(ax+inPad + (btnW+gap)*1, btnY, btnW, btnH)
        try UI.BtnBuffs.Move(ax+inPad + (btnW+gap)*2, btnY, btnW, btnH)
        try UI.BtnDefault.Move(ax+inPad + (btnW+gap)*3, btnY, btnW, btnH)
    }

    ; 内层Tab（技能/点位）
    if IsObject(UI.TabInner) {
        tabTop := autoTop + autoH + gapY
        tabH := Max(rcTop.H - (tabTop - rcTop.Y) - pad, 260)
        UI.TabInner.Move(x0, tabTop, gbW, tabH)

        rc := UI_TabPageRect(UI.TabInner)
        ip := 10, bar := 36
        lvX := rc.X + ip, lvY := rc.Y + ip
        lvW := Max(rc.W - ip*2, 100)
        lvH := Max(rc.H - ip*2 - bar, 80)

        ; 技能页
        try UI.SkillLV.Move(lvX, lvY, lvW, lvH)
        btnY := lvY + lvH + 8, btnW := 96, btnH := 28, gap := 8, startX := lvX
        try UI.BtnAddSkill.Move(startX, btnY, btnW, btnH)
        try UI.BtnEditSkill.Move(startX + (btnW+gap)*1, btnY, btnW, btnH)
        try UI.BtnDelSkill.Move(startX + (btnW+gap)*2, btnY, btnW, btnH)
        try UI.BtnTestSkill.Move(startX + (btnW+gap)*3, btnY, btnW, btnH)
        try UI.BtnSaveSkill.Move(startX + (btnW+gap)*4, btnY, btnW, btnH)
        loop 7
            try UI.SkillLV.ModifyCol(A_Index, "AutoHdr")

        ; 点位页
        try UI.PointLV.Move(lvX, lvY, lvW, lvH)
        pY := lvY + lvH + 8
        try UI.BtnAddPoint.Move(startX, pY, btnW, btnH)
        try UI.BtnEditPoint.Move(startX + (btnW+gap)*1, pY, btnW, btnH)
        try UI.BtnDelPoint.Move(startX + (btnW+gap)*2, pY, btnW, btnH)
        try UI.BtnTestPoint.Move(startX + (btnW+gap)*3, pY, btnW, btnH)
        try UI.BtnSavePoint.Move(startX + (btnW+gap)*4, pY, btnW, btnH)
        loop 6
            try UI.PointLV.ModifyCol(A_Index, "AutoHdr")
    }

    ; 第2页（设置）
    try UI.LblLang.Move(x0, y0, 120, 24)
    try UI.DdLang.Move(x0 + 120 + 6, y0, 220, 24)
    try UI.BtnApplyLang.Move(x0, y0 + 40, 120, 28)
    try UI.BtnOpenLang.Move(x0 + 120 + 8, y0 + 40, 140, 28)
    try UI.LblNote.Move(x0, y0 + 78, Max(gbW, 200), 24)
}