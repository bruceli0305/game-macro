#Requires AutoHotkey v2
;modules\ui\rotation\components\tracks\TrackEditor_Dialog.ahk
#Include "..\..\RE_UI_Common.ahk"

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

    g.Add("Text", "xm y+8 w100 Right", "最长(ms)：")
    edMax := g.Add("Edit", "x+6 w160 Number Center", t.MaxDurationMs)

    g.Add("Text", "x+20 w100 Right", "最短停留：")
    edMin := g.Add("Edit", "x+6 w160 Number Center", HasProp(t, "MinStayMs") ? t.MinStayMs : 0)

    g.Add("Text", "xm y+8 w100 Right", "下一轨：")
    ; 宽度稍微放大一点，方便显示“[id] 名称”
    ddNext := g.Add("DropDownList", "x+6 w220")
    ; 构造两个数组：
    ; arrNextIds    —— 实际保存到配置里的 NextTrackId
    ; arrNextLabels —— 下拉框里显示的文字
    ids := REUI_ListTrackIds(cfg)
    arrNextIds := []
    arrNextLabels := []
    ; 第一项：0，表示不自动跳轨
    try {
        arrNextIds.Push(0)
        arrNextLabels.Push("（不自动跳轨）")
    } catch {
    }

    for _, idv in ids {
        idInt := 0
        try {
            idInt := Integer(idv)
        } catch {
            idInt := 0
        }
        if (idInt <= 0) {
            continue
        }
        try {
            arrNextIds.Push(idInt)
        } catch {
        }
        lbl := ""
        try {
            lbl := REUI_TrackLabelById(cfg, idInt)    ; => "[id] 名称"
        } catch {
            lbl := "轨道#" idInt
        }
        try {
            arrNextLabels.Push(lbl)
        } catch {
        }
    }

    try {
        if (arrNextLabels.Length > 0) {
            ddNext.Add(arrNextLabels)
        }
    } catch {
    }

    ; 根据当前 t.NextTrackId 选中对应项
    want := 0
    try {
        want := Integer(HasProp(t, "NextTrackId") ? t.NextTrackId : 0)
    } catch {
        want := 0
    }
    nextSel := 1
    i := 1
    while (i <= arrNextIds.Length) {
        v := 0
        try {
            v := Integer(arrNextIds[i])
        } catch {
            v := 0
        }
        if (v = want) {
            nextSel := i
            break
        }
        i := i + 1
    }
    ddNext.Value := nextSel

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

    lvW.GetPos(&lvX, &lvY, &lvWidth, &lvHeight)
    yRule := lvY + lvHeight + 10
    g.Add("Text", Format("x{} y{} w100 Right", lvX, yRule), "规则集限制：")
    labRules := g.Add("Text", Format("x{} y{}", lvX + 106, yRule), REUI_TrackEditor_RulesLabel(t))
    btnRules := g.Add("Button", Format("x{} y{} w120", lvX + 106 + 180 + 10, yRule - 2), "选择规则...")
    btnRules.OnEvent("Click", (*) => REUI_RuleRefsPicker_Open(g, t, labRules))

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
            if (ddThr.Value >= 1 && ddThr.Value <= thIds.Length) {
                t.ThreadId := thIds[ddThr.Value]
            } else {
                t.ThreadId := 1
            }
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
            nextIdx := REUI_IndexClamp(ddNext.Value, arrNextIds.Length)
        } catch {
            nextIdx := 1
        }
        nextVal := 0
        try {
            nextVal := Integer(arrNextIds[nextIdx])
        } catch {
            nextVal := 0
        }
        try {
            t.NextTrackId := nextVal
        } catch {
            t.NextTrackId := 0
        }

        if onSaved {
            try {
                onSaved(t, (idx = 0 ? 0 : idx))
            } catch {
            }
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
        if HasProp(t, "Watch") {
            if (IsObject(t.Watch)) {
            for _, w in t.Watch {
                sName := REUI_Watch_SkillName(HasProp(w, "SkillIndex") ? w.SkillIndex : 0)
                cnt := HasProp(w, "RequireCount") ? w.RequireCount : 1
                vb := HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0
                try {
                    lvW.Add("", sName, cnt, vb)
                } catch {
                }
            }
        }
    }
    loop 3 {
        try {
            lvW.ModifyCol(A_Index, "AutoHdr")
        } catch {
        }
    }
}
catch {
}
finally {
    try {
        lvW.Opt("+Redraw")
    } catch {
    }
}
}

REUI_Watch_SkillName(idx) {
    global App
    try {
        if (idx >= 1) {
            if (idx <= App["ProfileData"].Skills.Length) {
                return App["ProfileData"].Skills[idx].Name
            }
        }
    } catch {
    }
    return "技能#" idx
}

; —— 新增：三组 Watch 操作 helper，使按钮绑定有实现 ——
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
