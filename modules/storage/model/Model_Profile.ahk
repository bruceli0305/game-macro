#Requires AutoHotkey v2
;modules\storage\model\Model_Profile.ahk 数据模型 Profile
; 新建空 Profile（带默认值 & NextId 初值 & IdMap 空表）
PM_NewProfile(name := "Default") {
    p := Map()
    p["Name"] := "" name

    meta := Map()
    meta["SchemaVersion"] := PM_SCHEMA_VERSION
    meta["DisplayName"] := "" name
    meta["CreatedAt"] := PM_NowStr()
    meta["ModifiedAt"] := PM_NowStr()

    nexts := Map()
    nexts["Skill"]  := 1
    nexts["Point"]  := 1
    nexts["Rule"]   := 1
    nexts["Track"]  := 1
    nexts["Gate"]   := 1
    nexts["Buff"]   := 1
    nexts["Thread"] := 1
    meta["NextId"] := nexts
    p["Meta"] := meta

    p["General"] := PM_DefaultGeneral()
    p["Skills"]  := []
    p["Points"]  := []
    p["Rules"]   := []
    p["Buffs"]   := []

    rot := PM_DefaultRotation()
    p["Rotation"] := rot

    ; IdMap 占位（加载后或保存后构建）
    p["IdMap"] := Map()
    return p
}

; General + DefaultSkill + Threads
PM_DefaultGeneral() {
    g := Map()
    g["StartHotkey"] := "F9"
    g["PollIntervalMs"] := 25
    g["SendCooldownMs"] := 250
    g["PickHoverEnabled"] := 1
    g["PickHoverOffsetY"] := -60
    g["PickHoverDwellMs"] := 120
    g["PickConfirmKey"] := "LButton"

    ; 线程（带稳定 ThreadId，从 1 起）
    ths := []
    ths.Push(Map("Id", 1, "Name", "默认线程"))
    g["Threads"] := ths

    ; 兜底技能（引用稳定 SkillId；初始为 0 表示未设置）
    ds := Map()
    ds["Enabled"] := 0
    ds["SkillId"] := 0
    ds["CheckReady"] := 1
    ds["ThreadId"] := 1
    ds["CooldownMs"] := 600
    ds["PreDelayMs"] := 0
    g["DefaultSkill"] := ds

    ; === 新增：施法条配置（CastBar） ===
    g["CastBarEnabled"] := 0             ; 是否启用施法条检测
    g["CastBarX"] := 0                   ; 施法条取色点 X
    g["CastBarY"] := 0                   ; 施法条取色点 Y
    g["CastBarColor"] := "0x000000"      ; 施法条“激活状态”颜色
    g["CastBarTol"] := 10                ; 容差
    g["CastBarDebugLog"] := 0            ; 规则结束时是否写技能状态日志
    g["CastBarIgnoreActionDelay"] := 0   ; 是否忽略规则的 ActionGapMs / DelayMs

    ; === 新增：技能调试窗口配置（CastDebug） ===
    g["CastDebugHotkey"] := ""           ; 调试窗口快捷键（例如 "F11"）
    g["CastDebugTopmost"] := 1           ; 调试窗口是否置顶
    g["CastDebugAlpha"] := 230           ; 调试窗口透明度 0-255

    return g
}

; Rotation 默认（基础 + BlackGuard + SwapVerify + Opener + 空 Tracks/Gates）
PM_DefaultRotation() {
    r := Map()
    r["Enabled"] := 0
    r["DefaultTrackId"] := 0
    r["SwapKey"] := ""
    r["BusyWindowMs"] := 200
    r["ColorTolBlack"] := 16
    r["RespectCastLock"] := 1

    ; BlackGuard
    bg := Map()
    bg["Enabled"] := 1
    bg["SampleCount"] := 5
    bg["BlackRatioThresh"] := 0.7
    bg["WindowMs"] := 120
    bg["CooldownMs"] := 600
    bg["MinAfterSendMs"] := 60
    bg["MaxAfterSendMs"] := 800
    bg["UniqueRequired"] := 1
    r["BlackGuard"] := bg

    ; Gates 开关与冷却（仅开关与冷却在 base 保存）
    r["GatesEnabled"] := 0
    r["GateCooldownMs"] := 0

    ; SwapVerify（引用 Id：RefType=Skill|Point，RefId 为稳定 Id）
    sv := Map()
    sv["RefType"] := "Skill"
    sv["RefId"] := 0
    sv["Op"] := "NEQ"
    sv["Color"] := "0x000000"
    sv["Tol"] := 16
    r["SwapVerify"] := sv
    r["VerifySwap"] := 0
    r["SwapTimeoutMs"] := 800
    r["SwapRetry"] := 0

    ; Opener
    op := Map()
    op["Enabled"] := 0
    op["MaxDurationMs"] := 4000
    op["ThreadId"] := 1
    op["Watch"] := []     ; [{SkillId, RequireCount, VerifyBlack}]
    op["Steps"] := []     ; [{Kind:Skill|Wait|Swap, ...}]
    r["Opener"] := op

    ; Tracks/Gates（稳定 Id）
    r["Tracks"] := []     ; [{Id, Name, ThreadId, MaxDurationMs, MinStayMs, NextTrackId, Watch[], RuleRefs[]}]
    r["Gates"] := []      ; [{Id, Priority, FromTrackId, ToTrackId, Logic, Conds[]}]
    return r
}
; 工厂：构建一个空 Track（新增 Name）
PM_NewTrack() {
    t := Map()
    t["Id"] := 0
    t["Name"] := ""            ; 新增：显示名（UI/存储层使用）
    t["ThreadId"] := 1
    t["MaxDurationMs"] := 8000
    t["MinStayMs"] := 0
    t["NextTrackId"] := 0
    t["Watch"] := []      ; [{SkillId, RequireCount, VerifyBlack}]
    t["RuleRefs"] := []   ; RuleId[]
    return t
}

; 工厂（可选）：构建一个空 Skill/Point/Rule/Buff/Track/Gate
PM_NewSkill(name := "") {
    s := Map()
    s["Id"] := 0
    s["Name"] := "" name
    s["Key"] := ""
    s["X"] := 0
    s["Y"] := 0
    s["Color"] := "0x000000"
    s["Tol"] := 10
    s["CastMs"] := 0

    ; 新增：施放期间是否禁止本线程释放其他技能（1=禁止，0=允许穿插）
    s["LockDuringCast"] := 1

    ; 新增：读条超时（毫秒），0 表示使用 CastMs 或不判超时
    s["CastTimeoutMs"] := 0

    return s
}

PM_NewPoint(name := "") {
    p := Map()
    p["Id"] := 0
    p["Name"] := "" name
    p["X"] := 0
    p["Y"] := 0
    p["Color"] := "0x000000"
    p["Tol"] := 10
    return p
}

PM_NewRule(name := "") {
    r := Map()
    r["Id"] := 0
    r["Name"] := "" name
    r["Enabled"] := 1
    r["Logic"] := "AND"
    r["CooldownMs"] := 500
    r["Priority"] := 0
    r["ActionGapMs"] := 60
    r["ThreadId"] := 1
    r["SessionTimeoutMs"] := 0
    r["AbortCooldownMs"] := 0
    r["Conditions"] := []   ; 用 Id 引用
    r["Actions"] := []      ; 用 Id 引用
    r["LastFire"] := 0
    return r
}

PM_NewBuff(name := "") {
    b := Map()
    b["Id"] := 0
    b["Name"] := "" name
    b["Enabled"] := 1
    b["DurationMs"] := 0
    b["RefreshBeforeMs"] := 0
    b["CheckReady"] := 1
    b["ThreadId"] := 1
    b["Skills"] := []   ; SkillId[]
    b["LastTime"] := 0
    b["NextIdx"] := 1
    return b
}

PM_NewGate() {
    g := Map()
    g["Id"] := 0
    g["Priority"] := 0
    g["FromTrackId"] := 0
    g["ToTrackId"] := 0
    g["Logic"] := "AND"
    g["Conds"] := []      ; [{Kind, RefType, RefId, Op, Color, Tol, RuleId, QuietMs, Cmp, Value, ElapsedMs}]
    return g
}

; 条件与动作构造（Id 引用）
PM_NewCondPixel(refType := "Skill", refId := 0) {
    c := Map()
    c["Kind"] := "PixelReady"
    c["RefType"] := "" refType
    c["RefId"] := Integer(refId)
    c["Op"] := "NEQ"
    c["Color"] := "0x000000"
    c["Tol"] := 16
    c["RuleId"] := 0
    c["QuietMs"] := 0
    c["Cmp"] := "GE"
    c["Value"] := 0
    c["ElapsedMs"] := 0
    return c
}

PM_NewCondCounter(skillId := 0) {
    c := Map()
    c["Kind"] := "Counter"
    c["SkillId"] := Integer(skillId)
    c["Cmp"] := "GE"
    c["Value"] := 1
    c["ResetOnTrigger"] := 0
    return c
}

PM_NewAction(skillId := 0) {
    a := Map()
    a["SkillId"] := Integer(skillId)
    a["DelayMs"] := 0
    a["HoldMs"] := -1
    a["RequireReady"] := 0
    a["Verify"] := 0
    a["VerifyTimeoutMs"] := 600
    a["Retry"] := 0
    a["RetryGapMs"] := 150
    return a
}