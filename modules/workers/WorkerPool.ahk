; WorkerPool.ahk - 稳定上线版（FF-ONLY）
; 增强：支持 HoldMs（全局默认 DefaultHoldMs + 技能级 HoldMs 覆盖）

; 全局
global WP_LOG_DIR := A_ScriptDir "\Logs"
global WorkerPool := { Mode: "FF_ONLY" }

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
    WP_Log("Rebuild (FF-only): skip spawning workers; threads=" (HasProp(App["ProfileData"], "Threads") ? App[
        "ProfileData"].Threads.Length : 0))
}

WorkerPool_Dispose() {
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

;================ 一次性发送（FF-ONLY 通道） ================
; 直接启动 WorkerHost.ahk 的 --fire 模式；key 用双引号包裹并转义内部引号
WorkerPool_FireAndForget(key, delay := 0, hold := 0) {
    host := A_ScriptDir "\modules\WorkerHost.ahk"
    if !FileExist(host) {
        WP_Log("Start one-shot FAIL: WorkerHost not found: " host)
        return false
    }
    qkey := '"' . StrReplace(key, '"', '""') . '"'
    cmd := '"' . A_AhkPath . '" "' . host . '" --fire ' . qkey . ' ' . delay . ' ' . hold
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

    ; 发送延迟（全局）
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
        newCnt := Counters_Inc(idx)
        WP_Log("Counter inc: idx=" idx " key=" s.Key " count=" newCnt)
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
