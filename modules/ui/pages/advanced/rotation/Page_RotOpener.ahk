#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"
#Include "..\..\..\rotation\RE_UI_Page_Opener.ahk"

; 轮换配置 - 起手页（嵌入主界面，绝对布局 + 运行时获取 cfg，模块化保存）
Page_RotOpener_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if !IsSet(App) || !App.Has("ProfileData") {
        UI.RO_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        try {
            page.Controls.Push(UI.RO_Empty)
        } catch {
        }
        return
    }

    cfg := Page_RotOpener_GetCfg()

    UI.RO_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w160", rc.X, rc.Y + 8), "启用起手")
    try {
        page.Controls.Push(UI.RO_cbEnable)
    } catch {
    }

    UI.RO_labMax := UI.Main.Add("Text", Format("x{} y{} w110 Right", rc.X, rc.Y + 44), "最大时长(ms)：")
    UI.RO_edMax  := UI.Main.Add("Edit",  "x+6 w120 Number Center")
    try {
        page.Controls.Push(UI.RO_labMax)
        page.Controls.Push(UI.RO_edMax)
    } catch {
    }

    UI.RO_labThr := UI.Main.Add("Text", "x+20 w80 Right", "线程：")
    UI.RO_ddThr  := UI.Main.Add("DropDownList", "x+6 w200")
    try {
        page.Controls.Push(UI.RO_labThr)
        page.Controls.Push(UI.RO_ddThr)
    } catch {
    }

    UI.RO_labW := UI.Main.Add("Text", Format("x{} y{}", rc.X, rc.Y + 86), "Watch（技能计数/黑框确认）：")
    try {
        page.Controls.Push(UI.RO_labW)
    } catch {
    }

    listW := Max(560, rc.W - 84 - 8 - 20)
    UI.RO_lvW := UI.Main.Add("ListView", Format("x{} y{} w{} r7 +Grid", rc.X, rc.Y + 108, listW), ["技能","Require","VerifyBlack"])
    try {
        page.Controls.Push(UI.RO_lvW)
    } catch {
    }

    UI.RO_btnWAdd  := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnWEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnWDel  := UI.Main.Add("Button", "w84", "删除")
    for ctl in [UI.RO_btnWAdd, UI.RO_btnWEdit, UI.RO_btnWDel] {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    UI.RO_labS := UI.Main.Add("Text", "w200", "Steps（按序执行）：")
    try {
        page.Controls.Push(UI.RO_labS)
    } catch {
    }

    UI.RO_lvS := UI.Main.Add("ListView", "w700 r8 +Grid"
        , ["序","类型","详情","就绪","预延时","按住","验证","超时","时长"])
    try {
        page.Controls.Push(UI.RO_lvS)
    } catch {
    }

    UI.RO_btnSAdd  := UI.Main.Add("Button", "w84", "新增")
    UI.RO_btnSEdit := UI.Main.Add("Button", "w84", "编辑")
    UI.RO_btnSDel  := UI.Main.Add("Button", "w84", "删除")
    UI.RO_btnSUp   := UI.Main.Add("Button", "w84", "上移")
    UI.RO_btnSDn   := UI.Main.Add("Button", "w84", "下移")
    for ctl in [UI.RO_btnSAdd, UI.RO_btnSEdit, UI.RO_btnSDel, UI.RO_btnSUp, UI.RO_btnSDn] {
        try {
            page.Controls.Push(ctl)
        } catch {
        }
    }

    UI.RO_btnSave := UI.Main.Add("Button", "w120", "保存起手")
    try {
        page.Controls.Push(UI.RO_btnSave)
    } catch {
    }

    Page_RotOpener_Refresh()

    UI.RO_btnWAdd.OnEvent("Click", Page_RotOpener_OnWAdd)
    UI.RO_btnWEdit.OnEvent("Click", Page_RotOpener_OnWEdit)
    UI.RO_btnWDel.OnEvent("Click", Page_RotOpener_OnWDel)
    UI.RO_lvW.OnEvent("DoubleClick", Page_RotOpener_OnWEdit)

    UI.RO_btnSAdd.OnEvent("Click", Page_RotOpener_OnSAdd)
    UI.RO_btnSEdit.OnEvent("Click", Page_RotOpener_OnSEdit)
    UI.RO_btnSDel.OnEvent("Click", Page_RotOpener_OnSDel)
    UI.RO_btnSUp.OnEvent("Click", (*) => Page_RotOpener_OnSMove(-1))
    UI.RO_btnSDn.OnEvent("Click", (*) => Page_RotOpener_OnSMove(1))
    UI.RO_lvS.OnEvent("DoubleClick", Page_RotOpener_OnSEdit)

    UI.RO_btnSave.OnEvent("Click", Page_RotOpener_OnSave)
}

Page_RotOpener_Layout(rc) {
    try {
        x := rc.X
        y := rc.Y

        btnW := 84
        gap  := 8
        minW := 560
        listW := Max(minW, rc.W - btnW - gap - 20)

        UI_MoveSafe(UI.RO_labW, x, y + 86)
        UI.RO_lvW.Move(x, y + 108, listW)
        UI.RO_lvW.GetPos(&lx, &ly, &lw, &lh)
        btnX := lx + lw + gap
        UI_MoveSafe(UI.RO_btnWAdd,  btnX, ly)
        UI_MoveSafe(UI.RO_btnWEdit, btnX, ly + 34)
        UI_MoveSafe(UI.RO_btnWDel,  btnX, ly + 68)

        stepsLabelY := ly + lh + 16
        UI_MoveSafe(UI.RO_labS, x, stepsLabelY)

        UI.RO_lvS.Move(x, stepsLabelY + 16, listW, rc.Y + rc.H - (stepsLabelY + 16) - 56)
        UI.RO_lvS.GetPos(&sx, &sy, &sw, &sh)
        UI_MoveSafe(UI.RO_btnSAdd,  btnX, sy)
        UI_MoveSafe(UI.RO_btnSEdit, btnX, sy + 34)
        UI_MoveSafe(UI.RO_btnSDel,  btnX, sy + 68)
        UI_MoveSafe(UI.RO_btnSUp,   btnX, sy + 102)
        UI_MoveSafe(UI.RO_btnSDn,   btnX, sy + 136)

        UI_MoveSafe(UI.RO_btnSave, x, rc.Y + rc.H - 36)
    } catch {
    }
}

Page_RotOpener_OnEnter(*) {
    Page_RotOpener_Refresh()
}

Page_RotOpener_GetCfg() {
    global App
    if !IsSet(App) || !App.Has("ProfileData") {
        return {}
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    try {
        REUI_EnsureRotationDefaults(&cfg)
        REUI_Opener_Ensure(&cfg)
        prof.Rotation := cfg
    } catch {
    }
    return cfg
}

Page_RotOpener_Refresh() {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if !IsObject(cfg) {
        return
    }
    try {
        UI.RO_cbEnable.Value := cfg.Opener.Enabled ? 1 : 0
    } catch {
    }
    try {
        UI.RO_edMax.Value := HasProp(cfg.Opener,"MaxDurationMs") ? cfg.Opener.MaxDurationMs : 4000
    } catch {
    }
    Page_RotOpener_FillThreads(cfg)
    REUI_Opener_FillWatch(UI.RO_lvW, cfg)
    REUI_Opener_FillSteps(UI.RO_lvS, cfg)
}

Page_RotOpener_FillThreads(cfg) {
    global UI, App

    try {
        DllCall("user32\SendMessageW", "ptr", UI.RO_ddThr.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)
    } catch {
    }

    thrNames := []
    thrIds   := []
    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")
            && IsObject(App["ProfileData"].Threads) && App["ProfileData"].Threads.Length) {
            for _, th in App["ProfileData"].Threads {
                try {
                    if (HasProp(th, "Name") && HasProp(th, "Id")) {
                        thrNames.Push(th.Name)
                        thrIds.Push(th.Id)
                    }
                } catch {
                }
            }
        }
    } catch {
    }
    if (thrNames.Length = 0) {
        thrNames := ["默认线程"]
        thrIds   := [1]
    }
    try {
        UI.RO_thrIds := thrIds
        UI.RO_ddThr.Add(thrNames)
    } catch {
    }
    curTid := 1
    try {
        curTid := HasProp(cfg.Opener,"ThreadId") ? cfg.Opener.ThreadId : 1
    } catch {
        curTid := 1
    }
    pos := 1
    i := 1
    while (i <= UI.RO_thrIds.Length) {
        v := 0
        try {
            v := UI.RO_thrIds[i]
        } catch {
            v := 0
        }
        if (v = curTid) {
            pos := i
            break
        }
        i := i + 1
    }
    try {
        UI.RO_ddThr.Value := pos
        UI.RO_ddThr.Enabled := true
    } catch {
    }
}

Page_RotOpener_OnWAdd(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchAdd(UI.Main, cfg, UI.RO_lvW)
    }
}
Page_RotOpener_OnWEdit(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchEdit(UI.Main, cfg, UI.RO_lvW)
    }
}
Page_RotOpener_OnWDel(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_WatchDel(cfg, UI.RO_lvW)
    }
}

Page_RotOpener_OnSAdd(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepAdd(UI.Main, cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSEdit(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepEdit(UI.Main, cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSDel(*) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepDel(cfg, UI.RO_lvS)
    }
}
Page_RotOpener_OnSMove(dir) {
    global UI
    cfg := Page_RotOpener_GetCfg()
    if IsObject(cfg) {
        REUI_Opener_StepMove(cfg, UI.RO_lvS, dir)
    }
}

; 模块化保存（索引→稳定 Id），写 rotation_opener.ini
Page_RotOpener_OnSave(*) {
    global UI, App
    if !IsSet(App) || !App.Has("ProfileData") {
        MsgBox "未加载配置，无法保存。"
        return
    }

    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    REUI_Opener_Ensure(&cfg)

    cfg.Opener.Enabled := UI.RO_cbEnable.Value ? 1 : 0
    cfg.Opener.MaxDurationMs := 4000
    try {
        if (UI.RO_edMax.Value != "") {
            cfg.Opener.MaxDurationMs := Integer(UI.RO_edMax.Value)
        }
    } catch {
        cfg.Opener.MaxDurationMs := 4000
    }

    if (HasProp(UI, "RO_thrIds") && IsObject(UI.RO_thrIds) && UI.RO_thrIds.Length >= 1) {
        idx := 1
        try {
            idx := UI.RO_ddThr.Value
        } catch {
            idx := 1
        }
        if (idx >= 1 && idx <= UI.RO_thrIds.Length) {
            cfg.Opener.ThreadId := UI.RO_thrIds[idx]
        } else {
            cfg.Opener.ThreadId := 1
        }
    } else {
        cfg.Opener.ThreadId := 1
    }

    cfg.Opener.StepsCount := 0
    try {
        if (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) {
            cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        } else {
            cfg.Opener.StepsCount := 0
        }
    } catch {
        cfg.Opener.StepsCount := 0
    }

    prof.Rotation := cfg

    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置，无法保存。"
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
            Logger_Debug("Opener", "Page_RotOpener_OnSave begin", f0)
        } catch {
        }
    }

    ; 索引→Id 映射表
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

    ; 运行时 cfg（索引）→ 文件夹模型（Id）
    op := Map()
    try {
        op["Enabled"] := OM_Get(cfg.Opener, "Enabled", 0)
        op["MaxDurationMs"] := OM_Get(cfg.Opener, "MaxDurationMs", 4000)
        op["ThreadId"] := OM_Get(cfg.Opener, "ThreadId", 1)
    } catch {
    }

    ; Watch
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

    ; Steps
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

    ; 重载 → 规范化 → 重建
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

    Page_RotOpener_Refresh()
    Notify("起手已保存")
}