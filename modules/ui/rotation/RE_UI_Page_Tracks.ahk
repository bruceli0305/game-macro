; modules\ui\rotation\RE_UI_Page_Tracks.ahk
#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

; 构建“轨道”页（列表 + 轨道编辑器 + 监视编辑器 + 规则选择器）
REUI_Page_Tracks_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(2)
    REUI_Tracks_Ensure(&cfg)

    lv := dlg.Add("ListView", "xm y+8 w820 r12 +Grid"
        , ["ID","名称","线程","最长ms","最短停留","下一轨","监视数","规则数"])
    btnAdd  := dlg.Add("Button", "xm y+8 w90", "新增")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑")
    btnDel  := dlg.Add("Button", "x+8 w90", "删除")
    btnUp   := dlg.Add("Button", "x+8 w90", "上移")
    btnDn   := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w110", "保存轨道")

    REUI_Tracks_FillList(lv, cfg)

    btnAdd.OnEvent("Click", (*) => REUI_Tracks_OnAdd(cfg, dlg, lv))
    btnEdit.OnEvent("Click", (*) => REUI_Tracks_OnEdit(lv, cfg, dlg))
    btnDel.OnEvent("Click", (*) => REUI_Tracks_OnDel(lv, cfg))
    btnUp.OnEvent("Click", (*) => REUI_Tracks_OnMove(lv, cfg, -1))
    btnDn.OnEvent("Click", (*) => REUI_Tracks_OnMove(lv, cfg, 1))
    lv.OnEvent("DoubleClick", (*) => REUI_Tracks_OnEdit(lv, cfg, dlg))
    btnSave.OnEvent("Click", SaveTracks)

    SaveTracks(*) {
        global App
        Storage_SaveProfile(App["ProfileData"])
        Notify("轨道已保存")
    }

    return { Save: () => 0 }
}

;------------------------------- 列表/数据 -------------------------------
REUI_Tracks_Ensure(&cfg) {
    if !HasProp(cfg, "Tracks") || !IsObject(cfg.Tracks) {
        cfg.Tracks := []
    }

    if (cfg.Tracks.Length = 0) {
        if HasProp(cfg, "Track1") {
            cfg.Tracks.Push(cfg.Track1)
        }
        if HasProp(cfg, "Track2") {
            cfg.Tracks.Push(cfg.Track2)
        }
    }
    if (cfg.Tracks.Length = 0) {
        cfg.Tracks.Push({ Id:1, Name:"轨道1", ThreadId:1, MaxDurationMs:8000, MinStayMs:0, NextTrackId:0, Watch:[], RuleRefs:[] })
    }
}

REUI_Tracks_FillList(lv, cfg) {
    lv.Opt("-Redraw")
    lv.Delete()
    if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) {
        for _, t in cfg.Tracks {
            thName := REUI_ThreadNameById(HasProp(t,"ThreadId") ? t.ThreadId : 1)
            wCnt := (HasProp(t,"Watch")    && IsObject(t.Watch))    ? t.Watch.Length    : 0
            rCnt := (HasProp(t,"RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
            lv.Add("", HasProp(t,"Id") ? t.Id : 0
                , HasProp(t,"Name") ? t.Name : ""
                , thName
                , HasProp(t,"MaxDurationMs") ? t.MaxDurationMs : 0
                , HasProp(t,"MinStayMs") ? t.MinStayMs : 0
                , HasProp(t,"NextTrackId") ? t.NextTrackId : 0
                , wCnt, rCnt)
        }
    }
    Loop 8 {
        lv.ModifyCol(A_Index, "AutoHdr")
    }
    lv.Opt("+Redraw")
}

REUI_Tracks_OnAdd(cfg, owner, lv) {
    newId := 1
    try {
        maxId := 0
        for _, t in cfg.Tracks {
            thisId := HasProp(t, "Id") ? Integer(t.Id) : 0
            if (thisId > maxId) {
                maxId := thisId
            }
        }
        newId := maxId + 1
    } catch {
        newId := 1
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
    if (row < 1 || row > cfg.Tracks.Length) {
        return
    }
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
    delId := HasProp(cfg.Tracks[row], "Id") ? Integer(cfg.Tracks[row].Id) : 0
    cfg.Tracks.RemoveAt(row)

    ; 重新获取现存轨道 ID 列表
    ids := REUI_ListTrackIds(cfg)

    ; 若默认轨道已不存在，则回退到第一条
    defId := HasProp(cfg, "DefaultTrackId") ? Integer(cfg.DefaultTrackId) : 0
    found := REUI_ArrayContains(ids, defId)
    if (!found) {
        if (ids.Length >= 1) {
            cfg.DefaultTrackId := Integer(ids[1])
        } else {
            cfg.DefaultTrackId := 0
        }
    }

    REUI_Tracks_FillList(lv, cfg)
    Notify("已删除轨道")
}

REUI_Tracks_OnMove(lv, cfg, dir) {
    row := lv.GetNext(0, "Focused")
    if !row {
        return
    }
    from := row
    to := from + dir
    if (to < 1 || to > cfg.Tracks.Length) {
        return
    }
    item := cfg.Tracks[from]
    cfg.Tracks.RemoveAt(from)
    cfg.Tracks.InsertAt(to, item)
    REUI_Tracks_FillList(lv, cfg)
    lv.Modify(to, "Select Focus Vis")
}

;------------------------------- 轨道编辑器 -------------------------------
REUI_TrackEditor_Open(owner, cfg, t, idx := 0, onSaved := 0) {
    isNew := (idx = 0)
    defaults := Map("Id",1,"Name","轨道","ThreadId",1,"MaxDurationMs",8000,"MinStayMs",0,"NextTrackId",0)
    for k, v in defaults {
        if !HasProp(t, k) {
            t.%k% := v
        }
    }
    if !HasProp(t,"Watch") {
        t.Watch := []
    }
    if !HasProp(t,"RuleRefs") {
        t.RuleRefs := []
    }

    g := Gui("+Owner" owner.Hwnd, isNew ? "" : "编辑轨道")
    g.MarginX := 12
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    ; ID
    g.Add("Text", "xm ym w100 Right", "ID：")
    edId := g.Add("Edit", "x+6 w120 ReadOnly", t.Id)

    ; 名称/线程
    g.Add("Text", "xm y+8 w100 Right", "名称：")
    edName := g.Add("Edit", "x+6 w120", t.Name)

    g.Add("Text", "x+20 w100 Right", "线程：")
    ddThr := g.Add("DropDownList", "x+6 w120")
    thNames := []
    thIds := []
    try {
        for _, th in App["ProfileData"].Threads {
            thNames.Push(th.Name)
            thIds.Push(th.Id)
        }
    }
    if (thNames.Length = 0) {
        thNames := ["默认线程"]
        thIds   := [1]
    }
    ddThr.Add(thNames)
    sel := 1
    for i, id in thIds {
        if (id = t.ThreadId) {
            sel := i
            break
        }
    }
    ddThr.Value := sel

    ; 时长/最短停留
    g.Add("Text", "xm y+8 w100 Right", "最长(ms)：")
    edMax := g.Add("Edit", "x+6 w120 Number Center", t.MaxDurationMs)

    g.Add("Text", "x+20 w100 Right", "最短停留：")
    edMin := g.Add("Edit", "x+6 w120 Number Center", HasProp(t,"MinStayMs") ? t.MinStayMs : 0)

    ; 下一轨
    g.Add("Text", "xm y+8 w100 Right", "下一轨：")
    ddNext := g.Add("DropDownList", "x+6 w120")
    ids := REUI_ListTrackIds(cfg)
    if (isNew) {
        if (ids.Length = 0 || ids[ids.Length] != t.Id) {
            ids.Push(t.Id)
        }
    }
    arrNext := ["0"]
    for _, id in ids {
        arrNext.Push(id)
    }
    if arrNext.Length {
        ddNext.Add(arrNext)
    }
    nextSel := 1
    allNext := arrNext
    for i, v in allNext {
        if (Integer(v) = Integer(HasProp(t,"NextTrackId") ? t.NextTrackId : 0)) {
            nextSel := i
            break
        }
    }
    ddNext.Value := nextSel

    ; 监视列表 + 右侧按钮
    g.Add("Text", "xm y+10", "监视（技能计数/黑框确认）：")
    lvW := g.Add("ListView", "xm w620 r8 +Grid", ["技能","计数","黑框确认"])
    btnWAdd := g.Add("Button", "x+10 yp w80", "新增")
    btnWEdit := g.Add("Button", "xp yp+34 w80", "编辑")
    btnWDel := g.Add("Button", "xp yp+34 w80", "删除")

    REUI_TrackEditor_FillWatch(lvW, t)

    btnWAdd.OnEvent("Click", (*) => REUI_WatchEditor_Add(g, t, lvW))
    btnWEdit.OnEvent("Click", (*) => REUI_WatchEditor_Edit(g, t, lvW))
    btnWDel.OnEvent("Click", (*) => REUI_WatchEditor_Del(t, lvW))
    lvW.OnEvent("DoubleClick", (*) => REUI_WatchEditor_Edit(g, t, lvW))

    ; 规则集限制（避免变量名与 lvW 大小写冲突）
    lvW.GetPos(&lvX, &lvY, &lvWidth, &lvHeight)
    yRule := lvY + lvHeight + 10
    g.Add("Text", Format("x{} y{} w100 Right", lvX, yRule), "规则集限制：")
    labRules := g.Add("Text", Format("x{} y{}", lvX + 106, yRule), REUI_TrackEditor_RulesLabel(t))
    btnRules := g.Add("Button", Format("x{} y{} w120", lvX + 106 + 180 + 10, yRule - 2), "选择规则...")
    btnRules.OnEvent("Click", (*) => REUI_RuleRefsPicker_Open(g, t, labRules))

    ; 底部按钮
    btnSave := g.Add("Button", Format("x{} y{} w100", lvX, yRule + 40), "保存")
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
        t.ThreadId := (ddThr.Value >= 1 && ddThr.Value <= thIds.Length) ? thIds[ddThr.Value] : 1
        t.MaxDurationMs := (edMax.Value != "") ? Integer(edMax.Value) : 8000
        t.MinStayMs  := (edMin.Value != "") ? Integer(edMin.Value) : 0
        t.NextTrackId := Integer(allNext[ REUI_IndexClamp(ddNext.Value, allNext.Length) ])

        if onSaved {
            onSaved(t, (idx = 0 ? 0 : idx))
        }
        g.Destroy()
        Notify(isNew ? "已新增轨道" : "已保存轨道")
    }
}

REUI_TrackEditor_FillWatch(lvW, t) {
    lvW.Opt("-Redraw")
    lvW.Delete()
    for _, w in t.Watch {
        sName := REUI_Watch_SkillName(HasProp(w,"SkillIndex") ? w.SkillIndex : 0)
        lvW.Add("", sName
            , (HasProp(w,"RequireCount") ? w.RequireCount : 1)
            , (HasProp(w,"VerifyBlack")  ? w.VerifyBlack  : 0))
    }
    Loop 3 {
        lvW.ModifyCol(A_Index, "AutoHdr")
    }
    lvW.Opt("+Redraw")
}

REUI_Watch_SkillName(idx) {
    try {
        if (idx >= 1 && idx <= App["ProfileData"].Skills.Length) {
            return App["ProfileData"].Skills[idx].Name
        }
    }
    return "技能#" idx
}

REUI_WatchEditor_Add(owner, t, lvW) {
    OnSaved(nw, i) {
        t.Watch.Push(nw)
        REUI_TrackEditor_FillWatch(lvW, t)
    }
    w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    REUI_WatchEditor_Open(owner, w, 0, OnSaved)
}

REUI_WatchEditor_Edit(owner, t, lvW) {
    row := lvW.GetNext(0, "Focused")
    if !row {
        MsgBox "请选择一条监视"
        return
    }
    w := t.Watch[row]
    OnSaved(nw, i) {
        t.Watch[i] := nw
        REUI_TrackEditor_FillWatch(lvW, t)
    }
    REUI_WatchEditor_Open(owner, w, row, OnSaved)
}

REUI_WatchEditor_Del(t, lvW) {
    row := lvW.GetNext(0, "Focused")
    if !row {
        return
    }
    t.Watch.RemoveAt(row)
    REUI_TrackEditor_FillWatch(lvW, t)
}

; 监视条目编辑器（中文化）
REUI_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    if !IsObject(w) {
        w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    }
    g2 := Gui("+Owner" owner.Hwnd, (idx = 0) ? "新增监视" : "编辑监视")
    g2.MarginX := 12
    g2.MarginY := 10
    g2.SetFont("s10", "Segoe UI")

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
        defIdx := HasProp(w, "SkillIndex") ? w.SkillIndex : 1
        ddS.Value := REUI_IndexClamp(defIdx, names.Length)
        ddS.Enabled := true
    } else {
        ddS.Add(["（无技能）"])
        ddS.Value := 1
        ddS.Enabled := false
    }

    g2.Add("Text", "xm y+8 w70 Right", "计数：")
    edReq := g2.Add("Edit", "x+6 w260 Number Center", HasProp(w, "RequireCount") ? w.RequireCount : 1)

    cbVB := g2.Add("CheckBox", "xm y+8", "黑框确认")
    cbVB.Value := HasProp(w, "VerifyBlack") ? (w.VerifyBlack ? 1 : 0) : 0

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
        req := (edReq.Value != "") ? Integer(edReq.Value) : 1
        vb := cbVB.Value ? 1 : 0
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }
        if onSaved {
            onSaved(nw, idx)
        }
        g2.Destroy()
    }
}

REUI_TrackEditor_RulesLabel(t) {
    cnt := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
    return "已选择规则数：" cnt
}

REUI_RuleRefsPicker_Open(owner, t, labRulesCtl) {
    g3 := Gui("+Owner" owner.Hwnd, "选择规则（勾选并排序）")
    g3.MarginX := 12, g3.MarginY := 10
    g3.SetFont("s10", "Segoe UI")

    ; 左：所有规则
    g3.Add("Text", "xm", "所有规则：")
    lvAll := g3.Add("ListView", "xm w360 r12 +Grid", ["ID", "名称", "启用"])
    try {
        for i, r in App["ProfileData"].Rules {
            lvAll.Add("", i, r.Name, (r.Enabled ? "√" : ""))
        }
    }
    Loop 3 {
        Loop 3 {
            try lvAll.ModifyCol(A_Index, "AutoHdr")
        }
    }

    ; 右：已选择（可排序）
    g3.Add("Text", "x+16 yp", "已选择（顺序生效）：")
    lvSel := g3.Add("ListView", "x+0 w360 r12 +Grid", ["序", "ID", "名称"])
    Loop 3 {
        try lvSel.ModifyCol(A_Index, "AutoHdr")
    }

    ; 默认填充已选（按现有顺序）
    try {
        if (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) {
            idx := 0
            for _, id in t.RuleRefs {
                if (id>=1 && id<=App["ProfileData"].Rules.Length) {
                    idx++
                    r := App["ProfileData"].Rules[id]
                    lvSel.Add("", idx, id, r.Name)
                }
            }
        }
    }

    ; 中间/右侧按钮
    btnAdd  := g3.Add("Button", "xm y+8 w90", "加入 >>")
    btnRem  := g3.Add("Button", "x+8 w90", "<< 移除")
    btnUp   := g3.Add("Button", "x+20 w80", "上移")
    btnDn   := g3.Add("Button", "x+8 w80", "下移")
    btnClr  := g3.Add("Button", "x+8 w80", "清空")

    btnOK := g3.Add("Button", "xm y+12 w100", "确定")
    btnCA := g3.Add("Button", "x+8 w100", "取消")

    ; 事件
    btnAdd.OnEvent("Click", (*) => AddSel())
    btnRem.OnEvent("Click", (*) => RemoveSel())
    btnUp.OnEvent("Click",  (*) => MoveSel(-1))
    btnDn.OnEvent("Click",  (*) => MoveSel(1))
    btnClr.OnEvent("Click", (*) => ClearSel())
    btnOK.OnEvent("Click",  (*) => SaveSel())
    btnCA.OnEvent("Click",  (*) => g3.Destroy())
    g3.OnEvent("Close",     (*) => g3.Destroy())

    g3.Show()

    ExistsInSel(id) {
        cnt := lvSel.GetCount()
        if (cnt <= 0)
            return 0
        Loop cnt {
            if (Integer(lvSel.GetText(A_Index, 2)) = Integer(id))
                return A_Index
        }
        return 0
    }
    RenumberSel() {
        cnt := lvSel.GetCount()
        if (cnt <= 0)
            return
        Loop cnt {
            lvSel.Modify(A_Index, , A_Index)  ; 第一列“序”
        }
    }

    AddSel() {
        row := lvAll.GetNext(0, "Focused")
        if (!row) {
            return
        }
        id := Integer(lvAll.GetText(row, 1))
        if (ExistsInSel(id)) {
            return
        }
        name := lvAll.GetText(row, 2)
        pos := lvSel.GetCount() + 1
        lvSel.Add("", pos, id, name)
        lvSel.Modify(pos, "Select Focus Vis")
    }
    RemoveSel() {
        row := lvSel.GetNext(0, "Focused")
        if (!row) {
            return
        }
        lvSel.Delete(row)
        RenumberSel()
        ; 选中新的当前位置
        cnt := lvSel.GetCount()
        if (cnt >= 1) {
            to := Min(row, cnt)
            lvSel.Modify(to, "Select Focus Vis")
        }
    }
    MoveSel(dir) {
        row := lvSel.GetNext(0, "Focused")
        if (!row)
            return
        to := row + dir
        cnt := lvSel.GetCount()
        if (to < 1 || to > cnt)
            return
        id := lvSel.GetText(row, 2)
        name := lvSel.GetText(row, 3)
        lvSel.Delete(row)
        lvSel.Insert(to, "", 0, id, name)
        RenumberSel()
        lvSel.Modify(to, "Select Focus Vis")
    }
    ClearSel() {
        lvSel.Delete()
    }

    SaveSel() {
        sel := []
        cnt := lvSel.GetCount()
        Loop cnt {
            id := Integer(lvSel.GetText(A_Index, 2))  ; 第2列是ID
            sel.Push(id)
        }
        t.RuleRefs := sel
        labRulesCtl.Text := REUI_TrackEditor_RulesLabel(t)
        g3.Destroy()
    }
}