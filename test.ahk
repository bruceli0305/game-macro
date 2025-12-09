#Requires AutoHotkey v2.0
#SingleInstance Force

; ================= 全局变量 =================

global g_dllPath      := A_ScriptDir "\modules\lib\KeyDispenserDLL.dll"
global g_hModule      := 0          ; LoadLibrary 返回的模块句柄
global g_pInitDevice  := 0          ; InitDevice 函数指针
global g_pSendKeyOp   := 0          ; SendKeyOp 函数指针
global g_pCloseDevice := 0          ; CloseDevice 函数指针
global g_deviceReady  := false      ; 是否已经成功 InitDevice


; ================= DLL 载入与函数地址获取 =================

LoadKeyDispenserDLL()
{
    global g_dllPath
    global g_hModule
    global g_pInitDevice
    global g_pSendKeyOp
    global g_pCloseDevice

    if (g_hModule != 0)
    {
        return
    }

    if (!FileExist(g_dllPath))
    {
        MsgBox "找不到 DLL 文件:`n" g_dllPath
        return
    }

    ; 使用 Unicode 版本 LoadLibraryW
    g_hModule := DllCall("Kernel32.dll\LoadLibraryW", "WStr", g_dllPath, "Ptr")
    if (g_hModule = 0)
    {
        MsgBox "LoadLibraryW 失败:`n" g_dllPath
        return
    }

    g_pInitDevice := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", g_hModule
        , "AStr", "InitDevice"
        , "Ptr")

    g_pSendKeyOp := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", g_hModule
        , "AStr", "SendKeyOp"
        , "Ptr")

    g_pCloseDevice := DllCall("Kernel32.dll\GetProcAddress"
        , "Ptr", g_hModule
        , "AStr", "CloseDevice"
        , "Ptr")

    if (g_pInitDevice = 0 || g_pSendKeyOp = 0 || g_pCloseDevice = 0)
    {
        MsgBox "GetProcAddress 失败，可能导出名不匹配。"
        return
    }
}


; ================= 对 DLL 的封装函数 =================

InitKeyDispenser()
{
    global g_deviceReady
    global g_pInitDevice

    if (g_deviceReady)
    {
        return
    }

    LoadKeyDispenserDLL()
    if (g_pInitDevice = 0)
    {
        return
    }

    result := DllCall(g_pInitDevice, "Int")
    if (result != 0)
    {
        MsgBox "InitDevice 调用失败，返回值: " result
        return
    }

    g_deviceReady := true
}

SendKeyOp(op, keyCode)
{
    global g_deviceReady
    global g_pSendKeyOp

    if (!g_deviceReady)
    {
        InitKeyDispenser()
    }

    if (!g_deviceReady)
    {
        return
    }

    if (g_pSendKeyOp = 0)
    {
        MsgBox "SendKeyOp 函数指针无效。"
        return
    }

    result := DllCall(g_pSendKeyOp
        , "UChar", op
        , "UChar", keyCode
        , "Int")

    if (result != 0)
    {
        MsgBox "SendKeyOp 调用失败，op=" op ", keyCode=" keyCode ", 返回值: " result
    }
}

SendKeyDown(keyCode)
{
    ; op = 1 -> 按下
    SendKeyOp(1, keyCode)
}

SendKeyUp(keyCode)
{
    ; op = 2 -> 松开
    SendKeyOp(2, keyCode)
}

SendKeyTap(keyCode, delayMs := 50)
{
    SendKeyDown(keyCode)
    Sleep delayMs
    SendKeyUp(keyCode)
}


; ================= 退出清理 =================

ExitCleanup(exitReason, exitCode)
{
    global g_deviceReady
    global g_pCloseDevice
    global g_hModule

    if (g_deviceReady && g_pCloseDevice != 0)
    {
        DllCall(g_pCloseDevice, "Int")
        g_deviceReady := false
    }

    if (g_hModule != 0)
    {
        DllCall("Kernel32.dll\FreeLibrary", "Ptr", g_hModule)
        g_hModule := 0
    }
}

OnExit(ExitCleanup)


; ================= 启动时先尝试初始化一次 =================

InitKeyDispenser()


; ================= 示例热键 =================
; 注意：这里的 keyCode 是 HID 键码 / QMK 键码：
;   4 = KC_A
;   5 = KC_B
;   6 = KC_C
;   ...
; 你的固件里：raw_hid_receive 把 data[1] 直接传给 register_code(key)，
; 所以这里用的就是 QMK 标准 keycode。

; F9: 让 Pro Micro “点按” A 键
F9::
{
    SendKeyTap(4)  ; KC_A
}

; F10: 让 Pro Micro “点按” B 键
F10::
{
    SendKeyTap(5)  ; KC_B
}

; F11: 按下 A 不松开
F11::
{
    SendKeyDown(4)
}

; F12: 松开 A
F12::
{
    SendKeyUp(4)
}