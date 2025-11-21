#Requires AutoHotkey v2
; Page_Threads_Summary.ahk
; 自动化 → 线程配置（摘要页）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：TH_

Page_Threads_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== 摘要区 ======
    sumH := 26 + 6*22 + 8 + 26 + 10
    UI.TH_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, sumH), "线程配置 - 摘要")
    page.Controls.Push(UI.TH_GB_Sum)

    UI.TH_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r6 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.TH_Info)

    UI.TH_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "刷新")
    page.Controls.Push(UI.TH_BtnRefresh)

    UI.TH_BtnSave := UI.Main.Add("Button", "x+8 w100 h26", "保存")
    page.Controls.Push(UI.TH_BtnSave)

    ; ====== 列表区 ======
    ly := rc.Y + sumH + 10
    listH := Max(220, rc.H - (ly - rc.Y))
    UI.TH_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "线程列表")
    page.Controls.Push(UI.TH_GB_List)

    ; 管理按钮（先创建，确保在 ListView 上层）
    UI.TH_BtnAdd := UI.Main.Add("Button", Format("x{} y{} w90 h26", rc.X + 12, ly + listH - 40), "新增线程")
    page.Controls.Push(UI.TH_BtnAdd)
    UI.TH_BtnRename := UI.Main.Add("Button", "x+8 w90 h26", "重命名")
    page.Controls.Push(UI.TH_BtnRename)
    UI.TH_BtnDel := UI.Main.Add("Button", "x+8 w90 h26", "删除")
    page.Controls.Push(UI.TH_BtnDel)

    ; 列表
    UI.TH_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        , ["ID","名称","规则引用#","BUFF引用#","总引用"])
    page.Controls.Push(UI.TH_LV)

    ; 事件
    UI.TH_BtnRefresh.OnEvent("Click", Threads_OnRefresh)
    UI.TH_BtnSave.OnEvent("Click", Threads_OnSave)
    UI.TH_BtnAdd.OnEvent("Click", Threads_OnAdd)
    UI.TH_BtnRename.OnEvent("Click", Threads_OnRename)
    UI.TH_BtnDel.OnEvent("Click", Threads_OnDelete)
    UI.TH_LV.OnEvent("DoubleClick", Threads_OnRename)

    ; 首次刷新
    Threads_RefreshAll()
}

Page_Threads_Layout(rc) {
    try {
        sumH := 26 + 6*22 + 8 + 26 + 10
        UI.TH_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.TH_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.TH_BtnRefresh.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.TH_BtnSave.Move(UI.TH_BtnRefresh.Pos.X + UI.TH_BtnRefresh.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10
        listH := Max(300, rc.H - (ly - rc.Y))
        UI.TH_GB_List.Move(rc.X, ly, rc.W, listH)

        UI.TH_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 80)

        btnY := ly + listH - 40
        UI.TH_BtnAdd.Move(rc.X + 12, btnY, 90, 26)
        UI.TH_BtnRename.Move(UI.TH_BtnAdd.Pos.X + UI.TH_BtnAdd.Pos.W + 8, btnY, 90, 26)
        UI.TH_BtnDel.Move(UI.TH_BtnRename.Pos.X + UI.TH_BtnRename.Pos.W + 8, btnY, 90, 26)
    } catch {
    }
}

Page_Threads_OnEnter(*) {
    Threads_RefreshAll()
}

; ====== 刷新逻辑 ======

Threads_RefreshAll() {
    Threads_FillSummary()
    Threads_FillList()
}

Threads_FillSummary() {
    global App, UI
    txt := "无线程信息。"
    tot := 0
    used := 0
    orphans := 0
    refs := Map()  ; tid -> { Rules:n, Buffs:n }

    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            for _, t in App["ProfileData"].Threads {
                tid := 0
                try {
                    tid := OM_Get(t, "Id", 0)
                } catch {
                    tid := 0
                }
                refs[tid] := { Rules: 0, Buffs: 0 }
            }
        }

        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            for _, r in App["ProfileData"].Rules {
                tid := 1
                try {
                    tid := OM_Get(r, "ThreadId", 1)
                } catch {
                    tid := 1
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Rules := refs[tid].Rules + 1
            }
        }

        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Buffs")) {
            for _, b in App["ProfileData"].Buffs {
                tid := 1
                try {
                    tid := OM_Get(b, "ThreadId", 1)
                } catch {
                    tid := 1
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Buffs := refs[tid].Buffs + 1
            }
        }

        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            try {
                tot := App["ProfileData"].Threads.Length
            } catch {
                tot := 0
            }
        } else {
            tot := 0
        }

        used := 0
        for tid, m in refs {
            s := 0
            try {
                s := m.Rules + m.Buffs
            } catch {
                s := 0
            }
            if (s > 0) {
                used := used + 1
            }
        }
        orphans := Max(0, tot - used)

        txt := ""
        txt .= "线程总数: " tot "`r`n"
        txt .= "被引用线程: " used "    未被引用: " orphans "`r`n"
        txt .= "引用分布: "
        if (refs.Count = 0) {
            txt .= "-"
        } else {
            first := true
            for k, m in refs {
                sum := 0
                try {
                    sum := m.Rules + m.Buffs
                } catch {
                    sum := 0
                }
                part := "[T" k ":R=" m.Rules ",B=" m.Buffs ",Σ=" sum "]"
                if (first) {
                    txt .= part
                    first := false
                } else {
                    txt .= " " part
                }
            }
        }
    } catch {
        txt := "读取线程摘要失败。"
    }

    try {
        UI.TH_Info.Value := txt
    } catch {
    }
}

Threads_FillList() {
    global App, UI

    refs := Map()
    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            for _, t in App["ProfileData"].Threads {
                tid := 0
                try {
                    tid := OM_Get(t, "Id", 0)
                } catch {
                    tid := 0
                }
                refs[tid] := { Rules: 0, Buffs: 0 }
            }
        }
    } catch {
    }

    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            for _, r in App["ProfileData"].Rules {
                tid := 1
                try {
                    tid := OM_Get(r, "ThreadId", 1)
                } catch {
                    tid := 1
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Rules := refs[tid].Rules + 1
            }
        }
    } catch {
    }

    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Buffs")) {
            for _, b in App["ProfileData"].Buffs {
                tid := 1
                try {
                    tid := OM_Get(b, "ThreadId", 1)
                } catch {
                    tid := 1
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Buffs := refs[tid].Buffs + 1
            }
        }
    } catch {
    }

    try {
        UI.TH_LV.Opt("-Redraw")
        UI.TH_LV.Delete()
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            return
        }
        for _, t in App["ProfileData"].Threads {
            rid := 0
            name := ""
            try {
                rid := OM_Get(t, "Id", 0)
            } catch {
                rid := 0
            }
            try {
                name := HasProp(t,"Name") ? t.Name : ("线程" rid)
            } catch {
                name := "线程" rid
            }
            rc := 0
            bc := 0
            try {
                rc := refs.Has(rid) ? refs[rid].Rules : 0
                bc := refs.Has(rid) ? refs[rid].Buffs : 0
            } catch {
                rc := 0
                bc := 0
            }
            sum := rc + bc
            UI.TH_LV.Add("", rid, name, rc, bc, sum)
        }
        loop 5 {
            try {
                UI.TH_LV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            UI.TH_LV.Opt("+Redraw")
        } catch {
        }
    }
}

; ====== 事件 ======

Threads_OnAdd(*) {
    global App
    try {
        ib := InputBox("线程名称：", "新增线程")
        if (ib.Result = "Cancel") {
            return
        }
        name := Trim(ib.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            App["ProfileData"].Threads := []
        }
        ths := App["ProfileData"].Threads

        ; 生成新 Id：当前最大 Id + 1（避免按顺序依赖）
        maxId := 0
        i := 1
        while (i <= ths.Length) {
            tid := 0
            try {
                tid := OM_Get(ths[i], "Id", 0)
            } catch {
                tid := 0
            }
            if (tid > maxId) {
                maxId := tid
            }
            i := i + 1
        }
        newId := maxId + 1
        ths.Push({ Id: newId, Name: name })
        Threads_RefreshAll()
    } catch as e {
        MsgBox "新增线程失败: " e.Message
    }
}

Threads_OnRename(*) {
    global App, UI
    try {
        row := UI.TH_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idText := ""
        nameText := ""
        try {
            idText := UI.TH_LV.GetText(row, 1)
            nameText := UI.TH_LV.GetText(row, 2)
        } catch {
            idText := ""
            nameText := ""
        }
        ib := InputBox("新名称：", "重命名线程",, nameText)
        if (ib.Result = "Cancel") {
            return
        }
        name := Trim(ib.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            return
        }
        ths := App["ProfileData"].Threads
        i := 1
        idNum := 0
        try {
            idNum := Integer(idText)
        } catch {
            idNum := 0
        }
        while (i <= ths.Length) {
            tid := 0
            try {
                tid := OM_Get(ths[i], "Id", 0)
            } catch {
                tid := 0
            }
            if (tid = idNum) {
                try {
                    ths[i].Name := name
                } catch {
                }
                break
            }
            i := i + 1
        }
        Threads_RefreshAll()
    } catch as e {
        MsgBox "重命名线程失败: " e.Message
    }
}

Threads_OnDelete(*) {
    global App, UI
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            return
        }
        ths := App["ProfileData"].Threads
        if (ths.Length <= 1) {
            MsgBox "至少保留一个线程。"
            return
        }
        row := UI.TH_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idDel := 0
        try {
            idDel := Integer(UI.TH_LV.GetText(row, 1))
        } catch {
            idDel := 0
        }

        ; 检查规则/BUFF/默认技能引用
        if HasProp(App["ProfileData"], "Rules") {
            for _, r in App["ProfileData"].Rules {
                try {
                    if (HasProp(r,"ThreadId") && r.ThreadId = idDel) {
                        MsgBox "该线程被规则引用，不能删除。请先修改规则。"
                        return
                    }
                } catch {
                }
            }
        }
        if HasProp(App["ProfileData"], "Buffs") {
            for _, b in App["ProfileData"].Buffs {
                try {
                    if (HasProp(b,"ThreadId") && b.ThreadId = idDel) {
                        MsgBox "该线程被 BUFF 引用，不能删除。请先修改 BUFF。"
                        return
                    }
                } catch {
                }
            }
        }
        if HasProp(App["ProfileData"], "DefaultSkill") {
            try {
                if (HasProp(App["ProfileData"].DefaultSkill, "ThreadId") && App["ProfileData"].DefaultSkill.ThreadId = idDel) {
                    MsgBox "该线程被默认技能引用，不能删除。请先修改默认技能。"
                    return
                }
            } catch {
            }
        }

        ; 删除
        i := 1
        while (i <= ths.Length) {
            tid := 0
            try {
                tid := OM_Get(ths[i], "Id", 0)
            } catch {
                tid := 0
            }
            if (tid = idDel) {
                ths.RemoveAt(i)
                break
            }
            i := i + 1
        }
        Threads_RefreshAll()
    } catch as e {
        MsgBox "删除线程失败: " e.Message
    }
}

Threads_OnSave(*) {
    global App
    try {
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

        ; 回写文件夹模型的 General.Threads
        newThs := []
        try {
            if !(p.Has("General")) {
                p["General"] := Map()
            }
            i := 1
            while (i <= App["ProfileData"].Threads.Length) {
                t := App["ProfileData"].Threads[i]
                tid := 0
                tname := ""
                try {
                    tid := OM_Get(t, "Id", i)
                } catch {
                    tid := i
                }
                try {
                    tname := OM_Get(t, "Name", "线程" tid)
                } catch {
                    tname := "线程" tid
                }
                newThs.Push(Map("Id", tid, "Name", tname))
                i := i + 1
            }
            g := p["General"]
            g["Threads"] := newThs
            p["General"] := g
        } catch {
        }

        ok := false
        try {
            SaveModule_General(p)
            ok := true
        } catch {
            ok := false
        }
        if (!ok) {
            MsgBox "保存线程配置失败。"
            return
        }

        ; 重载 → 规范化 → 轻量重建
        try {
            p2 := Storage_Profile_LoadFull(name)
            rt := PM_ToRuntime(p2)
            App["ProfileData"] := rt
        } catch {
            MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
            return
        }

        try {
            WorkerPool_Rebuild()
        } catch {
        }

        Threads_RefreshAll()
        Notify("线程配置已保存并重建进程池")
    } catch as e {
        MsgBox "保存线程配置失败: " e.Message
    }
}

Threads_OnRefresh(*) {
    Threads_RefreshAll()
}