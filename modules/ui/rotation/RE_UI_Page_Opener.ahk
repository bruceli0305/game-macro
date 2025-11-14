; 替换文件：modules\ui\rotation\RE_UI_Page_Opener.ahk
; 说明：这是“起手”页的完整实现（监视列表 + Steps 列表与各自编辑器）
; 风格：无逗号链、无单行多语句（AHK v2 稳定）

#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

REUI_Page_Opener_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(4)
    REUI_Opener_Ensure(&cfg)

    ; 顶部：启用/最大时长/线程
    cbEnable := dlg.Add("CheckBox", "xm y+10 w160", "启用起手")
    cbEnable.Value := cfg.Opener.Enabled ? 1 : 0

    dlg.Add("Text","xm y+8 w110 Right","最大时长(ms)：")
    edMax := dlg.Add("Edit","x+6 w120 Number Center", cfg.Opener.MaxDurationMs)

    dlg.Add("Text","x+20 w80 Right","线程：")
    ddThr := dlg.Add("DropDownList","x+6 w200")
    thrNames := []
    thrIds := []
    try {
        for _, th in App["ProfileData"].Threads {
            thrNames.Push(th.Name)
            thrIds.Push(th.Id)
        }
    }
    if (thrNames.Length) {
        ddThr.Add(thrNames)
    }
    pos := 1
    curTid := HasProp(cfg.Opener,"ThreadId") ? cfg.Opener.ThreadId : 1
    for i, id in thrIds {
        if (id = curTid) {
            pos := i
            break
        }
    }
    ddThr.Value := pos

    ; 计算 Tab 页内容矩形（有 UI_TabPageRect 则用之，失败则用兜底宽度）
    rc := { X: 12, Y: 12, W: 820, H: 520 }
    try {
        r := UI_TabPageRect(tab)  ; 来自 UI_Layout.ahk
        if (IsObject(r)) {
            rc := r
        }
    }
    btnW := 84       ; 右侧按钮列宽
    gap := 8         ; 列表与按钮列间距
    minW := 560      ; 列表最小宽度，避免过窄
    listW := Max(minW, rc.W - btnW - gap - 20)  ; 预留右列空间

    ;================ 监视（Watch） ==================
    dlg.Add("Text","xm y+16","监视（技能计数/黑框确认）：")
    lvOW := dlg.Add("ListView", Format("xm y+6 w{} r7 +Grid", listW), ["技能","计数","黑框确认"])
    ; 右侧按钮列：按列表左上角绝对定位
    lvOW.GetPos(&lx, &ly, &lw, &lh)
    btnX := lx + lw + gap
    btnWAdd := dlg.Add("Button", Format("x{} y{} w{}", btnX, ly, btnW), "新增")
    btnWEdit:= dlg.Add("Button", Format("x{} y{} w{}", btnX, ly + 34, btnW), "编辑")
    btnWDel := dlg.Add("Button", Format("x{} y{} w{}", btnX, ly + 68, btnW), "删除")

    REUI_Opener_FillWatch(lvOW, cfg)
    btnWAdd.OnEvent("Click", (*) => REUI_Opener_WatchAdd(dlg, cfg, lvOW))
    btnWEdit.OnEvent("Click", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))
    btnWDel.OnEvent("Click", (*) => REUI_Opener_WatchDel(cfg, lvOW))
    lvOW.OnEvent("DoubleClick", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))

    ;================ Steps ==================
    ; 在监视列表下方，使用同样宽度与按钮列
    stepsLabelY := ly + lh + 16
    dlg.Add("Text", Format("x{} y{}", lx, stepsLabelY), "Steps（按序执行）：")
    lvS := dlg.Add("ListView", Format("x{} y{} w{} r8 +Grid", lx, stepsLabelY + 16, listW)
        , ["序","类型","详情","就绪","预延时","按住","验证","超时","时长"])

    lvS.GetPos(&sx, &sy, &sw, &sh)
    btnSAdd  := dlg.Add("Button", Format("x{} y{} w{}", btnX, sy, btnW), "新增")
    btnSEdit := dlg.Add("Button", Format("x{} y{} w{}", btnX, sy + 34, btnW), "编辑")
    btnSDel  := dlg.Add("Button", Format("x{} y{} w{}", btnX, sy + 68, btnW), "删除")
    btnSUp   := dlg.Add("Button", Format("x{} y{} w{}", btnX, sy + 102, btnW), "上移")
    btnSDn   := dlg.Add("Button", Format("x{} y{} w{}", btnX, sy + 136, btnW), "下移")

    REUI_Opener_FillSteps(lvS, cfg)
    btnSAdd.OnEvent("Click", (*) => REUI_Opener_StepAdd(dlg, cfg, lvS))
    btnSEdit.OnEvent("Click", (*) => REUI_Opener_StepEdit(dlg, cfg, lvS))
    btnSDel.OnEvent("Click", (*) => REUI_Opener_StepDel(cfg, lvS))
    btnSUp.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS, -1))
    btnSDn.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS, 1))
    lvS.OnEvent("DoubleClick", (*) => REUI_Opener_StepEdit(dlg, cfg, lvS))

    ; 底部保存按钮：显式放在 Steps 列表下方左侧
    btnSave := dlg.Add("Button", Format("x{} y{} w120", sx, sy + sh + 12), "保存起手")
    btnSave.OnEvent("Click", SaveOpener)  ; 保持你原来的保存函数

    SaveOpener(*) {
        cfg.Opener.Enabled := cbEnable.Value ? 1 : 0
        if (edMax.Value != "") {
            cfg.Opener.MaxDurationMs := Integer(edMax.Value)
        } else {
            cfg.Opener.MaxDurationMs := 4000
        }

        if (ddThr.Value>=1 && ddThr.Value<=thrIds.Length) {
            cfg.Opener.ThreadId := thrIds[ddThr.Value]
        } else {
            cfg.Opener.ThreadId := 1
        }

        cfg.Opener.StepsCount := (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) ? cfg.Opener.Steps.Length : 0
        Storage_SaveProfile(App["ProfileData"])
        Notify("起手已保存")
    }

    return { Save: () => (
        cfg.Opener.Enabled := cbEnable.Value ? 1 : 0
      , cfg.Opener.MaxDurationMs := (edMax.Value!="") ? Integer(edMax.Value) : 4000
      , cfg.Opener.ThreadId := (ddThr.Value>=1 && ddThr.Value<=thrIds.Length) ? thrIds[ddThr.Value] : 1
    ) }
}

REUI_Opener_Ensure(&cfg) {
    if !HasProp(cfg,"Opener") {
        cfg.Opener := {}
    }
    op := cfg.Opener
    if !HasProp(op,"Enabled") {
        op.Enabled := 0
    }
    if !HasProp(op,"MaxDurationMs") {
        op.MaxDurationMs := 4000
    }
    if !HasProp(op,"ThreadId") {
        op.ThreadId := 1
    }
    if !HasProp(op,"Watch") {
        op.Watch := []
    }
    if !HasProp(op,"StepsCount") {
        op.StepsCount := 0
    }
    if !HasProp(op,"Steps") {
        op.Steps := []
    }
    cfg.Opener := op
}

REUI_Opener_FillWatch(lv, cfg) {
    lv.Opt("-Redraw")
    lv.Delete()
    if (HasProp(cfg.Opener,"Watch") && IsObject(cfg.Opener.Watch)) {
        for _, w in cfg.Opener.Watch {
            sName := REUI_Opener_SkillName(HasProp(w,"SkillIndex")?w.SkillIndex:0)
            req := HasProp(w,"RequireCount") ? w.RequireCount : 1
            vb  := HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0
            lv.Add("", sName, req, vb)
        }
    }
    Loop 3 {
        lv.ModifyCol(A_Index,"AutoHdr")
    }
    lv.Opt("+Redraw")
}
REUI_Opener_SkillName(idx) {
    try {
        if (idx>=1 && idx<=App["ProfileData"].Skills.Length) {
            return App["ProfileData"].Skills[idx].Name
        }
    }
    return "技能#" idx
}
REUI_Opener_WatchAdd(owner, cfg, lv) {
    w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    REUI_Opener_WatchEditor_Open(owner, w, 0, OnSaved)
    OnSaved(nw, i) {
        cfg.Opener.Watch.Push(nw)
        REUI_Opener_FillWatch(lv, cfg)
    }
}
REUI_Opener_WatchEdit(owner, cfg, lv) {
    row := lv.GetNext(0,"Focused")
    if !row {
        MsgBox "请选择一条监视"
        return
    }
    w := cfg.Opener.Watch[row]
    REUI_Opener_WatchEditor_Open(owner, w, row, OnSaved)
    OnSaved(nw, i) {
        cfg.Opener.Watch[i] := nw
        REUI_Opener_FillWatch(lv, cfg)
    }
}
REUI_Opener_WatchDel(cfg, lv) {
    row := lv.GetNext(0,"Focused")
    if !row {
        return
    }
    cfg.Opener.Watch.RemoveAt(row)
    REUI_Opener_FillWatch(lv, cfg)
}

REUI_Opener_FillSteps(lv, cfg) {
    lv.Opt("-Redraw")
    lv.Delete()
    if HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps) {
        for i, st in cfg.Opener.Steps {
            kind := HasProp(st,"Kind") ? st.Kind : "?"
            sum  := REUI_Opener_StepSummary(st)
            rr   := HasProp(st,"RequireReady") ? st.RequireReady : 0
            pre  := HasProp(st,"PreDelayMs") ? st.PreDelayMs : 0
            hold := HasProp(st,"HoldMs") ? st.HoldMs : 0
            ver  := HasProp(st,"Verify") ? st.Verify : 0
            to   := HasProp(st,"TimeoutMs") ? st.TimeoutMs : 0
            dur  := HasProp(st,"DurationMs") ? st.DurationMs : 0
            lv.Add("", i, kind, sum, rr, pre, hold, ver, to, dur)
        }
    }
    Loop 9 {
        lv.ModifyCol(A_Index,"AutoHdr")
    }
    lv.Opt("+Redraw")
}
REUI_Opener_StepSummary(st) {
    k := HasProp(st,"Kind") ? st.Kind : "?"
    if (k="Skill") {
        si := HasProp(st,"SkillIndex") ? st.SkillIndex : 0
        return "Skill#" si " (" REUI_Opener_SkillName(si) ")"
    } else if (k="Wait") {
        d := HasProp(st,"DurationMs") ? st.DurationMs : 0
        return "Wait " d "ms"
    } else if (k="Swap") {
        to := HasProp(st,"TimeoutMs") ? st.TimeoutMs : 800
        rt := HasProp(st,"Retry") ? st.Retry : 0
        return "Swap (TO=" to ", Retry=" rt ")"
    }
    return "?"
}
REUI_Opener_StepAdd(owner, cfg, lv) {
    st := { Kind:"Skill", SkillIndex:1, RequireReady:0, PreDelayMs:0, HoldMs:0, Verify:0, TimeoutMs:1200, DurationMs:0 }
    REUI_Opener_StepEditor_Open(owner, st, 0, OnSaved)
    OnSaved(ns, i) {
        cfg.Opener.Steps.Push(ns)
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        REUI_Opener_FillSteps(lv, cfg)
    }
}
REUI_Opener_StepEdit(owner, cfg, lv) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一个步骤"
        return
    }
    st := cfg.Opener.Steps[row]
    REUI_Opener_StepEditor_Open(owner, st, row, OnSaved)
    OnSaved(ns, i) {
        cfg.Opener.Steps[i] := ns
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        REUI_Opener_FillSteps(lv, cfg)
    }
}
REUI_Opener_StepDel(cfg, lv) {
    row := lv.GetNext(0, "Focused")
    if !row {
        return
    }
    cfg.Opener.Steps.RemoveAt(row)
    cfg.Opener.StepsCount := cfg.Opener.Steps.Length
    REUI_Opener_FillSteps(lv, cfg)
}
REUI_Opener_StepMove(cfg, lv, dir) {
    row := lv.GetNext(0, "Focused")
    if !row {
        return
    }
    from := row
    to := from + dir
    if (to < 1 || to > cfg.Opener.Steps.Length) {
        return
    }
    item := cfg.Opener.Steps[from]
    cfg.Opener.Steps.RemoveAt(from)
    cfg.Opener.Steps.InsertAt(to, item)
    cfg.Opener.StepsCount := cfg.Opener.Steps.Length
    REUI_Opener_FillSteps(lv, cfg)
    lv.Modify(to, "Select Focus Vis")
}

REUI_Opener_StepEditor_Open(owner, st, idx := 0, onSaved := 0) {
    if !IsObject(st) {
        st := { Kind:"Skill" }
    }
    if !HasProp(st,"Kind") {
        st.Kind := "Skill"
    }

    g3 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增步骤" : "编辑步骤")
    g3.MarginX := 12
    g3.MarginY := 10
    g3.SetFont("s10","Segoe UI")

    g3.Add("Text","w100 Right","类型：")
    ddK := g3.Add("DropDownList","x+6 w120", ["技能","等待","切换"])
    kdef := StrUpper(HasProp(st,"Kind") ? st.Kind : "SKILL")
    ddK.Value := (kdef="SKILL")?1:(kdef="WAIT")?2:3

    ; 技能
    g3.Add("Text","xm y+10 w100 Right","技能：")
    ddSS := g3.Add("DropDownList","x+6 w120")
    cnt := 0
    try cnt := App["ProfileData"].Skills.Length
    if (cnt>0) {
        names := []
        for _, s in App["ProfileData"].Skills {
            names.Push(s.Name)
        }
        ddSS.Add(names)
        defIdx := HasProp(st,"SkillIndex") ? st.SkillIndex : 1
        ddSS.Value := REUI_IndexClamp(defIdx, names.Length)
        ddSS.Enabled := true
    } else {
        ddSS.Add(["（无技能）"])
        ddSS.Value := 1
        ddSS.Enabled := false
    }

    cbReq := g3.Add("CheckBox","xm y+8","需就绪")
    cbReq.Value := HasProp(st,"RequireReady") ? (st.RequireReady?1:0) : 0

    g3.Add("Text","xm y+8 w100 Right","预延时(ms)：")
    edPre := g3.Add("Edit","x+6 w120 Number", HasProp(st,"PreDelayMs")?st.PreDelayMs:0)

    g3.Add("Text","x+20 w100 Right","按住(ms)：")
    edHold := g3.Add("Edit","x+6 w120 Number", HasProp(st,"HoldMs")?st.HoldMs:0)

    cbVer := g3.Add("CheckBox","xm y+8","发送后验证")
    cbVer.Value := HasProp(st,"Verify") ? (st.Verify?1:0) : 0

    ; 等待
    g3.Add("Text","xm y+10 w90 Right","时长(ms)：")
    edDur := g3.Add("Edit","x+6 w140 Number", HasProp(st,"DurationMs")?st.DurationMs:0)

    ; 切换
    g3.Add("Text","xm y+10 w90 Right","超时(ms)：")
    edTO := g3.Add("Edit","x+6 w140 Number", HasProp(st,"TimeoutMs")?st.TimeoutMs:800)
    g3.Add("Text","x+16 w70 Right","重试：")
    edRt := g3.Add("Edit","x+6 w120 Number", HasProp(st,"Retry")?st.Retry:0)

    btnOK := g3.Add("Button","xm y+12 w90","确定")
    btnCA := g3.Add("Button","x+8 w90","取消")

    ddK.OnEvent("Change", (*) => ToggleStep())
    btnOK.OnEvent("Click", SaveStep)
    btnCA.OnEvent("Click", (*) => g3.Destroy())
    g3.OnEvent("Close", (*) => g3.Destroy())

    ToggleStep()
    g3.Show()

    ToggleStep() {
        kcn := ddK.Text
        ShowSkill := (kcn="技能")
        ShowWait  := (kcn="等待")
        ShowSwap  := (kcn="切换")
        for ctl in [ddSS, cbReq, edPre, edHold, cbVer] {
            ctl.Visible := ShowSkill
        }
        for ctl in [edDur] {
            ctl.Visible := ShowWait
        }
        for ctl in [edTO, edRt] {
            ctl.Visible := ShowSwap
        }
    }
    SaveStep(*) {
        kcn := ddK.Text
        kkey := (kcn="技能") ? "Skill" : (kcn="等待") ? "Wait" : "Swap"
        if (kkey="Skill" && !ddSS.Enabled) {
            MsgBox "当前没有可引用的技能。"
            return
        }
        ns := {}
        if (kkey="Skill") {
            si := ddSS.Value ? ddSS.Value : 1
            pre := (edPre.Value!="") ? Integer(edPre.Value) : 0
            hold:= (edHold.Value!="") ? Integer(edHold.Value) : 0
            rr  := cbReq.Value ? 1 : 0
            ver := cbVer.Value ? 1 : 0
            ns := { Kind:"Skill", SkillIndex: si, RequireReady: rr
                  , PreDelayMs: pre, HoldMs: hold, Verify: ver
                  , TimeoutMs: 1200, DurationMs: 0 }
        } else if (kkey="Wait") {
            dur := (edDur.Value!="") ? Integer(edDur.Value) : 0
            ns := { Kind:"Wait", DurationMs: dur }
        } else {
            to := (edTO.Value!="") ? Integer(edTO.Value) : 800
            rt := (edRt.Value!="") ? Integer(edRt.Value) : 0
            ns := { Kind:"Swap", TimeoutMs: to, Retry: rt }
        }
        if onSaved {
            onSaved(ns, (idx=0?0:idx))
        }
        g3.Destroy()
    }
}
REUI_Opener_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    if !IsObject(w) {
        w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    }
    g2 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增监视" : "编辑监视")
    g2.MarginX := 12
    g2.MarginY := 10
    g2.SetFont("s10","Segoe UI")

    g2.Add("Text","w90 Right","技能：")
    ddS := g2.Add("DropDownList","x+6 w260")
    cnt := 0
    try cnt := App["ProfileData"].Skills.Length
    if (cnt>0) {
        names := []
        for _, s in App["ProfileData"].Skills {
            names.Push(s.Name)
        }
        ddS.Add(names)
        defIdx := HasProp(w,"SkillIndex") ? w.SkillIndex : 1
        ddS.Value := REUI_IndexClamp(defIdx, names.Length)
        ddS.Enabled := true
    } else {
        ddS.Add(["（无技能）"])
        ddS.Value := 1
        ddS.Enabled := false
    }

    g2.Add("Text","xm y+8 w90 Right","计数：")
    edReq := g2.Add("Edit","x+6 w260 Number Center", HasProp(w,"RequireCount")?w.RequireCount:1)

    cbVB := g2.Add("CheckBox","xm y+8","黑框确认")
    cbVB.Value := HasProp(w,"VerifyBlack") ? (w.VerifyBlack?1:0) : 0

    btnOK := g2.Add("Button","xm y+12 w90","确定")
    btnCA := g2.Add("Button","x+8 w90","取消")

    btnOK.OnEvent("Click", SaveWatch)
    btnCA.OnEvent("Click", (*) => g2.Destroy())
    g2.OnEvent("Close", (*) => g2.Destroy())
    g2.Show()

    SaveWatch(*) {
        if (!ddS.Enabled) {
            MsgBox "当前没有可引用的技能。"
            return
        }
        si := ddS.Value ? ddS.Value : 1
        req := (edReq.Value!="") ? Integer(edReq.Value) : 1
        vb  := cbVB.Value ? 1 : 0
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
        if onSaved {
            onSaved(nw, idx)
        }
        g2.Destroy()
    }
}