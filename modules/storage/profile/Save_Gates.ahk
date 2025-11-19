#Requires AutoHotkey v2

SaveModule_Gates(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rotation_gates")
    tmp := FS_AtomicBegin(file)

    gates := []
    try {
        gates := profile["Rotation"]["Gates"]
    } catch {
        gates := []
    }

    count := gates.Length
    IniWrite(count, tmp, "Gates", "Count")

    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Gate"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Gates", "NextId")

    i := 1
    while (i <= count) {
        g := gates[i]
        gid := 0
        try {
            gid := g.Id
        } catch {
            gid := 0
        }
        if (gid <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_GATE, g)
            gid := g.Id
        }

        IniWrite(gid, tmp, "Gates", "Id." i)

        gSec := "Gate." gid
        IniWrite(g.Has("Priority") ? g["Priority"] : i, tmp, gSec, "Priority")
        IniWrite(g.Has("FromTrackId") ? g["FromTrackId"] : 0, tmp, gSec, "FromTrackId")
        IniWrite(g.Has("ToTrackId")   ? g["ToTrackId"]   : 0, tmp, gSec, "ToTrackId")
        IniWrite(g.Has("Logic") ? g["Logic"] : "AND", tmp, gSec, "Logic")

        conds := []
        try {
            conds := g["Conds"]
        } catch {
            conds := []
        }
        IniWrite(conds.Length, tmp, gSec, "CondCount")

        j := 1
        while (j <= conds.Length) {
            c := conds[j]
            cSec := "Gate." gid ".Cond." j

            kind := ""
            try {
                kind := c["Kind"]
            } catch {
                kind := ""
            }
            IniWrite(kind != "" ? kind : "PixelReady", tmp, cSec, "Kind")

            if (StrUpper(kind) = "PIXELREADY") {
                IniWrite(c.Has("RefType")  ? c["RefType"]  : "Skill", tmp, cSec, "RefType")
                IniWrite(c.Has("RefId")    ? c["RefId"]    : 0,      tmp, cSec, "RefId")
                IniWrite(c.Has("Op")       ? c["Op"]       : "NEQ",   tmp, cSec, "Op")
                IniWrite(c.Has("Color")    ? c["Color"]    : "0x000000", tmp, cSec, "Color")
                IniWrite(c.Has("Tol")      ? c["Tol"]      : 16,      tmp, cSec, "Tol")
                IniWrite(c.Has("RuleId")   ? c["RuleId"]   : 0,       tmp, cSec, "RuleId")
                IniWrite(c.Has("QuietMs")  ? c["QuietMs"]  : 0,       tmp, cSec, "QuietMs")
                IniWrite(c.Has("Cmp")      ? c["Cmp"]      : "GE",    tmp, cSec, "Cmp")
                IniWrite(c.Has("Value")    ? c["Value"]    : 0,       tmp, cSec, "Value")
                IniWrite(c.Has("ElapsedMs")? c["ElapsedMs"]: 0,       tmp, cSec, "ElapsedMs")
            } else if (StrUpper(kind) = "RULEQUIET") {
                IniWrite(HasProp(c,"RuleId") ? c["RuleId"] : 0, tmp, cSec, "RuleId")
                IniWrite(HasProp(c,"QuietMs") ? c["QuietMs"] : 0, tmp, cSec, "QuietMs")
            } else if (StrUpper(kind) = "COUNTER") {
                IniWrite(HasProp(c,"SkillId") ? c["SkillId"] : 0, tmp, cSec, "SkillId")
                IniWrite(HasProp(c,"Cmp") ? c["Cmp"] : "GE", tmp, cSec, "Cmp")
                IniWrite(HasProp(c,"Value") ? c["Value"] : 1, tmp, cSec, "Value")
            } else if (StrUpper(kind) = "ELAPSED") {
                IniWrite(HasProp(c,"Cmp") ? c["Cmp"] : "GE", tmp, cSec, "Cmp")
                IniWrite(HasProp(c,"ElapsedMs") ? c["ElapsedMs"] : 0, tmp, cSec, "ElapsedMs")
            } else {
                ; 未知类型也按 PixelReady 兜底字段
                IniWrite(c.Has("RefType")  ? c["RefType"]  : "Skill", tmp, cSec, "RefType")
                IniWrite(c.Has("RefId")    ? c["RefId"]    : 0,      tmp, cSec, "RefId")
                IniWrite(c.Has("Op")       ? c["Op"]       : "NEQ",   tmp, cSec, "Op")
                IniWrite(c.Has("Color")    ? c["Color"]    : "0x000000", tmp, cSec, "Color")
                IniWrite(c.Has("Tol")      ? c["Tol"]      : 16,      tmp, cSec, "Tol")
            }

            j := j + 1
        }

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Gates(profileName, &profile) {
    file := FS_ModulePath(profileName, "rotation_gates")
    if !FileExist(file) {
        return
    }

    gates := []
    count := Integer(IniRead(file, "Gates", "Count", 0))
    nextId := Integer(IniRead(file, "Gates", "NextId", 1))

    i := 1
    while (i <= count) {
        gid := Integer(IniRead(file, "Gates", "Id." i, 0))
        if (gid <= 0) {
            i := i + 1
            continue
        }

        gSec := "Gate." gid
        g := PM_NewGate()
        g["Id"] := gid
        g["Priority"] := Integer(IniRead(file, gSec, "Priority", i))
        g["FromTrackId"] := Integer(IniRead(file, gSec, "FromTrackId", 0))
        g["ToTrackId"] := Integer(IniRead(file, gSec, "ToTrackId", 0))
        g["Logic"] := IniRead(file, gSec, "Logic", "AND")

        cc := Integer(IniRead(file, gSec, "CondCount", 0))
        conds := []
        j := 1
        while (j <= cc) {
            cSec := "Gate." gid ".Cond." j
            kind := IniRead(file, cSec, "Kind", "PixelReady")
            c := Map()
            c["Kind"] := "" kind

            if (StrUpper(kind) = "PIXELREADY") {
                c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                c["Op"] := IniRead(file, cSec, "Op", "NEQ")
                c["Color"] := IniRead(file, cSec, "Color", "0x000000")
                c["Tol"] := Integer(IniRead(file, cSec, "Tol", 16))
                c["RuleId"] := Integer(IniRead(file, cSec, "RuleId", 0))
                c["QuietMs"] := Integer(IniRead(file, cSec, "QuietMs", 0))
                c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                c["Value"] := Integer(IniRead(file, cSec, "Value", 0))
                c["ElapsedMs"] := Integer(IniRead(file, cSec, "ElapsedMs", 0))
            } else if (StrUpper(kind) = "RULEQUIET") {
                c["RuleId"] := Integer(IniRead(file, cSec, "RuleId", 0))
                c["QuietMs"] := Integer(IniRead(file, cSec, "QuietMs", 0))
            } else if (StrUpper(kind) = "COUNTER") {
                c["SkillId"] := Integer(IniRead(file, cSec, "SkillId", 0))
                c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                c["Value"] := Integer(IniRead(file, cSec, "Value", 1))
            } else if (StrUpper(kind) = "ELAPSED") {
                c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                c["ElapsedMs"] := Integer(IniRead(file, cSec, "ElapsedMs", 0))
            } else {
                c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                c["Op"] := IniRead(file, cSec, "Op", "NEQ")
                c["Color"] := IniRead(file, cSec, "Color", "0x000000")
                c["Tol"] := Integer(IniRead(file, cSec, "Tol", 16))
            }

            conds.Push(c)
            j := j + 1
        }
        g["Conds"] := conds

        gates.Push(g)
        i := i + 1
    }

    profile["Rotation"]["Gates"] := gates
    try {
        if (nextId > profile["Meta"]["NextId"]["Gate"]) {
            profile["Meta"]["NextId"]["Gate"] := nextId
        }
    } catch {
    }
}