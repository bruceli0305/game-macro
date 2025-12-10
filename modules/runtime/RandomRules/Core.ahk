#Requires AutoHotkey v2
;modules\runtime\RandomRules\Core.ahk
;================ 初始化 ================
RandomRules_Init() {
    global RR
    RR.TimerCallback := RR_Tick
    RandomRules_NormalizeRanges()
}

;================ Start / Stop ================
RandomRules_Start() {
    global RR, App

    if (RandomRules_IsRunning()) {
        Notify("随机规则触发已在运行。")
        return false
    }

    ; Poller 冲突检查（方案B）
    isPollerRunning := false
    try {
        isPollerRunning := Poller_IsRunning()
    } catch {
        isPollerRunning := false
    }
    if (isPollerRunning) {
        MsgBox "当前主循环正在运行，请先按开始/停止热键（默认 F9）停止主循环，再启动随机规则触发。"
        return false
    }

    ; 当前 Profile 名称
    curName := ""
    try {
        if IsObject(App) && App.Has("CurrentProfile") {
            curName := App["CurrentProfile"]
        }
    } catch {
        curName := ""
    }
    if (curName = "") {
        MsgBox "当前未选择配置（Profile），无法启动随机规则触发。"
        return false
    }

    ; 懒加载该 Profile 的配置
    try {
        if (RR.ProfileName != curName) {
            RandomRules_LoadConfig(curName)
        }
    } catch {
    }

    RandomRules_NormalizeRanges()

    ; 清空轮次池，保证新配置生效
    try {
        RR.RoundPool := []
        RR.RoundPos := 1
    } catch {
    }

    RR.Running := true

    ; 启动延迟：StartDelayMs >0 时，首次 Tick 等待该时长
    delay := 0
    try {
        delay := RR.StartDelayMs
    } catch {
        delay := 0
    }

    try {
        RandomRules_ScheduleNextTick(delay)
    } catch {
    }

    try {
        Logger_Info("RandomRules", "Start", Map(
              "profile", curName
            , "Mode", RR.Mode
            , "RuleMinMs", RR.RuleMinMs
            , "RuleMaxMs", RR.RuleMaxMs
            , "ActRandEnabled", RR.ActRandEnabled
            , "ActMinMs", RR.ActMinMs
            , "ActMaxMs", RR.ActMaxMs
            , "StartDelayMs", RR.StartDelayMs
        ))
    } catch {
    }

    Notify("随机规则触发：已启动（随机执行规则动作，不扫屏）")
    return true
}

RandomRules_Stop() {
    global RR

    if (!RR.Running) {
        return
    }

    RR.Running := false

    try {
        if (RR.TimerCallback) {
            SetTimer(RR.TimerCallback, 0)
        }
    } catch {
    }

    try {
        Logger_Info("RandomRules", "Stop", Map(
            "profile", RR.ProfileName
        ))
    } catch {
    }

    Notify("随机规则触发：已停止")
}

;================ 启用规则收集 ================
RandomRules_CollectEnabledRules() {
    global App

    list := []

    if !IsSet(App) {
        return list
    }
    if !App.Has("ProfileData") {
        return list
    }
    if !HasProp(App["ProfileData"], "Rules") {
        return list
    }
    if !IsObject(App["ProfileData"].Rules) {
        return list
    }

    i := 1
    while (i <= App["ProfileData"].Rules.Length) {
        r := App["ProfileData"].Rules[i]
        en := 0
        try {
            if (HasProp(r, "Enabled") && r.Enabled) {
                en := 1
            } else {
                en := 0
            }
        } catch {
            en := 0
        }
        if (en) {
            list.Push(i)
        }
        i := i + 1
    }

    return list
}

;================ Tick 调度 ================
RandomRules_ScheduleNextTick(delayMs := 0) {
    global RR

    if (!RR.Running) {
        return
    }

    d := 0
    try {
        d := Integer(delayMs)
    } catch {
        d := 0
    }
    ; AHK v2 中 delay=0 等于关闭定时器，这里最少 1ms
    if (d < 1) {
        d := 1
    }

    try {
        if (RR.TimerCallback) {
            SetTimer(RR.TimerCallback, 0)
        }
    } catch {
    }

    try {
        if (RR.TimerCallback) {
            SetTimer(RR.TimerCallback, -d)
        }
    } catch {
    }
}

;================ 执行一条规则（按动作顺序） ================
RandomRules_RunRule(ruleIdx) {
    global App, RR

    if !IsSet(App) {
        return
    }
    if !App.Has("ProfileData") {
        return
    }
    if !HasProp(App["ProfileData"], "Rules") {
        return
    }
    if !IsObject(App["ProfileData"].Rules) {
        return
    }

    if (ruleIdx < 1 || ruleIdx > App["ProfileData"].Rules.Length) {
        return
    }

    r := App["ProfileData"].Rules[ruleIdx]

    acts := []
    try {
        if (HasProp(r, "Actions") && IsObject(r.Actions)) {
            acts := r.Actions
        } else {
            acts := []
        }
    } catch {
        acts := []
    }

    if (acts.Length = 0) {
        return
    }

    threadId := 1
    try {
        threadId := HasProp(r, "ThreadId") ? r.ThreadId : 1
    } catch {
        threadId := 1
    }

    gapCfg := 0
    try {
        if (!RR.ActRandEnabled && HasProp(r, "ActionGapMs")) {
            gapCfg := Integer(r.ActionGapMs)
        } else {
            gapCfg := 0
        }
    } catch {
        gapCfg := 0
    }

    i := 1
    while (i <= acts.Length) {
        a := acts[i]

        if (!RR.Running) {
            break
        }

        waitMs := 0

        if (RR.ActRandEnabled) {
            try {
                if (RR.ActMaxMs > RR.ActMinMs) {
                    waitMs := Random(RR.ActMinMs, RR.ActMaxMs)
                } else {
                    waitMs := RR.ActMinMs
                }
            } catch {
                waitMs := RR.ActMinMs
            }
        } else {
            d := 0
            try {
                d := (HasProp(a, "DelayMs") ? Integer(a.DelayMs) : 0)
            } catch {
                d := 0
            }
            if (d > 0) {
                waitMs := d
            } else {
                waitMs := gapCfg
            }
        }

        if (waitMs > 0) {
            try {
                HighPrecisionDelay(waitMs)
            } catch {
                Sleep waitMs
            }
        }

        si := 0
        try {
            si := (HasProp(a, "SkillIndex") ? Integer(a.SkillIndex) : 0)
        } catch {
            si := 0
        }

        if (si >= 1) {
            try {
                ; HoldMs 一律忽略，传 0
                WorkerPool_SendSkillIndex(threadId, si, "RandomRules", 0)
            } catch {
            }
        }

        i := i + 1
    }
}

;================ Tick：随机/轮次 选择规则并执行 ================
RR_Tick(*) {
    global RR, App

    if (!RR.Running) {
        return
    }

    enabled := []
    try {
        enabled := RandomRules_CollectEnabledRules()
    } catch {
        enabled := []
    }

    if (enabled.Length = 0) {
        RR.Running := false
        try {
            if (RR.TimerCallback) {
                SetTimer(RR.TimerCallback, 0)
            }
        } catch {
        }
        try {
            Logger_Warn("RandomRules", "NoEnabledRules_Stop", Map(
                "profile", RR.ProfileName
            ))
        } catch {
        }
        Notify("随机规则触发：当前配置没有启用规则，已自动停止。")
        return
    }

    ruleIdx := 0

    ; ---- 模式一：每次随机选择一条启用规则 ----
    if (RR.Mode = "RandomEach") {
        try {
            maxN := enabled.Length
            if (maxN >= 1) {
                r := Random(1, maxN)
                ruleIdx := enabled[r]
            }
        } catch {
            ruleIdx := 0
        }
    } else {
        ; ---- 模式二：轮次洗牌 ----
        ; 每一轮把 enabled 复制一份洗牌，按顺序用完，再开新一轮
        ; 若 RoundPool 为空或 RoundPos 超出范围，则重建
        needRebuild := false
        try {
            if (!IsObject(RR.RoundPool) || RR.RoundPool.Length = 0) {
                needRebuild := true
            } else if (RR.RoundPos < 1 || RR.RoundPos > RR.RoundPool.Length) {
                needRebuild := true
            }
        } catch {
            needRebuild := true
        }

        if (needRebuild) {
            ; 重建轮次池：使用当前 enabled 列表
            np := []
            i := 1
            while (i <= enabled.Length) {
                np.Push(enabled[i])
                i := i + 1
            }

            ; 洗牌（Fisher-Yates）
            j := np.Length
            while (j > 1) {
                k := Random(1, j)
                tmp := np[j]
                np[j] := np[k]
                np[k] := tmp
                j := j - 1
            }

            try {
                RR.RoundPool := np
                RR.RoundPos := 1
            } catch {
            }
        }

        try {
            if (IsObject(RR.RoundPool) && RR.RoundPool.Length >= 1) {
                if (RR.RoundPos < 1) {
                    RR.RoundPos := 1
                }
                if (RR.RoundPos > RR.RoundPool.Length) {
                    RR.RoundPos := RR.RoundPool.Length
                }
                ruleIdx := RR.RoundPool[RR.RoundPos]
                RR.RoundPos := RR.RoundPos + 1
            }
        } catch {
            ruleIdx := 0
        }
    }

    rObj := 0
    rid := 0
    rname := ""
    thrId := 0
    actCount := 0

    if (ruleIdx >= 1) {
        try {
            if IsSet(App) && App.Has("ProfileData") {
                if (HasProp(App["ProfileData"], "Rules") && IsObject(App["ProfileData"].Rules)) {
                    if (ruleIdx >= 1 && ruleIdx <= App["ProfileData"].Rules.Length) {
                        rObj := App["ProfileData"].Rules[ruleIdx]
                    }
                }
            }
        } catch {
            rObj := 0
        }
    }

    if (rObj) {
        try {
            rid := HasProp(rObj, "Id") ? rObj.Id : 0
        } catch {
            rid := 0
        }
        try {
            rname := HasProp(rObj, "Name") ? rObj.Name : ""
        } catch {
            rname := ""
        }
        try {
            thrId := HasProp(rObj, "ThreadId") ? rObj.ThreadId : 0
        } catch {
            thrId := 0
        }
        try {
            if (HasProp(rObj, "Actions") && IsObject(rObj.Actions)) {
                actCount := rObj.Actions.Length
            } else {
                actCount := 0
            }
        } catch {
            actCount := 0
        }

        try {
            f := Map()
            f["profile"]    := RR.ProfileName
            f["ruleIndex"]  := ruleIdx
            f["ruleId"]     := rid
            f["ruleName"]   := rname
            f["threadId"]   := thrId
            f["actionCount"]:= actCount
            f["mode"]       := RR.Mode
            Logger_Info("RandomRules", "PickRule", f)
        } catch {
        }

        try {
            RandomRules_RunRule(ruleIdx)
        } catch {
        }
    } else {
        try {
            Logger_Warn("RandomRules", "PickRule_Failed", Map(
                "profile", RR.ProfileName
            ))
        } catch {
        }
    }

    ; 安排下一次 Tick
    if (RR.Running) {
        nextDelay := 0
        try {
            if (RR.RuleMaxMs > RR.RuleMinMs) {
                nextDelay := Random(RR.RuleMinMs, RR.RuleMaxMs)
            } else {
                nextDelay := RR.RuleMinMs
            }
        } catch {
            nextDelay := RR.RuleMinMs
        }

        try {
            RandomRules_ScheduleNextTick(nextDelay)
        } catch {
        }
    }
}