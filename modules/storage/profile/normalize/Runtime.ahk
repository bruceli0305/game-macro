#Requires AutoHotkey v2
; modules\storage\profile\normalize\Runtime.ahk
; 将“文件夹-模块化-Id引用”Profile 转为“引擎可用的索引引用”结构（运行时模型）
; 依赖：OM_Get / PM_BuildIdMaps / PM_*IndexById / Logger_*
; 严格块结构，不使用单行 if/try/catch

PM_ToRuntime(profile) {
    data := Core_DefaultProfileData()

    ; 名称
    if (IsObject(profile) && profile.Has("Name")) {
        data.Name := profile["Name"]
    }

    ; 构建 Id 映射（供下方 Id→Index 用）
    PM_BuildIdMaps(profile)

    dbgRt := 0
    try {
        if Logger_IsEnabled(50, "Runtime") {
            dbgRt := 1
        } else {
            dbgRt := 0
        }
    } catch {
        dbgRt := 0
    }

    ; ===== General =====
    g := Map()
    if (profile.Has("General")) {
        g := profile["General"]
    }

    val := ""
    val := OM_Get(g, "StartHotkey", data.StartHotkey)
    data.StartHotkey := val

    val := OM_Get(g, "PollIntervalMs", data.PollIntervalMs)
    data.PollIntervalMs := val

    val := OM_Get(g, "SendCooldownMs", data.SendCooldownMs)
    data.SendCooldownMs := val

    val := OM_Get(g, "PickHoverEnabled", data.PickHoverEnabled)
    data.PickHoverEnabled := val

    val := OM_Get(g, "PickHoverOffsetY", data.PickHoverOffsetY)
    data.PickHoverOffsetY := val

    val := OM_Get(g, "PickHoverDwellMs", data.PickHoverDwellMs)
    data.PickHoverDwellMs := val

    val := OM_Get(g, "PickConfirmKey", "LButton")
    data.PickConfirmKey := val

    ; Threads
    data.Threads := []
    if (g.Has("Threads") && IsObject(g["Threads"])) {
        i := 1
        while (i <= g["Threads"].Length) {
            t := g["Threads"][i]
            tid := OM_Get(t, "Id", i)
            tname := OM_Get(t, "Name", "线程" i)
            data.Threads.Push({ Id: tid, Name: tname })
            i := i + 1
        }
    } else {
        data.Threads := [{ Id: 1, Name: "默认线程" }]
    }

    ; DefaultSkill（SkillId → SkillIndex）
    data.DefaultSkill := { Enabled: 0, SkillIndex: 0, CheckReady: 1, ThreadId: 1, CooldownMs: 600, PreDelayMs: 0, LastFire: 0 }
    if (g.Has("DefaultSkill") && IsObject(g["DefaultSkill"])) {
        ds := g["DefaultSkill"]
        data.DefaultSkill.Enabled     := OM_Get(ds, "Enabled", 0)
        sid                           := OM_Get(ds, "SkillId", 0)
        data.DefaultSkill.SkillIndex  := (sid>0) ? PM_SkillIndexById(profile, sid) : 0
        data.DefaultSkill.CheckReady  := OM_Get(ds, "CheckReady", 1)
        data.DefaultSkill.ThreadId    := OM_Get(ds, "ThreadId", 1)
        data.DefaultSkill.CooldownMs  := OM_Get(ds, "CooldownMs", 600)
        data.DefaultSkill.PreDelayMs  := OM_Get(ds, "PreDelayMs", 0)
        data.DefaultSkill.LastFire    := 0
    }

    ; === 新增：CastBar 运行时结构 ===
    data.CastBar := {
        Enabled: 0
      , X: 0
      , Y: 0
      , Color: "0x000000"
      , Tol: 10
      , DebugLog: 0
      , IgnoreActionDelay: 0
      , AcceptWindowMs: 120    ; 新增：默认接受窗口 120ms
    }
    data.CastBar.Enabled := OM_Get(g, "CastBarEnabled", data.CastBar.Enabled)
    data.CastBar.X := OM_Get(g, "CastBarX", data.CastBar.X)
    data.CastBar.Y := OM_Get(g, "CastBarY", data.CastBar.Y)
    data.CastBar.Color := OM_Get(g, "CastBarColor", data.CastBar.Color)
    data.CastBar.Tol := OM_Get(g, "CastBarTol", data.CastBar.Tol)
    data.CastBar.DebugLog := OM_Get(g, "CastBarDebugLog", data.CastBar.DebugLog)
    data.CastBar.IgnoreActionDelay := OM_Get(g, "CastBarIgnoreActionDelay", data.CastBar.IgnoreActionDelay)
    data.CastBar.AcceptWindowMs := OM_Get(g, "CastBarAcceptWindowMs", data.CastBar.AcceptWindowMs)
    
    ; === 新增：调试窗口运行时结构 ===
    data.CastDebug := {
        Hotkey: OM_Get(g, "CastDebugHotkey", "")
      , Topmost: OM_Get(g, "CastDebugTopmost", 1)
      , Alpha: OM_Get(g, "CastDebugAlpha", 230)
    }

    ; ===== Skills =====
    data.Skills := []
    if (profile.Has("Skills") && IsObject(profile["Skills"])) {
        i := 1
        while (i <= profile["Skills"].Length) {
            s := profile["Skills"][i]
            id   := OM_Get(s, "Id", 0)
            nm   := OM_Get(s, "Name", "")
            key  := OM_Get(s, "Key", "")
            x    := OM_Get(s, "X", 0)
            y    := OM_Get(s, "Y", 0)
            col  := OM_Get(s, "Color", "0x000000")
            tol  := OM_Get(s, "Tol", 10)
            cast := OM_Get(s, "CastMs", 0)
            lock := OM_Get(s, "LockDuringCast", 1)
            cto  := OM_Get(s, "CastTimeoutMs", 0)
            data.Skills.Push({
                  Id: id
                , Name: nm
                , Key: key
                , X: x
                , Y: y
                , Color: col
                , Tol: tol
                , CastMs: cast
                , LockDuringCast: lock
                , CastTimeoutMs: cto
            })
            i := i + 1
        }
    }

    ; ===== Points =====
    data.Points := []
    if (profile.Has("Points") && IsObject(profile["Points"])) {
        i := 1
        while (i <= profile["Points"].Length) {
            p := profile["Points"][i]
            id  := OM_Get(p, "Id", 0)
            nm  := OM_Get(p, "Name", "")
            x   := OM_Get(p, "X", 0)
            y   := OM_Get(p, "Y", 0)
            col := OM_Get(p, "Color", "0x000000")
            tol := OM_Get(p, "Tol", 10)
            data.Points.Push({ Id: id, Name: nm, X: x, Y: y, Color: col, Tol: tol })
            i := i + 1
        }
    }

    ; ===== Rules（Id → Index）=====
    data.Rules := []
    if (profile.Has("Rules") && IsObject(profile["Rules"])) {
        i := 1
        while (i <= profile["Rules"].Length) {
            r := profile["Rules"][i]
            rid  := OM_Get(r, "Id", 0)
            nm   := OM_Get(r, "Name", "Rule")
            en   := OM_Get(r, "Enabled", 1)
            lg   := OM_Get(r, "Logic", "AND")
            cd   := OM_Get(r, "CooldownMs", 500)
            pr   := OM_Get(r, "Priority", i)
            gap  := OM_Get(r, "ActionGapMs", 60)
            th   := OM_Get(r, "ThreadId", 1)
            sto  := OM_Get(r, "SessionTimeoutMs", 0)
            abo  := OM_Get(r, "AbortCooldownMs", 0)

            conds := []
            if (r.Has("Conditions") && IsObject(r["Conditions"])) {
                j := 1
                while (j <= r["Conditions"].Length) {
                    c := r["Conditions"][j]
                    kind := OM_Get(c, "Kind", "")
                    kindU := StrUpper(kind)
                    if (kindU = "COUNTER") {
                        sid2 := OM_Get(c, "SkillId", 0)
                        cmp := OM_Get(c, "Cmp", "GE")
                        val := OM_Get(c, "Value", 1)
                        rst := OM_Get(c, "ResetOnTrigger", 0)
                        conds.Push({ Kind: "Counter", SkillIndex: (sid2>0 ? PM_SkillIndexById(profile, sid2) : 0), Cmp: cmp, Value: val, ResetOnTrigger: rst })
                    } else {
                        rt  := OM_Get(c, "RefType", "Skill")
                        rid2 := OM_Get(c, "RefId", 0)
                        op  := OM_Get(c, "Op", "EQ")
                        conds.Push({ RefType: rt, RefIndex: (StrUpper(rt)="SKILL" ? PM_SkillIndexById(profile, rid2) : PM_PointIndexById(profile, rid2)), Op: op, UseRefXY: 1, X: 0, Y: 0 })
                    }
                    j := j + 1
                }
            }

            acts := []
            if (r.Has("Actions") && IsObject(r["Actions"])) {
                j := 1
                while (j <= r["Actions"].Length) {
                    a := r["Actions"][j]
                    sid3 := OM_Get(a, "SkillId", 0)
                    d   := OM_Get(a, "DelayMs", 0)
                    h   := OM_Get(a, "HoldMs", -1)
                    rr  := OM_Get(a, "RequireReady", 0)
                    vf  := OM_Get(a, "Verify", 0)
                    vto := OM_Get(a, "VerifyTimeoutMs", 600)
                    rt  := OM_Get(a, "Retry", 0)
                    rg  := OM_Get(a, "RetryGapMs", 150)
                    acts.Push({ SkillIndex: (sid3>0 ? PM_SkillIndexById(profile, sid3) : 0), DelayMs: d, HoldMs: h, RequireReady: rr
                              , Verify: vf, VerifyTimeoutMs: vto, Retry: rt, RetryGapMs: rg })
                    j := j + 1
                }
            }

            data.Rules.Push({ Id: rid, Name: nm, Enabled: en, Logic: lg, CooldownMs: cd, Priority: pr
                            , ActionGapMs: gap, ThreadId: th, Conditions: conds, Actions: acts, LastFire: 0
                            , SessionTimeoutMs: sto, AbortCooldownMs: abo })
            i := i + 1
        }
    }

    ; ===== Buffs（SkillId → SkillIndex）=====
    data.Buffs := []
    if (profile.Has("Buffs") && IsObject(profile["Buffs"])) {
        i := 1
        while (i <= profile["Buffs"].Length) {
            b := profile["Buffs"][i]
            id := 0
            nm := "Buff"
            en := 1
            dur := 0
            ref := 0
            chk := 1
            th  := 1

            try {
                id := OM_Get(b, "Id", 0)
            } catch {
                id := 0
            }
            try {
                nm := OM_Get(b, "Name", "Buff")
            } catch {
                nm := "Buff"
            }
            try {
                en := OM_Get(b, "Enabled", 1)
            } catch {
                en := 1
            }
            try {
                dur := OM_Get(b, "DurationMs", 0)
            } catch {
                dur := 0
            }
            try {
                ref := OM_Get(b, "RefreshBeforeMs", 0)
            } catch {
                ref := 0
            }
            try {
                chk := OM_Get(b, "CheckReady", 1)
            } catch {
                chk := 1
            }
            try {
                th := OM_Get(b, "ThreadId", 1)
            } catch {
                th := 1
            }

            skills := []
            try {
                if (b.Has("Skills") && IsObject(b["Skills"])) {
                    j := 1
                    while (j <= b["Skills"].Length) {
                        sid4 := 0
                        try {
                            sid4 := b["Skills"][j]
                        } catch {
                            sid4 := 0
                        }
                        idx := 0
                        try {
                            idx := (sid4 > 0) ? PM_SkillIndexById(profile, sid4) : 0
                        } catch {
                            idx := 0
                        }
                        skills.Push(idx)
                        j := j + 1
                    }
                }
            } catch {
            }

            data.Buffs.Push({ Id: id, Name: nm, Enabled: en, DurationMs: dur, RefreshBeforeMs: ref, CheckReady: chk
                            , ThreadId: th, Skills: skills, LastTime: 0, NextIdx: 1 })
            i := i + 1
        }
    }

    ; ===== Rotation 基础 =====
    data.Rotation := { Enabled: 0
                     , DefaultTrackId: 1
                     , SwapKey: ""
                     , BusyWindowMs: 200
                     , ColorTolBlack: 16
                     , RespectCastLock: 1
                     , GatesEnabled: 0
                     , GateCooldownMs: 0
                     , VerifySwap: 0
                     , SwapTimeoutMs: 800
                     , SwapRetry: 0
                     , SwapVerify: { RefType: "Skill", RefIndex: 0, Op: "NEQ", Color: "0x000000", Tol: 16 }
                     , BlackGuard: { Enabled: 1, SampleCount: 5, BlackRatioThresh: 0.7, WindowMs: 120, CooldownMs: 600, MinAfterSendMs: 60, MaxAfterSendMs: 800, UniqueRequired: 1 }
                     , Opener: { Enabled: 0, MaxDurationMs: 4000, Watch: [], StepsCount: 0, Steps: [] }
                     , Tracks: []
                     , Gates: [] }

    rot := Map()
    if (profile.Has("Rotation")) {
        rot := profile["Rotation"]
    }

    data.Rotation.Enabled        := OM_Get(rot, "Enabled", data.Rotation.Enabled)
    data.Rotation.DefaultTrackId := OM_Get(rot, "DefaultTrackId", data.Rotation.DefaultTrackId)
    data.Rotation.SwapKey        := OM_Get(rot, "SwapKey", data.Rotation.SwapKey)
    data.Rotation.BusyWindowMs   := OM_Get(rot, "BusyWindowMs", data.Rotation.BusyWindowMs)
    data.Rotation.ColorTolBlack  := OM_Get(rot, "ColorTolBlack", data.Rotation.ColorTolBlack)
    data.Rotation.RespectCastLock:= OM_Get(rot, "RespectCastLock", data.Rotation.RespectCastLock)
    data.Rotation.GatesEnabled   := OM_Get(rot, "GatesEnabled", data.Rotation.GatesEnabled)
    data.Rotation.GateCooldownMs := OM_Get(rot, "GateCooldownMs", data.Rotation.GateCooldownMs)

    ; BlackGuard
    if (rot.Has("BlackGuard") && IsObject(rot["BlackGuard"])) {
        bg0 := rot["BlackGuard"]
        bg := data.Rotation.BlackGuard
        bg.Enabled         := OM_Get(bg0, "Enabled", bg.Enabled)
        bg.SampleCount     := OM_Get(bg0, "SampleCount", bg.SampleCount)
        bg.BlackRatioThresh:= OM_Get(bg0, "BlackRatioThresh", bg.BlackRatioThresh)
        bg.WindowMs        := OM_Get(bg0, "WindowMs", bg.WindowMs)
        bg.CooldownMs      := OM_Get(bg0, "CooldownMs", bg.CooldownMs)
        bg.MinAfterSendMs  := OM_Get(bg0, "MinAfterSendMs", bg.MinAfterSendMs)
        bg.MaxAfterSendMs  := OM_Get(bg0, "MaxAfterSendMs", bg.MaxAfterSendMs)
        bg.UniqueRequired  := OM_Get(bg0, "UniqueRequired", bg.UniqueRequired)
        data.Rotation.BlackGuard := bg
    }

    ; SwapVerify & VerifySwap
    if (rot.Has("SwapVerify") && IsObject(rot["SwapVerify"])) {
        sv := rot["SwapVerify"]
        svRefType  := OM_Get(sv, "RefType", "Skill")
        refId      := OM_Get(sv, "RefId", 0)
        svRefIndex := (StrUpper(svRefType) = "SKILL") ? PM_SkillIndexById(profile, refId) : PM_PointIndexById(profile, refId)
        svOp       := OM_Get(sv, "Op", "NEQ")
        svColor    := OM_Get(sv, "Color", "0x000000")
        svTol      := OM_Get(sv, "Tol", 16)
        data.Rotation.SwapVerify := { RefType: svRefType, RefIndex: svRefIndex, Op: svOp, Color: svColor, Tol: svTol }
    }
    data.Rotation.VerifySwap    := OM_Get(rot, "VerifySwap", data.Rotation.VerifySwap)
    data.Rotation.SwapTimeoutMs := OM_Get(rot, "SwapTimeoutMs", data.Rotation.SwapTimeoutMs)
    data.Rotation.SwapRetry     := OM_Get(rot, "SwapRetry", data.Rotation.SwapRetry)

    ; Opener
    if (rot.Has("Opener") && IsObject(rot["Opener"])) {
        op0 := rot["Opener"]
        data.Rotation.Opener.Enabled       := OM_Get(op0, "Enabled", data.Rotation.Opener.Enabled)
        data.Rotation.Opener.MaxDurationMs := OM_Get(op0, "MaxDurationMs", data.Rotation.Opener.MaxDurationMs)

        data.Rotation.Opener.Watch := []
        if (op0.Has("Watch") && IsObject(op0["Watch"])) {
            i := 1
            while (i <= op0["Watch"].Length) {
                w := op0["Watch"][i]
                sidw  := OM_Get(w, "SkillId", 0)
                idxw  := 0
                try {
                    idxw := (sidw>0 ? PM_SkillIndexById(profile, sidw) : 0)
                } catch {
                    idxw := 0
                }

                if (dbgRt) {
                    if (sidw > 0) {
                        if (idxw = 0) {
                            fW := Map()
                            try {
                                fW["SkillId"] := sidw
                                fW["Section"] := "Opener.Watch"
                                fW["Row"] := i
                                Logger_Warn("Runtime", "Watch SkillId→Index failed", fW)
                            } catch {
                            }
                        }
                    }
                }

                need := OM_Get(w, "RequireCount", 1)
                vb   := OM_Get(w, "VerifyBlack", 0)
                data.Rotation.Opener.Watch.Push({ SkillIndex: idxw, RequireCount: need, VerifyBlack: vb })
                i := i + 1
            }
        }

        steps := []
        if (op0.Has("Steps") && IsObject(op0["Steps"])) {
            i := 1
            while (i <= op0["Steps"].Length) {
                st := op0["Steps"][i]
                k  := OM_Get(st, "Kind", "")
                kU := StrUpper(k)
                if (kU = "SKILL") {
                    sids  := OM_Get(st, "SkillId", 0)
                    idxs  := 0
                    try {
                        idxs := (sids>0 ? PM_SkillIndexById(profile, sids) : 0)
                    } catch {
                        idxs := 0
                    }
                    if (dbgRt) {
                        if (sids > 0) {
                            if (idxs = 0) {
                                fS := Map()
                                try {
                                    fS["SkillId"] := sids
                                    fS["Section"] := "Opener.Steps"
                                    fS["Row"] := i
                                    Logger_Warn("Runtime", "Watch SkillId→Index failed", fS)
                                } catch {
                                }
                            }
                        }
                    }
                    rr   := OM_Get(st, "RequireReady", 0)
                    pre  := OM_Get(st, "PreDelayMs", 0)
                    hold := OM_Get(st, "HoldMs", 0)
                    vf   := OM_Get(st, "Verify", 0)
                    to   := OM_Get(st, "TimeoutMs", 1200)
                    dur  := OM_Get(st, "DurationMs", 0)
                    steps.Push({ Kind: "Skill", SkillIndex: idxs, RequireReady: rr, PreDelayMs: pre, HoldMs: hold, Verify: vf, TimeoutMs: to, DurationMs: dur })
                } else if (kU = "WAIT") {
                    dur := OM_Get(st, "DurationMs", 0)
                    steps.Push({ Kind: "Wait", DurationMs: dur })
                } else if (kU = "SWAP") {
                    to := OM_Get(st, "TimeoutMs", 800)
                    rt := OM_Get(st, "Retry", 0)
                    steps.Push({ Kind: "Swap", TimeoutMs: to, Retry: rt })
                }
                i := i + 1
            }
        }
        data.Rotation.Opener.Steps := steps
        data.Rotation.Opener.StepsCount := steps.Length
    }

    ; Tracks（Watch SkillId→Index；RuleRefs RuleId→Index；Track.Id/Name 保留）
    data.Rotation.Tracks := []
    if (rot.Has("Tracks") && IsObject(rot["Tracks"])) {
        i := 1
        while (i <= rot["Tracks"].Length) {
            t := rot["Tracks"][i]
            tr := { Id: 0, Name: "", ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [], RuleRefs: [] }
            tr.Id           := OM_Get(t, "Id", 0)
            tr.Name         := OM_Get(t, "Name", "")
            tr.ThreadId     := OM_Get(t, "ThreadId", 1)
            tr.MaxDurationMs:= OM_Get(t, "MaxDurationMs", 8000)
            tr.MinStayMs    := OM_Get(t, "MinStayMs", 0)
            tr.NextTrackId  := OM_Get(t, "NextTrackId", 0)

            if (t.Has("Watch") && IsObject(t["Watch"])) {
                j := 1
                while (j <= t["Watch"].Length) {
                    w := t["Watch"][j]
                    sid  := OM_Get(w, "SkillId", 0)
                    idx  := 0
                    try {
                        idx := (sid>0 ? PM_SkillIndexById(profile, sid) : 0)
                    } catch {
                        idx := 0
                    }

                    if (dbgRt) {
                        if (sid > 0) {
                            if (idx = 0) {
                                f3 := Map()
                                try {
                                    f3["SkillId"] := sid
                                    f3["TrackRow"] := i
                                    f3["WatchIdx"] := j
                                    Logger_Warn("Runtime", "Watch SkillId→Index failed", f3)
                                } catch {
                                }
                            }
                        }
                    }

                    need := OM_Get(w, "RequireCount", 1)
                    vb   := OM_Get(w, "VerifyBlack", 0)
                    tr.Watch.Push({ SkillIndex: idx, RequireCount: need, VerifyBlack: vb })
                    j := j + 1
                }
            }
            if (t.Has("RuleRefs") && IsObject(t["RuleRefs"])) {
                j := 1
                while (j <= t["RuleRefs"].Length) {
                    rid := 0
                    try {
                        rid := t["RuleRefs"][j]
                    } catch {
                        rid := 0
                    }
                    idx2 := 0
                    try {
                        idx2 := (rid>0 ? PM_RuleIndexById(profile, rid) : 0)
                    } catch {
                        idx2 := 0
                    }

                    if (dbgRt) {
                        if (rid > 0) {
                            if (idx2 = 0) {
                                f4 := Map()
                                try {
                                    f4["RuleId"] := rid
                                    f4["TrackRow"] := i
                                    f4["RefIdx"] := j
                                    Logger_Warn("Runtime", "RuleRef RuleId→Index failed", f4)
                                } catch {
                                }
                            }
                        }
                    }

                    tr.RuleRefs.Push(idx2)
                    j := j + 1
                }
            }
            data.Rotation.Tracks.Push(tr)
            i := i + 1
        }
    }

    ; Gates（Conds RefId→RefIndex；RuleId→规则索引）
    data.Rotation.Gates := []
    if (rot.Has("Gates") && IsObject(rot["Gates"])) {
        i := 1
        while (i <= rot["Gates"].Length) {
            g0 := rot["Gates"][i]
            g := { Priority: i, FromTrackId: 0, ToTrackId: 0, Logic: "AND", Conds: [] }
            g.Priority   := OM_Get(g0, "Priority", i)
            g.FromTrackId:= OM_Get(g0, "FromTrackId", 0)
            g.ToTrackId  := OM_Get(g0, "ToTrackId", 0)
            g.Logic      := OM_Get(g0, "Logic", "AND")

            if (g0.Has("Conds") && IsObject(g0["Conds"])) {
                j := 1
                while (j <= g0["Conds"].Length) {
                    c0 := g0["Conds"][j]
                    kind := OM_Get(c0, "Kind", "")
                    kindU := StrUpper(kind)
                    if (kindU = "PIXELREADY") {
                        rtype := OM_Get(c0, "RefType", "Skill")
                        rid   := OM_Get(c0, "RefId", 0)
                        op    := OM_Get(c0, "Op", "NEQ")
                        col   := OM_Get(c0, "Color", "0x000000")
                        tol   := OM_Get(c0, "Tol", 16)
                        q     := OM_Get(c0, "QuietMs", 0)
                        cmp   := OM_Get(c0, "Cmp", "GE")
                        val   := OM_Get(c0, "Value", 0)
                        ems   := OM_Get(c0, "ElapsedMs", 0)

                        refIdx := 0
                        try {
                            refIdx := (StrUpper(rtype)="SKILL" ? PM_SkillIndexById(profile, rid) : PM_PointIndexById(profile, rid))
                        } catch {
                            refIdx := 0
                        }
                        if (dbgRt) {
                            if (rid > 0) {
                                if (refIdx = 0) {
                                    f5 := Map()
                                    try {
                                        f5["RefType"] := rtype
                                        f5["RefId"] := rid
                                        f5["GateRow"] := i
                                        f5["CondIdx"] := j
                                        Logger_Warn("Runtime", "Gate RefId→Index failed", f5)
                                    } catch {
                                    }
                                }
                            }
                        }

                        ruleIdx := 0
                        try {
                            ruleIdx := (rid>0 ? PM_RuleIndexById(profile, rid) : 0)
                        } catch {
                            ruleIdx := 0
                        }
                        if (dbgRt) {
                            if (rid > 0) {
                                if (ruleIdx = 0) {
                                    f6 := Map()
                                    try {
                                        f6["RuleId"] := rid
                                        f6["GateRow"] := i
                                        f6["CondIdx"] := j
                                        Logger_Warn("Runtime", "Gate RuleId→Index failed", f6)
                                    } catch {
                                    }
                                }
                            }
                        }

                        g.Conds.Push({ Kind: "PixelReady", RefType: rtype, RefIndex: refIdx
                                     , Op: op, Color: col, Tol: tol, RuleId: ruleIdx, QuietMs: q, Cmp: cmp, Value: val, ElapsedMs: ems })
                    } else if (kindU = "RULEQUIET") {
                        rid2 := OM_Get(c0, "RuleId", 0)
                        ruleIdx2 := 0
                        try {
                            ruleIdx2 := (rid2>0 ? PM_RuleIndexById(profile, rid2) : 0)
                        } catch {
                            ruleIdx2 := 0
                        }
                        if (dbgRt) {
                            if (rid2 > 0) {
                                if (ruleIdx2 = 0) {
                                    f7 := Map()
                                    try {
                                        f7["RuleId"] := rid2
                                        f7["GateRow"] := i
                                        f7["CondIdx"] := j
                                        Logger_Warn("Runtime", "Gate RuleId→Index failed", f7)
                                    } catch {
                                    }
                                }
                            }
                        }
                        q2   := OM_Get(c0, "QuietMs", 0)
                        g.Conds.Push({ Kind: "RuleQuiet", RuleId: ruleIdx2, QuietMs: q2 })
                    } else if (kindU = "COUNTER") {
                        sid5 := OM_Get(c0, "SkillId", 0)
                        idxc := 0
                        try {
                            idxc := (sid5>0 ? PM_SkillIndexById(profile, sid5) : 0)
                        } catch {
                            idxc := 0
                        }
                        if (dbgRt) {
                            if (sid5 > 0) {
                                if (idxc = 0) {
                                    f8 := Map()
                                    try {
                                        f8["SkillId"] := sid5
                                        f8["GateRow"] := i
                                        f8["CondIdx"] := j
                                        Logger_Warn("Runtime", "Gate Counter SkillId→Index failed", f8)
                                    } catch {
                                    }
                                }
                            }
                        }
                        cmp2 := OM_Get(c0, "Cmp", "GE")
                        val2 := OM_Get(c0, "Value", 1)
                        g.Conds.Push({ Kind: "Counter", RefType: "Skill", RefIndex: idxc, Cmp: cmp2, Value: val2 })
                    } else if (kindU = "ELAPSED") {
                        cmp3 := OM_Get(c0, "Cmp", "GE")
                        ems  := OM_Get(c0, "ElapsedMs", 0)
                        g.Conds.Push({ Kind: "Elapsed", Cmp: cmp3, ElapsedMs: ems })
                    } else {
                        rtype2 := OM_Get(c0, "RefType", "Skill")
                        rid3   := OM_Get(c0, "RefId", 0)
                        idx3 := 0
                        try {
                            idx3 := (StrUpper(rtype2)="SKILL" ? PM_SkillIndexById(profile, rid3) : PM_PointIndexById(profile, rid3))
                        } catch {
                            idx3 := 0
                        }
                        if (dbgRt) {
                            if (rid3 > 0) {
                                if (idx3 = 0) {
                                    f9 := Map()
                                    try {
                                        f9["RefType"] := rtype2
                                        f9["RefId"] := rid3
                                        f9["GateRow"] := i
                                        f9["CondIdx"] := j
                                        Logger_Warn("Runtime", "Gate RefId→Index failed", f9)
                                    } catch {
                                    }
                                }
                            }
                        }
                        g.Conds.Push({ Kind: "PixelReady", RefType: rtype2, RefIndex: idx3, Op: "NEQ", Color: "0x000000", Tol: 16 })
                    }
                    j := j + 1
                }
            }
            data.Rotation.Gates.Push(g)
            i := i + 1
        }
    }

    return data
}