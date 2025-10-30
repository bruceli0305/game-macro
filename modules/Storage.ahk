; Storage.ahk - INI 配置读写/管理
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
        data.Skills.Push({ Name: sName, Key: sKey, X: sX, Y: sY, Color: sClr, Tol: sTol })
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
        data.Buffs.Push({ Name: bName, Enabled: bEn, DurationMs: bDur, RefreshBeforeMs: bRef, CheckReady: bChk, ThreadId:bThr, Skills: skills,
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
                si   := Integer(IniRead(file, cSec, "SkillIndex", 1))
                cmp  := IniRead(file, cSec, "Cmp", "GE")   ; GE/GT/EQ/LE/LT
                val  := Integer(IniRead(file, cSec, "Value", 1))
                rst  := Integer(IniRead(file, cSec, "ResetOnTrigger", 0))
                conds.Push({ Kind:"Counter", SkillIndex: si, Cmp: cmp, Value: val, ResetOnTrigger: rst })
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
    dsEn  := Integer(IniRead(file, "Default", "Enabled", 0))
    dsIdx := Integer(IniRead(file, "Default", "SkillIndex", 0))
    dsRdy := Integer(IniRead(file, "Default", "CheckReady", 1))
    dsTid := Integer(IniRead(file, "Default", "ThreadId", 1))
    dsCd  := Integer(IniRead(file, "Default", "CooldownMs", 600))
    dsPre := Integer(IniRead(file, "Default", "PreDelayMs", 0))
    data.DefaultSkill := {
        Enabled: dsEn, SkillIndex: dsIdx, CheckReady: dsRdy, ThreadId: dsTid
      , CooldownMs: dsCd, PreDelayMs: dsPre, LastFire: 0
    }

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
        IniWrite(HasProp(ds,"Enabled")    ? ds.Enabled    : 0,   file, "Default", "Enabled")
        IniWrite(HasProp(ds,"SkillIndex") ? ds.SkillIndex : 0,   file, "Default", "SkillIndex")
        IniWrite(HasProp(ds,"CheckReady") ? ds.CheckReady : 1,   file, "Default", "CheckReady")
        IniWrite(HasProp(ds,"ThreadId")   ? ds.ThreadId   : 1,   file, "Default", "ThreadId")
        IniWrite(HasProp(ds,"CooldownMs") ? ds.CooldownMs : 600, file, "Default", "CooldownMs")
        IniWrite(HasProp(ds,"PreDelayMs") ? ds.PreDelayMs : 0,   file, "Default", "PreDelayMs")
    }
    
    for idx, s in data.Skills {
        sec := "Skill" idx
        IniWrite(s.Name, file, sec, "Name")
        IniWrite(s.Key, file, sec, "Key")
        IniWrite(s.X, file, sec, "X")
        IniWrite(s.Y, file, sec, "Y")
        IniWrite(s.Color, file, sec, "Color")
        IniWrite(s.Tol, file, sec, "Tol")
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
                IniWrite(HasProp(c,"SkillIndex") ? c.SkillIndex : 1, file, cSec, "SkillIndex")
                IniWrite(HasProp(c,"Cmp") ? c.Cmp : "GE",            file, cSec, "Cmp")
                IniWrite(HasProp(c,"Value") ? c.Value : 1,          file, cSec, "Value")
                IniWrite(HasProp(c,"ResetOnTrigger") ? c.ResetOnTrigger : 0, file, cSec, "ResetOnTrigger")
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
}

Storage_DeleteProfile(name) {
    global App
    file := App["ProfilesDir"] "\" name App["ConfigExt"]
    if FileExist(file)
        FileDelete file
}
