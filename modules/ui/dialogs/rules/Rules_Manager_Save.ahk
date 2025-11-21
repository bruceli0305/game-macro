#Requires AutoHotkey v2
; Rules_Manager_Save.ahk
; 规则保存（索引 → Id 转换 + 持久化 + 运行时重载）
; 导出：RM_SaveAll(profileName) -> bool

RM_SaveAll(profileName) {
    global App
    if (profileName = "") {
        return false
    }
    if !(IsSet(App) && App.Has("ProfileData")) {
        return false
    }
    rt := App["ProfileData"]

    p := 0
    try {
        p := Storage_Profile_LoadFull(profileName)
    } catch {
        return false
    }
    if !IsObject(p) {
        return false
    }

    ; 构建索引->Id 映射
    skIdByIdx := Map()
    ptIdByIdx := Map()
    try {
        if (p.Has("Skills") && IsObject(p["Skills"])) {
            i := 1
            while (i <= p["Skills"].Length) {
                sid := 0
                try sid := OM_Get(p["Skills"][i], "Id", 0)
                skIdByIdx[i] := sid
                i := i + 1
            }
        }
    } catch {
    }
    try {
        if (p.Has("Points") && IsObject(p["Points"])) {
            i := 1
            while (i <= p["Points"].Length) {
                pid := 0
                try pid := OM_Get(p["Points"][i], "Id", 0)
                ptIdByIdx[i] := pid
                i := i + 1
            }
        }
    } catch {
    }

    ; 规则转换（运行时 -> 存储）
    newArr := []
    try {
        if (HasProp(rt, "Rules") && IsObject(rt.Rules)) {
            i := 1
            while (i <= rt.Rules.Length) {
                rr := rt.Rules[i]
                r := PM_NewRule()
                try r["Id"] := OM_Get(rr, "Id", 0)
                r["Name"] := OM_Get(rr, "Name", "Rule")
                r["Enabled"] := OM_Get(rr, "Enabled", 1)
                r["Logic"] := OM_Get(rr, "Logic", "AND")
                r["CooldownMs"] := OM_Get(rr, "CooldownMs", 500)
                r["Priority"] := OM_Get(rr, "Priority", i)
                r["ActionGapMs"] := OM_Get(rr, "ActionGapMs", 60)
                r["ThreadId"] := OM_Get(rr, "ThreadId", 1)
                r["SessionTimeoutMs"] := OM_Get(rr, "SessionTimeoutMs", 0)
                r["AbortCooldownMs"] := OM_Get(rr, "AbortCooldownMs", 0)

                ; 条件
                conds := []
                try {
                    if (HasProp(rr, "Conditions") && IsObject(rr.Conditions)) {
                        j := 1
                        while (j <= rr.Conditions.Length) {
                            c0 := rr.Conditions[j]
                            kind := OM_Get(c0, "Kind", "Pixel")
                            kindU := StrUpper(kind)
                            if (kindU = "COUNTER") {
                                si := OM_Get(c0, "SkillIndex", 0)
                                sid := 0
                                try sid := (skIdByIdx.Has(si) ? skIdByIdx[si] : 0)
                                cmp := OM_Get(c0, "Cmp", "GE")
                                val := OM_Get(c0, "Value", 1)
                                rst := OM_Get(c0, "ResetOnTrigger", 0)
                                conds.Push({ Kind: "Counter", SkillId: sid, Cmp: cmp, Value: val, ResetOnTrigger: rst })
                            } else {
                                rt2 := OM_Get(c0, "RefType", "Skill")
                                ri := OM_Get(c0, "RefIndex", 0)
                                op := OM_Get(c0, "Op", "EQ")
                                refId := 0
                                if (StrUpper(rt2) = "SKILL") {
                                    try refId := (skIdByIdx.Has(ri) ? skIdByIdx[ri] : 0)
                                } else {
                                    try refId := (ptIdByIdx.Has(ri) ? ptIdByIdx[ri] : 0)
                                }
                                conds.Push({ Kind: "Pixel", RefType: rt2, RefId: refId, Op: op, Color: "0x000000", Tol: 16 })
                            }
                            j := j + 1
                        }
                    }
                } catch {
                }
                r["Conditions"] := conds

                ; 动作
                acts := []
                try {
                    if (HasProp(rr, "Actions") && IsObject(rr.Actions)) {
                        j := 1
                        while (j <= rr.Actions.Length) {
                            a0 := rr.Actions[j]
                            si := OM_Get(a0, "SkillIndex", 0)
                            sid := 0
                            try sid := (skIdByIdx.Has(si) ? skIdByIdx[si] : 0)

                            a := PM_NewAction()
                            a["SkillId"] := sid
                            a["DelayMs"] := OM_Get(a0, "DelayMs", 0)
                            a["HoldMs"] := OM_Get(a0, "HoldMs", -1)
                            a["RequireReady"] := OM_Get(a0, "RequireReady", 0)
                            a["Verify"] := OM_Get(a0, "Verify", 0)
                            a["VerifyTimeoutMs"] := OM_Get(a0, "VerifyTimeoutMs", 600)
                            a["Retry"] := OM_Get(a0, "Retry", 0)
                            a["RetryGapMs"] := OM_Get(a0, "RetryGapMs", 150)
                            acts.Push(a)
                            j := j + 1
                        }
                    }
                } catch {
                }
                r["Actions"] := acts

                newArr.Push(r)
                i := i + 1
            }
        }
    } catch {
    }

    p["Rules"] := newArr

    ok := false
    try {
        SaveModule_Rules(p)
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        return false
    }

    ; 重载运行时
    try {
        p2 := Storage_Profile_LoadFull(profileName)
        rt2 := PM_ToRuntime(p2)
        App["ProfileData"] := rt2
    } catch {
        return false
    }

    ; 运行组件刷新
    try WorkerPool_Rebuild()
    try Counters_Init()
    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
    }

    return true
}