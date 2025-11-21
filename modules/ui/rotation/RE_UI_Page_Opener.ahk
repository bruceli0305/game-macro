#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

REUI_Page_Opener_Build(ctx) {
    global App
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(4)
    try {
        REUI_Opener_Ensure(&cfg)
    } catch {
    }

    cbEnable := dlg.Add("CheckBox", "xm y+10 w160", "启用起手")
    try {
        cbEnable.Value := cfg.Opener.Enabled ? 1 : 0
    } catch {
        cbEnable.Value := 0
    }

    dlg.Add("Text","xm y+8 w110 Right","最大时长(ms)：")
    edMax := dlg.Add("Edit","x+6 w120 Number Center", HasProp(cfg.Opener,"MaxDurationMs") ? cfg.Opener.MaxDurationMs : 4000)

    dlg.Add("Text","x+20 w80 Right","线程：")
    ddThr := dlg.Add("DropDownList","x+6 w200")
    thrNames := []
    thrIds := []
    try {
        for _, th in App["ProfileData"].Threads {
            thrNames.Push(th.Name)
            thrIds.Push(th.Id)
        }
    } catch {
    }
    if (thrNames.Length) {
        try {
            ddThr.Add(thrNames)
        } catch {
        }
    }
    pos := 1
    curTid := 1
    try {
        curTid := HasProp(cfg.Opener,"ThreadId") ? cfg.Opener.ThreadId : 1
    } catch {
        curTid := 1
    }
    i := 1
    while (i <= thrIds.Length) {
        idv := 1
        try {
            idv := thrIds[i]
        } catch {
            idv := 1
        }
        if (idv = curTid) {
            pos := i
            break
        }
        i := i + 1
    }
    try {
        ddThr.Value := pos
    } catch {
    }

    rc := { X: 12, Y: 12, W: 820, H: 520 }
    try {
        r := UI_TabPageRect(tab)
        if (IsObject(r)) {
            rc := r
        }
    } catch {
    }
    btnW := 84
    gap := 8
    minW := 560
    listW := Max(minW, rc.W - btnW - gap - 20)

    dlg.Add("Text","xm y+16","监视（技能计数/黑框确认）：")
    lvOW := dlg.Add("ListView", Format("xm y+6 w{} r7 +Grid", listW), ["技能","计数","黑框确认"])
    lvOW.GetPos(&lx, &ly, &lw, &lh)
    btnX := lx + lw + gap
    btnWAdd := dlg.Add("Button", Format("x{} y{} w{}", btnX, ly, btnW), "新增")
    btnWEdit:= dlg.Add("Button", Format("x{} y{} w{}", btnX, ly + 34, btnW), "编辑")
    btnWDel := dlg.Add("Button", Format("x{} y{} w{}", btnX, ly + 68, btnW), "删除")

    try {
        REUI_Opener_FillWatch(lvOW, cfg)
    } catch {
    }
    btnWAdd.OnEvent("Click", (*) => REUI_Opener_WatchAdd(dlg, cfg, lvOW))
    btnWEdit.OnEvent("Click", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))
    btnWDel.OnEvent("Click", (*) => REUI_Opener_WatchDel(cfg, lvOW))
    lvOW.OnEvent("DoubleClick", (*) => REUI_Opener_WatchEdit(dlg, cfg, lvOW))

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

    try {
        REUI_Opener_FillSteps(lvS, cfg)
    } catch {
    }
    btnSAdd.OnEvent("Click", (*) => REUI_Opener_StepAdd(dlg, cfg, lvS))
    btnSEdit.OnEvent("Click", (*) => REUI_Opener_StepEdit(dlg, cfg, lvS))
    btnSDel.OnEvent("Click", (*) => REUI_Opener_StepDel(cfg, lvS))
    btnSUp.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS, -1))
    btnSDn.OnEvent("Click", (*) => REUI_Opener_StepMove(cfg, lvS, 1))
    lvS.OnEvent("DoubleClick", (*) => REUI_Opener_StepEdit(dlg, cfg, lvS))

    btnSave := dlg.Add("Button", Format("x{} y{} w120", sx, sy + sh + 12), "保存起手")
    btnSave.OnEvent("Click", SaveOpener)

    SaveOpener(*) {
        global App
        if !(IsSet(App) && App.Has("CurrentProfile") && App.Has("ProfileData")) {
            MsgBox "未选择配置或配置未加载。"
            return
        }

        try {
            cfg.Opener.Enabled := cbEnable.Value ? 1 : 0
        } catch {
        }
        try {
            if (edMax.Value != "") {
                cfg.Opener.MaxDurationMs := Integer(edMax.Value)
            } else {
                cfg.Opener.MaxDurationMs := 4000
            }
        } catch {
            cfg.Opener.MaxDurationMs := 4000
        }

        if (ddThr.Value>=1 && ddThr.Value<=thrIds.Length) {
            try {
                cfg.Opener.ThreadId := thrIds[ddThr.Value]
            } catch {
                cfg.Opener.ThreadId := 1
            }
        } else {
            cfg.Opener.ThreadId := 1
        }

        try {
            cfg.Opener.StepsCount := (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) ? cfg.Opener.Steps.Length : 0
        } catch {
            cfg.Opener.StepsCount := 0
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

        dbgOp := 0
        try {
            if Logger_IsEnabled(50, "Opener") {
                dbgOp := 1
            } else {
                dbgOp := 0
            }
        } catch {
            dbgOp := 0
        }
        if (dbgOp) {
            f0 := Map()
            try {
                f0["profile"] := name
                Logger_Debug("Opener", "RE_UI_Page_Opener.Save begin", f0)
            } catch {
            }
        }

        skIdByIdx := Map()
        try {
            if (p.Has("Skills") && IsObject(p["Skills"])) {
                i := 1
                while (i <= p["Skills"].Length) {
                    sid := 0
                    try {
                        sid := OM_Get(p["Skills"][i], "Id", 0)
                    } catch {
                        sid := 0
                    }
                    skIdByIdx[i] := sid
                    i := i + 1
                }
            }
        } catch {
        }
        if (dbgOp) {
            f1 := Map()
            i := 1
            while (i <= 10) {
                v := ""
                try {
                    if skIdByIdx.Has(i) {
                        v := skIdByIdx[i]
                    } else {
                        v := "(none)"
                    }
                } catch {
                    v := "(err)"
                }
                try {
                    f1["s" i] := v
                } catch {
                }
                i := i + 1
            }
            try {
                Logger_Debug("Opener", "Skill idx→Id map (first 10)", f1)
            } catch {
            }
        }

        op := Map()
        try {
            op["Enabled"] := OM_Get(cfg.Opener, "Enabled", 0)
            op["MaxDurationMs"] := OM_Get(cfg.Opener, "MaxDurationMs", 4000)
            op["ThreadId"] := OM_Get(cfg.Opener, "ThreadId", 1)
        } catch {
        }

        wArr := []
        try {
            if (HasProp(cfg.Opener,"Watch") && IsObject(cfg.Opener.Watch)) {
                i := 1
                while (i <= cfg.Opener.Watch.Length) {
                    w0 := cfg.Opener.Watch[i]
                    si := 0
                    try {
                        si := OM_Get(w0, "SkillIndex", 0)
                    } catch {
                        si := 0
                    }
                    sid := 0
                    try {
                        if (skIdByIdx.Has(si)) {
                            sid := skIdByIdx[si]
                        } else {
                            sid := 0
                        }
                    } catch {
                        sid := 0
                    }
                    need := 1
                    vb := 0
                    try {
                        need := OM_Get(w0, "RequireCount", 1)
                        vb   := OM_Get(w0, "VerifyBlack", 0)
                    } catch {
                        need := 1
                        vb := 0
                    }
                    wArr.Push(Map("SkillId", sid, "RequireCount", need, "VerifyBlack", vb))
                    if (dbgOp) {
                        row := Map()
                        try {
                            row["WatchIdx"] := i
                            row["SkillIndex"] := si
                            row["SkillId"] := sid
                            row["Require"] := need
                            row["VerifyBlack"] := vb
                            Logger_Debug("Opener", "Map Watch SkillIndex→SkillId", row)
                        } catch {
                        }
                    }
                    i := i + 1
                }
            }
        } catch {
        }
        try {
            op["Watch"] := wArr
        } catch {
        }

        sArr := []
        try {
            if (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) {
                i := 1
                while (i <= cfg.Opener.Steps.Length) {
                    st0 := cfg.Opener.Steps[i]
                    kind := ""
                    try {
                        kind := OM_Get(st0, "Kind", "Skill")
                    } catch {
                        kind := "Skill"
                    }
                    kU := ""
                    try {
                        kU := StrUpper(kind)
                    } catch {
                        kU := "SKILL"
                    }
                    if (kU = "SKILL") {
                        si := 0
                        try {
                            si := OM_Get(st0, "SkillIndex", 0)
                        } catch {
                            si := 0
                        }
                        sid := 0
                        try {
                            if (skIdByIdx.Has(si)) {
                                sid := skIdByIdx[si]
                            } else {
                                sid := 0
                            }
                        } catch {
                            sid := 0
                        }
                        ns := Map()
                        try {
                            ns["Kind"] := "Skill"
                            ns["SkillId"] := sid
                            ns["RequireReady"] := OM_Get(st0, "RequireReady", 0)
                            ns["PreDelayMs"] := OM_Get(st0, "PreDelayMs", 0)
                            ns["HoldMs"] := OM_Get(st0, "HoldMs", 0)
                            ns["Verify"] := OM_Get(st0, "Verify", 0)
                            ns["TimeoutMs"] := OM_Get(st0, "TimeoutMs", 1200)
                            ns["DurationMs"] := OM_Get(st0, "DurationMs", 0)
                        } catch {
                        }
                        sArr.Push(ns)
                        if (dbgOp) {
                            rowS := Map()
                            try {
                                rowS["StepIdx"] := i
                                rowS["Kind"] := "Skill"
                                rowS["SkillIndex"] := si
                                rowS["SkillId"] := sid
                                Logger_Debug("Opener", "Map Step SkillIndex→SkillId", rowS)
                            } catch {
                            }
                        }
                    } else if (kU = "WAIT") {
                        ns := Map()
                        try {
                            ns["Kind"] := "Wait"
                            ns["DurationMs"] := OM_Get(st0, "DurationMs", 0)
                        } catch {
                        }
                        sArr.Push(ns)
                    } else if (kU = "SWAP") {
                        ns := Map()
                        try {
                            ns["Kind"] := "Swap"
                            ns["TimeoutMs"] := OM_Get(st0, "TimeoutMs", 800)
                            ns["Retry"] := OM_Get(st0, "Retry", 0)
                        } catch {
                        }
                        sArr.Push(ns)
                    } else {
                        ns := Map()
                        try {
                            ns["Kind"] := "Wait"
                            ns["DurationMs"] := 0
                        } catch {
                        }
                        sArr.Push(ns)
                    }
                    i := i + 1
                }
            }
        } catch {
        }
        try {
            op["Steps"] := sArr
        } catch {
        }

        try {
            if !(p.Has("Rotation")) {
                p["Rotation"] := Map()
            }
        } catch {
        }
        try {
            p["Rotation"]["Opener"] := op
        } catch {
            p["Rotation"] := Map("Opener", op)
        }

        ok := false
        try {
            SaveModule_Opener(p)
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
            Counters_Init()
        } catch {
        }
        try {
            RE_OnProfileDataReplaced(App["ProfileData"])
        } catch {
        }
        try {
            WorkerPool_Rebuild()
        } catch {
        }
        try {
            Rotation_Reset()
            Rotation_InitFromProfile()
        } catch {
        }

        try {
            REUI_Opener_FillWatch(lvOW, App["ProfileData"].Rotation)
        } catch {
        }
        try {
            REUI_Opener_FillSteps(lvS, App["ProfileData"].Rotation)
        } catch {
        }

        Notify("起手已保存")
    }

    return { Save: () => 0 }
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
; ============ 监视编辑器（前置定义，避免 #Warn） ============
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

; ============ 调用者（保持不变） ============
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