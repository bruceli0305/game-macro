#Requires AutoHotkey v2
; modules\ui\dialogs\GUI_RuleEditor.ahk
; 技能循环规则管理与编辑（支持“计数条件”）
; 严格块结构，不使用单行 if/try/catch

RulesManager_Show() {
    global App
    prof := App["ProfileData"]

    dlg := Gui("+Owner" UI.Main.Hwnd, "技能循环 - 规则管理")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    dlg.Add("Text", "xm", "规则列表：")
    lv := dlg.Add("ListView", "xm w760 r14 +Grid"
        , ["ID", "启用", "名称", "逻辑", "条件数", "动作数", "冷却ms", "优先级", "动作间隔", "线程"])
    btnAdd := dlg.Add("Button", "xm w90", "新增规则")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑规则")
    btnDel := dlg.Add("Button", "x+8 w90", "删除规则")
    btnUp := dlg.Add("Button", "x+8 w90", "上移")
    btnDn := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w100", "保存")

    RefreshLV()

    lv.OnEvent("DoubleClick", (*) => EditSel())
    btnAdd.OnEvent("Click", (*) => AddRule())
    btnEdit.OnEvent("Click", (*) => EditSel())
    btnDel.OnEvent("Click", (*) => DelSel())
    btnUp.OnEvent("Click", (*) => MoveSel(-1))
    btnDn.OnEvent("Click", (*) => MoveSel(1))
    btnSave.OnEvent("Click", (*) => SaveAll())
    dlg.OnEvent("Close", (*) => dlg.Destroy())

    dlg.Show()

    RefreshLV() {
        try {
            lv.Opt("-Redraw")
            lv.Delete()
        } catch {
        }
        try {
            for i, r in prof.Rules {
                rid := 0
                en := ""
                name := ""
                logic := ""
                cc := 0
                ac := 0
                cd := 0
                prio := i
                gap := 60
                tname := ""

                try {
                    rid := OM_Get(r, "Id", 0)
                } catch {
                    rid := 0
                }
                try {
                    en := (HasProp(r, "Enabled") && r.Enabled) ? "√" : ""
                } catch {
                    en := ""
                }
                try {
                    name := HasProp(r, "Name") ? r.Name : ("Rule" i)
                } catch {
                    name := "Rule"
                }
                try {
                    logic := HasProp(r, "Logic") ? r.Logic : "AND"
                } catch {
                    logic := "AND"
                }
                try {
                    cc := HasProp(r, "Conditions") ? r.Conditions.Length : 0
                } catch {
                    cc := 0
                }
                try {
                    ac := HasProp(r, "Actions") ? r.Actions.Length : 0
                } catch {
                    ac := 0
                }
                try {
                    cd := HasProp(r, "CooldownMs") ? r.CooldownMs : 0
                } catch {
                    cd := 0
                }
                try {
                    prio := HasProp(r, "Priority") ? r.Priority : i
                } catch {
                    prio := i
                }
                try {
                    gap := HasProp(r, "ActionGapMs") ? r.ActionGapMs : 60
                } catch {
                    gap := 60
                }
                try {
                    tname := ThreadNameById(HasProp(r, "ThreadId") ? r.ThreadId : 1)
                } catch {
                    tname := "默认线程"
                }
                lv.Add("", rid, en, name, logic, cc, ac, cd, prio, gap, tname)
            }
            loop 10 {
                try {
                    lv.ModifyCol(A_Index, "AutoHdr")
                } catch {
                }
            }
        } catch {
        } finally {
            try {
                lv.Opt("+Redraw")
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

    AddRule() {
        newR := {
            Id: 0, Name: "新规则", Enabled: 1, Logic: "AND", CooldownMs: 500, Priority: prof.Rules.Length + 1, ActionGapMs: 60,
            Conditions: [], Actions: [], LastFire: 0, ThreadId: 1
        }
        RuleEditor_Open(newR, 0, OnSavedNew)
    }

    OnSavedNew(savedR, idx) {
        global App
        try {
            if !HasProp(savedR, "Id") {
                savedR.Id := 0
            }
        } catch {
        }
        App["ProfileData"].Rules.Push(savedR)
        RefreshLV()
    }

    EditSel() {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请先选中一个规则。"
            return
        }
        idx := row
        cur := prof.Rules[idx]
        RuleEditor_Open(cur, idx, OnSavedEdit)
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
        RefreshLV()
    }

    DelSel() {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请先选中一个规则。"
            return
        }
        idx := row
        prof.Rules.RemoveAt(idx)
        for i, r in prof.Rules {
            r.Priority := i
        }
        RefreshLV()
        Notify("已删除规则")
    }

    MoveSel(dir) {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        from := row
        to := from + dir
        if (to < 1 || to > prof.Rules.Length) {
            return
        }
        item := prof.Rules[from]
        prof.Rules.RemoveAt(from)
        prof.Rules.InsertAt(to, item)
        for i, r in prof.Rules {
            r.Priority := i
        }
        RefreshLV()
        try {
            lv.Modify(to, "Select Focus Vis")
        } catch {
        }
    }

    SaveAll() {
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
                    r["Name"] := OM_Get(rr, "Name", "Rule")
                    r["Enabled"] := OM_Get(rr, "Enabled", 1)
                    r["Logic"] := OM_Get(rr, "Logic", "AND")
                    r["CooldownMs"] := OM_Get(rr, "CooldownMs", 500)
                    r["Priority"] := OM_Get(rr, "Priority", i)
                    r["ActionGapMs"] := OM_Get(rr, "ActionGapMs", 60)
                    r["ThreadId"] := OM_Get(rr, "ThreadId", 1)
                    r["SessionTimeoutMs"] := OM_Get(rr, "SessionTimeoutMs", 0)
                    r["AbortCooldownMs"] := OM_Get(rr, "AbortCooldownMs", 0)

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
                                    conds.Push({ Kind: "Counter", SkillId: sid, Cmp: cmp, Value: val, ResetOnTrigger: rst })
                                } else {
                                    rt := OM_Get(c0, "RefType", "Skill")
                                    ri := OM_Get(c0, "RefIndex", 0)
                                    op := OM_Get(c0, "Op", "EQ")
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
                                    conds.Push({ Kind: "Pixel", RefType: rt, RefId: refId, Op: op, Color: "0x000000",
                                        Tol: 16 })
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
                                a["SkillId"] := sid
                                a["DelayMs"] := OM_Get(a0, "DelayMs", 0)
                                a["HoldMs"] := OM_Get(a0, "HoldMs", -1)
                                a["RequireReady"] := OM_Get(a0, "RequireReady", 0)
                                a["Verify"] := OM_Get(a0, "Verify", 0)
                                a["VerifyTimeoutMs"] := OM_Get(a0, "VerifyTimeoutMs", 600)
                                a["Retry"] := OM_Get(a0, "Retry", 0)
                                a["RetryGapMs"] := OM_Get(a0, "RetryGapMs", 150)
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

        RefreshLV()
        Notify("循环配置已保存")
    }
}

; 规则编辑器（与原版基本一致，仍使用索引引用）
RuleEditor_Open(rule, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)

    defaults := Map("Name", "新规则", "Enabled", 1, "Logic", "AND", "CooldownMs", 500, "Priority", 1, "ActionGapMs", 60,
        "ThreadId", 1)
    for k, v in defaults {
        if !HasProp(rule, k) {
            rule.%k% := v
        }
    }
    if !HasProp(rule, "Conditions") {
        rule.Conditions := []
    }
    if !HasProp(rule, "Actions") {
        rule.Actions := []
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增规则" : "编辑规则")
    dlg.MarginX := 12, dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    dlg.Add("Text", "w90 Right", "名称：")
    tbName := dlg.Add("Edit", "x+6 w160", rule.Name)

    cbEn := dlg.Add("CheckBox", "x+12 w80 vRuleEnabled", "启用")
    cbEn.Value := rule.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+16 w90 Right", "逻辑：")
    ddLogic := dlg.Add("DropDownList", "x+6 w160", ["AND", "OR"])
    ddLogic.Value := (StrUpper(rule.Logic) = "OR") ? 2 : 1

    dlg.Add("Text", "x+20 w90 Right", "冷却(ms)：")
    edCd := dlg.Add("Edit", "x+6 w160 Number", rule.CooldownMs)

    dlg.Add("Text", "x+20 w90 Right", "优先级：")
    edPrio := dlg.Add("Edit", "x+6 w160 Number", rule.Priority)

    dlg.Add("Text", "xm y+10 w90 Right", "间隔(ms)：")
    edGap := dlg.Add("Edit", "x+6 w160 Number", rule.ActionGapMs)

    dlg.Add("Text", "x+20 w90 Right", "会话超时(ms)：")
    edSessTO := dlg.Add("Edit", "x+6 w160 Number", HasProp(rule, "SessionTimeoutMs") ? rule.SessionTimeoutMs : 0)

    dlg.Add("Text", "x+20 w100 Right", "中止冷却(ms)：")
    edAbortCd := dlg.Add("Edit", "x+6 w160 Number", HasProp(rule, "AbortCooldownMs") ? rule.AbortCooldownMs : 0)

    dlg.Add("Text", "x+20 w90 Right", "线程：")
    ddThread := dlg.Add("DropDownList", "x+6 w160")
    names := []
    for _, t in App["ProfileData"].Threads {
        names.Push(t.Name)
    }
    if names.Length {
        ddThread.Add(names)
    }
    curTid := HasProp(rule, "ThreadId") ? rule.ThreadId : 1
    ddThread.Value := (curTid >= 1 && curTid <= names.Length) ? curTid : 1

    dlg.Add("Text", "xm y+10", "条件：")
    lvC := dlg.Add("ListView", "xm w760 r7 +Grid", ["类型", "引用", "操作", "使用引用坐标", "X", "Y"])
    btnCAdd := dlg.Add("Button", "xm w90", "新增条件")
    btnCEdit := dlg.Add("Button", "x+8 w90", "编辑条件")
    btnCDel := dlg.Add("Button", "x+8 w90", "删除条件")

    dlg.Add("Text", "xm y+10", "动作（释放技能步骤）：")
    lvA := dlg.Add("ListView", "xm w760 r6 +Grid", ["序", "技能名", "延时(ms)", "按住(ms)", "需就绪", "验证", "重试"])
    btnAAdd := dlg.Add("Button", "xm w110", "新增动作")
    btnAEdit := dlg.Add("Button", "x+8  w110", "编辑动作")
    btnADel := dlg.Add("Button", "x+8  w110", "删除动作")
    btnAUp := dlg.Add("Button", "x+20 w90", "上移")
    btnADn := dlg.Add("Button", "x+8  w90", "下移")

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    RefreshC()
    RefreshA()

    btnCAdd.OnEvent("Click", (*) => CondAdd())
    btnCEdit.OnEvent("Click", (*) => CondEditSel())
    btnCDel.OnEvent("Click", (*) => CondDelSel())

    btnAAdd.OnEvent("Click", (*) => ActAdd())
    btnAEdit.OnEvent("Click", (*) => ActEditSel())
    btnADel.OnEvent("Click", (*) => ActDelSel())
    btnAUp.OnEvent("Click", (*) => ActMove(-1))
    btnADn.OnEvent("Click", (*) => ActMove(1))

    btnSave.OnEvent("Click", (*) => SaveRule())
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    lvC.OnEvent("DoubleClick", (*) => CondEditSel())
    lvA.OnEvent("DoubleClick", (*) => ActEditSel())

    dlg.Show()

    RefreshC() {
        try {
            lvC.Opt("-Redraw")
            lvC.Delete()
        } catch {
        }
        try {
            for _, c in rule.Conditions {
                if (HasProp(c, "Kind") && StrUpper(c.Kind) = "COUNTER") {
                    si := HasProp(c, "SkillIndex") ? c.SkillIndex : 1
                    sName := ""
                    try {
                        if (si >= 1 && si <= App["ProfileData"].Skills.Length) {
                            sName := App["ProfileData"].Skills[si].Name
                        } else {
                            sName := "技能#" si
                        }
                    } catch {
                        sName := "技能#" si
                    }
                    cmpText := CmpToText(HasProp(c, "Cmp") ? c.Cmp : "GE")
                    curCnt := 0
                    try {
                        curCnt := Counters_Get(si)
                    } catch {
                        curCnt := 0
                    }
                    lvC.Add("", "计数", sName, cmpText, "-", HasProp(c, "Value") ? c.Value : 1, curCnt)
                } else {
                    refType := HasProp(c, "RefType") ? c.RefType : "Skill"
                    refIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                    opText := (StrUpper(HasProp(c, "Op") ? c.Op : "EQ") = "EQ") ? "等于" : "不等于"
                    refName := ""
                    if (StrUpper(refType) = "SKILL") {
                        try {
                            refName := (refIdx <= App["ProfileData"].Skills.Length) ? App["ProfileData"].Skills[refIdx]
                                .Name : ("技能#" refIdx)
                        } catch {
                            refName := "技能#" refIdx
                        }
                    } else {
                        try {
                            refName := (refIdx <= App["ProfileData"].Points.Length) ? App["ProfileData"].Points[refIdx]
                                .Name : ("点位#" refIdx)
                        } catch {
                            refName := "点位#" refIdx
                        }
                    }
                    lvC.Add("", refType, refName, opText, (HasProp(c, "UseRefXY") && c.UseRefXY ? "是" : "否"), HasProp(c,
                        "X") ? c.X : 0, HasProp(c, "Y") ? c.Y : 0)
                }
            }
            loop 7 {
                try {
                    lvC.ModifyCol(A_Index, "AutoHdr")
                } catch {
                }
            }
        } catch {
        } finally {
            try {
                lvC.Opt("+Redraw")
            } catch {
            }
        }
    }

    CmpToText(cmp) {
        k := StrUpper(cmp)
        if (k = "GE") {
            return ">="
        }
        if (k = "EQ") {
            return "=="
        }
        if (k = "GT") {
            return ">"
        }
        if (k = "LE") {
            return "<="
        }
        if (k = "LT") {
            return "<"
        }
        return ">="
    }

    RefreshA() {
        try {
            lvA.Opt("-Redraw")
            lvA.Delete()
        } catch {
        }
        try {
            for i, a in rule.Actions {
                sName := ""
                try {
                    sName := (a.SkillIndex <= App["ProfileData"].Skills.Length)
                        ? App["ProfileData"].Skills[a.SkillIndex].Name
                        : ("技能#" a.SkillIndex)
                } catch {
                    sName := "技能#" a.SkillIndex
                }
                lvA.Add("", i, sName
                    , (HasProp(a, "DelayMs") ? a.DelayMs : 0)
                    , (HasProp(a, "HoldMs") ? a.HoldMs : -1)
                    , ((HasProp(a, "RequireReady") && a.RequireReady) ? "√" : ""))
            }
            loop 5 {
                try {
                    lvA.ModifyCol(A_Index, "AutoHdr")
                } catch {
                }
            }
        } catch {
        } finally {
            try {
                lvA.Opt("+Redraw")
            } catch {
            }
        }
    }

    CondAdd() {
        CondEditor_Open({}, 0, OnCondSavedNew)
    }

    OnCondSavedNew(nc, i) {
        rule.Conditions.Push(nc)
        RefreshC()
    }

    CondEditSel() {
        row := 0
        try {
            row := lvC.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个条件"
            return
        }
        c := rule.Conditions[row]
        CondEditor_Open(c, row, OnCondSavedEdit)
    }

    OnCondSavedEdit(nc, idx2) {
        rule.Conditions[idx2] := nc
        RefreshC()
    }

    CondDelSel() {
        row := 0
        try {
            row := lvC.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个条件"
            return
        }
        rule.Conditions.RemoveAt(row)
        RefreshC()
    }

    ActAdd() {
        ActEditor_Open({}, 0, OnActSavedNew)
    }

    OnActSavedNew(na, i) {
        rule.Actions.Push(na)
        RefreshA()
    }

    ActEditSel() {
        row := 0
        try {
            row := lvA.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个动作"
            return
        }
        a := rule.Actions[row]
        ActEditor_Open(a, row, OnActSavedEdit)
    }

    OnActSavedEdit(na, idx2) {
        rule.Actions[idx2] := na
        RefreshA()
    }

    ActDelSel() {
        row := 0
        try {
            row := lvA.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个动作"
            return
        }
        rule.Actions.RemoveAt(row)
        RefreshA()
    }

    ActMove(dir) {
        row := 0
        try {
            row := lvA.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        from := row
        to := from + dir
        if (to < 1 || to > rule.Actions.Length) {
            return
        }
        item := rule.Actions[from]
        rule.Actions.RemoveAt(from)
        rule.Actions.InsertAt(to, item)
        RefreshA()
        try {
            lvA.Modify(to, "Select Focus Vis")
        } catch {
        }
    }

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    btnSave.OnEvent("Click", (*) => SaveRule())
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    SaveRule() {
        name := ""
        try {
            name := Trim(tbName.Value)
        } catch {
            name := ""
        }
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        try {
            rule.Name := name
        } catch {
        }
        try {
            rule.Enabled := cbEn.Value ? 1 : 0
        } catch {
        }
        try {
            rule.Logic := (ddLogic.Value = 2) ? "OR" : "AND"
        } catch {
        }
        try {
            rule.CooldownMs := (edCd.Value != "") ? Integer(edCd.Value) : 500
        } catch {
        }
        try {
            rule.Priority := (edPrio.Value != "") ? Integer(edPrio.Value) : 1
        } catch {
        }
        try {
            rule.ActionGapMs := (edGap.Value != "") ? Integer(edGap.Value) : 60
        } catch {
        }
        try {
            rule.ThreadId := ddThread.Value ? ddThread.Value : 1
        } catch {
        }
        try {
            rule.SessionTimeoutMs := (edSessTO.Value != "") ? Integer(edSessTO.Value) : 0
        } catch {
        }
        try {
            rule.AbortCooldownMs := (edAbortCd.Value != "") ? Integer(edAbortCd.Value) : 0
        } catch {
        }

        if onSaved {
            onSaved(rule, idx)
        }
        try {
            dlg.Destroy()
        } catch {
        }
        Notify(isNew ? "已新增规则" : "已保存规则")
    }
}

; 条件编辑器（支持 Pixel / Counter）
CondEditor_Open(cond, idx := 0, onSaved := 0) {
    global App

    ; 缺省视为 Pixel
    if !HasProp(cond, "Kind")
        cond.Kind := "Pixel"

    ; Pixel 缺省字段
    if (StrUpper(cond.Kind) = "PIXEL") {
        defaultsP := Map("RefType", "Skill", "RefIndex", 1, "Op", "EQ", "UseRefXY", 1, "X", 0, "Y", 0)
        for k, v in defaultsP
            if !HasProp(cond, k)
                cond.%k% := v
    } else {
        ; Counter 缺省字段
        defaultsC := Map("SkillIndex", 1, "Cmp", "GE", "Value", 1, "ResetOnTrigger", 0)
        for k, v in defaultsC
            if !HasProp(cond, k)
                cond.%k% := v
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, "编辑条件")
    dlg.MarginX := 12, dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    ; 条件类型
    dlg.Add("Text", "w90 Right", "条件类型：")
    ddKind := dlg.Add("DropDownList", "x+6 w160", ["像素(Pixel)", "计数(Counter)"])
    ddKind.Value := (StrUpper(cond.Kind) = "COUNTER") ? 2 : 1

    ; ---------- Pixel 区 ----------
    txtType := dlg.Add("Text", "xm y+10 w90 Right", "引用类型：")
    ddType := dlg.Add("DropDownList", "x+6 w160", ["Skill", "Point"])
    ddType.Value := (StrUpper(HasProp(cond, "RefType") ? cond.RefType : "Skill") = "POINT") ? 2 : 1

    txtObj := dlg.Add("Text", "xm w90 Right", "引用对象：")
    ddObj := dlg.Add("DropDownList", "x+6 w160")

    txtOp := dlg.Add("Text", "xm w90 Right", "操作：")
    ddOp := dlg.Add("DropDownList", "x+6 w160", ["等于", "不等于"])
    ddOp.Value := (StrUpper(HasProp(cond, "Op") ? cond.Op : "EQ") = "NEQ") ? 2 : 1

    txtInfo := dlg.Add("Text", "xm y+10 w90 Right", "对象详情：")
    labX := dlg.Add("Text", "xm w48 Right", "X:")
    edRefX := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labY := dlg.Add("Text", "x+18 w48 Right", "Y:")
    edRefY := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labC := dlg.Add("Text", "x+18 w48 Right", "颜色:")
    edRefCol := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labT := dlg.Add("Text", "x+18 w48 Right", "容差:")
    edRefTol := dlg.Add("Edit", "x+6 w100 ReadOnly Center")

    grpPixel := [txtType, ddType, txtObj, ddObj, txtOp, ddOp, txtInfo, labX, edRefX, labY, edRefY, labC, edRefCol, labT,
        edRefTol]

    ; ---------- Counter 区 ----------
    txtCntSkill := dlg.Add("Text", "xm y+10 w90 Right", "计数技能：")
    ddCntSkill := dlg.Add("DropDownList", "x+6 w240")
    names := []
    for _, s in App["ProfileData"].Skills
        names.Push(s.Name)
    if names.Length
        ddCntSkill.Add(names)
    ddCntSkill.Value := Min(Max(HasProp(cond, "SkillIndex") ? cond.SkillIndex : 1, 1), Max(names.Length, 1))

    txtCmp := dlg.Add("Text", "xm w90 Right", "比较：")
    ddCmp := dlg.Add("DropDownList", "x+6 w120", [">=", "==", ">", "<=", "<"])
    cmpMapT2K := Map(">=", "GE", "==", "EQ", ">", "GT", "<=", "LE", "<", "LT")
    cmpMapK2T := Map("GE", ">=", "EQ", "==", "GT", ">", "LE", "<=", "LT", "<")
    defCmp := StrUpper(HasProp(cond, "Cmp") ? cond.Cmp : "GE")
    ddCmp.Value := (defCmp = "GE") ? 1 : (defCmp = "EQ") ? 2 : (defCmp = "GT") ? 3 : (defCmp = "LE") ? 4 : (defCmp =
        "LT") ? 5 : 1

    txtVal := dlg.Add("Text", "xm w90 Right", "阈值：")
    edVal := dlg.Add("Edit", "x+6 w120 Number", HasProp(cond, "Value") ? cond.Value : 1)

    cbReset := dlg.Add("CheckBox", "xm y+8", "触发后清零")
    cbReset.Value := HasProp(cond, "ResetOnTrigger") ? (cond.ResetOnTrigger ? 1 : 0) : 0

    grpCounter := [txtCntSkill, ddCntSkill, txtCmp, ddCmp, txtVal, edVal, cbReset]

    ; 计算一组控件的左上角
    Group_GetTopLeft(grp, &minX, &minY) {
        first := true
        for ctl in grp {
            ctl.GetPos(&x, &y)
            if (first) {
                minX := x, minY := y
                first := false
            } else {
                if (x < minX)
                    minX := x
                if (y < minY)
                    minY := y
            }
        }
    }

    ; 将一组控件整体平移
    Group_Offset(grp, dx, dy) {
        for ctl in grp {
            ctl.GetPos(&x, &y, &w, &h)
            ctl.Move(x + dx, y + dy, w, h)
        }
    }

    ; 计算一组控件的整体边界
    Group_GetBounds(grp, &minX, &minY, &maxX, &maxY) {
        first := true
        for ctl in grp {
            ctl.GetPos(&x, &y, &w, &h)
            if (first) {
                minX := x, minY := y, maxX := x + w, maxY := y + h
                first := false
            } else {
                if (x < minX)
                    minX := x
                if (y < minY)
                    minY := y
                if (x + w > maxX)
                    maxX := x + w
                if (y + h > maxY)
                    maxY := y + h
            }
        }
    }
    ; 底部按钮
    btnSave := dlg.Add("Button", "xm y+12 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    ; 事件
    ddType.OnEvent("Change", (*) => (FillObj(), UpdateInfo()))
    ddObj.OnEvent("Change", (*) => UpdateInfo())
    ddKind.OnEvent("Change", ToggleKind)
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    ; 初始化
    FillObj()
    UpdateInfo()
    ToggleKind(0)
    ; 两组对齐到同一块区域（计数组对齐到像素组）
    Group_GetTopLeft(grpPixel, &px, &py)
    Group_GetTopLeft(grpCounter, &cx, &cy)
    Group_Offset(grpCounter, px - cx, py - cy)

    ; 按当前可见组重新放置保存/取消，并让窗口按内容自适应高度
    PlaceButtons() {
        isCounter := (ddKind.Value = 2)
        minX := 0, minY := 0, maxX := 0, maxY := 0
        if (isCounter) {
            Group_GetBounds(grpCounter, &minX, &minY, &maxX, &maxY)
        } else {
            Group_GetBounds(grpPixel, &minX, &minY, &maxX, &maxY)
        }
        btnY := maxY + 12
        btnSave.GetPos(&sx, &sy, &sw, &sh)
        btnCancel.GetPos(&cx, &cy, &cw, &ch)
        btnSave.Move(, btnY)         ; 只改 Y
        btnCancel.Move(, btnY)
        ; 让对话框按可见内容自适应高度
        try dlg.Show("AutoSize")
    }

    ; 初次布局
    PlaceButtons()

    dlg.Show()

    ToggleKind(*) {
        isCounter := (ddKind.Value = 2)
        for _, ctl in grpPixel
            ctl.Visible := !isCounter
        for _, ctl in grpCounter
            ctl.Visible := isCounter
        PlaceButtons()   ; 切换后重排按钮并收缩窗口
    }

    FillObj() {
        ddObj.Delete()
        if (ddType.Value = 2) {
            names := []
            for _, p in App["ProfileData"].Points
                names.Push(p.Name)
            if names.Length
                ddObj.Add(names)
            ; 旧 cond.RefIndex 用于 Pixel
            defIdx := HasProp(cond, "RefIndex") ? cond.RefIndex : 1
            ddObj.Value := names.Length ? Min(Max(defIdx, 1), names.Length) : 0
        } else {
            names := []
            for _, s in App["ProfileData"].Skills
                names.Push(s.Name)
            if names.Length
                ddObj.Add(names)
            defIdx := HasProp(cond, "RefIndex") ? cond.RefIndex : 1
            ddObj.Value := names.Length ? Min(Max(defIdx, 1), names.Length) : 0
        }
    }

    UpdateInfo() {
        if (ddType.Value = 2) { ; Point
            idxSel := ddObj.Value
            if (idxSel >= 1 && idxSel <= App["ProfileData"].Points.Length) {
                p := App["ProfileData"].Points[idxSel]
                edRefX.Value := p.X
                edRefY.Value := p.Y
                edRefCol.Value := Pixel_ColorToHex(Pixel_HexToInt(p.Color))
                edRefTol.Value := p.Tol
            } else {
                edRefX.Value := 0, edRefY.Value := 0, edRefCol.Value := "0x000000", edRefTol.Value := 10
            }
        } else { ; Skill
            idxSel := ddObj.Value
            if (idxSel >= 1 && idxSel <= App["ProfileData"].Skills.Length) {
                s := App["ProfileData"].Skills[idxSel]
                edRefX.Value := s.X
                edRefY.Value := s.Y
                edRefCol.Value := Pixel_ColorToHex(Pixel_HexToInt(s.Color))
                edRefTol.Value := s.Tol
            } else {
                edRefX.Value := 0, edRefY.Value := 0, edRefCol.Value := "0x000000", edRefTol.Value := 10
            }
        }
    }

    OnSave(*) {
        if (ddKind.Value = 2) {
            ; 保存 Counter 条件
            if (App["ProfileData"].Skills.Length = 0) {
                MsgBox "没有可引用的技能"
                return
            }
            si := ddCntSkill.Value ? ddCntSkill.Value : 1
            cmpKey := cmpMapT2K[ddCmp.Text]
            val := (edVal.Value != "") ? Integer(edVal.Value) : 1
            rst := cbReset.Value ? 1 : 0
            newC := { Kind: "Counter", SkillIndex: si, Cmp: cmpKey, Value: val, ResetOnTrigger: rst }
            if onSaved
                onSaved(newC, idx)
            dlg.Destroy()
            Notify("已保存计数条件")
            return
        }

        ; 保存 Pixel 条件
        refType := (ddType.Value = 2) ? "Point" : "Skill"
        if (refType = "Point" && App["ProfileData"].Points.Length = 0) {
            MsgBox "没有可引用的取色点位"
            return
        }
        if (refType = "Skill" && App["ProfileData"].Skills.Length = 0) {
            MsgBox "没有可引用的技能"
            return
        }
        refIdx := ddObj.Value ? ddObj.Value : 1
        op := (ddOp.Value = 2) ? "NEQ" : "EQ"
        x := Integer(edRefX.Value)
        y := Integer(edRefY.Value)
        newC := { Kind: "Pixel", RefType: refType, RefIndex: refIdx, Op: op, UseRefXY: 1, X: x, Y: y }
        if onSaved
            onSaved(newC, idx)
        dlg.Destroy()
        Notify("已保存条件")
    }
}

; 动作编辑器
ActEditor_Open(act, idx := 0, onSaved := 0) {
    global App
    defaults := Map("SkillIndex", 1, "DelayMs", 0)
    for k, v in defaults
        if !HasProp(act, k)
            act.%k% := v

    dlg := Gui("+Owner" UI.Main.Hwnd, "编辑动作")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    dlg.Add("Text", "w90 Right", "技能：")
    names := []
    for _, s in App["ProfileData"].Skills
        names.Push(s.Name)
    ddS := dlg.Add("DropDownList", "x+6 w240")
    if names.Length
        ddS.Add(names)
    ddS.Value := Min(Max(act.SkillIndex, 1), Max(names.Length, 1))

    dlg.Add("Text", "xm w90 Right", "延时(ms)：")
    edD := dlg.Add("Edit", "x+6 w240 Number", act.DelayMs)

    dlg.Add("Text", "xm w90 Right", "按住(ms)：")
    edHold := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "HoldMs") ? act.HoldMs : -1)

    cbReady := dlg.Add("CheckBox", "xm y+8", "需就绪")
    cbReady.Value := HasProp(act, "RequireReady") ? (act.RequireReady ? 1 : 0) : 0

    cbVerify := dlg.Add("CheckBox", "xm y+8", "验证")
    cbVerify.Value := HasProp(act, "Verify") ? (act.Verify ? 1 : 0) : 0

    dlg.Add("Text", "xm w110 Right", "验证超时(ms)：")
    edVto := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "VerifyTimeoutMs") ? act.VerifyTimeoutMs : 600)

    dlg.Add("Text", "xm w110 Right", "重试次数：")
    edRetry := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "Retry") ? act.Retry : 0)

    dlg.Add("Text", "xm w110 Right", "重试间隔(ms)：")
    edRgap := dlg.Add("Edit", "x+6 w120 Number", HasProp(act, "RetryGapMs") ? act.RetryGapMs : 150)

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()

    OnSave(*) {
        idxS := ddS.Value ? ddS.Value : 1
        d := (edD.Value != "") ? Integer(edD.Value) : 0
        h := (edHold.Value != "") ? Integer(edHold.Value) : -1
        rr := cbReady.Value ? 1 : 0
        vf := cbVerify.Value ? 1 : 0
        vto := (edVto.Value != "") ? Integer(edVto.Value) : 600
        rt := (edRetry.Value != "") ? Integer(edRetry.Value) : 0
        rg := (edRgap.Value != "") ? Integer(edRgap.Value) : 150
        newA := { SkillIndex: idxS, DelayMs: d, HoldMs: h, RequireReady: rr, Verify: vf, VerifyTimeoutMs: vto, Retry: rt,
            RetryGapMs: rg }
        if onSaved
            onSaved(newA, idx)
        dlg.Destroy()
        Notify("已保存动作")
    }
}
