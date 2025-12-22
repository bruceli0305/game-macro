#Requires AutoHotkey v2
#SingleInstance Force

Test_Main()
{
    dllPath := A_ScriptDir "\modules\lib\KeyDispenserDLL.dll"

    arch := ""
    if (A_PtrSize = 8)
    {
        arch := "x64"
    }
    else
    {
        arch := "x86"
    }

    msg := "== 环境信息 ==" . "`n"
    msg .= "A_ScriptDir: " . A_ScriptDir . "`n"
    msg .= "arch (AHK): " . arch . "`n"
    msg .= "`n== DLL 路径 ==" . "`n"
    msg .= dllPath . "`n"
    msg .= "存在: " . (FileExist(dllPath) ? "是" : "否") . "`n"

    MsgBox msg

    if (!FileExist(dllPath))
    {
        MsgBox "DLL 文件不存在，测试结束。"
        return
    }

    ; 尝试 LoadLibraryW
    hMod := DllCall("Kernel32.dll\LoadLibraryW", "WStr", dllPath, "Ptr")
    err := DllCall("Kernel32.dll\GetLastError", "UInt")

    msg2 := "== LoadLibraryW 结果 ==" . "`n"
    msg2 .= "hModule: " . hMod . "`n"
    msg2 .= "GetLastError: " . err . "`n"
    msg2 .= "错误文本: " . GetLastErrorText(err)

    MsgBox msg2

    if (hMod = 0)
    {
        MsgBox "LoadLibraryW 返回 0，DLL 无法加载。根据上面的错误码/文本排查位数或依赖问题。"
        return
    }

    ; 测试获取函数地址
    pInit := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hMod, "AStr", "InitDevice", "Ptr")
    pSend := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hMod, "AStr", "SendKeyOp", "Ptr")
    pClose := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hMod, "AStr", "CloseDevice", "Ptr")

    msg3 := "== GetProcAddress 结果 ==" . "`n"
    msg3 .= "InitDevice: " . pInit . "`n"
    msg3 .= "SendKeyOp : " . pSend . "`n"
    msg3 .= "CloseDevice: " . pClose . "`n"

    MsgBox msg3

    if (pInit = 0 || pSend = 0 || pClose = 0)
    {
        MsgBox "有导出函数地址为 0，检查 DLL 是否正确导出 InitDevice/SendKeyOp/CloseDevice。"
        DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)
        return
    }

    ; 调用 InitDevice 测试
    initRes := 0
    try
    {
        initRes := DllCall(pInit, "Int")
    }
    catch
    {
        initRes := -9999
    }

    msg4 := "== InitDevice 调用结果 ==" . "`n"
    msg4 .= "返回值: " . initRes . "`n"
    msg4 .= "(0 表示成功，其他为错误码，由 DLL 内部定义)"

    MsgBox msg4

    ; 调用 CloseDevice 测试
    closeRes := 0
    try
    {
        closeRes := DllCall(pClose, "Int")
    }
    catch
    {
        closeRes := -9999
    }

    msg5 := "== CloseDevice 调用结果 ==" . "`n"
    msg5 .= "返回值: " . closeRes . "`n"

    MsgBox msg5

    ; 释放模块
    DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)

    MsgBox "测试结束。"
}

GetLastErrorText(err)
{
    if (err = 0)
    {
        return ""
    }

    flags := 0x00001000 | 0x00000200  ; FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS
    buf := Buffer(2048, 0)

    len := DllCall(
        "Kernel32.dll\FormatMessageW"
        , "UInt", flags
        , "Ptr", 0
        , "UInt", err
        , "UInt", 0
        , "Ptr", buf
        , "UInt", 1024
        , "Ptr", 0
        , "UInt"
    )

    if (len = 0)
    {
        return ""
    }

    text := StrGet(buf, "UTF-16")
    ; 去掉结尾换行
    text := Trim(text, "`r`n`t ")
    return text
}

Test_Main()