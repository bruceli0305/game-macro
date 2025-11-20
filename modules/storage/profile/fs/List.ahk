#Requires AutoHotkey v2
;modules\storage\profile\fs\List.ahk 列出 Profiles 目录下“有效配置”（含 meta.ini 的子目录）
FS_ListProfilesValid() {
    global App
    list := []
    base := ""
    try {
        base := App["ProfilesDir"]
    } catch {
        base := A_ScriptDir "\Profiles"
    }

    ; 确保目录存在
    try {
        DirCreate(base)
    } catch {
    }

    loop files, base "\*", "D" {
        name := A_LoopFileName
        meta := base "\" name "\meta.ini"
        if FileExist(meta) {
            list.Push(name)
        }
    }
    return list
}

; 仍保留“所有子目录”列表（如你有别处需要）
FS_ListProfiles() {
    global App
    list := []
    base := ""
    try {
        base := App["ProfilesDir"]
    } catch {
        base := A_ScriptDir "\Profiles"
    }
    try {
        DirCreate(base)
    } catch {
    }
    loop files, base "\*", "D" {
        list.Push(A_LoopFileName)
    }
    return list
}

; 递归删除 Profile 文件夹（无变化）
FS_DeleteProfile(profileName) {
    global App
    dir := App["ProfilesDir"] "\" profileName
    if !DirExist(dir) {
        return
    }
    try {
        DirDelete(dir, true)
    } catch {
    }
}