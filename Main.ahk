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
#Include "modules\util\Obj.ahk"
#Include "modules\util\IdGen.ahk"
#Include "modules\storage\model\_index.ahk"
#Include "modules\storage\profile\_index.ahk"
#Include "modules\logging\Logger.ahk"
#Include "modules\i18n\Lang.ahk"
#Include "modules\core\AppConfig.ahk"
#Include "modules\core\Core.ahk"
#Include "modules\engines\Rotation.ahk"
#Include "modules\engines\Pixel.ahk"
#Include "modules\engines\CastEngine.ahk"
#Include "modules\engines\RuleEngine.ahk"
#Include "modules\engines\BuffEngine.ahk"
#Include "modules\runtime\Counters.ahk"
#Include "modules\runtime\Poller.ahk"
#Include "modules\runtime\Hotkeys.ahk"
#Include "modules\workers\WorkerPool.ahk"
#Include "modules\storage\Exporter.ahk"
#Include "modules\ui\UI_Layout.ahk"
#Include "modules\ui\UI_Shell.ahk"
#Include "modules\gw2\GW2_DB.ahk"

; ========= Bootstrap =========
AppConfig_Init()
Lang_Init(AppConfig_Get("Language", "zh-CN"))

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
try {
    Logger_SetThrottlePerSec(0)
} catch {
}
env := Map()
env["arch"] := (A_PtrSize = 8) ? "x64" : "x86"
    env["admin"] := (A_IsAdmin ? "Admin" : "User")
    env["os"] := A_OSVersion
    Logger_Info("Core", "App start", env)
    Core_Init()
    ; 初始化 ID 生成器（建议从 AppConfig 读取）
    try {
        ID_Init(1)
    } catch {
    }
    UI_ShowMain()
    Logger_Info("UI", "Main shown", Map("hwnd", UI.Main.Hwnd))
    ; 退出时清理
    OnExit ExitCleanup
    ExitCleanup(*) {
        try Poller_Stop()
        try WorkerPool_Dispose()
        try Pixel_ROI_Dispose()
        try Logger_Flush()
        Logger_Info("Core", "App exit", Map())
        return 0
    }
