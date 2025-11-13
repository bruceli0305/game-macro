; ============================== modules\ui\UI_Framework.ahk ==============================
#Requires AutoHotkey v2
; 页面管理框架：注册、切换、布局（兼容 Build()/Build(page) 与 Layout()/Layout(rc)）
; 严格使用块结构 if/try/catch，不使用单行形式

; ====== 日志 ======
UI_Trace(msg) {
    ts := ""
    try {
        ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    } catch {
        ts := ""
    }
    try {
        DirCreate(A_ScriptDir "\Logs")
    } catch {
    }
    try {
        FileAppend(ts " [" A_TickCount "] " msg "`r`n"
            , A_ScriptDir "\Logs\ui_trace.log", "UTF-8")
    } catch {
    }
}

; ====== 通用调用器：检测 0/1 参并安全调用 ======
UI_Call0Or1(fn, arg) {
    ; 返回 true 表示成功调用
    ok := false
    if (!IsObject(fn)) {
        return false
    }
    pmin := -1
    try {
        pmin := fn.MinParams
    } catch {
        pmin := -1
    }
    if (pmin = 0) {
        try {
            fn.Call()
            ok := true
        } catch as e0 {
            UI_Trace("UI_Call0Or1: Call() exception: " e0.Message)
        }
        return ok
    }
    if (pmin >= 1) {
        try {
            fn.Call(arg)
            ok := true
        } catch as e1 {
            UI_Trace("UI_Call0Or1: Call(arg) exception: " e1.Message)
        }
        return ok
    }
    ; 未能读取到 MinParams 时，尝试先传参，再不传参
    try {
        fn.Call(arg)
        ok := true
    } catch as e2 {
        UI_Trace("UI_Call0Or1: Call(arg) failed: " e2.Message)
        try {
            fn.Call()
            ok := true
        } catch as e3 {
            UI_Trace("UI_Call0Or1: Call() failed: " e3.Message)
        }
    }
    return ok
}

global UI := IsSet(UI) ? UI : Map()
global UI_Pages := Map()          ; key -> { Title, Controls:[], Build, Layout, Inited, OnEnter?, OnLeave? }
global UI_CurrentPage := ""
global UI_NavMap := Map()         ; navNodeId -> pageKey

UI_RegisterPage(key, title, buildFn, layoutFn := 0, onEnter := 0, onLeave := 0) {
    global UI_Pages
    page := { Title: title
            , Controls: []
            , Build: buildFn
            , Layout: layoutFn
            , Inited: false
            , OnEnter: onEnter
            , OnLeave: onLeave }
    UI_Pages[key] := page
    UI_Trace("RegisterPage key=" key " title=" title)
}

UI_SwitchPage(key) {
    global UI_Pages, UI_CurrentPage

    UI_Trace("SwitchPage from=" UI_CurrentPage " to=" key)

    if (UI_CurrentPage = key) {
        if (UI_Pages.Has(key)) {
            _pg := UI_Pages[key]
            needRebuild := false
            try {
                needRebuild := (!_pg.Inited) || (!IsObject(_pg.Controls)) || (_pg.Controls.Length = 0)
            } catch {
                needRebuild := true
            }
            if (!needRebuild) {
                UI_Trace("SwitchPage short-circuit: already on " key)
                return
            }
            ; 否则继续往下执行，走正常重建流程
        } else {
            return
        }
    }

    ; 先正常触发旧页 OnLeave
    if (UI_CurrentPage != "" && UI_Pages.Has(UI_CurrentPage)) {
        old := UI_Pages[UI_CurrentPage]
        if (old.OnLeave) {
            try {
                UI_Trace("Calling OnLeave for " UI_CurrentPage)
                old.OnLeave()
            } catch as e {
                UI_Trace("OnLeave exception for " UI_CurrentPage ": " e.Message)
            }
        }
    }

    ; 核心修复：切换前先隐藏所有页面控件，杜绝残留
    UI_HideAllPageControls()

    if (!UI_Pages.Has(key)) {
        UI_Trace("SwitchPage target not found: " key)
        return
    }

    UI_CurrentPage := key
    pg := UI_Pages[key]

    if (!pg.Inited) {
        built := false
        try {
            UI_Trace("Page Build smart-call begin key=" key)
            called := UI_Call0Or1(pg.Build, pg)
            if (called) {
                built := true
                UI_Trace("Page Build smart-call success key=" key)
            } else {
                UI_Trace("Page Build smart-call failed key=" key)
                built := false
            }
        } catch as eB {
            UI_Trace("Page Build smart-call exception key=" key " err=" eB.Message)
            built := false
        }
        pg.Inited := built
        if (!built) {
            UI_Trace("Page init failed, abort switch key=" key)
            return
        }
    }

    shown := 0
    for ctl in pg.Controls {
        try {
            ctl.Visible := true
            shown += 1
        } catch {
        }
    }
    UI_Trace("Show controls: " shown " for page " key)

    if (pg.Layout) {
        try {
            rc := UI_GetPageRect()
        } catch as eRC {
            UI_Trace("GetPageRect exception: " eRC.Message)
            rc := { X: 244, Y: 10, W: 804, H: 760 }
        }
        try {
            ok := UI_Call0Or1(pg.Layout, rc)
            if (!ok) {
                UI_Trace("Layout smart-call failed for page " key)
            } else {
                UI_Trace("Layout smart-call success for page " key)
            }
        } catch as eL {
            UI_Trace("Layout smart-call exception for page " key " err=" eL.Message)
        }
    }

    if (pg.OnEnter) {
        try {
            UI_Trace("Calling OnEnter for " key)
            pg.OnEnter()
        } catch as eE {
            UI_Trace("OnEnter exception for " key " err=" eE.Message)
        }
    }
}

; ========= 右侧面板区域（动态读取左侧 Nav 宽度） =========
UI_GetPageRect() {
    global UI

    mX := 12
    mY := 10
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            mX := UI.Main.MarginX
            mY := UI.Main.MarginY
        }
    } catch {
        mX := 12
        mY := 10
    }

    navW := 220
    gap  := 12
    try {
        if (IsSet(UI) && UI.Has("Nav") && UI.Nav) {
            nx := 0, ny := 0, nw := 0, nh := 0
            UI.Nav.GetPos(&nx, &ny, &nw, &nh)  ; DIP
            if (nw > 0) {
                navW := nw
            }
        }
    } catch {
        navW := 220
    }

    cw := 0
    ch := 0
    try {
        rc := Buffer(16, 0)
        DllCall("user32\GetClientRect", "ptr", UI.Main.Hwnd, "ptr", rc.Ptr)
        cw_px := NumGet(rc, 8,  "Int")
        ch_px := NumGet(rc, 12, "Int")
        ; 把 px 转为 DIP（控件 Move/尺寸使用的是 DIP）
        scale := 1.0
        try scale := UI_GetScale(UI.Main.Hwnd)
        cw := Round(cw_px / scale)
        ch := Round(ch_px / scale)
    } catch {
        cw := A_ScreenWidth
        ch := A_ScreenHeight
    }

    x := mX + navW + gap
    y := mY
    w := cw - x - mX
    h := ch - mY * 2
    if (w < 320) {
        w := 320
    }
    if (h < 240) {
        h := 240
    }
    rcOut := { X: x, Y: y, W: w, H: h, NavW: navW, ClientW: cw, ClientH: ch }
    UI_Trace(Format("GetPageRect x={1} y={2} w={3} h={4} navW={5} clientDIP={6}x{7}", rcOut.X, rcOut.Y, rcOut.W, rcOut.H, navW, cw, ch))
    return rcOut
}

UI_LayoutCurrentPage() {
    global UI_Pages, UI_CurrentPage
    if (UI_CurrentPage = "" || !UI_Pages.Has(UI_CurrentPage)) {
        return
    }
    pg := UI_Pages[UI_CurrentPage]
    if (!pg.Layout) {
        return
    }
    rc := 0
    try {
        rc := UI_GetPageRect()
    } catch as e {
        UI_Trace("GetPageRect exception in LayoutCurrentPage: " e.Message)
        rc := { X: 244, Y: 10, W: 804, H: 760 }
    }
    try {
        ok := UI_Call0Or1(pg.Layout, rc)
        if (!ok) {
            UI_Trace("LayoutCurrentPage smart-call failed for " UI_CurrentPage)
        }
    } catch as e2 {
        UI_Trace("LayoutCurrentPage exception for " UI_CurrentPage " err=" e2.Message)
    }
}

UI_EnablePerMonitorDPI() {
    try {
        DllCall("user32\SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
        UI_Trace("DPI Awareness: PMv2 via SetProcessDpiAwarenessContext")
    } catch {
        try {
            DllCall("shcore\SetProcessDpiAwareness", "int", 2, "int")
            UI_Trace("DPI Awareness: PM via shcore")
        } catch {
            try {
                DllCall("user32\SetProcessDPIAware")
                UI_Trace("DPI Awareness: system DPI aware")
            } catch {
                UI_Trace("DPI Awareness: failed to set")
            }
        }
    }
}

UI_RebuildMain(*) {
    global UI
    UI_Trace("UI_RebuildMain begin")
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Destroy()
        }
    } catch as e {
        UI_Trace("UI_RebuildMain destroy exception: " e.Message)
    }
    UI_ShowMain()
    UI_Trace("UI_RebuildMain done")
}
; 动态本地化当前窗口：不销毁主窗，仅重建页面控件与标题
UI_RelocalizeInPlace() {
    global UI, UI_Pages, UI_CurrentPage

    UI_Trace("UI_RelocalizeInPlace begin")

    ; 先隐藏所有控件，避免重建过程闪烁
    UI_HideAllPageControls()

    ; 1) 更新窗口标题
    try {
        newTitle := T("app.title", "输出取色宏 - 左侧菜单")
        DllCall("user32\SetWindowTextW", "ptr", UI.Main.Hwnd, "wstr", newTitle)
    } catch as e1 {
        UI_Trace("Relocalize: SetWindowText fail: " e1.Message)
    }

    ; 2) 销毁全部页面控件，并重置初始化标记
    try {
        for key, pg in UI_Pages {
            if (pg && IsObject(pg) && pg.HasProp("Controls") && IsObject(pg.Controls)) {
                for ctl in pg.Controls {
                    try ctl.Destroy()
                }
                pg.Controls := []
            }
            if (pg && IsObject(pg) && pg.HasProp("Inited")) {
                pg.Inited := false
            }
        }
    } catch as e2 {
        UI_Trace("Relocalize: destroy page controls err: " e2.Message)
    }

    ; 3) 强制重建当前页：先清空当前页标记，再切回
    key := UI_CurrentPage
    UI_CurrentPage := ""   ; 强制 UI_SwitchPage 重建
    if (key = "" || !UI_Pages.Has(key)) {
        key := "profile"
    }
    try {
        UI_SwitchPage(key)
    } catch as e3 {
        UI_Trace("Relocalize: UI_SwitchPage err: " e3.Message)
    }

    ; 4) 强制重绘
    UI_ForceRedrawAll()
    UI_Trace("UI_RelocalizeInPlace end")
}

; 隐藏所有页面的全部控件（防止跨页残留）
UI_HideAllPageControls() {
    global UI_Pages
    try {
        for key, pg in UI_Pages {
            if (pg && IsObject(pg) && HasProp(pg, "Controls") && IsObject(pg.Controls)) {
                for ctl in pg.Controls {
                    try ctl.Visible := false
                }
            }
        }
    } catch {
    }
}