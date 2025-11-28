#Requires AutoHotkey v2
;modules\ui\rotation\adapters\Rot_MapIndexId.ahk

; 从完整 Profile 构建 运行时索引 → 稳定 Id 的映射表
; 返回 Map("SkByIdx", Map, "PtByIdx", Map, "RlByIdx", Map)

Rot_BuildIndexMaps(pFull) {
    maps := Map()
    sk := Map()
    pt := Map()
    rl := Map()

    try {
        if (IsObject(pFull) && pFull.Has("Skills") && IsObject(pFull["Skills"])) {
            i := 1
            while (i <= pFull["Skills"].Length) {
                id := 0
                try {
                    id := OM_Get(pFull["Skills"][i], "Id", 0)
                } catch {
                    id := 0
                }
                sk[i] := id
                i := i + 1
            }
        }
    } catch {
    }

    try {
        if (IsObject(pFull) && pFull.Has("Points") && IsObject(pFull["Points"])) {
            i := 1
            while (i <= pFull["Points"].Length) {
                id := 0
                try {
                    id := OM_Get(pFull["Points"][i], "Id", 0)
                } catch {
                    id := 0
                }
                pt[i] := id
                i := i + 1
            }
        }
    } catch {
    }

    try {
        if (IsObject(pFull) && pFull.Has("Rules") && IsObject(pFull["Rules"])) {
            i := 1
            while (i <= pFull["Rules"].Length) {
                id := 0
                try {
                    id := OM_Get(pFull["Rules"][i], "Id", 0)
                } catch {
                    id := 0
                }
                rl[i] := id
                i := i + 1
            }
        }
    } catch {
    }

    maps["SkByIdx"] := sk
    maps["PtByIdx"] := pt
    maps["RlByIdx"] := rl
    return maps
}