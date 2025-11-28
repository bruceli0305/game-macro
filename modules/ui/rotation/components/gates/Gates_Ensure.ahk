#Requires AutoHotkey v2
;modules\ui\rotation\components\gates\Gates_Ensure.ahk
#Include "..\..\RE_UI_Common.ahk"

REUI_Gates_Ensure(cfg) {
    if !IsObject(cfg) {
        return
    }
    if !HasProp(cfg, "Gates") {
        cfg.Gates := []
    } else {
        if !IsObject(cfg.Gates) {
            cfg.Gates := []
        }
    }
    if (cfg.Gates.Length = 0) {
        cfg.Gates.Push({ Priority: 1, FromTrackId: 0, ToTrackId: 0, Logic: "AND", Conds: [] })
    }
    i := 1
    while (i <= cfg.Gates.Length) {
        g := cfg.Gates[i]
        if !HasProp(g, "Priority") {
            g.Priority := i
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
        i := i + 1
    }
}

REUI_Gates_Renum(cfg) {
    if HasProp(cfg, "Gates") && IsObject(cfg.Gates) {
        i := 1
        while (i <= cfg.Gates.Length) {
            try {
                cfg.Gates[i].Priority := i
            } catch {
            }
            i := i + 1
        }
    }
}
