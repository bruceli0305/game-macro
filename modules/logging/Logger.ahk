#Requires AutoHotkey v2
;modules\logging\Logger.ahk
#Include "sinks\FileSink.ahk"
#Include "sinks\MemorySink.ahk"
#Include "sinks\PipeSink.ahk"

global g_LogCfg := Map()
global g_LogLevelText := Map()
global g_LogLevelNum  := Map()
global g_LogThrottle := Map()

Logger___InitTables() {
    global g_LogLevelText, g_LogLevelNum
    if (g_LogLevelText.Count = 0) {
        g_LogLevelText[0]  := "OFF"
        g_LogLevelText[10] := "FATAL"
        g_LogLevelText[20] := "ERROR"
        g_LogLevelText[30] := "WARN"
        g_LogLevelText[40] := "INFO"
        g_LogLevelText[50] := "DEBUG"
        g_LogLevelText[60] := "TRACE"
    }
    if (g_LogLevelNum.Count = 0) {
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

    global g_LogCfg, g_LogThrottle
    g_LogCfg.Clear()
    g_LogThrottle.Clear()

    g_LogCfg["Inited"] := false
    g_LogCfg["Level"] := 40
    g_LogCfg["PerCat"] := Map()
    g_LogCfg["File"] := A_ScriptDir "\Logs\app.log"
    g_LogCfg["CrashFile"] := A_ScriptDir "\Logs\crash.log"
    g_LogCfg["RotateSizeMB"] := 10
    g_LogCfg["RotateKeep"] := 5
    g_LogCfg["Pid"] := DllCall("Kernel32\GetCurrentProcessId", "UInt")
    g_LogCfg["EnableMemory"] := true
    g_LogCfg["MemoryCap"] := 10000
    g_LogCfg["EnablePipe"] := false
    g_LogCfg["PipeName"] := "GW2_LogSink"
    g_LogCfg["PipeClient"] := false
    g_LogCfg["IsPipeServer"] := false
    g_LogCfg["ThrottlePerSec"] := 5

    if IsObject(opts) {
        if HasProp(opts, "Level") {
            Logger_SetLevel(opts.Level)
        }
        if HasProp(opts, "PerCategory") {
            ; 允许传入 Map 或 "RuleEngine=DEBUG,DXGI=INFO" 字符串
            if IsObject(opts.PerCategory) {
                for k, v in opts.PerCategory {
                    Logger_SetLevelFor(k, v)
                }
            } else {
                pairs := StrSplit("" opts.PerCategory, ",")
                for _, kv in pairs {
                    kv2 := StrSplit(Trim(kv), "=")
                    if (kv2.Length = 2) {
                        Logger_SetLevelFor(Trim(kv2[1]), Trim(kv2[2]))
                    }
                }
            }
        }
        if HasProp(opts, "File") {
            g_LogCfg["File"] := "" opts.File
        }
        if HasProp(opts, "CrashFile") {
            g_LogCfg["CrashFile"] := "" opts.CrashFile
        }
        if HasProp(opts, "RotateSizeMB") {
            rsz := 10
            try {
                rsz := Integer(opts.RotateSizeMB)
            } catch {
                rsz := 10
            }
            if (rsz < 1) {
                rsz := 1
            }
            g_LogCfg["RotateSizeMB"] := rsz
        }
        if HasProp(opts, "RotateKeep") {
            rkp := 5
            try {
                rkp := Integer(opts.RotateKeep)
            } catch {
                rkp := 5
            }
            if (rkp < 1) {
                rkp := 1
            }
            g_LogCfg["RotateKeep"] := rkp
        }
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
        if HasProp(opts, "EnablePipe") {
            try {
                g_LogCfg["EnablePipe"] := (opts.EnablePipe ? 1 : 0)
            } catch {
                g_LogCfg["EnablePipe"] := false
            }
        }
        if HasProp(opts, "PipeName") {
            g_LogCfg["PipeName"] := "" opts.PipeName
        }
        if HasProp(opts, "PipeClient") {
            try {
                g_LogCfg["PipeClient"] := (opts.PipeClient ? 1 : 0)
            } catch {
                g_LogCfg["PipeClient"] := false
            }
        }
        if HasProp(opts, "ThrottlePerSec") {
            tp := 5
            try {
                tp := Integer(opts.ThrottlePerSec)
            } catch {
                tp := 5
            }
            if (tp < 0) {
                tp := 0
            }
            g_LogCfg["ThrottlePerSec"] := tp
        }
    }

    if g_LogCfg["EnableMemory"] {
        MemorySink_Init(g_LogCfg["MemoryCap"])
    }

    if g_LogCfg["EnablePipe"] {
        if g_LogCfg["PipeClient"] {
            g_LogCfg["IsPipeServer"] := false
        } else {
            g_LogCfg["IsPipeServer"] := true
            PipeSink_SetHandler(Logger__IngressLine)
            PipeSink_ServerStart(g_LogCfg["PipeName"])
        }
    }

    g_LogCfg["Inited"] := true

    try {
        f := Map()
        f["file"] := g_LogCfg["File"]
        f["keep"] := g_LogCfg["RotateKeep"]
        f["rotateMB"] := g_LogCfg["RotateSizeMB"]
        Logger_Info("Core", "Logger initialized", f)
    } catch {
    }
}

Logger_SetLevel(levelOrText) {
    global g_LogCfg
    n := Logger__ParseLevel(levelOrText)
    if (n >= 0) {
        g_LogCfg["Level"] := n
    }
}
Logger_GetLevel() {
    global g_LogCfg, g_LogLevelText
    lv := g_LogCfg["Level"]
    if g_LogLevelText.Has(lv) {
        return g_LogLevelText[lv]
    } else {
        return "" lv
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
Logger_GetLevelFor(category) {
    global g_LogCfg, g_LogLevelText
    cat := Logger__Cat(category)
    if g_LogCfg["PerCat"].Has(cat) {
        lv := g_LogCfg["PerCat"][cat]
        if g_LogLevelText.Has(lv) {
            return g_LogLevelText[lv]
        } else {
            return "" lv
        }
    } else {
        return ""
    }
}
Logger_ResetPerCategory() {
    global g_LogCfg
    g_LogCfg["PerCat"] := Map()
}

Logger_SetThrottlePerSec(n) {
    global g_LogCfg
    val := 0
    try {
        val := Integer(n)
    } catch {
        val := 0
    }
    if (val < 0) {
        val := 0
    }
    g_LogCfg["ThrottlePerSec"] := val
}
Logger_GetThrottlePerSec() {
    global g_LogCfg
    return g_LogCfg["ThrottlePerSec"]
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
            if (HasProp(e, "Message")) {
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
    if g_LogCfg["EnableMemory"] {
        MemorySink_Add(line)
    }
}

Logger_Flush() {
    global g_LogCfg
    if g_LogCfg.Has("EnablePipe") {
        if (g_LogCfg["EnablePipe"] && g_LogCfg["IsPipeServer"]) {
            try {
                PipeSink_ServerStop()
            } catch {
            }
        }
    }
}

Logger__Log(level, category, msg, fields) {
    global g_LogCfg
    if !Logger_IsEnabled(level, category) {
        return
    }

    ; 节流摘要（窗口切换前输出）
    sumLine := Logger__ThrottleCheck(category, msg)
    if (sumLine != "") {
        Logger__DirectWriteLine(sumLine)
    }

    line := Logger__Format(level, category, msg, fields)

    if (g_LogCfg["EnablePipe"] && g_LogCfg["PipeClient"]) {
        sentOk := false
        try {
            sentOk := PipeSink_ClientSend(g_LogCfg["PipeName"], line)
        } catch {
            sentOk := false
        }
        if (!sentOk) {
            FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
            if (level <= 20) {
                FileSink_WriteLine(g_LogCfg["CrashFile"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
            }
        }
    } else {
        FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
        if (level <= 20) {
            FileSink_WriteLine(g_LogCfg["CrashFile"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
        }
    }

    if g_LogCfg["EnableMemory"] {
        MemorySink_Add(line)
    }
}

Logger__DirectWriteLine(line) {
    global g_LogCfg
    if (line = "") {
        return
    }
    if (g_LogCfg["EnablePipe"] && g_LogCfg["PipeClient"]) {
        sentOk := false
        try {
            sentOk := PipeSink_ClientSend(g_LogCfg["PipeName"], line)
        } catch {
            sentOk := false
        }
        if (!sentOk) {
            FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
        }
    } else {
        FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    }
    if g_LogCfg["EnableMemory"] {
        MemorySink_Add(line)
    }
}

Logger__ThrottleCheck(category, msg) {
    global g_LogCfg, g_LogThrottle
    t := g_LogCfg["ThrottlePerSec"]
    if (t <= 0) {
        return ""
    }
    key := Logger__Cat(category) . "|" . Logger__Str(msg)
    now := A_TickCount

    if !g_LogThrottle.Has(key) {
        g_LogThrottle[key] := Map("start", now, "count", 1, "supp", 0)
        return ""
    }

    st := g_LogThrottle[key]["start"]
    cnt := g_LogThrottle[key]["count"]
    sup := g_LogThrottle[key]["supp"]

    if (now - st < 1000) {
        if (cnt >= t) {
            sup := sup + 1
            g_LogThrottle[key]["supp"] := sup
            return ""
        } else {
            cnt := cnt + 1
            g_LogThrottle[key]["count"] := cnt
            return ""
        }
    } else {
        sumLine := ""
        if (sup > 0) {
            f := Map()
            f["key"] := key
            f["suppressed"] := sup
            sumLine := Logger__Format(30, "Logger", "throttled", f)
        }
        g_LogThrottle[key]["start"] := now
        g_LogThrottle[key]["count"] := 1
        g_LogThrottle[key]["supp"] := 0
        return sumLine
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

; 内存缓冲访问（日志页用）
Logger_MemGetRecent(n := 1000) {
    return MemorySink_GetRecent(n)
}
Logger_MemClear() {
    MemorySink_Clear()
}
Logger_MemCount() {
    return MemorySink_Count()
}

; Pipe 服务端接收回调
Logger__IngressLine(text) {
    global g_LogCfg
    line := "" text
    FileSink_WriteLine(g_LogCfg["File"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])

    isErr := false
    if InStr(line, " [ERROR] ") {
        isErr := true
    }
    if InStr(line, " [FATAL] ") {
        isErr := true
    }
    if InStr(line, " CRASH ") {
        isErr := true
    }
    if (isErr) {
        FileSink_WriteLine(g_LogCfg["CrashFile"], line, g_LogCfg["RotateSizeMB"], g_LogCfg["RotateKeep"])
    }
    if g_LogCfg["EnableMemory"] {
        MemorySink_Add(line)
    }
}