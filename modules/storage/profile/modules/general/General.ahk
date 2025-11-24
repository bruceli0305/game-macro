#Requires AutoHotkey v2
;modules\storage\profile\modules\general\General.ahk 保存 General 模块
; 依赖：OM_Get（modules\util\Obj.ahk）

SaveModule_General(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }
    file := FS_ModulePath(name, "general")
    tmp := FS_AtomicBegin(file)

    ; General
    g := Map()
    try {
        g := profile["General"]
    } catch {
        g := Map()
    }

    ; 顶层 General
    try {
        IniWrite(OM_Get(g, "StartHotkey", "F9"),          tmp, "General", "StartHotkey")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "PollIntervalMs", 25),         tmp, "General", "PollIntervalMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "SendCooldownMs", 250),        tmp, "General", "SendCooldownMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "PickHoverEnabled", 1),        tmp, "General", "PickHoverEnabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "PickHoverOffsetY", -60),      tmp, "General", "PickHoverOffsetY")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "PickHoverDwellMs", 120),      tmp, "General", "PickHoverDwellMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "PickConfirmKey", "LButton"),  tmp, "General", "PickConfirmKey")
    } catch {
    }
    ; CastBar 配置
    try {
        IniWrite(OM_Get(g, "CastBarEnabled", 0), tmp, "General", "CastBarEnabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarX", 0), tmp, "General", "CastBarX")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarY", 0), tmp, "General", "CastBarY")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarColor", "0x000000"), tmp, "General", "CastBarColor")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarTol", 10), tmp, "General", "CastBarTol")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarDebugLog", 0), tmp, "General", "CastBarDebugLog")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastBarIgnoreActionDelay", 0), tmp, "General", "CastBarIgnoreActionDelay")
    } catch {
    }
    ; 调试窗口配置 CastDebug
    try {
        IniWrite(OM_Get(g, "CastDebugHotkey", ""), tmp, "General", "CastDebugHotkey")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastDebugTopmost", 1), tmp, "General", "CastDebugTopmost")
    } catch {
    }
    try {
        IniWrite(OM_Get(g, "CastDebugAlpha", 230), tmp, "General", "CastDebugAlpha")
    } catch {
    }
    ; DefaultSkill（使用 SkillId）
    ds := Map()
    try {
        ds := g["DefaultSkill"]
    } catch {
        ds := Map()
    }
    try {
        IniWrite(OM_Get(ds, "Enabled", 0),        tmp, "Default", "Enabled")
    } catch {
    }
    try {
        IniWrite(OM_Get(ds, "SkillId", 0),        tmp, "Default", "SkillId")
    } catch {
    }
    try {
        IniWrite(OM_Get(ds, "CheckReady", 1),     tmp, "Default", "CheckReady")
    } catch {
    }
    try {
        IniWrite(OM_Get(ds, "ThreadId", 1),       tmp, "Default", "ThreadId")
    } catch {
    }
    try {
        IniWrite(OM_Get(ds, "CooldownMs", 600),   tmp, "Default", "CooldownMs")
    } catch {
    }
    try {
        IniWrite(OM_Get(ds, "PreDelayMs", 0),     tmp, "Default", "PreDelayMs")
    } catch {
    }

    ; Threads（Count + Id.i + Thread.<id>.Name）
    ths := []
    try {
        ths := g["Threads"]
    } catch {
        ths := []
    }
    cnt := 0
    try {
        cnt := ths.Length
    } catch {
        cnt := 0
    }
    try {
        IniWrite(cnt, tmp, "Threads", "Count")
    } catch {
    }

    i := 1
    while (i <= cnt) {
        t := 0
        try {
            t := ths[i]
        } catch {
            t := 0
        }
        tid := i
        tname := "线程" i
        if (IsObject(t)) {
            try {
                tid := OM_Get(t, "Id", i)
            } catch {
                tid := i
            }
            try {
                tname := OM_Get(t, "Name", "线程" tid)
            } catch {
                tname := "线程" tid
            }
        }
        try {
            IniWrite(tid,   tmp, "Threads", "Id." i)
        } catch {
        }
        try {
            IniWrite(tname, tmp, "Thread." tid, "Name")
        } catch {
        }
        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_General(profileName, profile) {
    file := FS_ModulePath(profileName, "general")
    if !FileExist(file) {
        return
    }

    g := Map()
    try {
        g := profile["General"]
    } catch {
        g := Map()
    }

    ; General 顶层
    try {
        g["StartHotkey"] := IniRead(file, "General", "StartHotkey", OM_Get(g, "StartHotkey", "F9"))
    } catch {
    }
    try {
        g["PollIntervalMs"] := Integer(IniRead(file, "General", "PollIntervalMs", OM_Get(g, "PollIntervalMs", 25)))
    } catch {
    }
    try {
        g["SendCooldownMs"] := Integer(IniRead(file, "General", "SendCooldownMs", OM_Get(g, "SendCooldownMs", 250)))
    } catch {
    }
    try {
        g["PickHoverEnabled"] := Integer(IniRead(file, "General", "PickHoverEnabled", OM_Get(g, "PickHoverEnabled", 1)))
    } catch {
    }
    try {
        g["PickHoverOffsetY"] := Integer(IniRead(file, "General", "PickHoverOffsetY", OM_Get(g, "PickHoverOffsetY", -60)))
    } catch {
    }
    try {
        g["PickHoverDwellMs"] := Integer(IniRead(file, "General", "PickHoverDwellMs", OM_Get(g, "PickHoverDwellMs", 120)))
    } catch {
    }
    try {
        g["PickConfirmKey"] := IniRead(file, "General", "PickConfirmKey", OM_Get(g, "PickConfirmKey", "LButton"))
    } catch {
    }
    ; CastBar 配置
    try {
        g["CastBarEnabled"] := Integer(IniRead(file, "General", "CastBarEnabled", OM_Get(g, "CastBarEnabled", 0)))
    } catch {
    }
    try {
        g["CastBarX"] := Integer(IniRead(file, "General", "CastBarX", OM_Get(g, "CastBarX", 0)))
    } catch {
    }
    try {
        g["CastBarY"] := Integer(IniRead(file, "General", "CastBarY", OM_Get(g, "CastBarY", 0)))
    } catch {
    }
    try {
        g["CastBarColor"] := IniRead(file, "General", "CastBarColor", OM_Get(g, "CastBarColor", "0x000000"))
    } catch {
    }
    try {
        g["CastBarTol"] := Integer(IniRead(file, "General", "CastBarTol", OM_Get(g, "CastBarTol", 10)))
    } catch {
    }
    try {
        g["CastBarDebugLog"] := Integer(IniRead(file, "General", "CastBarDebugLog", OM_Get(g, "CastBarDebugLog", 0)))
    } catch {
    }
    try {
        g["CastBarIgnoreActionDelay"] := Integer(IniRead(file, "General", "CastBarIgnoreActionDelay", OM_Get(g, "CastBarIgnoreActionDelay", 0)))
    } catch {
    }

    ; 调试窗口配置 CastDebug
    try {
        g["CastDebugHotkey"] := IniRead(file, "General", "CastDebugHotkey", OM_Get(g, "CastDebugHotkey", ""))
    } catch {
    }
    try {
        g["CastDebugTopmost"] := Integer(IniRead(file, "General", "CastDebugTopmost", OM_Get(g, "CastDebugTopmost", 1)))
    } catch {
    }
    try {
        g["CastDebugAlpha"] := Integer(IniRead(file, "General", "CastDebugAlpha", OM_Get(g, "CastDebugAlpha", 230)))
    } catch {
    }
    ; DefaultSkill（SkillId）
    ds := Map()
    try {
        ds := g["DefaultSkill"]
    } catch {
        ds := Map()
    }
    try {
        ds["Enabled"] := Integer(IniRead(file, "Default", "Enabled", OM_Get(ds, "Enabled", 0)))
    } catch {
    }
    try {
        ds["SkillId"] := Integer(IniRead(file, "Default", "SkillId", OM_Get(ds, "SkillId", 0)))
    } catch {
    }
    try {
        ds["CheckReady"] := Integer(IniRead(file, "Default", "CheckReady", OM_Get(ds, "CheckReady", 1)))
    } catch {
    }
    try {
        ds["ThreadId"] := Integer(IniRead(file, "Default", "ThreadId", OM_Get(ds, "ThreadId", 1)))
    } catch {
    }
    try {
        ds["CooldownMs"] := Integer(IniRead(file, "Default", "CooldownMs", OM_Get(ds, "CooldownMs", 600)))
    } catch {
    }
    try {
        ds["PreDelayMs"] := Integer(IniRead(file, "Default", "PreDelayMs", OM_Get(ds, "PreDelayMs", 0)))
    } catch {
    }
    try {
        g["DefaultSkill"] := ds
    } catch {
    }

    ; Threads
    cnt := 0
    try {
        cnt := Integer(IniRead(file, "Threads", "Count", 0))
    } catch {
        cnt := 0
    }
    ths := []
    i := 1
    while (i <= cnt) {
        tid := 0
        tname := ""
        try {
            tid := Integer(IniRead(file, "Threads", "Id." i, i))
        } catch {
            tid := i
        }
        try {
            tname := IniRead(file, "Thread." tid, "Name", "线程" tid)
        } catch {
            tname := "线程" tid
        }
        try {
            ths.Push(Map("Id", tid, "Name", tname))
        } catch {
        }
        i := i + 1
    }
    if (ths.Length > 0) {
        try {
            g["Threads"] := ths
        } catch {
        }
    }
    try {
        profile["General"] := g
    } catch {
    }
}