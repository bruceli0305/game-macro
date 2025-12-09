#Requires AutoHotkey v2

; ======================================================
; KeyOut_QMK.ahk
; 仅包含 QMK / DLL 发送和内部资源管理
; 依赖于 KeyOut.ahk 中定义的全局变量
; ======================================================

KeyOut_Send_QMK(key, hidCode, delayMs, holdMs)
{
    global KeyOut_pSendKeyOp
    global KeyOut_Mode

    if (KeyOut_pSendKeyOp = 0 || KeyOut_Mode != "QMK")
    {
        KeyOut_DowngradeToHost(-1001)
        return KeyOut_Send_Host(key, delayMs, holdMs)
    }

    param := Map()
    param["Key"] := key
    param["HidCode"] := hidCode
    param["HoldMs"] := holdMs

    if (delayMs > 0)
    {
        cb := KeyOut_QMK_DownAndScheduleUp.Bind(param)
        SetTimer(cb, -delayMs)
    }
    else
    {
        KeyOut_QMK_DownAndScheduleUp(param)
    }

    return true
}

KeyOut_QMK_DownAndScheduleUp(param)
{
    global KeyOut_Mode
    global KeyOut_pSendKeyOp
    global KeyOut_DefaultTapMs

    if (!IsObject(param))
    {
        return
    }

    if (KeyOut_Mode != "QMK")
    {
        KeyOut_Send_Host(param["Key"], 0, param["HoldMs"])
        return
    }

    code := param["HidCode"]

    try
    {
        Logger_Info("KeyOut", "QMK down", Map("key", param["Key"], "code", code, "hold", param["HoldMs"]))
    }
    catch
    {
    }

    res := 0

    try
    {
        res := DllCall(KeyOut_pSendKeyOp, "UChar", 1, "UChar", code, "Int")
    }
    catch
    {
        res := -9999
    }

    if (res != 0)
    {
        try
        {
            Logger_Warn("KeyOut", "QMK down failed, downgrade", Map("code", code, "err", res))
        }
        catch
        {
        }

        KeyOut_DowngradeToHost(res)
        KeyOut_Send_Host(param["Key"], 0, param["HoldMs"])
        return
    }

    upDelay := 0
    if (param["HoldMs"] > 0)
    {
        upDelay := param["HoldMs"]
    }
    else
    {
        upDelay := KeyOut_DefaultTapMs
    }

    cb := KeyOut_QMK_Up.Bind(param)
    SetTimer(cb, -upDelay)
}

KeyOut_QMK_Up(param)
{
    global KeyOut_Mode
    global KeyOut_pSendKeyOp

    if (!IsObject(param))
    {
        return
    }

    if (KeyOut_Mode != "QMK")
    {
        return
    }

    code := param["HidCode"]

    try
    {
        Logger_Info("KeyOut", "QMK up", Map("key", param["Key"], "code", code))
    }
    catch
    {
    }

    res := 0

    try
    {
        res := DllCall(KeyOut_pSendKeyOp, "UChar", 2, "UChar", code, "Int")
    }
    catch
    {
        res := -9999
    }

    if (res != 0)
    {
        try
        {
            Logger_Warn("KeyOut", "QMK up failed, downgrade", Map("code", code, "err", res))
        }
        catch
        {
        }
        KeyOut_DowngradeToHost(res)
    }
}

KeyOut_DowngradeToHost(errCode)
{
    global KeyOut_Mode

    if (KeyOut_Mode != "QMK")
    {
        return
    }

    try
    {
        Logger_Warn("KeyOut", "Downgrade to Host", Map("err", errCode))
    }
    catch
    {
    }

    KeyOut_InternalCloseDevice()
    KeyOut_InternalFreeLibrary()
    KeyOut_Mode := "Host"
}

KeyOut_InternalCloseDevice()
{
    global KeyOut_pCloseDevice
    global KeyOut_pInitDevice
    global KeyOut_pSendKeyOp

    if (KeyOut_pCloseDevice != 0)
    {
        try
        {
            DllCall(KeyOut_pCloseDevice, "Int")
        }
        catch
        {
        }
    }

    KeyOut_pCloseDevice := 0
    KeyOut_pInitDevice := 0
    KeyOut_pSendKeyOp := 0
}

KeyOut_InternalFreeLibrary()
{
    global KeyOut_hModule

    if (KeyOut_hModule != 0)
    {
        try
        {
            DllCall("Kernel32.dll\FreeLibrary", "Ptr", KeyOut_hModule)
        }
        catch
        {
        }
    }

    KeyOut_hModule := 0
}