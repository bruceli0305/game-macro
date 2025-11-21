#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

REUI_Opener_Ensure(cfg) {
    if !IsObject(cfg) {
        return
    }
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
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if (HasProp(cfg.Opener,"Watch") && IsObject(cfg.Opener.Watch)) {
            for _, w in cfg.Opener.Watch {
                sName := REUI_Opener_SkillName(HasProp(w,"SkillIndex")?w.SkillIndex:0)
                req := HasProp(w,"RequireCount") ? w.RequireCount : 1
                vb  := HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0
                lv.Add("", sName, req, vb)
            }
        }
        Loop 3 {
            try {
                lv.ModifyCol(A_Index,"AutoHdr")
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

REUI_Opener_SkillName(idx) {
    try {
        if (idx>=1 && idx<=App["ProfileData"].Skills.Length) {
            return App["ProfileData"].Skills[idx].Name
        }
    } catch {
    }
    return "技能#" idx
}

REUI_Opener_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    global App
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
    try {
        cnt := App["ProfileData"].Skills.Length
    } catch {
        cnt := 0
    }
    if (cnt>0) {
        names := []
        try {
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
        } catch {
        }
        try {
            ddS.Add(names)
        } catch {
        }
        defIdx := 1
        try {
            defIdx := HasProp(w,"SkillIndex") ? w.SkillIndex : 1
        } catch {
            defIdx := 1
        }
        try {
            ddS.Value := REUI_IndexClamp(defIdx, names.Length)
            ddS.Enabled := true
        } catch {
        }
    } else {
        try {
            ddS.Add(["（无技能）"])
        } catch {
        }
        ddS.Value := 1
        ddS.Enabled := false
    }

    g2.Add("Text","xm y+8 w90 Right","计数：")
    edReq := g2.Add("Edit","x+6 w260 Number Center", HasProp(w,"RequireCount")?w.RequireCount:1)

    cbVB := g2.Add("CheckBox","xm y+8","黑框确认")
    try {
        cbVB.Value := HasProp(w,"VerifyBlack") ? (w.VerifyBlack?1:0) : 0
    } catch {
        cbVB.Value := 0
    }

    btnOK := g2.Add("Button","xm y+12 w90","确定")
    btnCA := g2.Add("Button","x+8 w90","取消")

    btnOK.OnEvent("Click", SaveWatch)
    btnCA.OnEvent("Click", (*) => g2.Destroy())
    g2.OnEvent("Close", (*) => g2.Destroy())
    try {
        g2.Show()
    } catch {
    }

    SaveWatch(*) {
        if (!ddS.Enabled) {
            MsgBox "当前没有可引用的技能。"
            return
        }
        si := 1
        try {
            si := ddS.Value ? ddS.Value : 1
        } catch {
            si := 1
        }
        req := 1
        vb := 0
        try {
            req := (edReq.Value!="") ? Integer(edReq.Value) : 1
        } catch {
            req := 1
        }
        try {
            vb := cbVB.Value ? 1 : 0
        } catch {
            vb := 0
        }
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
        if onSaved {
            try {
                onSaved(nw, idx)
            } catch {
            }
        }
        try {
            g2.Destroy()
        } catch {
        }
        Notify("已保存监视")
    }
}

; 监视列表操作
REUI_Opener_WatchAdd(owner, cfg, lv) {
    w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    REUI_Opener_WatchEditor_Open(owner, w, 0, OnSaved)
    OnSaved(nw, i) {
        try {
            cfg.Opener.Watch.Push(nw)
            REUI_Opener_FillWatch(lv, cfg)
        } catch {
        }
    }
}
REUI_Opener_WatchEdit(owner, cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0,"Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一条监视"
        return
    }
    w := cfg.Opener.Watch[row]
    REUI_Opener_WatchEditor_Open(owner, w, row, OnSaved)
    OnSaved(nw, i) {
        try {
            cfg.Opener.Watch[i] := nw
            REUI_Opener_FillWatch(lv, cfg)
        } catch {
        }
    }
}
REUI_Opener_WatchDel(cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0,"Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        cfg.Opener.Watch.RemoveAt(row)
        REUI_Opener_FillWatch(lv, cfg)
    } catch {
    }
}

REUI_Opener_FillSteps(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
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
                try {
                    lv.Add("", i, kind, sum, rr, pre, hold, ver, to, dur)
                } catch {
                }
            }
        }
        Loop 9 {
            try {
                lv.ModifyCol(A_Index,"AutoHdr")
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
        try {
            cfg.Opener.Steps.Push(ns)
            cfg.Opener.StepsCount := cfg.Opener.Steps.Length
            REUI_Opener_FillSteps(lv, cfg)
        } catch {
        }
    }
}
REUI_Opener_StepEdit(owner, cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一个步骤"
        return
    }
    st := cfg.Opener.Steps[row]
    REUI_Opener_StepEditor_Open(owner, st, row, OnSaved)
    OnSaved(ns, i) {
        try {
            cfg.Opener.Steps[i] := ns
            cfg.Opener.StepsCount := cfg.Opener.Steps.Length
            REUI_Opener_FillSteps(lv, cfg)
        } catch {
        }
    }
}
REUI_Opener_StepDel(cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        cfg.Opener.Steps.RemoveAt(row)
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        REUI_Opener_FillSteps(lv, cfg)
    } catch {
    }
}
REUI_Opener_StepMove(cfg, lv, dir) {
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
    if (to < 1 || to > cfg.Opener.Steps.Length) {
        return
    }
    item := cfg.Opener.Steps[from]
    try {
        cfg.Opener.Steps.RemoveAt(from)
        cfg.Opener.Steps.InsertAt(to, item)
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        REUI_Opener_FillSteps(lv, cfg)
        lv.Modify(to, "Select Focus Vis")
    } catch {
    }
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

    g3.Add("Text","xm y+10 w100 Right","技能：")
    ddSS := g3.Add("DropDownList","x+6 w120")
    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    } catch {
        cnt := 0
    }
    if (cnt>0) {
        names := []
        try {
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
        } catch {
        }
        try {
            ddSS.Add(names)
        } catch {
        }
        defIdx := 1
        try {
            defIdx := HasProp(st,"SkillIndex") ? st.SkillIndex : 1
        } catch {
            defIdx := 1
        }
        try {
            ddSS.Value := REUI_IndexClamp(defIdx, names.Length)
            ddSS.Enabled := true
        } catch {
        }
    } else {
        try {
            ddSS.Add(["（无技能）"])
        } catch {
        }
        ddSS.Value := 1
        ddSS.Enabled := false
    }

    cbReq := g3.Add("CheckBox","xm y+8","需就绪")
    try {
        cbReq.Value := HasProp(st,"RequireReady") ? (st.RequireReady?1:0) : 0
    } catch {
        cbReq.Value := 0
    }

    g3.Add("Text","xm y+8 w100 Right","预延时(ms)：")
    edPre := g3.Add("Edit","x+6 w120 Number", HasProp(st,"PreDelayMs")?st.PreDelayMs:0)

    g3.Add("Text","x+20 w100 Right","按住(ms)：")
    edHold := g3.Add("Edit","x+6 w120 Number", HasProp(st,"HoldMs")?st.HoldMs:0)

    cbVer := g3.Add("CheckBox","xm y+8","发送后验证")
    try {
        cbVer.Value := HasProp(st,"Verify") ? (st.Verify?1:0) : 0
    } catch {
        cbVer.Value := 0
    }

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
    try {
        g3.Show()
    } catch {
    }

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
        if (kkey="Skill") {
            if (!ddSS.Enabled) {
                MsgBox "当前没有可引用的技能。"
                return
            }
        }
        ns := {}
        if (kkey="Skill") {
            si := 1
            try {
                si := ddSS.Value ? ddSS.Value : 1
            } catch {
                si := 1
            }
            pre := 0
            hold := 0
            rr := 0
            ver := 0
            try {
                pre := (edPre.Value!="") ? Integer(edPre.Value) : 0
            } catch {
                pre := 0
            }
            try {
                hold := (edHold.Value!="") ? Integer(edHold.Value) : 0
            } catch {
                hold := 0
            }
            try {
                rr := cbReq.Value ? 1 : 0
            } catch {
                rr := 0
            }
            try {
                ver := cbVer.Value ? 1 : 0
            } catch {
                ver := 0
            }

            ns := { Kind:"Skill", SkillIndex: si, RequireReady: rr
                  , PreDelayMs: pre, HoldMs: hold, Verify: ver
                  , TimeoutMs: 1200, DurationMs: 0 }
        } else if (kkey="Wait") {
            dur := 0
            try {
                dur := (edDur.Value!="") ? Integer(edDur.Value) : 0
            } catch {
                dur := 0
            }
            ns := { Kind:"Wait", DurationMs: dur }
        } else {
            to := 800
            rt := 0
            try {
                to := (edTO.Value!="") ? Integer(edTO.Value) : 800
            } catch {
                to := 800
            }
            try {
                rt := (edRt.Value!="") ? Integer(edRt.Value) : 0
            } catch {
                rt := 0
            }
            ns := { Kind:"Swap", TimeoutMs: to, Retry: rt }
        }
        if onSaved {
            try {
                onSaved(ns, (idx=0?0:idx))
            } catch {
            }
        }
        try {
            g3.Destroy()
        } catch {
        }
    }
}