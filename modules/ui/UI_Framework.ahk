; ============================== modules\ui\UI_Framework.ahk ==============================
#Requires AutoHotkey v2
; 页面管理框架：注册、切换、布局（兼容 Build()/Build(page) 与 Layout()/Layout(rc)）
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
        }
        return ok
    }
    if (pmin >= 1) {
        try {
            fn.Call(arg)
            ok := true
        }
        return ok
    }
    ; 未能读取到 MinParams 时，尝试先传参，再不传参
    try {
        fn.Call(arg)
        ok := true
    } catch as e2 {
        fn.Call()
        ok := true
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
}

UI_SwitchPage(key) {
    global UI_Pages, UI_CurrentPage
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
                old.OnLeave()
            }
        }
    }

    ; 核心修复：切换前先隐藏所有页面控件，杜绝残留
    UI_HideAllPageControls()

    if (!UI_Pages.Has(key)) {
        return
    }

    UI_CurrentPage := key
    pg := UI_Pages[key]

    if (!pg.Inited) {
        built := false
        try {
            called := UI_Call0Or1(pg.Build, pg)
            if (called) {
                built := true
            } else {
                built := false
            }
        } catch as eB {
            built := false
        }
        pg.Inited := built
        if (!built) {
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

    if (pg.Layout) {
        try {
            rc := UI_GetPageRect()
        } catch as eRC {
            rc := { X: 244, Y: 10, W: 804, H: 760 }
        }
        try {
            ok := UI_Call0Or1(pg.Layout, rc)
        }
    }

    if (pg.OnEnter) {
        try {
            pg.OnEnter()
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
        rc := { X: 244, Y: 10, W: 804, H: 760 }
    }
    try {
        ok := UI_Call0Or1(pg.Layout, rc)
    }
}

UI_EnablePerMonitorDPI() {
    try {
        DllCall("user32\SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
    } catch {
        try {
            DllCall("shcore\SetProcessDpiAwareness", "int", 2, "int")
        } catch {
            DllCall("user32\SetProcessDPIAware")
        }
    }
}

UI_RebuildMain(*) {
    global UI
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Destroy()
        }
    }
    UI_ShowMain()
}
; 动态本地化当前窗口：不销毁主窗，仅重建页面控件与标题
UI_RelocalizeInPlace() {
    global UI, UI_Pages, UI_CurrentPage
    ; 先隐藏所有控件，避免重建过程闪烁
    UI_HideAllPageControls()

    ; 1) 更新窗口标题
    try {
        newTitle := T("app.title", "输出取色宏 - 左侧菜单")
        DllCall("user32\SetWindowTextW", "ptr", UI.Main.Hwnd, "wstr", newTitle)
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
    }

    ; 3) 强制重建当前页：先清空当前页标记，再切回
    key := UI_CurrentPage
    UI_CurrentPage := ""   ; 强制 UI_SwitchPage 重建
    if (key = "" || !UI_Pages.Has(key)) {
        key := "profile"
    }
    try {
        UI_SwitchPage(key)
    }
    ; 4) 强制重绘
    UI_ForceRedrawAll()
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