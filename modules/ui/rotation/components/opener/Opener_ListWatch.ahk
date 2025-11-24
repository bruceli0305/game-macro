#Requires AutoHotkey v2
; Watch 列表与编辑器（技能计数/黑框确认）

REUI_Opener_FillWatch(lv, cfg) {
    REUI_EnsureIdMaps()
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }
    try {
        if (HasProp(cfg, "Opener") && HasProp(cfg.Opener, "Watch") && IsObject(cfg.Opener.Watch)) {
            for _, w in cfg.Opener.Watch {
                sIdx := 0
                try {
                    sIdx := HasProp(w, "SkillIndex") ? w.SkillIndex : 0
                } catch {
                    sIdx := 0
                }
                sName := REUI_Opener_SkillName(sIdx)
                req := 1
                vb := 0
                try {
                    req := HasProp(w, "RequireCount") ? w.RequireCount : 1
                } catch {
                    req := 1
                }
                try {
                    vb := HasProp(w, "VerifyBlack") ? (w.VerifyBlack ? 1 : 0) : 0
                } catch {
                    vb := 0
                }
                try {
                    lv.Add("", sName, req, vb)
                } catch {
                }
            }
        }
        Loop 3 {
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

REUI_Opener_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    global App
    if (!IsObject(w)) {
        w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    }
    REUI_EnsureIdMaps()
    title := "新增监视"
    if (idx != 0) {
        title := "编辑监视"
    }
    g2 := Gui("+Owner" owner.Hwnd, title)
    g2.MarginX := 12
    g2.MarginY := 10
    g2.SetFont("s10", "Segoe UI")

    g2.Add("Text", "w90 Right", "技能：")
    ddS := g2.Add("DropDownList", "x+6 w260")

    cnt := 0
    try {
        cnt := App["ProfileData"].Skills.Length
    } catch {
        cnt := 0
    }
    if (cnt > 0) {
        names := []
        try {
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
        } catch {
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
        try {
            ddS.Value := REUI_IndexClamp(defIdx, names.Length)
            ddS.Enabled := true
        } catch {
        }
    } else {
        try {
            ddS.Add(["（无技能）"])
        } catch {
        }
        try {
            ddS.Value := 1
            ddS.Enabled := false
        } catch {
        }
    }

    g2.Add("Text", "xm y+8 w90 Right", "计数：")
    edReq := g2.Add("Edit", "x+6 w260 Number Center", HasProp(w, "RequireCount") ? w.RequireCount : 1)

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

    try {
        g2.Show()
    } catch {
    }

    SaveWatch(*) {
        if (!ddS.Enabled) {
            MsgBox "当前没有可引用的技能。"
            return
        }
        si := 1
        try {
            si := ddS.Value ? ddS.Value : 1
        } catch {
            si := 1
        }
        req := 1
        vb := 0
        try {
            req := (edReq.Value != "") ? Integer(edReq.Value) : 1
        } catch {
            req := 1
        }
        try {
            vb := cbVB.Value ? 1 : 0
        } catch {
            vb := 0
        }
        nw := { SkillIndex: si, RequireCount: req, VerifyBlack: vb }

        if (onSaved) {
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

REUI_Opener_WatchAdd(owner, cfg, lv) {
    w := { SkillIndex:1, RequireCount:1, VerifyBlack:0 }
    REUI_Opener_WatchEditor_Open(owner, w, 0, OnSaved)
    OnSaved(nw, i) {
        try {
            cfg.Opener.Watch.Push(nw)
            REUI_Opener_FillWatch(lv, cfg)
        } catch {
        }
    }
}

REUI_Opener_WatchEdit(owner, cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (row = 0) {
        MsgBox "请选择一条监视"
        return
    }
    w := cfg.Opener.Watch[row]
    REUI_Opener_WatchEditor_Open(owner, w, row, OnSaved)
    OnSaved(nw, i) {
        try {
            cfg.Opener.Watch[i] := nw
            REUI_Opener_FillWatch(lv, cfg)
        } catch {
        }
    }
}

REUI_Opener_WatchDel(cfg, lv) {
    row := 0
    try {
        row := lv.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (row = 0) {
        return
    }
    try {
        cfg.Opener.Watch.RemoveAt(row)
        REUI_Opener_FillWatch(lv, cfg)
    } catch {
    }
}