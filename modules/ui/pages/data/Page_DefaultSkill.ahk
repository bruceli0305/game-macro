#Requires AutoHotkey v2
;Page_DefaultSkill.ahk
; 默认技能（嵌入页）
; 控件命名以 DS_ 前缀，避免与其他页面冲突
; 严格块结构写法

global UI_DS_ThreadIds := []  ; 下拉显示用的线程Id映射（索引->Id）

Page_DefaultSkill_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 分组
    UI.DS_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h150", rc.X, rc.Y, rc.W), T("ds.title", "默认技能（兜底）"))
    page.Controls.Push(UI.DS_GB)

    ; 行1：开关 + 技能 + 检测就绪
    x0 := rc.X + 12
    y0 := rc.Y + 26
    UI.DS_Enable := UI.Main.Add("CheckBox", Format("x{} y{} w120", x0, y0), T("ds.enable", "启用默认技能"))
    page.Controls.Push(UI.DS_Enable)

    UI.DS_L_Skill := UI.Main.Add("Text", Format("x{} y{} w60 Right", x0 + 160, y0 + 4), T("ds.skill", "技能："))
    page.Controls.Push(UI.DS_L_Skill)
    UI.DS_DdSkill := UI.Main.Add("DropDownList", "x+6 w260")
    page.Controls.Push(UI.DS_DdSkill)

    UI.DS_CbReady := UI.Main.Add("CheckBox", "x+12 w120", T("ds.ready", "检测就绪"))
    page.Controls.Push(UI.DS_CbReady)

    ; 行2：线程 + 冷却 + 预延时
    y1 := y0 + 36
    UI.DS_L_Thread := UI.Main.Add("Text", Format("x{} y{} w60 Right", x0, y1 + 4), T("ds.thread", "线程："))
    page.Controls.Push(UI.DS_L_Thread)
    UI.DS_DdThread := UI.Main.Add("DropDownList", "x+6 w200")
    page.Controls.Push(UI.DS_DdThread)

    UI.DS_L_Cd := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0 + 310, y1 + 4), T("ds.cooldown", "冷却(ms)："))
    page.Controls.Push(UI.DS_L_Cd)
    UI.DS_EdCd := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.DS_EdCd)

    UI.DS_L_Pre := UI.Main.Add("Text", "x+20 w100 Right", T("ds.predelay", "预延时(ms)："))
    page.Controls.Push(UI.DS_L_Pre)
    UI.DS_EdPre := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.DS_EdPre)

    ; 行3：按钮
    y2 := y1 + 40
    UI.DS_BtnSave := UI.Main.Add("Button", Format("x{} y{} w100 h28", x0, y2), T("btn.save", "保存"))
    page.Controls.Push(UI.DS_BtnSave)

    ; 事件
    UI.DS_BtnSave.OnEvent("Click", DefaultSkill_OnSave)

    ; 首次刷新
    DefaultSkill_Refresh_Strong()
}

Page_DefaultSkill_Layout(rc) {
    ; 简单布局：仅调整分组宽度；内部相对位移保持不变
    try {
        UI.DS_GB.Move(rc.X, rc.Y, rc.W)
    } catch {
    }
}

Page_DefaultSkill_OnEnter(*) {
    DefaultSkill_Refresh_Strong()
}

DefaultSkill_Refresh_Strong() {
    global App, UI, UI_DS_ThreadIds

    ; 确保 ProfileData 与默认结构
    try {
        if !IsSet(App) {
            App := Map()
        }
        if !App.Has("ProfileData") {
            prof := Core_DefaultProfileData()
            prof.Name := "Default"
            App["ProfileData"] := prof
        }
        if !HasProp(App["ProfileData"], "DefaultSkill") {
            App["ProfileData"].DefaultSkill := { Enabled:0, SkillIndex:0, CheckReady:1, ThreadId:1, CooldownMs:600, PreDelayMs:0, LastFire:0 }
        }
    } catch {
        return
    }

    ds := App["ProfileData"].DefaultSkill

    ; 技能列表
    names := []
    try {
        if HasProp(App["ProfileData"], "Skills") {
            for _, s in App["ProfileData"].Skills {
                names.Push(s.Name)
            }
        }
        UI.DS_DdSkill.Delete()
        if (names.Length > 0) {
            UI.DS_DdSkill.Add(names)
            val := ds.SkillIndex
            if (val < 1 or val > names.Length) {
                val := 1
            }
            UI.DS_DdSkill.Value := val
        } else {
            UI.DS_DdSkill.Add(["（无技能）"])
            UI.DS_DdSkill.Value := 1
        }
    } catch {
    }

    ; 线程列表
    UI_DS_ThreadIds := []
    thrNames := []
    try {
        if HasProp(App["ProfileData"], "Threads") {
            for _, t in App["ProfileData"].Threads {
                thrNames.Push(t.Name)
                UI_DS_ThreadIds.Push(t.Id)
            }
        }
        UI.DS_DdThread.Delete()
        if (thrNames.Length > 0) {
            UI.DS_DdThread.Add(thrNames)
            sel := 1
            i := 0
            for _, id in UI_DS_ThreadIds {
                i += 1
                if (id = (HasProp(ds,"ThreadId") ? ds.ThreadId : 1)) {
                    sel := i
                    break
                }
            }
            UI.DS_DdThread.Value := sel
        } else {
            UI.DS_DdThread.Add(["（无线程）"])
            UI.DS_DdThread.Value := 1
        }
    } catch {
    }

    ; 其它字段
    try {
        UI.DS_Enable.Value := (HasProp(ds, "Enabled") and ds.Enabled) ? 1 : 0
        UI.DS_CbReady.Value := (HasProp(ds, "CheckReady") and ds.CheckReady) ? 1 : 0
        UI.DS_EdCd.Value := HasProp(ds,"CooldownMs") ? ds.CooldownMs : 600
        UI.DS_EdPre.Value := HasProp(ds,"PreDelayMs") ? ds.PreDelayMs : 0
    } catch {
    }
}

DefaultSkill_OnSave(*) {
    global App, UI, UI_DS_ThreadIds
    if !IsSet(App) {
        return
    }

    ds := 0
    try {
        if !HasProp(App["ProfileData"], "DefaultSkill") {
            App["ProfileData"].DefaultSkill := { Enabled:0, SkillIndex:0, CheckReady:1, ThreadId:1, CooldownMs:600, PreDelayMs:0, LastFire:0 }
        }
        ds := App["ProfileData"].DefaultSkill
    } catch {
        return
    }

    ; 取值与容错
    try {
        ds.Enabled := UI.DS_Enable.Value ? 1 : 0

        skIdx := UI.DS_DdSkill.Value
        if (skIdx < 1) {
            skIdx := 1
        }
        ds.SkillIndex := skIdx

        ds.CheckReady := UI.DS_CbReady.Value ? 1 : 0

        tidx := UI.DS_DdThread.Value
        if (tidx < 1 or tidx > UI_DS_ThreadIds.Length) {
            tidx := 1
        }
        ds.ThreadId := (UI_DS_ThreadIds.Length > 0) ? UI_DS_ThreadIds[tidx] : 1

        cd := 600
        if (UI.DS_EdCd.Value != "") {
            cd := Integer(UI.DS_EdCd.Value)
        }
        if (cd < 0) {
            cd := 0
        }
        ds.CooldownMs := cd

        pre := 0
        if (UI.DS_EdPre.Value != "") {
            pre := Integer(UI.DS_EdPre.Value)
        }
        if (pre < 0) {
            pre := 0
        }
        ds.PreDelayMs := pre
    } catch {
        return
    }

    ; 保存
    try {
        Storage_SaveProfile(App["ProfileData"])
    } catch {
    }
    Notify(T("msg.defaultSaved","默认技能配置已保存"))
}