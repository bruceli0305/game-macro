#Requires AutoHotkey v2
#Include "..\UIX_Common.ahk"

PG_General_Build(ctx) {
    dlg := ctx.dlg
    rc := UIX_PageRect(dlg)

    ; 标题
    ttl := dlg.Add("Text", Format("x{} y{} w420", rc.X, rc.Y), "常规设置")
    ttl.SetFont("s12 Bold", "Segoe UI")

    y := rc.Y + 36
    lab1 := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, y), "轮询(ms)：")
    edPoll := dlg.Add("Edit", Format("x+6 y{} w120 Number Center", y-2), ctx.prof.PollIntervalMs)

    lab2 := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, y+34), "全局延迟(ms)：")
    edCd := dlg.Add("Edit", Format("x+6 y{} w120 Number Center", y+32), ctx.prof.SendCooldownMs)

    lab3 := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, y+68), "开始/停止：")
    hkStart := dlg.Add("Hotkey", Format("x+6 y{} w180", y+66), ctx.prof.StartHotkey)

    cbPick := dlg.Add("CheckBox", Format("x{} y{} w180", rc.X, y+110), "取色避让")
    cbPick.Value := ctx.prof.PickHoverEnabled ? 1 : 0

    lab4 := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, y+146), "Y偏移(px)：")
    edOffY := dlg.Add("Edit", Format("x+6 y{} w120 Number Center", y+144), ctx.prof.PickHoverOffsetY)

    lab5 := dlg.Add("Text", Format("x{} y{} w110 Right", rc.X, y+180), "等待(ms)：")
    edDw := dlg.Add("Edit", Format("x+6 y{} w120 Number Center", y+178), ctx.prof.PickHoverDwellMs)

    btnSave := dlg.Add("Button", Format("x{} y{} w120", rc.X, y+220), "保存")
    btnSave.OnEvent("Click", (*) => SaveGeneral())

    Reflow(ctx2 := 0) {
        r := UIX_PageRect(dlg)
        ttl.Move(r.X, r.Y, 420, 28)
        baseY := r.Y + 36
        lab1.Move(r.X, baseY, 110, 24)
        edPoll.Move(r.X + 110 + 6, baseY - 2, 120, 24)

        lab2.Move(r.X, baseY + 34, 110, 24)
        edCd.Move(r.X + 110 + 6, baseY + 32, 120, 24)

        lab3.Move(r.X, baseY + 68, 110, 24)
        hkStart.Move(r.X + 110 + 6, baseY + 66, 180, 24)

        cbPick.Move(r.X, baseY + 110, 180, 24)
        lab4.Move(r.X, baseY + 146, 110, 24)
        edOffY.Move(r.X + 110 + 6, baseY + 144, 120, 24)

        lab5.Move(r.X, baseY + 180, 110, 24)
        edDw.Move(r.X + 110 + 6, baseY + 178, 120, 24)

        btnSave.Move(r.X, baseY + 220, 120, 28)
    }

    SaveGeneral() {
        global App
        p := App["ProfileData"]
        p.PollIntervalMs := (edPoll.Value != "") ? Integer(edPoll.Value) : 25
        p.SendCooldownMs := (edCd.Value != "")   ? Integer(edCd.Value)   : 250
        p.StartHotkey := hkStart.Value
        p.PickHoverEnabled := cbPick.Value ? 1 : 0
        p.PickHoverOffsetY := (edOffY.Value != "") ? Integer(edOffY.Value) : -60
        p.PickHoverDwellMs := (edDw.Value != "")   ? Integer(edDw.Value)   : 120

        Hotkeys_BindStartHotkey(p.StartHotkey)
        Storage_SaveProfile(p)
        Notify("常规设置已保存")
    }

    Reflow()
    return { Reflow: Reflow, Save: (*) => SaveGeneral(), Destroy: (c*) => 0 }
}