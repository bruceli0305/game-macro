#Requires AutoHotkey v2
; modules\ui\pages\automation\Page_Rules_Summary.ahk
; 自动化 → 循环规则（摘要页）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：RU_

Page_Rules_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    sumH := 26 + 6*22 + 8 + 26 + 10
    UI.RU_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, sumH), "循环规则 - 摘要")
    page.Controls.Push(UI.RU_GB_Sum)

    UI.RU_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r7 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.RU_Info)

    UI.RU_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "刷新")
    page.Controls.Push(UI.RU_BtnRefresh)

    UI.RU_BtnSave := UI.Main.Add("Button", "x+8 w100 h26", "保存")
    page.Controls.Push(UI.RU_BtnSave)

    ly := rc.Y + sumH + 10
    listH := Max(300, rc.H - (ly - rc.Y))
    UI.RU_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "规则管理")
    page.Controls.Push(UI.RU_GB_List)

    UI.RU_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        , ["ID","启用","名称","逻辑","条件数","动作数","冷却ms","优先级","动作间隔","线程"])
    page.Controls.Push(UI.RU_LV)

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

    UI.RU_BtnRefresh.OnEvent("Click", Rules_OnRefresh)
    UI.RU_BtnSave.OnEvent("Click", Rules_OnSave)
    UI.RU_BtnAdd.OnEvent("Click", Rules_OnAdd)
    UI.RU_BtnEdit.OnEvent("Click", Rules_OnEdit)
    UI.RU_BtnDel.OnEvent("Click", Rules_OnDelete)
    UI.RU_BtnUp.OnEvent("Click", Rules_OnMoveUp)
    UI.RU_BtnDown.OnEvent("Click", Rules_OnMoveDown)
    UI.RU_LV.OnEvent("DoubleClick", Rules_OnEdit)

    Rules_RefreshAll()
}

Page_Rules_Layout(rc) {
    try {
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
            try {
                thr := HasProp(r, "ThreadId") ? r.ThreadId : 1
            } catch {
                thr := 1
            }
            if !byThr.Has(thr) {
                byThr[thr] := 0
            }
            byThr[thr] := byThr[thr] + 1

            lf := 0
            try {
                lf := HasProp(r, "LastFire") ? r.LastFire : 0
            } catch {
                lf := 0
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
            rid := 0
            en := ""
            name := ""
            logic := ""
            cc := 0
            ac := 0
            cd := 0
            prio := i
            gap := 60
            thr := 1
            tname := ""

            try {
                rid := OM_Get(r, "Id", 0)
            } catch {
                rid := 0
            }
            try {
                en := (HasProp(r,"Enabled") && r.Enabled) ? "√" : ""
            } catch {
                en := ""
            }
            try {
                name := HasProp(r,"Name") ? r.Name : ("Rule" i)
            } catch {
                name := "Rule"
            }
            try {
                logic := HasProp(r,"Logic") ? r.Logic : "AND"
            } catch {
                logic := "AND"
            }
            try {
                cc := HasProp(r,"Conditions") ? r.Conditions.Length : 0
            } catch {
                cc := 0
            }
            try {
                ac := HasProp(r,"Actions") ? r.Actions.Length : 0
            } catch {
                ac := 0
            }
            try {
                cd := HasProp(r,"CooldownMs") ? r.CooldownMs : 0
            } catch {
                cd := 0
            }
            try {
                prio := HasProp(r,"Priority") ? r.Priority : i
            } catch {
                prio := i
            }
            try {
                gap := HasProp(r,"ActionGapMs") ? r.ActionGapMs : 60
            } catch {
                gap := 60
            }
            try {
                thr := HasProp(r,"ThreadId") ? r.ThreadId : 1
            } catch {
                thr := 1
            }
            tname := ThreadNameById(thr)
            UI.RU_LV.Add("", rid, en, name, logic, cc, ac, cd, prio, gap, tname)
        }
        loop 10 {
            try {
                UI.RU_LV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
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
            try {
                if (t.Id = id) {
                    return t.Name
                }
            } catch {
            }
        }
    }
    return (id = 1) ? "默认线程" : "线程#" id
}

; ====== 事件 ======

Rules_OnRefresh(*) {
    Rules_RefreshAll()
}

Rules_OnSave(*) {
    global App
    if !(IsSet(App) && App.Has("CurrentProfile") && App.Has("ProfileData")) {
        MsgBox "未选择配置或配置未加载。"
        return
    }

    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置。"
        return
    }

    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch {
        MsgBox "加载配置失败。"
        return
    }

    newArr := []
    try {
        if (HasProp(App["ProfileData"], "Rules") && IsObject(App["ProfileData"].Rules)) {
            skIdByIdx := Map()
            ptIdByIdx := Map()

            try {
                if (p.Has("Skills") && IsObject(p["Skills"])) {
                    si := 1
                    while (si <= p["Skills"].Length) {
                        sid := 0
                        try {
                            sid := OM_Get(p["Skills"][si], "Id", 0)
                        } catch {
                            sid := 0
                        }
                        skIdByIdx[si] := sid
                        si := si + 1
                    }
                }
            } catch {
            }

            try {
                if (p.Has("Points") && IsObject(p["Points"])) {
                    pi := 1
                    while (pi <= p["Points"].Length) {
                        pid := 0
                        try {
                            pid := OM_Get(p["Points"][pi], "Id", 0)
                        } catch {
                            pid := 0
                        }
                        ptIdByIdx[pi] := pid
                        pi := pi + 1
                    }
                }
            } catch {
            }

            i := 1
            while (i <= App["ProfileData"].Rules.Length) {
                rr := App["ProfileData"].Rules[i]
                r := PM_NewRule()
                try {
                    r["Id"] := OM_Get(rr, "Id", 0)
                } catch {
                }
                r["Name"]             := OM_Get(rr, "Name", "Rule")
                r["Enabled"]          := OM_Get(rr, "Enabled", 1)
                r["Logic"]            := OM_Get(rr, "Logic", "AND")
                r["CooldownMs"]       := OM_Get(rr, "CooldownMs", 500)
                r["Priority"]         := OM_Get(rr, "Priority", i)
                r["ActionGapMs"]      := OM_Get(rr, "ActionGapMs", 60)
                r["ThreadId"]         := OM_Get(rr, "ThreadId", 1)
                r["SessionTimeoutMs"] := OM_Get(rr, "SessionTimeoutMs", 0)
                r["AbortCooldownMs"]  := OM_Get(rr, "AbortCooldownMs", 0)

                ; 条件（索引 → Id）
                conds := []
                try {
                    if (HasProp(rr, "Conditions") && IsObject(rr.Conditions)) {
                        j := 1
                        while (j <= rr.Conditions.Length) {
                            c0 := rr.Conditions[j]
                            kind := OM_Get(c0, "Kind", "Pixel")
                            kindU := StrUpper(kind)

                            if (kindU = "COUNTER") {
                                si := OM_Get(c0, "SkillIndex", 0)
                                sid := 0
                                try {
                                    sid := skIdByIdx.Has(si) ? skIdByIdx[si] : 0
                                } catch {
                                    sid := 0
                                }
                                cmp := OM_Get(c0, "Cmp", "GE")
                                val := OM_Get(c0, "Value", 1)
                                rst := OM_Get(c0, "ResetOnTrigger", 0)
                                conds.Push({ Kind:"Counter", SkillId: sid, Cmp: cmp, Value: val, ResetOnTrigger: rst })
                            } else {
                                rt  := OM_Get(c0, "RefType", "Skill")
                                ri  := OM_Get(c0, "RefIndex", 0)
                                op  := OM_Get(c0, "Op", "EQ")
                                refId := 0
                                if (StrUpper(rt) = "SKILL") {
                                    try {
                                        refId := skIdByIdx.Has(ri) ? skIdByIdx[ri] : 0
                                    } catch {
                                        refId := 0
                                    }
                                } else {
                                    try {
                                        refId := ptIdByIdx.Has(ri) ? ptIdByIdx[ri] : 0
                                    } catch {
                                        refId := 0
                                    }
                                }
                                ; 颜色/容差的持久层字段由 UI 另处确定；此处维持必要字段
                                conds.Push({ Kind:"Pixel", RefType: rt, RefId: refId, Op: op, Color: "0x000000", Tol: 16 })
                            }
                            j := j + 1
                        }
                    }
                } catch {
                }
                r["Conditions"] := conds

                ; 动作（索引 → Id）
                acts := []
                try {
                    if (HasProp(rr, "Actions") && IsObject(rr.Actions)) {
                        j := 1
                        while (j <= rr.Actions.Length) {
                            a0 := rr.Actions[j]
                            si := OM_Get(a0, "SkillIndex", 0)
                            sid := 0
                            try {
                                sid := skIdByIdx.Has(si) ? skIdByIdx[si] : 0
                            } catch {
                                sid := 0
                            }

                            a := PM_NewAction()
                            a["SkillId"]         := sid
                            a["DelayMs"]         := OM_Get(a0, "DelayMs", 0)
                            a["HoldMs"]          := OM_Get(a0, "HoldMs", -1)
                            a["RequireReady"]    := OM_Get(a0, "RequireReady", 0)
                            a["Verify"]          := OM_Get(a0, "Verify", 0)
                            a["VerifyTimeoutMs"] := OM_Get(a0, "VerifyTimeoutMs", 600)
                            a["Retry"]           := OM_Get(a0, "Retry", 0)
                            a["RetryGapMs"]      := OM_Get(a0, "RetryGapMs", 150)
                            acts.Push(a)
                            j := j + 1
                        }
                    }
                } catch {
                }
                r["Actions"] := acts

                newArr.Push(r)
                i := i + 1
            }
        }
    } catch {
    }

    p["Rules"] := newArr

    ok := false
    try {
        SaveModule_Rules(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
    } catch {
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    try {
        WorkerPool_Rebuild()
    } catch {
    }
    try {
        Counters_Init()
    } catch {
    }
    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
    } catch {
    }

    Rules_RefreshAll()
    Notify("循环配置已保存")
}

Rules_OnAdd(*) {
    global App
    ; 安全计算新规则的优先级
    prio := 1
    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")
        && IsObject(App["ProfileData"].Rules)) {
            prio := App["ProfileData"].Rules.Length + 1
        } else {
            prio := 1
        }
    } catch {
        prio := 1
    }

    newR := { Id: 0
            , Name: "新规则", Enabled: 1, Logic: "AND"
            , CooldownMs: 500, Priority: prio, ActionGapMs: 60
            , Conditions: [], Actions: [], LastFire: 0, ThreadId: 1 }

    ; 尝试打开编辑器，若失败显示具体错误信息，便于定位 include 问题
    try {
        RuleEditor_Open(newR, 0, OnSavedNew)
    } catch as e {
        msg := "无法新增规则。"
        try {
            msg := msg "`r`n" e.Message
        }
        MsgBox msg
        return
    }

    OnSavedNew(savedR, idx) {
        global App
        try {
            if !HasProp(savedR, "Id") {
                savedR.Id := 0
            }
        } catch {
        }
        ; 确保 Rules 数组存在
        try {
            if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")
            && IsObject(App["ProfileData"].Rules)) {
                App["ProfileData"].Rules := []
            }
        } catch {
            App["ProfileData"].Rules := []
        }
        App["ProfileData"].Rules.Push(savedR)
        Rules_RefreshAll()
    }
}

Rules_OnEdit(*) {
    global App, UI
    row := 0
    try {
        row := UI.RU_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
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
    try {
        old := App["ProfileData"].Rules[idx2]
        if (old && HasProp(old, "Id")) {
            savedR.Id := old.Id
        }
    } catch {
    }
    App["ProfileData"].Rules[idx2] := savedR
    Rules_RefreshAll()
}

Rules_OnDelete(*) {
    global App, UI
    row := 0
    try {
        row := UI.RU_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请先选中一个规则。"
        return
    }
    try {
        idx := row
        App["ProfileData"].Rules.RemoveAt(idx)
        for i, r in App["ProfileData"].Rules {
            r.Priority := i
        }
        Rules_RefreshAll()
        Notify("已删除规则")
    } catch {
        MsgBox "无法删除规则。"
    }
}

Rules_OnMoveUp(*) {
    global App, UI
    row := 0
    try {
        row := UI.RU_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        from := row
        to := from - 1
        if (to < 1) {
            return
        }
        item := App["ProfileData"].Rules[from]
        App["ProfileData"].Rules.RemoveAt(from)
        App["ProfileData"].Rules.InsertAt(to, item)
        for i, r in App["ProfileData"].Rules {
            r.Priority := i
        }
        Rules_RefreshAll()
        UI.RU_LV.Modify(to, "Select Focus Vis")
    } catch {
        MsgBox "无法上移规则。"
    }
}

Rules_OnMoveDown(*) {
    global App, UI
    row := 0
    try {
        row := UI.RU_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        from := row
        to := from + 1
        if (to > App["ProfileData"].Rules.Length) {
            return
        }
        item := App["ProfileData"].Rules[from]
        App["ProfileData"].Rules.RemoveAt(from)
        App["ProfileData"].Rules.InsertAt(to, item)
        for i, r in App["ProfileData"].Rules {
            r.Priority := i
        }
        Rules_RefreshAll()
        UI.RU_LV.Modify(to, "Select Focus Vis")
    } catch {
        MsgBox "无法下移规则。"
    }
}