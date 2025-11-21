#Requires AutoHotkey v2
; modules\storage\profile\Save_Points.ahk
; Points 模块（新格式）：[Points] Count/Order + [Point.<Id>] 节内自带 Id
; 依赖：OM_Get（modules\util\Obj.ahk）、ID_Next（modules\util\IdGen.ahk）
; 依赖：FS_ModulePath / FS_AtomicBegin / FS_AtomicCommit / FS_Meta_Touch

SaveModule_Points(profile) {
    if !IsObject(profile) {
        return false
    }

    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "points")
    tmp := FS_AtomicBegin(file)

    arr := []
    try {
        arr := profile["Points"]
    } catch {
        arr := []
    }

    count := 0
    try {
        count := arr.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Points", "Count")

    ; 确保每项都有稳定 Id，并构建 Order
    order := ""
    i := 1
    while (i <= count) {
        p := 0
        try {
            p := arr[i]
        } catch {
            p := 0
        }
        if (!IsObject(p)) {
            i := i + 1
            continue
        }

        pid := 0
        try {
            pid := OM_Get(p, "Id", 0)
        } catch {
            pid := 0
        }
        if (pid <= 0) {
            newId := 0
            try {
                newId := ID_Next()
            } catch {
                newId := 0
            }
            if (newId > 0) {
                wrote := false
                try {
                    p["Id"] := newId
                    wrote := true
                } catch {
                    wrote := false
                }
                if (!wrote) {
                    try {
                        p.Id := newId
                    } catch {
                    }
                }
                pid := newId
            }
        }

        if (order = "") {
            order := "" pid
        } else {
            order := order "," pid
        }

        i := i + 1
    }
    IniWrite(order, tmp, "Points", "Order")

    ; 写每项
    i := 1
    while (i <= count) {
        p := 0
        try {
            p := arr[i]
        } catch {
            p := 0
        }
        if (!IsObject(p)) {
            i := i + 1
            continue
        }

        pid := 0
        try {
            pid := OM_Get(p, "Id", 0)
        } catch {
            pid := 0
        }
        if (pid <= 0) {
            i := i + 1
            continue
        }

        sec := "Point." pid
        IniWrite(pid, tmp, sec, "Id")
        IniWrite(OM_Get(p, "Name", ""),          tmp, sec, "Name")
        IniWrite(OM_Get(p, "X", 0),              tmp, sec, "X")
        IniWrite(OM_Get(p, "Y", 0),              tmp, sec, "Y")
        IniWrite(OM_Get(p, "Color", "0x000000"), tmp, sec, "Color")
        IniWrite(OM_Get(p, "Tol", 10),           tmp, sec, "Tol")

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Points(profileName, profile) {
    file := FS_ModulePath(profileName, "points")
    if !FileExist(file) {
        return
    }

    arr := []
    order := ""
    try {
        order := IniRead(file, "Points", "Order", "")
    } catch {
        order := ""
    }
    if (order = "") {
        ; 新格式要求必须有 Order；无则视为无数据
        profile["Points"] := []
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
        pid := 0
        try {
            pid := Integer(idStr)
        } catch {
            pid := 0
        }
        if (pid <= 0) {
            i := i + 1
            continue
        }

        sec := "Point." pid
        p := PM_NewPoint()
        try {
            p["Id"] := pid
        } catch {
        }
        try {
            p["Name"] := IniRead(file, sec, "Name", "")
        } catch {
        }
        try {
            p["X"] := Integer(IniRead(file, sec, "X", 0))
        } catch {
        }
        try {
            p["Y"] := Integer(IniRead(file, sec, "Y", 0))
        } catch {
        }
        try {
            p["Color"] := IniRead(file, sec, "Color", "0x000000")
        } catch {
        }
        try {
            p["Tol"] := Integer(IniRead(file, sec, "Tol", 10))
        } catch {
        }

        arr.Push(p)
        i := i + 1
    }

    profile["Points"] := arr
}