#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"

; 轮换配置 - 常规页（轻量化，保存委托适配器）
; 依赖：Rot_SaveBase / RotPU_* 工具

Page_RotGen_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []
    ; 启用
    UI.RG_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w200", rc.X, rc.Y), "启用轮换")
    page.Controls.Push(UI.RG_cbEnable)

    rowH := 34
    x := rc.X
    y := rc.Y + rowH

    ; 默认轨道
    UI.RG_labDef := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "默认轨道：")
    UI.RG_ddDefTrack := UI.Main.Add("DropDownList", "x+10 w200")
    page.Controls.Push(UI.RG_labDef)
    page.Controls.Push(UI.RG_ddDefTrack)
    y := y + rowH

    ; 忙窗
    UI.RG_labBusy := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "忙窗(ms)：")
    UI.RG_edBusy := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBusy)
    page.Controls.Push(UI.RG_edBusy)
    y := y + rowH

    ; 黑色容差
    UI.RG_labTol := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "黑色容差：")
    UI.RG_edTol := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labTol)
    page.Controls.Push(UI.RG_edTol)
    y := y + rowH

    ; 切换键 + 验证
    UI.RG_labSwap := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "切换键：")
    UI.RG_hkSwap := UI.Main.Add("Hotkey", "x+10 w200")
    UI.RG_cbVerifySwap := UI.Main.Add("CheckBox", "x+20 w120", "验证切换")
    page.Controls.Push(UI.RG_labSwap)
    page.Controls.Push(UI.RG_hkSwap)
    page.Controls.Push(UI.RG_cbVerifySwap)
    y := y + rowH

    ; 切换超时 / 重试
    UI.RG_labSwapTO := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "切换超时(ms)：")
    UI.RG_edSwapTO := UI.Main.Add("Edit", "x+10 w200 Number Center")
    UI.RG_labSwapRetry := UI.Main.Add("Text", "x+20 w120 Right", "重试次数：")
    UI.RG_edSwapRetry := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labSwapTO)
    page.Controls.Push(UI.RG_edSwapTO)
    page.Controls.Push(UI.RG_labSwapRetry)
    page.Controls.Push(UI.RG_edSwapRetry)
    y := y + rowH

    ; 尊重施法锁
    UI.RG_cbCast := UI.Main.Add("CheckBox", Format("x{} y{} w200", x, y), "尊重施法锁")
    page.Controls.Push(UI.RG_cbCast)
    y := y + rowH

    ; 跳轨开关 + 冷却
    UI.RG_cbGates := UI.Main.Add("CheckBox", Format("x{} y{} w120", x, y), "启用跳轨")
    UI.RG_labGateCd := UI.Main.Add("Text", "x+10 w80", "冷却(ms)：")
    UI.RG_edGateCd := UI.Main.Add("Edit", "x+10 w110 Number Center")
    page.Controls.Push(UI.RG_cbGates)
    page.Controls.Push(UI.RG_labGateCd)
    page.Controls.Push(UI.RG_edGateCd)

    ; 黑框防抖
    y := y + rowH + 10
    fullW := rc.W - 20
    UI.RG_gbBG := UI.Main.Add("GroupBox", Format("x{} y{} w{} h290", x, y, fullW), "黑框防抖")
    page.Controls.Push(UI.RG_gbBG)

    gy := y + 26
    UI.RG_cbBG := UI.Main.Add("CheckBox", Format("x{} y{} w120", x + 10, gy), "启用")
    page.Controls.Push(UI.RG_cbBG)
    gy := gy + rowH

    UI.RG_labBG_Samp := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "采样数：")
    UI.RG_edBG_Samp := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Samp)
    page.Controls.Push(UI.RG_edBG_Samp)
    gy := gy + rowH

    UI.RG_labBG_Ratio := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "黑像素阈值：")
    UI.RG_edBG_Ratio := UI.Main.Add("Edit", "x+10 w200 Center")
    page.Controls.Push(UI.RG_labBG_Ratio)
    page.Controls.Push(UI.RG_edBG_Ratio)
    gy := gy + rowH

    UI.RG_labBG_Win := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "冻结窗(ms)：")
    UI.RG_edBG_Win := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Win)
    page.Controls.Push(UI.RG_edBG_Win)
    gy := gy + rowH

    UI.RG_labBG_Cool := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "冷却(ms)：")
    UI.RG_edBG_Cool := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Cool)
    page.Controls.Push(UI.RG_edBG_Cool)
    gy := gy + rowH

    UI.RG_labBG_Min := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "最小延迟(ms)：")
    UI.RG_edBG_Min := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Min)
    page.Controls.Push(UI.RG_edBG_Min)
    gy := gy + rowH

    UI.RG_labBG_Max := UI.Main.Add("Text", Format("x{} y{} w120 Right", x + 10, gy), "最大延迟(ms)：")
    UI.RG_edBG_Max := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Max)
    page.Controls.Push(UI.RG_edBG_Max)
    gy := gy + rowH

    ; 需要唯一黑框（遗漏补回）
    UI.RG_cbBG_Uniq := UI.Main.Add("CheckBox", Format("x{} y{} w140", x + 10, gy), "需要唯一黑框")
    page.Controls.Push(UI.RG_cbBG_Uniq)

    ; 保存按钮
    UI.RG_btnSave := UI.Main.Add("Button", Format("x{} y{} w120", x, y + 300), "保存")
    UI.RG_btnSave.OnEvent("Click", Page_RotGen_OnSave)
    page.Controls.Push(UI.RG_btnSave)

    Page_RotGen_Refresh()
}

Page_RotGen_Layout(rc) {
    try {
        UI.RG_gbBG.Move(rc.X, , rc.W)
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
        DllCall("user32\SendMessageW", "ptr", UI.RG_ddDefTrack.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)  ; CB_RESETCONTENT
    } catch {
    }

    names := []
    ids := []

    ; 优先从 cfg.Tracks 读取 Id 和 Name
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

    ; 没有 Tracks 时，回退到 Id 列表（显示为“轨道#Id”）
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

    ; 写入下拉与位置信息
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

    ; 默认轨道：优先用 UI.RG_trackIds，把选择位置映射到 TrackId
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