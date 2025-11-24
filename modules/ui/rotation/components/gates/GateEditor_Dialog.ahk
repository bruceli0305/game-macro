#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_GateEditor_Open(owner, cfg, g, idx := 0, onSaved := 0) {
    global UI
    isNew := (idx = 0)
    if !IsObject(g) {
        g := {}
    }
    if !HasProp(g, "Priority") {
        len := 0
        try {
            if HasProp(cfg, "Gates") && IsObject(cfg.Gates) {
                len := cfg.Gates.Length
            } else {
                len := 0
            }
        } catch {
            len := 0
        }
        g.Priority := isNew ? (len + 1) : idx
    }
    if !HasProp(g, "FromTrackId") {
        g.FromTrackId := 0
    }
    if !HasProp(g, "ToTrackId") {
        g.ToTrackId := 0
    }
    if !HasProp(g, "Logic") {
        g.Logic := "AND"
    }
    if !HasProp(g, "Conds") || !IsObject(g.Conds) {
        g.Conds := []
    }
    ownHwnd := 0
    try {
        ownHwnd := owner.Hwnd
    } catch {
        try {
            ownHwnd := UI.Main.Hwnd
        } catch {
            ownHwnd := 0
        }
    }
    ge := Gui(ownHwnd ? Format("+Owner {}", ownHwnd) : "", isNew ? "新增跳轨" : "编辑跳轨")
    ge.MarginX := 12
    ge.MarginY := 10
    ge.SetFont("s10", "Segoe UI")

    ge.Add("Text", "w90 Right", "优先级：")
    edPri := ge.Add("Edit", "x+6 w120 Number", g.Priority)

    trackIds := []
    trackLabels := []
    try {
        if HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) {
            for _, t in cfg.Tracks {
                idv := 0
                try {
                    idv := HasProp(t, "Id") ? Integer(t.Id) : 0
                } catch {
                    idv := 0
                }
                if (idv > 0) {
                    nm := ""
                    try {
                        nm := HasProp(t, "Name") ? "" t.Name : ""
                    } catch {
                        nm := ""
                    }
                    if (nm = "") {
                        nm := "轨道" idv
                    }
                    trackIds.Push(idv)
                    trackLabels.Push(nm)
                }
            }
        }
    } catch {
    }

    ge.Add("Text", "xm y+8 w90 Right", "来源轨：")
    ddFrom := ge.Add("DropDownList", "x+6 w220")
    try {
        if (trackLabels.Length > 0) {
            ddFrom.Add(trackLabels)
        }
    } catch {
    }
    selFrom := 1
    i := 1
    while (i <= trackIds.Length) {
        v := 0
        try {
            v := trackIds[i]
        } catch {
            v := 0
        }
        want := 0
        try {
            want := Integer(g.FromTrackId)
        } catch {
            want := 0
        }
        if (v = want) {
            selFrom := i
            break
        }
        i := i + 1
    }
    ddFrom.Value := (trackLabels.Length > 0) ? selFrom : 0

    ge.Add("Text", "x+20 w90 Right", "目标轨：")
    ddTo := ge.Add("DropDownList", "x+6 w220")
    try {
        if (trackLabels.Length > 0) {
            ddTo.Add(trackLabels)
        }
    } catch {
    }
    selTo := 1
    i := 1
    while (i <= trackIds.Length) {
        v := 0
        try {
            v := trackIds[i]
        } catch {
            v := 0
        }
        want := 0
        try {
            want := Integer(g.ToTrackId)
        } catch {
            want := 0
        }
        if (v = want) {
            selTo := i
            break
        }
        i := i + 1
    }
    ddTo.Value := (trackLabels.Length > 0) ? selTo : 0

    ge.Add("Text", "xm y+8 w90 Right", "逻辑：")
    ddLogic := ge.Add("DropDownList", "x+6 w120", ["AND", "OR"])
    try {
        ddLogic.Value := (StrUpper(g.Logic) = "OR") ? 2 : 1
    } catch {
        ddLogic.Value := 1
    }

    ge.Add("Text", "xm y+8", "条件：")
    lvC := ge.Add("ListView", "xm w760 r9 +Grid", ["类型", "摘要"])
    btnCAdd := ge.Add("Button", "xm y+8 w90", "新增")
    btnCEdit := ge.Add("Button", "x+8 w90", "编辑")
    btnCDel := ge.Add("Button", "x+8 w90", "删除")

    REUI_GateEditor_FillConds(lvC, g)

    btnCAdd.OnEvent("Click", (*) => REUI_CondEditor_OnAdd(lvC, ge, cfg, g))
    btnCEdit.OnEvent("Click", (*) => REUI_CondEditor_OnEdit(lvC, ge, cfg, g))
    btnCDel.OnEvent("Click", (*) => REUI_CondEditor_OnDel(lvC, g))
    lvC.OnEvent("DoubleClick", (*) => REUI_CondEditor_OnEdit(lvC, ge, cfg, g))

    btnOK := ge.Add("Button", "xm y+12 w100", "保存")
    btnCA := ge.Add("Button", "x+8 w100", "取消")
    btnOK.OnEvent("Click", SaveGate)
    btnCA.OnEvent("Click", (*) => ge.Destroy())
    ge.OnEvent("Close", (*) => ge.Destroy())
    ge.Show()

    SaveGate(*) {
        p := 1
        try {
            if (edPri.Value != "") {
                p := Integer(edPri.Value)
            } else {
                p := (idx = 0 ? 1 : idx)
            }
        } catch {
            p := (idx = 0 ? 1 : idx)
        }
        if (p < 1) {
            p := 1
        }
        try {
            g.Priority := p
        } catch {
        }

        if (trackIds.Length <= 0) {
            MsgBox "当前没有可用的轨道，请先在“轨道”页新增。"
            return
        }

        fromPos := 1
        toPos := 1
        try {
            fromPos := ddFrom.Value
        } catch {
            fromPos := 1
        }
        try {
            toPos := ddTo.Value
        } catch {
            toPos := 1
        }
        if (fromPos < 1 || fromPos > trackIds.Length) {
            fromPos := 1
        }
        if (toPos < 1 || toPos > trackIds.Length) {
            toPos := 1
        }

        fromId := 0
        toId := 0
        try {
            fromId := trackIds[fromPos]
        } catch {
            fromId := 0
        }
        try {
            toId := trackIds[toPos]
        } catch {
            toId := 0
        }

        try {
            g.FromTrackId := fromId
        } catch {
        }
        try {
            g.ToTrackId := toId
        } catch {
        }
        try {
            g.Logic := (ddLogic.Value = 2) ? "OR" : "AND"
        } catch {
            g.Logic := "AND"
        }

        if onSaved {
            try {
                onSaved(g, (idx = 0 ? 0 : idx))
            } catch {
            }
        }
        try {
            ge.Destroy()
        } catch {
        }
        Notify(isNew ? "已新增跳轨" : "已保存跳轨")
    }
}

REUI_GateEditor_FillConds(lv, g) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if HasProp(g, "Conds") && IsObject(g.Conds) {
            for _, c in g.Conds {
                try {
                    lv.Add("", HasProp(c, "Kind") ? c.Kind : "?", REUI_GateCond_Summary(c))
                } catch {
                }
            }
        }
        loop 2 {
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
