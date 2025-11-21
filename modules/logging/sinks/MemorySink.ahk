#Requires AutoHotkey v2
;modules\logging\sinks\MemorySink.ahk

global g_LogMem := Map()

MemorySink_Init(capacity := 10000) {
    global g_LogMem
    g_LogMem.Clear()
    g_LogMem["Cap"] := 10000
    try {
        cap := Integer(capacity)
        if (cap >= 100) {
            g_LogMem["Cap"] := cap
        }
    } catch {
    }
    g_LogMem["Lines"] := []
}

MemorySink_Add(line) {
    global g_LogMem
    if !g_LogMem.Has("Lines") {
        MemorySink_Init(10000)
    }
    try {
        g_LogMem["Lines"].Push("" line)
        cap := g_LogMem["Cap"]
        len := g_LogMem["Lines"].Length
        if (len > cap) {
            overflow := len - cap
            if (overflow > 0) {
                try {
                    g_LogMem["Lines"].RemoveAt(1, overflow)
                } catch {
                    ; 兜底清空
                    try {
                        g_LogMem["Lines"] := []
                    } catch {
                    }
                }
            }
        }
    } catch {
    }
}

MemorySink_GetRecent(n := 1000) {
    global g_LogMem
    result := []
    if !g_LogMem.Has("Lines") {
        return result
    }
    total := g_LogMem["Lines"].Length
    if (total <= 0) {
        return result
    }
    cnt := 1000
    try {
        cnt := Integer(n)
    } catch {
        cnt := 1000
    }
    if (cnt < 1) {
        cnt := 1
    }
    start := total - cnt + 1
    if (start < 1) {
        start := 1
    }
    i := start
    while (i <= total) {
        try {
            result.Push(g_LogMem["Lines"][i])
        } catch {
        }
        i := i + 1
    }
    return result
}

MemorySink_Clear() {
    global g_LogMem
    try {
        g_LogMem["Lines"] := []
    } catch {
        g_LogMem["Lines"] := []
    }
}

MemorySink_Count() {
    global g_LogMem
    if g_LogMem.Has("Lines") {
        return g_LogMem["Lines"].Length
    } else {
        return 0
    }
}