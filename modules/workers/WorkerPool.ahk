; WorkerPool.ahk - 稳定上线版（FF-ONLY）
; 增强：支持 HoldMs（全局默认 DefaultHoldMs + 技能级 HoldMs 覆盖）

; 全局
global WP_LOG_DIR := A_ScriptDir "\Logs"
global WorkerPool := { Mode: "FF_ONLY" }
; —— 施法锁（按线程）：threadId -> lockUntilTick —— 
global WP_Cast := { ByThread: Map() }

WorkerPool_CastReset() {
    global WP_Cast
    WP_Cast.ByThread := Map()
}

WorkerPool_CastIsLocked(threadId) {
    global WP_Cast
    now := A_TickCount
    if WP_Cast.ByThread.Has(threadId) {
        lockUntil := WP_Cast.ByThread[threadId]
        if (now < lockUntil) {
            return { Locked: true, Remain: lockUntil - now, lockUntil: lockUntil }
        }
    }
    return { Locked: false, Remain: 0, lockUntil: 0 }
}

WorkerPool_CastLock(threadId, durMs) {
    global WP_Cast
    if (durMs <= 0)
        return
    lockUntil := A_TickCount + durMs
    WP_Cast.ByThread[threadId] := lockUntil
    WP_Log(Format("CastLock set: thr={1} dur={2} until={3}", threadId, durMs, lockUntil))
}

; 简单日志
WP_Log(msg) {
    DirCreate(WP_LOG_DIR)
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    try FileAppend(ts " [WorkerPool] " msg "`r`n", WP_LOG_DIR "\workerpool.log", "UTF-8")
}

;================ 生命周期（FF-ONLY: 不启动任何常驻线程） ================
WorkerPool_Rebuild() {
    global App, WorkerPool
    WorkerPool.Mode := "FF_ONLY"
    WorkerPool_CastReset()                                ; 新增：重置施法锁
    WP_Log("Rebuild (FF-only): skip spawning workers; threads=" (HasProp(App["ProfileData"], "Threads") ? App[
        "ProfileData"].Threads.Length : 0))
}

WorkerPool_Dispose() {
    WorkerPool_CastReset()                                ; 新增：释放锁
    WP_Log("Dispose (FF-only): nothing to close")
}

;================ 启动外部进程（Kernel32.CreateProcessW） ================
WorkerPool_CreateProcess(cmdLine) {
    si := Buffer(A_PtrSize = 8 ? 104 : 68, 0)
    NumPut("UInt", si.Size, si, 0)
    pi := Buffer(A_PtrSize * 2 + 8, 0)

    bytes := (StrLen(cmdLine) + 1) * 2
    cl := Buffer(bytes, 0)
    StrPut(cmdLine, cl, "UTF-16")

    ok := DllCall("Kernel32.dll\CreateProcessW"
        , "Ptr", 0
        , "Ptr", cl.Ptr
        , "Ptr", 0, "Ptr", 0
        , "Int", 0
        , "UInt", 0x08000000      ; CREATE_NO_WINDOW
        , "Ptr", 0, "Ptr", 0
        , "Ptr", si.Ptr, "Ptr", pi.Ptr
        , "Int")
    if (!ok)
        return 0

    hProcess := NumGet(pi, 0, "Ptr")
    hThread := NumGet(pi, A_PtrSize, "Ptr")
    pid := NumGet(pi, A_PtrSize * 2, "UInt")
    return { pid: pid, hProcess: hProcess, hThread: hThread }
}

; ============== 宿主定位（优先 EXE，再 AHK） ==============
; 查找 WorkerHost 宿主，返回 { Path, Kind:"exe"/"ahk" } 或 0
WorkerPool_FindHost() {
    global App
    ; 1) App 配置覆写（可选）
    try {
        if IsObject(App) && App.Has("WorkerHostPath") {
            p := App["WorkerHostPath"]
            if (p != "" && FileExist(p)) {
                ext := StrLower(RegExReplace(p, ".*\.", ""))
                return { Path: p, Kind: (ext="exe" ? "exe" : "ahk") }
            }
        }
    }

    ; 2) 环境变量覆写（WORKERHOST_PATH）
    try {
        p := EnvGet("WORKERHOST_PATH")
        if (p != "" && FileExist(p)) {
            ext := StrLower(RegExReplace(p, ".*\.", ""))
            return { Path: p, Kind: (ext="exe" ? "exe" : "ahk") }
        }
    }

    ; 3) 常规候选路径（相对主程序目录）
    candidates := [
        A_ScriptDir "\modules\workers\WorkerHost.exe"
      , A_ScriptDir "\modules\WorkerHost.exe"
      , A_ScriptDir "\WorkerHost.exe"
      , A_ScriptDir "\modules\workers\WorkerHost.ahk"
      , A_ScriptDir "\modules\WorkerHost.ahk"
      , A_ScriptDir "\WorkerHost.ahk"
    ]
    for _, p in candidates {
        if FileExist(p) {
            ext := StrLower(RegExReplace(p, ".*\.", ""))
            return { Path: p, Kind: (ext="exe" ? "exe" : "ahk") }
        }
    }
    return 0
}

; ============== 一次性发送（FF-only）：自动选择宿主 ==============
WorkerPool_FireAndForget(key, delay := 0, hold := 0) {
    host := WorkerPool_FindHost()
    if !host {
        WP_Log("Start one-shot FAIL: WorkerHost not found in candidates")
        return false
    }

    ; 组装命令行（优先 EXE）
    qkey := '"' . StrReplace(key, '"', '""') . '"'
    if (host.Kind = "exe") {
        cmd := '"' host.Path '" --fire ' . qkey . ' ' . delay . ' ' . hold
    } else {
        ; .ahk：依赖解释器
        ip := A_AhkPath
        if (ip = "" || !FileExist(ip)) {
            WP_Log("Start one-shot FAIL: A_AhkPath invalid for .ahk host. Please deploy WorkerHost.exe")
            return false
        }
        cmd := '"' ip '" "' host.Path '" --fire ' . qkey . ' ' . delay . ' ' . hold
    }

    WP_Log("Start one-shot: " cmd)

    pr := WorkerPool_CreateProcess(cmd)
    if !pr {
        WP_Log("Start one-shot FAIL: CreateProcessW error")
        return false
    }
    try DllCall("Kernel32.dll\CloseHandle", "Ptr", pr.hThread)
    try DllCall("Kernel32.dll\CloseHandle", "Ptr", pr.hProcess)
    return true
}

;================ 入口：按技能索引发送（规则/BUFF均用） ================
; src 可传 "Rule:xxx" 或 "Buff:yyy" 用于日志追踪
WorkerPool_SendSkillIndex(threadId, idx, src := "") {
    global App
    if (idx < 1 || idx > App["ProfileData"].Skills.Length)
        return false
    s := App["ProfileData"].Skills[idx]
    ; 新增：施法锁检查（按线程）
    lk := WorkerPool_CastIsLocked(threadId)
    if (lk.Locked) {
        WP_Log(Format("CastLock BLOCK: thr={1} idx={2} key={3} remain={4}ms src={5}"
            , threadId, idx, s.Key, lk.Remain, (src!="" ? src : "?")))
        return false
    }
    ; 全局每次发送延迟（统一在 WorkerHost 内 Sleep）
    delay := 0
    try {
        if IsObject(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "SendCooldownMs")
            delay := Max(0, Integer(App["ProfileData"].SendCooldownMs))
    } catch {
        delay := 0
    }

    ; 按住时长（全局默认 DefaultHoldMs + 技能级 HoldMs 覆盖）
    hold := 0
    try {
        if HasProp(App["ProfileData"], "DefaultHoldMs")
            hold := Max(0, Integer(App["ProfileData"].DefaultHoldMs))
        if HasProp(s, "HoldMs")
            hold := Max(0, Integer(s.HoldMs))
    } catch {
        hold := 0
    }

    WP_Log(Format("Send FF-only: thr={1} idx={2} key={3} delay={4} hold={5} src={6}"
        , threadId, idx, s.Key, delay, hold, (src != "" ? src : "?")))

    ok := WorkerPool_FireAndForget(s.Key, delay, hold)

    if (ok) {
        try Rotation_OnSkillSent(idx)         ; 新增：记录最近发送 tick（黑框时间窗使用）
        newCnt := Counters_Inc(idx)
        WP_Log("Counter inc: idx=" idx " key=" s.Key " count=" newCnt)
        ; 新增：若配置了读条时间（CastMs），对该线程加锁
        castMs := 0
        try castMs := Max(0, Integer(HasProp(s, "CastMs") ? s.CastMs : 0))
        if (castMs > 0) {
            WorkerPool_CastLock(threadId, castMs)
        }
    } else {
        WP_Log("Send FAIL -> no lock, no counter")
    }

    try {
        BuffEngine_NotifySkillUsed(idx)
    } catch {
        WP_Log("NotifySkillUsed FAIL: " A_LastError)
    }

    WP_Log("FF-only ret=" ok)
    return ok
}

;================ 可选：自测（记事本里更直观） ================
WorkerPool_TestFF() {
    MsgBox("3秒后向前台窗口发送 'a'，请切到记事本")
    Sleep 3000
    ok := WorkerPool_FireAndForget("a", 100, 0)
    MsgBox("FireAndForget: " (ok ? "OK" : "FAIL"))
}
