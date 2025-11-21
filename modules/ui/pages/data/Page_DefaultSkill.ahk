#Requires AutoHotkey v2
; Page_DefaultSkill.ahk
; 默认技能（嵌入页）
; 控件命名以 DS_ 前缀，避免与其他页面冲突
; 按新存储方案：保存到 general.ini 的 [Default] 使用 SkillId，而非 SkillIndex
; 严格块结构写法

global UI_DS_ThreadIds := []  ; 下拉显示用的线程Id映射（索引->Id）

Page_DefaultSkill_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 分组
    UI.DS_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h260", rc.X, rc.Y, rc.W), T("ds.title", "默认技能（兜底）"))
    page.Controls.Push(UI.DS_GB)

    ; 行1：启用默认技能（独立显示）
    x0 := rc.X + 12
    y0 := rc.Y + 26
    UI.DS_Enable := UI.Main.Add("CheckBox", Format("x{} y{} w160", x0, y0), T("ds.enable", "启用默认技能"))
    page.Controls.Push(UI.DS_Enable)

    ; 行2：技能 + 检测就绪
    y1 := y0 + 36
    UI.DS_L_Skill := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y1 + 4), T("ds.skill", "技能："))
    page.Controls.Push(UI.DS_L_Skill)
    UI.DS_DdSkill := UI.Main.Add("DropDownList", "x+10 w160")
    page.Controls.Push(UI.DS_DdSkill)

    UI.DS_CbReady := UI.Main.Add("CheckBox", "x+20 w160", T("ds.ready", "检测就绪"))
    page.Controls.Push(UI.DS_CbReady)

    ; 行3：线程
    y2 := y1 + 36
    UI.DS_L_Thread := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y2 + 4), T("ds.thread", "线程："))
    page.Controls.Push(UI.DS_L_Thread)
    UI.DS_DdThread := UI.Main.Add("DropDownList", "x+10 w160")
    page.Controls.Push(UI.DS_DdThread)

    ; 行4：冷却
    y3 := y2 + 36
    UI.DS_L_Cd := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y3 + 4), T("ds.cooldown", "冷却(ms)："))
    page.Controls.Push(UI.DS_L_Cd)
    UI.DS_EdCd := UI.Main.Add("Edit", "x+10 w160 Number")
    page.Controls.Push(UI.DS_EdCd)

    ; 行5：预延时
    y4 := y3 + 36
    UI.DS_L_Pre := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y4 + 4), T("ds.predelay", "预延时(ms)："))
    page.Controls.Push(UI.DS_L_Pre)
    UI.DS_EdPre := UI.Main.Add("Edit", "x+10 w160 Number")
    page.Controls.Push(UI.DS_EdPre)

    ; 行6：保存按钮
    y5 := y4 + 40
    UI.DS_BtnSave := UI.Main.Add("Button", Format("x{} y{} w96 h30", x0, y5), T("btn.save", "保存"))
    page.Controls.Push(UI.DS_BtnSave)

    ; 事件
    UI.DS_BtnSave.OnEvent("Click", DefaultSkill_OnSave)

    ; 首次刷新
    DefaultSkill_Refresh_Strong()
}

Page_DefaultSkill_Layout(rc) {
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

    ; 技能列表（运行时：索引模型）
    names := []
    try {
        if HasProp(App["ProfileData"], "Skills") {
            for _, s in App["ProfileData"].Skills {
                nm := ""
                try {
                    nm := OM_Get(s, "Name", "")
                } catch {
                    nm := ""
                }
                names.Push(nm)
            }
        }
        try {
            UI.DS_DdSkill.Delete()
        } catch {
        }
        if (names.Length > 0) {
            try {
                UI.DS_DdSkill.Add(names)
            } catch {
            }
            val := 1
            try {
                val := (HasProp(ds, "SkillIndex") ? ds.SkillIndex : 1)
            } catch {
                val := 1
            }
            if (val < 1) {
                val := 1
            }
            if (val > names.Length) {
                val := names.Length
            }
            try {
                UI.DS_DdSkill.Value := val
            } catch {
            }
        } else {
            try {
                UI.DS_DdSkill.Add(["（无技能）"])
                UI.DS_DdSkill.Value := 1
            } catch {
            }
        }
    } catch {
    }

    ; 线程列表（运行时：线程 Id 固定）
    UI_DS_ThreadIds := []
    thrNames := []
    try {
        if HasProp(App["ProfileData"], "Threads") {
            for _, t in App["ProfileData"].Threads {
                tname := ""
                tid := 0
                try {
                    tname := OM_Get(t, "Name", "")
                } catch {
                    tname := ""
                }
                try {
                    tid := OM_Get(t, "Id", 1)
                } catch {
                    tid := 1
                }
                thrNames.Push(tname)
                UI_DS_ThreadIds.Push(tid)
            }
        }
        try {
            UI.DS_DdThread.Delete()
        } catch {
        }
        if (thrNames.Length > 0) {
            try {
                UI.DS_DdThread.Add(thrNames)
            } catch {
            }
            sel := 1
            wantId := 1
            try {
                wantId := (HasProp(ds, "ThreadId") ? ds.ThreadId : 1)
            } catch {
                wantId := 1
            }
            i := 1
            while (i <= UI_DS_ThreadIds.Length) {
                id := 0
                try {
                    id := UI_DS_ThreadIds[i]
                } catch {
                    id := 0
                }
                if (id = wantId) {
                    sel := i
                    break
                }
                i := i + 1
            }
            try {
                UI.DS_DdThread.Value := sel
            } catch {
            }
        } else {
            try {
                UI.DS_DdThread.Add(["（无线程）"])
                UI.DS_DdThread.Value := 1
            } catch {
            }
        }
    } catch {
    }

    ; 其它字段
    try {
        UI.DS_Enable.Value := (HasProp(ds, "Enabled") and ds.Enabled) ? 1 : 0
    } catch {
    }
    try {
        UI.DS_CbReady.Value := (HasProp(ds, "CheckReady") and ds.CheckReady) ? 1 : 0
    } catch {
    }
    try {
        UI.DS_EdCd.Value := HasProp(ds, "CooldownMs") ? ds.CooldownMs : 600
    } catch {
    }
    try {
        UI.DS_EdPre.Value := HasProp(ds, "PreDelayMs") ? ds.PreDelayMs : 0
    } catch {
    }
}

DefaultSkill_OnSave(*) {
    global App, UI, UI_DS_ThreadIds
    if !IsSet(App) {
        return
    }

    ; 读取 UI 值
    enabled := 0
    try {
        enabled := UI.DS_Enable.Value ? 1 : 0
    } catch {
        enabled := 0
    }

    skIdx := 1
    try {
        skIdx := UI.DS_DdSkill.Value
    } catch {
        skIdx := 1
    }
    if (skIdx < 1) {
        skIdx := 1
    }

    chkReady := 1
    try {
        chkReady := UI.DS_CbReady.Value ? 1 : 0
    } catch {
        chkReady := 1
    }

    tidx := 1
    try {
        tidx := UI.DS_DdThread.Value
    } catch {
        tidx := 1
    }
    if (tidx < 1) {
        tidx := 1
    }

    cd := 600
    try {
        if (UI.DS_EdCd.Value != "") {
            cd := Integer(UI.DS_EdCd.Value)
        }
    } catch {
        cd := 600
    }
    if (cd < 0) {
        cd := 0
    }

    pre := 0
    try {
        if (UI.DS_EdPre.Value != "") {
            pre := Integer(UI.DS_EdPre.Value)
        }
    } catch {
        pre := 0
    }
    if (pre < 0) {
        pre := 0
    }

    ; 将 SkillIndex 映射为稳定 SkillId
    skillId := 0
    try {
        if (HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
            if (skIdx >= 1 && skIdx <= App["ProfileData"].Skills.Length) {
                s := App["ProfileData"].Skills[skIdx]
                try {
                    skillId := OM_Get(s, "Id", 0)
                } catch {
                    skillId := 0
                }
            }
        }
    } catch {
        skillId := 0
    }

    ; 将线程下拉索引映射为 ThreadId
    threadId := 1
    try {
        if (UI_DS_ThreadIds.Length >= tidx && tidx >= 1) {
            threadId := UI_DS_ThreadIds[tidx]
        } else {
            threadId := 1
        }
    } catch {
        threadId := 1
    }

    ; 获取当前 Profile 名称
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox T("msg.noProfile","未选择配置")
        return
    }

    ; 读取文件夹模型 → 写 DefaultSkill（使用 SkillId）→ 保存 general.ini → 重载规范化 → 回填
    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch {
        MsgBox T("msg.loadFail","加载配置失败")
        return
    }

    ; 写入 General.DefaultSkill（Id 模型）
    try {
        if !(p.Has("General")) {
            p["General"] := Map()
        }
        g := p["General"]
        if !(g.Has("DefaultSkill")) {
            g["DefaultSkill"] := Map()
        }
        ds := g["DefaultSkill"]
        ds["Enabled"]    := enabled
        ds["SkillId"]    := skillId
        ds["CheckReady"] := chkReady
        ds["ThreadId"]   := threadId
        ds["CooldownMs"] := cd
        ds["PreDelayMs"] := pre
        g["DefaultSkill"] := ds
        p["General"] := g
    } catch {
    }

    ok := false
    try {
        SaveModule_General(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        MsgBox T("msg.saveFail","保存失败")
        return
    }

    ; 重载 → 规范化（运行时里 SkillIndex 会由 SkillId 映射回索引）
    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
    } catch {
        MsgBox T("msg.reloadFail","保存成功，但重新加载失败，请切换配置后重试。")
        return
    }

    ; 回填 UI
    DefaultSkill_Refresh_Strong()
    Notify(T("msg.defaultSaved","默认技能配置已保存"))
}