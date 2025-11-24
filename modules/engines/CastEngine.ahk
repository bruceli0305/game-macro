#Requires AutoHotkey v2

; CastEngine.ahk
; 负责管理“当前规则技能列表 + 状态机”，为施法条和调试窗口提供统一数据源
; 仅依赖：
;   - global App["ProfileData"].Skills / .CastBar
;   - Pixel_FrameGet / Pixel_HexToInt / Pixel_ColorMatch
;   - Logger_*
; 严格块结构：不使用单行 if/try/catch

; 状态枚举
global CAST_STATE_READY   := 1
global CAST_STATE_CASTING := 2
global CAST_STATE_DONE    := 3
global CAST_STATE_FAILED  := 4

; 当前规则技能状态
global gCast := {
    Active: false
  , RuleIndex: 0
  , RuleName: ""
  , TrackId: 0
  , TrackName: ""
  , ThreadId: 1
  , Skills: []     ; [{ SkillIndex, Name, ActionIndex, State, StartedAt, EndedAt, FailedAt, LockDuringCast, TimeoutMs }]
}

CastEngine_InitFromProfile() {
    global gCast
    ; 对于当前实现，只需清空状态，后续可按需要扩展
    CastEngine_ClearCurrent()
}

CastEngine_ClearCurrent() {
    global gCast
    gCast.Active := false
    gCast.RuleIndex := 0
    gCast.RuleName := ""
    gCast.TrackId := 0
    gCast.TrackName := ""
    gCast.ThreadId := 1
    gCast.Skills := []
}

CastEngine_OnRuleTriggered(prof, ruleIndex, rule, trackId := 0, trackName := "") {
    global gCast

    CastEngine_ClearCurrent()

    gCast.Active := true
    gCast.RuleIndex := ruleIndex
    gCast.RuleName := ""
    if HasProp(rule, "Name") {
        gCast.RuleName := rule.Name
    }
    gCast.TrackId := trackId
    gCast.TrackName := trackName
    gCast.ThreadId := 1
    if HasProp(rule, "ThreadId") {
        gCast.ThreadId := rule.ThreadId
    }

    gCast.Skills := []

    if !HasProp(rule, "Actions") {
        return
    }
    acts := rule.Actions
    if !IsObject(acts) {
        return
    }

    if !HasProp(prof, "Skills") {
        return
    }

    i := 1
    while (i <= acts.Length) {
        act := acts[i]
        si := 0
        if HasProp(act, "SkillIndex") {
            si := act.SkillIndex
        }
        if (si >= 1 && si <= prof.Skills.Length) {
            s := prof.Skills[si]

            timeout := 0
            if HasProp(s, "CastTimeoutMs") {
                timeout := s.CastTimeoutMs
            }
            if (timeout <= 0 && HasProp(s, "CastMs")) {
                timeout := s.CastMs
            }

            lockFlag := 1
            if HasProp(s, "LockDuringCast") {
                lockFlag := s.LockDuringCast
            }

            entry := {
                SkillIndex: si
              , Name: ""
              , ActionIndex: i
              , State: CAST_STATE_READY
              , StartedAt: 0
              , EndedAt: 0
              , FailedAt: 0
              , LockDuringCast: lockFlag
              , TimeoutMs: timeout
            }
            try {
                if HasProp(s, "Name") {
                    entry.Name := s.Name
                }
            } catch {
            }

            gCast.Skills.Push(entry)
        }
        i := i + 1
    }
}

CastEngine_OnSkillSent(skillIndex, src := "") {
    global gCast, App

    if !gCast.Active {
        return
    }
    if !IsSet(App) {
        return
    }
    if !App.Has("ProfileData") {
        return
    }
    prof := App["ProfileData"]

    useBar := 0
    try {
        if HasProp(prof, "CastBar") {
            useBar := (prof.CastBar.Enabled ? 1 : 0)
        }
    } catch {
        useBar := 0
    }

    ; 在当前规则技能列表中，找到第一条匹配 SkillIndex 且处于 READY 的记录
    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]
        if (e.SkillIndex = skillIndex && e.State = CAST_STATE_READY) {
            now := A_TickCount
            if (useBar) {
                e.State := CAST_STATE_CASTING
                e.StartedAt := now
            } else {
                e.State := CAST_STATE_DONE
                e.StartedAt := now
                e.EndedAt := now
            }
            gCast.Skills[i] := e
            break
        }
        i := i + 1
    }
}

CastEngine_Tick() {
    global gCast, App

    if !gCast.Active {
        return
    }
    if !IsSet(App) {
        return
    }
    if !App.Has("ProfileData") {
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "CastBar") {
        return
    }
    cb := prof.CastBar
    if !cb.Enabled {
        return
    }

    ; 是否有处于 CASTING 的技能
    hasCasting := false
    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]
        if (e.State = CAST_STATE_CASTING) {
            hasCasting := true
            break
        }
        i := i + 1
    }
    if !hasCasting {
        return
    }

    ; 施法条当前颜色
    cur := 0
    try {
        cur := Pixel_FrameGet(cb.X, cb.Y)
    } catch {
        cur := 0
    }

    tgtInt := 0
    try {
        tgtInt := Pixel_HexToInt(cb.Color)
    } catch {
        tgtInt := 0
    }

    barActive := false
    try {
        barActive := Pixel_ColorMatch(cur, tgtInt, cb.Tol)
    } catch {
        barActive := false
    }

    now := A_TickCount

    ; 施法条不活跃：视为当前所有 CASTING 已结束（成功）
    if !barActive {
        i := 1
        while (i <= gCast.Skills.Length) {
            e := gCast.Skills[i]
            if (e.State = CAST_STATE_CASTING) {
                e.State := CAST_STATE_DONE
                e.EndedAt := now
                gCast.Skills[i] := e
            }
            i := i + 1
        }
        return
    }

    ; 施法条活跃：对 CASTING 技能做超时失败判定
    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]
        if (e.State = CAST_STATE_CASTING) {
            timeout := e.TimeoutMs
            if (timeout > 0 && e.StartedAt > 0) {
                elapsed := now - e.StartedAt
                if (elapsed > timeout) {
                    e.State := CAST_STATE_FAILED
                    e.FailedAt := now
                    gCast.Skills[i] := e
                }
            }
        }
        i := i + 1
    }
}

CastEngine_LogCurrentRuleIfNeeded(reason := "SessionEnd") {
    global gCast, App

    if !gCast.Active {
        return
    }
    if !IsSet(App) {
        return
    }
    if !App.Has("ProfileData") {
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "CastBar") {
        return
    }
    cb := prof.CastBar
    if !cb.DebugLog {
        return
    }

    fields := Map()
    fields["ruleIndex"] := gCast.RuleIndex
    fields["ruleName"] := gCast.RuleName
    fields["trackId"] := gCast.TrackId
    fields["trackName"] := gCast.TrackName
    fields["threadId"] := gCast.ThreadId
    fields["reason"] := reason

    listStr := ""
    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]
        stateName := CastEngine_StateName(e.State)
        idxText := "" i
        nameText := ""
        try {
            nameText := e.Name
        } catch {
            nameText := ""
        }
        item := idxText ":" nameText ":" stateName
        if (listStr = "") {
            listStr := item
        } else {
            listStr := listStr ";" item
        }
        i := i + 1
    }
    fields["skills"] := listStr

    try {
        Logger_Info("Cast", "RuleSkillSummary", fields)
    } catch {
    }
}

CastEngine_StateName(state) {
    if (state = CAST_STATE_READY) {
        return "READY"
    }
    if (state = CAST_STATE_CASTING) {
        return "CASTING"
    }
    if (state = CAST_STATE_DONE) {
        return "DONE"
    }
    if (state = CAST_STATE_FAILED) {
        return "FAILED"
    }
    return "UNKNOWN"
}