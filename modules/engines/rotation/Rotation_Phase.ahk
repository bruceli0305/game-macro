; Rotation_Phase.ahk - 初始化/阶段进入/PhaseState 构建
;modules\engines\rotation\Rotation_Phase.ahk
Rotation_InitFromProfile() {
    global App, gRot, gRotInitBusy, gRotInitialized
    if (gRotInitBusy)
        return
    gRotInitBusy := true
    try {
        if (gRotInitialized) {
            return
        }
        cfg := Rotation_ReadCfg(App["ProfileData"])

        ; 有 Watch 自动启用（仅当前运行）
        try {
            hasWatch := 0
            try hasWatch += (HasProp(cfg,"Opener") && HasProp(cfg.Opener,"Watch")) ? cfg.Opener.Watch.Length : 0
            try {
                if (HasProp(cfg, "Tracks") && IsObject(cfg.Tracks)) {
                    for _, __t in cfg.Tracks {
                        try hasWatch += (HasProp(__t,"Watch") ? __t.Watch.Length : 0)
                    }
                }
            }
            if (!cfg.Enabled && hasWatch > 0) {
                cfg.Enabled := 1
            }
        }
        gRot["Cfg"] := cfg
        gRot["RT"]  := Rotation_NewRT(cfg)

        if (!cfg.Enabled) {
            return
        }
        if (cfg.Opener.Enabled && !gRot["RT"].OpenerDone) {
            Rotation_EnterOpener()
        } else {
            Rotation_EnterTrack(Rotation_GetDefaultTrackId())
        }
        gRotInitialized := true
        try {
            f := Map()
            f["enabled"] := (cfg.Enabled ? 1 : 0)
            f["trackCount"] := (HasProp(cfg,"Tracks") && IsObject(cfg.Tracks)) ? cfg.Tracks.Length : 0
            Logger_Info("Rotation", "Init", f)
        } catch {
        }
    } catch as e {
    } finally {
        gRotInitBusy := false
    }
}

Rotation_EnterOpener() {
    global gRot
    gRot["RT"].Phase := "Opener"
    gRot["RT"].TrackId := 0
    gRot["RT"].PhaseState := Rotation_BuildPhaseState_Opener()
    try {
        Logger_Info("Rotation", "Enter opener", Map())
    } catch {
    }
}
Rotation_EnterTrack(trackId) {
    global gRot
    gRot["RT"].Phase := "Track"
    gRot["RT"].TrackId := trackId
    gRot["RT"].PhaseState := Rotation_BuildPhaseState_Track(trackId)
    try {
        Logger_Info("Rotation", "Enter track", Map("trackId", trackId))
    } catch {
    }
}

Rotation_BuildPhaseState_Opener() {
    global App, gRot
    now := A_TickCount
    st := { StartedAt: now, Baseline: Map(), Items: [] }
    for _, w in gRot["Cfg"].Opener.Watch {
        si := w.SkillIndex, need := Max(1, (HasProp(w,"RequireCount") ? w.RequireCount : 1))
        verify := (HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0)
        st.Baseline[si] := Counters_Get(si)
        st.Items.Push({ SkillIndex: si, Require: need, VerifyBlack: verify ? 1 : 0, BlackSeen: false })
    }
    return st
}
Rotation_BuildPhaseState_Track(trackId) {
    global gRot
    now := A_TickCount
    tr := Rotation_GetTrackById(trackId)
    st := { StartedAt: now, Baseline: Map(), Items: [] }
    if (tr && HasProp(tr, "Watch") && IsObject(tr.Watch)) {
        for _, w in tr.Watch {
            si := w.SkillIndex, need := Max(1, (HasProp(w,"RequireCount") ? w.RequireCount : 1))
            verify := (HasProp(w,"VerifyBlack") ? w.VerifyBlack : 0)
            st.Baseline[si] := Counters_Get(si)
            st.Items.Push({ SkillIndex: si, Require: need, VerifyBlack: verify ? 1 : 0, BlackSeen: false })
        }
    }
    return st
}