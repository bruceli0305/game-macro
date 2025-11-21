#Requires AutoHotkey v2
; Rules_Editor_Lists.ahk
; 条件/动作 列表逻辑与事件
; 导出：
;   RE_Lists_Init(ctx)
;   RE_Cond_Refresh(ctx), RE_Act_Refresh(ctx)
;   RE_Cond_Add/Edit/Del(ctx)
;   RE_Act_Add/Edit/Del/Move(ctx, dir)

#Include "Rules_UI_Common.ahk"
#Include "CondEditor_Dialog.ahk"
#Include "ActEditor_Dialog.ahk"

RE_Lists_Init(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    ctrls := ctx.ctrls

    ; 绑定事件（统一使用方括号访问 Map/Object）
    try {
        ctrls["btnCAdd"].OnEvent("Click", (*) => RE_Cond_Add(ctx))
        ctrls["btnCEdit"].OnEvent("Click", (*) => RE_Cond_Edit(ctx))
        ctrls["btnCDel"].OnEvent("Click", (*) => RE_Cond_Del(ctx))
        ctrls["lvC"].OnEvent("DoubleClick", (*) => RE_Cond_Edit(ctx))

        ctrls["btnAAdd"].OnEvent("Click", (*) => RE_Act_Add(ctx))
        ctrls["btnAEdit"].OnEvent("Click", (*) => RE_Act_Edit(ctx))
        ctrls["btnADel"].OnEvent("Click", (*) => RE_Act_Del(ctx))
        ctrls["btnAUp"].OnEvent("Click", (*) => RE_Act_Move(ctx, -1))
        ctrls["btnADn"].OnEvent("Click", (*) => RE_Act_Move(ctx, 1))
        ctrls["lvA"].OnEvent("DoubleClick", (*) => RE_Act_Edit(ctx))
    } catch {
    }

    RE_Cond_Refresh(ctx)
    RE_Act_Refresh(ctx)
}

; ========== 条件列表 ==========
RE_Cond_Refresh(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    lv := ctx.ctrls["lvC"]
    rule := ctx.rule

    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }

    try {
        if (HasProp(rule, "Conditions") && IsObject(rule.Conditions)) {
            for _, c in rule.Conditions {
                isCounter := false
                kind := "Pixel"
                try {
                    kind := OM_Get(c, "Kind", "Pixel")
                    isCounter := (StrUpper(kind) = "COUNTER")
                } catch {
                    isCounter := false
                }

                if (isCounter) {
                    si := 1
                    try si := OM_Get(c, "SkillIndex", 1)
                    sName := RE_Rules_SkillNameByIndex(si)
                    cmpText := RE_Cmp_KeyToText(OM_Get(c, "Cmp", "GE"))
                    val := 1
                    try val := OM_Get(c, "Value", 1)
                    curCnt := 0
                    try curCnt := Counters_Get(si)
                    try lv.Add("", "计数", sName, cmpText, "-", val, curCnt)
                } else {
                    rt := OM_Get(c, "RefType", "Skill")
                    ri := OM_Get(c, "RefIndex", 1)
                    opText := "等于"
                    try opText := (StrUpper(OM_Get(c, "Op", "EQ")) = "NEQ") ? "不等于" : "等于"
                    refName := (StrUpper(rt) = "SKILL") ? RE_Rules_SkillNameByIndex(ri) : RE_Rules_PointNameByIndex(ri)
                    useXY := 1
                    try useXY := OM_Get(c, "UseRefXY", 1) ? 1 : 0
                    xx := 0, yy := 0
                    try xx := OM_Get(c, "X", 0)
                    try yy := OM_Get(c, "Y", 0)
                    try lv.Add("", rt, refName, opText, (useXY ? "是" : "否"), xx, yy)
                }
            }
            ; 条件列表列数为 6
            RE_LV_AutoHdr(lv, 6)
        }
    } catch {
    } finally {
        try lv.Opt("+Redraw")
    }
}

RE_Cond_Add(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    CondEditor_Open({}, 0, OnSavedNew)
    OnSavedNew(nc, i) {
        try {
            if (!HasProp(ctx.rule, "Conditions") || !IsObject(ctx.rule.Conditions)) {
                ctx.rule.Conditions := []
            }
            ctx.rule.Conditions.Push(nc)
        } catch {
        }
        RE_Cond_Refresh(ctx)
    }
}

RE_Cond_Edit(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    row := 0
    try row := ctx.ctrls["lvC"].GetNext(0, "Focused")
    if (row = 0) {
        MsgBox "请选择一个条件"
        return
    }
    c := ctx.rule.Conditions[row]
    CondEditor_Open(c, row, OnSavedEdit)
    OnSavedEdit(nc, idx2) {
        try ctx.rule.Conditions[idx2] := nc
        RE_Cond_Refresh(ctx)
    }
}

RE_Cond_Del(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    row := 0
    try row := ctx.ctrls["lvC"].GetNext(0, "Focused")
    if (row = 0) {
        MsgBox "请选择一个条件"
        return
    }
    try ctx.rule.Conditions.RemoveAt(row)
    RE_Cond_Refresh(ctx)
}

; ========== 动作列表 ==========
RE_Act_Refresh(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    lv := ctx.ctrls["lvA"]
    rule := ctx.rule

    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }

    try {
        if (HasProp(rule, "Actions") && IsObject(rule.Actions)) {
            i := 1
            for a in rule.Actions {
                si := 1
                try si := OM_Get(a, "SkillIndex", 1)
                sName := RE_Rules_SkillNameByIndex(si)

                d := 0, h := -1, rr := 0, vf := 0, rt := 0
                try d := OM_Get(a, "DelayMs", 0)
                try h := OM_Get(a, "HoldMs", -1)
                try rr := OM_Get(a, "RequireReady", 0) ? 1 : 0
                try vf := OM_Get(a, "Verify", 0) ? 1 : 0
                try rt := OM_Get(a, "Retry", 0)

                try lv.Add("", i, sName, d, h, (rr ? "√" : ""), (vf ? "√" : ""), rt)
                i := i + 1
            }
            RE_LV_AutoHdr(lv, 7)
        }
    } catch {
    } finally {
        try lv.Opt("+Redraw")
    }
}

RE_Act_Add(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    ActEditor_Open({}, 0, OnSavedNew)
    OnSavedNew(na, i) {
        try {
            if (!HasProp(ctx.rule, "Actions") || !IsObject(ctx.rule.Actions)) {
                ctx.rule.Actions := []
            }
            ctx.rule.Actions.Push(na)
        } catch {
        }
        RE_Act_Refresh(ctx)
    }
}

RE_Act_Edit(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    row := 0
    try row := ctx.ctrls["lvA"].GetNext(0, "Focused")
    if (row = 0) {
        MsgBox "请选择一个动作"
        return
    }
    a := ctx.rule.Actions[row]
    ActEditor_Open(a, row, OnSavedEdit)
    OnSavedEdit(na, idx2) {
        try ctx.rule.Actions[idx2] := na
        RE_Act_Refresh(ctx)
    }
}

RE_Act_Del(ctx) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    row := 0
    try row := ctx.ctrls["lvA"].GetNext(0, "Focused")
    if (row = 0) {
        MsgBox "请选择一个动作"
        return
    }
    try ctx.rule.Actions.RemoveAt(row)
    RE_Act_Refresh(ctx)
}

RE_Act_Move(ctx, dir) {
    if (!IsObject(ctx)) {
        return
    }
    if (!HasProp(ctx, "rule")) {
        return
    }
    if (!HasProp(ctx, "ctrls")) {
        return
    }

    row := 0
    try row := ctx.ctrls["lvA"].GetNext(0, "Focused")
    if (row = 0) {
        return
    }
    from := row
    to := from + dir

    len := 0
    try len := ctx.rule.Actions.Length
    if (to < 1) {
        return
    }
    if (to > len) {
        return
    }

    item := ctx.rule.Actions[from]
    try {
        ctx.rule.Actions.RemoveAt(from)
        ctx.rule.Actions.InsertAt(to, item)
    } catch {
    }
    RE_Act_Refresh(ctx)
    try ctx.ctrls["lvA"].Modify(to, "Select Focus Vis")
}