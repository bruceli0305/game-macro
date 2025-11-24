#Requires AutoHotkey v2

; 技能调试窗口：显示 gCast 当前规则/轨道及技能状态列表

global gCastDebug := IsSet(gCastDebug) ? gCastDebug : Map()

CastDebug_EnsureState() {
    global gCastDebug
    if !IsObject(gCastDebug) {
        gCastDebug := Map()
    }
    if !gCastDebug.Has("Gui") {
        gCastDebug["Gui"] := 0
    }
    if !gCastDebug.Has("LV") {
        gCastDebug["LV"] := 0
    }
    if !gCastDebug.Has("TxtRule") {
        gCastDebug["TxtRule"] := 0
    }
    if !gCastDebug.Has("TxtTrack") {
        gCastDebug["TxtTrack"] := 0
    }
    if !gCastDebug.Has("AutoChk") {
        gCastDebug["AutoChk"] := 0
    }
    if !gCastDebug.Has("TimerOn") {
        gCastDebug["TimerOn"] := false
    }
    if !gCastDebug.Has("HotkeyBound") {
        gCastDebug["HotkeyBound"] := ""
    }
}

CastDebug_Show() {
    global gCastDebug

    CastDebug_EnsureState()

    if (gCastDebug["Gui"]) {
        try {
            gCastDebug["Gui"].Show()
        } catch {
        }
        CastDebug_ApplyConfigFromProfile()
        CastDebug_Refresh()
        return
    }

    g := Gui("+Resize", "技能调试 / 施法条")
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s9", "Segoe UI")

    txtRule := g.Add("Text", "xm w500", "当前规则：-")
    txtTrack := g.Add("Text", "xm w500", "当前轨道：-")

    lv := g.Add("ListView", "xm w700 h260", ["序","技能名","状态","锁定","超时ms","开始Tick","结束Tick","失败Tick"])

    autoChk := g.Add("CheckBox", "xm", "自动刷新")
    btnRef := g.Add("Button", "x+8 w80", "刷新")

    autoChk.OnEvent("Click", CastDebug_OnAutoToggle)
    btnRef.OnEvent("Click", CastDebug_OnManualRefresh)

    gCastDebug["Gui"] := g
    gCastDebug["LV"] := lv
    gCastDebug["TxtRule"] := txtRule
    gCastDebug["TxtTrack"] := txtTrack
    gCastDebug["AutoChk"] := autoChk
    gCastDebug["TimerOn"] := false

    CastDebug_ApplyConfigFromProfile()
    CastDebug_Refresh()

    try {
        g.Show()
    } catch {
    }
}

CastDebug_Hide() {
    global gCastDebug
    CastDebug_EnsureState()
    if (gCastDebug["Gui"]) {
        try {
            gCastDebug["Gui"].Hide()
        } catch {
        }
    }
}

CastDebug_Toggle(*) {
    global gCastDebug
    CastDebug_EnsureState()
    if !(gCastDebug["Gui"]) {
        CastDebug_Show()
        return
    }
    vis := false
    try {
        vis := gCastDebug["Gui"].Visible
    } catch {
        vis := false
    }
    if (vis) {
        CastDebug_Hide()
    } else {
        CastDebug_Show()
    }
}

CastDebug_OnManualRefresh(*) {
    CastDebug_Refresh()
}

CastDebug_OnAutoToggle(*) {
    global gCastDebug
    CastDebug_EnsureState()
    state := 0
    try {
        state := (gCastDebug["AutoChk"].Value ? 1 : 0)
    } catch {
        state := 0
    }
    if (state) {
        if !gCastDebug["TimerOn"] {
            try {
                SetTimer(CastDebug_AutoTick, 500)
            } catch {
            }
            gCastDebug["TimerOn"] := true
        }
    } else {
        if gCastDebug["TimerOn"] {
            try {
                SetTimer(CastDebug_AutoTick, 0)
            } catch {
            }
            gCastDebug["TimerOn"] := false
        }
    }
}

CastDebug_AutoTick() {
    CastDebug_Refresh()
}

CastDebug_Refresh() {
    global gCastDebug, gCast, App

    CastDebug_EnsureState()
    lv := gCastDebug["LV"]
    txtRule := gCastDebug["TxtRule"]
    txtTrack := gCastDebug["TxtTrack"]

    if !(lv) {
        return
    }

    ; 规则/轨道信息
    try {
        if IsObject(txtRule) {
            ruleText := "当前规则：-"
            if IsObject(gCast) && gCast.Active {
                rn := ""
                try {
                    rn := gCast.RuleName
                } catch {
                    rn := ""
                }
                ri := 0
                try {
                    ri := gCast.RuleIndex
                } catch {
                    ri := 0
                }
                ruleText := "当前规则：[" ri "] " rn
            }
            txtRule.Text := ruleText
        }
    } catch {
    }

    try {
        if IsObject(txtTrack) {
            trText := "当前轨道：-"
            if IsObject(gCast) && gCast.Active {
                tid := 0
                tname := ""
                try {
                    tid := gCast.TrackId
                } catch {
                    tid := 0
                }
                try {
                    tname := gCast.TrackName
                } catch {
                    tname := ""
                }
                trText := "当前轨道：[" tid "] " tname
            }
            txtTrack.Text := trText
        }
    } catch {
    }

    ; 列表
    try {
        lv.Opt("-Redraw")
        lv.Delete()
    } catch {
    }

    if !(IsObject(gCast) && gCast.Active) {
        try {
            lv.Opt("+Redraw")
        } catch {
        }
        return
    }

    i := 1
    while (i <= gCast.Skills.Length) {
        e := gCast.Skills[i]
        actIdx := 0
        sname := ""
        st := 0
        lockFlag := 0
        timeout := 0
        stTick := 0
        endTick := 0
        failTick := 0

        try {
            actIdx := e.ActionIndex
        } catch {
            actIdx := 0
        }
        try {
            sname := e.Name
        } catch {
            sname := ""
        }
        try {
            st := e.State
        } catch {
            st := 0
        }
        try {
            lockFlag := e.LockDuringCast
        } catch {
            lockFlag := 0
        }
        try {
            timeout := e.TimeoutMs
        } catch {
            timeout := 0
        }
        try {
            stTick := e.StartedAt
        } catch {
            stTick := 0
        }
        try {
            endTick := e.EndedAt
        } catch {
            endTick := 0
        }
        try {
            failTick := e.FailedAt
        } catch {
            failTick := 0
        }

        stateName := ""
        try {
            stateName := CastEngine_StateName(st)
        } catch {
            stateName := "UNKNOWN"
        }

        lockText := ""
        if (lockFlag) {
            lockText := "√"
        }

        try {
            lv.Add("", actIdx, sname, stateName, lockText, timeout, stTick, endTick, failTick)
        } catch {
        }

        i := i + 1
    }

    i2 := 1
    while (i2 <= 9) {
        try {
            lv.ModifyCol(i2, "AutoHdr")
        } catch {
        }
        i2 := i2 + 1
    }

    try {
        lv.Opt("+Redraw")
    } catch {
    }
}

CastDebug_ApplyConfigFromProfile() {
    global gCastDebug, App

    CastDebug_EnsureState()
    if !(gCastDebug["Gui"]) {
        return
    }
    if !(IsSet(App) && App.Has("ProfileData")) {
        return
    }
    prof := App["ProfileData"]
    if !HasProp(prof, "CastDebug") {
        return
    }
    cd := prof.CastDebug

    topmost := 1
    alpha := 230
    try {
        topmost := (HasProp(cd, "Topmost") && cd.Topmost) ? 1 : 0
    } catch {
        topmost := 1
    }
    try {
        alpha := HasProp(cd, "Alpha") ? Integer(cd.Alpha) : 230
    } catch {
        alpha := 230
    }
    if (alpha < 0) {
        alpha := 0
    }
    if (alpha > 255) {
        alpha := 255
    }

    g := gCastDebug["Gui"]

    try {
        if (topmost) {
            g.Opt("+AlwaysOnTop")
        } else {
            g.Opt("-AlwaysOnTop")
        }
    } catch {
    }

    try {
        WinSetTransparent(alpha, g)
    } catch {
    }
}

CastDebug_RebindHotkey(hk) {
    global gCastDebug

    CastDebug_EnsureState()

    ; 解绑旧的
    old := ""
    try {
        old := gCastDebug["HotkeyBound"]
    } catch {
        old := ""
    }
    if (old != "") {
        try {
            Hotkey old, CastDebug_Toggle, "Off"
        } catch {
        }
    }

    ; 绑定新的
    s := ""
    try {
        s := Trim("" hk)
    } catch {
        s := ""
    }
    if (s = "") {
        gCastDebug["HotkeyBound"] := ""
        return
    }
    ok := false
    try {
        Hotkey s, CastDebug_Toggle, "On"
        ok := true
    } catch {
        ok := false
    }
    if (ok) {
        gCastDebug["HotkeyBound"] := s
    } else {
        gCastDebug["HotkeyBound"] := ""
    }
}