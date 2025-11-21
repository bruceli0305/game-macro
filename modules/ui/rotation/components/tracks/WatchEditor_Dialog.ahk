#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_WatchEditor_Open(owner, w, idx := 0, onSaved := 0) {
    global App
    if !IsObject(w) {
        w := { SkillIndex: 1, RequireCount: 1, VerifyBlack: 0 }
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
