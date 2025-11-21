#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_Tracks_FillList(lv, cfg) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if HasProp(cfg, "Tracks") {
            if IsObject(cfg.Tracks) {
                for _, t in cfg.Tracks {
                    thName := "默认线程"
                    try {
                        thName := REUI_ThreadNameById(HasProp(t, "ThreadId") ? t.ThreadId : 1)
                    } catch {
                        thName := "默认线程"
                    }
                    wCnt := 0
                    rCnt := 0
                    try {
                        if HasProp(t, "Watch") && IsObject(t.Watch) {
                            wCnt := t.Watch.Length
                        } else {
                            wCnt := 0
                        }
                    } catch {
                        wCnt := 0
                    }
                    try {
                        if HasProp(t, "RuleRefs") && IsObject(t.RuleRefs) {
                            rCnt := t.RuleRefs.Length
                        } else {
                            rCnt := 0
                        }
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
    try {
        if (row < 1 || row > cfg.Tracks.Length) {
            return
        }
    } catch {
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
    try {
        if (cfg.Tracks.Length <= 1) {
            MsgBox "至少保留一条轨道。"
            return
        }
    } catch {
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
    try {
        if (to < 1 || to > cfg.Tracks.Length) {
            return
        }
    } catch {
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
        lv.Modify(to, "Select Focus Vis")
    } catch {
    }
}
