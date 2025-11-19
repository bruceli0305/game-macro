#Requires AutoHotkey v2
;modules\storage\profile\Save_Rules.ahk 保存 Rules 模块
SaveModule_Rules(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rules")
    tmp := FS_AtomicBegin(file)

    arr := []
    try {
        arr := profile["Rules"]
    } catch {
        arr := []
    }

    count := arr.Length
    IniWrite(count, tmp, "Rules", "Count")
    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Rule"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Rules", "NextId")

    i := 1
    while (i <= count) {
        r := arr[i]
        rid := 0
        try {
            rid := r.Id
        } catch {
            rid := 0
        }
        if (rid <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_RULE, r)
            rid := r.Id
        }

        IniWrite(rid, tmp, "Rules", "Id." i)

        rSec := "Rule." rid
        IniWrite(r.Has("Name") ? r["Name"] : "Rule", tmp, rSec, "Name")
        IniWrite(r.Has("Enabled") ? r["Enabled"] : 1, tmp, rSec, "Enabled")
        IniWrite(r.Has("Logic") ? r["Logic"] : "AND", tmp, rSec, "Logic")
        IniWrite(r.Has("CooldownMs") ? r["CooldownMs"] : 500, tmp, rSec, "CooldownMs")
        IniWrite(r.Has("Priority") ? r["Priority"] : i, tmp, rSec, "Priority")
        IniWrite(r.Has("ActionGapMs") ? r["ActionGapMs"] : 60, tmp, rSec, "ActionGapMs")
        IniWrite(r.Has("ThreadId") ? r["ThreadId"] : 1, tmp, rSec, "ThreadId")
        IniWrite(r.Has("SessionTimeoutMs") ? r["SessionTimeoutMs"] : 0, tmp, rSec, "SessionTimeoutMs")
        IniWrite(r.Has("AbortCooldownMs") ? r["AbortCooldownMs"] : 0, tmp, rSec, "AbortCooldownMs")

        ; Conditions
        conds := []
        try {
            conds := r["Conditions"]
        } catch {
            conds := []
        }
        IniWrite(conds.Length, tmp, rSec, "CondCount")
        j := 1
        while (j <= conds.Length) {
            c := conds[j]
            cSec := "Rule." rid ".Cond." j

            kind := ""
            try {
                kind := c["Kind"]
            } catch{
                kind := ""
            } 
            

            if (StrUpper(kind) = "COUNTER") {
                IniWrite("Counter", tmp, cSec, "Kind")
                IniWrite(c.Has("SkillId") ? c["SkillId"] : 0, tmp, cSec, "SkillId")
                IniWrite(c.Has("Cmp") ? c["Cmp"] : "GE", tmp, cSec, "Cmp")
                IniWrite(c.Has("Value") ? c["Value"] : 1, tmp, cSec, "Value")
                IniWrite(c.Has("ResetOnTrigger") ? c["ResetOnTrigger"] : 0, tmp, cSec, "ResetOnTrigger")
            } else {
                IniWrite("Pixel", tmp, cSec, "Kind")
                IniWrite(c.Has("RefType") ? c["RefType"] : "Skill", tmp, cSec, "RefType")
                IniWrite(c.Has("RefId") ? c["RefId"] : 0, tmp, cSec, "RefId")
                IniWrite(c.Has("Op") ? c["Op"] : "EQ", tmp, cSec, "Op")
                IniWrite(c.Has("Color") ? c["Color"] : "0x000000", tmp, cSec, "Color")
                IniWrite(c.Has("Tol") ? c["Tol"] : 16, tmp, cSec, "Tol")
            }
            j := j + 1
        }

        ; Actions
        acts := []
        try {
            acts := r["Actions"]
        } catch {
            acts := []
        }
        IniWrite(acts.Length, tmp, rSec, "ActCount")
        j := 1
        while (j <= acts.Length) {
            a := acts[j]
            aSec := "Rule." rid ".Act." j
            IniWrite(a.Has("SkillId") ? a["SkillId"] : 0, tmp, aSec, "SkillId")
            IniWrite(a.Has("DelayMs") ? a["DelayMs"] : 0, tmp, aSec, "DelayMs")
            IniWrite(a.Has("HoldMs") ? a["HoldMs"] : -1, tmp, aSec, "HoldMs")
            IniWrite(a.Has("RequireReady") ? a["RequireReady"] : 0, tmp, aSec, "RequireReady")
            IniWrite(a.Has("Verify") ? a["Verify"] : 0, tmp, aSec, "Verify")
            IniWrite(a.Has("VerifyTimeoutMs") ? a["VerifyTimeoutMs"] : 600, tmp, aSec, "VerifyTimeoutMs")
            IniWrite(a.Has("Retry") ? a["Retry"] : 0, tmp, aSec, "Retry")
            IniWrite(a.Has("RetryGapMs") ? a["RetryGapMs"] : 150, tmp, aSec, "RetryGapMs")
            j := j + 1
        }
        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Rules(profileName, &profile) {
    file := FS_ModulePath(profileName, "rules")
    if !FileExist(file) {
        return
    }
    arr := []
    count := Integer(IniRead(file, "Rules", "Count", 0))
    nextId := Integer(IniRead(file, "Rules", "NextId", 1))

    i := 1
    while (i <= count) {
        rid := Integer(IniRead(file, "Rules", "Id." i, 0))
        if (rid <= 0) {
            i := i + 1
            continue
        }

        rSec := "Rule." rid
        r := PM_NewRule()
        r["Id"] := rid
        r["Name"] := IniRead(file, rSec, "Name", "Rule")
        r["Enabled"] := Integer(IniRead(file, rSec, "Enabled", 1))
        r["Logic"] := IniRead(file, rSec, "Logic", "AND")
        r["CooldownMs"] := Integer(IniRead(file, rSec, "CooldownMs", 500))
        r["Priority"] := Integer(IniRead(file, rSec, "Priority", i))
        r["ActionGapMs"] := Integer(IniRead(file, rSec, "ActionGapMs", 60))
        r["ThreadId"] := Integer(IniRead(file, rSec, "ThreadId", 1))
        r["SessionTimeoutMs"] := Integer(IniRead(file, rSec, "SessionTimeoutMs", 0))
        r["AbortCooldownMs"] := Integer(IniRead(file, rSec, "AbortCooldownMs", 0))

        ; Conditions
        cCount := Integer(IniRead(file, rSec, "CondCount", 0))
        conds := []
        j := 1
        while (j <= cCount) {
            cSec := "Rule." rid ".Cond." j
            kind := IniRead(file, cSec, "Kind", "Pixel")
            if (StrUpper(kind) = "COUNTER") {
                c := PM_NewCondCounter()
                c["SkillId"] := Integer(IniRead(file, cSec, "SkillId", 0))
                c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                c["Value"] := Integer(IniRead(file, cSec, "Value", 1))
                c["ResetOnTrigger"] := Integer(IniRead(file, cSec, "ResetOnTrigger", 0))
                conds.Push(c)
            } else {
                c := PM_NewCondPixel()
                c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                c["Op"] := IniRead(file, cSec, "Op", "EQ")
                c["Color"] := IniRead(file, cSec, "Color", "0x000000")
                c["Tol"] := Integer(IniRead(file, cSec, "Tol", 16))
                conds.Push(c)
            }
            j := j + 1
        }
        r["Conditions"] := conds

        ; Actions
        aCount := Integer(IniRead(file, rSec, "ActCount", 0))
        acts := []
        j := 1
        while (j <= aCount) {
            aSec := "Rule." rid ".Act." j
            a := PM_NewAction()
            a["SkillId"] := Integer(IniRead(file, aSec, "SkillId", 0))
            a["DelayMs"] := Integer(IniRead(file, aSec, "DelayMs", 0))
            a["HoldMs"] := Integer(IniRead(file, aSec, "HoldMs", -1))
            a["RequireReady"] := Integer(IniRead(file, aSec, "RequireReady", 0))
            a["Verify"] := Integer(IniRead(file, aSec, "Verify", 0))
            a["VerifyTimeoutMs"] := Integer(IniRead(file, aSec, "VerifyTimeoutMs", 600))
            a["Retry"] := Integer(IniRead(file, aSec, "Retry", 0))
            a["RetryGapMs"] := Integer(IniRead(file, aSec, "RetryGapMs", 150))
            acts.Push(a)
            j := j + 1
        }
        r["Actions"] := acts

        arr.Push(r)
        i := i + 1
    }

    profile["Rules"] := arr
    try {
        if (nextId > profile["Meta"]["NextId"]["Rule"]) {
            profile["Meta"]["NextId"]["Rule"] := nextId
        }
    } catch {
    }
}