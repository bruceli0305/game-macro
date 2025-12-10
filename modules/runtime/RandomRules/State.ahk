#Requires AutoHotkey v2

; 状态结构 + 规范化 + Profile 切换回调

global RR := {
    Running: false
  , TimerCallback: 0           ; SetTimer 用的回调（Func 对象）

  , Mode: "RandomEach"         ; 规则选择模式：RandomEach / ShuffleRound
  , RuleMinMs: 800             ; 规则之间最小间隔(ms)
  , RuleMaxMs: 1500
  , ActRandEnabled: 1          ; 是否启用动作间隔随机 1=是 0=否
  , ActMinMs: 50               ; 动作之间最小间隔(ms)
  , ActMaxMs: 200

  , StartDelayMs: 0            ; 新增：启动延迟（开始按钮 -> 第一次 Tick 前等待的 ms）

  , ProfileName: ""            ; 最近一次加载配置对应的 Profile 名

  ; 轮次洗牌模式用到的轮次池（RoundPool）和当前位置（RoundPos）
  , RoundPool: []              ; 当前轮的规则索引数组
  , RoundPos: 1                ; 指向 RoundPool 中下一个要执行的索引
}

RandomRules_NormalizeRanges() {
    global RR

    ; 规则间隔
    try {
        if (RR.RuleMinMs < 0) {
            RR.RuleMinMs := 0
        }
        if (RR.RuleMaxMs < RR.RuleMinMs) {
            RR.RuleMaxMs := RR.RuleMinMs
        }
    } catch {
    }

    ; 动作间隔
    try {
        if (RR.ActMinMs < 0) {
            RR.ActMinMs := 0
        }
        if (RR.ActMaxMs < RR.ActMinMs) {
            RR.ActMaxMs := RR.ActMinMs
        }
    } catch {
    }

    ; 启动延迟
    try {
        if (RR.StartDelayMs < 0) {
            RR.StartDelayMs := 0
        }
    } catch {
        RR.StartDelayMs := 0
    }

    ; 标志 & 模式
    try {
        RR.ActRandEnabled := (RR.ActRandEnabled ? 1 : 0)
    } catch {
        RR.ActRandEnabled := 1
    }

    try {
        m := "" RR.Mode
        if (m = "ShuffleRound") {
            RR.Mode := "ShuffleRound"
        } else {
            RR.Mode := "RandomEach"
        }
    } catch {
        RR.Mode := "RandomEach"
    }
}

RandomRules_OnProfileChanged(profileName) {
    ; 切换 Profile 时：停止随机、加载新 Profile 的配置（Config 模块里实现）
    try {
        RandomRules_Stop()
    } catch {
    }
    try {
        RandomRules_LoadConfig(profileName)
    } catch {
    }
}

RandomRules_IsRunning() {
    global RR
    return RR.Running
}