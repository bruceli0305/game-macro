; modules\storage\model\IdMap.ahk（关键片段）
PM_BuildIdMaps(profile) {
    maps := Map()
    maps["SkillsById"]  := Map()
    maps["PointsById"]  := Map()
    maps["RulesById"]   := Map()
    maps["TracksById"]  := Map()
    maps["GatesById"]   := Map()
    maps["BuffsById"]   := Map()
    maps["ThreadsById"] := Map()

    ; Skills
    if IsObject(profile) && profile.Has("Skills") {
        i := 1
        while (i <= profile["Skills"].Length) {
            id := 0
            try {
                id := OM_Get(profile["Skills"][i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["SkillsById"][id] := i
            }
            i := i + 1
        }
    }

    ; Points
    if IsObject(profile) && profile.Has("Points") {
        i := 1
        while (i <= profile["Points"].Length) {
            id := 0
            try {
                id := OM_Get(profile["Points"][i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["PointsById"][id] := i
            }
            i := i + 1
        }
    }

    ; Rules
    if IsObject(profile) && profile.Has("Rules") {
        i := 1
        while (i <= profile["Rules"].Length) {
            id := 0
            try {
                id := OM_Get(profile["Rules"][i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["RulesById"][id] := i
            }
            i := i + 1
        }
    }

    ; Tracks
    if IsObject(profile) && profile.Has("Rotation") && HasProp(profile["Rotation"], "Tracks") {
        arr := profile["Rotation"]["Tracks"]
        i := 1
        while (i <= arr.Length) {
            id := 0
            try {
                id := OM_Get(arr[i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["TracksById"][id] := i
            }
            i := i + 1
        }
    }

    ; Gates
    if IsObject(profile) && profile.Has("Rotation") && HasProp(profile["Rotation"], "Gates") {
        arr := profile["Rotation"]["Gates"]
        i := 1
        while (i <= arr.Length) {
            id := 0
            try {
                id := OM_Get(arr[i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["GatesById"][id] := i
            }
            i := i + 1
        }
    }

    ; Buffs
    if IsObject(profile) && profile.Has("Buffs") {
        i := 1
        while (i <= profile["Buffs"].Length) {
            id := 0
            try {
                id := OM_Get(profile["Buffs"][i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["BuffsById"][id] := i
            }
            i := i + 1
        }
    }

    ; Threads
    if IsObject(profile) && profile.Has("General") && HasProp(profile["General"], "Threads") {
        arr := profile["General"]["Threads"]
        i := 1
        while (i <= arr.Length) {
            id := 0
            try {
                id := OM_Get(arr[i], "Id", 0)
            } catch {
                id := 0
            }
            if (id > 0) {
                maps["ThreadsById"][id] := i
            }
            i := i + 1
        }
    }

    profile["IdMap"] := maps
}

; 便捷查找（返回数组索引，找不到返回 0）
PM_SkillIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("SkillsById") {
        if profile["IdMap"]["SkillsById"].Has(id) {
            return profile["IdMap"]["SkillsById"][id]
        }
    }
    return 0
}
PM_PointIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("PointsById") {
        if profile["IdMap"]["PointsById"].Has(id) {
            return profile["IdMap"]["PointsById"][id]
        }
    }
    return 0
}
PM_RuleIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("RulesById") {
        if profile["IdMap"]["RulesById"].Has(id) {
            return profile["IdMap"]["RulesById"][id]
        }
    }
    return 0
}
PM_TrackIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("TracksById") {
        if profile["IdMap"]["TracksById"].Has(id) {
            return profile["IdMap"]["TracksById"][id]
        }
    }
    return 0
}
PM_GateIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("GatesById") {
        if profile["IdMap"]["GatesById"].Has(id) {
            return profile["IdMap"]["GatesById"][id]
        }
    }
    return 0
}
PM_BuffIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("BuffsById") {
        if profile["IdMap"]["BuffsById"].Has(id) {
            return profile["IdMap"]["BuffsById"][id]
        }
    }
    return 0
}
PM_ThreadIndexById(profile, id) {
    if IsObject(profile) && profile.Has("IdMap") && profile["IdMap"].Has("ThreadsById") {
        if profile["IdMap"]["ThreadsById"].Has(id) {
            return profile["IdMap"]["ThreadsById"][id]
        }
    }
    return 0
}