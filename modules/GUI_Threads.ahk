; GUI_Threads.ahk - 线程配置管理（多进程池）

ThreadsManager_Show() {
    global App
    dlg := Gui(, "线程配置（工作进程池）")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    lv := dlg.Add("ListView", "xm w520 r12 +Grid", ["ID","名称"])
    btnAdd  := dlg.Add("Button", "xm w90", "新增线程")
    btnRen  := dlg.Add("Button", "x+8 w90", "重命名")
    btnDel  := dlg.Add("Button", "x+8 w90", "删除")
    btnSave := dlg.Add("Button", "x+20 w100", "保存")
    btnClose:= dlg.Add("Button", "x+8 w100", "关闭")

    FillLV()

    btnAdd.OnEvent("Click", OnAdd)
    btnRen.OnEvent("Click", OnRename)
    btnDel.OnEvent("Click", OnDelete)
    btnSave.OnEvent("Click", OnSave)
    btnClose.OnEvent("Click", (*) => dlg.Destroy())
    lv.OnEvent("DoubleClick", (*) => OnRename())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show()

    FillLV() {
        lv.Opt("-Redraw")
        lv.Delete()
        ths := App["ProfileData"].Threads
        if !IsObject(ths) || ths.Length=0
            ths := App["ProfileData"].Threads := [ { Id:1, Name:"默认线程" } ]
        for _, t in ths
            lv.Add("", t.Id, t.Name)
        loop 2
            lv.ModifyCol(A_Index, "AutoHdr")
        lv.Opt("+Redraw")
    }

    OnAdd(*) {
        name := InputBox("线程名称：", "新增线程").Value
        if (name = "")
            return
        ths := App["ProfileData"].Threads
        newId := ths.Length ? (ths[ths.Length].Id + 1) : 1
        ths.Push({ Id: newId, Name: name })
        FillLV()
    }

    OnRename(*) {
        row := lv.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idText := lv.GetText(row, 1)
        nameText := lv.GetText(row, 2)
        name := InputBox("新名称：", "重命名线程", nameText).Value
        if (name = "")
            return
        ths := App["ProfileData"].Threads
        for i, t in ths {
            if (t.Id = Integer(idText)) {
                t.Name := name
                break
            }
        }
        FillLV()
    }

    OnDelete(*) {
        ths := App["ProfileData"].Threads
        if ths.Length <= 1 {
            MsgBox "至少保留一个线程。"
            return
        }
        row := lv.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idDel := Integer(lv.GetText(row, 1))
        ; 检查是否被规则/BUFF引用
        if HasProp(App["ProfileData"], "Rules") {
            for _, r in App["ProfileData"].Rules {
                if (HasProp(r,"ThreadId") && r.ThreadId=idDel) {
                    MsgBox "该线程被规则引用，不能删除。请先修改规则。"
                    return
                }
            }
        }
        if HasProp(App["ProfileData"], "Buffs") {
            for _, b in App["ProfileData"].Buffs {
                if (HasProp(b,"ThreadId") && b.ThreadId=idDel) {
                    MsgBox "该线程被 BUFF 引用，不能删除。请先修改 BUFF。"
                    return
                }
            }
        }
        ; 删除
        for i, t in ths {
            if (t.Id = idDel) {
                ths.RemoveAt(i)
                break
            }
        }
        FillLV()
    }

    OnSave(*) {
        Storage_SaveProfile(App["ProfileData"])
        WorkerPool_Rebuild()
        Notify("线程配置已保存并重建进程池")
    }
}