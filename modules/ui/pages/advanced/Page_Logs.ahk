#Requires AutoHotkey v2

Page_Logs_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 增加分组框高度以避免第四行控件贴边
    UI.LG_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h180", rc.X, rc.Y, rc.W), "日志过滤与控制")
    page.Controls.Push(UI.LG_GB)

    x := rc.X + 12
    rowH := 36
    
    ; 第一行：级别，分类，关键字
    y1 := rc.Y + 26
    UI.LG_LvLab := UI.Main.Add("Text", Format("x{} y{} w100 Right", x, y1 + 4), "级别：")
    page.Controls.Push(UI.LG_LvLab)
    UI.LG_DdLevel := UI.Main.Add("DropDownList", "x+6 w120")
    page.Controls.Push(UI.LG_DdLevel)
    try {
        UI.LG_DdLevel.Add(["ALL","TRACE","DEBUG","INFO","WARN","ERROR","FATAL"])
        UI.LG_DdLevel.Value := 4
    } catch {
    }

    UI.LG_CatLab := UI.Main.Add("Text", "x+16 w100 Right", "分类：")
    page.Controls.Push(UI.LG_CatLab)
    UI.LG_DdCat := UI.Main.Add("DropDownList", "x+6 w240")
    page.Controls.Push(UI.LG_DdCat)
    try {
        UI.LG_DdCat.Add(["ALL","Core","Storage","Poller","Rotation","RuleEngine","Buff","WorkerPool","WorkerHost","DXGI","Pixel","ROI","UI","Tools","Settings","Diag","Logger"])
        UI.LG_DdCat.Value := 1
    } catch {
    }

    UI.LG_KeyLab := UI.Main.Add("Text", "x+16 w100 Right", "关键字：")
    page.Controls.Push(UI.LG_KeyLab)
    UI.LG_EdKey := UI.Main.Add("Edit", "x+6 w80")
    page.Controls.Push(UI.LG_EdKey)

    ; 第二行：全局级别，按模块级别，节流每秒
    y2 := y1 + rowH
    UI.LG_SetLab := UI.Main.Add("Text", Format("x{} y{} w100 Right", x, y2 + 4), "全局级别：")
    page.Controls.Push(UI.LG_SetLab)
    UI.LG_DdSetLevel := UI.Main.Add("DropDownList", "x+6 w120")
    page.Controls.Push(UI.LG_DdSetLevel)
    try {
        UI.LG_DdSetLevel.Add(["TRACE","DEBUG","INFO","WARN","ERROR","FATAL","OFF"])
        ; 默认选择当前全局级别
        lvTxt := Logger_GetLevel()
        idx := Page_Logs__LevelIndex(lvTxt, ["TRACE","DEBUG","INFO","WARN","ERROR","FATAL","OFF"])
        if (idx < 1) {
            idx := 3
        }
        UI.LG_DdSetLevel.Value := idx
    } catch {
    }

    UI.LG_ModLab := UI.Main.Add("Text", "x+16 w100 Right", "按模块级别：")
    page.Controls.Push(UI.LG_ModLab)
    UI.LG_DdSetCat := UI.Main.Add("DropDownList", "x+6 w120")
    page.Controls.Push(UI.LG_DdSetCat)
    try {
        UI.LG_DdSetCat.Add(["Core","Storage","Poller","Rotation","RuleEngine","Buff","WorkerPool","WorkerHost","DXGI","Pixel","ROI","UI","Tools","Settings","Diag","Logger"])
        UI.LG_DdSetCat.Value := 5
    } catch {
    }
    UI.LG_DdSetCatLvl := UI.Main.Add("DropDownList", "x+6 w120")
    page.Controls.Push(UI.LG_DdSetCatLvl)
    try {
        UI.LG_DdSetCatLvl.Add(["TRACE","DEBUG","INFO","WARN","ERROR","FATAL","OFF"])
        UI.LG_DdSetCatLvl.Value := 3
    } catch {
    }
    
    ; 节流每秒移到第二行
    UI.LG_ThrLab := UI.Main.Add("Text", "x+8 w100 Right", "节流每秒：")
    page.Controls.Push(UI.LG_ThrLab)
    UI.LG_EdThr := UI.Main.Add("Edit", "x+6 w80 Number Center")
    page.Controls.Push(UI.LG_EdThr)
    try {
        UI.LG_EdThr.Value := Logger_GetThrottlePerSec()
    } catch {
    }

    ; 第三行：清空缓冲，导出当前，打开logs目录，应用设置，清空模块覆盖
    y3 := y2 + rowH
    UI.LG_BtnClear := UI.Main.Add("Button", Format("x{} y{} w120 h26", x, y3), "清空缓冲")
    page.Controls.Push(UI.LG_BtnClear)
    UI.LG_BtnExport := UI.Main.Add("Button", "x+10 w120 h26", "导出当前")
    page.Controls.Push(UI.LG_BtnExport)
    UI.LG_BtnOpen := UI.Main.Add("Button", "x+10 w120 h26", "打开 Logs 目录")
    page.Controls.Push(UI.LG_BtnOpen)
    UI.LG_BtnApply := UI.Main.Add("Button", "x+10 w100 h26", "应用设置")
    page.Controls.Push(UI.LG_BtnApply)
    UI.LG_BtnReset := UI.Main.Add("Button", "x+8 w120 h26", "清空模块覆盖")
    page.Controls.Push(UI.LG_BtnReset)

    ; 第四行：刷新，自动刷新
    y4 := y3 + rowH
    UI.LG_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", x, y4), "刷新")
    page.Controls.Push(UI.LG_BtnRefresh)
    UI.LG_Auto := UI.Main.Add("CheckBox", Format("x+10 y{} w120", y4 + 4), "自动刷新")
    page.Controls.Push(UI.LG_Auto)

    ; 列表 - 根据新的分组框高度调整位置
    ly := rc.Y + 180 + 10
    UI.LG_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, rc.H - (ly - rc.Y) - 8)
        , ["行"])
    page.Controls.Push(UI.LG_LV)

    ; 事件
    UI.LG_BtnRefresh.OnEvent("Click", Page_Logs_OnRefresh)
    UI.LG_BtnClear.OnEvent("Click", Page_Logs_OnClear)
    UI.LG_BtnExport.OnEvent("Click", Page_Logs_OnExport)
    UI.LG_BtnOpen.OnEvent("Click", Page_Logs_OnOpen)
    UI.LG_Auto.OnEvent("Click", Page_Logs_OnAutoToggle)
    UI.LG_BtnApply.OnEvent("Click", Page_Logs_OnApply)
    UI.LG_BtnReset.OnEvent("Click", Page_Logs_OnReset)

    UI.LG_TimerOn := false
    Page_Logs_OnRefresh(0)
}

Page_Logs_Layout(rc) {
    try {
        ; 增加分组框高度以避免第四行控件贴边
        UI.LG_GB.Move(rc.X, rc.Y, rc.W, 180)
        
        ; 重新计算列表视图位置
        ly := rc.Y + 180 + 10
        UI.LG_LV.Move(rc.X, ly, rc.W, rc.H - (ly - rc.Y) - 8)
        
        ; 调整控件位置以保持整齐
        x := rc.X + 12
        rowH := 36
        
        ; 第一行控件位置
        y1 := rc.Y + 26
        UI.LG_LvLab.Move(x, y1 + 4, 100)
        UI.LG_DdLevel.Move(UI.LG_LvLab.Pos.X + UI.LG_LvLab.Pos.W + 6, y1, 120)
        UI.LG_CatLab.Move(UI.LG_DdLevel.Pos.X + UI.LG_DdLevel.Pos.W + 16, y1 + 4, 100)
        UI.LG_DdCat.Move(UI.LG_CatLab.Pos.X + UI.LG_CatLab.Pos.W + 6, y1, 240)
        UI.LG_KeyLab.Move(UI.LG_DdCat.Pos.X + UI.LG_DdCat.Pos.W + 16, y1 + 4, 100)
        UI.LG_EdKey.Move(UI.LG_KeyLab.Pos.X + UI.LG_KeyLab.Pos.W + 6, y1, 80)
        
        ; 第二行控件位置 - 包含节流每秒
        y2 := y1 + rowH
        UI.LG_SetLab.Move(x, y2 + 4, 100)
        UI.LG_DdSetLevel.Move(UI.LG_SetLab.Pos.X + UI.LG_SetLab.Pos.W + 6, y2, 120)
        UI.LG_ModLab.Move(UI.LG_DdSetLevel.Pos.X + UI.LG_DdSetLevel.Pos.W + 16, y2 + 4, 100)
        UI.LG_DdSetCat.Move(UI.LG_ModLab.Pos.X + UI.LG_ModLab.Pos.W + 6, y2, 120)
        UI.LG_DdSetCatLvl.Move(UI.LG_DdSetCat.Pos.X + UI.LG_DdSetCat.Pos.W + 6, y2, 120)
        UI.LG_ThrLab.Move(UI.LG_DdSetCatLvl.Pos.X + UI.LG_DdSetCatLvl.Pos.W + 8, y2 + 4, 100)
        UI.LG_EdThr.Move(UI.LG_ThrLab.Pos.X + UI.LG_ThrLab.Pos.W + 6, y2, 80)
        
        ; 第三行控件位置 - 包含应用设置和清空模块覆盖按钮
        y3 := y2 + rowH
        UI.LG_BtnClear.Move(x, y3, 120, 26)
        UI.LG_BtnExport.Move(UI.LG_BtnClear.Pos.X + UI.LG_BtnClear.Pos.W + 10, y3, 120, 26)
        UI.LG_BtnOpen.Move(UI.LG_BtnExport.Pos.X + UI.LG_BtnExport.Pos.W + 10, y3, 120, 26)
        UI.LG_BtnApply.Move(UI.LG_BtnOpen.Pos.X + UI.LG_BtnOpen.Pos.W + 10, y3, 100, 26)
        UI.LG_BtnReset.Move(UI.LG_BtnApply.Pos.X + UI.LG_BtnApply.Pos.W + 8, y3, 120, 26)
        
        ; 第四行控件位置 - 只有刷新和自动刷新
        y4 := y3 + rowH
        UI.LG_BtnRefresh.Move(x, y4, 100, 26)
        UI.LG_Auto.Move(UI.LG_BtnRefresh.Pos.X + UI.LG_BtnRefresh.Pos.W + 10, y4 + 4, 120)
    } catch {
    }
}

Page_Logs_OnEnter(*) {
    Page_Logs_OnRefresh(0)
}

Page_Logs_OnRefresh(*) {
    global UI
    lines := []
    try {
        lines := Logger_MemGetRecent(2000)
    } catch {
        lines := []
    }

    filtLevel := "ALL"
    filtCat := "ALL"
    key := ""

    try {
        filtLevel := UI.LG_DdLevel.Text
    } catch {
        filtLevel := "ALL"
    }
    try {
        filtCat := UI.LG_DdCat.Text
    } catch {
        filtCat := "ALL"
    }
    try {
        key := Trim(UI.LG_EdKey.Value)
    } catch {
        key := ""
    }

    try {
        UI.LG_LV.Opt("-Redraw")
    } catch {
    }
    try {
        UI.LG_LV.Delete()
    } catch {
    }

    for _, ln in lines {
        if (ln = "") {
            continue
        }
        if (filtLevel != "ALL") {
            tag := " [" . filtLevel . "] "
            if !InStr(ln, tag) {
                continue
            }
        }
        if (filtCat != "ALL") {
            tagc := " [" . filtCat . "]"
            if !InStr(ln, tagc) {
                continue
            }
        }
        if (key != "") {
            if !InStr(ln, key) {
                continue
            }
        }
        try {
            UI.LG_LV.Add("", ln)
        } catch {
        }
    }

    try {
        UI.LG_LV.ModifyCol(1, "AutoHdr")
    } catch {
    }
    try {
        UI.LG_LV.Opt("+Redraw")
    } catch {
    }
}

Page_Logs_OnClear(*) {
    try {
        Logger_MemClear()
    } catch {
    }
    Page_Logs_OnRefresh(0)
}

Page_Logs_OnExport(*) {
    path := ""
    try {
        path := FileSelect("S16", A_ScriptDir "\Logs", "导出日志为", "Log (*.log)")
    } catch {
        path := ""
    }
    if (path = "") {
        return
    }
    lines := []
    try {
        lines := Logger_MemGetRecent(100000)
    } catch {
        lines := []
    }
    text := ""
    for _, ln in lines {
        text := text . ln
        if !(SubStr(ln, -1) = "`n") {
            text := text . "`r`n"
        }
    }
    try {
        FileAppend(text, path, "UTF-8")
        Notify("已导出日志： " path)
    } catch as e {
        MsgBox "导出失败：" e.Message
    }
}

Page_Logs_OnOpen(*) {
    dir := A_ScriptDir "\Logs"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox "无法打开目录：" dir
    }
}

Page_Logs_OnAutoToggle(*) {
    global UI
    state := 0
    try {
        state := UI.LG_Auto.Value
    } catch {
        state := 0
    }
    if (state) {
        if !UI.LG_TimerOn {
            SetTimer(Page_Logs_AutoTick, 1000)
            UI.LG_TimerOn := true
        }
    } else {
        if UI.LG_TimerOn {
            SetTimer(Page_Logs_AutoTick, 0)
            UI.LG_TimerOn := false
        }
    }
}
Page_Logs_AutoTick() {
    Page_Logs_OnRefresh(0)
}

Page_Logs_OnApply(*) {
    global UI
    ; 全局级别
    glv := ""
    try {
        glv := UI.LG_DdSetLevel.Text
    } catch {
        glv := ""
    }
    if (glv != "") {
        Logger_SetLevel(glv)
    }

    ; 按模块级别
    cat := ""
    lvl := ""
    try {
        cat := UI.LG_DdSetCat.Text
    } catch {
        cat := ""
    }
    try {
        lvl := UI.LG_DdSetCatLvl.Text
    } catch {
        lvl := ""
    }
    if (cat != "" && lvl != "") {
        Logger_SetLevelFor(cat, lvl)
    }

    ; 节流
    thr := 5
    try {
        if (UI.LG_EdThr.Value != "") {
            thr := Integer(UI.LG_EdThr.Value)
        }
    } catch {
        thr := 5
    }
    if (thr < 0) {
        thr := 0
    }
    Logger_SetThrottlePerSec(thr)

    Notify("日志设置已应用")
}

Page_Logs_OnReset(*) {
    Logger_ResetPerCategory()
    Notify("已清空按模块级别覆盖")
}

Page_Logs__LevelIndex(cur, arr) {
    i := 1
    while (i <= arr.Length) {
        if (StrUpper(arr[i]) = StrUpper(cur)) {
            return i
        }
        i := i + 1
    }
    return 0
}