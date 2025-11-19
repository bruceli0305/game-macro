#Requires AutoHotkey v2
; modules\util\IdGen.ahk
; 64-bit Snowflake（41位时间戳ms + 10位workerId + 12位序列）
; 严格块结构

global ID_EPOCH_FT := 133485408000000000        ; 2024-01-01 00:00:00 UTC 的 FILETIME（100ns）
global ID_WORKER_ID := 1

ID_Init(workerId := 1) {
    global ID_WORKER_ID
    if (workerId < 0) {
        workerId := 0
    }
    if (workerId > 1023) {
        workerId := 1023
    }
    ID_WORKER_ID := workerId
}

ID_Next() {
    static lastTs := 0
    static seq := 0

    ts := ID_NowMs()
    if (ts < lastTs) {
        ts := lastTs
    }
    if (ts = lastTs) {
        seq := (seq + 1) & 0xFFF
        if (seq = 0) {
            ts := ID_WaitNextMs(ts)
        }
    } else {
        seq := 0
    }
    lastTs := ts

    w := ID_WORKER_ID & 0x3FF
    id := ((ts & 0x1FFFFFFFFFF) << 22) | (w << 12) | (seq & 0xFFF)
    return id
}

ID_WaitNextMs(ts) {
    t2 := ID_NowMs()
    while (t2 <= ts) {
        Sleep 1
        t2 := ID_NowMs()
    }
    return t2
}

ID_NowMs() {
    ft := Buffer(8, 0)
    ok := false
    try {
        DllCall("kernel32\GetSystemTimePreciseAsFileTime", "ptr", ft.Ptr)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        try {
            DllCall("kernel32\GetSystemTimeAsFileTime", "ptr", ft.Ptr)
        } catch {
        }
    }
    v := NumGet(ft, 0, "Int64")
    if (v < ID_EPOCH_FT) {
        return 0
    }
    ms := (v - ID_EPOCH_FT) // 10000
    return ms
}