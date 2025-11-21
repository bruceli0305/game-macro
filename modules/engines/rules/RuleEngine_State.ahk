; RuleEngine_State.ahk - 全局开关/状态（唯一定义点）

; 调试与提示
global RE_Debug := IsSet(RE_Debug) ? RE_Debug : false
global RE_DebugVerbose := IsSet(RE_DebugVerbose) ? RE_DebugVerbose : false
global RE_ShowTips := IsSet(RE_ShowTips) ? RE_ShowTips : false

; 规则过滤与最后触发时间
global RE_Filter := IsSet(RE_Filter) ? RE_Filter : { Enabled:false, AllowSkills:0, AllowRuleIds:0 }
global RE_LastFireTick := IsSet(RE_LastFireTick) ? RE_LastFireTick : Map()

; 会话（M3：含验证状态）
global RE_Session := IsSet(RE_Session) ? RE_Session : { Active:false, RuleId:0, ThreadId:1
                                                      , Index:1, StartedAt:0, NextAt:0
                                                      , HadAnySend:false, LockWaitUntil:0
                                                      , TimeoutAt:0
                                                      , VerActive:false, VerSkillIndex:0
                                                      , VerTargetInt:0, VerTol:0
                                                      , VerLastTick:0, VerElapsed:0
                                                      , VerTimeoutMs:0, VerRetryLeft:0, VerRetryGapMs:150 }

; 会话参数（可调）
global RE_Session_CastMarginMs := IsSet(RE_Session_CastMarginMs) ? RE_Session_CastMarginMs : 100
global RE_Session_BusyPerActionMax := IsSet(RE_Session_BusyPerActionMax) ? RE_Session_BusyPerActionMax : 120

; 旧式阻塞回执（用于计数模式）开关
global RE_VerifySend := IsSet(RE_VerifySend) ? RE_VerifySend : true
global RE_VerifyForCounterOnly := IsSet(RE_VerifyForCounterOnly) ? RE_VerifyForCounterOnly : true
global RE_VerifyWaitMs := IsSet(RE_VerifyWaitMs) ? RE_VerifyWaitMs : 150
global RE_VerifyTimeoutMs := IsSet(RE_VerifyTimeoutMs) ? RE_VerifyTimeoutMs : 600
global RE_VerifyRetry := IsSet(RE_VerifyRetry) ? RE_VerifyRetry : 1
; 扫描顺序（轨道内的有序 RuleRefs 注入）
global RE_ScanOrder := IsSet(RE_ScanOrder) ? RE_ScanOrder : []

RE_SessionActive() {
    return (IsObject(RE_Session) && RE_Session.Active)
}
; 在 ProfileData 重新加载/替换后调用
RE_OnProfileDataReplaced(prof) {
    global RE_LastFireTick
    try {
        RE_LastFireTick := Map()
    } catch {
        RE_LastFireTick := Map()
    }

    RE_ClearFilter()
    RE_ClearScanOrder()

    ; 可选：根据新轨道注入扫描顺序（若 Rotation 已注入可忽略）
    ; if (IsObject(prof) && HasProp(prof, "Rotation") && IsObject(prof.Rotation)) {
    ;     ; 例如：从当前轨道 RuleRefs 注入（这些应是运行时索引）
    ; }
}