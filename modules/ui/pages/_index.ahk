#Requires AutoHotkey v2

; pages aggregator: include framework first, then all pages

; framework
#Include "..\UI_Framework.ahk"

; rotation adapters and utils (先于页面)
#Include "..\rotation\adapters\Rot_MapIndexId.ahk"
#Include "..\rotation\adapters\Rot_PageUtil.ahk"
#Include "..\rotation\adapters\Rot_SaveBase.ahk"
#Include "..\rotation\adapters\Rot_SaveTracks.ahk"
#Include "..\rotation\adapters\Rot_SaveGates.ahk"
#Include "..\rotation\adapters\Rot_SaveOpener.ahk"

; profile API（先于其他页）
#Include "profile\Page_Profile_API.ahk"

; profile
#Include "profile\Page_Profile.ahk"

; data
#Include "data\Page_Skills.ahk"
#Include "data\Page_Points.ahk"
#Include "data\Page_DefaultSkill.ahk"

; automation
#Include "automation\Page_Rules_Summary.ahk"
#Include "automation\Page_Buffs_Summary.ahk"
#Include "automation\Page_Threads_Summary.ahk"

; advanced
#Include "advanced\Page_Rotation_Summary.ahk"
#Include "advanced\Page_Diag.ahk"
#Include "advanced\Page_Logs.ahk"
#Include "advanced\Page_CastDebug.ahk"
; 新增：轮换配置子页（第一步：常规、轨道）
#Include "advanced\rotation\Page_RotGen.ahk"
#Include "advanced\rotation\Page_RotTracks.ahk"
#Include "advanced\rotation\Page_RotGates.ahk"
#Include "advanced\rotation\Page_RotOpener.ahk"

; tools
#Include "tools\Page_Tools_Quick.ahk"

; settings
#Include "settings\Page_Settings_Lang.ahk"
#Include "settings\Page_Settings_About.ahk"