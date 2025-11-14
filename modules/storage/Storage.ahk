; Storage.ahk - INI 配置读写/管理
#Requires AutoHotkey v2

; 轻量诊断日志（用于调试读取/写入，不依赖 Rotation）
Diag_Log(msg) {
    try {
        DirCreate(A_ScriptDir "\Logs")
        ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        FileAppend(ts " [Diag] " msg "`r`n", A_ScriptDir "\Logs\diag.log", "UTF-8")
    }
}

Storage_ListProfiles() {
    global App
    list := []
    loop files, App["ProfilesDir"] "\*" App["ConfigExt"]
        list.Push(RegExReplace(A_LoopFileName, "\.ini$"))
    return list
}

; ---------- Track 读/写辅助（顶层定义，避免函数内嵌定义带来的语法问题） ----------
Storage_ReadNamedTrack(file, name, defId) {
    t := { Id: defId, Name: name, ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [], RuleRefs: [] }
    sec := "Rotation." name
    t.Id := Integer(IniRead(file, sec, "Id", defId))
    t.ThreadId := Integer(IniRead(file, sec, "ThreadId", 1))
    t.MaxDurationMs := Integer(IniRead(file, sec, "MaxDurationMs", 8000))
    t.MinStayMs := Integer(IniRead(file, sec, "MinStayMs", 0))
    t.NextTrackId := Integer(IniRead(file, sec, "NextTrackId", 0))
    wcnt := Integer(IniRead(file, sec, "WatchCount", 0))
    loop wcnt {
        s := "Rotation." name ".Watch" A_Index
        si := Integer(IniRead(file, s, "SkillIndex", 0))
        need := Integer(IniRead(file, s, "RequireCount", 1))
        ver := Integer(IniRead(file, s, "VerifyBlack", 0))
        if (si > 0)
            t.Watch.Push({ SkillIndex: si, RequireCount: need, VerifyBlack: ver })
    }
    rcnt := Integer(IniRead(file, sec, "RuleCount", 0))
    loop rcnt {
        kval := "Rotation." name ".RuleRef" A_Index
        rid := Integer(IniRead(file, kval, "", 0))
        if (rid > 0)
            t.RuleRefs.Push(rid)
    }
    return t
}

Storage_SaveNamedTrack(file, name, t) {
    sec := "Rotation." name
    IniWrite(HasProp(t, "Id") ? t.Id : 0, file, sec, "Id")
    IniWrite(HasProp(t, "ThreadId") ? t.ThreadId : 1, file, sec, "ThreadId")
    IniWrite(HasProp(t, "MaxDurationMs") ? t.MaxDurationMs : 8000, file, sec, "MaxDurationMs")
    IniWrite(HasProp(t, "MinStayMs") ? t.MinStayMs : 0, file, sec, "MinStayMs")
    IniWrite(HasProp(t, "NextTrackId") ? t.NextTrackId : 0, file, sec, "NextTrackId")
    IniWrite(t.Watch.Length, file, sec, "WatchCount")
    for i, w in t.Watch {
        s := "Rotation." name ".Watch" i
        IniWrite(w.SkillIndex, file, s, "SkillIndex")
        IniWrite(HasProp(w, "RequireCount") ? w.RequireCount : 1, file, s, "RequireCount")
        IniWrite(HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0, file, s, "VerifyBlack")
    }
    IniWrite(t.RuleRefs.Length, file, sec, "RuleCount")
    for i, rid in t.RuleRefs
        IniWrite(rid, file, sec, "RuleRef" i)
}

Storage_SaveGates(file, rot) {
    IniWrite(HasProp(rot, "GatesEnabled") ? rot.GatesEnabled : 0, file, "Rotation", "GatesEnabled")
    IniWrite(HasProp(rot, "GateCooldownMs") ? rot.GateCooldownMs : 0, file, "Rotation", "GateCooldownMs")
    garr := HasProp(rot, "Gates") ? rot.Gates : []
    IniWrite(garr.Length, file, "Rotation", "GateCount")
    for gi, g in garr {
        gsec := "Rotation.Gate" gi
        IniWrite(HasProp(g, "Priority") ? g.Priority : gi, file, gsec, "Priority")
        ; 新版：必须写 From/To
        IniWrite(HasProp(g, "FromTrackId") ? g.FromTrackId : 0, file, gsec, "FromTrackId")
        IniWrite(HasProp(g, "ToTrackId")   ? g.ToTrackId   : 0, file, gsec, "ToTrackId")

        if (HasProp(g, "Conds") && g.Conds.Length > 0) {
            IniWrite(HasProp(g, "Logic") ? g.Logic : "AND", file, gsec, "Logic")
            IniWrite(g.Conds.Length, file, gsec, "CondCount")
            for ci, c in g.Conds {
                csec := "Rotation.Gate" gi ".Cond" ci
                IniWrite(HasProp(c,"Kind") ? c.Kind : "PixelReady", file, csec, "Kind")
                IniWrite(HasProp(c,"RefType") ? c.RefType : "Skill", file, csec, "RefType")
                IniWrite(HasProp(c,"RefIndex") ? c.RefIndex : 0, file, csec, "RefIndex")
                IniWrite(HasProp(c,"Op") ? c.Op : "NEQ", file, csec, "Op")
                IniWrite(HasProp(c,"Color") ? c.Color : "0x000000", file, csec, "Color")
                IniWrite(HasProp(c,"Tol") ? c.Tol : 16, file, csec, "Tol")
                IniWrite(HasProp(c,"RuleId") ? c.RuleId : 0, file, csec, "RuleId")
                IniWrite(HasProp(c,"QuietMs") ? c.QuietMs : 0, file, csec, "QuietMs")
                IniWrite(HasProp(c,"Cmp") ? c.Cmp : "GE", file, csec, "Cmp")
                IniWrite(HasProp(c,"Value") ? c.Value : 0, file, csec, "Value")
                IniWrite(HasProp(c,"ElapsedMs") ? c.ElapsedMs : 0, file, csec, "ElapsedMs")
            }
        } else {
            ; 仍保留 M2 单条件的保存方式（与 From/To 无关）
            IniWrite("AND", file, gsec, "Logic")
            IniWrite(1, file, gsec, "CondCount")
            csec := "Rotation.Gate" gi ".Cond1"
            IniWrite(HasProp(g,"Kind") ? g.Kind : "PixelReady", file, csec, "Kind")
            IniWrite(HasProp(g,"RefType") ? g.RefType : "Skill", file, csec, "RefType")
            IniWrite(HasProp(g,"RefIndex") ? g.RefIndex : 0, file, csec, "RefIndex")
            IniWrite(HasProp(g,"Op") ? g.Op : "NEQ", file, csec, "Op")
            IniWrite(HasProp(g,"Color") ? g.Color : "0x000000", file, csec, "Color")
            IniWrite(HasProp(g,"Tol") ? g.Tol : 16, file, csec, "Tol")
            IniWrite(HasProp(g,"RuleId") ? g.RuleId : 0, file, csec, "RuleId")
            IniWrite(HasProp(g,"QuietMs") ? g.QuietMs : 0, file, csec, "QuietMs")
            IniWrite(HasProp(g,"Cmp") ? g.Cmp : "GE", file, csec, "Cmp")
            IniWrite(HasProp(g,"Value") ? g.Value : 0, file, csec, "Value")
            IniWrite(HasProp(g,"ElapsedMs") ? g.ElapsedMs : 0, file, csec, "ElapsedMs")
        }
    }
}

Storage_LoadProfile(name) {
    global App
    file := App["ProfilesDir"] "\" name App["ConfigExt"]
    data := Core_DefaultProfileData()
    data.Name := name

    if !FileExist(file)
        return data

    ; ===== General =====
    data.StartHotkey := IniRead(file, "General", "StartHotkey", data.StartHotkey)
    data.PollIntervalMs := Integer(IniRead(file, "General", "PollIntervalMs", data.PollIntervalMs))
    data.SendCooldownMs := Integer(IniRead(file, "General", "SendCooldownMs", data.SendCooldownMs))
    data.PickHoverEnabled := Integer(IniRead(file, "General", "PickHoverEnabled", data.PickHoverEnabled))
    data.PickHoverOffsetY := Integer(IniRead(file, "General", "PickHoverOffsetY", data.PickHoverOffsetY))
    data.PickHoverDwellMs := Integer(IniRead(file, "General", "PickHoverDwellMs", data.PickHoverDwellMs))
    data.PickConfirmKey := IniRead(file, "General", "PickConfirmKey", "LButton")

    ; ===== Skills =====
    sc := Integer(IniRead(file, "General", "SkillCount", 0))
    data.Skills := []
    loop sc {
        idx := A_Index, sec := "Skill" idx
        sName := IniRead(file, sec, "Name", "")
        sKey := IniRead(file, sec, "Key", "")
        sX := Integer(IniRead(file, sec, "X", 0))
        sY := Integer(IniRead(file, sec, "Y", 0))
        sClr := IniRead(file, sec, "Color", "0x000000")
        sTol := Integer(IniRead(file, sec, "Tol", 10))
        sCast := Integer(IniRead(file, sec, "CastMs", 0))
        data.Skills.Push({ Name: sName, Key: sKey, X: sX, Y: sY, Color: sClr, Tol: sTol, CastMs: sCast })
    }

    ; ===== Points =====
    pc := Integer(IniRead(file, "General", "PointCount", 0))
    data.Points := []
    loop pc {
        idx := A_Index, sec := "Point" idx
        pName := IniRead(file, sec, "Name", "")
        pX := Integer(IniRead(file, sec, "X", 0))
        pY := Integer(IniRead(file, sec, "Y", 0))
        pClr := IniRead(file, sec, "Color", "0x000000")
        pTol := Integer(IniRead(file, sec, "Tol", 10))
        data.Points.Push({ Name: pName, X: pX, Y: pY, Color: pClr, Tol: pTol })
    }

    ; ===== Buffs =====
    bc := Integer(IniRead(file, "General", "BuffCount", 0))
    data.Buffs := []
    loop bc {
        bi := A_Index
        sec := "Buff" bi
        bName := IniRead(file, sec, "Name", "Buff" bi)
        bEn := Integer(IniRead(file, sec, "Enabled", 1))
        bDur := Integer(IniRead(file, sec, "DurationMs", 0))
        bRef := Integer(IniRead(file, sec, "RefreshBeforeMs", 0))
        bChk := Integer(IniRead(file, sec, "CheckReady", 1))
        sc2 := Integer(IniRead(file, sec, "SkillCount", 0))
        bThr := Integer(IniRead(file, sec, "ThreadId", 1))
        skills := []
        loop sc2 {
            sSec := "Buff" bi "_Skill" A_Index
            skills.Push(Integer(IniRead(file, sSec, "SkillIndex", 1)))
        }
        data.Buffs.Push({ Name: bName, Enabled: bEn, DurationMs: bDur, RefreshBeforeMs: bRef, CheckReady: bChk
                        , ThreadId: bThr, Skills: skills, LastTime: 0, NextIdx: 1 })
    }

    ; ===== Rules =====
    rc := Integer(IniRead(file, "General", "RuleCount", 0))
    data.Rules := []
    loop rc {
        rIdx := A_Index
        rSec := "Rule" rIdx
        rName := IniRead(file, rSec, "Name", "Rule" rIdx)
        rEnabled := Integer(IniRead(file, rSec, "Enabled", 1))
        rLogic := IniRead(file, rSec, "Logic", "AND")
        rCd := Integer(IniRead(file, rSec, "CooldownMs", 500))
        rPrio := Integer(IniRead(file, rSec, "Priority", rIdx))
        rGap := Integer(IniRead(file, rSec, "ActionGapMs", 60))
        cCount := Integer(IniRead(file, rSec, "CondCount", 0))
        aCount := Integer(IniRead(file, rSec, "ActCount", 0))
        rThread := Integer(IniRead(file, rSec, "ThreadId", 1))
        conds := []
        loop cCount {
            cSec := "Rule" rIdx "_Cond" A_Index
            kind := IniRead(file, cSec, "Kind", "Pixel")
            if (StrUpper(kind) = "COUNTER") {
                si := Integer(IniRead(file, cSec, "SkillIndex", 1))
                cmp := IniRead(file, cSec, "Cmp", "GE")
                val := Integer(IniRead(file, cSec, "Value", 1))
                rst := Integer(IniRead(file, cSec, "ResetOnTrigger", 0))
                conds.Push({ Kind: "Counter", SkillIndex: si, Cmp: cmp, Value: val, ResetOnTrigger: rst })
            } else {
                refType := IniRead(file, cSec, "RefType", "Skill")
                refIdx  := Integer(IniRead(file, cSec, "RefIndex", 1))
                op      := IniRead(file, cSec, "Op", "EQ")
                useRef  := Integer(IniRead(file, cSec, "UseRefXY", 1))
                cx      := Integer(IniRead(file, cSec, "X", 0))
                cy      := Integer(IniRead(file, cSec, "Y", 0))
                conds.Push({ RefType: refType, RefIndex: refIdx, Op: op, UseRefXY: useRef, X: cx, Y: cy })
            }
        }
        acts := []
        loop aCount {
            aSec := "Rule" rIdx "_Act" A_Index
            sIdx := Integer(IniRead(file, aSec, "SkillIndex", 1))
            dMs  := Integer(IniRead(file, aSec, "DelayMs", 0))
            acts.Push({ SkillIndex: sIdx, DelayMs: dMs })
        }
        data.Rules.Push({ Name: rName, Enabled: rEnabled, Logic: rLogic, CooldownMs: rCd, Priority: rPrio
                        , ActionGapMs: rGap, ThreadId: rThread, Conditions: conds, Actions: acts, LastFire: 0 })
    }

    ; ===== Threads =====
    tc := Integer(IniRead(file, "General", "ThreadCount", 0))
    data.Threads := []
    if (tc <= 0) {
        data.Threads := [{ Id: 1, Name: "默认线程" }]
    } else {
        loop tc {
            i := A_Index
            sec := "Thread" i
            tName := IniRead(file, sec, "Name", "线程" i)
            data.Threads.Push({ Id: i, Name: tName })
        }
    }

    ; ===== Default（兜底技能） =====
    dsEn  := Integer(IniRead(file, "Default", "Enabled", 0))
    dsIdx := Integer(IniRead(file, "Default", "SkillIndex", 0))
    dsRdy := Integer(IniRead(file, "Default", "CheckReady", 1))
    dsTid := Integer(IniRead(file, "Default", "ThreadId", 1))
    dsCd  := Integer(IniRead(file, "Default", "CooldownMs", 600))
    dsPre := Integer(IniRead(file, "Default", "PreDelayMs", 0))
    data.DefaultSkill := { Enabled: dsEn, SkillIndex: dsIdx, CheckReady: dsRdy
                         , ThreadId: dsTid, CooldownMs: dsCd, PreDelayMs: dsPre, LastFire: 0 }

    ; ===== Rotation 读取（M1/M2/M3） =====
    rot := HasProp(data, "Rotation") ? data.Rotation : {}

    ; 基础项
    rot.Enabled        := Integer(IniRead(file, "Rotation", "Enabled", 0))
    rot.DefaultTrackId := Integer(IniRead(file, "Rotation", "DefaultTrackId", 1))
    rot.SwapKey        := IniRead(file, "Rotation", "SwapKey", "")
    rot.BusyWindowMs   := Integer(IniRead(file, "Rotation", "BusyWindowMs", 200))
    rot.ColorTolBlack  := Integer(IniRead(file, "Rotation", "ColorTolBlack", 16))
    rot.GatesEnabled   := Integer(IniRead(file, "Rotation", "GatesEnabled", 0))
    rot.GateCooldownMs := Integer(IniRead(file, "Rotation", "GateCooldownMs", 0))

    ; BlackGuard
    rot.BlackGuard := {
        Enabled: Integer(IniRead(file, "Rotation.BlackGuard", "Enabled", 1))
      , SampleCount: Integer(IniRead(file, "Rotation.BlackGuard", "SampleCount", 5))
      , BlackRatioThresh: (IniRead(file, "Rotation.BlackGuard", "BlackRatioThresh", 0.7)+0)
      , WindowMs: Integer(IniRead(file, "Rotation.BlackGuard", "WindowMs", 120))
      , CooldownMs: Integer(IniRead(file, "Rotation.BlackGuard", "CooldownMs", 600))
      , MinAfterSendMs: Integer(IniRead(file, "Rotation.BlackGuard", "MinAfterSendMs", 60))
      , MaxAfterSendMs: Integer(IniRead(file, "Rotation.BlackGuard", "MaxAfterSendMs", 800))
      , UniqueRequired: Integer(IniRead(file, "Rotation.BlackGuard", "UniqueRequired", 1))
    }

    ; Opener（Watch + Steps）
    rot.Opener := { Enabled: Integer(IniRead(file, "Rotation.Opener", "Enabled", 0))
                  , MaxDurationMs: Integer(IniRead(file, "Rotation.Opener", "MaxDurationMs", 4000))
                  , Watch: [], StepsCount: Integer(IniRead(file, "Rotation.Opener", "StepsCount", 0)), Steps: [] }
    wcnt0 := Integer(IniRead(file, "Rotation.Opener", "WatchCount", 0))
    loop wcnt0 {
        sect := "Rotation.Opener.Watch" A_Index
        si := Integer(IniRead(file, sect, "SkillIndex", 0))
        need := Integer(IniRead(file, sect, "RequireCount", 1))
        ver := Integer(IniRead(file, sect, "VerifyBlack", 0))
        if (si > 0)
            rot.Opener.Watch.Push({ SkillIndex: si, RequireCount: need, VerifyBlack: ver })
    }
    if (rot.Opener.StepsCount > 0) {
        rot.Opener.Steps := []
        loop rot.Opener.StepsCount {
            si2 := A_Index
            ssec := "Rotation.Opener.Step" si2
            skind := IniRead(file, ssec, "Kind", "")
            if (skind = "")
                continue
            stp := {
                Kind: skind
              , SkillIndex: Integer(IniRead(file, ssec, "SkillIndex", 0))
              , RequireReady: Integer(IniRead(file, ssec, "RequireReady", 0))
              , PreDelayMs: Integer(IniRead(file, ssec, "PreDelayMs", 0))
              , HoldMs: Integer(IniRead(file, ssec, "HoldMs", 0))
              , Verify: Integer(IniRead(file, ssec, "Verify", 0))
              , TimeoutMs: Integer(IniRead(file, ssec, "TimeoutMs", 1200))
              , DurationMs: Integer(IniRead(file, ssec, "DurationMs", 0))
            }
            rot.Opener.Steps.Push(stp)
        }
    }

    ; Tracks（M3：TrackCount；兼容 Track1/Track2）
    rot.Tracks := []
    tcount := Integer(IniRead(file, "Rotation", "TrackCount", 0))
    if (tcount > 0) {
        loop tcount {
            i := A_Index
            t := Storage_ReadNamedTrack(file, "Track" i, i)
            rot.Tracks.Push(t)
        }
        ; 同步映射 Track1/Track2（兼容旧代码）
        if (rot.Tracks.Length >= 1) {
            rot.Track1 := rot.Tracks[1]
        }
        if (rot.Tracks.Length >= 2) {
            rot.Track2 := rot.Tracks[2]
        }
    } else {
        ; 旧格式：仅 Track1/Track2
        rot.Track1 := Storage_ReadNamedTrack(file, "Track1", 1)
        rot.Track2 := Storage_ReadNamedTrack(file, "Track2", 2)
        if (rot.Track1) {
            rot.Tracks.Push(rot.Track1)
        }
        if (rot.Track2) {
            rot.Tracks.Push(rot.Track2)
        }
    }

    ; ===== Gates（新版：必须 FromTrackId/ToTrackId；仍兼容单/多条件字段） =====
    rot.Gates := []
    gcnt := Integer(IniRead(file, "Rotation", "GateCount", 0))
    loop gcnt {
        gi := A_Index
        gsec := "Rotation.Gate" gi
        condCount := Integer(IniRead(file, gsec, "CondCount", 0))
        g := { Priority: Integer(IniRead(file, gsec, "Priority", gi))
            , FromTrackId: Integer(IniRead(file, gsec, "FromTrackId", 0))
            , ToTrackId:   Integer(IniRead(file, gsec, "ToTrackId", 0))
            , Logic: IniRead(file, gsec, "Logic", "AND")
            , Conds: [] }
        if (condCount <= 0) {
            ; 兼容旧式单条件字段的读取（仅条件层面），From/To 必须在新字段
            kind := IniRead(file, gsec, "Kind", "")
            if (kind != "") {
                c := {
                    Kind: kind
                , RefType:  IniRead(file, gsec, "RefType", "Skill")
                , RefIndex: Integer(IniRead(file, gsec, "RefIndex", 0))
                , Op:       IniRead(file, gsec, "Op", "NEQ")
                , Color:    IniRead(file, gsec, "Color", "0x000000")
                , Tol:      Integer(IniRead(file, gsec, "Tol", 16))
                , RuleId:   Integer(IniRead(file, gsec, "RuleId", 0))
                , QuietMs:  Integer(IniRead(file, gsec, "QuietMs", 0))
                , Cmp:      IniRead(file, gsec, "Cmp", "GE")
                , Value:    Integer(IniRead(file, gsec, "Value", 0))
                , ElapsedMs:Integer(IniRead(file, gsec, "ElapsedMs", 0))
                }
                g.Conds.Push(c)
            }
        } else {
            loop condCount {
                ci := A_Index
                csec := "Rotation.Gate" gi ".Cond" ci
                kind := IniRead(file, csec, "Kind", "")
                if (kind = "")
                    continue
                c := {
                    Kind: kind
                , RefType:  IniRead(file, csec, "RefType", "Skill")
                , RefIndex: Integer(IniRead(file, csec, "RefIndex", 0))
                , Op:       IniRead(file, csec, "Op", "NEQ")
                , Color:    IniRead(file, csec, "Color", "0x000000")
                , Tol:      Integer(IniRead(file, csec, "Tol", 16))
                , RuleId:   Integer(IniRead(file, csec, "RuleId", 0))
                , QuietMs:  Integer(IniRead(file, csec, "QuietMs", 0))
                , Cmp:      IniRead(file, csec, "Cmp", "GE")
                , Value:    Integer(IniRead(file, csec, "Value", 0))
                , ElapsedMs:Integer(IniRead(file, csec, "ElapsedMs", 0))
                }
                g.Conds.Push(c)
            }
        }
        rot.Gates.Push(g)
    }

    ; Swap 验证（M2）
    rot.VerifySwap    := Integer(IniRead(file, "Rotation", "VerifySwap", 0))
    rot.SwapTimeoutMs := Integer(IniRead(file, "Rotation", "SwapTimeoutMs", 800))
    rot.SwapRetry     := Integer(IniRead(file, "Rotation", "SwapRetry", 0))
    sv := {}
    sv.RefType  := IniRead(file, "Rotation.SwapVerify", "RefType", "Skill")
    sv.RefIndex := Integer(IniRead(file, "Rotation.SwapVerify", "RefIndex", 0))
    sv.Op       := IniRead(file, "Rotation.SwapVerify", "Op", "NEQ")
    sv.Color    := IniRead(file, "Rotation.SwapVerify", "Color", "0x000000")
    sv.Tol      := Integer(IniRead(file, "Rotation.SwapVerify", "Tol", 16))
    rot.SwapVerify := sv

    ; 调试友好：若没显式启用，但已有 Watch → 自动启用
    if (rot.Enabled = 0) {
        hasWatchAll := 0
        try hasWatchAll += (rot.Opener.Watch.Length)
        try hasWatchAll += (rot.Track1.Watch.Length)
        try hasWatchAll += (rot.Track2.Watch.Length)
        if (hasWatchAll > 0)
            rot.Enabled := 1
    }

    data.Rotation := rot
    return data
}

Storage_SaveProfile(data) {
    global App
    file := App["ProfilesDir"] "\" data.Name App["ConfigExt"]

    ; ===== General =====
    IniWrite(data.StartHotkey, file, "General", "StartHotkey")
    IniWrite(data.PollIntervalMs, file, "General", "PollIntervalMs")
    IniWrite(data.SendCooldownMs, file, "General", "SendCooldownMs")
    IniWrite(data.Skills.Length, file, "General", "SkillCount")
    IniWrite(data.PickHoverEnabled, file, "General", "PickHoverEnabled")
    IniWrite(data.PickHoverOffsetY, file, "General", "PickHoverOffsetY")
    IniWrite(data.PickHoverDwellMs, file, "General", "PickHoverDwellMs")
    IniWrite(HasProp(data, "PickConfirmKey") ? data.PickConfirmKey : "LButton", file, "General", "PickConfirmKey")
    IniWrite(data.Points.Length, file, "General", "PointCount")
    IniWrite(data.Rules.Length, file, "General", "RuleCount")
    IniWrite(data.Buffs.Length, file, "General", "BuffCount")
    IniWrite(data.Threads.Length, file, "General", "ThreadCount")

    for i, t in data.Threads {
        sec := "Thread" i
        IniWrite(t.Name, file, sec, "Name")
    }

    ; ===== Default =====
    ds := HasProp(data, "DefaultSkill") ? data.DefaultSkill : 0
    if ds {
        IniWrite(HasProp(ds, "Enabled") ? ds.Enabled : 0, file, "Default", "Enabled")
        IniWrite(HasProp(ds, "SkillIndex") ? ds.SkillIndex : 0, file, "Default", "SkillIndex")
        IniWrite(HasProp(ds, "CheckReady") ? ds.CheckReady : 1, file, "Default", "CheckReady")
        IniWrite(HasProp(ds, "ThreadId") ? ds.ThreadId : 1, file, "Default", "ThreadId")
        IniWrite(HasProp(ds, "CooldownMs") ? ds.CooldownMs : 600, file, "Default", "CooldownMs")
        IniWrite(HasProp(ds, "PreDelayMs") ? ds.PreDelayMs : 0, file, "Default", "PreDelayMs")
    }

    ; ===== Skills =====
    for idx, s in data.Skills {
        sec := "Skill" idx
        IniWrite(s.Name, file, sec, "Name")
        IniWrite(s.Key, file, sec, "Key")
        IniWrite(s.X, file, sec, "X")
        IniWrite(s.Y, file, sec, "Y")
        IniWrite(s.Color, file, sec, "Color")
        IniWrite(s.Tol, file, sec, "Tol")
        IniWrite(HasProp(s, "CastMs") ? s.CastMs : 0, file, sec, "CastMs")
    }

    ; ===== Points =====
    for idx, p in data.Points {
        sec := "Point" idx
        IniWrite(p.Name, file, sec, "Name")
        IniWrite(p.X, file, sec, "X")
        IniWrite(p.Y, file, sec, "Y")
        IniWrite(p.Color, file, sec, "Color")
        IniWrite(p.Tol, file, sec, "Tol")
    }

    ; ===== Rules =====
    for rIdx, r in data.Rules {
        rSec := "Rule" rIdx
        IniWrite(r.Name, file, rSec, "Name")
        IniWrite(r.Enabled, file, rSec, "Enabled")
        IniWrite(r.Logic, file, rSec, "Logic")
        IniWrite(r.CooldownMs, file, rSec, "CooldownMs")
        IniWrite(r.Priority, file, rSec, "Priority")
        IniWrite(r.ActionGapMs, file, rSec, "ActionGapMs")
        IniWrite(r.Conditions.Length, file, rSec, "CondCount")
        IniWrite(r.Actions.Length, file, rSec, "ActCount")
        IniWrite(HasProp(r, "ThreadId") ? r.ThreadId : 1, file, rSec, "ThreadId")
        for cIdx, c in r.Conditions {
            cSec := "Rule" rIdx "_Cond" cIdx
            kind := HasProp(c, "Kind") ? c.Kind : "Pixel"
            IniWrite(kind, file, cSec, "Kind")
            if (StrUpper(kind) = "COUNTER") {
                IniWrite(HasProp(c, "SkillIndex") ? c.SkillIndex : 1, file, cSec, "SkillIndex")
                IniWrite(HasProp(c, "Cmp") ? c.Cmp : "GE", file, cSec, "Cmp")
                IniWrite(HasProp(c, "Value") ? c.Value : 1, file, cSec, "Value")
                IniWrite(HasProp(c, "ResetOnTrigger") ? c.ResetOnTrigger : 0, file, cSec, "ResetOnTrigger")
            } else {
                IniWrite(c.RefType, file, cSec, "RefType")
                IniWrite(c.RefIndex, file, cSec, "RefIndex")
                IniWrite(c.Op, file, cSec, "Op")
                IniWrite(c.UseRefXY, file, cSec, "UseRefXY")
                IniWrite(c.X, file, cSec, "X")
                IniWrite(c.Y, file, cSec, "Y")
            }
        }
        for aIdx, a in r.Actions {
            aSec := "Rule" rIdx "_Act" aIdx
            IniWrite(a.SkillIndex, file, aSec, "SkillIndex")
            IniWrite(a.DelayMs, file, aSec, "DelayMs")
        }
    }

    ; ===== Buffs =====
    for bi, b in data.Buffs {
        sec := "Buff" bi
        IniWrite(b.Name, file, sec, "Name")
        IniWrite(b.Enabled, file, sec, "Enabled")
        IniWrite(b.DurationMs, file, sec, "DurationMs")
        IniWrite(b.RefreshBeforeMs, file, sec, "RefreshBeforeMs")
        IniWrite(b.CheckReady, file, sec, "CheckReady")
        IniWrite(b.Skills.Length, file, sec, "SkillCount")
        IniWrite(HasProp(b, "ThreadId") ? b.ThreadId : 1, file, sec, "ThreadId")
        for si, idx in b.Skills {
            sSec := "Buff" bi "_Skill" si
            IniWrite(idx, file, sSec, "SkillIndex")
        }
    }

    ; ===== Rotation 保存（含 M2/M3） =====
    if HasProp(data, "Rotation") {
        rot := data.Rotation
        IniWrite(HasProp(rot,"Enabled") ? rot.Enabled : 0, file, "Rotation", "Enabled")
        IniWrite(HasProp(rot,"DefaultTrackId") ? rot.DefaultTrackId : 1, file, "Rotation", "DefaultTrackId")
        IniWrite(HasProp(rot,"SwapKey") ? rot.SwapKey : "", file, "Rotation", "SwapKey")
        IniWrite(HasProp(rot,"BusyWindowMs") ? rot.BusyWindowMs : 200, file, "Rotation", "BusyWindowMs")
        IniWrite(HasProp(rot,"ColorTolBlack") ? rot.ColorTolBlack : 16, file, "Rotation", "ColorTolBlack")

        ; BlackGuard
        if HasProp(rot, "BlackGuard") {
            bg := rot.BlackGuard
            IniWrite(HasProp(bg,"Enabled")?bg.Enabled:1, file, "Rotation.BlackGuard", "Enabled")
            IniWrite(HasProp(bg,"SampleCount")?bg.SampleCount:5, file, "Rotation.BlackGuard", "SampleCount")
            IniWrite(HasProp(bg,"BlackRatioThresh")?bg.BlackRatioThresh:0.7, file, "Rotation.BlackGuard", "BlackRatioThresh")
            IniWrite(HasProp(bg,"WindowMs")?bg.WindowMs:120, file, "Rotation.BlackGuard", "WindowMs")
            IniWrite(HasProp(bg,"CooldownMs")?bg.CooldownMs:600, file, "Rotation.BlackGuard", "CooldownMs")
            IniWrite(HasProp(bg,"MinAfterSendMs")?bg.MinAfterSendMs:60, file, "Rotation.BlackGuard", "MinAfterSendMs")
            IniWrite(HasProp(bg,"MaxAfterSendMs")?bg.MaxAfterSendMs:800, file, "Rotation.BlackGuard", "MaxAfterSendMs")
            IniWrite(HasProp(bg,"UniqueRequired")?bg.UniqueRequired:1, file, "Rotation.BlackGuard", "UniqueRequired")
        }

        ; Opener 保存（Watch/Steps）
        op := rot.Opener
        IniWrite(HasProp(op,"Enabled")?op.Enabled:0, file, "Rotation.Opener", "Enabled")
        IniWrite(HasProp(op,"MaxDurationMs")?op.MaxDurationMs:4000, file, "Rotation.Opener", "MaxDurationMs")
        IniWrite(op.Watch.Length, file, "Rotation.Opener", "WatchCount")
        for i, w in op.Watch {
            s := "Rotation.Opener.Watch" i
            IniWrite(w.SkillIndex, file, s, "SkillIndex")
            IniWrite(HasProp(w,"RequireCount")?w.RequireCount:1, file, s, "RequireCount")
            IniWrite(HasProp(w,"VerifyBlack")?w.VerifyBlack:0, file, s, "VerifyBlack")
        }
        IniWrite(HasProp(op,"StepsCount")?op.StepsCount:0, file, "Rotation.Opener", "StepsCount")
        if (HasProp(op,"Steps") && op.Steps.Length>0) {
            loop op.Steps.Length {
                si2 := A_Index
                ssec := "Rotation.Opener.Step" si2
                stp := op.Steps[si2]
                IniWrite(HasProp(stp,"Kind")?stp.Kind:"", file, ssec, "Kind")
                IniWrite(HasProp(stp,"SkillIndex")?stp.SkillIndex:0, file, ssec, "SkillIndex")
                IniWrite(HasProp(stp,"RequireReady")?stp.RequireReady:0, file, ssec, "RequireReady")
                IniWrite(HasProp(stp,"PreDelayMs")?stp.PreDelayMs:0, file, ssec, "PreDelayMs")
                IniWrite(HasProp(stp,"HoldMs")?stp.HoldMs:0, file, ssec, "HoldMs")
                IniWrite(HasProp(stp,"Verify")?stp.Verify:0, file, ssec, "Verify")
                IniWrite(HasProp(stp,"TimeoutMs")?stp.TimeoutMs:1200, file, ssec, "TimeoutMs")
                IniWrite(HasProp(stp,"DurationMs")?stp.DurationMs:0, file, ssec, "DurationMs")
            }
        }

        ; Gates 保存（支持多条件）
        Storage_SaveGates(file, rot)

        ; Swap 验证
        IniWrite(HasProp(rot,"VerifySwap")?rot.VerifySwap:0, file, "Rotation", "VerifySwap")
        IniWrite(HasProp(rot,"SwapTimeoutMs")?rot.SwapTimeoutMs:800, file, "Rotation", "SwapTimeoutMs")
        IniWrite(HasProp(rot,"SwapRetry")?rot.SwapRetry:0, file, "Rotation", "SwapRetry")
        if HasProp(rot, "SwapVerify") {
            sv := rot.SwapVerify
            IniWrite(HasProp(sv,"RefType")?sv.RefType:"Skill", file, "Rotation.SwapVerify", "RefType")
            IniWrite(HasProp(sv,"RefIndex")?sv.RefIndex:0, file, "Rotation.SwapVerify", "RefIndex")
            IniWrite(HasProp(sv,"Op")?sv.Op:"NEQ", file, "Rotation.SwapVerify", "Op")
            IniWrite(HasProp(sv,"Color")?sv.Color:"0x000000", file, "Rotation.SwapVerify", "Color")
            IniWrite(HasProp(sv,"Tol")?sv.Tol:16, file, "Rotation.SwapVerify", "Tol")
        }

        ; Tracks 保存：优先 Tracks 数组；若无则保存 Track1/Track2
        if (HasProp(rot,"Tracks") && rot.Tracks.Length>0) {
            IniWrite(rot.Tracks.Length, file, "Rotation", "TrackCount")
            ; 先清理旧 Track1/Track2（可选）
            loop 2 {
                name := "Track" A_Index
                ; 不强制删除小节；保持简单
            }
            loop rot.Tracks.Length {
                i := A_Index
                Storage_SaveNamedTrack(file, "Track" i, rot.Tracks[i])
            }
            ; 同步写 Track1/Track2（兼容旧模块）
            if (rot.Tracks.Length >=1) {
                Storage_SaveNamedTrack(file, "Track1", rot.Tracks[1])
            }
            if (rot.Tracks.Length >=2) {
                Storage_SaveNamedTrack(file, "Track2", rot.Tracks[2])
            }
        } else {
            Storage_SaveNamedTrack(file, "Track1", rot.Track1)
            Storage_SaveNamedTrack(file, "Track2", rot.Track2)
            IniWrite(0, file, "Rotation", "TrackCount")
        }
    }
}

Storage_DeleteProfile(name) {
    global App
    file := App["ProfilesDir"] "\" name App["ConfigExt"]
    if FileExist(file)
        FileDelete file
}