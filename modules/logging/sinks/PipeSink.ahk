#Requires AutoHotkey v2
;modules\logging\sinks\PipeSink.ahk

global g_Pipe := Map()

PipeSink_SetHandler(fn) {
    global g_Pipe
    g_Pipe["Handler"] := fn
}

PipeSink_ServerStart(name := "GW2_LogSink") {
    global g_Pipe
    PipeSink_ServerStop()

    g_Pipe["Name"] := "" name
    g_Pipe["TimerOn"] := false
    g_Pipe["hSlot"] := 0

    path := "\\.\mailslot\" . name

    h := 0
    ok := 0
    try {
        h := DllCall("Kernel32\CreateMailslotW"
            , "WStr", path
            , "UInt", 0
            , "UInt", 0xFFFFFFFF
            , "Ptr",  0
            , "Ptr")
        if (h = -1) {
            throw Error("CreateMailslotW failed")
        }
        g_Pipe["hSlot"] := h
        try {
            SetTimer(PipeSink_ServerTick(), 20)
        } catch {
        }
        g_Pipe["TimerOn"] := true
    } catch {
        if (h && h != -1) {
            DllCall("Kernel32\CloseHandle", "Ptr", h)
        }
        g_Pipe["hSlot"] := 0
    }
}

PipeSink_ServerStop() {
    global g_Pipe
    if g_Pipe.Has("TimerOn") {
        if g_Pipe["TimerOn"] {
            try {
                SetTimer(PipeSink_ServerTick(), 0)
            } catch {
            }
            g_Pipe["TimerOn"] := false
        }
    }
    if g_Pipe.Has("hSlot") {
        if (g_Pipe["hSlot"] && g_Pipe["hSlot"] != -1) {
            try {
                DllCall("Kernel32\CloseHandle", "Ptr", g_Pipe["hSlot"])
            } catch {
            }
            g_Pipe["hSlot"] := 0
        }
    }
}

PipeSink_ServerTick() {
    global g_Pipe
    h := 0
    try {
        h := g_Pipe["hSlot"]
    } catch {
        h := 0
    }
    if (h = 0 || h = -1) {
        return
    }

    cbMsg := 0
    cnt := 0
    tail := 0
    ok := 0

    ok := DllCall("Kernel32\GetMailslotInfo"
        , "Ptr", h, "UInt*", 0, "UInt*", &cbMsg, "UInt*", &cnt, "UInt*", &tail
        , "Int")
    if (ok = 0) {
        return
    }

    if (cbMsg = 0xFFFFFFFF) {
        return
    }

    loop {
        cbMsg := 0
        cnt := 0
        tail := 0
        ok := DllCall("Kernel32\GetMailslotInfo"
            , "Ptr", h, "UInt*", 0, "UInt*", &cbMsg, "UInt*", &cnt, "UInt*", &tail
            , "Int")
        if (ok = 0) {
            break
        }
        if (cbMsg = 0xFFFFFFFF || cbMsg = 0) {
            break
        }

        buf := Buffer(cbMsg, 0)
        read := 0
        ok := DllCall("Kernel32\ReadFile"
            , "Ptr", h, "Ptr", buf.Ptr, "UInt", cbMsg, "UInt*", &read, "Ptr", 0
            , "Int")
        if (ok = 0 || read = 0) {
            break
        }

        text := ""
        try {
            text := StrGet(buf.Ptr, read, "UTF-8")
        } catch {
            text := ""
        }
        if (text != "") {
            PipeSink__OnLine(text)
        }
    }
}

PipeSink__OnLine(text) {
    global g_Pipe
    if g_Pipe.Has("Handler") {
        fn := g_Pipe["Handler"]
        if IsObject(fn) {
            try {
                fn.Call(text)
            } catch {
            }
        }
    }
}

PipeSink_ClientSend(name, text) {
    path := "\\.\mailslot\" . name
    h := 0
    ok := 0
    success := false

    try {
        h := DllCall("Kernel32\CreateFileW"
            , "WStr", path
            , "UInt", 0x40000000
            , "UInt", 0x00000000
            , "Ptr",  0
            , "UInt", 3
            , "UInt", 0
            , "Ptr",  0
            , "Ptr")
        if (h = -1) {
            return false
        }

        line := "" text
        if !(SubStr(line, -1) = "`n") {
            line := line . "`r`n"
        }

        bytes := StrPut(line, "UTF-8") - 1
        buf := Buffer(bytes, 0)
        StrPut(line, buf, "UTF-8")

        written := 0
        ok := DllCall("Kernel32\WriteFile"
            , "Ptr", h, "Ptr", buf.Ptr, "UInt", bytes, "UInt*", &written, "Ptr", 0
            , "Int")
        if (ok != 0) {
            success := true
        } else {
            success := false
        }
    } catch {
        success := false
    } finally {
        if (h && h != -1) {
            DllCall("Kernel32\CloseHandle", "Ptr", h)
        }
    }
    return success
}