#Requires AutoHotkey v2
; modules\ui\pages\automation\Page_Buffs_Summary.ahk
; 自动化 → 计时器（BUFF）摘要页
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：BF_

Page_Buffs_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    sumH := 26 + 6*22 + 8 + 26 + 10
    UI.BF_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, sumH), "计时器（BUFF） - 摘要")
    page.Controls.Push(UI.BF_GB_Sum)

    UI.BF_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r7 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.BF_Info)

    UI.BF_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "刷新")
    page.Controls.Push(UI.BF_BtnRefresh)

    UI.BF_BtnSave := UI.Main.Add("Button", "x+8 w100 h26", "保存")
    page.Controls.Push(UI.BF_BtnSave)

    ly := rc.Y + sumH + 10
    listH := Max(300, rc.H - (ly - rc.Y))
    UI.BF_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "BUFF 列表")
    page.Controls.Push(UI.BF_GB_List)

    UI.BF_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        , ["ID","名称","启用","线程","技能#","持续(ms)","提前续(ms)","检测就绪","上次续(毫秒前)","轮转位"])
    page.Controls.Push(UI.BF_LV)
    
    UI.BF_BtnAdd := UI.Main.Add("Button", Format("x{} y{} w90 h26", rc.X + 12, ly + listH - 40), "新增BUFF")
    page.Controls.Push(UI.BF_BtnAdd)
    UI.BF_BtnEdit := UI.Main.Add("Button", "x+8 w90 h26", "编辑BUFF")
    page.Controls.Push(UI.BF_BtnEdit)
    UI.BF_BtnDel := UI.Main.Add("Button", "x+8 w90 h26", "删除BUFF")
    page.Controls.Push(UI.BF_BtnDel)
    UI.BF_BtnUp := UI.Main.Add("Button", "x+8 w90 h26", "上移")
    page.Controls.Push(UI.BF_BtnUp)
    UI.BF_BtnDn := UI.Main.Add("Button", "x+8 w90 h26", "下移")
    page.Controls.Push(UI.BF_BtnDn)

    UI.BF_BtnAdd.OnEvent("Click", Buffs_OnAdd)
    UI.BF_BtnEdit.OnEvent("Click", Buffs_OnEdit)
    UI.BF_BtnDel.OnEvent("Click", Buffs_OnDelete)
    UI.BF_BtnUp.OnEvent("Click", Buffs_OnUp)
    UI.BF_BtnDn.OnEvent("Click", Buffs_OnDown)
    UI.BF_BtnSave.OnEvent("Click", Buffs_OnSave)
    UI.BF_BtnRefresh.OnEvent("Click", Buffs_OnRefresh)

    Buffs_RefreshAll()
}

Page_Buffs_Layout(rc) {
    try {
        sumH := 26 + 6*22 + 8 + 26 + 10
        UI.BF_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.BF_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.BF_BtnRefresh.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.BF_BtnSave.Move(UI.BF_BtnRefresh.Pos.X + UI.BF_BtnRefresh.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10
        listH := Max(300, rc.H - (ly - rc.Y))
        UI.BF_GB_List.Move(rc.X, ly, rc.W, listH)
        UI.BF_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        
        UI.BF_BtnAdd.Move(rc.X + 12, ly + listH - 40)
        UI.BF_BtnEdit.Move(UI.BF_BtnAdd.Pos.X + UI.BF_BtnAdd.Pos.W + 8, ly + listH - 40)
        UI.BF_BtnDel.Move(UI.BF_BtnEdit.Pos.X + UI.BF_BtnEdit.Pos.W + 8, ly + listH - 40)
        UI.BF_BtnUp.Move(UI.BF_BtnDel.Pos.X + UI.BF_BtnDel.Pos.W + 8, ly + listH - 40)
        UI.BF_BtnDn.Move(UI.BF_BtnUp.Pos.X + UI.BF_BtnUp.Pos.W + 8, ly + listH - 40)
    } catch {
    }
}

Page_Buffs_OnEnter(*) {
    Buffs_RefreshAll()
}

; ====== 刷新逻辑 ======

Buffs_RefreshAll() {
    Buffs_FillSummary()
    Buffs_FillList()
}

Buffs_FillSummary() {
    global App, UI
    txt := "当前配置无 BUFF。"
    tot := 0
    en := 0
    lastAny := 0
    thrMap := Map()

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Buffs")) {
            UI.BF_Info.Value := txt
            return
        }
        now := A_TickCount
        for i, b in App["ProfileData"].Buffs {
            tot := tot + 1
            if (HasProp(b,"Enabled") && b.Enabled) {
                en := en + 1
            }
            tid := 1
            try {
                tid := HasProp(b, "ThreadId") ? b.ThreadId : 1
            } catch {
                tid := 1
            }
            if !thrMap.Has(tid) {
                thrMap[tid] := 0
            }
            thrMap[tid] := thrMap[tid] + 1

            lf := 0
            try {
                lf := HasProp(b, "LastTime") ? b.LastTime : 0
            } catch {
                lf := 0
            }
            if (lf > 0) {
                if (lf > lastAny) {
                    lastAny := lf
                }
            }
        }

        txt := "BUFF 总数: " tot "`r`n"
        txt .= "启用: " en "  禁用: " (tot - en) "`r`n"
        txt .= "按线程分布: "
        if (thrMap.Count = 0) {
            txt .= "-"
        } else {
            first := true
            for k, v in thrMap {
                if (first) {
                    txt .= "[T" k ":" v "]"
                    first := false
                } else {
                    txt .= " [T" k ":" v "]"
                }
            }
        }
        txt .= "`r`n"
        if (lastAny > 0) {
            gap := A_TickCount - lastAny
            if (gap < 0) {
                gap := 0
            }
            txt .= "最近续时: " gap " ms 前"
        } else {
            txt .= "最近续时: -"
        }
    } catch {
        txt := "读取 BUFF 摘要失败。"
    }

    try {
        UI.BF_Info.Value := txt
    } catch {
    }
}

Buffs_FillList() {
    global App, UI
    try {
        UI.BF_LV.Opt("-Redraw")
        UI.BF_LV.Delete()
    } catch {
    }

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Buffs")) {
            return
        }
        now := A_TickCount
        for i, b in App["ProfileData"].Buffs {
            id   := 0
            name := ""
            en   := ""
            thr  := 1
            sc   := 0
            dur  := 0
            ref  := 0
            rdy  := ""
            last := 0
            lastTxt := "-"
            nextIdx := "-"

            try {
                id := OM_Get(b, "Id", 0)
            } catch {
                id := 0
            }
            try {
                name := HasProp(b,"Name") ? b.Name : ("Buff" i)
            } catch {
                name := "Buff"
            }
            try {
                en := (HasProp(b,"Enabled") && b.Enabled) ? "√" : ""
            } catch {
                en := ""
            }
            try {
                thr := HasProp(b,"ThreadId") ? b.ThreadId : 1
            } catch {
                thr := 1
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
                dur := HasProp(b,"DurationMs") ? b.DurationMs : 0
            } catch {
                dur := 0
            }
            try {
                ref := HasProp(b,"RefreshBeforeMs") ? b.RefreshBeforeMs : 0
            } catch {
                ref := 0
            }
            try {
                rdy := (HasProp(b,"CheckReady") && b.CheckReady) ? "√" : ""
            } catch {
                rdy := ""
            }
            try {
                last := HasProp(b,"LastTime") ? b.LastTime : 0
            } catch {
                last := 0
            }
            if (last > 0) {
                gap := now - last
                if (gap < 0) {
                    gap := 0
                }
                lastTxt := gap
            }
            try {
                if (HasProp(b,"NextIdx")) {
                    nextIdx := b.NextIdx
                } else {
                    nextIdx := "-"
                }
            } catch {
                nextIdx := "-"
            }

            UI.BF_LV.Add("", id, name, en, thr, sc, dur, ref, rdy, lastTxt, nextIdx)
        }
        loop 11 {
            try {
                UI.BF_LV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            UI.BF_LV.Opt("+Redraw")
        } catch {
        }
    }
}

; ====== 事件 ======

Buffs_OnAdd(*) {
    try {
        newB := {
            Id: 0
          , Name: "新BUFF", Enabled: 1, DurationMs: 15000, RefreshBeforeMs: 2000, CheckReady: 1, ThreadId: 1
          , Skills: [], LastTime: 0, NextIdx: 1
        }
        BuffEditor_Open(newB, 0, Buffs_OnSavedNew)
    } catch {
        MsgBox "新增BUFF失败。"
    }
}

Buffs_OnSavedNew(buff, idx) {
    global App
    App["ProfileData"].Buffs.Push(buff)
    Buffs_RefreshAll()
}

Buffs_OnEdit(*) {
    global App, UI
    row := 0
    try {
        row := UI.BF_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请先选中一个BUFF。"
        return
    }
    try {
        BuffEditor_Open(App["ProfileData"].Buffs[row], row, Buffs_OnSavedEdit)
    } catch {
        MsgBox "编辑BUFF失败。"
    }
}

Buffs_OnSavedEdit(buff, idx) {
    global App
    App["ProfileData"].Buffs[idx] := buff
    Buffs_RefreshAll()
}

Buffs_OnDelete(*) {
    global App, UI
    row := 0
    try {
        row := UI.BF_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        MsgBox "请先选中一个BUFF。"
        return
    }
    try {
        App["ProfileData"].Buffs.RemoveAt(row)
        Buffs_RefreshAll()
        Notify("已删除BUFF", 3000)
    } catch {
        MsgBox "删除BUFF失败。"
    }
}

Buffs_OnUp(*) {
    Buffs_MoveSel(-1)
}

Buffs_OnDown(*) {
    Buffs_MoveSel(1)
}

Buffs_MoveSel(dir) {
    global App, UI
    row := 0
    try {
        row := UI.BF_LV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (!row) {
        return
    }
    from := row
    to := from + dir
    if (to < 1 || to > App["ProfileData"].Buffs.Length) {
        return
    }
    item := App["ProfileData"].Buffs[from]
    App["ProfileData"].Buffs.RemoveAt(from)
    App["ProfileData"].Buffs.InsertAt(to, item)
    Buffs_RefreshAll()
    try {
        UI.BF_LV.Modify(to, "Select Focus Vis")
    } catch {
    }
}

Buffs_OnSave(*) {
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

    ; 将运行时 BUFF（索引引用）转换为文件夹模型（Id 引用）
    newArr := []
    try {
        if (HasProp(App["ProfileData"], "Buffs") && IsObject(App["ProfileData"].Buffs)) {
            ; 从运行时 Skills 构建 index->Id 映射（更可靠）
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

    Buffs_RefreshAll()
    Notify("BUFF 配置已保存", 3000)
}

Buffs_OnRefresh(*) {
    Buffs_RefreshAll()
}