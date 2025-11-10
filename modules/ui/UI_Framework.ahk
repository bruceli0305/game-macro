#Requires AutoHotkey v2

; 页面管理框架：注册、切换、布局（兼容 Build(page) 与 Build() 两种签名）
; 严格使用块结构 if/try/catch

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
}

UI_SwitchPage(key) {
    global UI_Pages, UI_CurrentPage

    ; 已是当前页则不处理
    if (UI_CurrentPage = key) {
        return
    }

    ; 隐藏旧页
    if (UI_CurrentPage != "" && UI_Pages.Has(UI_CurrentPage)) {
        old := UI_Pages[UI_CurrentPage]
        if (old.OnLeave) {
            try {
                old.OnLeave()
            } catch {
                ; 忽略页面离开回调异常
            }
        }
        for ctl in old.Controls {
            try {
                ctl.Visible := false
            } catch {
                ; 忽略不可见异常
            }
        }
    }

    ; 目标页不存在
    if (!UI_Pages.Has(key)) {
        return
    }

    ; 提前设置当前页，便于无参数 Build() 内通过 UI_CurrentPage 获取自身
    UI_CurrentPage := key
    pg := UI_Pages[key]

    ; 首次构建：优先尝试 Build(page)，失败则尝试 Build()
    if (!pg.Inited) {
        built := false
        try {
            pg.Build(pg)
            built := true
        } catch as e1 {
            try {
                pg.Build()
                built := true
            } catch as e2 {
                ; 记录一下（可选）
                try {
                    Diag_Log("Page Build failed: key=" key " err=" e1.Message "/" e2.Message)
                } catch {
                }
                built := false
            }
        }
        pg.Inited := built
    }

    ; 显示新页控件
    for ctl in pg.Controls {
        try {
            ctl.Visible := true
        } catch {
        }
    }

    ; 做一次布局
    UI_LayoutCurrentPage()

    ; 进入回调
    if (pg.OnEnter) {
        try {
            pg.OnEnter()
        } catch {
        }
    }
}

; ========= 右侧面板区域（动态读取左侧 Nav 宽度） =========
UI_GetPageRect() {
    global UI

    ; 主窗边距（默认为 12/10）
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

    ; 左侧导航实际宽度（默认 220），与页面间隔 gap=12
    navW := 220
    gap  := 12
    try {
        if (IsSet(UI) && UI.Has("Nav") && UI.Nav) {
            nx := 0, ny := 0, nw := 0, nh := 0
            UI.Nav.GetPos(&nx, &ny, &nw, &nh)
            if (nw > 0) {
                navW := nw
            }
        }
    } catch {
        navW := 220
    }

    ; 主窗客户区尺寸
    cw := 0, ch := 0
    try {
        rc := Buffer(16, 0)
        DllCall("user32\GetClientRect", "ptr", UI.Main.Hwnd, "ptr", rc.Ptr)
        cw := NumGet(rc, 8, "Int")
        ch := NumGet(rc, 12, "Int")
    } catch {
        cw := A_ScreenWidth
        ch := A_ScreenHeight
    }

    ; 右侧区域
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

    return { X: x, Y: y, W: w, H: h, NavW: navW, ClientW: cw, ClientH: ch }
}

UI_LayoutCurrentPage() {
    global UI_Pages, UI_CurrentPage
    if (UI_CurrentPage = "" || !UI_Pages.Has(UI_CurrentPage)) {
        return
    }
    pg := UI_Pages[UI_CurrentPage]
    if (pg.Layout) {
        try {
            rc := UI_GetPageRect()
            pg.Layout(rc)
        } catch {
            ; 忽略页面布局异常
        }
    }
}

UI_EnablePerMonitorDPI() {
    try {
        DllCall("user32\SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
    } catch {
        try {
            DllCall("shcore\SetProcessDpiAwareness", "int", 2, "int")
        } catch {
            try {
                DllCall("user32\SetProcessDPIAware")
            } catch {
            }
        }
    }
}

; ========= 重建主界面（全局可用） =========
UI_RebuildMain(*) {
    global UI
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Destroy()
        }
    } catch {
        ; 忽略销毁异常
    }
    UI_ShowMain()
}