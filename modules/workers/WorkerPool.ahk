; WorkerPool.ahk - 稳定上线版（FF-ONLY）
; 增强：支持 HoldMs（全局默认 DefaultHoldMs + 技能级 HoldMs 覆盖 + 可选一次性覆盖 holdOverride）
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
}

;================ 生命周期（FF-ONLY: 不启动任何常驻线程） ================
WorkerPool_Rebuild() {
    global App, WorkerPool
    WorkerPool.Mode := "FF_ONLY"
    try {
        f := Map()
        f["mode"] := WorkerPool.Mode
        f["threads"] := (HasProp(App["ProfileData"], "Threads") ? App["ProfileData"].Threads.Length : 0)
        Logger_Info("WorkerPool", "Rebuild", f)
    } catch {
    }
    WorkerPool_CastReset()
}

WorkerPool_Dispose() {
    WorkerPool_CastReset()
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
WorkerPool_FindHost() {
    global App
    try {
        if IsObject(App) && App.Has("WorkerHostPath") {
            p := App["WorkerHostPath"]
            if (p != "" && FileExist(p)) {
                ext := StrLower(RegExReplace(p, ".*\.", ""))
                return { Path: p, Kind: (ext="exe" ? "exe" : "ahk") }
            }
        }
    }
    try {
        p := EnvGet("WORKERHOST_PATH")
        if (p != "" && FileExist(p)) {
            ext := StrLower(RegExReplace(p, ".*\.", ""))
            return { Path: p, Kind: (ext="exe" ? "exe" : "ahk") }
        }
    }
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

; ============== 一次性发送（FF-only） ==============
WorkerPool_FireAndForget(key, delay := 0, hold := 0) {
    host := WorkerPool_FindHost()
    if !host {
        return false
    }
    qkey := '"' . StrReplace(key, '"', '""') . '"'
    if (host.Kind = "exe") {
        cmd := '"' host.Path '" --fire ' . qkey . ' ' . delay . ' ' . hold
    } else {
        ip := A_AhkPath
        if (ip = "" || !FileExist(ip)) {
            return false
        }
        cmd := '"' ip '" "' host.Path '" --fire ' . qkey . ' ' . delay . ' ' . hold
    }
    try {
        f := Map()
        f["key"] := key
        f["delay"] := delay
        f["hold"] := hold
        Logger_Info("WorkerPool", "Start one-shot", f)
    } catch {
    }
    pr := WorkerPool_CreateProcess(cmd)
    if !pr {
        return false
    }
    try DllCall("Kernel32.dll\CloseHandle", "Ptr", pr.hThread)
    try DllCall("Kernel32.dll\CloseHandle", "Ptr", pr.hProcess)
    return true
}

;================ 入口：按技能索引发送（规则/BUFF均用） ================
; src 可传 "Rule:xxx" 或 "Buff:yyy" 用于日志追踪
; holdOverride: >=0 时强制使用该 hold 时长（ms）；默认 -1 表示不覆盖
WorkerPool_SendSkillIndex(threadId, idx, src := "", holdOverride := -1) {
    global App
    if (idx < 1 || idx > App["ProfileData"].Skills.Length)
        return false
    s := App["ProfileData"].Skills[idx]

    lk := WorkerPool_CastIsLocked(threadId)
    if (lk.Locked) {
        return false
    }

    delay := 0
    try {
        if IsObject(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "SendCooldownMs")
            delay := Max(0, Integer(App["ProfileData"].SendCooldownMs))
    } catch {
        delay := 0
    }

    finalHold := 0
    try {
        if (holdOverride >= 0) {
            finalHold := Max(0, Integer(holdOverride))
        } else {
            if HasProp(App["ProfileData"], "DefaultHoldMs")
                finalHold := Max(0, Integer(App["ProfileData"].DefaultHoldMs))
            if HasProp(s, "HoldMs")
                finalHold := Max(0, Integer(s.HoldMs))
        }
    } catch {
        finalHold := 0
    }
    ok := WorkerPool_FireAndForget(s.Key, delay, finalHold)

    if (ok) {
        try Rotation_OnSkillSent(idx)
        newCnt := Counters_Inc(idx)
        castMs := 0
        try castMs := Max(0, Integer(HasProp(s, "CastMs") ? s.CastMs : 0))
        if (castMs > 0) {
            WorkerPool_CastLock(threadId, castMs)
        }
        try {
            f := Map()
            f["idx"] := idx
            f["key"] := s.Key
            f["threadId"] := threadId
            f["src"] := (src != "" ? src : "?")
            f["hold"] := finalHold
            Logger_Info("WorkerPool", "Skill sent", f)
        } catch {
        }
    } else {
        Logger_Warn("WorkerPool", "Skill send FAIL", Map("idx", idx, "threadId", threadId, "src", (src!=""?src:"?")))
    }

    try {
        BuffEngine_NotifySkillUsed(idx)
    }
    return ok
}

;================ 自测 ================
WorkerPool_TestFF() {
    MsgBox("3秒后向前台窗口发送 'a'，请切到记事本")
    Sleep 3000
    ok := WorkerPool_FireAndForget("a", 100, 0)
    MsgBox("FireAndForget: " (ok ? "OK" : "FAIL"))
}