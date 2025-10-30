#Requires AutoHotkey v2
; 默认技能配置对话（与原 GUI_Main 同名函数，保持兼容）

DefaultSkillEditor_Show() {
    global App
    ds := HasProp(App["ProfileData"], "DefaultSkill") ? App["ProfileData"].DefaultSkill : 0
    if !ds {
        App["ProfileData"].DefaultSkill := { Enabled:0, SkillIndex:0, CheckReady:1, ThreadId:1, CooldownMs:600, PreDelayMs:0, LastFire:0 }
        ds := App["ProfileData"].DefaultSkill
    }

    dlg := Gui(, T("dlg.defaultSkill","默认技能（兜底触发）"))
    dlg.SetFont("s10", "Segoe UI")
    dlg.MarginX := 12, dlg.MarginY := 10

    cbEn := dlg.Add("CheckBox", "xm w160", T("label.enableDefault","启用默认技能"))
    cbEn.Value := ds.Enabled ? 1 : 0

    dlg.Add("Text", "xm y+8 w70", T("label.skill","技能："))
    names := []
    for _, s in App["ProfileData"].Skills
        names.Push(s.Name)
    ddSkill := dlg.Add("DropDownList", "x+6 w260")
    if names.Length
        ddSkill.Add(names)
    ddSkill.Value := (ds.SkillIndex >= 1 && ds.SkillIndex <= names.Length) ? ds.SkillIndex : (names.Length ? 1 : 0)

    cbReady := dlg.Add("CheckBox", "xm y+8 w180", T("label.checkReady","检测就绪(像素)"))
    cbReady.Value := ds.CheckReady ? 1 : 0

    dlg.Add("Text", "xm y+8 w60", T("label.thread","线程："))
    ddThread := dlg.Add("DropDownList", "x+6 w200")
    threadIds := []
    tnames := []
    for _, t in App["ProfileData"].Threads {
        tnames.Push(t.Name)
        threadIds.Push(t.Id)
    }
    if tnames.Length
        ddThread.Add(tnames)
    sel := 1
    for i, id in threadIds
        if (id = (HasProp(ds,"ThreadId") ? ds.ThreadId : 1)) {
            sel := i
            break
        }
    ddThread.Value := sel

    dlg.Add("Text", "xm y+8 w80", T("label.cooldown","冷却(ms)："))
    edCd := dlg.Add("Edit", "x+6 w120 Number", HasProp(ds,"CooldownMs") ? ds.CooldownMs : 600)

    dlg.Add("Text", "x+20 w90", T("label.predelay","预延时(ms)："))
    edPre := dlg.Add("Edit", "x+6 w120 Number", HasProp(ds,"PreDelayMs") ? ds.PreDelayMs : 0)

    btnSave := dlg.Add("Button", "xm y+12 w100", T("btn.save","保存"))
    btnCancel := dlg.Add("Button", "x+8 w100", T("btn.cancel","取消"))
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    OnSave(*) {
        en  := cbEn.Value ? 1 : 0
        si  := ddSkill.Value ? ddSkill.Value : 0
        rdy := cbReady.Value ? 1 : 0
        tid := (ddThread.Value >= 1 && ddThread.Value <= threadIds.Length) ? threadIds[ddThread.Value] : 1
        cd  := (edCd.Value != "") ? Integer(edCd.Value) : 600
        pre := (edPre.Value != "") ? Integer(edPre.Value) : 0

        if (en = 1 && (si < 1 || si > App["ProfileData"].Skills.Length)) {
            MsgBox T("msg.chooseSkill","请先选择一个技能。")
            return
        }

        last := HasProp(ds, "LastFire") ? ds.LastFire : 0
        App["ProfileData"].DefaultSkill.Enabled := en
        App["ProfileData"].DefaultSkill.SkillIndex := si
        App["ProfileData"].DefaultSkill.CheckReady := rdy
        App["ProfileData"].DefaultSkill.ThreadId := tid
        App["ProfileData"].DefaultSkill.CooldownMs := cd
        App["ProfileData"].DefaultSkill.PreDelayMs := pre
        App["ProfileData"].DefaultSkill.LastFire := last

        Storage_SaveProfile(App["ProfileData"])
        dlg.Destroy()
        Notify(T("msg.defaultSaved","默认技能配置已保存"))
    }
}