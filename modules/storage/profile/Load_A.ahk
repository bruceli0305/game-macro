#Requires AutoHotkey v2

; 仅加载：meta/general/skills/points/rules（阶段A）
Storage_Profile_Load(profileName) {
    p := PM_NewProfile(profileName)

    ; meta
    meta := FS_Meta_Read(profileName)
    p["Meta"] := meta

    ; general
    FS_Load_General(profileName, p)

    ; skills
    FS_Load_Skills(profileName, p)

    ; points
    FS_Load_Points(profileName, p)

    ; rules
    FS_Load_Rules(profileName, p)

    ; 构建 IdMap
    PM_BuildIdMaps(p)
    return p
}