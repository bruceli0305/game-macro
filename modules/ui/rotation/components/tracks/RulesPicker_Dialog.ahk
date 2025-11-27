#Requires AutoHotkey v2
;modules\ui\rotation\components\tracks\RulesPicker_Dialog.ahk
#Include "..\..\RE_UI_Common.ahk"

REUI_TrackEditor_RulesLabel(t) {
    cnt := 0
    try {
        if HasProp(t, "RuleRefs") && IsObject(t.RuleRefs) {
            cnt := t.RuleRefs.Length
        } else {
            cnt := 0
        }
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
    g3.MarginX := 12
    g3.MarginY := 10
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
        if HasProp(t, "RuleRefs") && IsObject(t.RuleRefs) {
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

    try {
        g3.Show()
    } catch {
    }

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
