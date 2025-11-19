#Requires AutoHotkey v2
; modules\ui\dialogs\GUI_BuffEditor.ahk
; BUFF 续时配置（v2 安全版：无单行大括号 if、块级回调）

; 管理器（列表与整体保存）
BuffsManager_Show() {
    global App
    prof := App["ProfileData"]

    dlg := Gui("+Owner" UI.Main.Hwnd, "BUFF 配置 - 续时优先释放")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    lv := dlg.Add("ListView", "xm w780 r14 +Grid"
        , ["ID", "启用", "名称", "持续ms", "提前续ms", "技能数", "检测就绪", "线程"])
    btnAdd := dlg.Add("Button", "xm w90", "新增BUFF")
    btnEdit := dlg.Add("Button", "x+8 w90", "编辑BUFF")
    btnDel := dlg.Add("Button", "x+8 w90", "删除BUFF")
    btnUp := dlg.Add("Button", "x+8 w90", "上移")
    btnDn := dlg.Add("Button", "x+8 w90", "下移")
    btnSave := dlg.Add("Button", "x+20 w100", "保存")

    RefreshLV()

    lv.OnEvent("DoubleClick", OnEdit)
    btnAdd.OnEvent("Click", OnAdd)
    btnEdit.OnEvent("Click", OnEdit)
    btnDel.OnEvent("Click", OnDel)
    btnUp.OnEvent("Click", OnUp)
    btnDn.OnEvent("Click", OnDn)
    btnSave.OnEvent("Click", OnSave)
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show()

    RefreshLV() {
        try {
            lv.Opt("-Redraw")
            lv.Delete()
        } catch {
        }
        try {
            if !HasProp(prof, "Buffs") {
                prof.Buffs := []
            }
            for i, b in prof.Buffs {
                id := 0
                en := ""
                name := ""
                dur := 0
                ref := 0
                sc  := 0
                rdy := ""
                tname := ""

                try {
                    id := OM_Get(b, "Id", 0)
                } catch {
                    id := 0
                }
                try {
                    en := (HasProp(b,"Enabled") && b.Enabled) ? "√" : ""
                } catch {
                    en := ""
                }
                try {
                    name := OM_Get(b, "Name", "Buff")
                } catch {
                    name := "Buff"
                }
                try {
                    dur := OM_Get(b, "DurationMs", 0)
                } catch {
                    dur := 0
                }
                try {
                    ref := OM_Get(b, "RefreshBeforeMs", 0)
                } catch {
                    ref := 0
                }
                try {
                    if (HasProp(b,"Skills") && IsObject(b.Skills)) {
                        sc := b.Skills.Length
                    } else {
                        sc := 0
                    }
                } catch {
                    sc := 0
                }
                try {
                    rdy := (HasProp(b,"CheckReady") && b.CheckReady) ? "√" : ""
                } catch {
                    rdy := ""
                }
                tname := ThreadNameById(HasProp(b, "ThreadId") ? b.ThreadId : 1)
                lv.Add("", id, en, name, dur, ref, sc, rdy, tname)
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

    ThreadNameById(id) {
        global App
        if HasProp(App["ProfileData"], "Threads") {
            for _, t in App["ProfileData"].Threads {
                try {
                    if (t.Id = id) {
                        return t.Name
                    }
                } catch {
                }
            }
        }
        return (id = 1) ? "默认线程" : "线程#" id
    }

    OnAdd(*) {
        newB := {
            Id: 0
          , Name: "新BUFF", Enabled: 1, DurationMs: 15000, RefreshBeforeMs: 2000, CheckReady: 1, ThreadId: 1
          , Skills: [], LastTime: 0, NextIdx: 1
        }
        BuffEditor_Open(newB, 0, OnSavedNew)
    }

    OnSavedNew(buff, idx) {
        global App
        App["ProfileData"].Buffs.Push(buff)
        RefreshLV()
    }

    OnEdit(*) {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个 BUFF"
            return
        }
        BuffEditor_Open(prof.Buffs[row], row, OnSavedEdit)
    }

    OnSavedEdit(buff, idx) {
        global App
        App["ProfileData"].Buffs[idx] := buff
        RefreshLV()
    }

    OnDel(*) {
        row := 0
        try {
            row := lv.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            MsgBox "请选择一个 BUFF"
            return
        }
        prof.Buffs.RemoveAt(row)
        RefreshLV()
        Notify("已删除 BUFF")
    }

    OnUp(*) {
        MoveSel(-1)
    }

    OnDn(*) {
        MoveSel(1)
    }

    MoveSel(dir) {
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
        if (to < 1 || to > prof.Buffs.Length) {
            return
        }
        item := prof.Buffs[from]
        prof.Buffs.RemoveAt(from)
        prof.Buffs.InsertAt(to, item)
        RefreshLV()
        try {
            lv.Modify(to, "Select Focus Vis")
        } catch {
        }
    }

    ; 整体保存（走新存储 SaveModule_Buffs → 重载 → 规范化）
    OnSave(*) {
        global App
        if !(IsSet(App) && App.Has("CurrentProfile") && App.Has("ProfileData")) {
            MsgBox "未选择配置或配置未加载。"
            return
        }

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

        p := 0
        try {
            p := Storage_Profile_LoadFull(name)
        } catch {
            MsgBox "加载配置失败。"
            return
        }

        ; 索引 → Id 转换
        newArr := []
        try {
            if (HasProp(App["ProfileData"], "Buffs") && IsObject(App["ProfileData"].Buffs)) {
                skIdByIdx := Map()
                try {
                    if (HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
                        si := 1
                        while (si <= App["ProfileData"].Skills.Length) {
                            sid := 0
                            try {
                                sid := OM_Get(App["ProfileData"].Skills[si], "Id", 0)
                            } catch {
                                sid := 0
                            }
                            skIdByIdx[si] := sid
                            si := si + 1
                        }
                    }
                } catch {
                }

                i := 1
                while (i <= App["ProfileData"].Buffs.Length) {
                    rb := App["ProfileData"].Buffs[i]
                    b := Map()
                    try {
                        b["Id"] := OM_Get(rb, "Id", 0)
                    } catch {
                    }
                    b["Name"]            := OM_Get(rb, "Name", "Buff")
                    b["Enabled"]         := OM_Get(rb, "Enabled", 1)
                    b["DurationMs"]      := OM_Get(rb, "DurationMs", 0)
                    b["RefreshBeforeMs"] := OM_Get(rb, "RefreshBeforeMs", 0)
                    b["CheckReady"]      := OM_Get(rb, "CheckReady", 1)
                    b["ThreadId"]        := OM_Get(rb, "ThreadId", 1)

                    skills := []
                    try {
                        if (HasProp(rb, "Skills") && IsObject(rb.Skills)) {
                            j := 1
                            while (j <= rb.Skills.Length) {
                                idx := 0
                                try {
                                    idx := rb.Skills[j]
                                } catch {
                                    idx := 0
                                }
                                sid := 0
                                try {
                                    sid := skIdByIdx.Has(idx) ? skIdByIdx[idx] : 0
                                } catch {
                                    sid := 0
                                }
                                skills.Push(sid)
                                j := j + 1
                            }
                        }
                    } catch {
                    }
                    b["Skills"] := skills

                    newArr.Push(b)
                    i := i + 1
                }
            }
        } catch {
        }

        p["Buffs"] := newArr

        ok := false
        try {
            SaveModule_Buffs(p)
            ok := true
        } catch {
            ok := false
        }
        if (!ok) {
            MsgBox "保存失败。"
            return
        }

        try {
            p2 := Storage_Profile_LoadFull(name)
            rt := PM_ToRuntime(p2)
            App["ProfileData"] := rt
        } catch {
            MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
            return
        }

        RefreshLV()
        Notify("BUFF 配置已保存")
    }
}

; 编辑器（使用运行时索引模型）
BuffEditor_Open(buff, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)

    ; 填默认字段
    defaults := Map("Name", "新BUFF", "Enabled", 1, "DurationMs", 15000, "RefreshBeforeMs", 2000, "CheckReady", 1)
    for k, v in defaults {
        if !HasProp(buff, k) {
            buff.%k% := v
        }
    }
    if !HasProp(buff, "Skills") {
        buff.Skills := []
    }
    if !HasProp(buff, "LastTime") {
        buff.LastTime := 0
    }
    if !HasProp(buff, "NextIdx") {
        buff.NextIdx := 1
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增 BUFF" : "编辑 BUFF")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    dlg.Add("Text", "w90 Right", "名称：")
    tbName := dlg.Add("Edit", "x+6 w240", buff.Name)
    cbEn := dlg.Add("CheckBox", "x+20 w80", "启用")
    cbEn.Value := buff.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+16 w90 Right", "持续(ms)：")
    edDur := dlg.Add("Edit", "x+6 w240 Number", buff.DurationMs)

    dlg.Add("Text", "x+20 w90 Right", "提前续(ms)：")
    edRef := dlg.Add("Edit", "x+6 w240 Number", buff.RefreshBeforeMs)

    cbReady := dlg.Add("CheckBox", "xm y+8 w160", "检测技能就绪(像素)")
    cbReady.Value := buff.CheckReady ? 1 : 0

    dlg.Add("Text", "xm y+8 w90", "线程：")
    ddThread := dlg.Add("DropDownList", "x+6 w240")
    names := []
    for _, t in App["ProfileData"].Threads {
        names.Push(t.Name)
    }
    if names.Length {
        ddThread.Add(names)
    }
    curTid := HasProp(buff, "ThreadId") ? buff.ThreadId : 1
    ddThread.Value := (curTid >= 1 && curTid <= names.Length) ? curTid : 1

    ; 左：所有技能；右：已选技能
    dlg.Add("Text", "xm y+8", "可选技能：")
    lvAll := dlg.Add("ListView", "xm w360 r10 +Grid", ["ID", "技能名", "键位"])
    dlg.Add("Text", "x+10 yp", "已选技能(按顺序/轮换)：")
    lvSel := dlg.Add("ListView", "x+10 w360 r10 +Grid", ["序", "技能名", "键位"])

    btnAdd := dlg.Add("Button", "xm w90", "添加 >>")
    btnDel := dlg.Add("Button", "x+8 w90", "移除")
    btnUp := dlg.Add("Button", "x+8 w90", "上移")
    btnDn := dlg.Add("Button", "x+8 w90", "下移")

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    ; 填充列表
    FillAll()
    FillSel()

    ; 事件绑定
    lvAll.OnEvent("DoubleClick", OnAddSkill)
    lvSel.OnEvent("DoubleClick", OnDelSel)
    btnAdd.OnEvent("Click", OnAddSkill)
    btnDel.OnEvent("Click", OnDelSel)
    btnUp.OnEvent("Click", OnUpSel)
    btnDn.OnEvent("Click", OnDnSel)
    btnSave.OnEvent("Click", OnSaveBuff)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    FillAll() {
        try {
            lvAll.Opt("-Redraw")
            lvAll.Delete()
        } catch {
        }
        try {
            for i, s in App["ProfileData"].Skills {
                lvAll.Add("", i, s.Name, s.Key)
            }
            loop 3 {
                try {
                    lvAll.ModifyCol(A_Index, "AutoHdr")
                } catch {
                }
            }
        } catch {
        } finally {
            try {
                lvAll.Opt("+Redraw")
            } catch {
            }
        }
    }

    FillSel() {
        try {
            lvSel.Opt("-Redraw")
            lvSel.Delete()
        } catch {
        }
        try {
            for i, si in buff.Skills {
                if (si >= 1 && si <= App["ProfileData"].Skills.Length) {
                    s := App["ProfileData"].Skills[si]
                    lvSel.Add("", i, s.Name, s.Key)
                } else {
                    lvSel.Add("", i, "技能#" si, "?")
                }
            }
            loop 3 {
                try {
                    lvSel.ModifyCol(A_Index, "AutoHdr")
                } catch {
                }
            }
        } catch {
        } finally {
            try {
                lvSel.Opt("+Redraw")
            } catch {
            }
        }
    }

    OnAddSkill(*) {
        row := 0
        try {
            row := lvAll.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        si := 0
        try {
            si := Integer(lvAll.GetText(row, 1))
        } catch {
            si := 0
        }
        buff.Skills.Push(si)
        FillSel()
    }

    OnDelSel(*) {
        row := 0
        try {
            row := lvSel.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        buff.Skills.RemoveAt(row)
        FillSel()
    }

    OnUpSel(*) {
        MoveSel(-1)
    }

    OnDnSel(*) {
        MoveSel(1)
    }

    MoveSel(dir) {
        row := 0
        try {
            row := lvSel.GetNext(0, "Focused")
        } catch {
            row := 0
        }
        if (!row) {
            return
        }
        from := row
        to := from + dir
        if (to < 1 || to > buff.Skills.Length) {
            return
        }
        item := 0
        try {
            item := buff.Skills[from]
        } catch {
            item := 0
        }
        buff.Skills.RemoveAt(from)
        buff.Skills.InsertAt(to, item)
        FillSel()
        try {
            lvSel.Modify(to, "Select Focus Vis")
        } catch {
        }
    }

    OnSaveBuff(*) {
        name := ""
        try {
            name := Trim(tbName.Value)
        } catch {
            name := ""
        }
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        try {
            buff.Name := name
        } catch {
        }
        try {
            buff.Enabled := cbEn.Value ? 1 : 0
        } catch {
        }
        try {
            buff.DurationMs := (edDur.Value != "") ? Integer(edDur.Value) : 0
        } catch {
        }
        try {
            buff.RefreshBeforeMs := (edRef.Value != "") ? Integer(edRef.Value) : 0
        } catch {
        }
        try {
            buff.CheckReady := cbReady.Value ? 1 : 0
        } catch {
        }
        try {
            buff.ThreadId := ddThread.Value ? ddThread.Value : 1
        } catch {
        }

        if !HasProp(buff, "LastTime") {
            try {
                buff.LastTime := 0
            } catch {
            }
        }
        if !HasProp(buff, "NextIdx") {
            try {
                buff.NextIdx := 1
            } catch {
            }
        }

        if onSaved {
            onSaved(buff, idx)
        }
        try {
            dlg.Destroy()
        } catch {
        }
        Notify(isNew ? "已新增 BUFF" : "已保存 BUFF")
    }
}