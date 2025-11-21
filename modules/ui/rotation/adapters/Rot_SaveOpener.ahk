#Requires AutoHotkey v2
; modules\ui\rotation\adapters\Rot_SaveOpener.ahk
; 保存 Opener：运行时索引→稳定 Id，写盘→重载→Counters/WorkerPool/Rotation 重建

Rot_SaveOpener(profileName, cfg) {
    global App

    if !(IsSet(profileName) && profileName != "") {
        Logger_Error("Opener", "save_begin_fail", Map("reason", "empty_profile"))
        return false
    }

    Logger_Info("Opener", "save_begin", Map("profile", profileName))
    t0 := A_TickCount

    p := 0
    try {
        p := Storage_Profile_LoadFull(profileName)
    } catch as e {
        Logger_Exception("Opener", e, Map("when","load_full","profile",profileName))
        return false
    }

    maps := Rot_BuildIndexMaps(p)
    skByIdx := Map()
    try skByIdx := maps["SkByIdx"]
    try {
        Logger_Debug("Opener", "map_counters", Map("map_sk", skByIdx.Count))
    } catch {
    }

    op := Map()
    try op["Enabled"] := OM_Get(cfg.Opener, "Enabled", 0)
    try op["MaxDurationMs"] := OM_Get(cfg.Opener, "MaxDurationMs", 4000)
    try op["ThreadId"] := OM_Get(cfg.Opener, "ThreadId", 1)

    ; Watch
    wArr := []
    wZero := 0
    wCount := 0
    try {
        if (HasProp(cfg.Opener,"Watch") && IsObject(cfg.Opener.Watch)) {
            i := 1
            while (i <= cfg.Opener.Watch.Length) {
                w0 := cfg.Opener.Watch[i]
                si := 0
                try si := OM_Get(w0, "SkillIndex", 0)
                sid := 0
                try {
                    if (skByIdx.Has(si)) {
                        sid := skByIdx[si]
                    } else {
                        sid := 0
                    }
                } catch {
                    sid := 0
                }
                if (sid <= 0) {
                    wZero := wZero + 1
                }
                need := 1
                vb := 0
                try need := OM_Get(w0, "RequireCount", 1)
                try vb := OM_Get(w0, "VerifyBlack", 0)
                wArr.Push(Map("SkillId", sid, "RequireCount", need, "VerifyBlack", vb))
                wCount := wCount + 1
                i := i + 1
            }
        }
    } catch {
    }
    try op["Watch"] := wArr

    ; Steps
    sArr := []
    sCount := 0
    try {
        if (HasProp(cfg.Opener,"Steps") && IsObject(cfg.Opener.Steps)) {
            i := 1
            while (i <= cfg.Opener.Steps.Length) {
                st0 := cfg.Opener.Steps[i]
                kind := ""
                try kind := OM_Get(st0, "Kind", "Skill")
                kU := ""
                try kU := StrUpper(kind)

                if (kU = "SKILL") {
                    si := 0
                    try si := OM_Get(st0, "SkillIndex", 0)
                    sid := 0
                    try {
                        if (skByIdx.Has(si)) {
                            sid := skByIdx[si]
                        } else {
                            sid := 0
                        }
                    } catch {
                        sid := 0
                    }
                    ns := Map()
                    try {
                        ns["Kind"] := "Skill"
                        ns["SkillId"] := sid
                        ns["RequireReady"] := OM_Get(st0, "RequireReady", 0)
                        ns["PreDelayMs"] := OM_Get(st0, "PreDelayMs", 0)
                        ns["HoldMs"] := OM_Get(st0, "HoldMs", 0)
                        ns["Verify"] := OM_Get(st0, "Verify", 0)
                        ns["TimeoutMs"] := OM_Get(st0, "TimeoutMs", 1200)
                        ns["DurationMs"] := OM_Get(st0, "DurationMs", 0)
                    }
                    sArr.Push(ns)
                } else if (kU = "WAIT") {
                    ns := Map()
                    try {
                        ns["Kind"] := "Wait"
                        ns["DurationMs"] := OM_Get(st0, "DurationMs", 0)
                    }
                    sArr.Push(ns)
                } else if (kU = "SWAP") {
                    ns := Map()
                    try {
                        ns["Kind"] := "Swap"
                        ns["TimeoutMs"] := OM_Get(st0, "TimeoutMs", 800)
                        ns["Retry"] := OM_Get(st0, "Retry", 0)
                    }
                    sArr.Push(ns)
                } else {
                    ns := Map("Kind","Wait","DurationMs",0)
                    sArr.Push(ns)
                }
                sCount := sCount + 1
                i := i + 1
            }
        }
    } catch {
    }
    try op["Steps"] := sArr

    try {
        if !(p.Has("Rotation")) {
            p["Rotation"] := Map()
        }
        p["Rotation"]["Opener"] := op
    } catch {
    }

    try {
        Logger_Warn("Opener", "prewrite_check", Map("watch_total", wCount, "watch_zero", wZero, "steps_total", sCount))
    } catch {
    }

    ok := false
    try {
        SaveModule_Opener(p)
        ok := true
    } catch as e2 {
        ok := false
        Logger_Exception("Opener", e2, Map("when","save","profile",profileName))
    }
    if (!ok) {
        return false
    }
    try {
        Logger_Info("Storage", "save_ok", Map("module","opener","profile",profileName,"elapsed_ms",A_TickCount - t0))
    } catch {
    }

    ; Reload + 重建
    t1 := A_TickCount
    try {
        p2 := Storage_Profile_LoadFull(profileName)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
        Logger_Info("Runtime", "reload_ok", Map("profile", profileName, "elapsed_ms", A_TickCount - t1))
    } catch as e3 {
        Logger_Exception("Opener", e3, Map("when","reload","profile",profileName))
        return false
    }

    try {
        Counters_Init()
    } catch {
    }
    try {
        RE_OnProfileDataReplaced(App["ProfileData"])
    } catch {
    }
    try {
        WorkerPool_Rebuild()
    } catch {
    }
    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
        Logger_Info("Opener", "runtime_reset", Map("actions", "Counters_Init,WorkerPool_Rebuild,Rotation_Reset,Rotation_InitFromProfile"))
    } catch {
    }

    return true
}