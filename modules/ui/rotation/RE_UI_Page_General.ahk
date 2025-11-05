; modules\ui\rotation\RE_UI_Page_General.ahk
#Requires AutoHotkey v2

; 返回 { Save: Func }
REUI_Page_General_Build(ctx) {
    dlg := ctx.dlg
    cfg := ctx.cfg

    tab := ctx.tab
    tab.UseTab(1)

    ; 文案为纯中文
    cbEnable := dlg.Add("CheckBox", "xm y+10 w160", "启用轮换")
    cbEnable.Value := cfg.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "默认轨道：")
    ddDefTrack := dlg.Add("DropDownList", "x+6 w160")
    ids := REUI_ListTrackIds(cfg)
    if ids.Length {
        ddDefTrack.Add(ids)
        pos := 1
        for i, v in ids
            if (Integer(v) = Integer(cfg.DefaultTrackId)) {
                pos := i
                break
            }
        ddDefTrack.Value := pos
    }

    dlg.Add("Text", "xm y+8 w100 Right", "忙窗(ms)：")
    edBusy := dlg.Add("Edit", "x+6 w120 Number Center", cfg.BusyWindowMs)

    dlg.Add("Text", "x+20 w110 Right", "黑色容差：")
    edTol := dlg.Add("Edit", "x+6 w120 Number Center", cfg.ColorTolBlack)

    cbCast := dlg.Add("CheckBox", "xm y+8 w200", "尊重施法锁")
    cbCast.Value := cfg.RespectCastLock ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "切换键：")
    hkSwap := dlg.Add("Hotkey", "x+6 w160", cfg.SwapKey)
    cbVerifySwap := dlg.Add("CheckBox", "x+12 w120", "验证切换")
    cbVerifySwap.Value := cfg.VerifySwap ? 1 : 0

    dlg.Add("Text", "xm y+8 w100 Right", "切换超时(ms)：")
    edSwapTO := dlg.Add("Edit", "x+6 w120 Number Center", cfg.SwapTimeoutMs)
    dlg.Add("Text", "x+20 w100 Right", "重试次数：")
    edSwapRetry := dlg.Add("Edit", "x+6 w120 Number Center", cfg.SwapRetry)

    cbGates := dlg.Add("CheckBox", "xm y+8 w200", "启用跳轨")
    cbGates.Value := cfg.GatesEnabled ? 1 : 0
    dlg.Add("Text", "x+12 w100 Right", "跳轨冷却(ms)：")
    edGateCd := dlg.Add("Edit", "x+6 w120 Number Center", cfg.GateCooldownMs)

    ; 黑框防抖
    gb := dlg.Add("GroupBox", "xm y+12 w820 h150", "黑框防抖")
    cbBG := dlg.Add("CheckBox", "xp+12 yp+26 w80", "启用")
    cbBG.Value := cfg.BlackGuard.Enabled ? 1 : 0
    dlg.Add("Text", "x+10 w70 Right", "采样数：")
    edBG_Samp := dlg.Add("Edit", "x+6 w80 Number Center", cfg.BlackGuard.SampleCount)

    dlg.Add("Text", "x+16 w110 Right", "黑像素阈值：")
    ratio := Round(HasProp(cfg.BlackGuard, "BlackRatioThresh") ? cfg.BlackGuard.BlackRatioThresh : 0.7, 2)
    edBG_Ratio := dlg.Add("Edit", "x+6 w100 Center", ratio)

    dlg.Add("Text", "x+16 w100 Right", "冻结窗(ms)：")
    edBG_Win := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.WindowMs)

    dlg.Add("Text", "xm y+10 w100 Right", "冷却(ms)：")
    edBG_Cool := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.CooldownMs)

    dlg.Add("Text", "x+16 w120 Right", "黑窗最小延迟(ms)：")
    edBG_Min := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.MinAfterSendMs)

    dlg.Add("Text", "x+16 w120 Right", "黑窗最大延迟(ms)：")
    edBG_Max := dlg.Add("Edit", "x+6 w100 Number Center", cfg.BlackGuard.MaxAfterSendMs)

    cbBG_Uniq := dlg.Add("CheckBox", "x+16 w140", "需要唯一黑框")
    cbBG_Uniq.Value := cfg.BlackGuard.UniqueRequired ? 1 : 0

    ; 返回保存函数
    Save := () => (
        cfg.Enabled := cbEnable.Value ? 1 : 0
      , (idsNow := REUI_ListTrackIds(cfg))
      , (cfg.DefaultTrackId := (ddDefTrack.Value>=1 && ddDefTrack.Value<=idsNow.Length) ? Integer(idsNow[ddDefTrack.Value]) : 1)
      , (cfg.BusyWindowMs := (edBusy.Value!="") ? Integer(edBusy.Value) : 200)
      , (cfg.ColorTolBlack := (edTol.Value!="") ? Integer(edTol.Value) : 16)
      , (cfg.RespectCastLock := cbCast.Value ? 1 : 0)
      , (cfg.SwapKey := Trim(hkSwap.Value))
      , (cfg.VerifySwap := cbVerifySwap.Value ? 1 : 0)
      , (cfg.SwapTimeoutMs := (edSwapTO.Value!="") ? Integer(edSwapTO.Value) : 800)
      , (cfg.SwapRetry := (edSwapRetry.Value!="") ? Integer(edSwapRetry.Value) : 0)
      , (cfg.GatesEnabled := cbGates.Value ? 1 : 0)
      , (cfg.GateCooldownMs := (edGateCd.Value!="") ? Integer(edGateCd.Value) : 0)
      , (bg := cfg.BlackGuard)
      , (bg.Enabled := cbBG.Value ? 1 : 0)
      , (bg.SampleCount := (edBG_Samp.Value!="") ? Integer(edBG_Samp.Value) : 5)
      , (bg.BlackRatioThresh := (edBG_Ratio.Value!="") ? (edBG_Ratio.Value+0) : 0.7)
      , (bg.WindowMs := (edBG_Win.Value!="") ? Integer(edBG_Win.Value) : 120)
      , (bg.CooldownMs := (edBG_Cool.Value!="") ? Integer(edBG_Cool.Value) : 600)
      , (bg.MinAfterSendMs := (edBG_Min.Value!="") ? Integer(edBG_Min.Value) : 60)
      , (bg.MaxAfterSendMs := (edBG_Max.Value!="") ? Integer(edBG_Max.Value) : 800)
      , (bg.UniqueRequired := cbBG_Uniq.Value ? 1 : 0)
      , (cfg.BlackGuard := bg)
    )

    return { Save: Save }
}