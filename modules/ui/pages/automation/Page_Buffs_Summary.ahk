#Requires AutoHotkey v2
;Page_Buffs_Summary.ahk
; 自动化 → 计时器（BUFF）摘要页
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：BF_

Page_Buffs_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== 摘要区 ======
    ; 计算摘要区实际高度：标题栏26 + 7行文本编辑框(7*22=154) + 按钮区域(26+5=31) = 211像素
    sumH := 26 + 6*22 + 8 + 26 + 10
    UI.BF_GB_Sum := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, sumH), "计时器（BUFF） - 摘要")
    page.Controls.Push(UI.BF_GB_Sum)

    UI.BF_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r7 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.BF_Info)

    UI.BF_BtnRefresh := UI.Main.Add("Button", Format("x{} y{} w100 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "刷新")
    page.Controls.Push(UI.BF_BtnRefresh)

    UI.BF_BtnSave := UI.Main.Add("Button", "x+8 w100 h26", "保存")
    page.Controls.Push(UI.BF_BtnSave)

    ; ====== BUFF 列表 ======
    ly := rc.Y + sumH + 10
    listH := Max(300, rc.H - (ly - rc.Y))
    UI.BF_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "BUFF 列表")
    page.Controls.Push(UI.BF_GB_List)

    UI.BF_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 80)
        , ["ID","名称","启用","线程","技能#","持续(ms)","提前续(ms)","检测就绪","上次续(毫秒前)","轮转位"])
    page.Controls.Push(UI.BF_LV)
    
    ; 管理按钮
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

    ; 事件
    UI.BF_BtnAdd.OnEvent("Click", Buffs_OnAdd)
    UI.BF_BtnEdit.OnEvent("Click", Buffs_OnEdit)
    UI.BF_BtnDel.OnEvent("Click", Buffs_OnDelete)
    UI.BF_BtnUp.OnEvent("Click", Buffs_OnUp)
    UI.BF_BtnDn.OnEvent("Click", Buffs_OnDown)
    UI.BF_BtnSave.OnEvent("Click", Buffs_OnSave)
    UI.BF_BtnRefresh.OnEvent("Click", Buffs_OnRefresh)

    ; 首次刷新
    Buffs_RefreshAll()
}

Page_Buffs_Layout(rc) {
    try {
        ; 计算摘要区实际高度：标题栏26 + 7行文本编辑框(7*22=154) + 按钮区域(26+5=31) = 211像素
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
            ; 线程分布
            tid := 1
            if (HasProp(b,"ThreadId")) {
                tid := b.ThreadId
            }
            if !thrMap.Has(tid) {
                thrMap[tid] := 0
            }
            thrMap[tid] := thrMap[tid] + 1

            ; 最近续时
            lf := 0
            if (HasProp(b,"LastTime")) {
                lf := b.LastTime
            }
            if (lf > 0) {
                gap := now - lf
                if (gap < 0) {
                    gap := 0
                }
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
            txt .= "最近续时: " (A_TickCount - lastAny) " ms 前"
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
            name := HasProp(b,"Name") ? b.Name : ("Buff" i)
            en  := (HasProp(b,"Enabled") && b.Enabled) ? "√" : ""
            thr := HasProp(b,"ThreadId") ? b.ThreadId : 1
            sc  := 0
            if (HasProp(b,"Skills") && IsObject(b.Skills)) {
                sc := b.Skills.Length
            }
            dur := HasProp(b,"DurationMs") ? b.DurationMs : 0
            ref := HasProp(b,"RefreshBeforeMs") ? b.RefreshBeforeMs : 0
            rdy := (HasProp(b,"CheckReady") && b.CheckReady) ? "√" : ""
            last := HasProp(b,"LastTime") ? b.LastTime : 0
            lastTxt := "-"
            if (last > 0) {
                gap := now - last
                if (gap < 0) {
                    gap := 0
                }
                lastTxt := gap
            }
            nextIdx := "-"
            if (HasProp(b,"NextIdx")) {
                nextIdx := b.NextIdx
            }
            UI.BF_LV.Add("", i, name, en, thr, sc, dur, ref, rdy, lastTxt, nextIdx)
        }
        loop 11 {
            UI.BF_LV.ModifyCol(A_Index, "AutoHdr")
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
            Name: "新BUFF", Enabled: 1, DurationMs: 15000, RefreshBeforeMs: 2000, CheckReady: 1, Skills: [], LastTime: 0,
            NextIdx: 1
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
    try {
        row := UI.BF_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请先选中一个BUFF。"
            return
        }
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
    try {
        row := UI.BF_LV.GetNext(0, "Focused")
        if !row {
            MsgBox "请先选中一个BUFF。"
            return
        }
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
    global App
    row := UI.BF_LV.GetNext(0, "Focused")
    if !row
        return
    from := row
    to := from + dir
    if (to < 1 || to > App["ProfileData"].Buffs.Length)
        return
    item := App["ProfileData"].Buffs[from]
    App["ProfileData"].Buffs.RemoveAt(from)
    App["ProfileData"].Buffs.InsertAt(to, item)
    Buffs_RefreshAll()
    UI.BF_LV.Modify(to, "Select Focus Vis")
}

Buffs_OnSave(*) {
    try {
        Storage_SaveProfile(App["ProfileData"])
        Notify("BUFF 配置已保存", 3000)
    } catch {
        MsgBox "保存BUFF配置失败。"
    }
}

Buffs_OnRefresh(*) {
    Buffs_RefreshAll()
}