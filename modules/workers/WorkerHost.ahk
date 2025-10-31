#Requires AutoHotkey v2
#SingleInstance Off
#NoTrayIcon
OnExit (*) => ExitApp()

;================ 日志工具（写到项目根 Logs） ================
Host_Log(title, msg) {
    ; 从 modules 目录回到项目根
    root := RegExReplace(A_ScriptDir, "\\modules$", "")
    logDir := root "\Logs"
    DirCreate logDir
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend ts " [WorkerHost " title "] " msg "`r`n"
        , logDir "\workerhost_" title ".log", "UTF-8"
}

;================ 一次性模式：--fire key delay hold ================
if (A_Args.Length >= 1 && A_Args[1] = "--fire") {
    key   := (A_Args.Length >= 2) ? A_Args[2] : ""
    delay := (A_Args.Length >= 3) ? Integer(A_Args[3]) : 0
    hold  := (A_Args.Length >= 4) ? Integer(A_Args[4]) : 0

    pid := DllCall("Kernel32.dll\GetCurrentProcessId", "UInt")
    Host_Log("FIRE", "start pid=" pid " key=" key " delay=" delay " hold=" hold)
    WorkerHost_SendKey(key, delay, hold)
    Host_Log("FIRE", "sent  key=" key " delay=" delay " hold=" hold)
    ExitApp
}

;================ 常驻模式（进程池用） ================
; 用一个最小 GUI 窗口作为 WM_COPYDATA 的接收端（强烈推荐）
global HostTitle := (A_Args.Length ? A_Args[1] : "GW2_Worker")

g := Gui("+ToolWindow", HostTitle)
g.Show("w1 h1 Hide")                 ; 创建一个 1x1 的隐藏窗口
hwnd := g.Hwnd

; 先注册回调，避免漏第一条 WM_COPYDATA
OnMessage(0x004A, OnCopyData)        ; WM_COPYDATA

; 写握手文件：父进程读取此 hwnd 作为接收端
readyFile := A_Temp "\" HostTitle ".ready"
try FileDelete readyFile
FileAppend hwnd, readyFile

pid := DllCall("Kernel32.dll\GetCurrentProcessId", "UInt")
Host_Log(HostTitle, "start pid=" pid " hwnd=" hwnd " ready=" readyFile)

;================ WM_COPYDATA 回调（接收端=上面的 GUI 窗口） ================
OnCopyData(wParam, lParam, msg, hwndFrom) {
    global HostTitle
    ; 按标准 COPYDATASTRUCT 读取：dwData(UPtr)、cbData(DWORD/UInt)、lpData(PVOID/Ptr)
    cb := NumGet(lParam, A_PtrSize, "UInt")
    p  := NumGet(lParam, A_PtrSize*2, "Ptr")
    if (cb <= 0 || p = 0) {
        Host_Log(HostTitle, "recv invalid COPYDATASTRUCT cb=" cb " ptr=" p)
        return 0
    }

    text := StrGet(p, "UTF-16")  ; cb 为总字节数(含终止零)，StrGet 可直接取
    Host_Log(HostTitle, "recv wParam=" wParam " text=" text)

    parts := StrSplit(text, "|")
    if (parts.Length < 1)
        return 0

    cmd := parts[1]
    if (cmd = "SK") {
        key   := (parts.Length >= 2) ? parts[2] : ""
        delay := (parts.Length >= 3) ? Integer(parts[3]) : 0
        hold  := (parts.Length >= 4) ? Integer(parts[4]) : 0

        WorkerHost_SendKey(key, delay, hold)
        Host_Log(HostTitle, "sent key=" key " delay=" delay " hold=" hold)
        return 1        ; 非 0 表示“已处理”
    }
    return 0
}

;================ 统一发键（标准多行写法） ================
WorkerHost_SendKey(key, delay := 0, hold := 0) {
    if (delay > 0)
        Sleep delay
    if (key = "")
        return

    mouseRe := "i)^(LButton|MButton|RButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight)$"

    ; 按住优先：仅对功能/鼠标键做 down/up；其它复杂发送原样
    if (hold > 0) {
        if RegExMatch(key, "[\{\}\^\!\+#]") {
            SendEvent key
            return
        }
        if RegExMatch(key
            , "i)^(F([1-9]|1[0-9]|2[0-4])|Tab|Enter|Space|Backspace|Delete|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|Esc|Escape|AppsKey|PrintScreen|Pause|ScrollLock|CapsLock|NumLock|LWin|RWin|Numpad(Enter|Add|Sub|Mult|Div|\d+))$") {
            SendEvent "{" key " down}"
            Sleep hold
            SendEvent "{" key " up}"
            return
        }
        if RegExMatch(key, mouseRe) && !RegExMatch(key, "i)^Wheel") {
            SendEvent "{" key " down}"
            Sleep hold
            SendEvent "{" key " up}"
            return
        }
        ; 其它情况无法可靠 down/up，按一次
        SendEvent "{" key "}"
        return
    }

    ; 非按住
    if RegExMatch(key, "[\{\}\^\!\+#]") {
        SendEvent key
        return
    }
    if RegExMatch(key
        , "i)^(F([1-9]|1[0-9]|2[0-4])|Tab|Enter|Space|Backspace|Delete|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|Esc|Escape|AppsKey|PrintScreen|Pause|ScrollLock|CapsLock|NumLock|LWin|RWin|Numpad(Enter|Add|Sub|Mult|Div|\d+))$") {
        SendEvent "{" key "}"
        return
    }
    if RegExMatch(key, mouseRe) {
        SendEvent "{" key "}"
        return
    }

    SendEvent key
}