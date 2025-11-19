#Requires AutoHotkey v2
;modules\storage\profile\Load_B.ahk 加载 Buffs + Rotation Base/Tracks/Gates/Opener
FS_Load_B(profileName, &profile) {
    FS_Load_Buffs(profileName, profile)
    FS_Load_RotationBase(profileName, profile)
    FS_Load_Tracks(profileName, profile)
    FS_Load_Gates(profileName, profile)
    FS_Load_Opener(profileName, profile)
}

; 一次性加载完整 Profile（A + B）
Storage_Profile_LoadFull(profileName) {
    p := Storage_Profile_Load(profileName)         ; 已加载 meta/general/skills/points/rules
    FS_Load_B(profileName, p)                      ; 加载其余模块
    PM_BuildIdMaps(p)
    return p
}