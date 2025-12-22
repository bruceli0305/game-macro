#Requires AutoHotkey v2
; ============================== modules\ui\UI_Framework.ahk ==============================
; 页面管理框架：注册、切换、布局（兼容 Build()/Build(page) 与 Layout()/Layout(rc)）
; 保留修复点：
; - 切页重入保护（g_UI_Switching + Critical）
; - 切页前隐藏所有页面控件（防残留/点击穿透）
; - UI_Call0Or1 更稳健
; 已删除：所有 Info 打点日志

UI__LogException(where, e, fields := 0) {
    try {
        extra := Map("where", where)
        if (IsObject(fields)) {
            for k, v in fields {
                extra[k] := v
            }
        }
        try {
            if (HasProp(e, "What")) {
                extra["what"] := e.What
            }
        } catch {
        }
        try {
            if (HasProp(e, "Message")) {
                extra["msg"] := e.Message
            }
        } catch {
        }
        try {
            if (HasProp(e, "File")) {
                extra["file"] := e.File
            }
        } catch {
        }
        try {
            if (HasProp(e, "Line")) {
                extra["line"] := e.Line
            }
        } catch {
        }

        Logger_Error("UI", "exception", extra)

        try {
            if (HasProp(e, "Stack")) {
                Logger_Error("UI", "stack", Map("stack", e.Stack))
            }
        } catch {
        }
    } catch {
    }
}

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
        } catch {
            ok := false
        }
        return ok
    }

    if (pmin >= 1) {
        try {
            fn.Call(arg)
            ok := true
        } catch {
            ok := false
        }
        return ok
    }

    ; 未能读取到 MinParams 时，尝试先传参，再不传参
    try {
        fn.Call(arg)
        ok := true
        return ok
    } catch {
    }

    try {
        fn.Call()
        ok := true
    } catch {
        ok := false
    }
    return ok
}

global UI := IsSet(UI) ? UI : Map()
global UI_Pages := Map()          ; key -> { Title, Controls:[], Build, Layout, Inited, OnEnter?, OnLeave? }
global UI_CurrentPage := ""
global UI_NavMap := Map()         ; navNodeId -> pageKey

; ====== 切页重入保护 ======
global g_UI_Switching := IsSet(g_UI_Switching) ? g_UI_Switching : false

UI_IsSwitching() {
    global g_UI_Switching
    return g_UI_Switching ? true : false
}

UI__SwitchLeave(wasCrit) {
    global g_UI_Switching
    try {
        if (wasCrit) {
            Critical "On"
        } else {
            Critical "Off"
        }
    } catch {
    }
    g_UI_Switching := false
}

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
    global UI_Pages, UI_CurrentPage, g_UI_Switching

    if (key = "") {
        return
    }

    ; 防止重入：Size 事件 / Click 事件在 Build 中打断，容易造成卡住/错乱
    if (g_UI_Switching) {
        return
    }

    wasCrit := A_IsCritical
    g_UI_Switching := true
    Critical "On"

    ; ====== 同页重建判定 ======
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
                UI__SwitchLeave(wasCrit)
                return
            }
        } else {
            UI__SwitchLeave(wasCrit)
            return
        }
    }

    ; ====== 旧页 OnLeave ======
    if (UI_CurrentPage != "" && UI_Pages.Has(UI_CurrentPage)) {
        old := UI_Pages[UI_CurrentPage]
        if (old.OnLeave) {
            try {
                old.OnLeave()
            } catch as eLeave {
                UI__LogException("SwitchPage OnLeave", eLeave, Map("page", UI_CurrentPage))
            }
        }
    }

    ; 切换前先隐藏所有页面控件，杜绝残留
    UI_HideAllPageControls()

    if (!UI_Pages.Has(key)) {
        UI__SwitchLeave(wasCrit)
        return
    }

    UI_CurrentPage := key
    pg := UI_Pages[key]

    ; ====== Build ======
    if (!pg.Inited) {
        built := false
        try {
            called := UI_Call0Or1(pg.Build, pg)
            built := called ? true : false
        } catch as eB {
            built := false
            UI__LogException("SwitchPage build threw", eB, Map("key", key, "title", pg.Title))
        }
        pg.Inited := built
        if (!built) {
            UI__SwitchLeave(wasCrit)
            return
        }
    }

    ; ====== Show Controls ======
    try {
        if (IsObject(pg.Controls)) {
            for ctl in pg.Controls {
                try {
                    ctl.Visible := true
                } catch {
                }
            }
        }
    } catch as eShow {
        UI__LogException("SwitchPage show controls", eShow, Map("key", key))
    }

    ; ====== Layout ======
    if (pg.Layout) {
        rc := 0
        try {
            rc := UI_GetPageRect()
        } catch {
            rc := { X: 244, Y: 10, W: 804, H: 760 }
        }
        try {
            UI_Call0Or1(pg.Layout, rc)
        } catch as eL {
            UI__LogException("SwitchPage layout threw", eL, Map("key", key))
        }
    }

    ; ====== OnEnter ======
    if (pg.OnEnter) {
        try {
            pg.OnEnter()
        } catch as eE {
            UI__LogException("SwitchPage onEnter threw", eE, Map("key", key))
        }
    }

    UI__SwitchLeave(wasCrit)
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
            nx := 0
            ny := 0
            nw := 0
            nh := 0
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
        try {
            scale := UI_GetScale(UI.Main.Hwnd)
        } catch {
            scale := 1.0
        }
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
    global UI_Pages, UI_CurrentPage, g_UI_Switching
    if (g_UI_Switching) {
        return
    }
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
    } catch {
        rc := { X: 244, Y: 10, W: 804, H: 760 }
    }
    try {
        UI_Call0Or1(pg.Layout, rc)
    } catch as e {
        UI__LogException("LayoutCurrentPage", e, Map("key", UI_CurrentPage))
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

UI_RebuildMain(*) {
    global UI
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Destroy()
        }
    } catch {
    }
    try {
        UI_ShowMain()
    } catch as e {
        UI__LogException("UI_RebuildMain UI_ShowMain", e)
    }
}

; 动态本地化当前窗口：不销毁主窗，仅重建页面控件与标题
UI_RelocalizeInPlace() {
    global UI, UI_Pages, UI_CurrentPage

    UI_HideAllPageControls()

    ; 1) 更新窗口标题
    try {
        newTitle := T("app.title", "输出取色宏 - 左侧菜单")
        DllCall("user32\SetWindowTextW", "ptr", UI.Main.Hwnd, "wstr", newTitle)
    } catch {
    }

    ; 2) 销毁全部页面控件，并重置初始化标记
    try {
        for key, pg in UI_Pages {
            if (pg && IsObject(pg) && pg.HasProp("Controls") && IsObject(pg.Controls)) {
                for ctl in pg.Controls {
                    try {
                        ctl.Destroy()
                    } catch {
                    }
                }
                pg.Controls := []
            }
            if (pg && IsObject(pg) && pg.HasProp("Inited")) {
                pg.Inited := false
            }
        }
    } catch {
    }

    ; 3) 强制重建当前页：先清空当前页标记，再切回
    key := UI_CurrentPage
    UI_CurrentPage := ""
    if (key = "" || !UI_Pages.Has(key)) {
        key := "profile"
    }
    try {
        UI_SwitchPage(key)
    } catch as e2 {
        UI__LogException("UI_RelocalizeInPlace SwitchPage", e2, Map("key", key))
    }

    ; 4) 强制重绘
    try {
        UI_ForceRedrawAll()
    } catch {
    }
}

; 隐藏所有页面的全部控件（防止跨页残留）
UI_HideAllPageControls() {
    global UI_Pages
    try {
        for key, pg in UI_Pages {
            if (pg && IsObject(pg) && HasProp(pg, "Controls") && IsObject(pg.Controls)) {
                for ctl in pg.Controls {
                    try {
                        ctl.Visible := false
                    } catch {
                    }
                }
            }
        }
    } catch {
    }
}