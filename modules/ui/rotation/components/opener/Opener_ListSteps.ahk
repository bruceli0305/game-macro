#Requires AutoHotkey v2
; Steps 列表、摘要与编辑器

REUI_Opener_FillSteps(lv, cfg) {
    REUI_EnsureIdMaps()
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if (HasProp(cfg, "Opener") && HasProp(cfg.Opener, "Steps") && IsObject(cfg.Opener.Steps)) {
            for i, st in cfg.Opener.Steps {
                kind := "?"
                try {
                    kind := HasProp(st, "Kind") ? st.Kind : "?"
                } catch {
                    kind := "?"
                }
                sum := REUI_Opener_StepSummary(st)
                rr := 0, pre := 0, hold := 0, ver := 0, to := 0, dur := 0
                try rr  := HasProp(st, "RequireReady") ? (st.RequireReady ? 1 : 0) : 0
                try pre := HasProp(st, "PreDelayMs") ? st.PreDelayMs : 0
                try hold:= HasProp(st, "HoldMs") ? st.HoldMs : 0
                try ver := HasProp(st, "Verify") ? (st.Verify ? 1 : 0) : 0
                try to  := HasProp(st, "TimeoutMs") ? st.TimeoutMs : 0
                try dur := HasProp(st, "DurationMs") ? st.DurationMs : 0
                try {
                    lv.Add("", i, kind, sum, rr, pre, hold, ver, to, dur)
                } catch {
                }
            }
        }
        Loop 9 {
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

REUI_Opener_StepSummary(st) {
    REUI_EnsureIdMaps()
    k := "?"
    try {
        k := HasProp(st, "Kind") ? st.Kind : "?"
    } catch {
        k := "?"
    }
    if (k = "Skill") {
        si := 0
        try {
            si := HasProp(st, "SkillIndex") ? st.SkillIndex : 0
        } catch {
            si := 0
        }
        return "Skill#" si " (" REUI_SkillName(si) ")"
    } else if (k = "Wait") {
        d := 0
        try {
            d := HasProp(st, "DurationMs") ? st.DurationMs : 0
        } catch {
            d := 0
        }
        return "Wait " d "ms"
    } else if (k = "Swap") {
        to := 800
        rt := 0
        try {
            to := HasProp(st, "TimeoutMs") ? st.TimeoutMs : 800
        } catch {
            to := 800
        }
        try {
            rt := HasProp(st, "Retry") ? st.Retry : 0
        } catch {
            rt := 0
        }
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
    if (row = 0) {
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
    if (row = 0) {
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
    if (row = 0) {
        return
    }
    from := row
    to := from + dir

    len := 0
    try {
        len := cfg.Opener.Steps.Length
    } catch {
        len := 0
    }
    if (to < 1) {
        return
    }
    if (to > len) {
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
    global App
    if (!IsObject(st)) {
        st := { Kind:"Skill" }
    }
    if (!HasProp(st, "Kind")) {
        st.Kind := "Skill"
    }
    REUI_EnsureIdMaps()
    
    title := "新增步骤"
    if (idx != 0) {
        title := "编辑步骤"
    }
    g3 := Gui("+Owner" owner.Hwnd, title)
    g3.MarginX := 12
    g3.MarginY := 10
    g3.SetFont("s10", "Segoe UI")

    g3.Add("Text", "w100 Right", "类型：")
    ddK := g3.Add("DropDownList", "x+6 w120", ["技能", "等待", "切换"])
    kdef := "SKILL"
    try {
        kdef := StrUpper(HasProp(st, "Kind") ? st.Kind : "SKILL")
    } catch {
        kdef := "SKILL"
    }
    ddK.Value := (kdef = "SKILL") ? 1 : (kdef = "WAIT") ? 2 : 3

    g3.Add("Text", "xm y+10 w100 Right", "技能：")
    ddSS := g3.Add("DropDownList", "x+6 w120")

    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    } catch {
        cnt := 0
    }
    if (cnt > 0) {
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
            defIdx := HasProp(st, "SkillIndex") ? st.SkillIndex : 1
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
        try {
            ddSS.Value := 1
            ddSS.Enabled := false
        } catch {
        }
    }

    cbReq := g3.Add("CheckBox", "xm y+8", "需就绪")
    try {
        cbReq.Value := HasProp(st, "RequireReady") ? (st.RequireReady ? 1 : 0) : 0
    } catch {
        cbReq.Value := 0
    }

    g3.Add("Text", "xm y+8 w100 Right", "预延时(ms)：")
    edPre := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "PreDelayMs") ? st.PreDelayMs : 0)

    g3.Add("Text", "x+20 w100 Right", "按住(ms)：")
    edHold := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "HoldMs") ? st.HoldMs : 0)

    cbVer := g3.Add("CheckBox", "xm y+8", "发送后验证")
    try {
        cbVer.Value := HasProp(st, "Verify") ? (st.Verify ? 1 : 0) : 0
    } catch {
        cbVer.Value := 0
    }

    g3.Add("Text", "xm y+10 w90 Right", "时长(ms)：")
    edDur := g3.Add("Edit", "x+6 w140 Number", HasProp(st, "DurationMs") ? st.DurationMs : 0)

    g3.Add("Text", "xm y+10 w90 Right", "超时(ms)：")
    edTO := g3.Add("Edit", "x+6 w140 Number", HasProp(st, "TimeoutMs") ? st.TimeoutMs : 800)
    g3.Add("Text", "x+16 w70 Right", "重试：")
    edRt := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "Retry") ? st.Retry : 0)

    btnOK := g3.Add("Button", "xm y+12 w90", "确定")
    btnCA := g3.Add("Button", "x+8 w90", "取消")

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
        ShowSkill := (kcn = "技能")
        ShowWait := (kcn = "等待")
        ShowSwap := (kcn = "切换")

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
        kkey := "Skill"
        if (kcn = "技能") {
            kkey := "Skill"
        } else if (kcn = "等待") {
            kkey := "Wait"
        } else {
            kkey := "Swap"
        }

        if (kkey = "Skill") {
            if (!ddSS.Enabled) {
                MsgBox "当前没有可引用的技能。"
                return
            }
        }

        ns := {}
        if (kkey = "Skill") {
            si := 1
            pre := 0
            hold := 0
            rr := 0
            ver := 0
            try {
                si := ddSS.Value ? ddSS.Value : 1
            } catch {
                si := 1
            }
            try {
                pre := (edPre.Value != "") ? Integer(edPre.Value) : 0
            } catch {
                pre := 0
            }
            try {
                hold := (edHold.Value != "") ? Integer(edHold.Value) : 0
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
        } else if (kkey = "Wait") {
            dur := 0
            try {
                dur := (edDur.Value != "") ? Integer(edDur.Value) : 0
            } catch {
                dur := 0
            }
            ns := { Kind:"Wait", DurationMs: dur }
        } else {
            to := 800
            rt := 0
            try {
                to := (edTO.Value != "") ? Integer(edTO.Value) : 800
            } catch {
                to := 800
            }
            try {
                rt := (edRt.Value != "") ? Integer(edRt.Value) : 0
            } catch {
                rt := 0
            }
            ns := { Kind:"Swap", TimeoutMs: to, Retry: rt }
        }

        if (onSaved) {
            try {
                onSaved(ns, (idx = 0 ? 0 : idx))
            } catch {
            }
        }
        try {
            g3.Destroy()
        } catch {
        }
    }
}