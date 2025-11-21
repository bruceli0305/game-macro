; modules\runtime\Counters.ahk
#Requires AutoHotkey v2

global Counters := Map()

Counters_Init() {
    global Counters
    Counters := Map()
}

Counters_Inc(idx) {
    global Counters
    if !Counters.Has(idx)
        Counters[idx] := 0
    Counters[idx] += 1
    return Counters[idx]
}

Counters_Get(idx) {
    global Counters
    return Counters.Has(idx) ? Counters[idx] : 0
}

Counters_Reset(idx) {
    global Counters
    if Counters.Has(idx)
        Counters.Delete(idx)
}

Counters_ResetMany(indices) {
    for _, i in indices
        Counters_Reset(i)
}