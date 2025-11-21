#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"

; 轮换配置 - 常规页（轻量化，保存委托适配器）
; 依赖：Rot_SaveBase / RotPU_* 工具
; 说明：
; - 内容区域可滚动：使用垂直 Slider 作为滚动条（0~100）
; - 保存按钮固定在底部，不随滚动

Page_RotGen_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ========== 内容控件（可滚动区域） ==========
    UI.RG_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w200", rc.X, rc.Y), "启用轮换")
    page.Controls.Push(UI.RG_cbEnable)

    ; 默认轨道
    UI.RG_labDef := UI.Main.Add("Text", "w120 Right", "默认轨道：")
    UI.RG_ddDefTrack := UI.Main.Add("DropDownList", "w200")
    page.Controls.Push(UI.RG_labDef)
    page.Controls.Push(UI.RG_ddDefTrack)

    ; 忙窗
    UI.RG_labBusy := UI.Main.Add("Text", "w120 Right", "忙窗(ms)：")
    UI.RG_edBusy := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBusy)
    page.Controls.Push(UI.RG_edBusy)

    ; 黑色容差
    UI.RG_labTol := UI.Main.Add("Text", "w120 Right", "黑色容差：")
    UI.RG_edTol := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labTol)
    page.Controls.Push(UI.RG_edTol)

    ; 切换键 + 验证
    UI.RG_labSwap := UI.Main.Add("Text", "w120 Right", "切换键：")
    UI.RG_hkSwap := UI.Main.Add("Hotkey", "w200")
    UI.RG_cbVerifySwap := UI.Main.Add("CheckBox", "w120", "验证切换")
    page.Controls.Push(UI.RG_labSwap)
    page.Controls.Push(UI.RG_hkSwap)
    page.Controls.Push(UI.RG_cbVerifySwap)

    ; 切换超时 / 重试
    UI.RG_labSwapTO := UI.Main.Add("Text", "w120 Right", "切换超时(ms)：")
    UI.RG_edSwapTO := UI.Main.Add("Edit", "w200 Number Center")
    UI.RG_labSwapRetry := UI.Main.Add("Text", "w120 Right", "重试次数：")
    UI.RG_edSwapRetry := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labSwapTO)
    page.Controls.Push(UI.RG_edSwapTO)
    page.Controls.Push(UI.RG_labSwapRetry)
    page.Controls.Push(UI.RG_edSwapRetry)

    ; 尊重施法锁
    UI.RG_cbCast := UI.Main.Add("CheckBox", "w200", "尊重施法锁")
    page.Controls.Push(UI.RG_cbCast)

    ; 跳轨开关 + 冷却
    UI.RG_cbGates := UI.Main.Add("CheckBox", "w120", "启用跳轨")
    UI.RG_labGateCd := UI.Main.Add("Text", "w80", "冷却(ms)：")
    UI.RG_edGateCd := UI.Main.Add("Edit", "w110 Number Center")
    page.Controls.Push(UI.RG_cbGates)
    page.Controls.Push(UI.RG_labGateCd)
    page.Controls.Push(UI.RG_edGateCd)

    ; 黑框防抖（组）
    UI.RG_gbBG := UI.Main.Add("GroupBox", "w300 h290", "黑框防抖")
    page.Controls.Push(UI.RG_gbBG)

    UI.RG_cbBG := UI.Main.Add("CheckBox", "w120", "启用")
    page.Controls.Push(UI.RG_cbBG)

    UI.RG_labBG_Samp := UI.Main.Add("Text", "w120 Right", "采样数：")
    UI.RG_edBG_Samp := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Samp)
    page.Controls.Push(UI.RG_edBG_Samp)

    UI.RG_labBG_Ratio := UI.Main.Add("Text", "w120 Right", "黑像素阈值：")
    UI.RG_edBG_Ratio := UI.Main.Add("Edit", "w200 Center")
    page.Controls.Push(UI.RG_labBG_Ratio)
    page.Controls.Push(UI.RG_edBG_Ratio)

    UI.RG_labBG_Win := UI.Main.Add("Text", "w120 Right", "冻结窗(ms)：")
    UI.RG_edBG_Win := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Win)
    page.Controls.Push(UI.RG_edBG_Win)

    UI.RG_labBG_Cool := UI.Main.Add("Text", "w120 Right", "冷却(ms)：")
    UI.RG_edBG_Cool := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Cool)
    page.Controls.Push(UI.RG_edBG_Cool)

    UI.RG_labBG_Min := UI.Main.Add("Text", "w120 Right", "最小延迟(ms)：")
    UI.RG_edBG_Min := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Min)
    page.Controls.Push(UI.RG_edBG_Min)

    UI.RG_labBG_Max := UI.Main.Add("Text", "w120 Right", "最大延迟(ms)：")
    UI.RG_edBG_Max := UI.Main.Add("Edit", "w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Max)
    page.Controls.Push(UI.RG_edBG_Max)

    UI.RG_cbBG_Uniq := UI.Main.Add("CheckBox", "w140", "需要唯一黑框")
    page.Controls.Push(UI.RG_cbBG_Uniq)

    ; 垂直滚动条（Slider 代替），初始隐藏
    UI.RG_scroll := UI.Main.Add("Slider", "Vertical Range0-100 ToolTip TickInterval10")
    UI.RG_scroll.Value := 0
    UI.RG_scroll.Visible := false
    UI.RG_scroll.OnEvent("Change", Page_RotGen_OnScroll)
    page.Controls.Push(UI.RG_scroll)

    ; ========== 底部固定按钮（不随滚动） ==========
    UI.RG_btnSave := UI.Main.Add("Button", "w120", "保存")
    UI.RG_btnSave.OnEvent("Click", Page_RotGen_OnSave)
    page.Controls.Push(UI.RG_btnSave)

    ; 内部状态
    UI.RG_scrollPct := 0.0

    Page_RotGen_Refresh()
}

Page_RotGen_Layout(rc) {
    try {
        Page_RotGen_DoLayout(rc)
    } catch {
    }
}

Page_RotGen_OnEnter(*) {
    RotPU_LogEnter("RotGen")
    Page_RotGen_Refresh()
}

; 用名称填充“默认轨道”下拉，内部映射到 UI.RG_trackIds（保存时用 Id）
Page_RotGen_FillDefaultTrackDD(cfg) {
    global UI

    ; 清空下拉
    try {
        DllCall("user32\SendMessageW", "ptr", UI.RG_ddDefTrack.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)
    } catch {
    }

    names := []
    ids := []

    hasTracks := false
    try {
        hasTracks := HasProp(cfg, "Tracks") && IsObject(cfg.Tracks) && (cfg.Tracks.Length > 0)
    } catch {
        hasTracks := false
    }

    if (hasTracks) {
        for _, t in cfg.Tracks {
            tid := 0
            tname := ""
            try {
                tid := OM_Get(t, "Id", 0)
            } catch {
                tid := 0
            }
            try {
                tname := OM_Get(t, "Name", "")
            } catch {
                tname := ""
            }
            if (tid > 0) {
                if (tname = "") {
                    tname := "轨道#" tid
                }
                names.Push(tname)
                ids.Push(tid)
            }
        }
    }

    if (names.Length = 0) {
        idList := []
        try {
            idList := REUI_ListTrackIds(cfg)
        } catch {
            idList := []
        }
        if (IsObject(idList) && idList.Length > 0) {
            i := 1
            while (i <= idList.Length) {
                idv := 0
                try {
                    idv := Integer(idList[i])
                } catch {
                    idv := 0
                }
                if (idv > 0) {
                    names.Push("轨道#" idv)
                    ids.Push(idv)
                }
                i := i + 1
            }
        }
    }

    if (names.Length > 0) {
        try {
            UI.RG_ddDefTrack.Add(names)
        } catch {
        }
        UI.RG_trackIds := ids

        wantId := 1
        try {
            wantId := OM_Get(cfg, "DefaultTrackId", 1)
        } catch {
            wantId := 1
        }
        pos := 1
        i := 1
        while (i <= ids.Length) {
            v := 0
            try {
                v := Integer(ids[i])
            } catch {
                v := 0
            }
            if (v = wantId) {
                pos := i
                break
            }
            i := i + 1
        }
        try {
            UI.RG_ddDefTrack.Value := pos
            UI.RG_ddDefTrack.Enabled := true
        } catch {
        }
    } else {
        try {
            UI.RG_ddDefTrack.Add(["（无轨道）"])
            UI.RG_ddDefTrack.Value := 1
            UI.RG_ddDefTrack.Enabled := false
        } catch {
        }
        UI.RG_trackIds := []
    }
}

Page_RotGen_Refresh() {
    global UI
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        return
    }

    ; 默认轨道下拉：显示名称，内部映射到 Id
    Page_RotGen_FillDefaultTrackDD(cfg)

    ; 勾选/数值
    UI.RG_cbEnable.Value := (OM_Get(cfg, "Enabled", 0) ? 1 : 0)
    UI.RG_edBusy.Value := OM_Get(cfg, "BusyWindowMs", 200)
    UI.RG_edTol.Value := OM_Get(cfg, "ColorTolBlack", 16)

    UI.RG_cbCast.Value := (OM_Get(cfg, "RespectCastLock", 1) ? 1 : 0)
    UI.RG_hkSwap.Value := OM_Get(cfg, "SwapKey", "")
    UI.RG_cbVerifySwap.Value := (OM_Get(cfg, "VerifySwap", 0) ? 1 : 0)
    UI.RG_edSwapTO.Value := OM_Get(cfg, "SwapTimeoutMs", 800)
    UI.RG_edSwapRetry.Value := OM_Get(cfg, "SwapRetry", 0)

    UI.RG_cbGates.Value := (OM_Get(cfg, "GatesEnabled", 0) ? 1 : 0)
    UI.RG_edGateCd.Value := OM_Get(cfg, "GateCooldownMs", 0)

    bg := OM_Get(cfg, "BlackGuard", Map())
    UI.RG_cbBG.Value := (OM_Get(bg, "Enabled", 1) ? 1 : 0)
    UI.RG_edBG_Samp.Value := OM_Get(bg, "SampleCount", 5)
    UI.RG_edBG_Ratio.Value := OM_Get(bg, "BlackRatioThresh", 0.7)
    UI.RG_edBG_Win.Value := OM_Get(bg, "WindowMs", 120)
    UI.RG_edBG_Cool.Value := OM_Get(bg, "CooldownMs", 600)
    UI.RG_edBG_Min.Value := OM_Get(bg, "MinAfterSendMs", 60)
    UI.RG_edBG_Max.Value := OM_Get(bg, "MaxAfterSendMs", 800)
    UI.RG_cbBG_Uniq.Value := (OM_Get(bg, "UniqueRequired", 1) ? 1 : 0)

    ; 每次刷新后重置滚动位置
    try {
        UI.RG_scroll.Value := 0
        UI.RG_scrollPct := 0.0
    } catch {
        UI.RG_scrollPct := 0.0
    }

    Page_RotGen_DoLayout(UI_GetPageRect())
}

; 滚动条事件：根据滑块位置重新布局
Page_RotGen_OnScroll(*) {
    global UI
    try {
        v := UI.RG_scroll.Value
        if (v < 0) {
            v := 0
        }
        if (v > 100) {
            v := 100
        }
        UI.RG_scrollPct := v + 0.0
    } catch {
        UI.RG_scrollPct := 0.0
    }
    Page_RotGen_DoLayout(UI_GetPageRect())
}

; 实际布局：计算可视高度 / 内容高度，决定滚动与控件位置
Page_RotGen_DoLayout(rc) {
    global UI

    ; 预留底部按钮栏高度 & 滚动条宽度
    bottomBarH := 44
    sbW := 16

    ; 固定按钮（不随滚动）
    try {
        UI_MoveSafe(UI.RG_btnSave, rc.X, rc.Y + rc.H - 36)
    } catch {
    }

    ; 内容可视区域
    viewX := rc.X
    viewY := rc.Y
    viewW := rc.W - sbW
    viewH := rc.H - bottomBarH
    if (viewW < 240) {
        viewW := 240
    }
    if (viewH < 120) {
        viewH := 120
    }

    ; 测量内容总高度（按未滚动时的自然排版计算）
    contentH := Page_RotGen_MeasureContent(viewX, viewY, viewW)

    ; 滚动条显隐 + 值 -> 像素偏移
    needScroll := false
    if (contentH > viewH + 1) {
        needScroll := true
    } else {
        needScroll := false
    }

    offset := 0
    if (needScroll) {
        try {
            UI.RG_scroll.Visible := true
            UI.RG_scroll.Move(rc.X + rc.W - sbW, viewY, sbW, viewH)
        } catch {
        }
        ; 百分比 -> 像素偏移
        try {
            maxDelta := contentH - viewH
            pct := UI.RG_scrollPct
            if (pct < 0) {
                pct := 0
            }
            if (pct > 100) {
                pct := 100
            }
            offset := Round((pct / 100.0) * maxDelta)
        } catch {
            offset := 0
        }
    } else {
        try {
            UI.RG_scroll.Visible := false
            UI.RG_scroll.Value := 0
            UI.RG_scrollPct := 0.0
        } catch {
        }
    }

    ; 依据偏移进行实际排版
    Page_RotGen_LayoutContent(viewX, viewY, viewW, offset)
}

; 只计算内容的总高度（不移动控件）
Page_RotGen_MeasureContent(x, yTop, w) {
    rowH := 34
    y := yTop
    y := y + rowH                        ; cbEnable 占一行

    ; 默认轨道行
    y := y + rowH
    ; 忙窗行
    y := y + rowH
    ; 黑色容差行
    y := y + rowH
    ; 切换键+验证行
    y := y + rowH
    ; 切换超时/重试行
    y := y + rowH
    ; 尊重施法锁行
    y := y + rowH
    ; 跳轨开关 + 冷却行
    y := y + rowH

    ; 黑框防抖组（上面基础 + 10 间距 + 290 高度）
    y := y + rowH + 10
    y := y + 290

    return (y - yTop)
}

; 内容实际排版（根据偏移移动控件）
Page_RotGen_LayoutContent(x, yTop, w, offset) {
    global UI
    rowH := 34
    gapX := 10

    ; 统一基线（应用滚动偏移）
    y := yTop - offset

    ; 行 1：启用
    UI_MoveSafe(UI.RG_cbEnable, x, y)
    y := y + rowH

    ; 行 2：默认轨道
    labX := x
    ddX := x + 120 + gapX
    UI_MoveSafe(UI.RG_labDef, labX, y)
    UI_MoveSafe(UI.RG_ddDefTrack, ddX, y)
    y := y + rowH

    ; 行 3：忙窗
    UI_MoveSafe(UI.RG_labBusy, labX, y)
    UI_MoveSafe(UI.RG_edBusy, ddX, y)
    y := y + rowH

    ; 行 4：黑色容差
    UI_MoveSafe(UI.RG_labTol, labX, y)
    UI_MoveSafe(UI.RG_edTol, ddX, y)
    y := y + rowH

    ; 行 5：切换键 + 验证
    UI_MoveSafe(UI.RG_labSwap, labX, y)
    UI_MoveSafe(UI.RG_hkSwap, ddX, y)
    verX := ddX + 200 + 20
    UI_MoveSafe(UI.RG_cbVerifySwap, verX, y)
    y := y + rowH

    ; 行 6：切换超时 / 重试
    UI_MoveSafe(UI.RG_labSwapTO, labX, y)
    UI_MoveSafe(UI.RG_edSwapTO, ddX, y)
    lab2X := ddX + 200 + 20
    UI_MoveSafe(UI.RG_labSwapRetry, lab2X, y)
    UI_MoveSafe(UI.RG_edSwapRetry, lab2X + 120 + gapX, y)
    y := y + rowH

    ; 行 7：尊重施法锁
    UI_MoveSafe(UI.RG_cbCast, x, y)
    y := y + rowH

    ; 行 8：跳轨开关 + 冷却
    UI_MoveSafe(UI.RG_cbGates, x, y)
    gateLabX := x + 120 + gapX
    UI_MoveSafe(UI.RG_labGateCd, gateLabX, y)
    UI_MoveSafe(UI.RG_edGateCd, gateLabX + 80 + gapX, y)
    y := y + rowH

    ; 行 9：黑框防抖组（+10 间距）
    y := y + rowH + 10
    gbW := w - 20
    if (gbW < 240) {
        gbW := 240
    }
    UI_MoveSafe(UI.RG_gbBG, x, y, gbW, 290)

    ; 组内内容
    gy := y + 26
    gx := x + 10

    UI_MoveSafe(UI.RG_cbBG, gx, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Samp, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Samp, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Ratio, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Ratio, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Win, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Win, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Cool, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Cool, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Min, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Min, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_labBG_Max, gx, gy)
    UI_MoveSafe(UI.RG_edBG_Max, gx + 120 + gapX, gy)
    gy := gy + rowH

    UI_MoveSafe(UI.RG_cbBG_Uniq, gx, gy)
}

Page_RotGen_OnSave(*) {
    name := RotPU_CurrentProfileOrMsg()
    if (name = "") {
        return
    }
    cfg := RotPU_GetRotationCfg()
    if !IsObject(cfg) {
        MsgBox "未加载配置，无法保存。"
        return
    }

    ; 从 UI 写回 cfg
    cfg.Enabled := UI.RG_cbEnable.Value ? 1 : 0

    defId := 1
    try {
        if (HasProp(UI, "RG_trackIds") && IsObject(UI.RG_trackIds) && UI.RG_trackIds.Length >= 1) {
            pos := 0
            try {
                pos := UI.RG_ddDefTrack.Value
            } catch {
                pos := 0
            }
            if (pos >= 1 && pos <= UI.RG_trackIds.Length) {
                v := 0
                try {
                    v := Integer(UI.RG_trackIds[pos])
                } catch {
                    v := 0
                }
                if (v > 0) {
                    defId := v
                }
            } else {
                idsFB := REUI_ListTrackIds(cfg)
                if (IsObject(idsFB) && idsFB.Length >= 1) {
                    try {
                        defId := Integer(idsFB[1])
                    } catch {
                        defId := 1
                    }
                } else {
                    defId := 1
                }
            }
        } else {
            idsFB2 := REUI_ListTrackIds(cfg)
            if (IsObject(idsFB2) && idsFB2.Length >= 1) {
                try {
                    defId := Integer(idsFB2[1])
                } catch {
                    defId := 1
                }
            } else {
                defId := 1
            }
        }
    } catch {
        defId := 1
    }
    cfg.DefaultTrackId := defId

    cfg.BusyWindowMs := (UI.RG_edBusy.Value != "") ? Integer(UI.RG_edBusy.Value) : 200
    cfg.ColorTolBlack := (UI.RG_edTol.Value != "") ? Integer(UI.RG_edTol.Value) : 16
    cfg.RespectCastLock := UI.RG_cbCast.Value ? 1 : 0

    cfg.SwapKey := Trim(UI.RG_hkSwap.Value)
    cfg.VerifySwap := UI.RG_cbVerifySwap.Value ? 1 : 0
    cfg.SwapTimeoutMs := (UI.RG_edSwapTO.Value != "") ? Integer(UI.RG_edSwapTO.Value) : 800
    cfg.SwapRetry := (UI.RG_edSwapRetry.Value != "") ? Integer(UI.RG_edSwapRetry.Value) : 0

    cfg.GatesEnabled := UI.RG_cbGates.Value ? 1 : 0
    cfg.GateCooldownMs := (UI.RG_edGateCd.Value != "") ? Integer(UI.RG_edGateCd.Value) : 0

    bg := OM_Get(cfg, "BlackGuard", Map())
    bg.Enabled := UI.RG_cbBG.Value ? 1 : 0
    bg.SampleCount := (UI.RG_edBG_Samp.Value != "") ? Integer(UI.RG_edBG_Samp.Value) : 5
    bg.BlackRatioThresh := (UI.RG_edBG_Ratio.Value != "") ? (UI.RG_edBG_Ratio.Value + 0) : 0.7
    bg.WindowMs := (UI.RG_edBG_Win.Value != "") ? Integer(UI.RG_edBG_Win.Value) : 120
    bg.CooldownMs := (UI.RG_edBG_Cool.Value != "") ? Integer(UI.RG_edBG_Cool.Value) : 600
    bg.MinAfterSendMs := (UI.RG_edBG_Min.Value != "") ? Integer(UI.RG_edBG_Min.Value) : 60
    bg.MaxAfterSendMs := (UI.RG_edBG_Max.Value != "") ? Integer(UI.RG_edBG_Max.Value) : 800
    bg.UniqueRequired := UI.RG_cbBG_Uniq.Value ? 1 : 0
    cfg.BlackGuard := bg

    ok := false
    try {
        ok := Rot_SaveBase(name, cfg)
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    Page_RotGen_Refresh()
    Notify("常规配置已保存")
}