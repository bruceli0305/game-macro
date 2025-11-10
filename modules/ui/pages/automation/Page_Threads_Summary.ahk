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

    UI.TH_BtnOpen := UI.Main.Add("Button", Format("x{} y{} w140 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "打开线程管理器")
    page.Controls.Push(UI.TH_BtnOpen)

    UI.TH_BtnRefresh := UI.Main.Add("Button", "x+8 w100 h26", "刷新")
    page.Controls.Push(UI.TH_BtnRefresh)

    ; ====== 列表区 ======
    ly := rc.Y + sumH + 10  ; 使用实际摘要区高度计算列表区位置
    listH := Max(220, rc.H - (ly - rc.Y))
    UI.TH_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, listH), "线程列表")
    page.Controls.Push(UI.TH_GB_List)

    UI.TH_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, listH - 40)
        , ["ID","名称","规则引用#","BUFF引用#","总引用"])
    page.Controls.Push(UI.TH_LV)

    ; 事件
    UI.TH_BtnOpen.OnEvent("Click", Threads_OnOpenManager)
    UI.TH_BtnRefresh.OnEvent("Click", Threads_OnRefresh)

    ; 首次刷新
    Threads_RefreshAll()
}

Page_Threads_Layout(rc) {
    try {
        ; 计算摘要区实际需要的高度：标题栏26 + 文本编辑框6行(6*22) + 按钮间距8 + 按钮高度26 + 底部间距10 = 196
        sumH := 26 + 6*22 + 8 + 26 + 10
        
        UI.TH_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.TH_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.TH_BtnOpen.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.TH_BtnRefresh.Move(UI.TH_BtnOpen.Pos.X + UI.TH_BtnOpen.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10  ; 使用实际摘要区高度计算列表区位置
        listH := Max(220, rc.H - (ly - rc.Y))
        UI.TH_GB_List.Move(rc.X, ly, rc.W, listH)
        UI.TH_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 40)
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

Threads_OnOpenManager(*) {
    try {
        ThreadsManager_Show()
    } catch {
        MsgBox "无法打开线程管理器。"
    }
}

Threads_OnRefresh(*) {
    Threads_RefreshAll()
}