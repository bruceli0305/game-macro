#Requires AutoHotkey v2
;modules\storage\profile\fs\Meta.ahk 读取 meta.ini（若不存在返回默认 meta）
FS_Meta_Read(profileName) {
    file := FS_ModulePath(profileName, "meta")
    meta := Map()
    meta["SchemaVersion"] := PM_SCHEMA_VERSION
    meta["DisplayName"] := "" profileName
    meta["CreatedAt"] := PM_NowStr()
    meta["ModifiedAt"] := PM_NowStr()

    nexts := Map()
    nexts["Skill"]  := 1
    nexts["Point"]  := 1
    nexts["Rule"]   := 1
    nexts["Track"]  := 1
    nexts["Gate"]   := 1
    nexts["Buff"]   := 1
    nexts["Thread"] := 1

    if FileExist(file) {
        try {
            sv := Integer(IniRead(file, "Meta", "SchemaVersion", PM_SCHEMA_VERSION))
            meta["SchemaVersion"] := sv
        } catch {
        }
        try {
            meta["DisplayName"] := IniRead(file, "Meta", "DisplayName", profileName)
        } catch {
        }
        try {
            meta["CreatedAt"] := IniRead(file, "Meta", "CreatedAt", PM_NowStr())
        } catch {
        }
        try {
            meta["ModifiedAt"] := IniRead(file, "Meta", "ModifiedAt", PM_NowStr())
        } catch {
        }

        try {
            nexts["Skill"]  := Integer(IniRead(file, "NextId", "Skill", 1))
        } catch {
        }
        try {
            nexts["Point"]  := Integer(IniRead(file, "NextId", "Point", 1))
        } catch {
        }
        try {
            nexts["Rule"]   := Integer(IniRead(file, "NextId", "Rule", 1))
        } catch {
        }
        try {
            nexts["Track"]  := Integer(IniRead(file, "NextId", "Track", 1))
        } catch {
        }
        try {
            nexts["Gate"]   := Integer(IniRead(file, "NextId", "Gate", 1))
        } catch {
        }
        try {
            nexts["Buff"]   := Integer(IniRead(file, "NextId", "Buff", 1))
        } catch {
        }
        try {
            nexts["Thread"] := Integer(IniRead(file, "NextId", "Thread", 1))
        } catch {
        }
    }

    meta["NextId"] := nexts
    return meta
}

; 写入 meta.ini（原子）
FS_Meta_Write(profile) {
    if !IsObject(profile) {
        return
    }
    name := ""
    try {
        name := profile["Name"]
    } catch {
        return
    }
    file := FS_ModulePath(name, "meta")
    tmp := FS_AtomicBegin(file)

    ; 写 Meta
    IniWrite(PM_SCHEMA_VERSION, tmp, "Meta", "SchemaVersion")
    disp := "" name
    try {
        if profile.Has("Meta") && profile["Meta"].Has("DisplayName") {
            disp := profile["Meta"]["DisplayName"]
        }
    } catch {
        disp := "" name
    }
    IniWrite(disp, tmp, "Meta", "DisplayName")

    cr := PM_NowStr()
    try {
        if profile.Has("Meta") && profile["Meta"].Has("CreatedAt") {
            cr := profile["Meta"]["CreatedAt"]
        }
    } catch {
        cr := PM_NowStr()
    }
    IniWrite(cr, tmp, "Meta", "CreatedAt")

    md := PM_NowStr()
    try {
        if profile.Has("Meta") && profile["Meta"].Has("ModifiedAt") {
            md := profile["Meta"]["ModifiedAt"]
        }
    } catch {
        md := PM_NowStr()
    }
    IniWrite(md, tmp, "Meta", "ModifiedAt")

    ; NextId
    nexts := Map()
    try {
        nexts := profile["Meta"]["NextId"]
    } catch {
        nexts := Map()
    }
    IniWrite(nexts.Has("Skill")  ? nexts["Skill"]  : 1, tmp, "NextId", "Skill")
    IniWrite(nexts.Has("Point")  ? nexts["Point"]  : 1, tmp, "NextId", "Point")
    IniWrite(nexts.Has("Rule")   ? nexts["Rule"]   : 1, tmp, "NextId", "Rule")
    IniWrite(nexts.Has("Track")  ? nexts["Track"]  : 1, tmp, "NextId", "Track")
    IniWrite(nexts.Has("Gate")   ? nexts["Gate"]   : 1, tmp, "NextId", "Gate")
    IniWrite(nexts.Has("Buff")   ? nexts["Buff"]   : 1, tmp, "NextId", "Buff")
    IniWrite(nexts.Has("Thread") ? nexts["Thread"] : 1, tmp, "NextId", "Thread")

    FS_AtomicCommit(tmp, file, true)
}

; 只更新 ModifiedAt 并落盘
FS_Meta_Touch(profile) {
    if !IsObject(profile) {
        return
    }
    try {
        profile["Meta"]["ModifiedAt"] := PM_NowStr()
    } catch {
    }
    FS_Meta_Write(profile)
}