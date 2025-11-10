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

    UI.BF_BtnOpen := UI.Main.Add("Button", Format("x{} y{} w160 h26", rc.X + 12, rc.Y + 26 + 6*22 + 8), "打开 BUFF 编辑器")
    page.Controls.Push(UI.BF_BtnOpen)

    UI.BF_BtnRefresh := UI.Main.Add("Button", "x+8 w100 h26", "刷新")
    page.Controls.Push(UI.BF_BtnRefresh)

    ; ====== BUFF 列表 ======
    ly := rc.Y + sumH + 10
    UI.BF_GB_List := UI.Main.Add("GroupBox", Format("x{} y{} w{} h{}", rc.X, ly, rc.W, Max(220, rc.H - (ly - rc.Y))), "BUFF 列表")
    page.Controls.Push(UI.BF_GB_List)

    UI.BF_LV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X + 12, ly + 26, rc.W - 24, Max(180, rc.H - (ly - rc.Y) - 40))
        , ["ID","名称","启用","线程","技能#","持续(ms)","提前续(ms)","检测就绪","上次续(毫秒前)","轮转位"])
    page.Controls.Push(UI.BF_LV)

    ; 事件
    UI.BF_BtnOpen.OnEvent("Click", Buffs_OnOpenEditor)
    UI.BF_BtnRefresh.OnEvent("Click", Buffs_OnRefresh)

    ; 首次刷新
    Buffs_RefreshAll()
}

Page_Buffs_Layout(rc) {
    try {
        ; 计算摘要区实际高度：标题栏26 + 7行文本编辑框(7*22=154) + 按钮区域(26+5=31) = 211像素
        sumH := 26 + 7*22 + 26 + 5
        UI.BF_GB_Sum.Move(rc.X, rc.Y, rc.W, sumH)
        UI.BF_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        UI.BF_BtnOpen.Move(rc.X + 12, rc.Y + 26 + 6*22 + 8)
        UI.BF_BtnRefresh.Move(UI.BF_BtnOpen.Pos.X + UI.BF_BtnOpen.Pos.W + 8, rc.Y + 26 + 6*22 + 8)

        ly := rc.Y + sumH + 10
        listH := Max(220, rc.H - (ly - rc.Y))
        UI.BF_GB_List.Move(rc.X, ly, rc.W, listH)
        UI.BF_LV.Move(rc.X + 12, ly + 26, rc.W - 24, listH - 40)
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

Buffs_OnOpenEditor(*) {
    try {
        BuffsManager_Show()
    } catch {
        MsgBox "无法打开 BUFF 编辑器。"
    }
}

Buffs_OnRefresh(*) {
    Buffs_RefreshAll()
}