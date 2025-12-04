; Rotation_Config.ahk - 配置读入/轨道辅助（纯 Tracks[] 版本）
;modules\engines\rotation\Rotation_Config.ahk
Rotation_ReadCfg(prof) {
    cfg := HasProp(prof, "Rotation") ? prof.Rotation : {}
    if !HasProp(cfg, "Enabled"){
        cfg.Enabled := 0
    }
    if !HasProp(cfg, "DefaultTrackId"){
        cfg.DefaultTrackId := 1
    }
    if !HasProp(cfg, "BusyWindowMs"){
        cfg.BusyWindowMs := 200
    }
    if !HasProp(cfg, "ColorTolBlack"){
        cfg.ColorTolBlack := 16
    }
    if !HasProp(cfg, "RespectCastLock"){
        cfg.RespectCastLock := 1
    }
    if !HasProp(cfg, "Opener"){
        cfg.Opener := { Enabled: 0, MaxDurationMs: 4000, Watch: [], StepsCount: 0, Steps: [] }
    }
    if !HasProp(cfg, "GatesEnabled"){
        cfg.GatesEnabled := 0
    }
    if !HasProp(cfg, "Gates"){
        cfg.Gates := []
    }
    if !HasProp(cfg, "GateCooldownMs"){
        cfg.GateCooldownMs := 0
    }
    if !HasProp(cfg, "Tracks"){ 
        cfg.Tracks := []   ; 仅保留 Tracks[]
    }
    if !HasProp(cfg, "BlackGuard"){
        cfg.BlackGuard := {
            Enabled: 1, SampleCount: 5, BlackRatioThresh: 0.7
          , WindowMs: 120, CooldownMs: 600
          , MinAfterSendMs: 60, MaxAfterSendMs: 800
          , UniqueRequired: 1
        }
    }
    return cfg
}

Rotation_UseTracks() {
    global gRot
    try {
        return HasProp(gRot["Cfg"], "Tracks")
            && IsObject(gRot["Cfg"].Tracks)
            && gRot["Cfg"].Tracks.Length > 0
    } catch {
        return false
    }
}

Rotation_GetTrackById(id) {
    global gRot
    if (id <= 0)
        return 0
    try {
        for _, t in gRot["Cfg"].Tracks {
            if (HasProp(t, "Id") && t.Id = id)
                return t
        }
    }
    return 0
}

Rotation_GetDefaultTrackId() {
    global gRot
    try {
        id := HasProp(gRot["Cfg"], "DefaultTrackId") ? Integer(gRot["Cfg"].DefaultTrackId) : 0
        if (id > 0 && Rotation_GetTrackById(id))
            return id
        ; fallback：用第一条 Tracks 的 Id（若存在）
        if (Rotation_UseTracks())
            return gRot["Cfg"].Tracks[1].Id
    } catch {
    }
    return 0
}

Rotation_GetNextTrackId(curId) {
    global gRot
    if (!Rotation_UseTracks())
        return 0
    arr := gRot["Cfg"].Tracks
    ; 优先 NextTrackId（若合理）
    cur := Rotation_GetTrackById(curId)
    if (cur && HasProp(cur, "NextTrackId") && cur.NextTrackId > 0 && Rotation_GetTrackById(cur.NextTrackId))
        return cur.NextTrackId
    ; 否则按数组自然顺序
    pos := 0
    for i, t in arr {
        if (HasProp(t,"Id") && t.Id = curId) {
            pos := i
            break
        }
    }
    if (pos = 0) {
        ; curId 不在数组中，返回第一条
        return arr[1].Id
    }
    nxt := (pos >= arr.Length) ? 1 : (pos + 1)
    return arr[nxt].Id
}

Rotation_CurrentTrackCfg() {
    global gRot
    return Rotation_GetTrackById(gRot["RT"].TrackId)
}