; Rotation_State.ahk - 全局状态/日志/基础开关
;modules\engines\rotation\Rotation_State.ahk
global gRot := IsSet(gRot) ? gRot : Map()   ; { Cfg, RT }
global gRotInitBusy := IsSet(gRotInitBusy) ? gRotInitBusy : false
global gRotInitialized := IsSet(gRotInitialized) ? gRotInitialized : false

Rotation_Reset() {
    global gRot, gRotInitialized, gRotInitBusy
    try gRot.Clear()
    gRot := Map()
    gRotInitBusy := false
    gRotInitialized := false
}

Rotation_IsEnabled() {
    try {
        return !!(gRot.Has("Cfg") ? gRot["Cfg"].Enabled : 0)
    } catch {
        return false
    }
}
Rotation_IsBusyWindowActive() {
    try {
        return Rotation_IsEnabled() && gRot.Has("RT") && (A_TickCount < gRot["RT"].BusyUntil)
    } catch {
        return false
    }
}

Rotation_NewRT(cfg) {
    rt := {
        Phase: "Idle"               ; "Opener" | "Track"
      , TrackId: 0
      , BusyUntil: 0
      , GateCooldownUntil: 0
      , OpenerDone: false
      , PhaseState: 0               ; { StartedAt, Baseline:Map, Items:[{si,need,verify,BlackSeen}] }
      , LastSent: Map()             ; SkillIndex -> last tick（用于黑框时间窗）
      , BlackoutUntil: 0            ; 全局黑忽略窗口截止
      , FreezeUntil: 0              ; 黑屏冻结（WindowMs）
      , OpStep: { Index: 1, StepStarted: 0, StepWaiting: 0 }
    }
    return rt
}