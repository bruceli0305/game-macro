#Requires AutoHotkey v2
#Include "..\..\RE_UI_Common.ahk"

REUI_Opener_Ensure(cfg) {
    if !IsObject(cfg) {
        return
    }
    if !HasProp(cfg,"Opener") {
        cfg.Opener := {}
    }
    op := cfg.Opener
    if !HasProp(op,"Enabled") {
        op.Enabled := 0
    }
    if !HasProp(op,"MaxDurationMs") {
        op.MaxDurationMs := 4000
    }
    if !HasProp(op,"ThreadId") {
        op.ThreadId := 1
    }
    if !HasProp(op,"StepsCount") {
        op.StepsCount := 0
    }
    if !HasProp(op,"Watch") || !IsObject(op.Watch) {
        op.Watch := []
    }
    if !HasProp(op,"Steps") || !IsObject(op.Steps) {
        op.Steps := []
    }
    cfg.Opener := op
}