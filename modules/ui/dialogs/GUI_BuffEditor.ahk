; GUI_BuffEditor.ahk - BUFF 续时配置（v2 安全版：无单行大括号 if、块级回调）

; 管理器
BuffsManager_Show() {
    global App
    prof := App["ProfileData"]

    dlg := Gui(, "BUFF 配置 - 续时优先释放")
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
        lv.Opt("-Redraw")
        lv.Delete()
        if !HasProp(prof, "Buffs")
            prof.Buffs := []
        for i, b in prof.Buffs {
            tname := ThreadNameById(HasProp(b, "ThreadId") ? b.ThreadId : 1)
            lv.Add("", i
                , (b.Enabled ? "√" : "")
                , b.Name
                , (HasProp(b, "DurationMs") ? b.DurationMs : 0)
                , (HasProp(b, "RefreshBeforeMs") ? b.RefreshBeforeMs : 0)
                , (HasProp(b, "Skills") ? b.Skills.Length : 0)
                , (HasProp(b, "CheckReady") ? b.CheckReady : 1)
                , tname)
        }
        loop 8
            lv.ModifyCol(A_Index, "AutoHdr")
        lv.Opt("+Redraw")
    }
    ThreadNameById(id) {
        global App
        if HasProp(App["ProfileData"], "Threads") {
            for _, t in App["ProfileData"].Threads {
                if (t.Id = id)
                    return t.Name
            }
        }
        return (id = 1) ? "默认线程" : "线程#" id
    }
    OnAdd(*) {
        newB := {
            Name: "新BUFF", Enabled: 1, DurationMs: 15000, RefreshBeforeMs: 2000, CheckReady: 1, Skills: [], LastTime: 0,
            NextIdx: 1
        }
        BuffEditor_Open(newB, 0, OnSavedNew)
    }
    OnSavedNew(buff, idx) {
        global App
        App["ProfileData"].Buffs.Push(buff)
        RefreshLV()
    }

    OnEdit(*) {
        row := lv.GetNext(0, "Focused")
        if !row {
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
        row := lv.GetNext(0, "Focused")
        if !row {
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
        row := lv.GetNext(0, "Focused")
        if !row
            return
        from := row
        to := from + dir
        if (to < 1 || to > prof.Buffs.Length)
            return
        item := prof.Buffs[from]
        prof.Buffs.RemoveAt(from)
        prof.Buffs.InsertAt(to, item)
        RefreshLV()
        lv.Modify(to, "Select Focus Vis")
    }

    OnSave(*) {
        Storage_SaveProfile(prof)
        Notify("BUFF 配置已保存")
    }
}

; 编辑器
BuffEditor_Open(buff, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)

    ; 填默认字段
    defaults := Map("Name", "新BUFF", "Enabled", 1, "DurationMs", 15000, "RefreshBeforeMs", 2000, "CheckReady", 1)
    for k, v in defaults {
        if !HasProp(buff, k)
            buff.%k% := v
    }
    if !HasProp(buff, "Skills")
        buff.Skills := []
    if !HasProp(buff, "LastTime")
        buff.LastTime := 0
    if !HasProp(buff, "NextIdx")
        buff.NextIdx := 1

    dlg := Gui(, isNew ? "新增 BUFF" : "编辑 BUFF")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    dlg.Add("Text", "w60", "名称：")
    tbName := dlg.Add("Edit", "x+6 w240", buff.Name)
    cbEn := dlg.Add("CheckBox", "x+12 w80", "启用")
    cbEn.Value := buff.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w70", "持续(ms)：")
    edDur := dlg.Add("Edit", "x+6 w120 Number", buff.DurationMs)

    dlg.Add("Text", "x+20 w90", "提前续(ms)：")
    edRef := dlg.Add("Edit", "x+6 w120 Number", buff.RefreshBeforeMs)

    cbReady := dlg.Add("CheckBox", "xm y+8 w160", "检测技能就绪(像素)")
    cbReady.Value := buff.CheckReady ? 1 : 0

    dlg.Add("Text", "xm y+8 w60", "线程：")
    ddThread := dlg.Add("DropDownList", "x+6 w200")
    names := []
    for _, t in App["ProfileData"].Threads
        names.Push(t.Name)
    if names.Length
        ddThread.Add(names)
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

    ; ----------------- 内部函数 -----------------
    FillAll() {
        lvAll.Opt("-Redraw")
        lvAll.Delete()
        for i, s in App["ProfileData"].Skills {
            lvAll.Add("", i, s.Name, s.Key)
        }
        loop 3
            lvAll.ModifyCol(A_Index, "AutoHdr")
        lvAll.Opt("+Redraw")
    }

    FillSel() {
        lvSel.Opt("-Redraw")
        lvSel.Delete()
        for i, si in buff.Skills {
            if (si >= 1 && si <= App["ProfileData"].Skills.Length) {
                s := App["ProfileData"].Skills[si]
                lvSel.Add("", i, s.Name, s.Key)
            } else {
                lvSel.Add("", i, "技能#" si, "?")
            }
        }
        loop 3
            lvSel.ModifyCol(A_Index, "AutoHdr")
        lvSel.Opt("+Redraw")
    }

    OnAddSkill(*) {
        row := lvAll.GetNext(0, "Focused")
        if !row
            return
        si := Integer(lvAll.GetText(row, 1))
        buff.Skills.Push(si)
        FillSel()
    }

    OnDelSel(*) {
        row := lvSel.GetNext(0, "Focused")
        if !row
            return
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
        row := lvSel.GetNext(0, "Focused")
        if !row
            return
        from := row
        to := from + dir
        if (to < 1 || to > buff.Skills.Length)
            return
        item := buff.Skills[from]
        buff.Skills.RemoveAt(from)
        buff.Skills.InsertAt(to, item)
        FillSel()
        lvSel.Modify(to, "Select Focus Vis")
    }

    OnSaveBuff(*) {
        name := Trim(tbName.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        buff.Name := name
        buff.Enabled := cbEn.Value ? 1 : 0
        buff.DurationMs := (edDur.Value != "") ? Integer(edDur.Value) : 0
        buff.RefreshBeforeMs := (edRef.Value != "") ? Integer(edRef.Value) : 0
        buff.CheckReady := cbReady.Value ? 1 : 0
        buff.ThreadId := ddThread.Value ? ddThread.Value : 1

        if !HasProp(buff, "LastTime")
            buff.LastTime := 0
        if !HasProp(buff, "NextIdx")
            buff.NextIdx := 1

        if onSaved
            onSaved(buff, idx)
        dlg.Destroy()
        Notify(isNew ? "已新增 BUFF" : "已保存 BUFF")
    }
}
