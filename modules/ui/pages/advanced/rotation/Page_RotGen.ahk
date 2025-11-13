; modules\ui\pages\advanced\rotation\Page_RotGen.ahk
#Requires AutoHotkey v2
#Include "..\..\..\rotation\RE_UI_Common.ahk"

; 轮换配置 - 常规页
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
    if !HasProp(prof, "Rotation") {
        prof.Rotation := {}
    }
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    prof.Rotation := cfg

    ; 行距与列宽
    x := rc.X
    y := rc.Y
    labelW := 110
    colW := 160
    gapX := 10
    gapY := 10

    ; 启用
    UI.RG_cbEnable := UI.Main.Add("CheckBox", Format("x{} y{} w160", x, y), "启用轮换")
    page.Controls.Push(UI.RG_cbEnable)

    ; 默认轨道 + 忙窗 + 黑色容差
    y := y + 34
    UI.RG_labDef := UI.Main.Add("Text", Format("x{} y{} w{} Right", x, y, labelW), "默认轨道：")
    UI.RG_ddDefTrack := UI.Main.Add("DropDownList", Format("x+{} w{}", gapX, colW))
    page.Controls.Push(UI.RG_labDef), page.Controls.Push(UI.RG_ddDefTrack)

    UI.RG_labBusy := UI.Main.Add("Text", Format("x+{} w{} Right", 20, labelW), "忙窗(ms)：")
    UI.RG_edBusy := UI.Main.Add("Edit", Format("x+{} w120 Number Center", gapX))
    page.Controls.Push(UI.RG_labBusy), page.Controls.Push(UI.RG_edBusy)

    UI.RG_labTol := UI.Main.Add("Text", Format("x+{} w{} Right", 20, 110), "黑色容差：")
    UI.RG_edTol := UI.Main.Add("Edit", Format("x+{} w120 Number Center", gapX))
    page.Controls.Push(UI.RG_labTol), page.Controls.Push(UI.RG_edTol)

    ; 尊重施法锁
    y := y + 36
    UI.RG_cbCast := UI.Main.Add("CheckBox", Format("x{} y{} w200", x, y), "尊重施法锁")
    page.Controls.Push(UI.RG_cbCast)

    ; 切换键/验证
    y := y + 34
    UI.RG_labSwap := UI.Main.Add("Text", Format("x{} y{} w{} Right", x, y, labelW), "切换键：")
    UI.RG_hkSwap := UI.Main.Add("Hotkey", Format("x+{} w{}", gapX, colW))
    UI.RG_cbVerifySwap := UI.Main.Add("CheckBox", "x+12 w120", "验证切换")
    page.Controls.Push(UI.RG_labSwap), page.Controls.Push(UI.RG_hkSwap), page.Controls.Push(UI.RG_cbVerifySwap)

    ; 切换超时/重试
    y := y + 36
    UI.RG_labSwapTO := UI.Main.Add("Text", Format("x{} y{} w{} Right", x, y, labelW), "切换超时(ms)：")
    UI.RG_edSwapTO := UI.Main.Add("Edit", Format("x+{} w120 Number Center", gapX))
    UI.RG_labSwapRetry := UI.Main.Add("Text", "x+20 w100 Right", "重试次数：")
    UI.RG_edSwapRetry := UI.Main.Add("Edit", "x+6 w120 Number Center")
    page.Controls.Push(UI.RG_labSwapTO), page.Controls.Push(UI.RG_edSwapTO), page.Controls.Push(UI.RG_labSwapRetry), page.Controls.Push(UI.RG_edSwapRetry)

    ; 启用跳轨 + 冷却
    y := y + 36
    UI.RG_cbGates := UI.Main.Add("CheckBox", Format("x{} y{} w200", x, y), "启用跳轨")
    UI.RG_labGateCd := UI.Main.Add("Text", "x+12 w100 Right", "跳轨冷却(ms)：")
    UI.RG_edGateCd := UI.Main.Add("Edit", "x+6 w120 Number Center")
    page.Controls.Push(UI.RG_cbGates), page.Controls.Push(UI.RG_labGateCd), page.Controls.Push(UI.RG_edGateCd)

    ; 黑框防抖 Group
    y := y + 48
    UI.RG_gbBG := UI.Main.Add("GroupBox", Format("x{} y{} w{} h150", x, y, rc.W), "黑框防抖")
    page.Controls.Push(UI.RG_gbBG)

    UI.RG_cbBG := UI.Main.Add("CheckBox", Format("x{} y{} w80", x + 12, y + 26), "启用")
    UI.RG_labBG_Samp := UI.Main.Add("Text", "x+10 w70 Right", "采样数：")
    UI.RG_edBG_Samp := UI.Main.Add("Edit", "x+6 w80 Number Center")
    page.Controls.Push(UI.RG_cbBG), page.Controls.Push(UI.RG_labBG_Samp), page.Controls.Push(UI.RG_edBG_Samp)

    UI.RG_labBG_Ratio := UI.Main.Add("Text", "x+16 w110 Right", "黑像素阈值：")
    UI.RG_edBG_Ratio := UI.Main.Add("Edit", "x+6 w100 Center")
    page.Controls.Push(UI.RG_labBG_Ratio), page.Controls.Push(UI.RG_edBG_Ratio)

    UI.RG_labBG_Win := UI.Main.Add("Text", "x+16 w100 Right", "冻结窗(ms)：")
    UI.RG_edBG_Win := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.RG_labBG_Win), page.Controls.Push(UI.RG_edBG_Win)

    y2 := y + 26 + 28
    UI.RG_labBG_Cool := UI.Main.Add("Text", Format("x{} y{} w100 Right", x + 12, y2), "冷却(ms)：")
    UI.RG_edBG_Cool := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.RG_labBG_Cool), page.Controls.Push(UI.RG_edBG_Cool)

    UI.RG_labBG_Min := UI.Main.Add("Text", "x+16 w120 Right", "黑窗最小延迟(ms)：")
    UI.RG_edBG_Min := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.RG_labBG_Min), page.Controls.Push(UI.RG_edBG_Min)

    UI.RG_labBG_Max := UI.Main.Add("Text", "x+16 w120 Right", "黑窗最大延迟(ms)：")
    UI.RG_edBG_Max := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.RG_labBG_Max), page.Controls.Push(UI.RG_edBG_Max)

    UI.RG_cbBG_Uniq := UI.Main.Add("CheckBox", "x+16 w140", "需要唯一黑框")
    page.Controls.Push(UI.RG_cbBG_Uniq)

    ; 保存按钮
    yBtn := y + 150 + 12
    UI.RG_btnSave := UI.Main.Add("Button", Format("x{} y{} w120", x, yBtn), "保存")
    page.Controls.Push(UI.RG_btnSave)
    UI.RG_btnSave.OnEvent("Click", Page_RotGen_OnSave)

    ; 初次填充
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
    cfg := prof.Rotation
    REUI_EnsureRotationDefaults(&cfg)
    prof.Rotation := cfg

    ; 默认轨道下拉
    ids := REUI_ListTrackIds(cfg)
    try {
        DllCall("user32\SendMessageW", "ptr", UI.RG_ddDefTrack.Hwnd, "uint", 0x014B, "ptr", 0, "ptr", 0)
        if (ids.Length) {
            UI.RG_ddDefTrack.Add(ids)
            pos := 1
            for i, v in ids {
                if (Integer(v) = Integer(cfg.DefaultTrackId)) {
                    pos := i
                    break
                }
            }
            UI.RG_ddDefTrack.Value := pos
        }
    } catch {
    }

    UI.RG_cbEnable.Value := cfg.Enabled ? 1 : 0
    UI.RG_edBusy.Value := HasProp(cfg,"BusyWindowMs") ? cfg.BusyWindowMs : 200
    UI.RG_edTol.Value := HasProp(cfg,"ColorTolBlack") ? cfg.ColorTolBlack : 16

    UI.RG_cbCast.Value := HasProp(cfg,"RespectCastLock") ? (cfg.RespectCastLock?1:0) : 0

    UI.RG_hkSwap.Value := HasProp(cfg,"SwapKey") ? cfg.SwapKey : ""
    UI.RG_cbVerifySwap.Value := HasProp(cfg,"VerifySwap") ? (cfg.VerifySwap?1:0) : 0
    UI.RG_edSwapTO.Value := HasProp(cfg,"SwapTimeoutMs") ? cfg.SwapTimeoutMs : 800
    UI.RG_edSwapRetry.Value := HasProp(cfg,"SwapRetry") ? cfg.SwapRetry : 0

    UI.RG_cbGates.Value := HasProp(cfg,"GatesEnabled") ? (cfg.GatesEnabled?1:0) : 0
    UI.RG_edGateCd.Value := HasProp(cfg,"GateCooldownMs") ? cfg.GateCooldownMs : 0

    bg := HasProp(cfg,"BlackGuard") ? cfg.BlackGuard : {}
    UI.RG_cbBG.Value := HasProp(bg,"Enabled") ? (bg.Enabled?1:0) : 0
    UI.RG_edBG_Samp.Value := HasProp(bg,"SampleCount") ? bg.SampleCount : 5
    UI.RG_edBG_Ratio.Value := HasProp(bg,"BlackRatioThresh") ? Round(bg.BlackRatioThresh,2) : 0.7
    UI.RG_edBG_Win.Value := HasProp(bg,"WindowMs") ? bg.WindowMs : 120
    UI.RG_edBG_Cool.Value := HasProp(bg,"CooldownMs") ? bg.CooldownMs : 600
    UI.RG_edBG_Min.Value := HasProp(bg,"MinAfterSendMs") ? bg.MinAfterSendMs : 60
    UI.RG_edBG_Max.Value := HasProp(bg,"MaxAfterSendMs") ? bg.MaxAfterSendMs : 800
    UI.RG_cbBG_Uniq.Value := HasProp(bg,"UniqueRequired") ? (bg.UniqueRequired?1:0) : 0
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

    ; 读取控件值
    cfg.Enabled := UI.RG_cbEnable.Value ? 1 : 0

    idsNow := REUI_ListTrackIds(cfg)
    if (UI.RG_ddDefTrack.Value>=1 && UI.RG_ddDefTrack.Value<=idsNow.Length) {
        cfg.DefaultTrackId := Integer(idsNow[UI.RG_ddDefTrack.Value])
    } else {
        cfg.DefaultTrackId := 1
    }

    cfg.BusyWindowMs := (UI.RG_edBusy.Value!="") ? Integer(UI.RG_edBusy.Value) : 200
    cfg.ColorTolBlack := (UI.RG_edTol.Value!="") ? Integer(UI.RG_edTol.Value) : 16

    cfg.RespectCastLock := UI.RG_cbCast.Value ? 1 : 0

    cfg.SwapKey := Trim(UI.RG_hkSwap.Value)
    cfg.VerifySwap := UI.RG_cbVerifySwap.Value ? 1 : 0
    cfg.SwapTimeoutMs := (UI.RG_edSwapTO.Value!="") ? Integer(UI.RG_edSwapTO.Value) : 800
    cfg.SwapRetry := (UI.RG_edSwapRetry.Value!="") ? Integer(UI.RG_edSwapRetry.Value) : 0

    cfg.GatesEnabled := UI.RG_cbGates.Value ? 1 : 0
    cfg.GateCooldownMs := (UI.RG_edGateCd.Value!="") ? Integer(UI.RG_edGateCd.Value) : 0

    bg := HasProp(cfg,"BlackGuard") ? cfg.BlackGuard : {}
    bg.Enabled := UI.RG_cbBG.Value ? 1 : 0
    bg.SampleCount := (UI.RG_edBG_Samp.Value!="") ? Integer(UI.RG_edBG_Samp.Value) : 5
    bg.BlackRatioThresh := (UI.RG_edBG_Ratio.Value!="") ? (UI.RG_edBG_Ratio.Value+0) : 0.7
    bg.WindowMs := (UI.RG_edBG_Win.Value!="") ? Integer(UI.RG_edBG_Win.Value) : 120
    bg.CooldownMs := (UI.RG_edBG_Cool.Value!="") ? Integer(UI.RG_edBG_Cool.Value) : 600
    bg.MinAfterSendMs := (UI.RG_edBG_Min.Value!="") ? Integer(UI.RG_edBG_Min.Value) : 60
    bg.MaxAfterSendMs := (UI.RG_edBG_Max.Value!="") ? Integer(UI.RG_edBG_Max.Value) : 800
    bg.UniqueRequired := UI.RG_cbBG_Uniq.Value ? 1 : 0
    cfg.BlackGuard := bg

    prof.Rotation := cfg
    Storage_SaveProfile(prof)
    Notify("常规配置已保存")
}