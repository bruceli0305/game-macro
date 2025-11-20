#Requires AutoHotkey v2
;modules\storage\profile\fs\Create.ahk 创建 Profile 文件夹并写入最小模块（meta/general/skills/points/rules）
Storage_Profile_Create(profileName) {
    p := PM_NewProfile(profileName)

    ; 创建文件夹
    folder := FS_ProfileFolder(profileName)

    ; 初始写 meta/general/skills/points/rules
    FS_Meta_Write(p)
    SaveModule_General(p)
    SaveModule_Skills(p)
    SaveModule_Points(p)
    SaveModule_Rules(p)

    return p
}