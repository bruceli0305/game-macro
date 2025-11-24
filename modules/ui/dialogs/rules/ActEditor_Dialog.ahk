#Requires AutoHotkey v2
; ActEditor_Dialog.ahk
; 动作编辑器
; 导出：ActEditor_Open(act, idx := 0, onSaved := 0)

#Include "Rules_UI_Common.ahk"

ActEditor_Open(act, idx := 0, onSaved := 0) {
    global App
    if !IsObject(act) {
        act := {}
    }
    if !HasProp(act, "SkillIndex") {
        act.SkillIndex := 1
    }
    if !HasProp(act, "DelayMs") {
        act.DelayMs := 0
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, "编辑动作")
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12
    dlg.MarginY := 10

    dlg.Add("Text", "w90 Right", "技能：")
    ddS := dlg.Add("DropDownList", "x+6 w240")
    cnt := RE_Rules_FillSkills(ddS)
    defIdx := RE_Rules_ClampIndex(act.SkillIndex, Max(cnt, 1))
    try ddS.Value := (defIdx > 0 ? defIdx : 1)

    dlg.Add("Text", "xm w90 Right", "延时(ms)：")
    edD := dlg.Add("Edit", "x+6 w240 Number", act.DelayMs)

    dlg.Add("Text", "xm w90 Right", "按住(ms)：")
    edHold := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "HoldMs") ? act.HoldMs : -1)

    cbReady := dlg.Add("CheckBox", "xm y+8", "需就绪")
    try cbReady.Value := HasProp(act, "RequireReady") ? (act.RequireReady ? 1 : 0) : 0

    cbVerify := dlg.Add("CheckBox", "xm y+8", "验证")
    try cbVerify.Value := HasProp(act, "Verify") ? (act.Verify ? 1 : 0) : 0

    dlg.Add("Text", "xm w110 Right", "验证超时(ms)：")
    edVto := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "VerifyTimeoutMs") ? act.VerifyTimeoutMs : 600)

    dlg.Add("Text", "xm w110 Right", "重试次数：")
    edRetry := dlg.Add("Edit", "x+6 w240 Number", HasProp(act, "Retry") ? act.Retry : 0)

    dlg.Add("Text", "xm w110 Right", "重试间隔(ms)：")
    edRgap := dlg.Add("Edit", "x+6 w120 Number", HasProp(act, "RetryGapMs") ? act.RetryGapMs : 150)

    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    OnSave(*) {
        idxS := 1
        try idxS := (ddS.Value ? ddS.Value : 1)
        d := 0
        try d := (edD.Value != "") ? Integer(edD.Value) : 0
        h := -1
        try h := (edHold.Value != "") ? Integer(edHold.Value) : -1
        rr := 0
        try rr := cbReady.Value ? 1 : 0
        vf := 0
        try vf := cbVerify.Value ? 1 : 0
        vto := 600
        try vto := (edVto.Value != "") ? Integer(edVto.Value) : 600
        rt := 0
        try rt := (edRetry.Value != "") ? Integer(edRetry.Value) : 0
        rg := 150
        try rg := (edRgap.Value != "") ? Integer(edRgap.Value) : 150

        newA := { SkillIndex: idxS, DelayMs: d, HoldMs: h, RequireReady: rr, Verify: vf, VerifyTimeoutMs: vto, Retry: rt, RetryGapMs: rg }
        if onSaved {
            try onSaved(newA, idx)
        }
        try dlg.Destroy()
        Notify("已保存动作")
    }
}