#Requires AutoHotkey v2
;Page_Rules_Summary.ahk
; 自动化 → 循环规则（摘要页）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：RU_

Page_Rules_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== 摘要区 ======
    ; 计算摘要区实际高度：标题栏26 + 7行文本编辑框(7*22=154) + 按钮区域(26+5=31) = 211像素
    sumH := 26 + 6*22 + 8 + 26 + 10
    UI.RU_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, sumH), "循环规则 - 摘要")
    page.Controls.Push(UI.RU_GB_Sum)

    UI.RU_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r7 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.RU_Info)

    UI.RU_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "刷新")
    page.Controls.Push(UI.RU_BtnRefresh)

    UI.RU_BtnSave := UI.Main.Add("Button", "x+8 w100 h26", "保存")
    page.Controls.Push(UI.RU_BtnSave)

    ; ====== 规则列表 ======
    ly := rc.Y + sumH + 10
    listH := Max(300, rc.H - (ly - rc.Y))
    UI.RU_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "规则管理")
    page.Controls.Push(UI.RU_GB_List)

    UI.RU_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        , ["ID","启用","名称","逻辑","条件数","动作数","冷却ms","优先级","动作间隔","线程"])
    page.Controls.Push(UI.RU_LV)

    ; 管理按钮
    UI.RU_BtnAdd := UI.Main.Add("Button", Format("x{} y{} w90 h26", rc.X + 12, ly + listH - 40), "新增规则")
    page.Controls.Push(UI.RU_BtnAdd)
    
    UI.RU_BtnEdit := UI.Main.Add("Button", "x+8 w90 h26", "编辑规则")
    page.Controls.Push(UI.RU_BtnEdit)
    
    UI.RU_BtnDel := UI.Main.Add("Button", "x+8 w90 h26", "删除规则")
    page.Controls.Push(UI.RU_BtnDel)
    
    UI.RU_BtnUp := UI.Main.Add("Button", "x+8 w90 h26", "上移")
    page.Controls.Push(UI.RU_BtnUp)
    
    UI.RU_BtnDown := UI.Main.Add("Button", "x+8 w90 h26", "下移")
    page.Controls.Push(UI.RU_BtnDown)

    ; 事件
    UI.RU_BtnRefresh.OnEvent("Click", Rules_OnRefresh)
    UI.RU_BtnSave.OnEvent("Click", Rules_OnSave)
    UI.RU_BtnAdd.OnEvent("Click", Rules_OnAdd)
    UI.RU_BtnEdit.OnEvent("Click", Rules_OnEdit)
    UI.RU_BtnDel.OnEvent("Click", Rules_OnDelete)
    UI.RU_BtnUp.OnEvent("Click", Rules_OnMoveUp)
    UI.RU_BtnDown.OnEvent("Click", Rules_OnMoveDown)
    UI.RU_LV.OnEvent("DoubleClick", Rules_OnEdit)

    ; 首次刷新
    Rules_RefreshAll()
}

Page_Rules_Layout(rc) {
    try {
        ; 计算摘要区实际高度：标题栏26 + 7行文本编辑框(7*22=154) + 按钮区域(26+5=31) = 211像素
        sumH := 26 + 6*22 + 8 + 26 + 10
        UI.RU_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.RU_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.RU_BtnRefresh.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.RU_BtnSave.Move(UI.RU_BtnRefresh.Pos.X + UI.RU_BtnRefresh.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10
        listH := Max(300, rc.H - (ly - rc.Y))
        UI.RU_GB_List.Move(rc.X, ly, rc.W, listH)
        UI.RU_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        
        UI.RU_BtnAdd.Move(rc.X + 12, ly + listH - 40)
        UI.RU_BtnEdit.Move(UI.RU_BtnAdd.Pos.X + UI.RU_BtnAdd.Pos.W + 8, ly + listH - 40)
        UI.RU_BtnDel.Move(UI.RU_BtnEdit.Pos.X + UI.RU_BtnEdit.Pos.W + 8, ly + listH - 40)
        UI.RU_BtnUp.Move(UI.RU_BtnDel.Pos.X + UI.RU_BtnDel.Pos.W + 8, ly + listH - 40)
        UI.RU_BtnDown.Move(UI.RU_BtnUp.Pos.X + UI.RU_BtnUp.Pos.W + 8, ly + listH - 40)
    } catch {
    }
}

Page_Rules_OnEnter(*) {
    Rules_RefreshAll()
}

; ====== 刷新逻辑 ======

Rules_RefreshAll() {
    Rules_FillSummary()
    Rules_FillList()
}

Rules_FillSummary() {
    global App, UI
    txt := ""
    tot := 0
    en := 0
    byThr := Map()
    lastAny := 0

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            UI.RU_Info.Value := "当前配置无规则。"
            return
        }
        for i, r in App["ProfileData"].Rules {
            tot := tot + 1
            if (HasProp(r, "Enabled") && r.Enabled) {
                en := en + 1
            }
            thr := 1
            if (HasProp(r, "ThreadId")) {
                thr := r.ThreadId
            }
            if !byThr.Has(thr) {
                byThr[thr] := 0
            }
            byThr[thr] := byThr[thr] + 1

            lf := 0
            if (HasProp(r, "LastFire")) {
                lf := r.LastFire
            }
            if (lf > lastAny) {
                lastAny := lf
            }
        }
    } catch {
        txt := "读取规则失败。"
    }

    if (txt = "") {
        txt := "规则总数: " tot "`r`n"
        txt .= "启用: " en "  禁用: " (tot - en) "`r`n"
        txt .= "按线程分布: "
        if (byThr.Count = 0) {
            txt .= "-"
        } else {
            first := true
            for k, v in byThr {
                if (first) {
                    txt .= "[T" k ":" v "]"
                    first := false
                } else {
                    txt .= " [T" k ":" v "]"
                }
            }
        }
        txt .= "`r`n"
        if (lastAny > 0) {
            dt := A_TickCount - lastAny
            txt .= "最近触发: " dt " ms 前"
        } else {
            txt .= "最近触发: -"
        }
    }

    try {
        UI.RU_Info.Value := txt
    } catch {
    }
}

Rules_FillList() {
    global App, UI
    try {
        UI.RU_LV.Opt("-Redraw")
        UI.RU_LV.Delete()
    } catch {
    }

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            return
        }
        for i, r in App["ProfileData"].Rules {
            en := (HasProp(r,"Enabled") && r.Enabled) ? "√" : ""
            name := HasProp(r,"Name") ? r.Name : ("Rule" i)
            logic := HasProp(r,"Logic") ? r.Logic : "AND"
            cc := HasProp(r,"Conditions") ? r.Conditions.Length : 0
            ac := HasProp(r,"Actions") ? r.Actions.Length : 0
            cd := HasProp(r,"CooldownMs") ? r.CooldownMs : 0
            prio := HasProp(r,"Priority") ? r.Priority : i
            gap := HasProp(r,"ActionGapMs") ? r.ActionGapMs : 60
            thr := HasProp(r,"ThreadId") ? r.ThreadId : 1
            tname := ThreadNameById(thr)
            UI.RU_LV.Add("", i, en, name, logic, cc, ac, cd, prio, gap, tname)
        }
        loop 10 {
            UI.RU_LV.ModifyCol(A_Index, "AutoHdr")
        }
    } catch {
    } finally {
        try {
            UI.RU_LV.Opt("+Redraw")
        } catch {
        }
    }
}

ThreadNameById(id) {
    global App
    if HasProp(App["ProfileData"], "Threads") {
        for _, t in App["ProfileData"].Threads {
            if (t.Id = id)
                return t.Name
        }
    }
    return (id = 1) ? "默认线程" : "线程#" id
}

; ====== 事件 ======

Rules_OnRefresh(*) {
    Rules_RefreshAll()
}

Rules_OnSave(*) {
    try {
        Storage_SaveProfile(App["ProfileData"])
        Notify("循环配置已保存")
    } catch {
        MsgBox "保存失败。"
    }
}

Rules_OnAdd(*) {
    try {
        global App
        newR := {
            Name: "新规则", Enabled: 1, Logic: "AND", CooldownMs: 500
          , Priority: App["ProfileData"].Rules.Length + 1, ActionGapMs: 60
          , Conditions: [], Actions: [], LastFire: 0, ThreadId: 1
        }
        RuleEditor_Open(newR, 0, OnSavedNew)
    } catch {
        MsgBox "无法新增规则。"
    }
}

OnSavedNew(savedR, idx) {
    global App
    App["ProfileData"].Rules.Push(savedR)
    Rules_RefreshAll()
}

Rules_OnEdit(*) {
    row := UI.RU_LV.GetNext(0, "Focused")
    if !row {
        MsgBox "请先选中一个规则。"
        return
    }
    try {
        idx := row
        cur := App["ProfileData"].Rules[idx]
        RuleEditor_Open(cur, idx, OnSavedEdit)
    } catch {
        MsgBox "无法编辑规则。"
    }
}

OnSavedEdit(savedR, idx2) {
    global App
    App["ProfileData"].Rules[idx2] := savedR
    Rules_RefreshAll()
}

Rules_OnDelete(*) {
    row := UI.RU_LV.GetNext(0, "Focused")
    if !row {
        MsgBox "请先选中一个规则。"
        return
    }
    try {
        idx := row
        App["ProfileData"].Rules.RemoveAt(idx)
        for i, r in App["ProfileData"].Rules
            r.Priority := i
        Rules_RefreshAll()
        Notify("已删除规则")
    } catch {
        MsgBox "无法删除规则。"
    }
}

Rules_OnMoveUp(*) {
    row := UI.RU_LV.GetNext(0, "Focused")
    if !row
        return
    try {
        from := row, to := from - 1
        if (to < 1)
            return
        item := App["ProfileData"].Rules[from]
        App["ProfileData"].Rules.RemoveAt(from)
        App["ProfileData"].Rules.InsertAt(to, item)
        for i, r in App["ProfileData"].Rules
            r.Priority := i
        Rules_RefreshAll()
        UI.RU_LV.Modify(to, "Select Focus Vis")
    } catch {
        MsgBox "无法上移规则。"
    }
}

Rules_OnMoveDown(*) {
    row := UI.RU_LV.GetNext(0, "Focused")
    if !row
        return
    try {
        from := row, to := from + 1
        if (to > App["ProfileData"].Rules.Length)
            return
        item := App["ProfileData"].Rules[from]
        App["ProfileData"].Rules.RemoveAt(from)
        App["ProfileData"].Rules.InsertAt(to, item)
        for i, r in App["ProfileData"].Rules
            r.Priority := i
        Rules_RefreshAll()
        UI.RU_LV.Modify(to, "Select Focus Vis")
    } catch {
        MsgBox "无法下移规则。"
    }
}