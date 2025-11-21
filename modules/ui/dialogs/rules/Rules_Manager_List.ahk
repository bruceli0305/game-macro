#Requires AutoHotkey v2
; Rules_Manager_List.ahk
; 规则管理器：列表与操作（保存委托 Rules_Manager_Save）
; 导出：RulesManager_Show()

#Include "Rules_UI_Common.ahk"

RulesManager_Show() {
    global App
    if !(IsSet(App) && App.Has("ProfileData")) {
        MsgBox "配置未加载。"
        return
    }
    prof := App["ProfileData"]

    dlg := Gui("+Owner" UI.Main.Hwnd, "技能循环 - 规则管理")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12
    dlg.MarginY := 10

    dlg.Add("Text", "xm", "规则列表：")
    lv := dlg.Add("ListView", "xm w760 r14 +Grid", ["ID", "启用", "名称", "逻辑", "条件数", "动作数", "冷却ms", "优先级", "动作间隔", "线程"])
    btnAdd := dlg.Add("Button", "xm w90", "新增规则")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑规则")
    btnDel := dlg.Add("Button", "x+8 w90", "删除规则")
    btnUp := dlg.Add("Button", "x+8 w90", "上移")
    btnDn := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w100", "保存")

    RM_RefreshLV()

    lv.OnEvent("DoubleClick", (*) => RM_EditSel())
    btnAdd.OnEvent("Click", (*) => RM_Add())
    btnEdit.OnEvent("Click", (*) => RM_EditSel())
    btnDel.OnEvent("Click", (*) => RM_DelSel())
    btnUp.OnEvent("Click", (*) => RM_MoveSel(-1))
    btnDn.OnEvent("Click", (*) => RM_MoveSel(1))
    btnSave.OnEvent("Click", (*) => RM_Save())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show()

    RM_RefreshLV() {
        try {
            lv.Opt("-Redraw")
            lv.Delete()
        } catch {
        }
        try {
            for i, r in prof.Rules {
                rid := 0
                en := ""
                name := ""
                logic := "AND"
                cc := 0
                ac := 0
                cd := 0
                prio := i
                gap := 60
                tname := ""

                try rid := OM_Get(r, "Id", 0)
                try en := (OM_Get(r, "Enabled", 1) ? "√" : "")
                try name := OM_Get(r, "Name", "Rule")
                try logic := OM_Get(r, "Logic", "AND")
                try cc := (HasProp(r, "Conditions") && IsObject(r.Conditions)) ? r.Conditions.Length : 0
                try ac := (HasProp(r, "Actions") && IsObject(r.Actions)) ? r.Actions.Length : 0
                try cd := OM_Get(r, "CooldownMs", 0)
                try prio := OM_Get(r, "Priority", i)
                try gap := OM_Get(r, "ActionGapMs", 60)
                try {
                    tid := OM_Get(r, "ThreadId", 1)
                    tname := RE_Rules_ThreadNameById(tid)
                }
                lv.Add("", rid, en, name, logic, cc, ac, cd, prio, gap, tname)
            }
            RE_LV_AutoHdr(lv, 10)
        } catch {
        } finally {
            try lv.Opt("+Redraw")
        }
    }

    RM_Add() {
        newR := { Id: 0, Name: "新规则", Enabled: 1, Logic: "AND", CooldownMs: 500, Priority: prof.Rules.Length + 1, ActionGapMs: 60
                , Conditions: [], Actions: [], LastFire: 0, ThreadId: 1 }
        RuleEditor_Open(newR, 0, OnSavedNew)
    }
    OnSavedNew(savedR, idx) {
        try {
            if !HasProp(savedR, "Id") {
                savedR.Id := 0
            }
        } catch {
        }
        prof.Rules.Push(savedR)
        RM_RefreshLV()
    }

    RM_GetSelected() {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        return row
    }

    RM_EditSel() {
        row := RM_GetSelected()
        if (!row) {
            MsgBox "请先选中一个规则。"
            return
        }
        cur := prof.Rules[row]
        RuleEditor_Open(cur, row, OnSavedEdit)
    }
    OnSavedEdit(savedR, idx2) {
        try {
            old := prof.Rules[idx2]
            if (old && HasProp(old, "Id")) {
                savedR.Id := old.Id
            }
        } catch {
        }
        prof.Rules[idx2] := savedR
        RM_RefreshLV()
    }

    RM_DelSel() {
        row := RM_GetSelected()
        if (!row) {
            MsgBox "请先选中一个规则。"
            return
        }
        prof.Rules.RemoveAt(row)
        for i, r in prof.Rules {
            try r.Priority := i
        }
        RM_RefreshLV()
        Notify("已删除规则")
    }

    RM_MoveSel(dir) {
        row := RM_GetSelected()
        if (!row) {
            return
        }
        from := row
        to := from + dir
        try {
            if (to < 1 || to > prof.Rules.Length) {
                return
            }
        } catch {
            return
        }
        item := prof.Rules[from]
        try prof.Rules.RemoveAt(from)
        try prof.Rules.InsertAt(to, item)
        for i, r in prof.Rules {
            try r.Priority := i
        }
        RM_RefreshLV()
        try lv.Modify(to, "Select Focus Vis")
    }

    RM_Save() {
        name := ""
        try {
            name := App["CurrentProfile"]
        } catch {
            name := ""
        }
        if (name = "") {
            MsgBox "未选择配置。"
            return
        }
        ok := false
        try {
            ok := RM_SaveAll(name)
        } catch {
            ok := false
        }
        if (!ok) {
            MsgBox "保存失败。"
            return
        }
        RM_RefreshLV()
        Notify("循环配置已保存")
    }
}