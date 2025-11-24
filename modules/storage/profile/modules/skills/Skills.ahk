#Requires AutoHotkey v2
;modules\storage\profile\modules\skills\Skills.ahk 保存 Skills 模块
; 仅新格式：Count + Order + [Skill.<Id>]，不再写旧的 Id.N/NextId
; 依赖：OM_Get（modules\util\Obj.ahk）、ID_Next（modules\util\IdGen.ahk）
; 依赖：FS_ModulePath / FS_AtomicBegin / FS_AtomicCommit / FS_Meta_Touch

SaveModule_Skills(profile) {
    if !IsObject(profile) {
        return false
    }

    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "skills")
    tmp := FS_AtomicBegin(file)

    arr := []
    try {
        arr := profile["Skills"]
    } catch {
        arr := []
    }

    count := 0
    try {
        count := arr.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Skills", "Count")

    ; 确保每项都有稳定 Id（雪花），并构建 Order
    order := ""
    i := 1
    while (i <= count) {
        s := 0
        try {
            s := arr[i]
        } catch {
            s := 0
        }
        if (!IsObject(s)) {
            i := i + 1
            continue
        }

        sid := 0
        try {
            sid := OM_Get(s, "Id", 0)
        } catch {
            sid := 0
        }
        if (sid <= 0) {
            newsid := 0
            try {
                newsid := ID_Next()
            } catch {
                newsid := 0
            }
            if (newsid > 0) {
                wrote := false
                try {
                    s["Id"] := newsid
                    wrote := true
                } catch {
                    wrote := false
                }
                if (!wrote) {
                    try {
                        s.Id := newsid
                    } catch {
                    }
                }
                sid := newsid
            }
        }

        if (order = "") {
            order := "" sid
        } else {
            order := order "," sid
        }
        i := i + 1
    }

    IniWrite(order, tmp, "Skills", "Order")

    ; 写每项
    i := 1
    while (i <= count) {
        s := 0
        try {
            s := arr[i]
        } catch {
            s := 0
        }
        if (!IsObject(s)) {
            i := i + 1
            continue
        }

        sid := 0
        try {
            sid := OM_Get(s, "Id", 0)
        } catch {
            sid := 0
        }
        if (sid <= 0) {
            i := i + 1
            continue
        }

        sec := "Skill." sid
        IniWrite(sid, tmp, sec, "Id")
        IniWrite(OM_Get(s, "Name", ""),          tmp, sec, "Name")
        IniWrite(OM_Get(s, "Key", ""),           tmp, sec, "Key")
        IniWrite(OM_Get(s, "X", 0),              tmp, sec, "X")
        IniWrite(OM_Get(s, "Y", 0),              tmp, sec, "Y")
        IniWrite(OM_Get(s, "Color", "0x000000"), tmp, sec, "Color")
        IniWrite(OM_Get(s, "Tol", 10),           tmp, sec, "Tol")
        IniWrite(OM_Get(s, "CastMs", 0),         tmp, sec, "CastMs")
        IniWrite(OM_Get(s, "LockDuringCast", 1),  tmp, sec, "LockDuringCast")
        IniWrite(OM_Get(s, "CastTimeoutMs", 0),   tmp, sec, "CastTimeoutMs")
        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Skills(profileName, profile) {
    file := FS_ModulePath(profileName, "skills")
    if !FileExist(file) {
        return
    }

    arr := []
    order := ""
    try {
        order := IniRead(file, "Skills", "Order", "")
    } catch {
        order := ""
    }
    if (order = "") {
        ; 新格式要求必须有 Order；无则视为无数据
        profile["Skills"] := []
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
        sid := 0
        try {
            sid := Integer(idStr)
        } catch {
            sid := 0
        }
        if (sid <= 0) {
            i := i + 1
            continue
        }

        sec := "Skill." sid
        s := PM_NewSkill()
        try {
            s["Id"] := sid
        } catch {
        }
        try {
            s["Name"] := IniRead(file, sec, "Name", "")
        } catch {
        }
        try {
            s["Key"] := IniRead(file, sec, "Key", "")
        } catch {
        }
        try {
            s["X"] := Integer(IniRead(file, sec, "X", 0))
        } catch {
        }
        try {
            s["Y"] := Integer(IniRead(file, sec, "Y", 0))
        } catch {
        }
        try {
            s["Color"] := IniRead(file, sec, "Color", "0x000000")
        } catch {
        }
        try {
            s["Tol"] := Integer(IniRead(file, sec, "Tol", 10))
        } catch {
        }
        try {
            s["CastMs"] := Integer(IniRead(file, sec, "CastMs", 0))
        } catch {
        }
        try {
            s["LockDuringCast"] := Integer(IniRead(file, sec, "LockDuringCast", OM_Get(s, "LockDuringCast", 1)))
        } catch {
        }
        try {
            s["CastTimeoutMs"] := Integer(IniRead(file, sec, "CastTimeoutMs", OM_Get(s, "CastTimeoutMs", 0)))
        } catch {
        }
        arr.Push(s)
        i := i + 1
    }

    profile["Skills"] := arr
}