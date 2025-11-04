#Requires AutoHotkey v2
; GUI_RotationEditor.ahk
; Rotation 全量配置编辑器（General + Tracks + Gates + Opener 分页）
; 本文件分4段发送，全部粘贴完毕后再运行
; 放在 modules\ui\dialogs\GUI_RotationEditor.ahk 顶部（函数外）
; 简单日志：Logs\ui_rotation_editor.log
REd_Log(msg) {
    try {
        DirCreate(A_ScriptDir "\Logs")
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [RotationUI] " msg "`r`n"
        , A_ScriptDir "\Logs\ui_rotation_editor.log", "UTF-8")
    }
}

; 便捷：输出 UI.Main 状态
REd_DumpUIState(tag := "state") {
    okSet := IsSet(UI)
    okObj := (okSet && IsObject(UI))
    hasM := (okObj && UI.Has("Main"))
    hwnd := 0
    try hwnd := (hasM && UI.Main) ? UI.Main.Hwnd : 0
    REd_Log(tag " IsSet=" okSet " IsObj=" okObj " HasMain=" hasM " Hwnd=" hwnd)
}
RotationEditor_Show() {
    global UI, App
    if !IsObject(App) || !App.Has("ProfileData") {
        MsgBox "Profile 未加载"
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation")
        prof.Rotation := {}

    cfg := prof.Rotation
    ; 默认字段兜底（逐项写法，便于维护）
    if !HasProp(cfg, "Enabled") cfg.Enabled := 0
        if !HasProp(cfg, "DefaultTrackId") cfg.DefaultTrackId := 1
            if !HasProp(cfg, "BusyWindowMs") cfg.BusyWindowMs := 200
                if !HasProp(cfg, "ColorTolBlack") cfg.ColorTolBlack := 16
                    if !HasProp(cfg, "RespectCastLock") cfg.RespectCastLock := 1
                        if !HasProp(cfg, "SwapKey") cfg.SwapKey := ""
                            if !HasProp(cfg, "VerifySwap") cfg.VerifySwap := 0
                                if !HasProp(cfg, "SwapTimeoutMs") cfg.SwapTimeoutMs := 800
                                    if !HasProp(cfg, "SwapRetry") cfg.SwapRetry := 0
                                        if !HasProp(cfg, "GatesEnabled") cfg.GatesEnabled := 0
                                            if !HasProp(cfg, "GateCooldownMs") cfg.GateCooldownMs := 0
                                                if !HasProp(cfg, "BlackGuard") cfg.BlackGuard := {
                                                    Enabled: 1,
                                                    SampleCount: 5, BlackRatioThresh: 0.7,
                                                    WindowMs: 120, CooldownMs: 600, MinAfterSendMs: 60,
                                                    MaxAfterSendMs: 800, UniqueRequired: 1
                                                }
                                                ; 主对话
                                                ; 在 RotationEditor_Show() 函数体“最开始”插入（或替换你创建 dlg 之前的全部内容）
                                                    REd_Log("ENTER RotationEditor_Show file=" A_LineFile)
    REd_DumpUIState("before-gui")
    ; 直接分支创建 GUI（不依赖中间变量）
    if (IsSet(UI) && IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd) {
        REd_Log("create dlg with owner=" UI.Main.Hwnd)
        dlg := Gui("+Owner" UI.Main.Hwnd, "Rotation 配置")
    } else {
        REd_Log("create dlg without owner")
        dlg := Gui(, "Rotation 配置")
    }
    REd_Log("dlg.hwnd=" dlg.Hwnd)

    dlg.MarginX := 12
    dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    tab := dlg.Add("Tab3", "xm ym w860 h520", ["常规", "轨道", "跳轨", "起手"])

    ; ===================== General =====================
    tab.UseTab(1)

    cbEnable := dlg.Add("CheckBox", "xm y+10 w160", "启用轮换")
    cbEnable.Value := cfg.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "默认轨道：")
    ddDefTrack := dlg.Add("DropDownList", "x+6 w160")
    trackIds := _REd_ListTrackIds(cfg)
    if trackIds.Length {
        ddDefTrack.Add(trackIds)
        pos := 1
        for i, v in trackIds
            if (Integer(v) = Integer(cfg.DefaultTrackId)) {
                pos := i
                break
            }
        ddDefTrack.Value := pos
    }

    dlg.Add("Text", "xm y+8 w100 Right", "忙窗(ms)：")
    edBusy := dlg.Add("Edit", "x+6 w120 Number Center", cfg.BusyWindowMs)

    dlg.Add("Text", "x+20 w110 Right", "黑色容差：")
    edTol := dlg.Add("Edit", "x+6 w120 Number Center", cfg.ColorTolBlack)

    cbCast := dlg.Add("CheckBox", "xm y+8 w200", "尊重施法锁")
    cbCast.Value := cfg.RespectCastLock ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "切换键：")
    hkSwap := dlg.Add("Hotkey", "x+6 w160", cfg.SwapKey)
    cbVerifySwap := dlg.Add("CheckBox", "x+12 w120", "验证切换")
    cbVerifySwap.Value := cfg.VerifySwap ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "切换超时(ms)：")
    edSwapTO := dlg.Add("Edit", "x+6 w120 Number Center", cfg.SwapTimeoutMs)
    dlg.Add("Text", "x+20 w100 Right", "重试次数：")
    edSwapRetry := dlg.Add("Edit", "x+6 w120 Number Center", cfg.SwapRetry)

    cbGates := dlg.Add("CheckBox", "xm y+8 w200", "启用跳轨(Gates)")
    cbGates.Value := cfg.GatesEnabled ? 1 : 0
    dlg.Add("Text", "x+12 w100 Right", "跳轨冷却(ms)：")
    edGateCd := dlg.Add("Edit", "x+6 w120 Number Center", cfg.GateCooldownMs)

    ; 黑框防抖
    gb := dlg.Add("GroupBox", "xm y+12 w820 h150", "黑框防抖")
    cbBG := dlg.Add("CheckBox", "xp+12 yp+26 w80", "启用")
    cbBG.Value := cfg.BlackGuard.Enabled ? 1 : 0
    dlg.Add("Text", "x+10 w70 Right", "采样数：")
    edBG_Samp := dlg.Add("Edit", "x+6 w80 Number Center", cfg.BlackGuard.SampleCount)

    dlg.Add("Text", "x+16 w110 Right", "黑像素阈值：")
    ratio := Round(HasProp(cfg.BlackGuard, "BlackRatioThresh") ? cfg.BlackGuard.BlackRatioThresh : 0.7, 2)
    edBG_Ratio := dlg.Add("Edit", "x+6 w100 Center", ratio)

    dlg.Add("Text", "x+16 w100 Right", "冻结窗(ms)：")
    edBG_Win := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.WindowMs)

    dlg.Add("Text", "xm y+10 w100 Right", "冷却(ms)：")
    edBG_Cool := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.CooldownMs)

    dlg.Add("Text", "x+16 w120 Right", "黑窗最小延迟(ms)：")
    edBG_Min := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.MinAfterSendMs)

    dlg.Add("Text", "x+16 w120 Right", "黑窗最大延迟(ms)：")
    edBG_Max := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.MaxAfterSendMs)

    cbBG_Uniq := dlg.Add("CheckBox", "x+16 w140", "需要唯一黑框")
    cbBG_Uniq.Value := cfg.BlackGuard.UniqueRequired ? 1 : 0
    ; ----------------- 工具函数：根据当前配置列出轨道 Id -----------------
    _REd_ListTrackIds(cfgObj) {
        ids := []
        try {
            if HasProp(cfgObj, "Tracks") && IsObject(cfgObj.Tracks) && cfgObj.Tracks.Length > 0 {
                for _, t in cfgObj.Tracks
                    ids.Push(t.Id)
                return ids
            }
        }
        ; 回退 Track1/Track2
        ids.Push(1), ids.Push(2)
        return ids
    }
    ; ===================== Tracks =====================
    tab.UseTab(2)

    ;轨道页
    lvTracks := dlg.Add("ListView", "xm y+8 w820 r12 +Grid"
        , ["ID", "名称", "线程", "最长ms", "最短停留", "下一轨", "Watch#", "规则#"])
    btnTrAdd := dlg.Add("Button", "xm y+8 w90", "新增")
    btnTrEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnTrDel := dlg.Add("Button", "x+8 w90", "删除")
    btnTrUp := dlg.Add("Button", "x+8 w90", "上移")
    btnTrDn := dlg.Add("Button", "x+8 w90", "下移")
    btnTrSave := dlg.Add("Button", "x+20 w110", "保存轨道")

    _REd_EnsureTracks()
    _REd_FillTracks()

    lvTracks.OnEvent("DoubleClick", (*) => _REd_EditSel())
    btnTrAdd.OnEvent("Click", (*) => _REd_Add())
    btnTrEdit.OnEvent("Click", (*) => _REd_EditSel())
    btnTrDel.OnEvent("Click", (*) => _REd_Del())
    btnTrUp.OnEvent("Click", (*) => _REd_Move(-1))
    btnTrDn.OnEvent("Click", (*) => _REd_Move(1))
    btnTrSave.OnEvent("Click", (*) => _REd_SaveTracks())

    ; --------- Tracks helpers ---------
    _REd_EnsureTracks() {
        ; 若 Tracks 为空，尝试从 Track1/Track2 导入一份初始数据
        try {
            if !(HasProp(cfg, "Tracks") && IsObject(cfg.Tracks)) {
                cfg.Tracks := []
            }
            if (cfg.Tracks.Length = 0) {
                if HasProp(cfg, "Track1")
                    cfg.Tracks.Push(cfg.Track1)
                if HasProp(cfg, "Track2")
                    cfg.Tracks.Push(cfg.Track2)
                ; 若仍为空，创建一条默认轨
                if (cfg.Tracks.Length = 0) {
                    cfg.Tracks.Push({ Id: 1, Name: "轨道1", ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0,
                        Watch: [], RuleRefs: [] })
                }
            }
        } catch {
        }
    }

    _REd_FillTracks() {
        lvTracks.Opt("-Redraw")
        lvTracks.Delete()
        for _, t in cfg.Tracks {
            thName := _REd_ThreadNameById(HasProp(t, "ThreadId") ? t.ThreadId : 1)
            wCnt := (HasProp(t, "Watch") && IsObject(t.Watch)) ? t.Watch.Length : 0
            rCnt := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
            lvTracks.Add("", HasProp(t, "Id") ? t.Id : 0
            , HasProp(t, "Name") ? t.Name : ""
            , thName
            , HasProp(t, "MaxDurationMs") ? t.MaxDurationMs : 0
            , HasProp(t, "MinStayMs") ? t.MinStayMs : 0
            , HasProp(t, "NextTrackId") ? t.NextTrackId : 0
            , wCnt, rCnt)
        }
        loop 8
            lvTracks.ModifyCol(A_Index, "AutoHdr")
        lvTracks.Opt("+Redraw")
        _REd_RefreshDefaultTrackDD()  ; Tracks 变化后刷新 General 页的 DefaultTrackId 下拉
    }

    _REd_ThreadNameById(id) {
        global App
        try {
            for _, th in App["ProfileData"].Threads
                if (th.Id = id)
                    return th.Name
        } catch {
        }
        return (id = 1) ? "默认线程" : "线程#" id
    }

    _REd_Add() {
        ; 分配新 Id = 当前最大 Id + 1
        newId := 1
        try {
            maxId := 0
            for _, t in cfg.Tracks
                maxId := Max(maxId, HasProp(t, "Id") ? Integer(t.Id) : 0)
            newId := maxId + 1
        }
        tr := { Id: newId, Name: "轨道" newId, ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [],
            RuleRefs: [] }
        _REd_OpenTrackEditor(tr, 0, (saved, idx) => (
            cfg.Tracks.Push(saved),
            _REd_FillTracks()
        ))
    }

    _REd_EditSel() {
        row := lvTracks.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一条轨道"
            return
        }
        idx := row
        if (idx < 1 || idx > cfg.Tracks.Length)
            return
        cur := cfg.Tracks[idx]
        _REd_OpenTrackEditor(cur, idx, (saved, i) => (
            cfg.Tracks[i] := saved,
            _REd_FillTracks()
        ))
    }

    _REd_Move(dir) {
        row := lvTracks.GetNext(0, "Focused")
        if !row
            return
        from := row, to := from + dir
        if (to < 1 || to > cfg.Tracks.Length)
            return
        item := cfg.Tracks[from]
        cfg.Tracks.RemoveAt(from)
        cfg.Tracks.InsertAt(to, item)
        _REd_FillTracks()
        lvTracks.Modify(to, "Select Focus Vis")
    }

    _REd_Del() {
        if (cfg.Tracks.Length <= 1) {
            MsgBox "至少保留一条轨道"
            return
        }
        row := lvTracks.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一条轨道"
            return
        }
        idx := row
        delId := HasProp(cfg.Tracks[idx], "Id") ? cfg.Tracks[idx].Id : 0
        cfg.Tracks.RemoveAt(idx)
        ; 若 DefaultTrackId 指向被删轨，回退到第一条
        try {
            ids := _REd_ListTrackIds(cfg)
            if !(ids.IndexOf(delId)) {
                cfg.DefaultTrackId := Integer(ids[1])
            }
        }
        _REd_FillTracks()
        Notify("已删除轨道")
    }

    _REd_SaveTracks() {
        prof.Rotation := cfg
        Storage_SaveProfile(prof)
        Notify("Tracks 已保存")
    }

    _REd_RefreshDefaultTrackDD() {
        try {
            ids := _REd_ListTrackIds(cfg)
            ddDefTrack.Delete()
            if ids.Length
                ddDefTrack.Add(ids)
            ; 尝试选中当前 DefaultTrackId
            pos := 1
            for i, v in ids
                if (Integer(v) = Integer(cfg.DefaultTrackId)) {
                    pos := i
                    break
                }
            ddDefTrack.Value := pos
        } catch {
        }
    }

    ; 替换 GUI_RotationEditor.ahk 中的 _REd_OpenTrackEditor 函数为下方版本
    _REd_OpenTrackEditor(t, idx := 0, onSaved := 0) {
        isNew := (idx = 0)
        if !IsObject(t)
            t := {}
        ; 默认字段
        defaults := Map("Id", 1, "Name", "轨道", "ThreadId", 1, "MaxDurationMs", 8000, "MinStayMs", 0, "NextTrackId", 0)
        for k, v in defaults
            if !HasProp(t, k)
                t.%k% := v
        if !HasProp(t, "Watch")
            t.Watch := []
        if !HasProp(t, "RuleRefs")
            t.RuleRefs := []

        g := Gui("+Owner" dlg.Hwnd, isNew ? "新增轨道" : "编辑轨道")
        g.MarginX := 12, g.MarginY := 10
        g.SetFont("s10", "Segoe UI")

        ; 行1：ID
        g.Add("Text", "xm ym w70 Right", "ID：")
        edId := g.Add("Edit", "x+6 w100 ReadOnly", t.Id)

        ; 行2：名称 + 线程
        g.Add("Text", "xm y+8 w70 Right", "名称：")
        edName := g.Add("Edit", "x+6 w220", t.Name)

        g.Add("Text", "x+20 w50 Right", "线程：")
        ddThr := g.Add("DropDownList", "x+6 w200")
        thNames := [], thIds := []
        try {
            for _, th in App["ProfileData"].Threads {
                thNames.Push(th.Name), thIds.Push(th.Id)
            }
        }
        if thNames.Length
            ddThr.Add(thNames)
        sel := 1
        for i, id in thIds
            if (id = t.ThreadId) {
                sel := i
                break
            }
        ddThr.Value := sel

        ; 行3：最长/最短停留
        g.Add("Text", "xm y+8 w70 Right", "最长(ms)：")
        edMax := g.Add("Edit", "x+6 w120 Number Center", t.MaxDurationMs)

        g.Add("Text", "x+20 w90 Right", "最短停留(ms)：")
        edMin := g.Add("Edit", "x+6 w120 Number Center", HasProp(t, "MinStayMs") ? t.MinStayMs : 0)

        ; 行4：下一轨
        g.Add("Text", "xm y+8 w70 Right", "下一轨：")
        ddNext := g.Add("DropDownList", "x+6 w160")
        ids := []
        for _, tx in cfg.Tracks
            ids.Push(tx.Id)
        if (isNew) {
            if (ids.Length = 0 || ids[ids.Length] != t.Id)
                ids.Push(t.Id)
        }
        arrNext := ["0"]
        for _, id in ids
            arrNext.Push(id)
        if arrNext.Length
            ddNext.Add(arrNext)
        nextSel := 1
        allNext := arrNext
        for i, v in allNext
            if (Integer(v) = Integer(HasProp(t, "NextTrackId") ? t.NextTrackId : 0)) {
                nextSel := i
                break
            }
        ddNext.Value := nextSel

        ; 行5：Watch 标题
        labWatch := g.Add("Text", "xm y+10", "Watch（技能计数/黑框确认）：")

        ; 行6：Watch 列表 + 右侧竖排按钮
        lvW := g.Add("ListView", "xm w620 r8 +Grid", ["技能", "Require", "VerifyBlack"])
        btnWAdd := g.Add("Button", "x+10 yp w80", "新增")
        btnWEdit := g.Add("Button", "xp yp+34 w80", "编辑")
        btnWDel := g.Add("Button", "xp yp+34 w80", "删除")

        ; Watch 填充
        _FillW()
        lvW.OnEvent("DoubleClick", (*) => _W_Edit())
        btnWAdd.OnEvent("Click", (*) => _W_Add())
        btnWEdit.OnEvent("Click", (*) => _W_Edit())
        btnWDel.OnEvent("Click", (*) => _W_Del())

        ; 行7：规则集限制
        lvW.GetPos(&lvx, &lvy, &lvw, &lvh)
        yRule := lvy + lvh + 10
        labRule := g.Add("Text", Format("x{} y{} w100 Right", lvx, yRule), "规则集限制：")
        labRules := g.Add("Text", Format("x{} y{}", lvx + 100 + 6, yRule), _RulesLabel())
        btnRules := g.Add("Button", Format("x{} y{} w120", lvx + 100 + 6 + 180 + 10, yRule - 2), "选择规则...")
        btnRules.OnEvent("Click", (*) => _PickRules())

        ; 行8：底部按钮
        btnSave := g.Add("Button", Format("x{} y{} w100", lvx, yRule + 40), "保存")
        btnCancel := g.Add("Button", "x+8 w100", "取消")
        btnSave.OnEvent("Click", (*) => _Save())
        btnCancel.OnEvent("Click", (*) => g.Destroy())

        g.OnEvent("Close", (*) => g.Destroy())
        g.Show()

        ; ---------- 内部函数 ----------
        _FillW() {
            lvW.Opt("-Redraw")
            lvW.Delete()
            for _, w in t.Watch {
                sName := _NameOfSkill(HasProp(w, "SkillIndex") ? w.SkillIndex : 0)
                lvW.Add("", sName
                    , (HasProp(w, "RequireCount") ? w.RequireCount : 1)
                    , (HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0))
            }
            loop 3
                lvW.ModifyCol(A_Index, "AutoHdr")
            lvW.Opt("+Redraw")
        }

        _NameOfSkill(idx) {
            global App
            if (idx >= 1 && idx <= App["ProfileData"].Skills.Length)
                return App["ProfileData"].Skills[idx].Name
            return "技能#" idx
        }

        _W_Add() {
            w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
            _OpenWatchEditor(w, 0, (nw, i) => (
                t.Watch.Push(nw),
                _FillW()
            ))
        }
        _W_Edit() {
            row := lvW.GetNext(0, "Focused")
            if !row {
                MsgBox "请选择一条 Watch"
                return
            }
            w := t.Watch[row]
            _OpenWatchEditor(w, row, (nw, i) => (
                t.Watch[i] := nw,
                _FillW()
            ))
        }
        _W_Del() {
            row := lvW.GetNext(0, "Focused")
            if !row
                return
            t.Watch.RemoveAt(row)
            _FillW()
        }

        _RulesLabel() {
            cnt := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
            return "已选择规则数：" cnt
        }

        _PickRules() {
            rr := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Clone() : []
            _OpenRuleRefsPicker(rr, (sel) => (
                t.RuleRefs := sel,
                labRules.Text := _RulesLabel()
            ))
        }

        _Save() {
            name := Trim(edName.Value)
            if (name = "") {
                MsgBox "名称不可为空"
                return
            }
            t.Name := name
            t.ThreadId := (ddThr.Value >= 1 && ddThr.Value <= thIds.Length) ? thIds[ddThr.Value] : 1
            t.MaxDurationMs := (edMax.Value != "") ? Integer(edMax.Value) : 8000
            t.MinStayMs := (edMin.Value != "") ? Integer(edMin.Value) : 0
            if (ddNext.Value >= 1 && ddNext.Value <= allNext.Length)
                t.NextTrackId := Integer(allNext[ddNext.Value])
            else
                t.NextTrackId := 0

            if onSaved
                onSaved(t, (idx = 0 ? 0 : idx))
            g.Destroy()
            Notify(isNew ? "已新增轨道" : "已保存轨道")
        }
    }

    ; ---------- Watch Editor ----------
    _OpenWatchEditor(w, idx := 0, onSaved := 0) {
        if !IsObject(w)
            w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
        g2 := Gui("+Owner" . dlg.Hwnd, (idx = 0) ? "新增 Watch" : "编辑 Watch")
        g2.MarginX := 12, g2.MarginY := 10
        g2.SetFont("s10", "Segoe UI")

        g2.Add("Text", "w70", "技能：")
        ddS := g2.Add("DropDownList", "x+6 w260")
        names := []
        try for _, s in App["ProfileData"].Skills
            names.Push(s.Name)
        if names.Length
            ddS.Add(names)
        ddS.Value := Min(Max(HasProp(w, "SkillIndex") ? w.SkillIndex : 1, 1), Max(names.Length, 1))

        g2.Add("Text", "xm y+8 w80", "Require：")
        edReq := g2.Add("Edit", "x+6 w120 Number", HasProp(w, "RequireCount") ? w.RequireCount : 1)

        cbVB := g2.Add("CheckBox", "xm y+8", "VerifyBlack")
        cbVB.Value := HasProp(w, "VerifyBlack") ? (w.VerifyBlack ? 1 : 0) : 0

        btnOK := g2.Add("Button", "xm y+12 w90", "确定")
        btnCA := g2.Add("Button", "x+8 w90", "取消")
        btnOK.OnEvent("Click", (*) => _OK())
        btnCA.OnEvent("Click", (*) => g2.Destroy())
        g2.OnEvent("Close", (*) => g2.Destroy())

        g2.Show()

        _OK() {
            si := ddS.Value ? ddS.Value : 1
            req := (edReq.Value != "") ? Integer(edReq.Value) : 1
            vb := cbVB.Value ? 1 : 0
            nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
            if onSaved
                onSaved(nw, idx)
            g2.Destroy()
        }
    }

    ; ---------- RuleRefs 选择器 ----------
    _OpenRuleRefsPicker(curSel, onDone) {
        g3 := Gui("+Owner" . dlg.Hwnd, "选择规则（勾选）")
        g3.MarginX := 12, g3.MarginY := 10
        g3.SetFont("s10", "Segoe UI")

        lv := g3.Add("ListView", "xm w520 r12 +Grid +Checked", ["ID", "名称", "启用"])
        ; 填充规则
        try {
            for i, r in App["ProfileData"].Rules {
                row := lv.Add("", i, r.Name, (r.Enabled ? "√" : ""))
                ; 预勾选
                if (IsObject(curSel) && curSel.IndexOf(i))
                    lv.Modify(row, "Check")
            }
        }
        loop 3
            lv.ModifyCol(A_Index, "AutoHdr")

        btnOK := g3.Add("Button", "xm y+10 w90", "确定")
        btnCA := g3.Add("Button", "x+8 w90", "取消")
        btnOK.OnEvent("Click", (*) => _OK())
        btnCA.OnEvent("Click", (*) => g3.Destroy())
        g3.OnEvent("Close", (*) => g3.Destroy())

        g3.Show()

        _OK() {
            sel := []
            row := 0
            loop {
                row := lv.GetNext(row, "Checked")
                if (!row)
                    break
                id := Integer(lv.GetText(row, 1))
                sel.Push(id)
            }
            if onDone
                onDone(sel)
            g3.Destroy()
        }
    }
    ; ===================== Gates =====================
    tab.UseTab(3)

    ;跳轨页
    lvGates := dlg.Add("ListView", "xm y+8 w820 r12 +Grid", ["优先级", "目标轨", "逻辑", "条件数"])
    btnGAdd := dlg.Add("Button", "xm y+8 w90", "新增")
    btnGEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnGDel := dlg.Add("Button", "x+8 w90", "删除")
    btnGUp := dlg.Add("Button", "x+8 w90", "上移")
    btnGDn := dlg.Add("Button", "x+8 w90", "下移")
    btnGSave := dlg.Add("Button", "x+20 w110", "保存跳轨")

    _GEd_EnsureGates()
    _GEd_FillGates()

    lvGates.OnEvent("DoubleClick", (*) => _GEd_EditSel())
    btnGAdd.OnEvent("Click", (*) => _GEd_Add())
    btnGEdit.OnEvent("Click", (*) => _GEd_EditSel())
    btnGDel.OnEvent("Click", (*) => _GEd_Del())
    btnGUp.OnEvent("Click", (*) => _GEd_Move(-1))
    btnGDn.OnEvent("Click", (*) => _GEd_Move(1))
    btnGSave.OnEvent("Click", (*) => _GEd_SaveGates())

    ; ---------- Gates helpers ----------
    _GEd_EnsureGates() {
        try {
            if !(HasProp(cfg, "Gates") && IsObject(cfg.Gates))
                cfg.Gates := []
            ; 补齐字段
            for i, g in cfg.Gates {
                if !HasProp(g, "Priority")
                    g.Priority := i
                if !HasProp(g, "TargetTrackId")
                    g.TargetTrackId := 0
                if !HasProp(g, "Logic")
                    g.Logic := "AND"
                if !HasProp(g, "Conds") || !IsObject(g.Conds)
                    g.Conds := []
            }
            if (cfg.Gates.Length = 0) {
                cfg.Gates.Push({ Priority: 1, TargetTrackId: 0, Logic: "AND", Conds: [] })
            }
        } catch {
        }
    }
    _GEd_RenumPriority() {
        for i, g in cfg.Gates
            g.Priority := i
    }
    _GEd_ListTrackIds() {
        ; 复用 Tracks 页的工具（若无 Tracks，则回退 1/2）
        ids := _REd_ListTrackIds(cfg)
        return ids
    }
    _GEd_FillGates() {
        lvGates.Opt("-Redraw")
        lvGates.Delete()
        for _, g in cfg.Gates {
            tgt := HasProp(g, "TargetTrackId") ? g.TargetTrackId : 0
            lgc := HasProp(g, "Logic") ? g.Logic : "AND"
            cnt := (HasProp(g, "Conds") && IsObject(g.Conds)) ? g.Conds.Length : 0
            pri := HasProp(g, "Priority") ? g.Priority : 0
            lvGates.Add("", pri, tgt, lgc, cnt)
        }
        loop 4
            lvGates.ModifyCol(A_Index, "AutoHdr")
        lvGates.Opt("+Redraw")
    }
    _GEd_Add() {
        pri := cfg.Gates.Length + 1
        g := { Priority: pri, TargetTrackId: 0, Logic: "AND", Conds: [] }
        _GEd_OpenGateEditor(g, 0, (ng, idx) => (
            cfg.Gates.Push(ng),
            _GEd_RenumPriority(),
            _GEd_FillGates()
        ))
    }
    _GEd_EditSel() {
        row := lvGates.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个 Gate"
            return
        }
        idx := row
        if (idx < 1 || idx > cfg.Gates.Length)
            return
        cur := cfg.Gates[idx]
        _GEd_OpenGateEditor(cur, idx, (ng, i) => (
            cfg.Gates[i] := ng,
            _GEd_RenumPriority(),
            _GEd_FillGates()
        ))
    }
    _GEd_Move(dir) {
        row := lvGates.GetNext(0, "Focused")
        if !row
            return
        from := row, to := from + dir
        if (to < 1 || to > cfg.Gates.Length)
            return
        item := cfg.Gates[from]
        cfg.Gates.RemoveAt(from)
        cfg.Gates.InsertAt(to, item)
        _GEd_RenumPriority()
        _GEd_FillGates()
        lvGates.Modify(to, "Select Focus Vis")
    }
    _GEd_Del() {
        row := lvGates.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个 Gate"
            return
        }
        cfg.Gates.RemoveAt(row)
        _GEd_RenumPriority()
        _GEd_FillGates()
        Notify("已删除 Gate")
    }
    _GEd_SaveGates() {
        prof.Rotation := cfg
        Storage_SaveProfile(prof)
        Notify("Gates 已保存")
    }

    _GEd_OpenGateEditor(g, idx := 0, onSaved := 0) {
        isNew := (idx = 0)
        if !IsObject(g)
            g := {}
        if !HasProp(g, "Priority") g.Priority := (isNew ? (cfg.Gates.Length + 1) : idx)
            if !HasProp(g, "TargetTrackId") g.TargetTrackId := 0
                if !HasProp(g, "Logic") g.Logic := "AND"
                    if !HasProp(g, "Conds") g.Conds := []
                    ; Gate 编辑器
                        REd_Log("open GateEditor owner=" dlg.Hwnd)
        ge := Gui("+Owner" dlg.Hwnd, isNew ? "新增跳轨" : "编辑跳轨")
        ge.MarginX := 12, ge.MarginY := 10
        ge.SetFont("s10", "Segoe UI")

        ge.Add("Text", "w80 Right", "优先级：")
        edPri := ge.Add("Edit", "x+6 w120 Number", g.Priority)

        ge.Add("Text", "xm y+8 w100 Right", "目标轨：")
        ddTarget := ge.Add("DropDownList", "x+6 w160")
        trackIds := _GEd_ListTrackIds()
        arrTargets := ["0"]
        for _, id in trackIds
            arrTargets.Push(id)
        if arrTargets.Length
            ddTarget.Add(arrTargets)
        allTargets := arrTargets
        selT := 1
        for i, v in allTargets
            if (Integer(v) = Integer(g.TargetTrackId)) {
                selT := i
                break
            }
        ddTarget.Value := selT

        ge.Add("Text", "xm y+8 w70 Right", "逻辑：")
        ddLogic := ge.Add("DropDownList", "x+6 w120", ["AND", "OR"])
        ddLogic.Value := (StrUpper(g.Logic) = "OR") ? 2 : 1

        ge.Add("Text", "xm y+8", "条件：")
        lvC := ge.Add("ListView", "xm w760 r9 +Grid", ["类型", "摘要"])
        btnCAdd := ge.Add("Button", "xm y+8 w90", "新增")
        btnCEdit := ge.Add("Button", "x+8 w90", "编辑")
        btnCDel := ge.Add("Button", "x+8 w90", "删除")

        _FillC()

        lvC.OnEvent("DoubleClick", (*) => _C_Edit())
        btnCAdd.OnEvent("Click", (*) => _C_Add())
        btnCEdit.OnEvent("Click", (*) => _C_Edit())
        btnCDel.OnEvent("Click", (*) => _C_Del())

        btnSave := ge.Add("Button", "xm y+12 w100", "保存")
        btnCancel := ge.Add("Button", "x+8 w100", "取消")
        btnSave.OnEvent("Click", (*) => _Save())
        btnCancel.OnEvent("Click", (*) => ge.Destroy())
        ge.OnEvent("Close", (*) => ge.Destroy())
        ge.Show()

        _FillC() {
            lvC.Opt("-Redraw")
            lvC.Delete()
            for _, c in g.Conds {
                lvC.Add("", HasProp(c, "Kind") ? c.Kind : "?", _CondSummary(c))
            }
            loop 2
                lvC.ModifyCol(A_Index, "AutoHdr")
            lvC.Opt("+Redraw")
        }
        _CondSummary(c) {
            kind := HasProp(c, "Kind") ? StrUpper(c.Kind) : "?"
            if (kind = "PIXELREADY") {
                rt := HasProp(c, "RefType") ? c.RefType : "Skill"
                ri := HasProp(c, "RefIndex") ? c.RefIndex : 0
                opKey := StrUpper(HasProp(c, "Op") ? c.Op : "NEQ")
                opTxt := (opKey = "EQ") ? "等于" : "不等于"
                return "像素就绪 " rt "#" ri " " opTxt
            } else if (kind = "RULEQUIET") {
                rid := HasProp(c, "RuleId") ? c.RuleId : 0
                q := HasProp(c, "QuietMs") ? c.QuietMs : 0
                return "规则静默 规则#" rid " ≥" q "ms"
            } else if (kind = "COUNTER") {
                si := HasProp(c, "RefIndex") ? c.RefIndex : 0
                cmp := HasProp(c, "Cmp") ? c.Cmp : "GE"
                cmpTxt := (cmp = "GE") ? ">=" : (cmp = "EQ") ? "==" : (cmp = "GT") ? ">" : (cmp = "LE") ? "<=" : "<"
                v := HasProp(c, "Value") ? c.Value : 1
                return "计数 技能#" si " " cmpTxt " " v
            } else if (kind = "ELAPSED") {
                cmp := HasProp(c, "Cmp") ? c.Cmp : "GE"
                cmpTxt := (cmp = "GE") ? ">=" : (cmp = "EQ") ? "==" : (cmp = "GT") ? ">" : (cmp = "LE") ? "<=" : "<"
                ms := HasProp(c, "ElapsedMs") ? c.ElapsedMs : 0
                return "阶段用时 " cmpTxt " " ms "ms"
            }
            return "?"
        }
        _C_Add() {
            nc := {}
            _GEd_OpenCondEditor(nc, 0, (saved, i) => (
                g.Conds.Push(saved),
                _FillC()
            ))
        }
        _C_Edit() {
            row := lvC.GetNext(0, "Focused")
            if !row {
                MsgBox "请选择一个条件"
                return
            }
            cur := g.Conds[row]
            _GEd_OpenCondEditor(cur, row, (saved, idx2) => (
                g.Conds[idx2] := saved,
                _FillC()
            ))
        }
        _C_Del() {
            row := lvC.GetNext(0, "Focused")
            if !row
                return
            g.Conds.RemoveAt(row)
            _FillC()
        }
        _Save() {
            p := (edPri.Value != "") ? Integer(edPri.Value) : (idx = 0 ? 1 : idx)
            g.Priority := Max(1, p)
            tidx := ddTarget.Value ? ddTarget.Value : 1
            tgt := Integer(allTargets[tidx])
            g.TargetTrackId := tgt
            g.Logic := (ddLogic.Value = 2) ? "OR" : "AND"
            if onSaved
                onSaved(g, (idx = 0 ? 0 : idx))
            ge.Destroy()
            Notify(isNew ? "已新增跳轨" : "已保存跳轨")
        }
    }

    _GEd_OpenCondEditor(c, idx := 0, onSaved := 0) {
        if !IsObject(c)
            c := {}
        if !HasProp(c, "Kind")
            c.Kind := "PixelReady"

        ge2 := Gui("+Owner" . dlg.Hwnd, (idx = 0) ? "新增条件" : "编辑条件")
        ge2.MarginX := 12, ge2.MarginY := 10
        ge2.SetFont("s10", "Segoe UI")

        ge2.Add("Text", "w90 Right", "类型：")
        ddKind := ge2.Add("DropDownList", "x+6 w180", ["像素就绪", "规则静默", "计数", "阶段用时"])
        k := StrUpper(c.Kind)
        ddKind.Value := (k = "PIXELREADY") ? 1 : (k = "RULEQUIET") ? 2 : (k = "COUNTER") ? 3 : 4

        ; ----- PixelReady -----
        grpP1 := ge2.Add("Text", "xm y+10 w90 Right", "引用类型：")
        ddRefType := ge2.Add("DropDownList", "x+6 w140", ["技能", "点位"])
        ddRefType.Value := (StrUpper(HasProp(c, "RefType") ? c.RefType : "Skill") = "POINT") ? 2 : 1

        grpP2 := ge2.Add("Text", "xm y+8 w90 Right", "引用对象：")
        ddRefObj := ge2.Add("DropDownList", "x+6 w260")

        grpP3 := ge2.Add("Text", "xm y+8 w90 Right", "比较：")
        ddOp := ge2.Add("DropDownList", "x+6 w140", ["等于", "不等于"])
        ddOp.Value := (StrUpper(HasProp(c, "Op") ? c.Op : "NEQ") = "EQ") ? 1 : 2

        grpP4 := ge2.Add("Text", "xm y+8 w90 Right", "颜色：")
        edColor := ge2.Add("Edit", "x+6 w140", HasProp(c, "Color") ? c.Color : "0x000000")
        grpP5 := ge2.Add("Text", "x+14 w70 Right", "容差：")
        edTol := ge2.Add("Edit", "x+6 w90 Number", HasProp(c, "Tol") ? c.Tol : 16)
        btnAuto := ge2.Add("Button", "x+14 w110", "取引用颜色")

        ; ----- RuleQuiet -----
        grpR1 := ge2.Add("Text", "xm y+10 w90 Right", "规则：")
        ddRule := ge2.Add("DropDownList", "x+6 w260")
        grpR2 := ge2.Add("Text", "xm y+8 w90 Right", "静默(ms)：")
        edQuiet := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "QuietMs") ? c.QuietMs : 0)

        ; ----- Counter -----
        grpC1 := ge2.Add("Text", "xm y+10 w90 Right", "计数技能：")
        ddCSkill := ge2.Add("DropDownList", "x+6 w260")
        grpC2 := ge2.Add("Text", "xm y+8 w90 Right", "比较：")
        ddCCmp := ge2.Add("DropDownList", "x+6 w140", [">=", "==", ">", "<=", "<"])
        grpC3 := ge2.Add("Text", "xm y+8 w90 Right", "阈值：")
        edCVal := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "Value") ? c.Value : 1)
        ddCCmp.Value := (StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE") = "GE") ? 1 : (StrUpper(c.Cmp) = "EQ") ? 2 : (
            StrUpper(c.Cmp) = "GT") ? 3 : (StrUpper(c.Cmp) = "LE") ? 4 : (StrUpper(c.Cmp) = "LT") ? 5 : 1

        ; ----- Elapsed -----
        grpE1 := ge2.Add("Text", "xm y+10 w90 Right", "比较：")
        ddECmp := ge2.Add("DropDownList", "x+6 w140", [">=", "==", ">", "<=", "<"])
        grpE2 := ge2.Add("Text", "xm y+8 w90 Right", "用时(ms)：")
        edEMs := ge2.Add("Edit", "x+6 w140 Number", HasProp(c, "ElapsedMs") ? c.ElapsedMs : 0)
        ddECmp.Value := (StrUpper(HasProp(c, "Cmp") ? c.Cmp : "GE") = "GE") ? 1 : (StrUpper(c.Cmp) = "EQ") ? 2 : (
            StrUpper(c.Cmp) = "GT") ? 3 : (StrUpper(c.Cmp) = "LE") ? 4 : (StrUpper(c.Cmp) = "LT") ? 5 : 1

        btnOK := ge2.Add("Button", "xm y+12 w90", "确定")
        btnCA := ge2.Add("Button", "x+8 w90", "取消")
        btnOK.OnEvent("Click", (*) => _OK())
        btnCA.OnEvent("Click", (*) => ge2.Destroy())

        ddKind.OnEvent("Change", (*) => _toggle())
        ddRefType.OnEvent("Change", (*) => _fillRefObj())
        btnAuto.OnEvent("Click", (*) => _autoColor())
        ge2.OnEvent("Close", (*) => ge2.Destroy())

        _fillRules()
        _fillSkills()
        _fillRefObj()
        _toggle()
        ge2.Show()

        _toggle() {
            kcn := ddKind.Text
            ; 像素就绪
            for ctl in [grpP1, ddRefType, grpP2, ddRefObj, grpP3, ddOp, grpP4, edColor, grpP5, edTol, btnAuto]
                ctl.Visible := (kcn = "像素就绪")
            ; 规则静默
            for ctl in [grpR1, ddRule, grpR2, edQuiet]
                ctl.Visible := (kcn = "规则静默")
            ; 计数
            for ctl in [grpC1, ddCSkill, grpC2, ddCCmp, grpC3, edCVal]
                ctl.Visible := (kcn = "计数")
            ; 阶段用时
            for ctl in [grpE1, ddECmp, grpE2, edEMs]
                ctl.Visible := (kcn = "阶段用时")
        }
        ; 修复：_GEd_OpenCondEditor 内，当“引用类型=点位/技能/规则”为空时，DropDownList 赋值报错。
        ; 下面四个片段替换你现有的 _fillRefObj/_fillSkills/_fillRules/_toggle/_OK 对应部分。

        ; 1) 替换 _fillRefObj（像素就绪的“引用对象”下拉）
        _fillRefObj() {
            ddRefObj.Delete()
            if (ddRefType.Value = 2) { ; 点位
                cnt := 0
                try cnt := App["ProfileData"].Points.Length
                if (cnt > 0) {
                    names := []
                    for _, p in App["ProfileData"].Points
                        names.Push(p.Name)
                    ddRefObj.Add(names)
                    defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                    ddRefObj.Value := Min(Max(defIdx, 1), names.Length)
                    ddRefObj.Enabled := true
                } else {
                    ; 无点位时添加占位并禁用，避免 .Value 赋无效索引
                    ddRefObj.Add(["（无点位）"])
                    ddRefObj.Value := 1
                    ddRefObj.Enabled := false
                }
            } else { ; 技能
                cnt := 0
                try cnt := App["ProfileData"].Skills.Length
                if (cnt > 0) {
                    names := []
                    for _, s in App["ProfileData"].Skills
                        names.Push(s.Name)
                    ddRefObj.Add(names)
                    defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                    ddRefObj.Value := Min(Max(defIdx, 1), names.Length)
                    ddRefObj.Enabled := true
                } else {
                    ddRefObj.Add(["（无技能）"])
                    ddRefObj.Value := 1
                    ddRefObj.Enabled := false
                }
            }
        }
        ; 3) 替换 _fillRules（规则静默用的规则下拉，防止无规则时报错）
        _fillRules() {
            ddRule.Delete()
            cnt := 0
            try cnt := App["ProfileData"].Rules.Length
            if (cnt > 0) {
                names := []
                for i, r in App["ProfileData"].Rules
                    names.Push(i " - " r.Name)
                ddRule.Add(names)
                defIdx := HasProp(c, "RuleId") ? c.RuleId : 1
                ddRule.Value := Min(Max(defIdx, 1), names.Length)
                ddRule.Enabled := true
            } else {
                ddRule.Add(["（无规则）"])
                ddRule.Value := 1
                ddRule.Enabled := false
            }
        }
        ; 2) 替换 _fillSkills（计数条件用的技能下拉）
        _fillSkills() {
            ddCSkill.Delete()
            cnt := 0
            try cnt := App["ProfileData"].Skills.Length
            if (cnt > 0) {
                names := []
                for _, s in App["ProfileData"].Skills
                    names.Push(s.Name)
                ddCSkill.Add(names)
                defIdx := HasProp(c, "RefIndex") ? c.RefIndex : 1
                ddCSkill.Value := Min(Max(defIdx, 1), names.Length)
                ddCSkill.Enabled := true
            } else {
                ddCSkill.Add(["（无技能）"])
                ddCSkill.Value := 1
                ddCSkill.Enabled := false
            }
        }
        _autoColor() {
            if (ddRefType.Value = 2) { ; 点位
                idxP := ddRefObj.Value
                if (idxP >= 1 && idxP <= App["ProfileData"].Points.Length) {
                    p := App["ProfileData"].Points[idxP]
                    edColor.Value := p.Color
                    edTol.Value := p.Tol
                }
            } else { ; 技能
                idxS := ddRefObj.Value
                if (idxS >= 1 && idxS <= App["ProfileData"].Skills.Length) {
                    s := App["ProfileData"].Skills[idxS]
                    edColor.Value := s.Color
                    edTol.Value := s.Tol
                }
            }
        }
        _OK() {
            kcn := ddKind.Text
            kindKey := (kcn = "像素就绪") ? "PixelReady" : (kcn = "规则静默") ? "RuleQuiet" : (kcn = "计数") ? "Counter" :
                "Elapsed"

            if (kindKey = "PixelReady") {
                refType := (ddRefType.Value = 2) ? "Point" : "Skill"
                refIdx := ddRefObj.Value ? ddRefObj.Value : 1
                opKey := (ddOp.Value = 1) ? "EQ" : "NEQ"
                col := Trim(edColor.Value)
                tol := (edTol.Value != "") ? Integer(edTol.Value) : 16
                nc := { Kind: kindKey, RefType: refType, RefIndex: refIdx, Op: opKey, Color: col != "" ? col : "0x000000",
                    Tol: tol }
                if onSaved
                    onSaved(nc, idx)
            } else if (kindKey = "RuleQuiet") {
                rid := ddRule.Value ? ddRule.Value : 1
                qms := (edQuiet.Value != "") ? Integer(edQuiet.Value) : 0
                nc := { Kind: kindKey, RuleId: rid, QuietMs: qms }
                if onSaved
                    onSaved(nc, idx)
            } else if (kindKey = "Counter") {
                si := ddCSkill.Value ? ddCSkill.Value : 1
                cmpTxt := ddCCmp.Text
                cmpKey := (cmpTxt = ">=") ? "GE" : (cmpTxt = "==") ? "EQ" : (cmpTxt = ">") ? "GT" : (cmpTxt = "<=") ?
                    "LE" : "LT"
                v := (edCVal.Value != "") ? Integer(edCVal.Value) : 1
                nc := { Kind: kindKey, RefIndex: si, Cmp: cmpKey, Value: v }
                if onSaved
                    onSaved(nc, idx)
            } else { ; Elapsed
                cmpTxt := ddECmp.Text
                cmpKey := (cmpTxt = ">=") ? "GE" : (cmpTxt = "==") ? "EQ" : (cmpTxt = ">") ? "GT" : (cmpTxt = "<=") ?
                    "LE" : "LT"
                ms := (edEMs.Value != "") ? Integer(edEMs.Value) : 0
                nc := { Kind: kindKey, Cmp: cmpKey, ElapsedMs: ms }
                if onSaved
                    onSaved(nc, idx)
            }
            ge2.Destroy()
        }
    }
    ; ===================== Opener =====================
    tab.UseTab(4)

    _OEd_EnsureOpener()

    ; 顶部：启用/最大时长/线程
    cbOEnable := dlg.Add("CheckBox", "xm y+8 w160", "启用 Opener")
    cbOEnable.Value := cfg.Opener.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w110", "最大时长(ms)：")
    edOMax := dlg.Add("Edit", "x+6 w120 Number", HasProp(cfg.Opener, "MaxDurationMs") ? cfg.Opener.MaxDurationMs : 4000
    )

    dlg.Add("Text", "x+20 w80", "线程：")
    ddOThr := dlg.Add("DropDownList", "x+6 w200")
    oThrNames := [], oThrIds := []
    try {
        for _, th in App["ProfileData"].Threads
            oThrNames.Push(th.Name), oThrIds.Push(th.Id)
    }
    if oThrNames.Length
        ddOThr.Add(oThrNames)
    oSel := 1
    curOTid := HasProp(cfg.Opener, "ThreadId") ? cfg.Opener.ThreadId : 1
    for i, id in oThrIds
        if (id = curOTid) {
            oSel := i
            break
        }
    ddOThr.Value := oSel

    ; Watch 列表（与 Track Watch 语义一致）
    dlg.Add("Text", "xm y+12", "Watch（技能计数/黑框确认）：")
    lvOW := dlg.Add("ListView", "xm w680 r7 +Grid", ["技能", "Require", "VerifyBlack"])
    btnOWAdd := dlg.Add("Button", "x+10 w80", "新增")
    btnOWEdit := dlg.Add("Button", "x+8 w80", "编辑")
    btnOWDel := dlg.Add("Button", "x+8 w80", "删除")

    ; Steps 列表
    dlg.Add("Text", "xm y+12", "按序执行：")
    lvSteps := dlg.Add("ListView", "xm w820 r8 +Grid"
        , ["序", "类型", "详情", "就绪", "预延时", "按住", "验证", "超时", "时长"])
    btnSAdd := dlg.Add("Button", "xm y+8 w90", "新增")
    btnSEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnSDel := dlg.Add("Button", "x+8 w90", "删除")
    btnSUp := dlg.Add("Button", "x+8 w90", "上移")
    btnSDn := dlg.Add("Button", "x+8 w90", "下移")
    btnOSave := dlg.Add("Button", "x+20 w120", "保存起手")

    _OEd_FillWatch()
    _OEd_FillSteps()

    ; 事件
    lvOW.OnEvent("DoubleClick", (*) => _OEd_EditWatch())
    btnOWAdd.OnEvent("Click", (*) => _OEd_AddWatch())
    btnOWEdit.OnEvent("Click", (*) => _OEd_EditWatch())
    btnOWDel.OnEvent("Click", (*) => _OEd_DelWatch())

    lvSteps.OnEvent("DoubleClick", (*) => _OEd_EditStep())
    btnSAdd.OnEvent("Click", (*) => _OEd_AddStep())
    btnSEdit.OnEvent("Click", (*) => _OEd_EditStep())
    btnSDel.OnEvent("Click", (*) => _OEd_DelStep())
    btnSUp.OnEvent("Click", (*) => _OEd_MoveStep(-1))
    btnSDn.OnEvent("Click", (*) => _OEd_MoveStep(1))
    btnOSave.OnEvent("Click", (*) => _OEd_SaveOpener())

    ; 退出 Tab
    tab.UseTab()

    ; ===== 底部保存/关闭（保存 General + 其余页已各自有“保存”按钮）=====
    btnSave := dlg.Add("Button", "xm y+12 w110", "保存")
    btnClose := dlg.Add("Button", "x+8 w110", "关闭")
    btnSave.OnEvent("Click", OnSave)
    btnClose.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())

    dlg.Show()

    ; ---------- Opener helpers ----------
    _OEd_EnsureOpener() {
        if !HasProp(cfg, "Opener")
            cfg.Opener := {}
        op := cfg.Opener
        if !HasProp(op, "Enabled") op.Enabled := 0
            if !HasProp(op, "MaxDurationMs") op.MaxDurationMs := 4000
                if !HasProp(op, "ThreadId") op.ThreadId := 1
                    if !HasProp(op, "Watch") op.Watch := []
                        if !HasProp(op, "StepsCount") op.StepsCount := 0
                            if !HasProp(op, "Steps") op.Steps := []
                                cfg.Opener := op
    }

    _OEd_FillWatch() {
        lvOW.Opt("-Redraw")
        lvOW.Delete()
        for _, w in cfg.Opener.Watch {
            sName := _OEd_SkillName(HasProp(w, "SkillIndex") ? w.SkillIndex : 0)
            lvOW.Add("", sName
                , (HasProp(w, "RequireCount") ? w.RequireCount : 1)
                , (HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0))
        }
        loop 3
            lvOW.ModifyCol(A_Index, "AutoHdr")
        lvOW.Opt("+Redraw")
    }
    _OEd_SkillName(idx) {
        global App
        if (idx >= 1 && idx <= App["ProfileData"].Skills.Length)
            return App["ProfileData"].Skills[idx].Name
        return "技能#" idx
    }
    _OEd_AddWatch() {
        w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
        _OEd_OpenWatchEditor(w, 0, (nw, i) => (
            cfg.Opener.Watch.Push(nw),
            _OEd_FillWatch()
        ))
    }
    _OEd_EditWatch() {
        row := lvOW.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一条 Watch"
            return
        }
        cur := cfg.Opener.Watch[row]
        _OEd_OpenWatchEditor(cur, row, (nw, i) => (
            cfg.Opener.Watch[i] := nw,
            _OEd_FillWatch()
        ))
    }
    _OEd_DelWatch() {
        row := lvOW.GetNext(0, "Focused")
        if !row
            return
        cfg.Opener.Watch.RemoveAt(row)
        _OEd_FillWatch()
    }

    _OEd_FillSteps() {
        lvSteps.Opt("-Redraw")
        lvSteps.Delete()
        for i, st in cfg.Opener.Steps {
            kind := HasProp(st, "Kind") ? st.Kind : "?"
            sum := _OEd_StepSummary(st)
            lvSteps.Add("", i, kind, sum
                , (HasProp(st, "RequireReady") ? st.RequireReady : 0)
                , (HasProp(st, "PreDelayMs") ? st.PreDelayMs : 0)
                , (HasProp(st, "HoldMs") ? st.HoldMs : 0)
                , (HasProp(st, "Verify") ? st.Verify : 0)
                , (HasProp(st, "TimeoutMs") ? st.TimeoutMs : 0)
                , (HasProp(st, "DurationMs") ? st.DurationMs : 0))
        }
        loop 9
            lvSteps.ModifyCol(A_Index, "AutoHdr")
        lvSteps.Opt("+Redraw")
    }
    _OEd_StepSummary(st) {
        k := HasProp(st, "Kind") ? st.Kind : "?"
        if (k = "Skill") {
            si := HasProp(st, "SkillIndex") ? st.SkillIndex : 0
            return "Skill#" si " (" _OEd_SkillName(si) ")"
        } else if (k = "Wait") {
            d := HasProp(st, "DurationMs") ? st.DurationMs : 0
            return "Wait " d "ms"
        } else if (k = "Swap") {
            to := HasProp(st, "TimeoutMs") ? st.TimeoutMs : 800
            rt := HasProp(st, "Retry") ? st.Retry : 0
            return "Swap (TO=" to "ms, Retry=" rt ")"
        }
        return "?"
    }
    _OEd_AddStep() {
        st := { Kind: "Skill", SkillIndex: 1, RequireReady: 0, PreDelayMs: 0, HoldMs: 0, Verify: 0, TimeoutMs: 1200,
            DurationMs: 0 }
        _OEd_OpenStepEditor(st, 0, (ns, i) => (
            cfg.Opener.Steps.Push(ns),
            cfg.Opener.StepsCount := cfg.Opener.Steps.Length,
            _OEd_FillSteps()
        ))
    }
    _OEd_EditStep() {
        row := lvSteps.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个 Step"
            return
        }
        cur := cfg.Opener.Steps[row]
        _OEd_OpenStepEditor(cur, row, (ns, i) => (
            cfg.Opener.Steps[i] := ns,
            cfg.Opener.StepsCount := cfg.Opener.Steps.Length,
            _OEd_FillSteps()
        ))
    }
    _OEd_DelStep() {
        row := lvSteps.GetNext(0, "Focused")
        if !row
            return
        cfg.Opener.Steps.RemoveAt(row)
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        _OEd_FillSteps()
    }
    _OEd_MoveStep(dir) {
        row := lvSteps.GetNext(0, "Focused")
        if !row
            return
        from := row, to := from + dir
        if (to < 1 || to > cfg.Opener.Steps.Length)
            return
        item := cfg.Opener.Steps[from]
        cfg.Opener.Steps.RemoveAt(from)
        cfg.Opener.Steps.InsertAt(to, item)
        cfg.Opener.StepsCount := cfg.Opener.Steps.Length
        _OEd_FillSteps()
        lvSteps.Modify(to, "Select Focus Vis")
    }

    _OEd_SaveOpener() {
        cfg.Opener.Enabled := cbOEnable.Value ? 1 : 0
        cfg.Opener.MaxDurationMs := (edOMax.Value != "") ? Integer(edOMax.Value) : 4000
        cfg.Opener.ThreadId := (ddOThr.Value >= 1 && ddOThr.Value <= oThrIds.Length) ? oThrIds[ddOThr.Value] : 1
        cfg.Opener.StepsCount := HasProp(cfg.Opener, "Steps") ? cfg.Opener.Steps.Length : 0
        prof.Rotation := cfg
        Storage_SaveProfile(prof)
        Notify("Opener 已保存")
    }

    ; ---------- Watch Editor（Opener） ----------
    _OEd_OpenWatchEditor(w, idx := 0, onSaved := 0) {
        if !IsObject(w)
            w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
        g2 := Gui("+Owner" . dlg.Hwnd, (idx = 0) ? "新增 Watch" : "编辑 Watch")
        g2.MarginX := 12, g2.MarginY := 10
        g2.SetFont("s10", "Segoe UI")

        g2.Add("Text", "w70", "技能：")
        ddS := g2.Add("DropDownList", "x+6 w260")
        names := []
        try for _, s in App["ProfileData"].Skills
            names.Push(s.Name)
        if names.Length
            ddS.Add(names)
        ddS.Value := Min(Max(HasProp(w, "SkillIndex") ? w.SkillIndex : 1, 1), Max(names.Length, 1))

        g2.Add("Text", "xm y+8 w80", "Require：")
        edReq := g2.Add("Edit", "x+6 w120 Number", HasProp(w, "RequireCount") ? w.RequireCount : 1)

        cbVB := g2.Add("CheckBox", "xm y+8", "VerifyBlack")
        cbVB.Value := HasProp(w, "VerifyBlack") ? (w.VerifyBlack ? 1 : 0) : 0

        btnOK := g2.Add("Button", "xm y+12 w90", "确定")
        btnCA := g2.Add("Button", "x+8 w90", "取消")
        btnOK.OnEvent("Click", (*) => _OK())
        btnCA.OnEvent("Click", (*) => g2.Destroy())
        g2.OnEvent("Close", (*) => g2.Destroy())

        g2.Show()

        _OK() {
            si := ddS.Value ? ddS.Value : 1
            req := (edReq.Value != "") ? Integer(edReq.Value) : 1
            vb := cbVB.Value ? 1 : 0
            nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
            if onSaved
                onSaved(nw, idx)
            g2.Destroy()
        }
    }

    ; 步编辑器
    _OEd_OpenStepEditor(st, idx := 0, onSaved := 0) {
        if !IsObject(st)
            st := { Kind: "Skill" }
        if !HasProp(st, "Kind") st.Kind := "Skill"
            g3 := Gui("+Owner" . dlg.Hwnd, (idx = 0) ? "新增步骤" : "编辑步骤")
        g3.MarginX := 12, g3.MarginY := 10
        g3.SetFont("s10", "Segoe UI")

        g3.Add("Text", "w70 Right", "类型：")
        ddK := g3.Add("DropDownList", "x+6 w180", ["技能", "等待", "切换"])
        kdef := StrUpper(HasProp(st, "Kind") ? st.Kind : "SKILL")
        ddK.Value := (kdef = "SKILL") ? 1 : (kdef = "WAIT") ? 2 : 3

        ; ---- 技能字段 ----
        g3.Add("Text", "xm y+10 w70 Right", "技能：")
        ddSS := g3.Add("DropDownList", "x+6 w260")
        names := []
        try for _, s in App["ProfileData"].Skills
            names.Push(s.Name)
        if names.Length
            ddSS.Add(names)
        ddSS.Value := Min(Max(HasProp(st, "SkillIndex") ? st.SkillIndex : 1, 1), Max(names.Length, 1))

        cbReq := g3.Add("CheckBox", "xm y+8", "需就绪")
        cbReq.Value := HasProp(st, "RequireReady") ? (st.RequireReady ? 1 : 0) : 0

        g3.Add("Text", "xm y+8 w80 Right", "预延时(ms)：")
        edPre := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "PreDelayMs") ? st.PreDelayMs : 0)

        g3.Add("Text", "x+20 w80 Right", "按住(ms)：")
        edHold := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "HoldMs") ? st.HoldMs : 0)

        cbVer := g3.Add("CheckBox", "xm y+8", "发送后验证")
        cbVer.Value := HasProp(st, "Verify") ? (st.Verify ? 1 : 0) : 0

        ; ---- 等待字段 ----
        g3.Add("Text", "xm y+10 w90 Right", "时长(ms)：")
        edDur := g3.Add("Edit", "x+6 w140 Number", HasProp(st, "DurationMs") ? st.DurationMs : 0)

        ; ---- 切换字段 ----
        g3.Add("Text", "xm y+10 w90 Right", "超时(ms)：")
        edTO := g3.Add("Edit", "x+6 w140 Number", HasProp(st, "TimeoutMs") ? st.TimeoutMs : 800)
        g3.Add("Text", "x+16 w70 Right", "重试：")
        edRt := g3.Add("Edit", "x+6 w120 Number", HasProp(st, "Retry") ? st.Retry : 0)

        btnOK := g3.Add("Button", "xm y+12 w90", "确定")
        btnCA := g3.Add("Button", "x+8 w90", "取消")
        btnOK.OnEvent("Click", (*) => _OK())
        btnCA.OnEvent("Click", (*) => g3.Destroy())

        ddK.OnEvent("Change", (*) => _toggle())
        g3.OnEvent("Close", (*) => g3.Destroy())

        _toggle()
        g3.Show()

        ; 4) 在 _GEd_OpenCondEditor 内，增强 _toggle 与 _OK，避免在空列表时继续保存

        ; 在 _toggle() 内，末尾增加：当切到“像素就绪”时自动刷新一次引用对象
        _toggle() {
            kcn := ddKind.Text
            for ctl in [grpP1, ddRefType, grpP2, ddRefObj, grpP3, ddOp, grpP4, edColor, grpP5, edTol, btnAuto]
                ctl.Visible := (kcn = "像素就绪")
            for ctl in [grpR1, ddRule, grpR2, edQuiet]
                ctl.Visible := (kcn = "规则静默")
            for ctl in [grpC1, ddCSkill, grpC2, ddCCmp, grpC3, edCVal]
                ctl.Visible := (kcn = "计数")
            for ctl in [grpE1, ddECmp, grpE2, edEMs]
                ctl.Visible := (kcn = "阶段用时")
            if (kcn = "像素就绪")
                _fillRefObj()
        }

        ; 在 _OK() 内，替换“像素就绪/计数/规则静默”的保存分支，加入空数据保护
        _OK() {
            kcn := ddKind.Text
            kindKey := (kcn = "像素就绪") ? "PixelReady" : (kcn = "规则静默") ? "RuleQuiet" : (kcn = "计数") ? "Counter" :
                "Elapsed"

            if (kindKey = "PixelReady") {
                refType := (ddRefType.Value = 2) ? "Point" : "Skill"
                if (!ddRefObj.Enabled) {  ; 无可选对象
                    MsgBox (refType = "Point")
                        ? "当前没有可引用的取色点位，请先在“取色点位”页新增后再配置条件。"
                        : "当前没有可引用的技能，请先在“技能列表”页新增后再配置条件。"
                    return
                }
                refIdx := ddRefObj.Value ? ddRefObj.Value : 1
                opKey := (ddOp.Value = 1) ? "EQ" : "NEQ"
                col := Trim(edColor.Value)
                tol := (edTol.Value != "") ? Integer(edTol.Value) : 16
                nc := { Kind: kindKey, RefType: (refType = "Point" ? "Point" : "Skill"), RefIndex: refIdx, Op: opKey,
                    Color: (col != "" ? col : "0x000000"), Tol: tol }
                if onSaved
                    onSaved(nc, idx)
                ge2.Destroy()
                return
            }

            if (kindKey = "Counter") {
                if (!ddCSkill.Enabled) {
                    MsgBox "当前没有可引用的技能，请先在“技能列表”页新增后再配置条件。"
                    return
                }
                si := ddCSkill.Value ? ddCSkill.Value : 1
                cmpTxt := ddCCmp.Text
                cmpKey := (cmpTxt = ">=") ? "GE" : (cmpTxt = "==") ? "EQ" : (cmpTxt = ">") ? "GT" : (cmpTxt = "<=") ?
                    "LE" : "LT"
                v := (edCVal.Value != "") ? Integer(edCVal.Value) : 1
                nc := { Kind: kindKey, RefIndex: si, Cmp: cmpKey, Value: v }
                if onSaved
                    onSaved(nc, idx)
                ge2.Destroy()
                return
            }

            if (kindKey = "RuleQuiet") {
                if (!ddRule.Enabled) {
                    MsgBox "当前没有可引用的规则，请先在“循环配置”页新增规则后再配置条件。"
                    return
                }
                rid := ddRule.Value ? ddRule.Value : 1
                qms := (edQuiet.Value != "") ? Integer(edQuiet.Value) : 0
                nc := { Kind: kindKey, RuleId: rid, QuietMs: qms }
                if onSaved
                    onSaved(nc, idx)
                ge2.Destroy()
                return
            }

            ; 阶段用时
            cmpTxt := ddECmp.Text
            cmpKey := (cmpTxt = ">=") ? "GE" : (cmpTxt = "==") ? "EQ" : (cmpTxt = ">") ? "GT" : (cmpTxt = "<=") ? "LE" :
                "LT"
            ms := (edEMs.Value != "") ? Integer(edEMs.Value) : 0
            nc := { Kind: kindKey, Cmp: cmpKey, ElapsedMs: ms }
            if onSaved
                onSaved(nc, idx)
            ge2.Destroy()
        }
    }

    ; ---------- 通用保存（General 页） ----------
    OnSave(*) {
        cfg.Enabled := cbEnable.Value ? 1 : 0

        ; DefaultTrackId 基于当前 Tracks 列表映射
        idsNow := _REd_ListTrackIds(cfg)
        if (ddDefTrack.Value >= 1 && ddDefTrack.Value <= idsNow.Length)
            cfg.DefaultTrackId := Integer(idsNow[ddDefTrack.Value])

        cfg.BusyWindowMs := (edBusy.Value != "") ? Integer(edBusy.Value) : 200
        cfg.ColorTolBlack := (edTol.Value != "") ? Integer(edTol.Value) : 16
        cfg.RespectCastLock := cbCast.Value ? 1 : 0

        cfg.SwapKey := Trim(hkSwap.Value)
        cfg.VerifySwap := cbVerifySwap.Value ? 1 : 0
        cfg.SwapTimeoutMs := (edSwapTO.Value != "") ? Integer(edSwapTO.Value) : 800
        cfg.SwapRetry := (edSwapRetry.Value != "") ? Integer(edSwapRetry.Value) : 0

        cfg.GatesEnabled := cbGates.Value ? 1 : 0
        cfg.GateCooldownMs := (edGateCd.Value != "") ? Integer(edGateCd.Value) : 0

        ; BlackGuard
        bg := cfg.BlackGuard
        bg.Enabled := cbBG.Value ? 1 : 0
        bg.SampleCount := (edBG_Samp.Value != "") ? Integer(edBG_Samp.Value) : 5
        try bg.BlackRatioThresh := (edBG_Ratio.Value != "") ? (edBG_Ratio.Value + 0) : 0.7
        bg.WindowMs := (edBG_Win.Value != "") ? Integer(edBG_Win.Value) : 120
        bg.CooldownMs := (edBG_Cool.Value != "") ? Integer(edBG_Cool.Value) : 600
        bg.MinAfterSendMs := (edBG_Min.Value != "") ? Integer(edBG_Min.Value) : 60
        bg.MaxAfterSendMs := (edBG_Max.Value != "") ? Integer(edBG_Max.Value) : 800
        bg.UniqueRequired := cbBG_Uniq.Value ? 1 : 0
        cfg.BlackGuard := bg

        prof.Rotation := cfg
        Storage_SaveProfile(prof)
        Notify("Rotation 配置已保存")
    }
}
