#Requires AutoHotkey v2
;modules\storage\profile\Save_Opener.ahk 保存 Opener 模块
SaveModule_Opener(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rotation_opener")
    tmp := FS_AtomicBegin(file)

    op := Map()
    try {
        op := profile["Rotation"]["Opener"]
    } catch {
        op := Map()
    }

    IniWrite(op.Has("Enabled") ? op["Enabled"] : 0, tmp, "Opener", "Enabled")
    IniWrite(op.Has("MaxDurationMs") ? op["MaxDurationMs"] : 4000, tmp, "Opener", "MaxDurationMs")
    IniWrite(op.Has("ThreadId") ? op["ThreadId"] : 1, tmp, "Opener", "ThreadId")

    watch := []
    try {
        watch := op["Watch"]
    } catch {
        watch := []
    }
    IniWrite(watch.Length, tmp, "Opener", "WatchCount")
    i := 1
    while (i <= watch.Length) {
        w := watch[i]
        wSec := "Opener.Watch." i
        IniWrite(w.Has("SkillId") ? w["SkillId"] : 0, tmp, wSec, "SkillId")
        IniWrite(w.Has("RequireCount") ? w["RequireCount"] : 1, tmp, wSec, "RequireCount")
        IniWrite(w.Has("VerifyBlack") ? w["VerifyBlack"] : 0, tmp, wSec, "VerifyBlack")
        i := i + 1
    }

    steps := []
    try {
        steps := op["Steps"]
    } catch {
        steps := []
    }
    IniWrite(steps.Length, tmp, "Opener", "StepsCount")
    i := 1
    while (i <= steps.Length) {
        st := steps[i]
        sSec := "Opener.Step." i
        kind := ""
        try {
            kind := st["Kind"]
        } catch {
            kind := ""
        }
        IniWrite(kind, tmp, sSec, "Kind")
        if (StrUpper(kind) = "SKILL") {
            IniWrite(st.Has("SkillId") ? st["SkillId"] : 0, tmp, sSec, "SkillId")
            IniWrite(st.Has("RequireReady") ? st["RequireReady"] : 0, tmp, sSec, "RequireReady")
            IniWrite(st.Has("PreDelayMs") ? st["PreDelayMs"] : 0, tmp, sSec, "PreDelayMs")
            IniWrite(st.Has("HoldMs") ? st["HoldMs"] : 0, tmp, sSec, "HoldMs")
            IniWrite(st.Has("Verify") ? st["Verify"] : 0, tmp, sSec, "Verify")
            IniWrite(st.Has("TimeoutMs") ? st["TimeoutMs"] : 1200, tmp, sSec, "TimeoutMs")
            IniWrite(st.Has("DurationMs") ? st["DurationMs"] : 0, tmp, sSec, "DurationMs")
        } else if (StrUpper(kind) = "WAIT") {
            IniWrite(st.Has("DurationMs") ? st["DurationMs"] : 0, tmp, sSec, "DurationMs")
        } else if (StrUpper(kind) = "SWAP") {
            IniWrite(st.Has("TimeoutMs") ? st["TimeoutMs"] : 800, tmp, sSec, "TimeoutMs")
            IniWrite(st.Has("Retry") ? st["Retry"] : 0, tmp, sSec, "Retry")
        }
        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Opener(profileName, profile) {
    file := FS_ModulePath(profileName, "rotation_opener")
    if !FileExist(file) {
        return
    }

    op := Map()
    try {
        op := profile["Rotation"]["Opener"]
    } catch {
        op := Map()
    }

    try {
        op["Enabled"] := Integer(IniRead(file, "Opener", "Enabled", op.Has("Enabled") ? op["Enabled"] : 0))
    } catch {
    }
    try {
        op["MaxDurationMs"] := Integer(IniRead(file, "Opener", "MaxDurationMs", op.Has("MaxDurationMs") ? op["MaxDurationMs"] : 4000))
    } catch {
    }
    try {
        op["ThreadId"] := Integer(IniRead(file, "Opener", "ThreadId", op.Has("ThreadId") ? op["ThreadId"] : 1))
    } catch {
    }

    wc := Integer(IniRead(file, "Opener", "WatchCount", 0))
    wArr := []
    i := 1
    while (i <= wc) {
        wSec := "Opener.Watch." i
        w := Map()
        w["SkillId"] := Integer(IniRead(file, wSec, "SkillId", 0))
        w["RequireCount"] := Integer(IniRead(file, wSec, "RequireCount", 1))
        w["VerifyBlack"] := Integer(IniRead(file, wSec, "VerifyBlack", 0))
        wArr.Push(w)
        i := i + 1
    }
    op["Watch"] := wArr

    sc := Integer(IniRead(file, "Opener", "StepsCount", 0))
    sArr := []
    i := 1
    while (i <= sc) {
        sSec := "Opener.Step." i
        st := Map()
        k := IniRead(file, sSec, "Kind", "")
        st["Kind"] := "" k
        if (StrUpper(k) = "SKILL") {
            st["SkillId"] := Integer(IniRead(file, sSec, "SkillId", 0))
            st["RequireReady"] := Integer(IniRead(file, sSec, "RequireReady", 0))
            st["PreDelayMs"] := Integer(IniRead(file, sSec, "PreDelayMs", 0))
            st["HoldMs"] := Integer(IniRead(file, sSec, "HoldMs", 0))
            st["Verify"] := Integer(IniRead(file, sSec, "Verify", 0))
            st["TimeoutMs"] := Integer(IniRead(file, sSec, "TimeoutMs", 1200))
            st["DurationMs"] := Integer(IniRead(file, sSec, "DurationMs", 0))
        } else if (StrUpper(k) = "WAIT") {
            st["DurationMs"] := Integer(IniRead(file, sSec, "DurationMs", 0))
        } else if (StrUpper(k) = "SWAP") {
            st["TimeoutMs"] := Integer(IniRead(file, sSec, "TimeoutMs", 800))
            st["Retry"] := Integer(IniRead(file, sSec, "Retry", 0))
        }
        sArr.Push(st)
        i := i + 1
    }
    op["Steps"] := sArr

    profile["Rotation"]["Opener"] := op
}