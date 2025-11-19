#Requires AutoHotkey v2
;modules\storage\profile\Load_B.ahk 加载 Buffs + Rotation Base/Tracks/Gates/Opener
FS_Load_B(profileName, profile) {
    FS_Load_Buffs(profileName, profile)
    FS_Load_RotationBase(profileName, profile)
    FS_Load_Tracks(profileName, profile)
    FS_Load_Gates(profileName, profile)
    FS_Load_Opener(profileName, profile)
}

Storage_Profile_LoadFull(profileName) {
    p := Storage_Profile_Load(profileName)
    FS_Load_B(profileName, p)
    PM_BuildIdMaps(p)
    return p
}