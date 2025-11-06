; modules\ui\rotation\RE_UI_Page_Opener.ahk
; 严格 AHK v2：无单行 if/catch、无逗号链、无内联 “; return }” 之类注释
#Requires AutoHotkey v2
#Include "..\shell_v2\UIX_Common.ahk"

; 起手页：顶部表单（启用/时长/线程）+ 右列 Watch/Steps（工具条 + 满宽列表）
; Build(ctx) => { Save: Func }
REUI_Page_Opener_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(1)
    REUI_Opener_Ensure(&cfg)

    rc := UIX_PageRect(ctx.dlg)

    ; 顶部表单
    cbEnable := dlg.Add("CheckBox", Format("x{} y{} w160", rc.X, rc.Y + 8), "启用起手")
    cbEnable.Value := cfg.Opener.Enabled ? 1 : 0

    labMax := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, rc.Y + 44), "最大时长(ms)：")
    edMax  := dlg.Add("Edit", Format("x{} y{} w120 Number Center", rc.X + 110 + 6, rc.Y + 40), cfg.Opener.MaxDurationMs)

    labThr := dlg.Add("Text", Format("x{} y{} w80 Right", rc.X + 380, rc.Y + 44), "线程：")
    ddThr  := dlg.Add("DropDownList", Format("x{} y{} w200", rc.X + 380 + 80 + 6, rc.Y + 40))
    thrNames := []
    thrIds   := []
    try {
        for _, th in App["ProfileData"].Threads {
            thrNames.Push(th.Name)
            thrIds.Push(th.Id)
        }
    }
    if (thrNames.Length) {
        ddThr.Add(thrNames)
    }
    sel := 1
    curTid := HasProp(cfg.Opener, "ThreadId") ? cfg.Opener.ThreadId : 1
    for i, id in thrIds {
        if (id = curTid) {
            sel := i
            break
        }
    }
    ddThr.Value := sel

    ; 求表单底部 y
    ddThr.GetPos(&tx, &ty, &tw, &th)
    yFormBottom := ty + th

    ; 两列区域：右侧用于列表
    cols := UIX_Cols2(rc, 0.58, 12)
    R := cols.R

    ; 右列：Watch 工具条 + 列表
    btnWAdd  := dlg.Add("Button", Format("x{} y{} w70", R.X, yFormBottom + 12), "新增")
    btnWEdit := dlg.Add("Button", "x+6 w70", "编辑")
    btnWDel  := dlg.Add("Button", "x+6 w70", "删除")

    watchY := yFormBottom + 12 + 34 + 6
    watchH := Round(R.H * 0.38)
    lvOW   := dlg.Add("ListView", Format("x{} y{} w{} h{} +Grid", R.X, watchY, R.W, watchH)
                     , ["技能","Require","VerifyBlack"])
    REUI_Opener_FillWatch(lvOW, cfg)
    btnWAdd.OnEvent("Click", (*) => REUI_Opener_WatchAdd(dlg, cfg, lvOW))
    btnWEdit.OnEvent("Click", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))
    btnWDel.OnEvent("Click", (*) => REUI_Opener_WatchDel(cfg, lvOW))
    lvOW.OnEvent("DoubleClick", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))
    Loop 3 {
        lvOW.ModifyCol(A_Index, "AutoHdr")
    }

    ; 右列：Steps 工具条 + 列表
    stepsToolY := watchY + watchH + 12
    btnSAdd  := dlg.Add("Button", Format("x{} y{} w70", R.X, stepsToolY), "新增")
    btnSEdit := dlg.Add("Button", "x+6 w70", "编辑")
    btnSDel  := dlg.Add("Button", "x+6 w70", "删除")
    btnSUp   := dlg.Add("Button", "x+18 w70", "上移")
    btnSDn   := dlg.Add("Button", "x+6 w70", "下移")

    stepsY := stepsToolY + 34 + 6
    stepsH := Max(120, R.H - (stepsY - rc.Y) - 56)
    lvS    := dlg.Add("ListView", Format("x{} y{} w{} h{} +Grid", R.X, stepsY, R.W, stepsH)
                    , ["序","类型","详情","就绪","预延时","按住","验证","超时","时长"])
    REUI_Opener_FillSteps(lvS, cfg)
    btnSAdd.OnEvent("Click", (*) => REUI_Opener_StepAdd(dlg, cfg, lvS))
    btnSEdit.OnEvent("Click", (*) => REUI_Opener_StepEdit(dlg, cfg, lvS))
    btnSDel.OnEvent("Click", (*) => REUI_Opener_StepDel(cfg, lvS))
    btnSUp.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS, -1))
    btnSDn.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS,  1))
    Loop 9 {
        lvS.ModifyCol(A_Index, "AutoHdr")
    }

    ; 底部保存
    btnSave := dlg.Add("Button", Format("x{} y{} w120", R.X, stepsY + stepsH + 12), "保存起手")
    btnSave.OnEvent("Click", SaveOpener)

    ; 保存函数（给 Build 返回调用）
    Save := (*) => (
        cfg.Opener.Enabled := cbEnable.Value ? 1 : 0
      , cfg.Opener.MaxDurationMs := (edMax.Value!="") ? Integer(edMax.Value) : 4000
      , cfg.Opener.ThreadId := (ddThr.Value>=1 && ddThr.Value<=thrIds.Length) ? thrIds[ddThr.Value] : 1
    )

    SaveOpener(*) {
        Save()
        cfg.Opener.StepsCount := (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) ? cfg.Opener.Steps.Length : 0
        Storage_SaveProfile(App["ProfileData"])
        Notify("起手已保存")
    }

    return { Save: Save }
}

;===================== 数据与工具 =====================
REUI_Opener_Ensure(&cfg) {
    if !HasProp(cfg,"Opener") {
        cfg.Opener := {}
    }
    op := cfg.Opener
    if !HasProp(op,"Enabled")       {
        op.Enabled := 0
    }
    if !HasProp(op,"MaxDurationMs") {
        op.MaxDurationMs := 4000
    }
    if !HasProp(op,"ThreadId")      {
        op.ThreadId := 1
    }
    if !HasProp(op,"Watch")         {
        op.Watch := []
    }
    if !HasProp(op,"StepsCount")    {
        op.StepsCount := 0
    }
    if !HasProp(op,"Steps")         {
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
            req   := HasProp(w,"RequireCount") ? w.RequireCount : 1
            vb    := HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0
            lv.Add("", sName, req, vb)
        }
    }
    Loop 3 {
        lv.ModifyCol(A_Index, "AutoHdr")
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
        MsgBox "请选择一条 Watch"
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

REUI_Opener_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    if !IsObject(w) {
        w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    }
    g2 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增 Watch" : "编辑 Watch")
    g2.MarginX := 12, g2.MarginY := 10
    g2.SetFont("s10","Segoe UI")

    g2.Add("Text", "w70 Right", "技能：")
    ddS := g2.Add("DropDownList", "x+6 w260")
    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    }
    if (cnt > 0) {
        names := []
        for _, s in App["ProfileData"].Skills {
            names.Push(s.Name)
        }
        ddS.Add(names)
        defIdx := HasProp(w,"SkillIndex") ? w.SkillIndex : 1
        ddS.Value := UIX_IndexClamp(defIdx, names.Length)
        ddS.Enabled := true
    } else {
        ddS.Add(["（无技能）"])
        ddS.Value := 1
        ddS.Enabled := false
    }

    g2.Add("Text", "xm y+8 w80 Right", "Require：")
    edReq := g2.Add("Edit", "x+6 w120 Number Center", HasProp(w,"RequireCount")?w.RequireCount:1)

    cbVB := g2.Add("CheckBox", "xm y+8", "VerifyBlack")
    cbVB.Value := HasProp(w,"VerifyBlack") ? (w.VerifyBlack?1:0) : 0

    btnOK := g2.Add("Button", "xm y+12 w90", "确定")
    btnCA := g2.Add("Button", "x+8 w90", "取消")
    btnOK.OnEvent("Click", SaveWatch)
    btnCA.OnEvent("Click", (*) => g2.Destroy())
    g2.OnEvent("Close", (*) => g2.Destroy())
    g2.Show()

    SaveWatch(*) {
        if (!ddS.Enabled) {
            MsgBox "当前没有可引用的技能。"
            return
        }
        si  := ddS.Value ? ddS.Value : 1
        req := (edReq.Value!="") ? Integer(edReq.Value) : 1
        vb  := cbVB.Value ? 1 : 0
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
        if onSaved {
            onSaved(nw, idx)
        }
        g2.Destroy()
    }
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
        lv.ModifyCol(A_Index, "AutoHdr")
    }
    lv.Opt("+Redraw")
}
REUI_Opener_StepSummary(st) {
    k := HasProp(st,"Kind") ? st.Kind : "?"
    if (k = "Skill") {
        si := HasProp(st,"SkillIndex") ? st.SkillIndex : 0
        return "Skill#" si " (" REUI_Opener_SkillName(si) ")"
    } else if (k = "Wait") {
        d := HasProp(st,"DurationMs") ? st.DurationMs : 0
        return "Wait " d "ms"
    } else if (k = "Swap") {
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
    g3.MarginX := 12, g3.MarginY := 10
    g3.SetFont("s10","Segoe UI")

    g3.Add("Text","w70 Right","类型：")
    ddK := g3.Add("DropDownList","x+6 w180", ["技能","等待","切换"])
    kdef := StrUpper(HasProp(st,"Kind") ? st.Kind : "SKILL")
    ddK.Value := (kdef="SKILL")?1:(kdef="WAIT")?2:3

    g3.Add("Text","xm y+10 w70 Right","技能：")
    ddSS := g3.Add("DropDownList","x+6 w260")
    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    }
    if (cnt>0) {
        names := []
        for _, s in App["ProfileData"].Skills {
            names.Push(s.Name)
        }
        ddSS.Add(names)
        defIdx := HasProp(st,"SkillIndex") ? st.SkillIndex : 1
        ddSS.Value := UIX_IndexClamp(defIdx, names.Length)
        ddSS.Enabled := true
    } else {
        ddSS.Add(["（无技能）"])
        ddSS.Value := 1
        ddSS.Enabled := false
    }

    cbReq := g3.Add("CheckBox","xm y+8","需就绪")
    cbReq.Value := HasProp(st,"RequireReady") ? (st.RequireReady?1:0) : 0

    g3.Add("Text","xm y+8 w80 Right","预延时(ms)：")
    edPre := g3.Add("Edit","x+6 w120 Number", HasProp(st,"PreDelayMs")?st.PreDelayMs:0)

    g3.Add("Text","x+20 w80 Right","按住(ms)：")
    edHold := g3.Add("Edit","x+6 w120 Number", HasProp(st,"HoldMs")?st.HoldMs:0)

    cbVer := g3.Add("CheckBox","xm y+8","发送后验证")
    cbVer.Value := HasProp(st,"Verify") ? (st.Verify?1:0) : 0

    g3.Add("Text","xm y+10 w90 Right","时长(ms)：")
    edDur := g3.Add("Edit","x+6 w140 Number", HasProp(st,"DurationMs")?st.DurationMs:0)

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
        showSkill := (kcn="技能")
        showWait  := (kcn="等待")
        showSwap  := (kcn="切换")
        for ctl in [ddSS, cbReq, edPre, edHold, cbVer] {
            ctl.Visible := showSkill
        }
        for ctl in [edDur] {
            ctl.Visible := showWait
        }
        for ctl in [edTO, edRt] {
            ctl.Visible := showSwap
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
            si  := ddSS.Value ? ddSS.Value : 1
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