; modules\ui\shell_v2\UI_ShellV2.ahk
#Requires AutoHotkey v2
#Include "UIX_Common.ahk"
#Include "..\rotation\RE_UI_Page_General.ahk"
#Include "..\rotation\RE_UI_Page_Tracks.ahk"
#Include "..\rotation\RE_UI_Page_Gates.ahk"
#Include "..\rotation\RE_UI_Page_Opener.ahk"

global UI_ShellV2_Main := 0

UI_ShowMainV2(owned := true, startKey := "general") {
    UIX_EnablePerMonitorDPI()
    global App, UI_ShellV2_Main

    try {
        if IsObject(UI_ShellV2_Main) && UI_ShellV2_Main && UI_ShellV2_Main.Hwnd {
            WinActivate "ahk_id " UI_ShellV2_Main.Hwnd
            return UI_ShellV2_Main
        }
    }

    if !IsObject(App) || !App.Has("ProfileData") {
        MsgBox "Profile 未加载"
        return 0
    }

    main := UIX_CreateOwnedGui("输出取色宏（ShellV2）", owned)
    main.MarginX := 10, main.MarginY := 10
    main.SetFont("s10", "Segoe UI")

    ; 左侧导航
    navItems := [{ type: "sep", text: "配置" }, { key: "general", text: "常规设置" }, { type: "sep", text: "自动化" }, { key: "opener",
        text: "起手配置" }, { key: "tracks", text: "轮换轨道" }, { key: "gates", text: "跳轨规则" }
    ]
    nav := UIX_Nav_Build(main, main.MarginX, main.MarginY, 160, 640, navItems)

    ; 右侧面板区域
    panelRect := { x: main.MarginX + 160 + 8, y: main.MarginY, w: 860, h: 720 }

    ; 页面路由构建器
    builders := Map()
    builders["general"] := (ctx) => REUI_Page_General_Build(ctx)
    builders["opener"] := (ctx) => REUI_Page_Opener_Build(ctx)
    builders["tracks"] := (ctx) => REUI_Page_Tracks_Build(ctx)
    builders["gates"] := (ctx) => REUI_Page_Gates_Build(ctx)

    state := { current: "", panel: 0, controls: [] }

    ; --- 将 UI_ShowMainV2 内部的 LoadPage(name) 替换为以下版本 ---
    LoadPage(name) {
        UIX_Log("LoadPage " name)
        if (state.current = name) {
            UIX_Log("same page, skip")
            return
        }

        if (IsObject(state.panel) && state.panel && state.panel.Hwnd) {
            try {
                state.panel.Destroy()
                UIX_Log("Destroy prev panel hwnd=" state.panel.Hwnd)
            } catch {
            }
        }
        state.controls := []

        preSet := Map()
        preArr := UIX_EnumChildHwnds(main.Hwnd)
        for _, h in preArr {
            preSet[h] := 1
        }
        UIX_Log("Pre snapshot size=" preSet.Count)

        ; 子面板：设为真正子窗口（WS_CHILD），并裁剪，避免闪烁/残影
        panel := Gui()
        panel.MarginX := 10
        panel.MarginY := 10
        panel.Opt("-Caption -SysMenu -MinimizeBox -MaximizeBox -Border +Theme")

        DllCall("user32\SetParent", "ptr", panel.Hwnd, "ptr", main.Hwnd)

        GWL_STYLE := -16
        WS_CHILD := 0x40000000
        WS_POPUP := 0x80000000
        WS_CLIPCHILDREN := 0x02000000
        WS_CLIPSIBLINGS := 0x04000000

        style := DllCall("user32\GetWindowLongPtr", "ptr", panel.Hwnd, "int", GWL_STYLE, "ptr")
        style := (style & ~WS_POPUP) | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
        DllCall("user32\SetWindowLongPtr", "ptr", panel.Hwnd, "int", GWL_STYLE, "ptr", style)

        SWP_NOZORDER := 0x0004
        SWP_FRAMECHANGED := 0x0020
        SWP_SHOWWINDOW := 0x0040
        DllCall("user32\SetWindowPos", "ptr", panel.Hwnd, "ptr", 0
            , "int", panelRect.x, "int", panelRect.y
            , "int", panelRect.w, "int", panelRect.h
            , "uint", SWP_NOZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW)

        UIX_Log("Create child panel hwnd=" panel.Hwnd)

        ; 上下文：tabStub 仅兼容旧页面的 tab.UseTab 调用
        tabStub := { UseTab: (*) => 0, Hwnd: panel.Hwnd }
        ctx := { dlg: panel, tab: tabStub, cfg: App["ProfileData"].Rotation, prof: App["ProfileData"] }

        builtOK := false
        if (builders.Has(name)) {
            try {
                builders[name].Call(ctx)
                builtOK := true
                UIX_Log("Builder ok for " name)
            } catch as e {
                UIX_Log("Builder error: " e.Message " @ " e.File ":" e.Line)
                MsgBox "加载页面失败：" e.Message
            }
        } else {
            panel.Add("Text", "xm ym", "页面未实现：" name)
            builtOK := true
        }

        if (builtOK) {
            post := UIX_EnumChildHwnds(main.Hwnd)
            newCount := 0
            for _, h in post {
                if (!preSet.Has(h)) {
                    newCount += 1
                }
            }
            UIX_Log("Post snapshot newControls=" newCount)

            ; 强制刷新子面板与子控件
            RDW_INVALIDATE := 0x0001
            RDW_ERASE := 0x0004
            RDW_ALLCHILDREN := 0x0080
            RDW_FRAME := 0x0400
            flags := RDW_INVALIDATE | RDW_ERASE | RDW_ALLCHILDREN | RDW_FRAME
            DllCall("user32\RedrawWindow", "ptr", panel.Hwnd, "ptr", 0, "ptr", 0, "uint", flags)
        }

        state.current := name
        state.panel := panel
    }

    ; 绑定回调与首屏
    (nav.SetOnChange).Call((key) => LoadPage(key))
    (nav.SelectKey).Call(startKey)

    ; 自适应（只移动左列与右侧子面板）
    main.OnEvent("Size", (gui, mm, w, h) => (
        nav.Ctrl.Move(gui.MarginX, gui.MarginY, 160, Max(h - gui.MarginY * 2, 360)),
        panelRect.x := gui.MarginX + 160 + 8,
        panelRect.y := gui.MarginY,
        panelRect.w := Max(w - panelRect.x - gui.MarginX, 480),
        panelRect.h := Max(h - gui.MarginY * 2, 360),
        (IsObject(state.panel) && state.panel) ? state.panel.Move(panelRect.x, panelRect.y, panelRect.w, panelRect.h) :
            0
    ))
    main.OnEvent("Close", (*) => (UI_ShellV2_Main := 0))
    main.Show("w1060 h760")

    UI_ShellV2_Main := main
    return main
}
