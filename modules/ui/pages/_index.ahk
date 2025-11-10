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

; tools
#Include "tools\Page_Tools_IO.ahk"
#Include "tools\Page_Tools_Quick.ahk"

; settings
#Include "settings\Page_Settings_Lang.ahk"
#Include "settings\Page_Settings_About.ahk"