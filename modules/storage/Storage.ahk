; Storage.ahk - INI 配置读写/管理

; 轻量诊断日志（避免依赖 Rotation）
Diag_Log(msg) {
    DirCreate(A_ScriptDir "\Logs")
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " [Diag] " msg "`r`n", A_ScriptDir "\Logs\diag.log", "UTF-8")
}

Storage_ListProfiles() {
    global App
    list := []
    loop files, App["ProfilesDir"] "\*" App["ConfigExt"]
        list.Push(RegExReplace(A_LoopFileName, "\.ini$"))
    return list
}

Storage_LoadProfile(name) {
    global App
    file := App["ProfilesDir"] "\" name App["ConfigExt"]
    data := Core_DefaultProfileData()
    data.Name := name

    if !FileExist(file)
        return data

    ; General
    data.StartHotkey := IniRead(file, "General", "StartHotkey", data.StartHotkey)
    data.PollIntervalMs := Integer(IniRead(file, "General", "PollIntervalMs", data.PollIntervalMs))
    data.SendCooldownMs := Integer(IniRead(file, "General", "SendCooldownMs", data.SendCooldownMs))
    data.PickHoverEnabled := Integer(IniRead(file, "General", "PickHoverEnabled", data.PickHoverEnabled))
    data.PickHoverOffsetY := Integer(IniRead(file, "General", "PickHoverOffsetY", data.PickHoverOffsetY))
    data.PickHoverDwellMs := Integer(IniRead(file, "General", "PickHoverDwellMs", data.PickHoverDwellMs))
    data.PickConfirmKey := IniRead(file, "General", "PickConfirmKey", "LButton")   ; 新增
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
        sCast := Integer(IniRead(file, sec, "CastMs", 0))               ; 新增
        data.Skills.Push({ Name: sName, Key: sKey, X: sX, Y: sY, Color: sClr, Tol: sTol, CastMs: sCast })
    }
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
        sc := Integer(IniRead(file, sec, "SkillCount", 0))
        bThr := Integer(IniRead(file, sec, "ThreadId", 1))
        skills := []
        loop sc {
            sSec := "Buff" bi "_Skill" A_Index
            skills.Push(Integer(IniRead(file, sSec, "SkillIndex", 1)))
        }
        data.Buffs.Push({ Name: bName, Enabled: bEn, DurationMs: bDur, RefreshBeforeMs: bRef, CheckReady: bChk,
            ThreadId: bThr, Skills: skills,
            LastTime: 0, NextIdx: 1 })
    }

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
                cmp := IniRead(file, cSec, "Cmp", "GE")   ; GE/GT/EQ/LE/LT
                val := Integer(IniRead(file, cSec, "Value", 1))
                rst := Integer(IniRead(file, cSec, "ResetOnTrigger", 0))
                conds.Push({ Kind: "Counter", SkillIndex: si, Cmp: cmp, Value: val, ResetOnTrigger: rst })
            } else {
                ; 原有像素条件读取
                refType := IniRead(file, cSec, "RefType", "Skill")  ; Skill/Point
                refIdx := Integer(IniRead(file, cSec, "RefIndex", 1))
                op := IniRead(file, cSec, "Op", "EQ")          ; EQ/NEQ
                useRef := Integer(IniRead(file, cSec, "UseRefXY", 1))
                cx := Integer(IniRead(file, cSec, "X", 0))
                cy := Integer(IniRead(file, cSec, "Y", 0))
                conds.Push({ RefType: refType, RefIndex: refIdx, Op: op, UseRefXY: useRef, X: cx, Y: cy })
            }
        }

        acts := []
        loop aCount {
            aSec := "Rule" rIdx "_Act" A_Index
            sIdx := Integer(IniRead(file, aSec, "SkillIndex", 1))
            dMs := Integer(IniRead(file, aSec, "DelayMs", 0))
            acts.Push({ SkillIndex: sIdx, DelayMs: dMs })
        }
        data.Rules.Push({ Name: rName, Enabled: rEnabled, Logic: rLogic, CooldownMs: rCd, Priority: rPrio, ActionGapMs: rGap,
            ThreadId: rThread, Conditions: conds, Actions: acts, LastFire: 0 })
    }

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
    dsEn := Integer(IniRead(file, "Default", "Enabled", 0))
    dsIdx := Integer(IniRead(file, "Default", "SkillIndex", 0))
    dsRdy := Integer(IniRead(file, "Default", "CheckReady", 1))
    dsTid := Integer(IniRead(file, "Default", "ThreadId", 1))
    dsCd := Integer(IniRead(file, "Default", "CooldownMs", 600))
    dsPre := Integer(IniRead(file, "Default", "PreDelayMs", 0))
    data.DefaultSkill := {
        Enabled: dsEn, SkillIndex: dsIdx, CheckReady: dsRdy, ThreadId: dsTid, CooldownMs: dsCd, PreDelayMs: dsPre,
        LastFire: 0
    }
    ; ===== Rotation（M1）读取 =====
    rot := HasProp(data, "Rotation") ? data.Rotation : {}

    ; 基础项（Enabled 必须读入）
    rot.Enabled := Integer(IniRead(file, "Rotation", "Enabled", 0))
    rot.DefaultTrackId := Integer(IniRead(file, "Rotation", "DefaultTrackId", 1))
    rot.SwapKey := IniRead(file, "Rotation", "SwapKey", "")
    rot.BusyWindowMs := Integer(IniRead(file, "Rotation", "BusyWindowMs", 200))
    rot.ColorTolBlack := Integer(IniRead(file, "Rotation", "ColorTolBlack", 16))

    ; BlackGuard（可选，M1 可以先用默认）
    rot.BlackGuard := {
        Enabled: Integer(IniRead(file, "Rotation.BlackGuard", "Enabled", 1)), SampleCount: Integer(IniRead(file,
            "Rotation.BlackGuard", "SampleCount", 5)), BlackRatioThresh: (IniRead(file, "Rotation.BlackGuard",
                "BlackRatioThresh", 0.7) + 0), WindowMs: Integer(IniRead(file, "Rotation.BlackGuard", "WindowMs", 120)),
        CooldownMs: Integer(IniRead(file, "Rotation.BlackGuard", "CooldownMs", 600)), MinAfterSendMs: Integer(IniRead(
            file, "Rotation.BlackGuard", "MinAfterSendMs", 60)), MaxAfterSendMs: Integer(IniRead(file,
                "Rotation.BlackGuard", "MaxAfterSendMs", 800)), UniqueRequired: Integer(IniRead(file,
                    "Rotation.BlackGuard", "UniqueRequired", 1))
    }

    ; Opener
    rot.Opener := { Enabled: Integer(IniRead(file, "Rotation.Opener", "Enabled", 0)), MaxDurationMs: Integer(IniRead(
        file, "Rotation.Opener", "MaxDurationMs", 4000)), Watch: [] }
    wcnt := Integer(IniRead(file, "Rotation.Opener", "WatchCount", 0))
    loop wcnt {
        sect := "Rotation.Opener.Watch" A_Index
        si := Integer(IniRead(file, sect, "SkillIndex", 0))
        need := Integer(IniRead(file, sect, "RequireCount", 1))
        ver := Integer(IniRead(file, sect, "VerifyBlack", 0))
        if (si > 0)
            rot.Opener.Watch.Push({ SkillIndex: si, RequireCount: need, VerifyBlack: ver })
    }

    ReadTrack(name, defId) {
        t := { Id: defId, Name: name, ThreadId: 1, MaxDurationMs: 8000, Watch: [], RuleRefs: [] }
        sec := "Rotation." name
        t.Id := Integer(IniRead(file, sec, "Id", defId))
        t.ThreadId := Integer(IniRead(file, sec, "ThreadId", 1))
        t.MaxDurationMs := Integer(IniRead(file, sec, "MaxDurationMs", 8000))
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
    rot.Track1 := ReadTrack("Track1", 1)
    rot.Track2 := ReadTrack("Track2", 2)

    ; 调试友好：若没显式启用，但已有 Watch → 自动启用
    if (rot.Enabled = 0) {
        if (rot.Opener.Watch.Length > 0 || rot.Track1.Watch.Length > 0 || rot.Track2.Watch.Length > 0) {
            rot.Enabled := 1
            ; 可选：Diag_Log("AutoEnable in LoadProfile")
        }
    }

    data.Rotation := rot
    data.Rotation := rot
    return data
}

Storage_SaveProfile(data) {
    global App
    file := App["ProfilesDir"] "\" data.Name App["ConfigExt"]

    IniWrite(data.StartHotkey, file, "General", "StartHotkey")
    IniWrite(data.PollIntervalMs, file, "General", "PollIntervalMs")
    IniWrite(data.SendCooldownMs, file, "General", "SendCooldownMs")
    IniWrite(data.Skills.Length, file, "General", "SkillCount")
    IniWrite(data.PickHoverEnabled, file, "General", "PickHoverEnabled")
    IniWrite(data.PickHoverOffsetY, file, "General", "PickHoverOffsetY")
    IniWrite(data.PickHoverDwellMs, file, "General", "PickHoverDwellMs")
    IniWrite(HasProp(data, "PickConfirmKey") ? data.PickConfirmKey : "LButton", file, "General", "PickConfirmKey")  ; 新增
    IniWrite(data.Points.Length, file, "General", "PointCount")
    IniWrite(data.Rules.Length, file, "General", "RuleCount")
    IniWrite(data.Buffs.Length, file, "General", "BuffCount")
    IniWrite(data.Threads.Length, file, "General", "ThreadCount")
    for i, t in data.Threads {
        sec := "Thread" i
        IniWrite(t.Name, file, sec, "Name")
    }
    ; ===== Default（兜底技能） =====
    ds := HasProp(data, "DefaultSkill") ? data.DefaultSkill : 0
    if ds {
        IniWrite(HasProp(ds, "Enabled") ? ds.Enabled : 0, file, "Default", "Enabled")
        IniWrite(HasProp(ds, "SkillIndex") ? ds.SkillIndex : 0, file, "Default", "SkillIndex")
        IniWrite(HasProp(ds, "CheckReady") ? ds.CheckReady : 1, file, "Default", "CheckReady")
        IniWrite(HasProp(ds, "ThreadId") ? ds.ThreadId : 1, file, "Default", "ThreadId")
        IniWrite(HasProp(ds, "CooldownMs") ? ds.CooldownMs : 600, file, "Default", "CooldownMs")
        IniWrite(HasProp(ds, "PreDelayMs") ? ds.PreDelayMs : 0, file, "Default", "PreDelayMs")
    }

    for idx, s in data.Skills {
        sec := "Skill" idx
        IniWrite(s.Name, file, sec, "Name")
        IniWrite(s.Key, file, sec, "Key")
        IniWrite(s.X, file, sec, "X")
        IniWrite(s.Y, file, sec, "Y")
        IniWrite(s.Color, file, sec, "Color")
        IniWrite(s.Tol, file, sec, "Tol")
        IniWrite(HasProp(s, "CastMs") ? s.CastMs : 0, file, sec, "CastMs")   ; 新增
    }
    for idx, p in data.Points {
        sec := "Point" idx
        IniWrite(p.Name, file, sec, "Name")
        IniWrite(p.X, file, sec, "X")
        IniWrite(p.Y, file, sec, "Y")
        IniWrite(p.Color, file, sec, "Color")
        IniWrite(p.Tol, file, sec, "Tol")
    }
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
                ; 原有像素条件写入
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
    ; ===== Rotation 保存（M1 简化） =====
    if HasProp(data, "Rotation") {
        rot := data.Rotation
        IniWrite(rot.Enabled, file, "Rotation", "Enabled")
        IniWrite(HasProp(rot, "DefaultTrackId") ? rot.DefaultTrackId : 1, file, "Rotation", "DefaultTrackId")
        IniWrite(HasProp(rot, "SwapKey") ? rot.SwapKey : "", file, "Rotation", "SwapKey")
        IniWrite(HasProp(rot, "BusyWindowMs") ? rot.BusyWindowMs : 200, file, "Rotation", "BusyWindowMs")
        IniWrite(HasProp(rot, "ColorTolBlack") ? rot.ColorTolBlack : 16, file, "Rotation", "ColorTolBlack")

        ; BlackGuard
        bg := HasProp(rot, "BlackGuard") ? rot.BlackGuard : 0
        if bg {
            IniWrite(HasProp(bg, "Enabled") ? bg.Enabled : 1, file, "Rotation.BlackGuard", "Enabled")
            IniWrite(HasProp(bg, "SampleCount") ? bg.SampleCount : 5, file, "Rotation.BlackGuard", "SampleCount")
            IniWrite(HasProp(bg, "BlackRatioThresh") ? bg.BlackRatioThresh : 0.7, file, "Rotation.BlackGuard",
            "BlackRatioThresh")
            IniWrite(HasProp(bg, "WindowMs") ? bg.WindowMs : 120, file, "Rotation.BlackGuard", "WindowMs")
            IniWrite(HasProp(bg, "CooldownMs") ? bg.CooldownMs : 600, file, "Rotation.BlackGuard", "CooldownMs")
            IniWrite(HasProp(bg, "MinAfterSendMs") ? bg.MinAfterSendMs : 60, file, "Rotation.BlackGuard",
            "MinAfterSendMs")
            IniWrite(HasProp(bg, "MaxAfterSendMs") ? bg.MaxAfterSendMs : 800, file, "Rotation.BlackGuard",
            "MaxAfterSendMs")
            IniWrite(HasProp(bg, "UniqueRequired") ? bg.UniqueRequired : 1, file, "Rotation.BlackGuard",
            "UniqueRequired")
        }

        ; Opener
        op := rot.Opener
        IniWrite(op.Enabled, file, "Rotation.Opener", "Enabled")
        IniWrite(op.MaxDurationMs, file, "Rotation.Opener", "MaxDurationMs")
        IniWrite(op.Watch.Length, file, "Rotation.Opener", "WatchCount")
        for i, w in op.Watch {
            s := "Rotation.Opener.Watch" i
            IniWrite(w.SkillIndex, file, s, "SkillIndex")
            IniWrite(HasProp(w, "RequireCount") ? w.RequireCount : 1, file, s, "RequireCount")
            IniWrite(HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0, file, s, "VerifyBlack")
        }

        ; Track1/2
        SaveTrack(name, t) {
            sec := "Rotation." name
            IniWrite(HasProp(t, "Id") ? t.Id : (name = "Track1" ? 1 : 2), file, sec, "Id")
            IniWrite(HasProp(t, "ThreadId") ? t.ThreadId : 1, file, sec, "ThreadId")
            IniWrite(HasProp(t, "MaxDurationMs") ? t.MaxDurationMs : 8000, file, sec, "MaxDurationMs")
            IniWrite(t.Watch.Length, file, sec, "WatchCount")
            for i, w in t.Watch {
                s := "Rotation." name ".Watch" i
                IniWrite(w.SkillIndex, file, s, "SkillIndex")
                IniWrite(HasProp(w, "RequireCount") ? w.RequireCount : 1, file, s, "RequireCount")
                IniWrite(HasProp(w, "VerifyBlack") ? w.VerifyBlack : 0, file, s, "VerifyBlack")
            }
            IniWrite(t.RuleRefs.Length, file, sec, "RuleCount")
            for i, rid in t.RuleRefs
                IniWrite(rid, file, "Rotation." name, "RuleRef" i)
        }
        SaveTrack("Track1", rot.Track1)
        SaveTrack("Track2", rot.Track2)
    }
}

Storage_DeleteProfile(name) {
    global App
    file := App["ProfilesDir"] "\" name App["ConfigExt"]
    if FileExist(file)
        FileDelete file
}
