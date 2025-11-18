; _index.ahk
;页面聚合器：先引入框架，再引入所有页面
#Requires AutoHotkey v2

; pages aggregator: include framework first, then all pages

; framework (必须先引入，提供 UI_GetPageRect 等通用函数)
#Include "..\UI_Framework.ahk"
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

; 新增：轮换配置子页（第一步：常规、轨道）
#Include "advanced\rotation\Page_RotGen.ahk"
#Include "advanced\rotation\Page_RotTracks.ahk"
#Include "advanced\rotation\Page_RotGates.ahk"
#Include "advanced\rotation\Page_RotOpener.ahk"

; tools
#Include "tools\Page_Tools_IO.ahk"
#Include "tools\Page_Tools_Quick.ahk"

; settings
#Include "settings\Page_Settings_Lang.ahk"
#Include "settings\Page_Settings_About.ahk"