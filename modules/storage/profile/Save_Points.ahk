#Requires AutoHotkey v2
;modules\storage\profile\Save_Points.ahk 保存 Points 模块
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

    count := arr.Length
    IniWrite(count, tmp, "Points", "Count")
    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Point"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Points", "NextId")

    i := 1
    while (i <= count) {
        id := 0
        p := arr[i]
        try {
            id := p.Id
        } catch {
            id := 0
        }
        if (id <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_POINT, p)
            id := p.Id
        }
        IniWrite(id, tmp, "Points", "Id." i)

        sec := "Point." id
        IniWrite(p.Has("Name") ? p["Name"] : "", tmp, sec, "Name")
        IniWrite(p.Has("X") ? p["X"] : 0, tmp, sec, "X")
        IniWrite(p.Has("Y") ? p["Y"] : 0, tmp, sec, "Y")
        IniWrite(p.Has("Color") ? p["Color"] : "0x000000", tmp, sec, "Color")
        IniWrite(p.Has("Tol") ? p["Tol"] : 10, tmp, sec, "Tol")

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
    count := Integer(IniRead(file, "Points", "Count", 0))
    nextId := Integer(IniRead(file, "Points", "NextId", 1))

    i := 1
    while (i <= count) {
        id := Integer(IniRead(file, "Points", "Id." i, 0))
        if (id <= 0) {
            i := i + 1
            continue
        }
        sec := "Point." id
        p := PM_NewPoint()
        p["Id"] := id
        p["Name"] := IniRead(file, sec, "Name", "")
        p["X"] := Integer(IniRead(file, sec, "X", 0))
        p["Y"] := Integer(IniRead(file, sec, "Y", 0))
        p["Color"] := IniRead(file, sec, "Color", "0x000000")
        p["Tol"] := Integer(IniRead(file, sec, "Tol", 10))
        arr.Push(p)
        i := i + 1
    }

    profile["Points"] := arr
    try {
        if (nextId > profile["Meta"]["NextId"]["Point"]) {
            profile["Meta"]["NextId"]["Point"] := nextId
        }
    } catch {
    }
}