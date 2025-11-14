; GUI_RuleEditor.ahk - 技能循环规则管理与编辑（支持“计数条件”）
; v2 安全风格：无单行大括号 if、显式连接、避免隐式拼接

; 打开规则管理器
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
    btnUp  := dlg.Add("Button", "x+8 w90", "上移")
    btnDn  := dlg.Add("Button", "x+8 w90", "下移")
    btnSave:= dlg.Add("Button", "x+20 w100", "保存")

    RefreshLV()

    lv.OnEvent("DoubleClick", (*) => EditSel())
    btnAdd.OnEvent("Click", (*) => AddRule())
    btnEdit.OnEvent("Click", (*) => EditSel())
    btnDel.OnEvent("Click", (*) => DelSel())
    btnUp.OnEvent("Click",  (*) => MoveSel(-1))
    btnDn.OnEvent("Click",  (*) => MoveSel(1))
    btnSave.OnEvent("Click",(*) => SaveAll())
    dlg.OnEvent("Close", (*) => dlg.Destroy())

    dlg.Show()

    RefreshLV() {
        lv.Opt("-Redraw")
        lv.Delete()
        for i, r in prof.Rules {
            tname := ThreadNameById(HasProp(r, "ThreadId") ? r.ThreadId : 1)
            lv.Add("", i
                , (r.Enabled ? "√" : "")
                , r.Name, r.Logic
                , r.Conditions.Length, r.Actions.Length
                , r.CooldownMs, r.Priority, r.ActionGapMs
                , tname)
        }
        loop 10
            lv.ModifyCol(A_Index, "AutoHdr")
        lv.Opt("+Redraw")
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

    AddRule() {
        newR := {
            Name: "新规则", Enabled: 1, Logic: "AND", CooldownMs: 500
          , Priority: prof.Rules.Length + 1, ActionGapMs: 60
          , Conditions: [], Actions: [], LastFire: 0, ThreadId: 1
        }
        RuleEditor_Open(newR, 0, OnSavedNew)
    }

    OnSavedNew(savedR, idx) {
        global App
        App["ProfileData"].Rules.Push(savedR)
        RefreshLV()
    }

    EditSel() {
        row := lv.GetNext(0, "Focused")
        if !row {
            MsgBox "请先选中一个规则。"
            return
        }
        idx := row
        cur := prof.Rules[idx]
        RuleEditor_Open(cur, idx, OnSavedEdit)
    }

    OnSavedEdit(savedR, idx2) {
        global App
        App["ProfileData"].Rules[idx2] := savedR
        RefreshLV()
    }

    DelSel() {
        row := lv.GetNext(0, "Focused")
        if !row {
            MsgBox "请先选中一个规则。"
            return
        }
        idx := row
        prof.Rules.RemoveAt(idx)
        for i, r in prof.Rules
            r.Priority := i
        RefreshLV()
        Notify("已删除规则")
    }

    MoveSel(dir) {
        row := lv.GetNext(0, "Focused")
        if !row
            return
        from := row, to := from + dir
        if (to < 1 || to > prof.Rules.Length)
            return
        item := prof.Rules[from]
        prof.Rules.RemoveAt(from)
        prof.Rules.InsertAt(to, item)
        for i, r in prof.Rules
            r.Priority := i
        RefreshLV()
        lv.Modify(to, "Select Focus Vis")
    }

    SaveAll() {
        Storage_SaveProfile(prof)
        Notify("循环配置已保存")
    }
}

; 规则编辑器
RuleEditor_Open(rule, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)

    defaults := Map("Name","新规则","Enabled",1,"Logic","AND","CooldownMs",500,"Priority",1,"ActionGapMs",60,"ThreadId",1)
    for k, v in defaults
        if !HasProp(rule, k)
            rule.%k% := v
    if !HasProp(rule, "Conditions")
        rule.Conditions := []
    if !HasProp(rule, "Actions")
        rule.Actions := []

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

    dlg.Add("Text", "x+20 w90 Right", "线程：")
    ddThread := dlg.Add("DropDownList", "x+6 w160")
    names := []
    for _, t in App["ProfileData"].Threads
        names.Push(t.Name)
    if names.Length
        ddThread.Add(names)
    curTid := HasProp(rule, "ThreadId") ? rule.ThreadId : 1
    ddThread.Value := (curTid >= 1 && curTid <= names.Length) ? curTid : 1

    ; 条件
    dlg.Add("Text", "xm y+10", "条件：")
    ; 保持旧列名：类型/引用/操作/使用引用坐标/X/Y
    ; 对 Counter：X=阈值、Y=当前计数
    lvC := dlg.Add("ListView", "xm w760 r7 +Grid", ["类型", "引用", "操作", "使用引用坐标", "X", "Y"])
    btnCAdd := dlg.Add("Button", "xm w90", "新增条件")
    btnCEdit:= dlg.Add("Button", "x+8 w90", "编辑条件")
    btnCDel:= dlg.Add("Button", "x+8 w90", "删除条件")

    ; 动作
    dlg.Add("Text", "xm y+10", "动作（释放技能步骤）：")
    lvA := dlg.Add("ListView", "xm w760 r6 +Grid", ["序", "技能名", "延时(ms)"])
    btnAAdd := dlg.Add("Button", "xm w110", "新增动作")
    btnAEdit:= dlg.Add("Button", "x+8  w110", "编辑动作")
    btnADel := dlg.Add("Button", "x+8  w110", "删除动作")

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

    btnSave.OnEvent("Click", (*) => SaveRule())
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    lvC.OnEvent("DoubleClick", (*) => CondEditSel())
    lvA.OnEvent("DoubleClick", (*) => ActEditSel())

    dlg.Show()

    RefreshC() {
        lvC.Opt("-Redraw")
        lvC.Delete()
        for _, c in rule.Conditions {
            if (HasProp(c,"Kind") && StrUpper(c.Kind) = "COUNTER") {
                ; 计数条件展示
                si := HasProp(c,"SkillIndex") ? c.SkillIndex : 1
                sName := (si>=1 && si<=App["ProfileData"].Skills.Length)
                    ? App["ProfileData"].Skills[si].Name
                    : ("技能#" . si)
                cmpText := CmpToText(HasProp(c,"Cmp") ? c.Cmp : "GE")
                curCnt := Counters_Get(si)
                lvC.Add("", "计数", sName, cmpText, "-", c.Value, curCnt)
            } else {
                ; Pixel 条件展示（兼容旧数据无 Kind）
                refType := HasProp(c,"RefType") ? c.RefType : "Skill"
                refIdx  := HasProp(c,"RefIndex") ? c.RefIndex : 1
                opText  := (StrUpper(HasProp(c,"Op") ? c.Op : "EQ") = "EQ") ? "等于" : "不等于"
                refName := (StrUpper(refType) = "SKILL")
                    ? (refIdx <= App["ProfileData"].Skills.Length ? App["ProfileData"].Skills[refIdx].Name : ("技能#" . refIdx))
                    : (refIdx <= App["ProfileData"].Points.Length ? App["ProfileData"].Points[refIdx].Name : ("点位#" . refIdx))
                lvC.Add("", refType, refName, opText, (HasProp(c,"UseRefXY") && c.UseRefXY ? "是" : "否"), c.X, c.Y)
            }
        }
        loop 6
            lvC.ModifyCol(A_Index, "AutoHdr")
        lvC.Opt("+Redraw")
    }

    CmpToText(cmp) {
        switch StrUpper(cmp) {
            case "GE": return ">="
            case "EQ": return "=="
            case "GT": return ">"
            case "LE": return "<="
            case "LT": return "<"
            default:   return ">="
        }
    }

    RefreshA() {
        lvA.Opt("-Redraw")
        lvA.Delete()
        for i, a in rule.Actions {
            sName := (a.SkillIndex <= App["ProfileData"].Skills.Length)
                ? App["ProfileData"].Skills[a.SkillIndex].Name
                : ("技能#" . a.SkillIndex)
            lvA.Add("", i, sName, a.DelayMs)
        }
        loop 3
            lvA.ModifyCol(A_Index, "AutoHdr")
        lvA.Opt("+Redraw")
    }

    CondAdd() {
        CondEditor_Open({}, 0, OnCondSavedNew)
    }

    OnCondSavedNew(nc, i) {
        rule.Conditions.Push(nc)
        RefreshC()
    }

    CondEditSel() {
        row := lvC.GetNext(0, "Focused")
        if !row {
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
        row := lvC.GetNext(0, "Focused")
        if !row {
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
        row := lvA.GetNext(0, "Focused")
        if !row {
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
        row := lvA.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个动作"
            return
        }
        rule.Actions.RemoveAt(row)
        RefreshA()
    }

    SaveRule() {
        name := Trim(tbName.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        rule.Name := name
        rule.Enabled := cbEn.Value ? 1 : 0
        rule.Logic := (ddLogic.Value = 2) ? "OR" : "AND"
        rule.CooldownMs := (edCd.Value != "") ? Integer(edCd.Value) : 500
        rule.Priority := (edPrio.Value != "") ? Integer(edPrio.Value) : 1
        rule.ActionGapMs := (edGap.Value != "") ? Integer(edGap.Value) : 60
        rule.ThreadId := ddThread.Value ? ddThread.Value : 1
        if onSaved
            onSaved(rule, idx)
        dlg.Destroy()
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
        defaultsP := Map("RefType","Skill","RefIndex",1,"Op","EQ","UseRefXY",1,"X",0,"Y",0)
        for k, v in defaultsP
            if !HasProp(cond, k)
                cond.%k% := v
    } else {
        ; Counter 缺省字段
        defaultsC := Map("SkillIndex",1,"Cmp","GE","Value",1,"ResetOnTrigger",0)
        for k, v in defaultsC
            if !HasProp(cond, k)
                cond.%k% := v
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, "编辑条件")
    dlg.MarginX := 12, dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    ; 条件类型
    dlg.Add("Text", "w90 Right", "条件类型：")
    ddKind := dlg.Add("DropDownList", "x+6 w160", ["像素(Pixel)","计数(Counter)"])
    ddKind.Value := (StrUpper(cond.Kind) = "COUNTER") ? 2 : 1

    ; ---------- Pixel 区 ----------
    txtType := dlg.Add("Text", "xm y+10 w90 Right", "引用类型：")
    ddType  := dlg.Add("DropDownList", "x+6 w160", ["Skill", "Point"])
    ddType.Value := (StrUpper(HasProp(cond,"RefType") ? cond.RefType : "Skill") = "POINT") ? 2 : 1

    txtObj := dlg.Add("Text", "xm w90 Right", "引用对象：")
    ddObj  := dlg.Add("DropDownList", "x+6 w160")

    txtOp  := dlg.Add("Text", "xm w90 Right", "操作：")
    ddOp   := dlg.Add("DropDownList", "x+6 w160", ["等于", "不等于"])
    ddOp.Value := (StrUpper(HasProp(cond,"Op") ? cond.Op : "EQ") = "NEQ") ? 2 : 1

    txtInfo := dlg.Add("Text", "xm y+10 w90 Right", "对象详情：")
    labX    := dlg.Add("Text", "xm w48 Right", "X:")
    edRefX  := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labY    := dlg.Add("Text", "x+18 w48 Right", "Y:")
    edRefY  := dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labC    := dlg.Add("Text", "x+18 w48 Right", "颜色:")
    edRefCol:= dlg.Add("Edit", "x+6 w100 ReadOnly Center")
    labT    := dlg.Add("Text", "x+18 w48 Right", "容差:")
    edRefTol:= dlg.Add("Edit", "x+6 w100 ReadOnly Center")

    grpPixel := [txtType, ddType, txtObj, ddObj, txtOp, ddOp, txtInfo, labX, edRefX, labY, edRefY, labC, edRefCol, labT, edRefTol]

    ; ---------- Counter 区 ----------
    txtCntSkill := dlg.Add("Text", "xm y+10 w90 Right", "计数技能：")
    ddCntSkill  := dlg.Add("DropDownList", "x+6 w240")
    names := []
    for _, s in App["ProfileData"].Skills
        names.Push(s.Name)
    if names.Length
        ddCntSkill.Add(names)
    ddCntSkill.Value := Min(Max(HasProp(cond,"SkillIndex") ? cond.SkillIndex : 1, 1), Max(names.Length, 1))

    txtCmp := dlg.Add("Text", "xm w90 Right", "比较：")
    ddCmp  := dlg.Add("DropDownList", "x+6 w120", [">=","==",">","<=","<"])
    cmpMapT2K := Map(">=","GE","==","EQ",">","GT","<=","LE","<","LT")
    cmpMapK2T := Map("GE",">=","EQ","==","GT",">","LE","<=","LT","<")
    defCmp := StrUpper(HasProp(cond,"Cmp") ? cond.Cmp : "GE")
    ddCmp.Value := (defCmp="GE")?1:(defCmp="EQ")?2:(defCmp="GT")?3:(defCmp="LE")?4:(defCmp="LT")?5:1

    txtVal := dlg.Add("Text", "xm w90 Right", "阈值：")
    edVal  := dlg.Add("Edit", "x+6 w120 Number", HasProp(cond,"Value") ? cond.Value : 1)

    cbReset := dlg.Add("CheckBox", "xm y+8", "触发后清零")
    cbReset.Value := HasProp(cond,"ResetOnTrigger") ? (cond.ResetOnTrigger ? 1 : 0) : 0

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
    Group_GetTopLeft(grpPixel,  &px, &py)
    Group_GetTopLeft(grpCounter, &cx, &cy)
    Group_Offset(grpCounter, px - cx, py - cy)

    ; 按当前可见组重新放置保存/取消，并让窗口按内容自适应高度
    PlaceButtons() {
        isCounter := (ddKind.Value = 2)
        minX := 0, minY := 0, maxX := 0, maxY := 0
        if (isCounter) {
            Group_GetBounds(grpCounter, &minX, &minY, &maxX, &maxY)
        } else {
            Group_GetBounds(grpPixel,   &minX, &minY, &maxX, &maxY)
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
            newC := { Kind:"Counter", SkillIndex: si, Cmp: cmpKey, Value: val, ResetOnTrigger: rst }
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
        newC := { Kind:"Pixel", RefType: refType, RefIndex: refIdx, Op: op, UseRefXY: 1, X: x, Y: y }
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

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()

    OnSave(*) {
        idxS := ddS.Value ? ddS.Value : 1
        d := (edD.Value != "") ? Integer(edD.Value) : 0
        newA := { SkillIndex: idxS, DelayMs: d }
        if onSaved
            onSaved(newA, idx)
        dlg.Destroy()
        Notify("已保存动作")
    }
}