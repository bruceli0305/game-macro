#Requires AutoHotkey v2
; Main.ahk
; 若未以管理员运行，则自举为管理员
if !A_IsAdmin {
    try {
        Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"'
    }
    ExitApp
}

#SingleInstance Force
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"

; 设置应用程序图标
if FileExist(A_ScriptDir "\assets\icon.ico") {
    TraySetIcon(A_ScriptDir "\assets\icon.ico", , 1)
}

; ========= Includes =========
#Include "modules\util\Utils.ahk"
#Include "modules\logging\Logger.ahk"
#Include "modules\i18n\Lang.ahk"
#Include "modules\core\AppConfig.ahk"
#Include "modules\core\Core.ahk"
#Include "modules\storage\Storage.ahk"
#Include "modules\engines\Rotation.ahk"
#Include "modules\engines\Dup.ahk"
#Include "modules\engines\Pixel.ahk"
#Include "modules\engines\RuleEngine.ahk"
#Include "modules\engines\BuffEngine.ahk"
#Include "modules\runtime\Counters.ahk"
#Include "modules\runtime\Poller.ahk"
#Include "modules\runtime\Hotkeys.ahk"
#Include "modules\workers\WorkerPool.ahk"
#Include "modules\storage\Exporter.ahk"
#Include "modules\ui\dialogs\GUI_SkillEditor.ahk"
#Include "modules\ui\dialogs\GUI_PointEditor.ahk"
#Include "modules\ui\dialogs\GUI_RuleEditor.ahk"
#Include "modules\ui\dialogs\GUI_BuffEditor.ahk"
#Include "modules\ui\UI_Layout.ahk"
#Include "modules\ui\UI_Shell.ahk"
; ========= Bootstrap =========
AppConfig_Init()
Lang_Init(AppConfig_Get("Language","zh-CN"))

opts := Map()
opts["Level"] := AppConfig_GetLog("Level", "INFO")
opts["RotateSizeMB"] := AppConfig_GetLog("RotateSizeMB", 10)
opts["RotateKeep"] := AppConfig_GetLog("RotateKeep", 5)
opts["EnableMemory"] := true
opts["MemoryCap"] := 10000
opts["EnablePipe"] := true
opts["PipeName"] := "GW2_LogSink"
opts["PipeClient"] := false
opts["PerCategory"] := AppConfig_GetLog("PerCategory", "")
opts["ThrottlePerSec"] := AppConfig_GetLog("ThrottlePerSec", 5)
Logger_Init(opts)

env := Map()
env["arch"] := (A_PtrSize = 8) ? "x64" : "x86"
env["admin"] := (A_IsAdmin ? "Admin" : "User")
env["os"] := A_OSVersion
Logger_Info("Core", "App start", env)
Core_Init()
try {
    Dup_InitAuto()   ; 如果 EnumOutputs=0，将直接返回 false，不创建线程
}

UI_ShowMain()
Logger_Info("UI", "Main shown", Map("hwnd", UI.Main.Hwnd))
; 退出时清理
OnExit ExitCleanup
ExitCleanup(*) {
    try Poller_Stop()
    try WorkerPool_Dispose()
    try Pixel_ROI_Dispose()
    try DX_Shutdown()
    try Logger_Flush()
    Logger_Info("Core", "App exit", Map())
    return 0
}