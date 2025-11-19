#Requires AutoHotkey v2
; modules\storage\profile\modules\buffs\Buffs.ahk
; BUFF 模块（新格式）：[Buffs] Count/Order + [Buff.<Id>] 节内自带 Id
; 依赖：OM_Get（modules\util\Obj.ahk）、ID_Next（modules\util\IdGen.ahk）
; 依赖：FS_ModulePath / FS_AtomicBegin / FS_AtomicCommit / FS_Meta_Touch

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

    count := 0
    try {
        count := arr.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Buffs", "Count")

    ; 确保每项都有稳定 Id，并构建 Order
    order := ""
    i := 1
    while (i <= count) {
        b := 0
        try {
            b := arr[i]
        } catch {
            b := 0
        }
        if (!IsObject(b)) {
            i := i + 1
            continue
        }

        bid := 0
        try {
            bid := OM_Get(b, "Id", 0)
        } catch {
            bid := 0
        }
        if (bid <= 0) {
            newId := 0
            try {
                newId := ID_Next()
            } catch {
                newId := 0
            }
            if (newId > 0) {
                wrote := false
                try {
                    b["Id"] := newId
                    wrote := true
                } catch {
                    wrote := false
                }
                if (!wrote) {
                    try {
                        b.Id := newId
                    } catch {
                    }
                }
                bid := newId
            }
        }

        if (order = "") {
            order := "" bid
        } else {
            order := order "," bid
        }
        i := i + 1
    }
    IniWrite(order, tmp, "Buffs", "Order")

    ; 写每条 BUFF 明细
    i := 1
    while (i <= count) {
        b := 0
        try {
            b := arr[i]
        } catch {
            b := 0
        }
        if (!IsObject(b)) {
            i := i + 1
            continue
        }

        bid := 0
        try {
            bid := OM_Get(b, "Id", 0)
        } catch {
            bid := 0
        }
        if (bid <= 0) {
            i := i + 1
            continue
        }

        sec := "Buff." bid
        IniWrite(bid, tmp, sec, "Id")
        IniWrite(OM_Get(b, "Name", "Buff"),             tmp, sec, "Name")
        IniWrite(OM_Get(b, "Enabled", 1),               tmp, sec, "Enabled")
        IniWrite(OM_Get(b, "DurationMs", 0),            tmp, sec, "DurationMs")
        IniWrite(OM_Get(b, "RefreshBeforeMs", 0),       tmp, sec, "RefreshBeforeMs")
        IniWrite(OM_Get(b, "CheckReady", 1),            tmp, sec, "CheckReady")
        IniWrite(OM_Get(b, "ThreadId", 1),              tmp, sec, "ThreadId")

        skills := []
        try {
            skills := b["Skills"]
        } catch {
            skills := []
        }
        sc := 0
        try {
            sc := skills.Length
        } catch {
            sc := 0
        }
        IniWrite(sc, tmp, sec, "SkillsCount")

        j := 1
        while (j <= sc) {
            sid := 0
            try {
                sid := skills[j]
            } catch {
                sid := 0
            }
            IniWrite(sid, tmp, "Buff." bid ".Skill." j, "SkillId")
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

    arr := []
    order := ""
    try {
        order := IniRead(file, "Buffs", "Order", "")
    } catch {
        order := ""
    }
    if (order = "") {
        profile["Buffs"] := []
        return
    }

    ids := StrSplit(order, ",")
    i := 1
    while (i <= ids.Length) {
        idStr := ""
        try {
            idStr := Trim(ids[i])
        } catch {
            idStr := ""
        }
        bid := 0
        try {
            bid := Integer(idStr)
        } catch {
            bid := 0
        }
        if (bid <= 0) {
            i := i + 1
            continue
        }

        sec := "Buff." bid
        b := PM_NewBuff()
        try {
            b["Id"] := bid
        } catch {
        }
        try {
            b["Name"] := IniRead(file, sec, "Name", "Buff")
        } catch {
        }
        try {
            b["Enabled"] := Integer(IniRead(file, sec, "Enabled", 1))
        } catch {
        }
        try {
            b["DurationMs"] := Integer(IniRead(file, sec, "DurationMs", 0))
        } catch {
        }
        try {
            b["RefreshBeforeMs"] := Integer(IniRead(file, sec, "RefreshBeforeMs", 0))
        } catch {
        }
        try {
            b["CheckReady"] := Integer(IniRead(file, sec, "CheckReady", 1))
        } catch {
        }
        try {
            b["ThreadId"] := Integer(IniRead(file, sec, "ThreadId", 1))
        } catch {
        }

        sc := 0
        try {
            sc := Integer(IniRead(file, sec, "SkillsCount", 0))
        } catch {
            sc := 0
        }
        skills := []
        j := 1
        while (j <= sc) {
            sid := 0
            try {
                sid := Integer(IniRead(file, "Buff." bid ".Skill." j, "SkillId", 0))
            } catch {
                sid := 0
            }
            skills.Push(sid)
            j := j + 1
        }
        b["Skills"] := skills

        arr.Push(b)
        i := i + 1
    }

    profile["Buffs"] := arr
}