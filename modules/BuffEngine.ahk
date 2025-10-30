; BuffEngine.ahk - 续BUFF优先释放引擎（修复 s 未定义；使用帧缓存提取像素）

; BuffEngine_RunTick - BUFF 续时优先执行（支持每组 ThreadId）
; 返回 true 表示本 Tick 已因续BUFF而发了技能
BuffEngine_RunTick() {
    global App
    prof := App["ProfileData"]
    if !HasProp(prof, "Buffs") || (prof.Buffs.Length = 0)
        return false

    now := A_TickCount

    for _, b in prof.Buffs {
        ; 基本校验
        if !b.Enabled
            continue
        if !HasProp(b, "Skills") || (b.Skills.Length = 0)
            continue
        duration := HasProp(b, "DurationMs") ? b.DurationMs : 0
        refresh  := HasProp(b, "RefreshBeforeMs") ? b.RefreshBeforeMs : 0
        if (duration <= 0)
            continue

        ; 需要续：从未建立过(last=0) 或 剩余时间 <= refresh
        last := HasProp(b, "LastTime") ? b.LastTime : 0
        elapsed := (last = 0) ? duration : (now - last)
        needRefresh := (last = 0) || (duration - elapsed <= refresh)
        if !needRefresh
            continue

        ; 本组线程与就绪检测
        thrId := HasProp(b, "ThreadId") ? b.ThreadId : 1
        requireReady := HasProp(b, "CheckReady") ? b.CheckReady : 1

        ; 轮转起点
        if !HasProp(b, "NextIdx") || b.NextIdx < 1 || b.NextIdx > b.Skills.Length
            b.NextIdx := 1

        total := b.Skills.Length
        tryCount := 0
        while (tryCount < total) {
            slot := b.NextIdx
            ; 先推进指针，避免 continue 时卡在同一个位置
            b.NextIdx := (slot >= total) ? 1 : (slot + 1)
            tryCount++

            idx := b.Skills[slot]
            ; 索引越界保护（技能被删除后的残留引用）
            if (idx < 1 || idx > prof.Skills.Length)
                continue

            s := prof.Skills[idx]

            ; 可选：像素就绪检测（使用帧缓存）
            if (requireReady = 1) {
                cur := Pixel_FrameGet(s.X, s.Y)
                tgt := Pixel_HexToInt(s.Color)
                if !Pixel_ColorMatch(cur, tgt, s.Tol)
                    continue
            }

            ; 在指定“线程”（工作进程）发键
            if WorkerPool_SendSkillIndex(thrId, idx, "Buff:" s.Name) {
                b.LastTime := A_TickCount   ; 本组计时重置
                return true
            }
            ; 若该技能发送失败，换下一个
        }
        ; 本组没有任何可用技能，本 Tick 放过
    }
    return false
}

; 发送技能（按索引）；requireReady=1 时会先检测像素就绪
BuffEngine_SendSkillByIndex(idx, updateBuff := true, requireReady := false) {
    global App
    if (idx < 1 || idx > App["ProfileData"].Skills.Length)
        return false

    s := App["ProfileData"].Skills[idx]
    thr := HasProp(s, "ThreadId") ? s.ThreadId : 1
    if requireReady {
        cur := Pixel_FrameGet(s.X, s.Y)
        tgt := Pixel_HexToInt(s.Color)
        if !Pixel_ColorMatch(cur, tgt, s.Tol)
            return false
    }

    ; 统一通道：这里仍走 Poller_SendKey（保持原行为）
    Poller_SendKey(s.Key)

    if updateBuff
        BuffEngine_NotifySkillUsed(idx)
    return true
}

; 当某个技能被释放（无论来源）时，通知 BUFF 引擎重置相关 BUFF 计时
BuffEngine_NotifySkillUsed(idx) {
    global App
    now := A_TickCount
    if !HasProp(App["ProfileData"], "Buffs")
        return
    for _, b in App["ProfileData"].Buffs {
        if !HasProp(b, "Skills")
            continue
        for _, si in b.Skills {
            if (si = idx) {
                b.LastTime := now
                ; 轻微推进轮转指针，避免固定一个技能
                if !HasProp(b, "NextIdx")
                    b.NextIdx := 1
                b.NextIdx := (b.NextIdx >= b.Skills.Length) ? 1 : (b.NextIdx + 1)
                break
            }
        }
    }
}

BuffEngine_SendSkillByIndex_Threaded(threadId, idx, requireReady := false) {
    global App
    if (idx < 1 || idx > App["ProfileData"].Skills.Length)
        return false
    s := App["ProfileData"].Skills[idx]
    if requireReady {
        cur := Pixel_FrameGet(s.X, s.Y)
        tgt := Pixel_HexToInt(s.Color)
        if !Pixel_ColorMatch(cur, tgt, s.Tol)
            return false
    }
    return WorkerPool_SendSkillIndex(threadId, idx, "Buff:" s.Name)
}