#Requires AutoHotkey v2
;UI_Framework.ahk
; 页面管理框架：注册、切换、布局（兼容 Build(page) 与 Build() 两种签名）
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
        FileAppend(ts " [" A_TickCount "] " msg "rn"
            , A_ScriptDir "\Logs\ui_trace.log", "UTF-8")
    } catch {
    }
}

global UI := IsSet(UI) ? UI : Map()
global UI_Pages := Map() ; key -> { Title, Controls:[], Build, Layout, Inited, OnEnter?, OnLeave? }
global UI_CurrentPage := ""
global UI_NavMap := Map() ; navNodeId -> pageKey

UI_RegisterPage(key, title, buildFn, layoutFn := 0, onEnter := 0, onLeave := 0) {
    global UI_Pages
    page := { Title: title, Controls: [], Build: buildFn, Layout: layoutFn, Inited: false, OnEnter: onEnter, OnLeave: onLeave }
    UI_Pages[key] := page
    UI_Trace("RegisterPage key=" key " title=" title)
}

UI_SwitchPage(key) {
    global UI_Pages, UI_CurrentPage
    UI_Trace("SwitchPage from=" UI_CurrentPage " to=" key)

    if (UI_CurrentPage = key) {
        UI_Trace("SwitchPage short-circuit: already on " key)
        return
    }

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
        for ctl in old.Controls {
            try {
                ctl.Visible := false
            } catch {
            }
        }
    }

    if (!UI_Pages.Has(key)) {
        UI_Trace("SwitchPage target not found: " key)
        return
    }

    UI_CurrentPage := key
    pg := UI_Pages[key]

    if (!pg.Inited) {
        built := false
        try {
            UI_Trace("Page Build(page) begin key=" key)
            pg.Build(pg)
            UI_Trace("Page Build(page) success key=" key)
            built := true
        } catch as e1 {
            UI_Trace("Page Build(page) failed key=" key " err=" e1.Message)
            try {
                UI_Trace("Page Build() begin key=" key)
                pg.Build()
                UI_Trace("Page Build() success key=" key)
                built := true
            } catch as e2 {
                UI_Trace("Page Build() failed key=" key " err=" e2.Message)
                built := false
            }
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
            shown := shown + 1
        } catch {
        }
    }
    UI_Trace("Show controls: " shown " for page " key)

    try {
        UI_LayoutCurrentPage()
        UI_Trace("Layout called for page " key)
    } catch as eL {
        UI_Trace("Layout exception for page " key " err=" eL.Message)
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
    gap := 12
    try {
        if (IsSet(UI) && UI.Has("Nav") && UI.Nav) {
            nx := 0
            ny := 0
            nw := 0
            nh := 0
            UI.Nav.GetPos(&nx, &ny, &nw, &nh)
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
        cw := NumGet(rc, 8, "Int")
        ch := NumGet(rc, 12, "Int")
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
    UI_Trace(Format("GetPageRect x={1} y={2} w={3} h={4} navW={5} client={6}x{7}", rcOut.X, rcOut.Y, rcOut.W, rcOut.H,
        navW, cw, ch))
    return rcOut
}

UI_LayoutCurrentPage() {
    global UI_Pages, UI_CurrentPage
    if (UI_CurrentPage = "" || !UI_Pages.Has(UI_CurrentPage)) {
        return
    }
    pg := UI_Pages[UI_CurrentPage]
    if (pg.Layout) {
        rc := 0
        try {
            rc := UI_GetPageRect()
        } catch as eRC {
            UI_Trace("GetPageRect exception: " eRC.Message)
            rc := { X: 244, Y: 10, W: 804, H: 760 }
        }
        ; 首选调用 Layout(rc)，若因签名不匹配抛出异常，回退调用 Layout()
        try {
            pg.Layout(rc)
        } catch as e1 {
            UI_Trace("Layout(rc) exception for " UI_CurrentPage " err=" e1.Message)
            try {
                pg.Layout()
                UI_Trace("Layout() fallback success for " UI_CurrentPage)
            } catch as e2 {
                UI_Trace("Layout() fallback failed for " UI_CurrentPage " err=" e2.Message)
            }
        }
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
