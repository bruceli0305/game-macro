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
    UI.RU_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h180", rc.X, rc.Y, rc.W), "循环规则 - 摘要")
    page.Controls.Push(UI.RU_GB_Sum)

    UI.RU_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r7 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.RU_Info)

    UI.RU_BtnOpen := UI.Main.Add("Button", Format("x{} y{} w160 h26", rc.X + 12, rc.Y + 26 + 7*22 + 10), "打开规则管理器")
    page.Controls.Push(UI.RU_BtnOpen)

    UI.RU_BtnRefresh := UI.Main.Add("Button", "x+8 w100 h26", "刷新")
    page.Controls.Push(UI.RU_BtnRefresh)

    ; ====== 规则列表 ======
    ly := rc.Y + 180 + 10
    UI.RU_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, Max(220, rc.H - (ly - rc.Y))), "规则列表")
    page.Controls.Push(UI.RU_GB_List)

    UI.RU_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, Max(180, rc.H - (ly - rc.Y) - 40))
        , ["ID","名称","启用","线程","条件#","动作#","冷却(ms)","上次触发"])
    page.Controls.Push(UI.RU_LV)

    ; 事件
    UI.RU_BtnOpen.OnEvent("Click", Rules_OnOpenManager)
    UI.RU_BtnRefresh.OnEvent("Click", Rules_OnRefresh)

    ; 首次刷新
    Rules_RefreshAll()
}

Page_Rules_Layout(rc) {
    try {
        UI.RU_GB_Sum.Move(rc.X, rc.Y, rc.W)
        UI.RU_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.RU_BtnOpen.Move(rc.X + 12, rc.Y + 26 + 7*22 + 10)
        UI.RU_BtnRefresh.Move(UI.RU_BtnOpen.Pos.X + UI.RU_BtnOpen.Pos.W + 8, rc.Y + 26 + 7*22 + 10)

        ly := rc.Y + 180 + 10
        listH := Max(220, rc.H - (ly - rc.Y))
        UI.RU_GB_List.Move(rc.X, ly, rc.W, listH)
        UI.RU_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 40)
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
            name := HasProp(r,"Name") ? r.Name : ("Rule" i)
            en := (HasProp(r,"Enabled") && r.Enabled) ? "√" : ""
            thr := HasProp(r,"ThreadId") ? r.ThreadId : 1
            cc := HasProp(r,"Conditions") ? r.Conditions.Length : 0
            ac := HasProp(r,"Actions") ? r.Actions.Length : 0
            cd := HasProp(r,"CooldownMs") ? r.CooldownMs : 0
            lf := HasProp(r,"LastFire") ? r.LastFire : 0
            lfTxt := (lf > 0) ? (A_TickCount - lf) " ms 前" : "-"
            UI.RU_LV.Add("", i, name, en, thr, cc, ac, cd, lfTxt)
        }
        loop 8 {
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

; ====== 事件 ======

Rules_OnOpenManager(*) {
    try {
        RulesManager_Show()
    } catch {
        MsgBox "无法打开规则管理器。"
    }
}

Rules_OnRefresh(*) {
    Rules_RefreshAll()
}