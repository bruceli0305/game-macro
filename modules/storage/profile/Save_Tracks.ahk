#Requires AutoHotkey v2
;modules\storage\profile\Save_Tracks.ahk 保存 Tracks 模块
SaveModule_Tracks(profile) {
    if !IsObject(profile) {
        return false
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rotation_tracks")
    tmp := FS_AtomicBegin(file)

    tracks := []
    try {
        tracks := profile["Rotation"]["Tracks"]
    } catch {
        tracks := []
    }

    count := tracks.Length
    IniWrite(count, tmp, "Tracks", "Count")

    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Track"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Tracks", "NextId")

    i := 1
    while (i <= count) {
        t := tracks[i]
        tid := 0
        try {
            tid := t.Id
        } catch {
            tid := 0
        }
        if (tid <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_TRACK, t)
            tid := t.Id
        }

        IniWrite(tid, tmp, "Tracks", "Id." i)

        tSec := "Track." tid
        IniWrite(t.Has("ThreadId") ? t["ThreadId"] : 1, tmp, tSec, "ThreadId")
        IniWrite(t.Has("MaxDurationMs") ? t["MaxDurationMs"] : 8000, tmp, tSec, "MaxDurationMs")
        IniWrite(t.Has("MinStayMs") ? t["MinStayMs"] : 0, tmp, tSec, "MinStayMs")
        IniWrite(t.Has("NextTrackId") ? t["NextTrackId"] : 0, tmp, tSec, "NextTrackId")

        watch := []
        try {
            watch := t["Watch"]
        } catch {
            watch := []
        }
        IniWrite(watch.Length, tmp, tSec, "WatchCount")
        j := 1
        while (j <= watch.Length) {
            w := watch[j]
            wSec := "Track." tid ".Watch." j
            IniWrite(w.Has("SkillId") ? w["SkillId"] : 0, tmp, wSec, "SkillId")
            IniWrite(w.Has("RequireCount") ? w["RequireCount"] : 1, tmp, wSec, "RequireCount")
            IniWrite(w.Has("VerifyBlack") ? w["VerifyBlack"] : 0, tmp, wSec, "VerifyBlack")
            j := j + 1
        }

        refs := []
        try {
            refs := t["RuleRefs"]
        } catch {
            refs := []
        }
        IniWrite(refs.Length, tmp, tSec, "RuleRefCount")
        j := 1
        while (j <= refs.Length) {
            rid := 0
            try {
                rid := refs[j]
            } catch {
                rid := 0
            }
            IniWrite(rid, tmp, "Track." tid ".RuleRef." j, "RuleId")
            j := j + 1
        }

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Tracks(profileName, &profile) {
    file := FS_ModulePath(profileName, "rotation_tracks")
    if !FileExist(file) {
        return
    }

    tracks := []
    count := Integer(IniRead(file, "Tracks", "Count", 0))
    nextId := Integer(IniRead(file, "Tracks", "NextId", 1))

    i := 1
    while (i <= count) {
        tid := Integer(IniRead(file, "Tracks", "Id." i, 0))
        if (tid <= 0) {
            i := i + 1
            continue
        }
        tSec := "Track." tid

        t := PM_NewTrack()
        t["Id"] := tid
        t["ThreadId"] := Integer(IniRead(file, tSec, "ThreadId", 1))
        t["MaxDurationMs"] := Integer(IniRead(file, tSec, "MaxDurationMs", 8000))
        t["MinStayMs"] := Integer(IniRead(file, tSec, "MinStayMs", 0))
        t["NextTrackId"] := Integer(IniRead(file, tSec, "NextTrackId", 0))

        wc := Integer(IniRead(file, tSec, "WatchCount", 0))
        wArr := []
        j := 1
        while (j <= wc) {
            w := Map()
            wSec := "Track." tid ".Watch." j
            w["SkillId"] := Integer(IniRead(file, wSec, "SkillId", 0))
            w["RequireCount"] := Integer(IniRead(file, wSec, "RequireCount", 1))
            w["VerifyBlack"] := Integer(IniRead(file, wSec, "VerifyBlack", 0))
            wArr.Push(w)
            j := j + 1
        }
        t["Watch"] := wArr

        rc := Integer(IniRead(file, tSec, "RuleRefCount", 0))
        rArr := []
        j := 1
        while (j <= rc) {
            rid := Integer(IniRead(file, "Track." tid ".RuleRef." j, "RuleId", 0))
            rArr.Push(rid)
            j := j + 1
        }
        t["RuleRefs"] := rArr

        tracks.Push(t)
        i := i + 1
    }

    profile["Rotation"]["Tracks"] := tracks
    try {
        if (nextId > profile["Meta"]["NextId"]["Track"]) {
            profile["Meta"]["NextId"]["Track"] := nextId
        }
    } catch {
    }
}