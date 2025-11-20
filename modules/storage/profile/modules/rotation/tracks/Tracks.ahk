#Requires AutoHotkey v2
; modules\storage\profile\modules\rotation\tracks\Tracks.ahk
; 轨道模块（新格式）：[Tracks] Count/Order + [Track.<Id>] 节内自带 Id/Name
; 引用均为稳定 Id（SkillId/RuleId/NextTrackId）
; 不兼容旧格式（无 Id.n / 无 NextId）

; 依赖：OM_Get / ID_Next / FS_ModulePath / FS_AtomicBegin / FS_AtomicCommit / FS_Meta_Touch / Logger_*

SaveModule_Tracks(profile) {
    if !IsObject(profile) {
        return false
    }

    name := ""
    try {
        name := profile["Name"]
    } catch {
        name := ""
    }
    if (name = "") {
        return false
    }

    dbgStore := 0
    try {
        if Logger_IsEnabled(50, "Storage") {
            dbgStore := 1
        } else {
            dbgStore := 0
        }
    } catch {
        dbgStore := 0
    }

    file := FS_ModulePath(name, "rotation_tracks")
    tmp := FS_AtomicBegin(file)

    tracks := []
    try {
        tracks := profile["Rotation"]["Tracks"]
    } catch {
        tracks := []
    }

    count := 0
    try {
        count := tracks.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Tracks", "Count")

    ; 为缺失 Id 的轨道分配雪花 Id，并构建 Order
    order := ""
    newIdAlloc := 0
    i := 1
    while (i <= count) {
        t := 0
        try {
            t := tracks[i]
        } catch {
            t := 0
        }
        if !IsObject(t) {
            i := i + 1
            continue
        }

        tid := 0
        try {
            tid := OM_Get(t, "Id", 0)
        } catch {
            tid := 0
        }
        if (tid <= 0) {
            nid := 0
            try {
                nid := ID_Next()
            } catch {
                nid := 0
            }
            if (nid > 0) {
                wrote := false
                try {
                    t["Id"] := nid
                    wrote := true
                } catch {
                    wrote := false
                }
                if (!wrote) {
                    try {
                        t.Id := nid
                    } catch {
                    }
                }
                tid := nid
                newIdAlloc := newIdAlloc + 1
            }
        }

        if (order = "") {
            order := "" tid
        } else {
            order := order "," tid
        }
        i := i + 1
    }
    IniWrite(order, tmp, "Tracks", "Order")

    if (dbgStore) {
        fi := Map()
        try {
            fi["profile"] := name
            fi["order"] := order
            fi["count"] := count
            fi["newIds"] := newIdAlloc
            Logger_Debug("Storage", "SaveModule_Tracks order", fi)
        } catch {
        }
    }

    ; 写每条轨道与子节（记录写入前 0 的统计）
    i := 1
    while (i <= count) {
        t := 0
        try {
            t := tracks[i]
        } catch {
            t := 0
        }
        if !IsObject(t) {
            i := i + 1
            continue
        }

        tid := 0
        try {
            tid := OM_Get(t, "Id", 0)
        } catch {
            tid := 0
        }
        if (tid <= 0) {
            i := i + 1
            continue
        }

        if (dbgStore) {
            badW := 0
            badR := 0

            wt := []
            try {
                if t.Has("Watch") {
                    wt := t["Watch"]
                } else {
                    wt := []
                }
            } catch {
                wt := []
            }
            j := 1
            while (j <= wt.Length) {
                sid0 := 0
                try {
                    sid0 := OM_Get(wt[j], "SkillId", 0)
                } catch {
                    sid0 := 0
                }
                if (sid0 <= 0) {
                    badW := badW + 1
                }
                j := j + 1
            }

            rf := []
            try {
                if t.Has("RuleRefs") {
                    rf := t["RuleRefs"]
                } else {
                    rf := []
                }
            } catch {
                rf := []
            }
            j := 1
            while (j <= rf.Length) {
                rr := 0
                try {
                    rr := rf[j]
                } catch {
                    rr := 0
                }
                if (rr <= 0) {
                    badR := badR + 1
                }
                j := j + 1
            }

            rec := Map()
            try {
                rec["Tid"] := OM_Get(t, "Id", 0)
                rec["Name"] := OM_Get(t, "Name", "")
                rec["WatchTotal"] := wt.Length
                rec["WatchZero"] := badW
                rec["RuleRefTotal"] := rf.Length
                rec["RuleRefZero"] := badR
                Logger_Warn("Storage", "SaveModule_Tracks pre-write check", rec)
            } catch {
            }
        }

        tSec := "Track." tid
        IniWrite(tid, tmp, tSec, "Id")
        IniWrite(OM_Get(t, "Name", ""), tmp, tSec, "Name")
        IniWrite(OM_Get(t, "ThreadId", 1), tmp, tSec, "ThreadId")
        IniWrite(OM_Get(t, "MaxDurationMs", 8000), tmp, tSec, "MaxDurationMs")
        IniWrite(OM_Get(t, "MinStayMs", 0), tmp, tSec, "MinStayMs")
        IniWrite(OM_Get(t, "NextTrackId", 0), tmp, tSec, "NextTrackId")

        ; Watch
        watch := []
        try {
            watch := t["Watch"]
        } catch {
            watch := []
        }
        wCount := 0
        try {
            wCount := watch.Length
        } catch {
            wCount := 0
        }
        IniWrite(wCount, tmp, tSec, "WatchCount")
        j := 1
        while (j <= wCount) {
            w := 0
            try {
                w := watch[j]
            } catch {
                w := 0
            }
            wSec := "Track." tid ".Watch." j
            IniWrite(OM_Get(w, "SkillId", 0),      tmp, wSec, "SkillId")
            IniWrite(OM_Get(w, "RequireCount", 1),  tmp, wSec, "RequireCount")
            IniWrite(OM_Get(w, "VerifyBlack", 0),   tmp, wSec, "VerifyBlack")
            j := j + 1
        }

        ; RuleRefs
        refs := []
        try {
            refs := t["RuleRefs"]
        } catch {
            refs := []
        }
        rCount := 0
        try {
            rCount := refs.Length
        } catch {
            rCount := 0
        }
        IniWrite(rCount, tmp, tSec, "RuleRefCount")
        j := 1
        while (j <= rCount) {
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
    try {
        Logger_Info("Storage", "SaveModule_Tracks ok", Map("profile", name, "count", count, "newIds", newIdAlloc))
    } catch {
    }
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Tracks(profileName, profile) {
    file := FS_ModulePath(profileName, "rotation_tracks")
    if !FileExist(file) {
        return
    }

    dbgLoad := 0
    try {
        if Logger_IsEnabled(50, "Storage") {
            dbgLoad := 1
        } else {
            dbgLoad := 0
        }
    } catch {
        dbgLoad := 0
    }

    order := ""
    try {
        order := IniRead(file, "Tracks", "Order", "")
    } catch {
        order := ""
    }
    if (dbgLoad) {
        f := Map()
        try {
            f["profile"] := profileName
            f["order"] := order
        } catch {
        }
        try {
            Logger_Debug("Storage", "FS_Load_Tracks order", f)
        } catch {
        }
    }
    if (order = "") {
        try {
            profile["Rotation"]["Tracks"] := []
        } catch {
        }
        try {
            Logger_Warn("Storage", "FS_Load_Tracks: empty or missing Order", Map("profile", profileName))
        } catch {
        }
        return
    }

    ids := StrSplit(order, ",")
    tracks := []
    validIds := Map()

    i := 1
    while (i <= ids.Length) {
        idStr := ""
        try {
            idStr := Trim(ids[i])
        } catch {
            idStr := ""
        }
        tid := 0
        try {
            tid := Integer(idStr)
        } catch {
            tid := 0
        }
        if (tid <= 0) {
            i := i + 1
            continue
        }

        tSec := "Track." tid
        t := PM_NewTrack()

        try {
            t["Id"] := tid
        } catch {
        }
        try {
            t["Name"] := IniRead(file, tSec, "Name", "")
        } catch {
        }
        try {
            t["ThreadId"] := Integer(IniRead(file, tSec, "ThreadId", 1))
        } catch {
        }
        try {
            t["MaxDurationMs"] := Integer(IniRead(file, tSec, "MaxDurationMs", 8000))
        } catch {
        }
        try {
            t["MinStayMs"] := Integer(IniRead(file, tSec, "MinStayMs", 0))
        } catch {
        }
        try {
            t["NextTrackId"] := Integer(IniRead(file, tSec, "NextTrackId", 0))
        } catch {
        }

        ; Watch
        wCount := 0
        try {
            wCount := Integer(IniRead(file, tSec, "WatchCount", 0))
        } catch {
            wCount := 0
        }
        wArr := []
        j := 1
        while (j <= wCount) {
            wSec := "Track." tid ".Watch." j
            w := Map()

            val := 0
            try {
                val := Integer(IniRead(file, wSec, "SkillId", 0))
            } catch {
                val := 0
            }
            try {
                w["SkillId"] := val
            } catch {
            }

            val := 1
            try {
                val := Integer(IniRead(file, wSec, "RequireCount", 1))
            } catch {
                val := 1
            }
            try {
                w["RequireCount"] := val
            } catch {
            }

            val := 0
            try {
                val := Integer(IniRead(file, wSec, "VerifyBlack", 0))
            } catch {
                val := 0
            }
            try {
                w["VerifyBlack"] := val
            } catch {
            }

            wArr.Push(w)
            j := j + 1
        }

        ; RuleRefs
        rCount := 0
        try {
            rCount := Integer(IniRead(file, tSec, "RuleRefCount", 0))
        } catch {
            rCount := 0
        }
        rArr := []
        j := 1
        while (j <= rCount) {
            rid := 0
            try {
                rid := Integer(IniRead(file, "Track." tid ".RuleRef." j, "RuleId", 0))
            } catch {
                rid := 0
            }
            rArr.Push(rid)
            j := j + 1
        }

        if (dbgLoad) {
            wZero := 0
            j := 1
            while (j <= wArr.Length) {
                sidv := 0
                try {
                    sidv := OM_Get(wArr[j], "SkillId", 0)
                } catch {
                    sidv := 0
                }
                if (sidv <= 0) {
                    wZero := wZero + 1
                }
                j := j + 1
            }

            rZero := 0
            j := 1
            while (j <= rArr.Length) {
                ridv := 0
                try {
                    ridv := rArr[j]
                } catch {
                    ridv := 0
                }
                if (ridv <= 0) {
                    rZero := rZero + 1
                }
                j := j + 1
            }

            rec := Map()
            try {
                rec["profile"] := profileName
                rec["Tid"] := tid
                rec["WatchTotal"] := wArr.Length
                rec["WatchZero"] := wZero
                rec["RuleRefTotal"] := rArr.Length
                rec["RuleRefZero"] := rZero
                Logger_Info("Storage", "FS_Load_Tracks summary", rec)
            } catch {
            }
        }

        t["Watch"] := wArr
        t["RuleRefs"] := rArr

        tracks.Push(t)
        try {
            validIds[tid] := 1
        } catch {
        }

        i := i + 1
    }

    ; 轻量一致性：NextTrackId 不存在则归零（仅内存）
    fixed := 0
    i := 1
    while (i <= tracks.Length) {
        nextId := 0
        try {
            nextId := OM_Get(tracks[i], "NextTrackId", 0)
        } catch {
            nextId := 0
        }
        if (nextId != 0) {
            ok := false
            try {
                ok := validIds.Has(nextId)
            } catch {
                ok := false
            }
            if (!ok) {
                try {
                    tracks[i]["NextTrackId"] := 0
                } catch {
                }
                fixed := fixed + 1
            }
        }
        i := i + 1
    }

    try {
        profile["Rotation"]["Tracks"] := tracks
    } catch {
    }
    try {
        Logger_Info("Storage", "FS_Load_Tracks ok", Map("profile", profileName, "count", tracks.Length, "fixedNext", fixed))
    } catch {
    }
}