#Requires AutoHotkey v2

; ======================================================
; KeyOut.ahk 统一键输出后端：
; - Mode = "QMK": 通过 DLL + Pro Micro 发送可映射的键盘键
; - Mode = "Host": 回退到原 WorkerHost + SendEvent 逻辑
; ======================================================

#Include "KeyMap.ahk"
#Include "KeyOut_QMK.ahk"

global KeyOut_Mode := "Host"
global KeyOut_DllPath := A_ScriptDir "\modules\lib\KeyDispenserDLL.dll"
global KeyOut_hModule := 0
global KeyOut_pInitDevice := 0
global KeyOut_pSendKeyOp := 0
global KeyOut_pCloseDevice := 0
global KeyOut_DefaultTapMs := 40  ; QMK 点按默认按下时长(ms)

; ========== 对外 API ==========

KeyOut_Init()
{
    global KeyOut_Mode
    global KeyOut_DllPath
    global KeyOut_hModule
    global KeyOut_pInitDevice
    global KeyOut_pSendKeyOp
    global KeyOut_pCloseDevice

    if (KeyOut_Mode = "QMK")
    {
        return
    }

    try
    {
        Logger_Info("KeyOut", "Init begin", Map("dll", KeyOut_DllPath))
    }
    catch
    {
    }

    if (!FileExist(KeyOut_DllPath))
    {
        KeyOut_Mode := "Host"
        try
        {
            Logger_Info("KeyOut", "DLL not found, use Host mode", Map())
        }
        catch
        {
        }
        return
    }

    KeyOut_hModule := DllCall("Kernel32.dll\LoadLibraryW", "WStr", KeyOut_DllPath, "Ptr")
    if (KeyOut_hModule = 0)
    {
        KeyOut_Mode := "Host"
        try
        {
            Logger_Warn("KeyOut", "LoadLibrary failed, use Host mode", Map())
        }
        catch
        {
        }
        return
    }

    KeyOut_pInitDevice := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", KeyOut_hModule
        , "AStr", "InitDevice"
        , "Ptr")

    KeyOut_pSendKeyOp := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", KeyOut_hModule
        , "AStr", "SendKeyOp"
        , "Ptr")

    KeyOut_pCloseDevice := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", KeyOut_hModule
        , "AStr", "CloseDevice"
        , "Ptr")

    if (KeyOut_pInitDevice = 0 || KeyOut_pSendKeyOp = 0 || KeyOut_pCloseDevice = 0)
    {
        try
        {
            Logger_Warn("KeyOut", "GetProcAddress failed, use Host mode", Map())
        }
        catch
        {
        }

        KeyOut_InternalFreeLibrary()
        KeyOut_Mode := "Host"
        return
    }

    result := 0
    try
    {
        result := DllCall(KeyOut_pInitDevice, "Int")
    }
    catch
    {
        result := -9999
    }

    if (result != 0)
    {
        try
        {
            Logger_Warn("KeyOut", "InitDevice failed, fallback Host", Map("err", result))
        }
        catch
        {
        }

        KeyOut_InternalCloseDevice()
        KeyOut_InternalFreeLibrary()
        KeyOut_Mode := "Host"
        return
    }

    KeyOut_Mode := "QMK"
    try
    {
        Logger_Info("KeyOut", "QMK mode enabled", Map())
    }
    catch
    {
    }
}

KeyOut_Shutdown()
{
    global KeyOut_Mode

    if (KeyOut_Mode = "QMK")
    {
        KeyOut_InternalCloseDevice()
        KeyOut_InternalFreeLibrary()
    }

    KeyOut_Mode := "Host"
}

KeyOut_Reinit()
{
    global KeyOut_Mode

    success := false

    try
    {
        Logger_Info("KeyOut", "Reinit begin", Map("mode", KeyOut_Mode))
    }
    catch
    {
    }

    if (KeyOut_Mode = "QMK")
    {
        return true
    }

    KeyOut_InternalCloseDevice()
    KeyOut_InternalFreeLibrary()

    KeyOut_Init()

    if (KeyOut_Mode = "QMK")
    {
        success := true
    }
    else
    {
        success := false
    }

    try
    {
        Logger_Info("KeyOut", "Reinit end", Map("success", success, "mode", KeyOut_Mode))
    }
    catch
    {
    }

    return success
}

; 统一发键入口：key=字符串，delayMs=预延时, holdMs=按住时长(ms)
KeyOut_Send(key, delayMs := 0, holdMs := 0)
{
    global KeyOut_Mode

    s := Trim(key)
    if (s = "")
    {
        return false
    }

    try
    {
        Logger_Info("KeyOut", "Send request", Map("key", s, "delay", delayMs, "hold", holdMs, "mode", KeyOut_Mode))
    }
    catch
    {
    }

    if (KeyOut_Mode = "QMK")
    {
        info := KeyMap_ResolveKey(s)
        if (info.Has("CanQmk") && info["CanQmk"])
        {
            code := info["HidCode"]
            if (code > 0 && code < 256)
            {
                KeyOut_Send_QMK(s, code, delayMs, holdMs)
                return true
            }

            try
            {
                Logger_Warn("KeyOut", "ResolveKey returned invalid code, fallback Host", info)
            }
            catch
            {
            }
            return KeyOut_Send_Host(s, delayMs, holdMs)
        }
        else
        {
            return KeyOut_Send_Host(s, delayMs, holdMs)
        }
    }
    else
    {
        return KeyOut_Send_Host(s, delayMs, holdMs)
    }
}

; 针对 Skill 对象的发键（使用预计算 HidCode）
KeyOut_SendSkill(skill, delayMs := 0, holdMs := 0)
{
    global KeyOut_Mode

    if (!IsObject(skill))
    {
        return false
    }

    key := ""
    hid := 0

    if (HasProp(skill, "Key"))
    {
        key := skill.Key
    }

    if (HasProp(skill, "HidCode"))
    {
        hid := skill.HidCode
    }

    if (KeyOut_Mode = "QMK")
    {
        if (hid > 0 && hid < 256)
        {
            try
            {
                Logger_Info("KeyOut", "Send skill via QMK", Map("key", key, "code", hid, "delay", delayMs, "hold", holdMs))
            }
            catch
            {
            }
            KeyOut_Send_QMK(key, hid, delayMs, holdMs)
            return true
        }

        try
        {
            Logger_Info("KeyOut", "Skill has no valid HidCode, fallback Host", Map("key", key, "code", hid))
        }
        catch
        {
        }
    }

    return KeyOut_Send_Host(key, delayMs, holdMs)
}

; ========== Host 通道（原 WorkerHost） ==========

KeyOut_Send_Host(key, delayMs, holdMs)
{
    ok := false
    try
    {
        ok := WorkerPool_FireAndForget(key, delayMs, holdMs)
    }
    catch
    {
        ok := false
    }

    if (!ok)
    {
        try
        {
            Logger_Warn("KeyOut", "Host send FAIL", Map("key", key, "delay", delayMs, "hold", holdMs))
        }
        catch
        {
        }
    }

    return ok
}