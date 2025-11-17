; Core.ahk - 全局状态与默认配置
global App := Map()

Core_Init() {
    global App
    App["ProfilesDir"] := A_ScriptDir "\Profiles"
    App["ExportDir"]   := A_ScriptDir "\Exports"
    App["ConfigExt"]   := ".ini"

    App["CurrentProfile"] := ""
    App["Profiles"]       := []
    App["ProfileData"]    := Core_DefaultProfileData()
    App["IsRunning"]      := false
    App["BoundHotkeys"]   := Map()

    DirCreate(App["ProfilesDir"])
    DirCreate(App["ExportDir"])
}

Core_DefaultProfileData() {
    ; Note: 可扩展更多 General 项
    return {
        Name: "Default"
      , StartHotkey: "F9"         ; 开始/停止
      , PollIntervalMs: 25        ; 轮询间隔
      , SendCooldownMs: 250       ; 全局每次发送延迟
      , PickHoverEnabled: 1          ; 取色避让：1=开 0=关
      , PickHoverOffsetY: -60        ; 负数=向上移动
      , PickHoverDwellMs: 120        ; 避让后等待时间
      , PickConfirmKey: "LButton"      ; 新增：拾色确认热键
      , Skills: []                ; { Name, Key, X, Y, Color("0xRRGGBB"), Tol }
      , Points: []   ; 新增：独立点位
      , Rules: []                      ; 规则数组（见 Rule 结构）
      , Buffs: []    ; 续BUFF配置数组
      , Threads: [ { Id: 1, Name: "默认线程" } ]
      , DefaultSkill: {           ; 新增：兜底技能配置
            Enabled: 0
          , SkillIndex: 0         ; 0=未选
          , CheckReady: 1         ; 是否检测像素就绪
          , ThreadId: 1
          , CooldownMs: 600       ; 兜底触发冷却，避免每Tick都发
          , PreDelayMs: 0         ; 触发前延时
          , LastFire: 0           ; 运行时字段，不落盘
        }
      , Rotation: {
          Enabled: 0
        , DefaultTrackId: 1
        , SwapKey: ""                 ; M1 可不填；切轨时若有则发送
        , BusyWindowMs: 200
        , ColorTolBlack: 16
        , RespectCastLock: 1
        , BlackGuard: { Enabled: 1, SampleCount: 5, BlackRatioThresh: 0.7
                      , WindowMs: 120, CooldownMs: 600, MinAfterSendMs: 60
                      , MaxAfterSendMs: 800, UniqueRequired: 1 }
        , Opener: { Enabled: 0, MaxDurationMs: 4000, Watch: [] }
      }
    }
}