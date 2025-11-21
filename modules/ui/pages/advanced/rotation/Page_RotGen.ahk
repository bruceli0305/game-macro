; modules\ui\pages\advanced\rotation\Page_RotGen.ahk
#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"

Page_RotGen_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    if !IsSet(App) || !App.Has("ProfileData") {
        UI.RG_Empty := UI.Main.Add("Text", Format("x{} y{} w{} h24", rc.X, rc.Y, rc.W), "尚未加载配置。")
        page.Controls.Push(UI.RG_Empty)
        return
    }

    prof := App["ProfileData"]
    if !HasProp(prof,"Rotation")
        prof.Rotation := {}
    cfg := prof.Rotation
    ; REUI_EnsureRotationDefaults(&cfg)

    x := rc.X
    y := rc.Y
    rowH := 34
    fullW := rc.W - 20

    ; ============ 第一行：启用 =============
    UI.RG_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w200", x, y), "启用轮换")
    page.Controls.Push(UI.RG_cbEnable)
    y += rowH

    ; ============ 默认轨道 ============
    UI.RG_labDef := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "默认轨道：")
    UI.RG_ddDefTrack := UI.Main.Add("DropDownList", Format("x+10 w200"))
    page.Controls.Push(UI.RG_labDef, UI.RG_ddDefTrack)
    y += rowH

    ; ============ 忙窗 ============
    UI.RG_labBusy := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "忙窗(ms)：")
    UI.RG_edBusy := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBusy, UI.RG_edBusy)
    y += rowH

    ; ============ 黑色容差 ============
    UI.RG_labTol := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "黑色容差：")
    UI.RG_edTol := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labTol, UI.RG_edTol)
    y += rowH

    ; ============ 切换键（附带验证） ============
    UI.RG_labSwap := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "切换键：")
    UI.RG_hkSwap := UI.Main.Add("Hotkey", "x+10 w200")
    UI.RG_cbVerifySwap := UI.Main.Add("CheckBox", "x+20 w120", "验证切换")
    page.Controls.Push(UI.RG_labSwap, UI.RG_hkSwap, UI.RG_cbVerifySwap)
    y += rowH

    ; ============ 切换超时 ============
    UI.RG_labSwapTO := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "切换超时(ms)：")
    UI.RG_edSwapTO := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labSwapTO, UI.RG_edSwapTO)
    y += rowH

    ; ============ 重试次数 ============
    UI.RG_labSwapRetry := UI.Main.Add("Text", Format("x{} y{} w120 Right", x, y), "重试次数：")
    UI.RG_edSwapRetry := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labSwapRetry, UI.RG_edSwapRetry)
    y += rowH

    ; ============ 尊重施法锁 ============
    UI.RG_cbCast := UI.Main.Add("CheckBox", Format("x{} y{} w200", x, y), "尊重施法锁")
    page.Controls.Push(UI.RG_cbCast)
    y += rowH

    ; ============ 启用跳轨 + 冷却 ============
    UI.RG_cbGates := UI.Main.Add("CheckBox", Format("x{} y{} w120", x, y), "启用跳轨")
    UI.RG_labGateCd := UI.Main.Add("Text", "x+10 w80", "冷却(ms)：")
    UI.RG_edGateCd := UI.Main.Add("Edit", "x+10 w110 Number Center")
    page.Controls.Push(UI.RG_cbGates, UI.RG_labGateCd, UI.RG_edGateCd)
    y += (rowH + 12)

    ; ============================================================
    ;                     黑框防抖（每行独立）  
    ; ============================================================
    UI.RG_gbBG := UI.Main.Add("GroupBox", Format("x{} y{} w{} h290", x, y, fullW), "黑框防抖")
    page.Controls.Push(UI.RG_gbBG)

    gy := y + 26

    ; 启用
    UI.RG_cbBG := UI.Main.Add("CheckBox", Format("x{} y{} w120", x+10, gy), "启用")
    page.Controls.Push(UI.RG_cbBG)
    gy += rowH

    ; 采样数
    UI.RG_labBG_Samp := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "采样数：")
    UI.RG_edBG_Samp := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Samp, UI.RG_edBG_Samp)
    gy += rowH

    ; 黑像素阈值
    UI.RG_labBG_Ratio := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "黑像素阈值：")
    UI.RG_edBG_Ratio := UI.Main.Add("Edit", "x+10 w200 Center")
    page.Controls.Push(UI.RG_labBG_Ratio, UI.RG_edBG_Ratio)
    gy += rowH

    ; 冻结窗
    UI.RG_labBG_Win := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "冻结窗(ms)：")
    UI.RG_edBG_Win := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Win, UI.RG_edBG_Win)
    gy += rowH

    ; 冷却
    UI.RG_labBG_Cool := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "冷却(ms)：")
    UI.RG_edBG_Cool := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Cool, UI.RG_edBG_Cool)
    gy += rowH

    ; 黑窗最小延迟
    UI.RG_labBG_Min := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "最小延迟(ms)：")
    UI.RG_edBG_Min := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Min, UI.RG_edBG_Min)
    gy += rowH

    ; 黑窗最大延迟
    UI.RG_labBG_Max := UI.Main.Add("Text", Format("x{} y{} w120 Right", x+10, gy), "最大延迟(ms)：")
    UI.RG_edBG_Max := UI.Main.Add("Edit", "x+10 w200 Number Center")
    page.Controls.Push(UI.RG_labBG_Max, UI.RG_edBG_Max)
    gy += rowH

    ; 唯一黑框
    UI.RG_cbBG_Uniq := UI.Main.Add("CheckBox", Format("x{} y{} w140", x+10, gy), "需要唯一黑框")
    page.Controls.Push(UI.RG_cbBG_Uniq)

    ; 保存按钮
    UI.RG_btnSave := UI.Main.Add("Button", Format("x{} y{} w120", x, y+300), "保存")
    UI.RG_btnSave.OnEvent("Click", Page_RotGen_OnSave)
    page.Controls.Push(UI.RG_btnSave)

    Page_RotGen_Refresh()
}


Page_RotGen_Layout(rc) {
    try {
        ; 主要动态是 Group 宽度与保存按钮纵向位置，其他控件横向自动布局即可
        UI.RG_gbBG.Move(rc.X, , rc.W)
    } catch {
    }
}

Page_RotGen_OnEnter(*) {
    Page_RotGen_Refresh()
}

; 填充与保存
Page_RotGen_Refresh() {
    global UI, App
    if !IsSet(App) || !App.Has("ProfileData") {
        return
    }

    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation  ; 只读，不要在刷新里改 cfg 或 prof.Rotation

    ; 默认轨道下拉（使用稳定 TrackId 列表）
    ids := REUI_ListTrackIds(cfg)
    try {
        DllCall("user32\SendMessageW", "ptr", UI.RG_ddDefTrack.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)  ; CB_RESETCONTENT
    } catch {
    }
    try {
        if (IsObject(ids) && ids.Length > 0) {
            UI.RG_ddDefTrack.Add(ids)
            pos := 1
            wantId := OM_Get(cfg, "DefaultTrackId", 1)
            i := 1
            while (i <= ids.Length) {
                idVal := 0
                try {
                    idVal := Integer(ids[i])
                } catch {
                    idVal := 0
                }
                if (idVal = wantId) {
                    pos := i
                    break
                }
                i := i + 1
            }
            UI.RG_ddDefTrack.Value := pos
        }
    } catch {
    }

    ; 勾选/数值（全部只读 cfg，不写 cfg）
    val := 0
    try {
        val := OM_Get(cfg, "Enabled", 0)
        UI.RG_cbEnable.Value := (val ? 1 : 0)
    } catch {
    }

    try {
        UI.RG_edBusy.Value := OM_Get(cfg, "BusyWindowMs", 200)
    } catch {
    }
    try {
        UI.RG_edTol.Value := OM_Get(cfg, "ColorTolBlack", 16)
    } catch {
    }

    try {
        UI.RG_cbCast.Value := (OM_Get(cfg, "RespectCastLock", 1) ? 1 : 0)
    } catch {
    }

    try {
        UI.RG_hkSwap.Value := OM_Get(cfg, "SwapKey", "")
    } catch {
    }
    try {
        UI.RG_cbVerifySwap.Value := (OM_Get(cfg, "VerifySwap", 0) ? 1 : 0)
    } catch {
    }
    try {
        UI.RG_edSwapTO.Value := OM_Get(cfg, "SwapTimeoutMs", 800)
    } catch {
    }
    try {
        UI.RG_edSwapRetry.Value := OM_Get(cfg, "SwapRetry", 0)
    } catch {
    }

    try {
        UI.RG_cbGates.Value := (OM_Get(cfg, "GatesEnabled", 0) ? 1 : 0)
    } catch {
    }
    try {
        UI.RG_edGateCd.Value := OM_Get(cfg, "GateCooldownMs", 0)
    } catch {
    }

    bg := Map()
    try {
        bg := OM_Get(cfg, "BlackGuard", Map())
    } catch {
        bg := Map()
    }
    try {
        UI.RG_cbBG.Value := (OM_Get(bg, "Enabled", 1) ? 1 : 0)
    } catch {
    }
    try {
        UI.RG_edBG_Samp.Value := OM_Get(bg, "SampleCount", 5)
    } catch {
    }
    try {
        UI.RG_edBG_Ratio.Value := OM_Get(bg, "BlackRatioThresh", 0.7)
    } catch {
    }
    try {
        UI.RG_edBG_Win.Value := OM_Get(bg, "WindowMs", 120)
    } catch {
    }
    try {
        UI.RG_edBG_Cool.Value := OM_Get(bg, "CooldownMs", 600)
    } catch {
    }
    try {
        UI.RG_edBG_Min.Value := OM_Get(bg, "MinAfterSendMs", 60)
    } catch {
    }
    try {
        UI.RG_edBG_Max.Value := OM_Get(bg, "MaxAfterSendMs", 800)
    } catch {
    }
    try {
        UI.RG_cbBG_Uniq.Value := (OM_Get(bg, "UniqueRequired", 1) ? 1 : 0)
    } catch {
    }
}

Page_RotGen_OnSave(*) {
    global UI, App
    if !IsSet(App) || !App.Has("ProfileData") {
        MsgBox "未加载配置，无法保存。"
        return
    }

    prof := App["ProfileData"]
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }

    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)

    ; 1) 从 UI 读取值到运行时 cfg（保留你原有逻辑）
    cfg.Enabled := UI.RG_cbEnable.Value ? 1 : 0

    idsNow := REUI_ListTrackIds(cfg)
    if (UI.RG_ddDefTrack.Value >= 1 && UI.RG_ddDefTrack.Value <= idsNow.Length) {
        cfg.DefaultTrackId := Integer(idsNow[UI.RG_ddDefTrack.Value])
    } else {
        cfg.DefaultTrackId := 1
    }

    cfg.BusyWindowMs  := (UI.RG_edBusy.Value  != "") ? Integer(UI.RG_edBusy.Value)  : 200
    cfg.ColorTolBlack := (UI.RG_edTol.Value   != "") ? Integer(UI.RG_edTol.Value)   : 16
    cfg.RespectCastLock := UI.RG_cbCast.Value ? 1 : 0

    cfg.SwapKey      := Trim(UI.RG_hkSwap.Value)
    cfg.VerifySwap   := UI.RG_cbVerifySwap.Value ? 1 : 0
    cfg.SwapTimeoutMs:= (UI.RG_edSwapTO.Value   != "") ? Integer(UI.RG_edSwapTO.Value) : 800
    cfg.SwapRetry    := (UI.RG_edSwapRetry.Value!= "") ? Integer(UI.RG_edSwapRetry.Value) : 0

    cfg.GatesEnabled := UI.RG_cbGates.Value ? 1 : 0
    cfg.GateCooldownMs := (UI.RG_edGateCd.Value != "") ? Integer(UI.RG_edGateCd.Value) : 0

    bg := HasProp(cfg, "BlackGuard") ? cfg.BlackGuard : {}
    bg.Enabled          := UI.RG_cbBG.Value ? 1 : 0
    bg.SampleCount      := (UI.RG_edBG_Samp.Value  != "") ? Integer(UI.RG_edBG_Samp.Value)  : 5
    bg.BlackRatioThresh := (UI.RG_edBG_Ratio.Value != "") ? (UI.RG_edBG_Ratio.Value + 0)     : 0.7
    bg.WindowMs         := (UI.RG_edBG_Win.Value   != "") ? Integer(UI.RG_edBG_Win.Value)   : 120
    bg.CooldownMs       := (UI.RG_edBG_Cool.Value  != "") ? Integer(UI.RG_edBG_Cool.Value)  : 600
    bg.MinAfterSendMs   := (UI.RG_edBG_Min.Value   != "") ? Integer(UI.RG_edBG_Min.Value)   : 60
    bg.MaxAfterSendMs   := (UI.RG_edBG_Max.Value   != "") ? Integer(UI.RG_edBG_Max.Value)   : 800
    bg.UniqueRequired   := UI.RG_cbBG_Uniq.Value ? 1 : 0
    cfg.BlackGuard := bg

    prof.Rotation := cfg

    ; 2) 写入文件夹模型并保存 rotation_base.ini
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置，无法保存。"
        return
    }

    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch {
        MsgBox "加载配置失败。"
        return
    }

    ; 构造文件夹模型的 Rotation（Map），兼容 Map/{} 读取
    rot := Map()
    try {
        rot["Enabled"]        := OM_Get(cfg, "Enabled", 0)
        rot["DefaultTrackId"] := OM_Get(cfg, "DefaultTrackId", 0)
        rot["SwapKey"]        := OM_Get(cfg, "SwapKey", "")
        rot["BusyWindowMs"]   := OM_Get(cfg, "BusyWindowMs", 200)
        rot["ColorTolBlack"]  := OM_Get(cfg, "ColorTolBlack", 16)
        rot["RespectCastLock"]:= OM_Get(cfg, "RespectCastLock", 1)
        rot["GatesEnabled"]   := OM_Get(cfg, "GatesEnabled", 0)
        rot["GateCooldownMs"] := OM_Get(cfg, "GateCooldownMs", 0)
    } catch {
    }

    ; SwapVerify
    svCfg := Map()
    try {
        svCfg := OM_Get(cfg, "SwapVerify", Map())
    } catch {
        svCfg := Map()
    }
    sv := Map()
    try {
        sv["RefType"] := OM_Get(svCfg, "RefType", "Skill")
        sv["RefId"]   := OM_Get(svCfg, "RefId", 0)
        sv["Op"]      := OM_Get(svCfg, "Op", "NEQ")
        sv["Color"]   := OM_Get(svCfg, "Color", "0x000000")
        sv["Tol"]     := OM_Get(svCfg, "Tol", 16)
    } catch {
    }
    try {
        rot["SwapVerify"] := sv
        rot["VerifySwap"] := OM_Get(cfg, "VerifySwap", 0)
        rot["SwapTimeoutMs"] := OM_Get(cfg, "SwapTimeoutMs", 800)
        rot["SwapRetry"]     := OM_Get(cfg, "SwapRetry", 0)
    } catch {
    }

    ; BlackGuard
    bgCfg := Map()
    try {
        bgCfg := OM_Get(cfg, "BlackGuard", Map())
    } catch {
        bgCfg := Map()
    }
    bg2 := Map()
    try {
        bg2["Enabled"]         := OM_Get(bgCfg, "Enabled", 1)
        bg2["SampleCount"]     := OM_Get(bgCfg, "SampleCount", 5)
        bg2["BlackRatioThresh"]:= OM_Get(bgCfg, "BlackRatioThresh", 0.7)
        bg2["WindowMs"]        := OM_Get(bgCfg, "WindowMs", 120)
        bg2["CooldownMs"]      := OM_Get(bgCfg, "CooldownMs", 600)
        bg2["MinAfterSendMs"]  := OM_Get(bgCfg, "MinAfterSendMs", 60)
        bg2["MaxAfterSendMs"]  := OM_Get(bgCfg, "MaxAfterSendMs", 800)
        bg2["UniqueRequired"]  := OM_Get(bgCfg, "UniqueRequired", 1)
    } catch {
    }
    try {
        rot["BlackGuard"] := bg2
    } catch {
    }

    try {
        p["Rotation"] := rot
    } catch {
    }

    ok := false
    try {
        SaveModule_RotationBase(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    ; 3) 重载 → 规范化 → 轻量重建
    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        try RE_OnProfileDataReplaced(App["ProfileData"])
    } catch {
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
    } catch {
    }

    Notify("常规配置已保存")
}