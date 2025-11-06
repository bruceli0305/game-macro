; modules\ui\rotation\RE_UI_Page_Tracks.ahk
#Requires AutoHotkey v2
#Include "..\shell_v2\UIX_Common.ahk"

; 轨道页（完整）：列表+顶部工具条，编辑器内含 Watch/RuleRefs 编辑
; Build(ctx) => { Save: Func }
REUI_Page_Tracks_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(1)
    REUI_Tracks_Ensure(&cfg)

    rc := UIX_PageRect(ctx.dlg)

    ; 顶部工具条（横向按钮）
    btnY := rc.Y + 8
    x := rc.X
    btnAdd  := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "新增"), x += 70 + 8
    btnEdit := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "编辑"), x += 70 + 8
    btnDel  := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "删除"), x += 70 + 8
    btnUp   := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "上移"),  x += 70 + 8
    btnDn   := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "下移"),  x += 70 + 8
    btnSave := dlg.Add("Button", Format("x{} y{} w70", x, btnY), "保存")

    ; 列表：占满右侧内容区
    lvY := btnY + 34 + 6
    lvH := Max(120, rc.H - (lvY - rc.Y) - 12)
    lv := dlg.Add("ListView"
        , Format("x{} y{} w{} h{} +Grid", rc.X, lvY, rc.W, lvH)
        , ["ID","名称","线程","最长ms","最短停留","下一轨","Watch#","规则#"])

    REUI_Tracks_FillList(lv, cfg)

    ; 事件
    btnAdd.OnEvent("Click", (*) => REUI_Tracks_OnAdd(cfg, dlg, lv))
    btnEdit.OnEvent("Click", (*) => REUI_Tracks_OnEdit(lv, cfg, dlg))
    btnDel.OnEvent("Click", (*) => REUI_Tracks_OnDel(lv, cfg))
    btnUp .OnEvent("Click", (*) => REUI_Tracks_OnMove(lv, cfg, -1))
    btnDn .OnEvent("Click", (*) => REUI_Tracks_OnMove(lv, cfg, 1))
    btnSave.OnEvent("Click", (*) => (Storage_SaveProfile(App["ProfileData"]), Notify("轨道已保存")))
    lv.OnEvent("DoubleClick", (*) => REUI_Tracks_OnEdit(lv, cfg, dlg))

    return { Save: () => 0 }
}

;========================== 列表/数据 ==========================
REUI_Tracks_Ensure(&cfg) {
    if !HasProp(cfg,"Tracks") || !IsObject(cfg.Tracks)
        cfg.Tracks := []
    if (cfg.Tracks.Length = 0) {
        if HasProp(cfg,"Track1")
            cfg.Tracks.Push(cfg.Track1)
        if HasProp(cfg,"Track2")
            cfg.Tracks.Push(cfg.Track2)
    }
    if (cfg.Tracks.Length = 0) {
        cfg.Tracks.Push({ Id:1, Name:"轨道1", ThreadId:1, MaxDurationMs:8000, MinStayMs:0, NextTrackId:0, Watch:[], RuleRefs:[] })
    }
}
REUI_Tracks_FillList(lv, cfg) {
    lv.Opt("-Redraw")
    lv.Delete()
    if HasProp(cfg,"Tracks") && IsObject(cfg.Tracks) {
        for _, t in cfg.Tracks {
            thName := REUI_ThreadNameById(HasProp(t,"ThreadId") ? t.ThreadId : 1)
            wCnt := (HasProp(t,"Watch")    && IsObject(t.Watch))    ? t.Watch.Length    : 0
            rCnt := (HasProp(t,"RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
            lv.Add("", HasProp(t,"Id")?t.Id:0
                , HasProp(t,"Name")?t.Name:""
                , thName
                , HasProp(t,"MaxDurationMs")?t.MaxDurationMs:0
                , HasProp(t,"MinStayMs")?t.MinStayMs:0
                , HasProp(t,"NextTrackId")?t.NextTrackId:0
                , wCnt, rCnt)
        }
    }
    Loop 8
        lv.ModifyCol(A_Index, "AutoHdr")
    lv.Opt("+Redraw")
}
REUI_Tracks_OnAdd(cfg, owner, lv) {
    newId := 1
    try {
        maxId := 0
        for _, t in cfg.Tracks {
            tid := HasProp(t,"Id") ? Integer(t.Id) : 0
            if (tid > maxId)
                maxId := tid
        }
        newId := maxId + 1
    }
    tr := { Id:newId, Name:"轨道" newId, ThreadId:1, MaxDurationMs:8000, MinStayMs:0, NextTrackId:0, Watch:[], RuleRefs:[] }
    REUI_TrackEditor_Open(owner, cfg, tr, 0, OnSaved)
    OnSaved(saved, idx) {
        cfg.Tracks.Push(saved)
        REUI_Tracks_FillList(lv, cfg)
    }
}
REUI_Tracks_OnEdit(lv, cfg, owner) {
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一条轨道"
        return
    }
    if (row < 1 || row > cfg.Tracks.Length)
        return
    cur := cfg.Tracks[row]
    REUI_TrackEditor_Open(owner, cfg, cur, row, OnSaved)
    OnSaved(saved, i) {
        cfg.Tracks[i] := saved
        REUI_Tracks_FillList(lv, cfg)
    }
}
REUI_Tracks_OnDel(lv, cfg) {
    if (cfg.Tracks.Length <= 1) {
        MsgBox "至少保留一条轨道。"
        return
    }
    row := lv.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一条轨道"
        return
    }
    delId := HasProp(cfg.Tracks[row], "Id") ? cfg.Tracks[row].Id : 0
    cfg.Tracks.RemoveAt(row)
    ids := REUI_Tracks_ListTrackIds(cfg)
    if !(ids.IndexOf(delId))
        cfg.DefaultTrackId := Integer(ids[1])
    REUI_Tracks_FillList(lv, cfg)
    Notify("已删除轨道")
}
REUI_Tracks_OnMove(lv, cfg, dir) {
    row := lv.GetNext(0, "Focused")
    if !row
        return
    from := row
    to := from + dir
    if (to < 1 || to > cfg.Tracks.Length)
        return
    item := cfg.Tracks[from]
    cfg.Tracks.RemoveAt(from)
    cfg.Tracks.InsertAt(to, item)
    REUI_Tracks_FillList(lv, cfg)
    lv.Modify(to, "Select Focus Vis")
}

;========================== 轨道编辑器 ==========================
REUI_TrackEditor_Open(owner, cfg, t, idx := 0, onSaved := 0) {
    isNew := (idx = 0)
    defaults := Map("Id",1,"Name","轨道","ThreadId",1,"MaxDurationMs",8000,"MinStayMs",0,"NextTrackId",0)
    for k, v in defaults
        if !HasProp(t, k)
            t.%k% := v
    if !HasProp(t,"Watch")
        t.Watch := []
    if !HasProp(t,"RuleRefs")
        t.RuleRefs := []

    g := Gui("+Owner" owner.Hwnd, isNew ? "新增轨道" : "编辑轨道")
    g.MarginX := 12, g.MarginY := 10
    g.SetFont("s10","Segoe UI")

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
    edMin := g.Add("Edit", "x+6 w120 Number Center", HasProp(t,"MinStayMs")?t.MinStayMs:0)

    ; 行4：下一轨
    g.Add("Text", "xm y+8 w70 Right", "下一轨：")
    ddNext := g.Add("DropDownList", "x+6 w160")
    ids := REUI_Tracks_ListTrackIds(cfg)
    if (isNew && (!ids.Length || ids[ids.Length] != t.Id))
        ids.Push(t.Id)
    arrNext := ["0"]
    for _, id in ids
        arrNext.Push(id)
    if arrNext.Length
        ddNext.Add(arrNext)
    nextSel := 1
    allNext := arrNext
    for i, v in allNext
        if (Integer(v) = Integer(HasProp(t,"NextTrackId")?t.NextTrackId:0)) {
            nextSel := i
            break
        }
    ddNext.Value := nextSel

    ; 行5：Watch 列表 + 右侧竖排按钮
    g.Add("Text", "xm y+10", "Watch（技能计数/黑框确认）：")
    lvW := g.Add("ListView", "xm w620 r8 +Grid", ["技能","Require","VerifyBlack"])
    btnWAdd := g.Add("Button", "x+10 yp w80", "新增")
    btnWEdit:= g.Add("Button", "xp yp+34 w80", "编辑")
    btnWDel := g.Add("Button", "xp yp+34 w80", "删除")

    REUI_TrackEditor_FillWatch(lvW, t)
    btnWAdd.OnEvent("Click", (*) => REUI_WatchEditor_Add(g, t, lvW))
    btnWEdit.OnEvent("Click", (*) => REUI_WatchEditor_Edit(g, t, lvW))
    btnWDel.OnEvent("Click", (*) => REUI_WatchEditor_Del(t, lvW))
    lvW.OnEvent("DoubleClick", (*) => REUI_WatchEditor_Edit(g, t, lvW))

    ; 行6：规则集限制
    lvW.GetPos(&lvx, &lvy, &lvw, &lvh)
    yRule := lvy + lvh + 10
    g.Add("Text", Format("x{} y{} w100 Right", lvx, yRule), "规则集限制：")
    labRules := g.Add("Text", Format("x{} y{}", lvx + 106, yRule), REUI_TrackEditor_RulesLabel(t))
    btnRules := g.Add("Button", Format("x{} y{} w120", lvx + 106 + 180 + 10, yRule - 2), "选择规则...")
    btnRules.OnEvent("Click", (*) => REUI_RuleRefsPicker_Open(g, t, labRules))

    ; 行7：底部按钮
    btnSave := g.Add("Button", Format("x{} y{} w100", lvx, yRule + 40), "保存")
    btnCancel := g.Add("Button", "x+8 w100", "取消")
    btnSave.OnEvent("Click", SaveTrack)
    btnCancel.OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Close", (*) => g.Destroy())
    g.Show()

    SaveTrack(*) {
        name := Trim(edName.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        t.Name := name
        t.ThreadId := (ddThr.Value>=1 && ddThr.Value<=thIds.Length) ? thIds[ddThr.Value] : 1
        t.MaxDurationMs := (edMax.Value!="") ? Integer(edMax.Value) : 8000
        t.MinStayMs    := (edMin.Value!="") ? Integer(edMin.Value) : 0
        if (ddNext.Value>=1 && ddNext.Value<=allNext.Length)
            t.NextTrackId := Integer(allNext[ddNext.Value])
        else
            t.NextTrackId := 0

        if onSaved
            onSaved(t, (idx=0 ? 0 : idx))
        g.Destroy()
        Notify(isNew ? "已新增轨道" : "已保存轨道")
    }
}

REUI_TrackEditor_FillWatch(lvW, t) {
    lvW.Opt("-Redraw")
    lvW.Delete()
    for _, w in t.Watch {
        sName := REUI_Watch_SkillName(HasProp(w,"SkillIndex")?w.SkillIndex:0)
        lvW.Add("", sName
            , (HasProp(w,"RequireCount")?w.RequireCount:1)
            , (HasProp(w,"VerifyBlack")?w.VerifyBlack:0))
    }
    Loop 3
        lvW.ModifyCol(A_Index, "AutoHdr")
    lvW.Opt("+Redraw")
}
REUI_Watch_SkillName(idx) {
    try {
        if (idx>=1 && idx<=App["ProfileData"].Skills.Length)
            return App["ProfileData"].Skills[idx].Name
    }
    return "技能#" idx
}

;========================== Watch 编辑器 ==========================
REUI_WatchEditor_Add(owner, t, lvW) {
    w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    REUI_WatchEditor_Open(owner, w, 0, OnSaved)
    OnSaved(nw, i) {
        t.Watch.Push(nw)
        REUI_TrackEditor_FillWatch(lvW, t)
    }
}
REUI_WatchEditor_Edit(owner, t, lvW) {
    row := lvW.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一条 Watch"
        return
    }
    w := t.Watch[row]
    REUI_WatchEditor_Open(owner, w, row, OnSaved)
    OnSaved(nw, i) {
        t.Watch[i] := nw
        REUI_TrackEditor_FillWatch(lvW, t)
    }
}
REUI_WatchEditor_Del(t, lvW) {
    row := lvW.GetNext(0, "Focused")
    if !row
        return
    t.Watch.RemoveAt(row)
    REUI_TrackEditor_FillWatch(lvW, t)
}
REUI_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    if !IsObject(w)
        w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    g2 := Gui("+Owner" owner.Hwnd, (idx=0) ? "新增 Watch" : "编辑 Watch")
    g2.MarginX := 12, g2.MarginY := 10
    g2.SetFont("s10","Segoe UI")

    g2.Add("Text", "w70 Right", "技能：")
    ddS := g2.Add("DropDownList", "x+6 w260")
    cnt := 0
    try cnt := App["ProfileData"].Skills.Length
    if (cnt>0) {
        names := []
        for _, s in App["ProfileData"].Skills
            names.Push(s.Name)
        ddS.Add(names)
        defIdx := HasProp(w,"SkillIndex") ? w.SkillIndex : 1
        ddS.Value := UIX_IndexClamp(defIdx, names.Length)
        ddS.Enabled := true
    } else {
        ddS.Add(["（无技能）"]), ddS.Value := 1, ddS.Enabled := false
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
        si := ddS.Value ? ddS.Value : 1
        req := (edReq.Value!="") ? Integer(edReq.Value) : 1
        vb  := cbVB.Value ? 1 : 0
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
        if onSaved
            onSaved(nw, idx)
        g2.Destroy()
    }
}

;========================== 规则选择器 ==========================
REUI_TrackEditor_RulesLabel(t) {
    cnt := (HasProp(t,"RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
    return "已选择规则数：" cnt
}
REUI_RuleRefsPicker_Open(owner, t, labRulesCtl) {
    g3 := Gui("+Owner" owner.Hwnd, "选择规则（勾选）")
    g3.MarginX := 12, g3.MarginY := 10
    g3.SetFont("s10","Segoe UI")

    lv := g3.Add("ListView", "xm w520 r12 +Grid +Checked", ["ID","名称","启用"])
    try {
        for i, r in App["ProfileData"].Rules {
            row := lv.Add("", i, r.Name, (r.Enabled ? "√" : ""))
            if (HasProp(t,"RuleRefs") && IsObject(t.RuleRefs) && t.RuleRefs.IndexOf(i))
                lv.Modify(row, "Check")
        }
    }
    Loop 3
        lv.ModifyCol(A_Index, "AutoHdr")

    btnOK := g3.Add("Button", "xm y+10 w90", "确定")
    btnCA := g3.Add("Button", "x+8 w90", "取消")
    btnOK.OnEvent("Click", SaveSel)
    btnCA.OnEvent("Click", (*) => g3.Destroy())
    g3.OnEvent("Close", (*) => g3.Destroy())
    g3.Show()

    SaveSel(*) {
        sel := []
        row := 0
        Loop {
            row := lv.GetNext(row, "Checked")
            if (!row)
                break
            id := Integer(lv.GetText(row, 1))
            sel.Push(id)
        }
        t.RuleRefs := sel
        labRulesCtl.Text := REUI_TrackEditor_RulesLabel(t)
        g3.Destroy()
    }
}
; —— 替换：仅 Tracks 页使用，避免与其它页冲突 ——
REUI_Tracks_ListTrackIds(cfg) {
    ids := []
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length > 0 {
            for _, tt in cfg.Tracks
                ids.Push(tt.Id)
            return ids
        }
    }
    ids.Push(1), ids.Push(2)
    return ids
}