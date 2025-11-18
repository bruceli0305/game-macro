#Requires AutoHotkey v2
#Include "sinks\FileSink.ahk"
#Include "sinks\MemorySink.ahk"

global g_LogCfg := Map()
global g_LogLevelText := Map()
global g_LogLevelNum  := Map()

Logger___InitTables() {
    global g_LogLevelText, g_LogLevelNum
    if g_LogLevelText.Count = 0 {
        g_LogLevelText[0]  := "OFF"
        g_LogLevelText[10] := "FATAL"
        g_LogLevelText[20] := "ERROR"
        g_LogLevelText[30] := "WARN"
        g_LogLevelText[40] := "INFO"
        g_LogLevelText[50] := "DEBUG"
        g_LogLevelText[60] := "TRACE"
    }
    if g_LogLevelNum.Count = 0 {
        g_LogLevelNum["OFF"]   := 0
        g_LogLevelNum["FATAL"] := 10
        g_LogLevelNum["ERROR"] := 20
        g_LogLevelNum["WARN"]  := 30
        g_LogLevelNum["INFO"]  := 40
        g_LogLevelNum["DEBUG"] := 50
        g_LogLevelNum["TRACE"] := 60
    }
}

Logger_Init(opts := 0) {
    Logger___InitTables()

    global g_LogCfg
    g_LogCfg.Clear()
    g_LogCfg["Inited"] := false
    g_LogCfg["Level"] := 40
    g_LogCfg["PerCat"] := Map()
    g_LogCfg["File"] := A_ScriptDir "\Logs\app.log"
    g_LogCfg["CrashFile"] := A_ScriptDir "\Logs\crash.log"
    g_LogCfg["RotateSizeMB"] := 10
    g_LogCfg["RotateKeep"] := 5
    g_LogCfg["Pid"] := DllCall("Kernel32\GetCurrentProcessId", "UInt")
    ; 在初始化默认值处加入
    g_LogCfg["EnableMemory"] := true
    g_LogCfg["MemoryCap"] := 10000

    if IsObject(opts) {
        if HasProp(opts, "EnableMemory") {
            try {
                g_LogCfg["EnableMemory"] := (opts.EnableMemory ? 1 : 0)
            } catch {
                g_LogCfg["EnableMemory"] := true
            }
        }
        if HasProp(opts, "MemoryCap") {
            mc := 10000
            try {
                mc := Integer(opts.MemoryCap)
            } catch {
                mc := 10000
            }
            if (mc < 100) {
                mc := 100
            }
            g_LogCfg["MemoryCap"] := mc
        }
        if HasProp(opts, "Level") {
            Logger_SetLevel(opts.Level)
        }
        if HasProp(opts, "PerCategory") {
            for k, v in opts.PerCategory {
                Logger_SetLevelFor(k, v)
            }
        }
        if HasProp(opts, "File") {
            g_LogCfg["File"] := "" opts.File
        }
        if HasProp(opts, "CrashFile") {
            g_LogCfg["CrashFile"] := "" opts.CrashFile
        }
        if HasProp(opts, "RotateSizeMB") {
            rot := 0
            try {
                rot := Integer(opts.RotateSizeMB)
            } catch {
                rot := 10
            }
            if (rot < 1) {
                rot := 1
            }
            g_LogCfg["RotateSizeMB"] := rot
        }
        if HasProp(opts, "RotateKeep") {
            kp := 0
            try {
                kp := Integer(opts.RotateKeep)
            } catch {
                kp := 5
            }
            if (kp < 1) {
                kp := 1
            }
            g_LogCfg["RotateKeep"] := kp
        }
    }
    ; 初始化内存缓冲
    if g_LogCfg["EnableMemory"] {
        MemorySink_Init(g_LogCfg["MemoryCap"])
    }
    g_LogCfg["Inited"] := true
    Logger_Info("Core", "Logger initialized", Map("file", g_LogCfg["File"], "rotateMB", g_LogCfg["RotateSizeMB"], "keep", g_LogCfg["RotateKeep"]))
}

Logger_SetLevel(levelOrText) {
    global g_LogCfg
    n := Logger__ParseLevel(levelOrText)
    if (n >= 0) {
        g_LogCfg["Level"] := n
    }
}

Logger_SetLevelFor(category, levelOrText) {
    global g_LogCfg
    if !(IsSet(category) && category != "") {
        return
    }
    n := Logger__ParseLevel(levelOrText)
    if (n < 0) {
        return
    }
    cat := Logger__Cat(category)
    g_LogCfg["PerCat"][cat] := n
}

Logger_IsEnabled(level, category := "") {
    global g_LogCfg
    if !g_LogCfg.Has("Inited") {
        return true
    }
    if !g_LogCfg["Inited"] {
        return true
    }
    eff := g_LogCfg["Level"]
    cat := Logger__Cat(category)
    if (cat != "" && g_LogCfg["PerCat"].Has(cat)) {
        eff := g_LogCfg["PerCat"][cat]
    }
    return (Integer(level) <= eff)
}

Logger_Trace(category, msg, fields := 0) {
    Logger__Log(60, category, msg, fields)
}
Logger_Debug(category, msg, fields := 0) {
    Logger__Log(50, category, msg, fields)
}
Logger_Info(category, msg, fields := 0) {
    Logger__Log(40, category, msg, fields)
}
Logger_Warn(category, msg, fields := 0) {
    Logger__Log(30, category, msg, fields)
}
Logger_Error(category, msg, fields := 0) {
    Logger__Log(20, category, msg, fields)
}
Logger_Fatal(category, msg, fields := 0) {
    Logger__Log(10, category, msg, fields)
}

Logger_Exception(category, e, fields := 0) {
    extra := Map()
    if IsObject(fields) {
        try {
            extra := fields.Clone()
        } catch {
            extra := Map()
        }
    }
    if IsObject(e) {
        try {
            if HasProp(e, "Message") {
                extra["err"] := "" e.Message
            }
        }
    }
    Logger_Error(category, "exception", extra)
}

Logger_Crash(category, e := 0, fields := 0) {
    global g_LogCfg
    extra := Map()
    if IsObject(fields) {
        try {
            extra := fields.Clone()
        } catch {
            extra := Map()
        }
    }
    if IsObject(e) {
        try {
            if HasProp(e, "Message") {
                extra["err"] := "" e.Message
            }
        }
    }
    line := Logger__Format(10, category, "CRASH", extra)
    FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    FileSink_WriteLine(g_LogCfg["CrashFile"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    if (g_LogCfg["EnableMemory"]) {
        MemorySink_Add(line)
    }
}

Logger_Flush() {
    ; 预留：当前 FileSink 无缓冲，此处保持空实现
}

Logger__Log(level, category, msg, fields) {
    global g_LogCfg
    if !Logger_IsEnabled(level, category) {
        return
    }
    line := Logger__Format(level, category, msg, fields)
    FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    if (level <= 20) {
        FileSink_WriteLine(g_LogCfg["CrashFile"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    }
    if (g_LogCfg["EnableMemory"]) {
        MemorySink_Add(line)
    }
}

Logger__Format(level, category, msg, fields := 0) {
    global g_LogCfg, g_LogLevelText
    ts := Logger__TsMs()
    tk := A_TickCount
    lv := "LV" . level
    if g_LogLevelText.Has(level) {
        lv := g_LogLevelText[level]
    }
    cat := Logger__Cat(category)
    pid := g_LogCfg["Pid"]
    fld := Logger__Fields(fields)
    m := Logger__Str(msg)

    line := ts . " [tick=" . tk . "] [pid=" . pid . "] [" . lv . "] [" . cat . "]"
    if (fld != "") {
        line := line . " " . fld
    }
    line := line . " | " . m
    return line
}

Logger__Fields(fields) {
    if !IsObject(fields) {
        return ""
    }
    out := ""
    i := 0
    for k, v in fields {
        sk := Logger__Str(k)
        sv := Logger__Str(v)
        if (i = 0) {
            out := sk . "=" . sv
        } else {
            out := out . " " . sk . "=" . sv
        }
        i := i + 1
    }
    return out
}

Logger__Str(x) {
    s := ""
    try {
        if IsNumber(x) {
            return "" x
        }
        if IsObject(x) {
            return "[obj]"
        }
        s := "" x
        s := StrReplace(s, "`r", " ")
        s := StrReplace(s, "`n", " ")
    } catch {
        s := ""
    }
    return s
}

Logger__Cat(c) {
    if !(IsSet(c) && c != "") {
        return "General"
    }
    return "" c
}

Logger__ParseLevel(x) {
    Logger___InitTables()
    if IsNumber(x) {
        n := 0
        try {
            n := Integer(x)
        } catch {
            n := -1
        }
        if (n >= 0 && n <= 60) {
            return n
        } else {
            return -1
        }
    }
    s := ""
    try {
        s := StrUpper(Trim("" x))
    } catch {
        s := ""
    }
    if g_LogLevelNum.Has(s) {
        return g_LogLevelNum[s]
    } else {
        return -1
    }
}

Logger__TsMs() {
    st := Buffer(16, 0)
    try {
        DllCall("Kernel32\GetLocalTime", "ptr", st.Ptr)
    } catch {
    }
    y  := NumGet(st, 0,  "UShort")
    mo := NumGet(st, 2,  "UShort")
    d  := NumGet(st, 6,  "UShort")
    h  := NumGet(st, 8,  "UShort")
    mi := NumGet(st, 10, "UShort")
    s  := NumGet(st, 12, "UShort")
    ms := NumGet(st, 14, "UShort")
    return Format("{:04}-{:02}-{:02} {:02}:{:02}:{:02}.{:03}", y, mo, d, h, mi, s, ms)
}

Logger_MemGetRecent(n := 1000) {
    return MemorySink_GetRecent(n)
}
Logger_MemClear() {
    MemorySink_Clear()
}
Logger_MemCount() {
    return MemorySink_Count()
}