#Requires AutoHotkey v2
; Rules_UI_Common.ahk
; 规则编辑通用工具：线程/技能/点位名称、下拉填充、比较符映射、ListView 自适应等
; 严格块结构，不使用单行 if/try/catch

RE_Rules_ThreadNameById(id) {
    global App
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "Threads") && IsObject(App["ProfileData"].Threads)) {
                for _, t in App["ProfileData"].Threads {
                    try {
                        if (t.Id = id) {
                            return t.Name
                        }
                    } catch {
                    }
                }
            }
        }
    } catch {
    }
    if (id = 1) {
        return "默认线程"
    }
    return "线程#" id
}

RE_Rules_SkillNameByIndex(idx) {
    global App
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
                if (idx >= 1 && idx <= App["ProfileData"].Skills.Length) {
                    return App["ProfileData"].Skills[idx].Name
                }
            }
        }
    } catch {
    }
    return "技能#" idx
}

RE_Rules_PointNameByIndex(idx) {
    global App
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "Points") && IsObject(App["ProfileData"].Points)) {
                if (idx >= 1 && idx <= App["ProfileData"].Points.Length) {
                    return App["ProfileData"].Points[idx].Name
                }
            }
        }
    } catch {
    }
    return "点位#" idx
}

RE_Rules_ClampIndex(v, vmax) {
    v := Integer(v)
    vmax := Integer(vmax)
    if (vmax <= 0) {
        return 0
    }
    if (v < 1) {
        return 1
    }
    if (v > vmax) {
        return vmax
    }
    return v
}

RE_Rules_FillSkills(dd) {
    global App
    count := 0
    try {
        dd.Delete()
    } catch {
    }
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
                names := []
                for _, s in App["ProfileData"].Skills {
                    try {
                        names.Push(s.Name)
                    } catch {
                    }
                }
                if (names.Length > 0) {
                    dd.Add(names)
                    count := names.Length
                }
            }
        }
    } catch {
        count := 0
    }
    return count
}

RE_Rules_FillPoints(dd) {
    global App
    count := 0
    try {
        dd.Delete()
    } catch {
    }
    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "Points") && IsObject(App["ProfileData"].Points)) {
                names := []
                for _, p in App["ProfileData"].Points {
                    try {
                        names.Push(p.Name)
                    } catch {
                    }
                }
                if (names.Length > 0) {
                    dd.Add(names)
                    count := names.Length
                }
            }
        }
    } catch {
        count := 0
    }
    return count
}

RE_Cmp_TextToKey(text) {
    t := "" text
    if (t = ">=") {
        return "GE"
    }
    if (t = "==") {
        return "EQ"
    }
    if (t = ">") {
        return "GT"
    }
    if (t = "<=") {
        return "LE"
    }
    if (t = "<") {
        return "LT"
    }
    return "GE"
}

RE_Cmp_KeyToText(key) {
    k := StrUpper("" key)
    if (k = "GE") {
        return ">="
    }
    if (k = "EQ") {
        return "=="
    }
    if (k = "GT") {
        return ">"
    }
    if (k = "LE") {
        return "<="
    }
    if (k = "LT") {
        return "<"
    }
    return ">="
}

RE_LV_AutoHdr(lv, colCount) {
    i := 1
    while (i <= colCount) {
        try {
            lv.ModifyCol(i, "AutoHdr")
        } catch {
        }
        i := i + 1
    }
}