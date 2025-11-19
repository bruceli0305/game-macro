#Requires AutoHotkey v2
; modules\storage\profile\_index.ahk
; 聚合入口：统一 include + 对外 API
; 约定：所有 FS_Load_* 第二参数为普通参数（非 ByRef），对象本身为引用语义

; 依赖模型（Id/IdMap/IdUtil 等）
#Include "../model/_index.ahk"

; FS 工具
#Include "fs/Path.ahk"
#Include "fs/Atomic.ahk"
#Include "fs/Meta.ahk"
#Include "fs/List.ahk"
#Include "fs/Create.ahk"

; 运行时规范化
#Include "normalize/Runtime.ahk"

; 各业务模块（Save + Load）
#Include "modules/general/General.ahk"
#Include "modules/skills/Skills.ahk"
#Include "modules/points/Points.ahk"
#Include "modules/rules/Rules.ahk"
#Include "modules/buffs/Buffs.ahk"
#Include "modules/rotation/base/Base.ahk"
#Include "modules/rotation/tracks/Tracks.ahk"
#Include "modules/rotation/gates/Gates.ahk"
#Include "modules/rotation/opener/Opener.ahk"

; 阶段A加载：meta/general/skills/points/rules
Storage_Profile_Load(profileName) {
    p := PM_NewProfile(profileName)

    ; meta
    meta := FS_Meta_Read(profileName)
    p["Meta"] := meta

    ; general
    try {
        FS_Load_General(profileName, p)
    } catch {
    }

    ; skills
    try {
        FS_Load_Skills(profileName, p)
    } catch {
    }

    ; points
    try {
        FS_Load_Points(profileName, p)
    } catch {
    }

    ; rules
    try {
        FS_Load_Rules(profileName, p)
    } catch {
    }

    ; 构建 IdMap（便于后续引用/校验）
    PM_BuildIdMaps(p)
    return p
}

; 完整加载：阶段A + Buffs/RotationBase/Tracks/Gates/Opener
Storage_Profile_LoadFull(profileName) {
    p := Storage_Profile_Load(profileName)

    try {
        FS_Load_Buffs(profileName, p)
    } catch {
    }
    try {
        FS_Load_RotationBase(profileName, p)
    } catch {
    }
    try {
        FS_Load_Tracks(profileName, p)
    } catch {
    }
    try {
        FS_Load_Gates(profileName, p)
    } catch {
    }
    try {
        FS_Load_Opener(profileName, p)
    } catch {
    }

    PM_BuildIdMaps(p)
    return p
}

; 可选：保存所有模块（用于克隆或一次性写回）
Storage_Profile_SaveAll(profile) {
    if !IsObject(profile) {
        return false
    }

    ok := true
    try {
        FS_Meta_Write(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_General(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Skills(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Points(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Rules(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Buffs(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_RotationBase(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Tracks(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Gates(profile)
    } catch {
        ok := false
    }
    try {
        SaveModule_Opener(profile)
    } catch {
        ok := false
    }

    return ok
}