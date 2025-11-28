#Requires AutoHotkey v2
;modules\ui\rotation\components\gates\Gates_List.ahk
#Include "..\..\RE_UI_Common.ahk"

REUI_Gates_FillList(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }

    ; 预构建 TrackId → TrackName 映射
    trackNames := Map()
    try {
        if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length > 0) {
            for _, t in cfg.Tracks {
                tid := 0
                tname := ""
                try {
                    tid := OM_Get(t, "Id", 0)
                } catch {
                    tid := 0
                }
                try {
                    tname := OM_Get(t, "Name", "")
                } catch {
                    tname := ""
                }
                if (tid > 0) {
                    if (tname = "") {
                        tname := "轨道#" tid
                    }
                    try {
                        trackNames[tid] := tname
                    } catch {
                    }
                }
            }
        }
    } catch {
    }

    ; 填充 Gate 列表，来源/目标用名称回显
    try {
        if (HasProp(cfg, "Gates") && IsObject(cfg.Gates)) {
            for _, g in cfg.Gates {
                pri := 0
                frm := 0
                tgt := 0
                lgc := "AND"
                cnt := 0
                try {
                    pri := HasProp(g, "Priority") ? g.Priority : OM_Get(g, "Priority", 0)
                } catch {
                    pri := 0
                }
                try {
                    frm := HasProp(g, "FromTrackId") ? g.FromTrackId : OM_Get(g, "FromTrackId", 0)
                } catch {
                    frm := 0
                }
                try {
                    tgt := HasProp(g, "ToTrackId") ? g.ToTrackId : OM_Get(g, "ToTrackId", 0)
                } catch {
                    tgt := 0
                }
                try {
                    lgc := HasProp(g, "Logic") ? g.Logic : OM_Get(g, "Logic", "AND")
                } catch {
                    lgc := "AND"
                }
                try {
                    if (HasProp(g, "Conds") && IsObject(g.Conds)) {
                        cnt := g.Conds.Length
                    } else {
                        cnt := 0
                    }
                } catch {
                    cnt := 0
                }

                frmTxt := "轨道#" frm
                tgtTxt := "轨道#" tgt
                try {
                    if (trackNames.Has(frm)) {
                        frmTxt := trackNames[frm]
                    }
                } catch {
                }
                try {
                    if (trackNames.Has(tgt)) {
                        tgtTxt := trackNames[tgt]
                    }
                } catch {
                }

                try {
                    lv.Add("", pri, frmTxt, tgtTxt, lgc, cnt)
                } catch {
                }
            }
        }

        i := 1
        while (i <= 5) {
            try {
                lv.ModifyCol(i, "AutoHdr")
            } catch {
            }
            i := i + 1
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
