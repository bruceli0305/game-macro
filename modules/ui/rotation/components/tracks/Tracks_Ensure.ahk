#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_Tracks_Ensure(cfg) {
    if !IsObject(cfg) {
        return
    }
    if !HasProp(cfg, "Tracks") {
        cfg.Tracks := []
    } else {
        if !IsObject(cfg.Tracks) {
            cfg.Tracks := []
        }
    }
    if (cfg.Tracks.Length = 0) {
        if HasProp(cfg, "Track1") {
            cfg.Tracks.Push(cfg.Track1)
        }
        if HasProp(cfg, "Track2") {
            cfg.Tracks.Push(cfg.Track2)
        }
    }
    if (cfg.Tracks.Length = 0) {
        def := { Id: 0, Name: "轨道1", ThreadId: 1, MaxDurationMs: 8000, MinStayMs: 0, NextTrackId: 0, Watch: [],
            RuleRefs: [] }
        cfg.Tracks.Push(def)
    }
}
