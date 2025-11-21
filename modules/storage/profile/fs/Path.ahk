#Requires AutoHotkey v2
;modules\storage\profile\fs\Path.ahk Profile 根目录（确保存在）

FS_ProfileFolder(profileName) {
    global App
    base := ""
    try {
        base := App["ProfilesDir"]
    } catch {
        base := A_ScriptDir "\Profiles"
    }
    dir := base "\" profileName
    try {
        DirCreate(dir)
    } catch {
    }
    return dir
}

; 模块 ini 文件路径
FS_ModulePath(profileName, moduleName) {
    dir := FS_ProfileFolder(profileName)
    file := ""
    if (moduleName = "meta") {
        file := dir "\meta.ini"
    } else if (moduleName = "general") {
        file := dir "\general.ini"
    } else if (moduleName = "skills") {
        file := dir "\skills.ini"
    } else if (moduleName = "points") {
        file := dir "\points.ini"
    } else if (moduleName = "rules") {
        file := dir "\rules.ini"
    } else if (moduleName = "buffs") {
        file := dir "\buffs.ini"
    } else if (moduleName = "rotation_base") {
        file := dir "\rotation_base.ini"
    } else if (moduleName = "rotation_tracks") {
        file := dir "\rotation_tracks.ini"
    } else if (moduleName = "rotation_gates") {
        file := dir "\rotation_gates.ini"
    } else if (moduleName = "rotation_opener") {
        file := dir "\rotation_opener.ini"
    } else {
        file := dir "\" moduleName ".ini"
    }
    return file
}