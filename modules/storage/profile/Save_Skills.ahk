#Requires AutoHotkey v2
;modules\storage\profile\Save_Skills.ahk 保存 Skills 模块
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

    ; 写头部
    count := arr.Length
    IniWrite(count, tmp, "Skills", "Count")

    ; NextId（来自 Meta）
    nextId := 1
    try {
        nextId := profile["Meta"]["NextId"]["Skill"]
    } catch {
        nextId := 1
    }
    IniWrite(nextId, tmp, "Skills", "NextId")

    ; Id 列表 + 逐项
    i := 1
    while (i <= count) {
        id := 0
        s := arr[i]
        try {
            id := s.Id
        } catch {
            id := 0
        }
        if (id <= 0) {
            PM_AssignIdIfMissing(profile, PM_MOD_SKILL, s)
            id := s.Id
        }
        IniWrite(id, tmp, "Skills", "Id." i)

        sec := "Skill." id
        IniWrite(s.Has("Name") ? s["Name"] : "", tmp, sec, "Name")
        IniWrite(s.Has("Key") ? s["Key"] : "", tmp, sec, "Key")
        IniWrite(s.Has("X") ? s["X"] : 0, tmp, sec, "X")
        IniWrite(s.Has("Y") ? s["Y"] : 0, tmp, sec, "Y")
        IniWrite(s.Has("Color") ? s["Color"] : "0x000000", tmp, sec, "Color")
        IniWrite(s.Has("Tol") ? s["Tol"] : 10, tmp, sec, "Tol")
        IniWrite(s.Has("CastMs") ? s["CastMs"] : 0, tmp, sec, "CastMs")

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Skills(profileName,  &profile) {
    file := FS_ModulePath(profileName, "skills")
    if !FileExist(file) {
        return
    }
    arr := []
    count := Integer(IniRead(file, "Skills", "Count", 0))
    nextId := Integer(IniRead(file, "Skills", "NextId", 1))

    i := 1
    while (i <= count) {
        id := Integer(IniRead(file, "Skills", "Id." i, 0))
        if (id <= 0) {
            i := i + 1
            continue
        }
        sec := "Skill." id
        s := PM_NewSkill()
        s["Id"] := id
        s["Name"] := IniRead(file, sec, "Name", "")
        s["Key"] := IniRead(file, sec, "Key", "")
        s["X"] := Integer(IniRead(file, sec, "X", 0))
        s["Y"] := Integer(IniRead(file, sec, "Y", 0))
        s["Color"] := IniRead(file, sec, "Color", "0x000000")
        s["Tol"] := Integer(IniRead(file, sec, "Tol", 10))
        s["CastMs"] := Integer(IniRead(file, sec, "CastMs", 0))
        arr.Push(s)
        i := i + 1
    }

    profile["Skills"] := arr
    ; 更新 NextId
    if IsObject(profile["Meta"]) && profile["Meta"].Has("NextId") {
        try {
            if (nextId > profile["Meta"]["NextId"]["Skill"]) {
                profile["Meta"]["NextId"]["Skill"] := nextId
            }
        } catch {
        }
    }
}