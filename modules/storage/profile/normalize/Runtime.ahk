#Requires AutoHotkey v2
;modules\storage\profile\Normalize_Runtime.ahk
; 将“文件夹-模块化-Id引用”Profile 转为“引擎可用的索引引用”结构（运行时模型）
; 注意：不使用 ByRef；不使用单行 if/try/catch

PM_ToRuntime(profile) {
    data := Core_DefaultProfileData()

    ; 名称
    if (IsObject(profile) && profile.Has("Name")) {
        data.Name := profile["Name"]
    }

    ; 构建 Id 映射（供下方 Id→Index 用）
    PM_BuildIdMaps(profile)

    ; ===== General =====
    g := Map()
    if (profile.Has("General")) {
        g := profile["General"]
    }

    if (g.Has("StartHotkey")) {
        data.StartHotkey := g["StartHotkey"]
    }
    if (g.Has("PollIntervalMs")) {
        data.PollIntervalMs := g["PollIntervalMs"]
    }
    if (g.Has("SendCooldownMs")) {
        data.SendCooldownMs := g["SendCooldownMs"]
    }
    if (g.Has("PickHoverEnabled")) {
        data.PickHoverEnabled := g["PickHoverEnabled"]
    }
    if (g.Has("PickHoverOffsetY")) {
        data.PickHoverOffsetY := g["PickHoverOffsetY"]
    }
    if (g.Has("PickHoverDwellMs")) {
        data.PickHoverDwellMs := g["PickHoverDwellMs"]
    }
    if (g.Has("PickConfirmKey")) {
        data.PickConfirmKey := g["PickConfirmKey"]
    } else {
        data.PickConfirmKey := "LButton"
    }

    ; Threads
    data.Threads := []
    if (g.Has("Threads") && IsObject(g["Threads"])) {
        i := 1
        while (i <= g["Threads"].Length) {
            t := g["Threads"][i]
            tid := 1
            tname := "线程" i
            if (IsObject(t)) {
                if (t.Has("Id")) {
                    tid := t["Id"]
                }
                if (t.Has("Name")) {
                    tname := t["Name"]
                }
            }
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
        if (ds.Has("Enabled")) {
            data.DefaultSkill.Enabled := ds["Enabled"]
        }
        idx := 0
        if (ds.Has("SkillId")) {
            idx := PM_SkillIndexById(profile, ds["SkillId"])
        }
        data.DefaultSkill.SkillIndex := idx
        if (ds.Has("CheckReady")) {
            data.DefaultSkill.CheckReady := ds["CheckReady"]
        }
        if (ds.Has("ThreadId")) {
            data.DefaultSkill.ThreadId := ds["ThreadId"]
        }
        if (ds.Has("CooldownMs")) {
            data.DefaultSkill.CooldownMs := ds["CooldownMs"]
        }
        if (ds.Has("PreDelayMs")) {
            data.DefaultSkill.PreDelayMs := ds["PreDelayMs"]
        }
        data.DefaultSkill.LastFire := 0
    }

    ; ===== Skills =====
    data.Skills := []
    if (profile.Has("Skills") && IsObject(profile["Skills"])) {
        i := 1
        while (i <= profile["Skills"].Length) {
            s := profile["Skills"][i]
            nm := ""
            key := ""
            x := 0
            y := 0
            col := "0x000000"
            tol := 10
            cast := 0
            if (IsObject(s)) {
                if (s.Has("Name")) {
                    nm := s["Name"]
                }
                if (s.Has("Key")) {
                    key := s["Key"]
                }
                if (s.Has("X")) {
                    x := s["X"]
                }
                if (s.Has("Y")) {
                    y := s["Y"]
                }
                if (s.Has("Color")) {
                    col := s["Color"]
                }
                if (s.Has("Tol")) {
                    tol := s["Tol"]
                }
                if (s.Has("CastMs")) {
                    cast := s["CastMs"]
                }
            }
            data.Skills.Push({ Name: nm, Key: key, X: x, Y: y, Color: col, Tol: tol, CastMs: cast })
            i := i + 1
        }
    }

    ; ===== Points =====
    data.Points := []
    if (profile.Has("Points") && IsObject(profile["Points"])) {
        i := 1
        while (i <= profile["Points"].Length) {
            p := profile["Points"][i]
            nm := ""
            x := 0
            y := 0
            col := "0x000000"
            tol := 10
            if (IsObject(p)) {
                if (p.Has("Name")) {
                    nm := p["Name"]
                }
                if (p.Has("X")) {
                    x := p["X"]
                }
                if (p.Has("Y")) {
                    y := p["Y"]
                }
                if (p.Has("Color")) {
                    col := p["Color"]
                }
                if (p.Has("Tol")) {
                    tol := p["Tol"]
                }
            }
            data.Points.Push({ Name: nm, X: x, Y: y, Color: col, Tol: tol })
            i := i + 1
        }
    }

    ; ===== Rules（Id → Index）=====
    data.Rules := []
    if (profile.Has("Rules") && IsObject(profile["Rules"])) {
        i := 1
        while (i <= profile["Rules"].Length) {
            r := profile["Rules"][i]
            nm := "Rule"
            en := 1
            lg := "AND"
            cd := 500
            pr := i
            gap := 60
            th := 1
            sto := 0
            abo := 0
            if (IsObject(r)) {
                if (r.Has("Name")) {
                    nm := r["Name"]
                }
                if (r.Has("Enabled")) {
                    en := r["Enabled"]
                }
                if (r.Has("Logic")) {
                    lg := r["Logic"]
                }
                if (r.Has("CooldownMs")) {
                    cd := r["CooldownMs"]
                }
                if (r.Has("Priority")) {
                    pr := r["Priority"]
                }
                if (r.Has("ActionGapMs")) {
                    gap := r["ActionGapMs"]
                }
                if (r.Has("ThreadId")) {
                    th := r["ThreadId"]
                }
                if (r.Has("SessionTimeoutMs")) {
                    sto := r["SessionTimeoutMs"]
                }
                if (r.Has("AbortCooldownMs")) {
                    abo := r["AbortCooldownMs"]
                }
            }

            conds := []
            if (IsObject(r) && r.Has("Conditions") && IsObject(r["Conditions"])) {
                j := 1
                while (j <= r["Conditions"].Length) {
                    c := r["Conditions"][j]
                    kind := ""
                    if (IsObject(c) && c.Has("Kind")) {
                        kind := c["Kind"]
                    }
                    kindU := StrUpper(kind)
                    if (kindU = "COUNTER") {
                        si := 0
                        cmp := "GE"
                        val := 1
                        rst := 0
                        if (c.Has("SkillId")) {
                            si := PM_SkillIndexById(profile, c["SkillId"])
                        }
                        if (c.Has("Cmp")) {
                            cmp := c["Cmp"]
                        }
                        if (c.Has("Value")) {
                            val := c["Value"]
                        }
                        if (c.Has("ResetOnTrigger")) {
                            rst := c["ResetOnTrigger"]
                        }
                        conds.Push({ Kind: "Counter", SkillIndex: si, Cmp: cmp, Value: val, ResetOnTrigger: rst })
                    } else {
                        rt := "Skill"
                        ridx := 0
                        op := "EQ"
                        if (c.Has("RefType")) {
                            rt := c["RefType"]
                        }
                        if (StrUpper(rt) = "SKILL") {
                            if (c.Has("RefId")) {
                                ridx := PM_SkillIndexById(profile, c["RefId"])
                            }
                        } else {
                            if (c.Has("RefId")) {
                                ridx := PM_PointIndexById(profile, c["RefId"])
                            }
                        }
                        if (c.Has("Op")) {
                            op := c["Op"]
                        }
                        ; 运行时旧模型里 Pixel 条件一般使用引用的 X/Y（UseRefXY=1），提供 X/Y 备用
                        conds.Push({ RefType: rt, RefIndex: ridx, Op: op, UseRefXY: 1, X: 0, Y: 0 })
                    }
                    j := j + 1
                }
            }

            acts := []
            if (IsObject(r) && r.Has("Actions") && IsObject(r["Actions"])) {
                j := 1
                while (j <= r["Actions"].Length) {
                    a := r["Actions"][j]
                    si := 0
                    d := 0
                    h := -1
                    rr := 0
                    vf := 0
                    vto := 600
                    rt := 0
                    rg := 150
                    if (IsObject(a)) {
                        if (a.Has("SkillId")) {
                            si := PM_SkillIndexById(profile, a["SkillId"])
                        }
                        if (a.Has("DelayMs")) {
                            d := a["DelayMs"]
                        }
                        if (a.Has("HoldMs")) {
                            h := a["HoldMs"]
                        }
                        if (a.Has("RequireReady")) {
                            rr := a["RequireReady"]
                        }
                        if (a.Has("Verify")) {
                            vf := a["Verify"]
                        }
                        if (a.Has("VerifyTimeoutMs")) {
                            vto := a["VerifyTimeoutMs"]
                        }
                        if (a.Has("Retry")) {
                            rt := a["Retry"]
                        }
                        if (a.Has("RetryGapMs")) {
                            rg := a["RetryGapMs"]
                        }
                    }
                    acts.Push({ SkillIndex: si, DelayMs: d, HoldMs: h, RequireReady: rr
                              , Verify: vf, VerifyTimeoutMs: vto, Retry: rt, RetryGapMs: rg })
                    j := j + 1
                }
            }

            data.Rules.Push({ Name: nm, Enabled: en, Logic: lg, CooldownMs: cd, Priority: pr
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
            nm := "Buff"
            en := 1
            dur := 0
            ref := 0
            chk := 1
            th := 1
            if (IsObject(b)) {
                if (b.Has("Name")) {
                    nm := b["Name"]
                }
                if (b.Has("Enabled")) {
                    en := b["Enabled"]
                }
                if (b.Has("DurationMs")) {
                    dur := b["DurationMs"]
                }
                if (b.Has("RefreshBeforeMs")) {
                    ref := b["RefreshBeforeMs"]
                }
                if (b.Has("CheckReady")) {
                    chk := b["CheckReady"]
                }
                if (b.Has("ThreadId")) {
                    th := b["ThreadId"]
                }
            }

            skills := []
            if (IsObject(b) && b.Has("Skills") && IsObject(b["Skills"])) {
                j := 1
                while (j <= b["Skills"].Length) {
                    idx := 0
                    if (IsObject(b["Skills"]) && b["Skills"][j] != "") {
                        idx := PM_SkillIndexById(profile, b["Skills"][j])
                    }
                    skills.Push(idx)
                    j := j + 1
                }
            }
            data.Buffs.Push({ Name: nm, Enabled: en, DurationMs: dur, RefreshBeforeMs: ref, CheckReady: chk
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

    if (rot.Has("Enabled")) {
        data.Rotation.Enabled := rot["Enabled"]
    }
    if (rot.Has("DefaultTrackId")) {
        data.Rotation.DefaultTrackId := rot["DefaultTrackId"]
    }
    if (rot.Has("SwapKey")) {
        data.Rotation.SwapKey := rot["SwapKey"]
    }
    if (rot.Has("BusyWindowMs")) {
        data.Rotation.BusyWindowMs := rot["BusyWindowMs"]
    }
    if (rot.Has("ColorTolBlack")) {
        data.Rotation.ColorTolBlack := rot["ColorTolBlack"]
    }
    if (rot.Has("RespectCastLock")) {
        data.Rotation.RespectCastLock := rot["RespectCastLock"]
    }
    if (rot.Has("GatesEnabled")) {
        data.Rotation.GatesEnabled := rot["GatesEnabled"]
    }
    if (rot.Has("GateCooldownMs")) {
        data.Rotation.GateCooldownMs := rot["GateCooldownMs"]
    }

    ; BlackGuard
    if (rot.Has("BlackGuard") && IsObject(rot["BlackGuard"])) {
        bg0 := rot["BlackGuard"]
        bg := data.Rotation.BlackGuard
        if (bg0.Has("Enabled")) {
            bg.Enabled := bg0["Enabled"]
        }
        if (bg0.Has("SampleCount")) {
            bg.SampleCount := bg0["SampleCount"]
        }
        if (bg0.Has("BlackRatioThresh")) {
            bg.BlackRatioThresh := bg0["BlackRatioThresh"]
        }
        if (bg0.Has("WindowMs")) {
            bg.WindowMs := bg0["WindowMs"]
        }
        if (bg0.Has("CooldownMs")) {
            bg.CooldownMs := bg0["CooldownMs"]
        }
        if (bg0.Has("MinAfterSendMs")) {
            bg.MinAfterSendMs := bg0["MinAfterSendMs"]
        }
        if (bg0.Has("MaxAfterSendMs")) {
            bg.MaxAfterSendMs := bg0["MaxAfterSendMs"]
        }
        if (bg0.Has("UniqueRequired")) {
            bg.UniqueRequired := bg0["UniqueRequired"]
        }
        data.Rotation.BlackGuard := bg
    }

    ; SwapVerify & VerifySwap
    if (rot.Has("SwapVerify") && IsObject(rot["SwapVerify"])) {
        sv := rot["SwapVerify"]
        svRefType := "Skill"
        svRefIndex := 0
        svOp := "NEQ"
        svColor := "0x000000"
        svTol := 16
        if (sv.Has("RefType")) {
            svRefType := sv["RefType"]
        }
        if (StrUpper(svRefType) = "SKILL") {
            if (sv.Has("RefId")) {
                svRefIndex := PM_SkillIndexById(profile, sv["RefId"])
            }
        } else {
            if (sv.Has("RefId")) {
                svRefIndex := PM_PointIndexById(profile, sv["RefId"])
            }
        }
        if (sv.Has("Op")) {
            svOp := sv["Op"]
        }
        if (sv.Has("Color")) {
            svColor := sv["Color"]
        }
        if (sv.Has("Tol")) {
            svTol := sv["Tol"]
        }
        data.Rotation.SwapVerify := { RefType: svRefType, RefIndex: svRefIndex, Op: svOp, Color: svColor, Tol: svTol }
    }
    if (rot.Has("VerifySwap")) {
        data.Rotation.VerifySwap := rot["VerifySwap"]
    }
    if (rot.Has("SwapTimeoutMs")) {
        data.Rotation.SwapTimeoutMs := rot["SwapTimeoutMs"]
    }
    if (rot.Has("SwapRetry")) {
        data.Rotation.SwapRetry := rot["SwapRetry"]
    }

    ; Opener（Watch SkillId→Index，Steps SkillId→Index）
    if (rot.Has("Opener") && IsObject(rot["Opener"])) {
        op0 := rot["Opener"]
        if (op0.Has("Enabled")) {
            data.Rotation.Opener.Enabled := op0["Enabled"]
        }
        if (op0.Has("MaxDurationMs")) {
            data.Rotation.Opener.MaxDurationMs := op0["MaxDurationMs"]
        }

        data.Rotation.Opener.Watch := []
        if (op0.Has("Watch") && IsObject(op0["Watch"])) {
            i := 1
            while (i <= op0["Watch"].Length) {
                w := op0["Watch"][i]
                idx := 0
                need := 1
                vb := 0
                if (IsObject(w)) {
                    if (w.Has("SkillId")) {
                        idx := PM_SkillIndexById(profile, w["SkillId"])
                    }
                    if (w.Has("RequireCount")) {
                        need := w["RequireCount"]
                    }
                    if (w.Has("VerifyBlack")) {
                        vb := w["VerifyBlack"]
                    }
                }
                data.Rotation.Opener.Watch.Push({ SkillIndex: idx, RequireCount: need, VerifyBlack: vb })
                i := i + 1
            }
        }

        steps := []
        if (op0.Has("Steps") && IsObject(op0["Steps"])) {
            i := 1
            while (i <= op0["Steps"].Length) {
                st := op0["Steps"][i]
                if (IsObject(st)) {
                    k := ""
                    if (st.Has("Kind")) {
                        k := st["Kind"]
                    }
                    kU := StrUpper(k)
                    if (kU = "SKILL") {
                        idx := 0
                        rr := 0
                        pre := 0
                        hold := 0
                        vf := 0
                        to := 1200
                        dur := 0
                        if (st.Has("SkillId")) {
                            idx := PM_SkillIndexById(profile, st["SkillId"])
                        }
                        if (st.Has("RequireReady")) {
                            rr := st["RequireReady"]
                        }
                        if (st.Has("PreDelayMs")) {
                            pre := st["PreDelayMs"]
                        }
                        if (st.Has("HoldMs")) {
                            hold := st["HoldMs"]
                        }
                        if (st.Has("Verify")) {
                            vf := st["Verify"]
                        }
                        if (st.Has("TimeoutMs")) {
                            to := st["TimeoutMs"]
                        }
                        if (st.Has("DurationMs")) {
                            dur := st["DurationMs"]
                        }
                        steps.Push({ Kind: "Skill", SkillIndex: idx, RequireReady: rr, PreDelayMs: pre, HoldMs: hold, Verify: vf, TimeoutMs: to, DurationMs: dur })
                    } else if (kU = "WAIT") {
                        dur := 0
                        if (st.Has("DurationMs")) {
                            dur := st["DurationMs"]
                        }
                        steps.Push({ Kind: "Wait", DurationMs: dur })
                    } else if (kU = "SWAP") {
                        to := 800
                        rt := 0
                        if (st.Has("TimeoutMs")) {
                            to := st["TimeoutMs"]
                        }
                        if (st.Has("Retry")) {
                            rt := st["Retry"]
                        }
                        steps.Push({ Kind: "Swap", TimeoutMs: to, Retry: rt })
                    }
                }
                i := i + 1
            }
        }
        data.Rotation.Opener.Steps := steps
        data.Rotation.Opener.StepsCount := steps.Length
    }

    ; Tracks（Watch SkillId→Index；RuleRefs RuleId→Index；Track.Id 保留）
    data.Rotation.Tracks := []
    if (rot.Has("Tracks") && IsObject(rot["Tracks"])) {
        i := 1
        while (i <= rot["Tracks"].Length) {
            t := rot["Tracks"][i]
            tr := { Id: 0, ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [], RuleRefs: [] }
            if (IsObject(t)) {
                if (t.Has("Id")) {
                    tr.Id := t["Id"]
                }
                if (t.Has("ThreadId")) {
                    tr.ThreadId := t["ThreadId"]
                }
                if (t.Has("MaxDurationMs")) {
                    tr.MaxDurationMs := t["MaxDurationMs"]
                }
                if (t.Has("MinStayMs")) {
                    tr.MinStayMs := t["MinStayMs"]
                }
                if (t.Has("NextTrackId")) {
                    tr.NextTrackId := t["NextTrackId"]
                }
                if (t.Has("Watch") && IsObject(t["Watch"])) {
                    j := 1
                    while (j <= t["Watch"].Length) {
                        w := t["Watch"][j]
                        idx := 0
                        need := 1
                        vb := 0
                        if (IsObject(w)) {
                            if (w.Has("SkillId")) {
                                idx := PM_SkillIndexById(profile, w["SkillId"])
                            }
                            if (w.Has("RequireCount")) {
                                need := w["RequireCount"]
                            }
                            if (w.Has("VerifyBlack")) {
                                vb := w["VerifyBlack"]
                            }
                        }
                        tr.Watch.Push({ SkillIndex: idx, RequireCount: need, VerifyBlack: vb })
                        j := j + 1
                    }
                }
                if (t.Has("RuleRefs") && IsObject(t["RuleRefs"])) {
                    j := 1
                    while (j <= t["RuleRefs"].Length) {
                        rid := 0
                        if (t["RuleRefs"][j] != "") {
                            rid := t["RuleRefs"][j]
                        }
                        rIdx := PM_RuleIndexById(profile, rid)
                        tr.RuleRefs.Push(rIdx)
                        j := j + 1
                    }
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
            if (IsObject(g0)) {
                if (g0.Has("Priority")) {
                    g.Priority := g0["Priority"]
                }
                if (g0.Has("FromTrackId")) {
                    g.FromTrackId := g0["FromTrackId"]
                }
                if (g0.Has("ToTrackId")) {
                    g.ToTrackId := g0["ToTrackId"]
                }
                if (g0.Has("Logic")) {
                    g.Logic := g0["Logic"]
                }

                if (g0.Has("Conds") && IsObject(g0["Conds"])) {
                    j := 1
                    while (j <= g0["Conds"].Length) {
                        c0 := g0["Conds"][j]
                        if (IsObject(c0)) {
                            kind := ""
                            if (c0.Has("Kind")) {
                                kind := c0["Kind"]
                            }
                            kindU := StrUpper(kind)
                            c := Map()
                            if (kindU = "PIXELREADY") {
                                rtype := "Skill"
                                ridx := 0
                                op := "NEQ"
                                col := "0x000000"
                                tol := 16
                                rid := 0
                                q := 0
                                cmp := "GE"
                                val := 0
                                ems := 0
                                if (c0.Has("RefType")) {
                                    rtype := c0["RefType"]
                                }
                                if (StrUpper(rtype) = "SKILL") {
                                    if (c0.Has("RefId")) {
                                        ridx := PM_SkillIndexById(profile, c0["RefId"])
                                    }
                                } else {
                                    if (c0.Has("RefId")) {
                                        ridx := PM_PointIndexById(profile, c0["RefId"])
                                    }
                                }
                                if (c0.Has("Op")) {
                                    op := c0["Op"]
                                }
                                if (c0.Has("Color")) {
                                    col := c0["Color"]
                                }
                                if (c0.Has("Tol")) {
                                    tol := c0["Tol"]
                                }
                                if (c0.Has("RuleId")) {
                                    rid := c0["RuleId"]
                                }
                                if (c0.Has("QuietMs")) {
                                    q := c0["QuietMs"]
                                }
                                if (c0.Has("Cmp")) {
                                    cmp := c0["Cmp"]
                                }
                                if (c0.Has("Value")) {
                                    val := c0["Value"]
                                }
                                if (c0.Has("ElapsedMs")) {
                                    ems := c0["ElapsedMs"]
                                }
                                g.Conds.Push({ Kind: "PixelReady", RefType: rtype, RefIndex: ridx, Op: op, Color: col, Tol: tol
                                             , RuleId: (rid>0 ? PM_RuleIndexById(profile, rid) : 0), QuietMs: q, Cmp: cmp, Value: val, ElapsedMs: ems })
                            } else if (kindU = "RULEQUIET") {
                                rid := 0
                                q := 0
                                if (c0.Has("RuleId")) {
                                    rid := c0["RuleId"]
                                }
                                if (c0.Has("QuietMs")) {
                                    q := c0["QuietMs"]
                                }
                                g.Conds.Push({ Kind: "RuleQuiet", RuleId: (rid>0 ? PM_RuleIndexById(profile, rid) : 0), QuietMs: q })
                            } else if (kindU = "COUNTER") {
                                sid := 0
                                cmp := "GE"
                                val := 1
                                if (c0.Has("SkillId")) {
                                    sid := c0["SkillId"]
                                }
                                if (c0.Has("Cmp")) {
                                    cmp := c0["Cmp"]
                                }
                                if (c0.Has("Value")) {
                                    val := c0["Value"]
                                }
                                g.Conds.Push({ Kind: "Counter", RefType: "Skill", RefIndex: PM_SkillIndexById(profile, sid), Cmp: cmp, Value: val })
                            } else if (kindU = "ELAPSED") {
                                cmp := "GE"
                                ems := 0
                                if (c0.Has("Cmp")) {
                                    cmp := c0["Cmp"]
                                }
                                if (c0.Has("ElapsedMs")) {
                                    ems := c0["ElapsedMs"]
                                }
                                g.Conds.Push({ Kind: "Elapsed", Cmp: cmp, ElapsedMs: ems })
                            } else {
                                rtype := "Skill"
                                ridx := 0
                                if (c0.Has("RefType")) {
                                    rtype := c0["RefType"]
                                }
                                if (StrUpper(rtype) = "SKILL") {
                                    if (c0.Has("RefId")) {
                                        ridx := PM_SkillIndexById(profile, c0["RefId"])
                                    }
                                } else {
                                    if (c0.Has("RefId")) {
                                        ridx := PM_PointIndexById(profile, c0["RefId"])
                                    }
                                }
                                g.Conds.Push({ Kind: "PixelReady", RefType: rtype, RefIndex: ridx, Op: "NEQ", Color: "0x000000", Tol: 16 })
                            }
                        }
                        j := j + 1
                    }
                }
            }
            data.Rotation.Gates.Push(g)
            i := i + 1
        }
    }

    return data
}