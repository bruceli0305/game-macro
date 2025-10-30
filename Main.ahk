#Requires AutoHotkey v2
#SingleInstance Force
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"

; ========= Includes =========
#Include "modules\util\Utils.ahk"
#Include "modules\i18n\Lang.ahk"
#Include "modules\core\AppConfig.ahk"
#Include "modules\core\Core.ahk"
#Include "modules\storage\Storage.ahk"
#Include "modules\engines\Pixel.ahk"
#Include "modules\engines\RuleEngine.ahk"
#Include "modules\engines\BuffEngine.ahk"
#Include "modules\runtime\Counters.ahk"
#Include "modules\runtime\Poller.ahk"
#Include "modules\runtime\Hotkeys.ahk"
#Include "modules\workers\WorkerPool.ahk"
#Include "modules\storage\Exporter.ahk"
#Include "modules\ui\pages\UI_Page_Config.ahk"
#Include "modules\ui\pages\UI_Page_Settings.ahk"
#Include "modules\ui\dialogs\UI_DefaultSkillDlg.ahk"
#Include "modules\ui\dialogs\GUI_SkillEditor.ahk"
#Include "modules\ui\dialogs\GUI_PointEditor.ahk"
#Include "modules\ui\dialogs\GUI_RuleEditor.ahk"
#Include "modules\ui\dialogs\GUI_BuffEditor.ahk"
#Include "modules\ui\dialogs\GUI_Threads.ahk"
#Include "modules\ui\UI_Layout.ahk"
#Include "modules\ui\UI_Shell.ahk"
; ========= Bootstrap =========
AppConfig_Init()
Lang_Init(AppConfig_Get("Language","zh-CN"))
Core_Init()
UI_ShowMain()

; 退出时清理
OnExit ExitCleanup
ExitCleanup(*) {
    try Poller_Stop()
    try WorkerPool_Dispose()
    try Pixel_ROI_Dispose()
    return 0
}