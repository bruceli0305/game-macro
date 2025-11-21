#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_Gates_FillList(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if HasProp(cfg, "Gates") && IsObject(cfg.Gates) {
            for _, g in cfg.Gates {
                pri := HasProp(g, "Priority") ? g.Priority : 0
                frm := HasProp(g, "FromTrackId") ? g.FromTrackId : 0
                tgt := HasProp(g, "ToTrackId") ? g.ToTrackId : 0
                lgc := HasProp(g, "Logic") ? g.Logic : "AND"
                cnt := 0
                try {
                    if HasProp(g, "Conds") && IsObject(g.Conds) {
                        cnt := g.Conds.Length
                    } else {
                        cnt := 0
                    }
                } catch {
                    cnt := 0
                }
                try {
                    lv.Add("", pri, frm, tgt, lgc, cnt)
                } catch {
                }
            }
        }
        loop 5 {
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

REUI_Gates_OnAdd(cfg, owner, lv) {
    OnSaved(ng, idx) {
        try {
            cfg.Gates.Push(ng)
            REUI_Gates_Renum(cfg)
            REUI_Gates_FillList(lv, cfg)
        } catch {
        }
    }
    g := { Priority: (HasProp(cfg, "Gates") ? cfg.Gates.Length : 0) + 1, FromTrackId: 0, ToTrackId: 0, Logic: "AND",
        Conds: [] }
    REUI_GateEditor_Open(owner, cfg, g, 0, OnSaved)
}

REUI_Gates_OnEdit(lv, cfg, owner) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一个跳轨规则"
        return
    }
    try {
        if (row < 1 || row > cfg.Gates.Length) {
            return
        }
    } catch {
        return
    }
    cur := cfg.Gates[row]
    OnSaved(ng, i) {
        try {
            cfg.Gates[i] := ng
            REUI_Gates_Renum(cfg)
            REUI_Gates_FillList(lv, cfg)
        } catch {
        }
    }
    REUI_GateEditor_Open(owner, cfg, cur, row, OnSaved)
}

REUI_Gates_OnDel(lv, cfg, owner) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请选择一个跳轨规则"
        return
    }
    try {
        cfg.Gates.RemoveAt(row)
    } catch {
    }
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    Notify("已删除跳轨规则")
}

REUI_Gates_OnMove(lv, cfg, dir) {
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
    try {
        if (to < 1 || to > cfg.Gates.Length) {
            return
        }
    } catch {
        return
    }
    item := cfg.Gates[from]
    try {
        cfg.Gates.RemoveAt(from)
    } catch {
    }
    try {
        cfg.Gates.InsertAt(to, item)
    } catch {
    }
    REUI_Gates_Renum(cfg)
    REUI_Gates_FillList(lv, cfg)
    try {
        lv.Modify(to, "Select Focus Vis")
    } catch {
    }
}
