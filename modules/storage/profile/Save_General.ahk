#Requires AutoHotkey v2
;modules\storage\profile\Save_General.ahk 保存 General 模块
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
    g := profile["General"]

    IniWrite(g.Has("StartHotkey") ? g["StartHotkey"] : "F9", tmp, "General", "StartHotkey")
    IniWrite(g.Has("PollIntervalMs") ? g["PollIntervalMs"] : 25, tmp, "General", "PollIntervalMs")
    IniWrite(g.Has("SendCooldownMs") ? g["SendCooldownMs"] : 250, tmp, "General", "SendCooldownMs")
    IniWrite(g.Has("PickHoverEnabled") ? g["PickHoverEnabled"] : 1, tmp, "General", "PickHoverEnabled")
    IniWrite(g.Has("PickHoverOffsetY") ? g["PickHoverOffsetY"] : -60, tmp, "General", "PickHoverOffsetY")
    IniWrite(g.Has("PickHoverDwellMs") ? g["PickHoverDwellMs"] : 120, tmp, "General", "PickHoverDwellMs")
    IniWrite(g.Has("PickConfirmKey") ? g["PickConfirmKey"] : "LButton", tmp, "General", "PickConfirmKey")

    ; DefaultSkill（使用 SkillId）
    ds := g["DefaultSkill"]
    IniWrite(ds.Has("Enabled") ? ds["Enabled"] : 0, tmp, "Default", "Enabled")
    IniWrite(ds.Has("SkillId") ? ds["SkillId"] : 0, tmp, "Default", "SkillId")
    IniWrite(ds.Has("CheckReady") ? ds["CheckReady"] : 1, tmp, "Default", "CheckReady")
    IniWrite(ds.Has("ThreadId") ? ds["ThreadId"] : 1, tmp, "Default", "ThreadId")
    IniWrite(ds.Has("CooldownMs") ? ds["CooldownMs"] : 600, tmp, "Default", "CooldownMs")
    IniWrite(ds.Has("PreDelayMs") ? ds["PreDelayMs"] : 0, tmp, "Default", "PreDelayMs")

    ; Threads
    ths := g["Threads"]
    IniWrite(ths.Length, tmp, "Threads", "Count")

    i := 1
    while (i <= ths.Length) {
        tid := 0
        tname := "线程" i
        try {
            tid := ths[i].Id
        } catch {
            tid := i
        }
        try {
            tname := ths[i].Name
        } catch {
            tname := "线程" i
        }
        IniWrite(tid, tmp, "Threads", "Id." i)
        IniWrite(tname, tmp, "Thread." tid, "Name")
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
    g := profile["General"]

    try {
        g["StartHotkey"] := IniRead(file, "General", "StartHotkey", g["StartHotkey"])
    } catch {
    }
    try {
        g["PollIntervalMs"] := Integer(IniRead(file, "General", "PollIntervalMs", g["PollIntervalMs"]))
    } catch {
    }
    try {
        g["SendCooldownMs"] := Integer(IniRead(file, "General", "SendCooldownMs", g["SendCooldownMs"]))
    } catch {
    }
    try {
        g["PickHoverEnabled"] := Integer(IniRead(file, "General", "PickHoverEnabled", g["PickHoverEnabled"]))
    } catch {
    }
    try {
        g["PickHoverOffsetY"] := Integer(IniRead(file, "General", "PickHoverOffsetY", g["PickHoverOffsetY"]))
    } catch {
    }
    try {
        g["PickHoverDwellMs"] := Integer(IniRead(file, "General", "PickHoverDwellMs", g["PickHoverDwellMs"]))
    } catch {
    }
    try {
        g["PickConfirmKey"] := IniRead(file, "General", "PickConfirmKey", g["PickConfirmKey"])
    } catch {
    }

    ds := g["DefaultSkill"]
    try {
        ds["Enabled"] := Integer(IniRead(file, "Default", "Enabled", ds["Enabled"]))
    } catch {
    }
    try {
        ds["SkillId"] := Integer(IniRead(file, "Default", "SkillId", ds["SkillId"]))
    } catch {
    }
    try {
        ds["CheckReady"] := Integer(IniRead(file, "Default", "CheckReady", ds["CheckReady"]))
    } catch {
    }
    try {
        ds["ThreadId"] := Integer(IniRead(file, "Default", "ThreadId", ds["ThreadId"]))
    } catch {
    }
    try {
        ds["CooldownMs"] := Integer(IniRead(file, "Default", "CooldownMs", ds["CooldownMs"]))
    } catch {
    }
    try {
        ds["PreDelayMs"] := Integer(IniRead(file, "Default", "PreDelayMs", ds["PreDelayMs"]))
    } catch {
    }

    cnt := Integer(IniRead(file, "Threads", "Count", 0))
    ths := []
    i := 1
    while (i <= cnt) {
        tid := Integer(IniRead(file, "Threads", "Id." i, i))
        tname := IniRead(file, "Thread." tid, "Name", "线程" tid)
        ths.Push(Map("Id", tid, "Name", tname))
        i := i + 1
    }
    if (ths.Length > 0) {
        g["Threads"] := ths
    }
    profile["General"] := g
}