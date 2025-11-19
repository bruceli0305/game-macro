#Requires AutoHotkey v2
;modules\storage\profile\Save_Buffs.ahk 保存 Buffs 模块
SaveModule_Buffs(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "buffs")
    tmp := FS_AtomicBegin(file)

    arr := []
    try {
        arr := profile["Buffs"]
    } catch {
        arr := []
    }

    count := arr.Length
    IniWrite(count, tmp, "Buffs", "Count")

    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Buff"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Buffs", "NextId")

    i := 1
    while (i <= count) {
        b := arr[i]
        bid := 0
        try {
            bid := b.Id
        } catch {
            bid := 0
        }
        if (bid <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_BUFF, b)
            bid := b.Id
        }

        IniWrite(bid, tmp, "Buffs", "Id." i)

        bSec := "Buff." bid
        IniWrite(b.Has("Name") ? b["Name"] : "Buff", tmp, bSec, "Name")
        IniWrite(b.Has("Enabled") ? b["Enabled"] : 1, tmp, bSec, "Enabled")
        IniWrite(b.Has("DurationMs") ? b["DurationMs"] : 0, tmp, bSec, "DurationMs")
        IniWrite(b.Has("RefreshBeforeMs") ? b["RefreshBeforeMs"] : 0, tmp, bSec, "RefreshBeforeMs")
        IniWrite(b.Has("CheckReady") ? b["CheckReady"] : 1, tmp, bSec, "CheckReady")
        IniWrite(b.Has("ThreadId") ? b["ThreadId"] : 1, tmp, bSec, "ThreadId")

        skills := []
        try {
            skills := b["Skills"]
        } catch {
            skills := []
        }
        IniWrite(skills.Length, tmp, bSec, "SkillsCount")

        j := 1
        while (j <= skills.Length) {
            skId := 0
            try {
                skId := skills[j]
            } catch {
                skId := 0
            }
            IniWrite(skId, tmp, "Buff." bid ".Skill." j, "SkillId")
            j := j + 1
        }

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Buffs(profileName, profile) {
    file := FS_ModulePath(profileName, "buffs")
    if !FileExist(file) {
        return
    }
    count := Integer(IniRead(file, "Buffs", "Count", 0))
    nextId := Integer(IniRead(file, "Buffs", "NextId", 1))

    arr := []
    i := 1
    while (i <= count) {
        bid := Integer(IniRead(file, "Buffs", "Id." i, 0))
        if (bid <= 0) {
            i := i + 1
            continue
        }
        bSec := "Buff." bid

        b := PM_NewBuff()
        b["Id"] := bid
        b["Name"] := IniRead(file, bSec, "Name", "Buff")
        b["Enabled"] := Integer(IniRead(file, bSec, "Enabled", 1))
        b["DurationMs"] := Integer(IniRead(file, bSec, "DurationMs", 0))
        b["RefreshBeforeMs"] := Integer(IniRead(file, bSec, "RefreshBeforeMs", 0))
        b["CheckReady"] := Integer(IniRead(file, bSec, "CheckReady", 1))
        b["ThreadId"] := Integer(IniRead(file, bSec, "ThreadId", 1))

        sc := Integer(IniRead(file, bSec, "SkillsCount", 0))
        skills := []
        j := 1
        while (j <= sc) {
            skId := Integer(IniRead(file, "Buff." bid ".Skill." j, "SkillId", 0))
            skills.Push(skId)
            j := j + 1
        }
        b["Skills"] := skills

        arr.Push(b)
        i := i + 1
    }

    profile["Buffs"] := arr
    try {
        if (nextId > profile["Meta"]["NextId"]["Buff"]) {
            profile["Meta"]["NextId"]["Buff"] := nextId
        }
    } catch {
    }
}