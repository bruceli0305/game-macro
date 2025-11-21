#Requires AutoHotkey v2
#Include "RE_UI_Common.ahk"

; ------------------------------- 列表/数据 -------------------------------
REUI_Tracks_Ensure(cfg) {
    if !IsObject(cfg) {
        return
    }
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
        cfg.Tracks.Push({ Id: 0, Name: "轨道1", ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [],
            RuleRefs: [] })
    }
}

REUI_Tracks_FillList(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) {
            for _, t in cfg.Tracks {
                thName := ""
                try {
                    thName := REUI_ThreadNameById(HasProp(t, "ThreadId") ? t.ThreadId : 1)
                } catch {
                    thName := "默认线程"
                }
                wCnt := 0
                rCnt := 0
                try {
                    wCnt := (HasProp(t, "Watch") && IsObject(t.Watch)) ? t.Watch.Length : 0
                } catch {
                    wCnt := 0
                }
                try {
                    rCnt := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
                } catch {
                    rCnt := 0
                }
                idVal := 0
                nmVal := ""
                mxVal := 0
                mnVal := 0
                nxVal := 0
                try {
                    idVal := HasProp(t, "Id") ? t.Id : 0
                } catch {
                    idVal := 0
                }
                try {
                    nmVal := HasProp(t, "Name") ? t.Name : ""
                } catch {
                    nmVal := ""
                }
                try {
                    mxVal := HasProp(t, "MaxDurationMs") ? t.MaxDurationMs : 0
                } catch {
                    mxVal := 0
                }
                try {
                    mnVal := HasProp(t, "MinStayMs") ? t.MinStayMs : 0
                } catch {
                    mnVal := 0
                }
                try {
                    nxVal := HasProp(t, "NextTrackId") ? t.NextTrackId : 0
                } catch {
                    nxVal := 0
                }
                try {
                    lv.Add("", idVal, nmVal, thName, mxVal, mnVal, nxVal, wCnt, rCnt)
                } catch {
                }
            }
        }
        loop 8 {
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

REUI_Tracks_OnAdd(cfg, owner, lv) {
    newIdx := 1
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) {
            newIdx := cfg.Tracks.Length + 1
        }
    } catch {
        newIdx := 1
    }
    tr := { Id: 0, Name: "轨道" newIdx, ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [],
        RuleRefs: [] }
    OnSaved(saved, idx) {
        try {
            cfg.Tracks.Push(saved)
            REUI_Tracks_FillList(lv, cfg)
        } catch {
        }
    }
    REUI_TrackEditor_Open(owner, cfg, tr, 0, OnSaved)
}

REUI_Tracks_OnEdit(lv, cfg, owner) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一条轨道"
        return
    }
    if (row < 1 || row > cfg.Tracks.Length) {
        return
    }
    cur := cfg.Tracks[row]
    OnSaved(saved, i) {
        try {
            cfg.Tracks[i] := saved
            REUI_Tracks_FillList(lv, cfg)
        } catch {
        }
    }
    REUI_TrackEditor_Open(owner, cfg, cur, row, OnSaved)
}

REUI_Tracks_OnDel(lv, cfg) {
    if (cfg.Tracks.Length <= 1) {
        MsgBox "至少保留一条轨道。"
        return
    }
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一条轨道"
        return
    }
    try {
        cfg.Tracks.RemoveAt(row)
    } catch {
    }
    ids := REUI_ListTrackIds(cfg)
    defId := 0
    try {
        defId := HasProp(cfg, "DefaultTrackId") ? Integer(cfg.DefaultTrackId) : 0
    } catch {
        defId := 0
    }
    found := REUI_ArrayContains(ids, defId)
    if (!found) {
        if (ids.Length >= 1) {
            try {
                cfg.DefaultTrackId := Integer(ids[1])
            } catch {
                cfg.DefaultTrackId := 0
            }
        } else {
            cfg.DefaultTrackId := 0
        }
    }
    try {
        REUI_Tracks_FillList(lv, cfg)
    } catch {
    }
    Notify("已删除轨道")
}

REUI_Tracks_OnMove(lv, cfg, dir) {
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
    if (to < 1 || to > cfg.Tracks.Length) {
        return
    }
    item := cfg.Tracks[from]
    try {
        cfg.Tracks.RemoveAt(from)
    } catch {
    }
    try {
        cfg.Tracks.InsertAt(to, item)
    } catch {
    }
    try {
        REUI_Tracks_FillList(lv, cfg)
    } catch {
    }
    try {
        lv.Modify(to, "Select Focus Vis")
    } catch {
    }
}

;------------------------------- 监视条目编辑器（先定义） -------------------------------
REUI_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    global App
    if !IsObject(w) {
        w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
    }
    if !HasProp(w, "SkillIndex") {
        w.SkillIndex := 1
    }
    if !HasProp(w, "RequireCount") {
        w.RequireCount := 1
    }
    if !HasProp(w, "VerifyBlack") {
        w.VerifyBlack := 0
    }
    g2 := 0
    try {
        g2 := Gui("+Owner" owner.Hwnd, (idx = 0) ? "新增监视" : "编辑监视")
    } catch {
        g2 := Gui(, (idx = 0) ? "新增监视" : "编辑监视")
    }
    g2.MarginX := 12
    g2.MarginY := 10
    g2.SetFont("s10", "Segoe UI")

    g2.Add("Text", "w70 Right", "技能：")
    ddS := g2.Add("DropDownList", "x+6 w260")

    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    } catch {
        cnt := 0
    }

    if (cnt > 0) {
        names := []
        for _, s in App["ProfileData"].Skills {
            nm := ""
            try {
                nm := HasProp(s, "Name") ? s.Name : ""
            } catch {
                nm := ""
            }
            if (nm = "") {
                nm := "技能"
            }
            names.Push(nm)
        }
        try {
            ddS.Add(names)
        } catch {
        }
        defIdx := 1
        try {
            defIdx := HasProp(w, "SkillIndex") ? w.SkillIndex : 1
        } catch {
            defIdx := 1
        }
        ddS.Value := REUI_IndexClamp(defIdx, names.Length)
        ddS.Enabled := true
    } else {
        try {
            ddS.Add(["（无技能）"])
        } catch {
        }
        ddS.Value := 1
        ddS.Enabled := false
    }

    g2.Add("Text", "xm y+8 w70 Right", "计数：")
    defCnt := 1
    try {
        defCnt := HasProp(w, "RequireCount") ? w.RequireCount : 1
    } catch {
        defCnt := 1
    }
    edReq := g2.Add("Edit", "x+6 w260 Number Center", defCnt)

    cbVB := g2.Add("CheckBox", "xm y+8", "黑框确认")
    try {
        cbVB.Value := HasProp(w, "VerifyBlack") ? (w.VerifyBlack ? 1 : 0) : 0
    } catch {
        cbVB.Value := 0
    }

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
        si := 1
        try {
            si := ddS.Value
        } catch {
            si := 1
        }
        req := 1
        try {
            req := (edReq.Value != "") ? Integer(edReq.Value) : 1
        } catch {
            req := 1
        }
        vb := 0
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

;------------------------------- 轨道编辑器 -------------------------------
REUI_TrackEditor_Open(owner, cfg, t, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)
    defaults := Map("Id", 0, "Name", "轨道", "ThreadId", 1, "MaxDurationMs", 8000, "MinStayMs", 0, "NextTrackId", 0)
    for k, v in defaults {
        if !HasProp(t, k) {
            t.%k% := v
        }
    }
    if !HasProp(t, "Watch") {
        t.Watch := []
    }
    if !HasProp(t, "RuleRefs") {
        t.RuleRefs := []
    }
    g := 0
    try {
        g := Gui("+Owner" owner.Hwnd, isNew ? "新增轨道" : "编辑轨道")
    } catch {
        g := Gui(, isNew ? "新增轨道" : "编辑轨道")
    }
    g.MarginX := 12
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")
    ; ID
    g.Add("Text", "xm ym w100 Right", "ID：")
    idText := "(待分配)"
    try {
        if (HasProp(t, "Id") && t.Id > 0) {
            idText := t.Id
        }
    } catch {
        idText := "(待分配)"
    }
    edId := g.Add("Edit", "x+6 w160 ReadOnly", idText)

    ; 名称/线程
    g.Add("Text", "xm y+8 w100 Right", "名称：")
    edName := g.Add("Edit", "x+6 w160", t.Name)

    g.Add("Text", "x+20 w100 Right", "线程：")
    ddThr := g.Add("DropDownList", "x+6 w160")
    thNames := []
    thIds := []
    try {
        for _, th in App["ProfileData"].Threads {
            thNames.Push(th.Name)
            thIds.Push(th.Id)
        }
    } catch {
    }
    if (thNames.Length = 0) {
        thNames := ["默认线程"]
        thIds := [1]
    }
    try {
        ddThr.Add(thNames)
    } catch {
    }
    sel := 1
    i := 1
    while (i <= thIds.Length) {
        idv := 1
        try {
            idv := thIds[i]
        } catch {
            idv := 1
        }
        curTid := 1
        try {
            curTid := HasProp(t, "ThreadId") ? t.ThreadId : 1
        } catch {
            curTid := 1
        }
        if (idv = curTid) {
            sel := i
            break
        }
        i := i + 1
    }
    ddThr.Value := sel

    ; 时长/最短停留
    g.Add("Text", "xm y+8 w100 Right", "最长(ms)：")
    edMax := g.Add("Edit", "x+6 w160 Number Center", t.MaxDurationMs)

    g.Add("Text", "x+20 w100 Right", "最短停留：")
    edMin := g.Add("Edit", "x+6 w160 Number Center", HasProp(t, "MinStayMs") ? t.MinStayMs : 0)

    ; 下一轨
    g.Add("Text", "xm y+8 w100 Right", "下一轨：")
    ddNext := g.Add("DropDownList", "x+6 w160")
    ids := REUI_ListTrackIds(cfg)
    ids2 := []
    for _, idv in ids {
        if (Integer(idv) > 0) {
            ids2.Push(idv)
        }
    }
    arrNext := ["0"]
    for _, idv in ids2 {
        arrNext.Push(idv)
    }
    try {
        if (arrNext.Length > 0) {
            ddNext.Add(arrNext)
        }
    } catch {
    }
    nextSel := 1
    i := 1
    while (i <= arrNext.Length) {
        v := 0
        try {
            v := Integer(arrNext[i])
        } catch {
            v := 0
        }
        want := 0
        try {
            want := Integer(HasProp(t, "NextTrackId") ? t.NextTrackId : 0)
        } catch {
            want := 0
        }
        if (v = want) {
            nextSel := i
            break
        }
        i := i + 1
    }
    ddNext.Value := nextSel

    ; 监视列表 + 右侧按钮
    g.Add("Text", "xm y+10", "监视（技能计数/黑框确认）：")
    lvW := g.Add("ListView", "xm w620 r8 +Grid", ["技能", "计数", "黑框确认"])
    btnWAdd := g.Add("Button", "x+10 yp w80", "新增")
    btnWEdit := g.Add("Button", "xp yp+34 w80", "编辑")
    btnWDel := g.Add("Button", "xp yp+34 w80", "删除")

    try {
        REUI_TrackEditor_FillWatch(lvW, t)
    } catch {
    }

    btnWAdd.OnEvent("Click", (*) => REUI_WatchEditor_Add(g, t, lvW))
    btnWEdit.OnEvent("Click", (*) => REUI_WatchEditor_Edit(g, t, lvW))
    btnWDel.OnEvent("Click", (*) => REUI_WatchEditor_Del(t, lvW))
    lvW.OnEvent("DoubleClick", (*) => REUI_WatchEditor_Edit(g, t, lvW))

    ; 规则集限制
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
        name := ""
        try {
            name := Trim(edName.Value)
        } catch {
            name := ""
        }
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        try {
            t.Name := name
        } catch {
        }
        try {
            t.ThreadId := (ddThr.Value >= 1 && ddThr.Value <= thIds.Length) ? thIds[ddThr.Value] : 1
        } catch {
            t.ThreadId := 1
        }
        try {
            t.MaxDurationMs := (edMax.Value != "") ? Integer(edMax.Value) : 8000
        } catch {
            t.MaxDurationMs := 8000
        }
        try {
            t.MinStayMs := (edMin.Value != "") ? Integer(edMin.Value) : 0
        } catch {
            t.MinStayMs := 0
        }
        nextIdx := 1
        try {
            nextIdx := REUI_IndexClamp(ddNext.Value, arrNext.Length)
        } catch {
            nextIdx := 1
        }
        nextVal := 0
        try {
            nextVal := Integer(arrNext[nextIdx])
        } catch {
            nextVal := 0
        }
        try {
            t.NextTrackId := nextVal
        } catch {
            t.NextTrackId := 0
        }

        if onSaved {
            onSaved(t, (idx = 0 ? 0 : idx))
        }
        try {
            g.Destroy()
        } catch {
        }
        Notify(isNew ? "已新增轨道" : "已保存轨道")
    }
}

REUI_TrackEditor_FillWatch(lvW, t) {
    try {
        lvW.Opt("-Redraw")
        lvW.Delete()
    } catch {
    }
    try {
        for _, w in t.Watch {
            sName := REUI_Watch_SkillName(HasProp(w, "SkillIndex") ? w.SkillIndex : 0)
            lvW.Add("", sName
                , (HasProp(w, "RequireCount") ? w.RequireCount : 1)
                , (HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0))
        }
        loop 3 {
            try {
                lvW.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            lvW.Opt("+Redraw")
        } catch {
        }
    }
}

REUI_Watch_SkillName(idx) {
    global App
    try {
        if (idx >= 1 && idx <= App["ProfileData"].Skills.Length) {
            return App["ProfileData"].Skills[idx].Name
        }
    } catch {
    }
    return "技能#" idx
}

REUI_WatchEditor_Add(owner, t, lvW) {
    OnSaved(nw, i) {
        try {
            t.Watch.Push(nw)
            REUI_TrackEditor_FillWatch(lvW, t)
        } catch {
        }
    }
    w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
    REUI_WatchEditor_Open(owner, w, 0, OnSaved)
}

REUI_WatchEditor_Edit(owner, t, lvW) {
    row := 0
    try {
        row := lvW.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一条监视"
        return
    }
    w := t.Watch[row]
    OnSaved(nw, i) {
        try {
            t.Watch[i] := nw
            REUI_TrackEditor_FillWatch(lvW, t)
        } catch {
        }
    }
    REUI_WatchEditor_Open(owner, w, row, OnSaved)
}

REUI_WatchEditor_Del(t, lvW) {
    row := 0
    try {
        row := lvW.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    try {
        t.Watch.RemoveAt(row)
    } catch {
    }
    REUI_TrackEditor_FillWatch(lvW, t)
}

REUI_TrackEditor_RulesLabel(t) {
    cnt := 0
    try {
        cnt := (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) ? t.RuleRefs.Length : 0
    } catch {
        cnt := 0
    }
    return "已选择规则数：" cnt
}

REUI_RuleRefsPicker_Open(owner, t, labRulesCtl) {
    global App
    g3 := 0
    try {
        g3 := Gui("+Owner" owner.Hwnd, "选择规则（勾选并排序）")
    } catch {
        g3 := Gui(, "选择规则（勾选并排序）")
    }
    g3.MarginX := 12, g3.MarginY := 10
    g3.SetFont("s10", "Segoe UI")
    g3.Add("Text", "xm", "所有规则：")
    lvAll := g3.Add("ListView", "xm w360 r12 +Grid", ["ID", "名称", "启用"])
    try {
        for i, r in App["ProfileData"].Rules {
            en := ""
            try {
                en := (HasProp(r, "Enabled") && r.Enabled) ? "√" : ""
            } catch {
                en := ""
            }
            try {
                lvAll.Add("", i, r.Name, en)
            } catch {
            }
        }
    } catch {
    }
    loop 3 {
        try {
            lvAll.ModifyCol(A_Index, "AutoHdr")
        } catch {
        }
    }
    g3.Add("Text", "x+16 yp", "已选择（顺序生效）：")
    lvSel := g3.Add("ListView", "x+0 w360 r12 +Grid", ["序", "ID", "名称"])
    loop 3 {
        try {
            lvSel.ModifyCol(A_Index, "AutoHdr")
        } catch {
        }
    }

    try {
        if (HasProp(t, "RuleRefs") && IsObject(t.RuleRefs)) {
            idx := 0
            for _, id in t.RuleRefs {
                if (id >= 1 && id <= App["ProfileData"].Rules.Length) {
                    idx := idx + 1
                    r := App["ProfileData"].Rules[id]
                    try {
                        lvSel.Add("", idx, id, r.Name)
                    } catch {
                    }
                }
            }
        }
    } catch {
    }

    btnAdd := g3.Add("Button", "xm y+8 w90", "加入 >>")
    btnRem := g3.Add("Button", "x+8 w90", "<< 移除")
    btnUp := g3.Add("Button", "x+20 w80", "上移")
    btnDn := g3.Add("Button", "x+8 w80", "下移")
    btnClr := g3.Add("Button", "x+8 w80", "清空")

    btnOK := g3.Add("Button", "xm y+12 w100", "确定")
    btnCA := g3.Add("Button", "x+8 w100", "取消")

    btnAdd.OnEvent("Click", (*) => AddSel())
    btnRem.OnEvent("Click", (*) => RemoveSel())
    btnUp.OnEvent("Click", (*) => MoveSel(-1))
    btnDn.OnEvent("Click", (*) => MoveSel(1))
    btnClr.OnEvent("Click", (*) => ClearSel())
    btnOK.OnEvent("Click", (*) => SaveSel())
    btnCA.OnEvent("Click", (*) => g3.Destroy())
    g3.OnEvent("Close", (*) => g3.Destroy())

    g3.Show()

    ExistsInSel(id) {
        cnt := 0
        try {
            cnt := lvSel.GetCount()
        } catch {
            cnt := 0
        }
        if (cnt <= 0) {
            return 0
        }
        i := 1
        while (i <= cnt) {
            cur := 0
            try {
                cur := Integer(lvSel.GetText(i, 2))
            } catch {
                cur := 0
            }
            if (cur = Integer(id)) {
                return i
            }
            i := i + 1
        }
        return 0
    }

    RenumberSel() {
        cnt := 0
        try {
            cnt := lvSel.GetCount()
        } catch {
            cnt := 0
        }
        if (cnt <= 0) {
            return
        }
        i := 1
        while (i <= cnt) {
            try {
                lvSel.Modify(i, , i)
            } catch {
            }
            i := i + 1
        }
    }

    AddSel() {
        row := 0
        try {
            row := lvAll.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        id := 0
        name := ""
        try {
            id := Integer(lvAll.GetText(row, 1))
            name := lvAll.GetText(row, 2)
        } catch {
            id := 0
            name := ""
        }
        if (ExistsInSel(id)) {
            return
        }
        pos := 1
        try {
            pos := lvSel.GetCount() + 1
        } catch {
            pos := 1
        }
        try {
            lvSel.Add("", pos, id, name)
            lvSel.Modify(pos, "Select Focus Vis")
        } catch {
        }
    }

    RemoveSel() {
        row := 0
        try {
            row := lvSel.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        try {
            lvSel.Delete(row)
        } catch {
        }
        RenumberSel()
        cnt := 0
        try {
            cnt := lvSel.GetCount()
        } catch {
            cnt := 0
        }
        if (cnt >= 1) {
            to := row
            if (to > cnt) {
                to := cnt
            }
            try {
                lvSel.Modify(to, "Select Focus Vis")
            } catch {
            }
        }
    }

    MoveSel(dir) {
        row := 0
        cnt := 0
        try {
            row := lvSel.GetNext(0, "Focused")
            cnt := lvSel.GetCount()
        } catch {
            row := 0
            cnt := 0
        }
        if (!row) {
            return
        }
        to := row + dir
        if (to < 1 || to > cnt) {
            return
        }
        id := ""
        name := ""
        try {
            id := lvSel.GetText(row, 2)
            name := lvSel.GetText(row, 3)
        } catch {
            id := ""
            name := ""
        }
        try {
            lvSel.Delete(row)
            lvSel.Insert(to, "", 0, id, name)
        } catch {
        }
        RenumberSel()
        try {
            lvSel.Modify(to, "Select Focus Vis")
        } catch {
        }
    }

    ClearSel() {
        try {
            lvSel.Delete()
        } catch {
        }
    }

    SaveSel() {
        sel := []
        cnt := 0
        try {
            cnt := lvSel.GetCount()
        } catch {
            cnt := 0
        }
        i := 1
        while (i <= cnt) {
            id := 0
            try {
                id := Integer(lvSel.GetText(i, 2))
            } catch {
                id := 0
            }
            sel.Push(id)
            i := i + 1
        }
        try {
            t.RuleRefs := sel
        } catch {
            t["RuleRefs"] := sel
        }
        try {
            labRulesCtl.Text := REUI_TrackEditor_RulesLabel(t)
        } catch {
        }
        try {
            g3.Destroy()
        } catch {
        }
    }
}
