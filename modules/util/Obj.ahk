#Requires AutoHotkey v2
; modules\util\Obj.ahk
; 通用对象取值与数组拼接，兼容 {} 与 Map
; 严格块结构，不使用单行 if/try/catch

OM_Get(obj, key, def := "") {
    val := def
    if !IsObject(obj) {
        return val
    }

    ; 1) 先尝试点号属性（{} 对象常用）
    try {
        if HasProp(obj, key) {
            val := obj.%key%
            return val
        }
    } catch {
    }

    ; 2) 再尝试 Map.Has + []（Map 常用）
    hasKey := false
    try {
        hasKey := obj.Has(key)
    } catch {
        hasKey := false
    }
    if (hasKey) {
        try {
            val := obj[key]
        } catch {
            val := def
        }
        return val
    }

    ; 3) 兜底尝试 [] 访问（{} 也可用）
    try {
        val2 := obj[key]
        return val2
    } catch {
    }

    return val
}

ArrJoin(arr, delim := ",") {
    out := ""
    if !IsObject(arr) {
        return out
    }
    i := 1
    while (i <= arr.Length) {
        if (i = 1) {
            out := "" arr[i]
        } else {
            out := out delim arr[i]
        }
        i := i + 1
    }
    return out
}