#Requires AutoHotkey v2
#SingleInstance Force
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"

; ========= Includes =========
#Include "modules\Utils.ahk"
#Include "modules\Core.ahk"
#Include "modules\Pixel.ahk"
#Include "modules\Storage.ahk"
#Include "modules\Poller.ahk"
#Include "modules\Hotkeys.ahk"
#Include "modules\Exporter.ahk"
#Include "modules\GUI_SkillEditor.ahk"
#Include "modules\GUI_Main.ahk"
#Include "modules\GUI_PointEditor.ahk"
#Include "modules\RuleEngine.ahk"
#Include "modules\GUI_RuleEditor.ahk"
#Include "modules\BuffEngine.ahk"
#Include "modules\GUI_BuffEditor.ahk"
#Include "modules\WorkerPool.ahk"
#Include "modules\GUI_Threads.ahk"
#Include "modules\Counters.ahk"
; ========= Bootstrap =========
Core_Init()
GUI_Main_Show()

; 退出时清理
OnExit ExitCleanup
ExitCleanup(*) {
    try Poller_Stop()
    try WorkerPool_Dispose()
    try Pixel_ROI_Dispose()
    return 0
}