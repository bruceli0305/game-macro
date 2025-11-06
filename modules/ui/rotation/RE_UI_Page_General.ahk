; modules\ui\rotation\RE_UI_Page_General.ahk
#Requires AutoHotkey v2
#Include "..\shell_v2\UIX_Common.ahk"

REUI_Page_General_Build(ctx) {
    dlg := ctx.dlg
    tab := ctx.tab
    cfg := ctx.cfg

    tab.UseTab(1)
    rc := UIX_PageRect(dlg)
    cols := UIX_Cols2(rc, 0.58, 12)
    L := cols.L, R := cols.R

    ; 取轨道ID列表
    ids := []
    try {
        if HasProp(cfg,"Tracks") && IsObject(cfg.Tracks) && cfg.Tracks.Length>0 {
            for _, t in cfg.Tracks
                ids.Push(t.Id)
        } else {
            ids := [1,2]
        }
    }

    y := L.Y
    cbEnable := dlg.Add("CheckBox", Format("x{} y{} w160", L.X, y), "启用轮换")
    cbEnable.Value := HasProp(cfg,"Enabled") ? (cfg.Enabled?1:0) : 0

    y += 34
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X, y), "默认轨道：")
    ddDef := dlg.Add("DropDownList", Format("x{} y{} w160", L.X + 100 + 6, y), ids)
    if (ids.Length) {
        pos := 1
        defId := HasProp(cfg,"DefaultTrackId") ? cfg.DefaultTrackId : 1
        for i, v in ids
            if (Integer(v) = Integer(defId)) { 
                pos := i
                break 
            }
        ddDef.Value := pos
    }

    y += 34
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X, y), "忙窗(ms)：")
    edBusy := dlg.Add("Edit", Format("x{} y{} w120", L.X + 100 + 6, y), HasProp(cfg,"BusyWindowMs") ? cfg.BusyWindowMs : 200)

    dlg.Add("Text", Format("x{} y{} w110 Right", L.X + 100 + 6 + 120 + 18, y), "黑色容差：")
    edTol := dlg.Add("Edit", Format("x{} y{} w120", L.X + 100 + 6 + 120 + 18 + 110 + 6, y)
        , HasProp(cfg,"ColorTolBlack") ? cfg.ColorTolBlack : 16)

    y += 34
    cbCast := dlg.Add("CheckBox", Format("x{} y{} w180", L.X, y), "尊重施法锁")
    cbCast.Value := HasProp(cfg,"RespectCastLock") ? (cfg.RespectCastLock?1:0) : 1

    y += 34
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X, y), "切换键：")
    hkSwap := dlg.Add("Hotkey", Format("x{} y{} w160", L.X + 100 + 6, y), HasProp(cfg,"SwapKey") ? cfg.SwapKey : "")
    cbVerify := dlg.Add("CheckBox", Format("x{} y{} w120", L.X + 100 + 6 + 160 + 12, y), "验证切换")
    cbVerify.Value := HasProp(cfg,"VerifySwap") ? (cfg.VerifySwap?1:0) : 0

    y += 34
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X, y), "切换超时(ms)：")
    edTO := dlg.Add("Edit", Format("x{} y{} w120", L.X + 100 + 6, y), HasProp(cfg,"SwapTimeoutMs") ? cfg.SwapTimeoutMs : 800)
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X + 100 + 6 + 120 + 18, y), "重试次数：")
    edRetry := dlg.Add("Edit", Format("x{} y{} w120", L.X + 100 + 6 + 120 + 18 + 100 + 6, y)
        , HasProp(cfg,"SwapRetry") ? cfg.SwapRetry : 0)

    y += 34
    cbGates := dlg.Add("CheckBox", Format("x{} y{} w160", L.X, y), "启用跳轨")
    cbGates.Value := HasProp(cfg,"GatesEnabled") ? (cfg.GatesEnabled?1:0) : 0
    dlg.Add("Text", Format("x{} y{} w100 Right", L.X + 160 + 12, y), "跳轨冷却(ms)：")
    edGate := dlg.Add("Edit", Format("x{} y{} w120", L.X + 160 + 12 + 100 + 6, y)
        , HasProp(cfg,"GateCooldownMs") ? cfg.GateCooldownMs : 0)

    ; BlackGuard 分组
    gy := y + 46
    gb := dlg.Add("GroupBox", Format("x{} y{} w{} h150", L.X, gy, L.W), "黑框防抖")
    cbBG := dlg.Add("CheckBox", Format("x{} y{} w80", L.X + 12, gy + 26), "启用")
    cbBG.Value := (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"Enabled")) ? (cfg.BlackGuard.Enabled?1:0) : 1

    dlg.Add("Text", Format("x{} y{} w70 Right", L.X + 12 + 80 + 10, gy + 26), "采样数：")
    edSamp := dlg.Add("Edit", Format("x{} y{} w80", L.X + 12 + 80 + 10 + 70 + 6, gy + 26)
        , (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"SampleCount")) ? cfg.BlackGuard.SampleCount : 5)

    dlg.Add("Text", Format("x{} y{} w110 Right", L.X + 12 + 80 + 10 + 70 + 6 + 80 + 16, gy + 26), "黑像素阈值：")
    ratio := (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"BlackRatioThresh")) ? cfg.BlackGuard.BlackRatioThresh : 0.7
    edRatio := dlg.Add("Edit", Format("x{} y{} w100", L.X + 12 + 80 + 10 + 70 + 6 + 80 + 16 + 110 + 6, gy + 26)
        , Round(ratio, 2))

    dlg.Add("Text", Format("x{} y{} w100 Right", L.X + 12, gy + 26 + 40), "冷却(ms)：")
    edCool := dlg.Add("Edit", Format("x{} y{} w100", L.X + 12 + 100 + 6, gy + 26 + 40)
        , (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"CooldownMs")) ? cfg.BlackGuard.CooldownMs : 600)

    dlg.Add("Text", Format("x{} y{} w140 Right", L.X + 12 + 100 + 6 + 100 + 16, gy + 26 + 40), "黑窗最小延迟(ms)：")
    edMin := dlg.Add("Edit", Format("x{} y{} w100", L.X + 12 + 100 + 6 + 100 + 16 + 140 + 6, gy + 26 + 40)
        , (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"MinAfterSendMs")) ? cfg.BlackGuard.MinAfterSendMs : 60)

    dlg.Add("Text", Format("x{} y{} w140 Right", L.X + 12, gy + 26 + 40 + 34), "黑窗最大延迟(ms)：")
    edMax := dlg.Add("Edit", Format("x{} y{} w100", L.X + 12 + 140 + 6, gy + 26 + 40 + 34)
        , (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"MaxAfterSendMs")) ? cfg.BlackGuard.MaxAfterSendMs : 800)

    cbUniq := dlg.Add("CheckBox", Format("x{} y{}", L.X + 12 + 140 + 6 + 100 + 16, gy + 26 + 40 + 34), "需要唯一黑框")
    cbUniq.Value := (HasProp(cfg,"BlackGuard") && HasProp(cfg.BlackGuard,"UniqueRequired")) ? (cfg.BlackGuard.UniqueRequired?1:0) : 1

    ; 保存
    btnSave := dlg.Add("Button", Format("x{} y{} w120", L.X, gy + 150 + 16), "保存")
    btnSave.OnEvent("Click", Save)

    Save(*) {
        cfg.Enabled := cbEnable.Value ? 1 : 0
        if (ddDef.Value>=1 && ddDef.Value<=ids.Length)
            cfg.DefaultTrackId := Integer(ids[ddDef.Value])
        cfg.BusyWindowMs := (edBusy.Value!="") ? Integer(edBusy.Value) : 200
        cfg.ColorTolBlack := (edTol.Value!="") ? Integer(edTol.Value) : 16
        cfg.RespectCastLock := cbCast.Value ? 1 : 0
        cfg.SwapKey := Trim(hkSwap.Value)
        cfg.VerifySwap := cbVerify.Value ? 1 : 0
        cfg.SwapTimeoutMs := (edTO.Value!="") ? Integer(edTO.Value) : 800
        cfg.SwapRetry := (edRetry.Value!="") ? Integer(edRetry.Value) : 0
        cfg.GatesEnabled := cbGates.Value ? 1 : 0
        cfg.GateCooldownMs := (edGate.Value!="") ? Integer(edGate.Value) : 0

        if !HasProp(cfg,"BlackGuard")
            cfg.BlackGuard := {}
        bg := cfg.BlackGuard
        bg.Enabled := cbBG.Value ? 1 : 0
        bg.SampleCount := (edSamp.Value!="") ? Integer(edSamp.Value) : 5
        try bg.BlackRatioThresh := (edRatio.Value!="") ? (edRatio.Value+0) : 0.7
        bg.CooldownMs := (edCool.Value!="") ? Integer(edCool.Value) : 600
        bg.MinAfterSendMs := (edMin.Value!="") ? Integer(edMin.Value) : 60
        bg.MaxAfterSendMs := (edMax.Value!="") ? Integer(edMax.Value) : 800
        bg.UniqueRequired := cbUniq.Value ? 1 : 0
        cfg.BlackGuard := bg

        App["ProfileData"].Rotation := cfg
        Storage_SaveProfile(App["ProfileData"])
        Notify("常规设置已保存")
    }

    return { Save: (*) => 0 }
}