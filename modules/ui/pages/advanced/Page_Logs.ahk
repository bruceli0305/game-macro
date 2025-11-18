#Requires AutoHotkey v2

; ========= 顶层页面函数 =========
Page_Logs_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.LG_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h110", rc.X, rc.Y, rc.W), "日志过滤与控制")
    page.Controls.Push(UI.LG_GB)

    x := rc.X + 12
    y := rc.Y + 26

    UI.LG_LvLab := UI.Main.Add("Text", Format("x{} y{} w80 Right", x, y + 4), "级别：")
    page.Controls.Push(UI.LG_LvLab)
    UI.LG_DdLevel := UI.Main.Add("DropDownList", "x+6 w120")
    page.Controls.Push(UI.LG_DdLevel)
    try {
        UI.LG_DdLevel.Add(["ALL","TRACE","DEBUG","INFO","WARN","ERROR","FATAL"])
        UI.LG_DdLevel.Value := 4
    } catch {
    }

    UI.LG_CatLab := UI.Main.Add("Text", "x+16 w80 Right", "分类：")
    page.Controls.Push(UI.LG_CatLab)
    UI.LG_DdCat := UI.Main.Add("DropDownList", "x+6 w160")
    page.Controls.Push(UI.LG_DdCat)
    try {
        UI.LG_DdCat.Add(["ALL","Core","Storage","Poller","Rotation","RuleEngine","Buff","WorkerPool","WorkerHost","DXGI","Pixel","ROI","UI","Tools","Settings","Diag","Logger"])
        UI.LG_DdCat.Value := 1
    } catch {
    }

    UI.LG_KeyLab := UI.Main.Add("Text", "x+16 w80 Right", "关键字：")
    page.Controls.Push(UI.LG_KeyLab)
    UI.LG_EdKey := UI.Main.Add("Edit", "x+6 w220")
    page.Controls.Push(UI.LG_EdKey)

    y2 := y + 34
    UI.LG_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", x, y2), "刷新")
    page.Controls.Push(UI.LG_BtnRefresh)
    UI.LG_Auto := UI.Main.Add("CheckBox", "x+8 w120", "自动刷新")
    page.Controls.Push(UI.LG_Auto)
    UI.LG_BtnClear := UI.Main.Add("Button", "x+8 w100 h26", "清空缓冲")
    page.Controls.Push(UI.LG_BtnClear)
    UI.LG_BtnExport := UI.Main.Add("Button", "x+8 w120 h26", "导出当前")
    page.Controls.Push(UI.LG_BtnExport)
    UI.LG_BtnOpen := UI.Main.Add("Button", "x+8 w120 h26", "打开 Logs 目录")
    page.Controls.Push(UI.LG_BtnOpen)

    ly := rc.Y + 110 + 10
    UI.LG_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, rc.H - (ly - rc.Y) - 8)
        , ["日志列表"])
    page.Controls.Push(UI.LG_LV)

    ; 绑定事件到“顶层函数”
    UI.LG_BtnRefresh.OnEvent("Click", Page_Logs_OnRefresh)
    UI.LG_BtnClear.OnEvent("Click", Page_Logs_OnClear)
    UI.LG_BtnExport.OnEvent("Click", Page_Logs_OnExport)
    UI.LG_BtnOpen.OnEvent("Click", Page_Logs_OnOpen)
    UI.LG_Auto.OnEvent("Click", Page_Logs_OnAutoToggle)

    ; 自动刷新标记
    UI.LG_TimerOn := false

    ; 初次刷新
    Page_Logs_OnRefresh(0)
}

Page_Logs_Layout(rc) {
    try {
        UI.LG_GB.Move(rc.X, rc.Y, rc.W, 110)
        ly := rc.Y + 110 + 10
        UI.LG_LV.Move(rc.X, ly, rc.W, rc.H - (ly - rc.Y) - 8)
    } catch {
    }
}

Page_Logs_OnEnter(*) {
    ; 注意：这里调用的是顶层的 Page_Logs_OnRefresh，而不是局部函数
    Page_Logs_OnRefresh(0)
}

; ========= 事件处理（顶层可见） =========
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