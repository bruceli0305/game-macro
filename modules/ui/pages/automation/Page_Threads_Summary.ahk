#Requires AutoHotkey v2
;Page_Threads_Summary.ahk
; 自动化 → 线程配置（摘要页）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：TH_

Page_Threads_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== 摘要区 ======
    ; 计算摘要区实际需要的高度：标题栏26 + 文本编辑框6行(6*22) + 按钮间距8 + 按钮高度26 + 底部间距10 = 196
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
    ly := rc.Y + sumH + 10  ; 使用实际摘要区高度计算列表区位置
    listH := Max(220, rc.H - (ly - rc.Y))
    UI.TH_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "线程列表")
    page.Controls.Push(UI.TH_GB_List)

    ; 先创建管理按钮，确保它们在Z顺序上位于ListView之上
    UI.TH_BtnAdd := UI.Main.Add("Button", Format("x{} y{} w90 h26", rc.X + 12, ly + listH - 40), "新增线程")
    page.Controls.Push(UI.TH_BtnAdd)
    
    UI.TH_BtnRename := UI.Main.Add("Button", "x+8 w90 h26", "重命名")
    page.Controls.Push(UI.TH_BtnRename)
    
    UI.TH_BtnDel := UI.Main.Add("Button", "x+8 w90 h26", "删除")
    page.Controls.Push(UI.TH_BtnDel)
    
    ; 最后创建ListView，这样按钮会在ListView上方显示
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
        ; 计算摘要区实际需要的高度：标题栏26 + 文本编辑框6行(6*22) + 按钮间距8 + 按钮高度26 + 底部间距10 = 196
        sumH := 26 + 6*22 + 8 + 26 + 10
        
        UI.TH_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.TH_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.TH_BtnRefresh.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.TH_BtnSave.Move(UI.TH_BtnRefresh.Pos.X + UI.TH_BtnRefresh.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10  ; 使用实际摘要区高度计算列表区位置
        listH := Max(300, rc.H - (ly - rc.Y))
        UI.TH_GB_List.Move(rc.X, ly, rc.W, listH)
        
        ; 调整列表视图高度，使用与BUFF/RULES页面一致的计算方式，为底部按钮预留足够空间
        UI.TH_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        
        ; 重新计算按钮位置，确保在列表区内可见
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

    ; 统计映射：tid -> {Rules:n, Buffs:n}
    refs := Map()

    try {
        ; 初始化映射
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            for _, t in App["ProfileData"].Threads {
                refs[t.Id] := { Rules: 0, Buffs: 0 }
            }
        }

        ; 规则引用
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            for _, r in App["ProfileData"].Rules {
                tid := 1
                if (HasProp(r, "ThreadId")) {
                    tid := r.ThreadId
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Rules := refs[tid].Rules + 1
            }
        }

        ; BUFF 引用
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Buffs")) {
            for _, b in App["ProfileData"].Buffs {
                tid := 1
                if (HasProp(b, "ThreadId")) {
                    tid := b.ThreadId
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Buffs := refs[tid].Buffs + 1
            }
        }

        ; 汇总
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            tot := App["ProfileData"].Threads.Length
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

        ; 简要分布
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

    ; 预先构建引用映射
    refs := Map()
    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            for _, t in App["ProfileData"].Threads {
                refs[t.Id] := { Rules: 0, Buffs: 0 }
            }
        }
    } catch {
    }

    try {
        if (IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Rules")) {
            for _, r in App["ProfileData"].Rules {
                tid := 1
                if (HasProp(r, "ThreadId")) {
                    tid := r.ThreadId
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
                if (HasProp(b, "ThreadId")) {
                    tid := b.ThreadId
                }
                if !refs.Has(tid) {
                    refs[tid] := { Rules: 0, Buffs: 0 }
                }
                refs[tid].Buffs := refs[tid].Buffs + 1
            }
        }
    } catch {
    }

    ; 填充列表
    try {
        UI.TH_LV.Opt("-Redraw")
        UI.TH_LV.Delete()
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Threads")) {
            return
        }
        for _, t in App["ProfileData"].Threads {
            rid := t.Id
            name := HasProp(t,"Name") ? t.Name : ("线程" rid)
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
            UI.TH_LV.ModifyCol(A_Index, "AutoHdr")
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
    try {
        name := InputBox("线程名称：", "新增线程").Value
        if (name = "")
            return
        ths := App["ProfileData"].Threads
        newId := ths.Length ? (ths[ths.Length].Id + 1) : 1
        ths.Push({ Id: newId, Name: name })
        Threads_RefreshAll()
    } catch as e {
        MsgBox "新增线程失败: " e.Message
    }
}

Threads_OnRename(*) {
    try {
        row := UI.TH_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idText := UI.TH_LV.GetText(row, 1)
        nameText := UI.TH_LV.GetText(row, 2)
        name := InputBox("新名称：", "重命名线程",, nameText).Value
        if (name = "")
            return
        ths := App["ProfileData"].Threads
        for i, t in ths {
            if (t.Id = Integer(idText)) {
                t.Name := name
                break
            }
        }
        Threads_RefreshAll()
    } catch as e {
        MsgBox "重命名线程失败: " e.Message
    }
}

Threads_OnDelete(*) {
    try {
        ths := App["ProfileData"].Threads
        if ths.Length <= 1 {
            MsgBox "至少保留一个线程。"
            return
        }
        row := UI.TH_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请选择一个线程"
            return
        }
        idDel := Integer(UI.TH_LV.GetText(row, 1))
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
        Threads_RefreshAll()
    } catch as e {
        MsgBox "删除线程失败: " e.Message
    }
}

Threads_OnSave(*) {
    try {
        Storage_SaveProfile(App["ProfileData"])
        WorkerPool_Rebuild()
        Notify("线程配置已保存并重建进程池")
    } catch as e {
        MsgBox "保存线程配置失败: " e.Message
    }
}

Threads_OnRefresh(*) {
    Threads_RefreshAll()
}