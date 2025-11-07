#Requires AutoHotkey v2
#Include "UIX_Common.ahk"
#Include "UIX_Theme.ahk"
#Include "..\rotation\RE_UI_Page_General.ahk"
#Include "..\rotation\RE_UI_Page_Tracks.ahk"
#Include "..\rotation\RE_UI_Page_Gates.ahk"
#Include "..\rotation\RE_UI_Page_Opener.ahk"
#Include "pages\PG_General.ahk"
#Include "pages\PG_Skills.ahk"

global UI_ShellV2_Main := 0

NAV_W   := 300   ; 左侧更宽（大约增加一半）
NAV_PAD := 16    ; 卡片内边距
GUTTER  := 18    ; 左右分隔
ROW_H   := 52    ; 行高更高

UI_ShowMainV2(owned := true, startKey := "skills") {
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

    theme := UIX_Theme_Get()

    main := UIX_CreateOwnedGui("输出取色宏（ShellV2）", owned)
    main.MarginX := 10
    main.MarginY := 10
    main.SetFont("s10", "Segoe UI")
    UIX_Theme_ApplyWindow(main, theme)

    navItems := [
        { type:"sep", text:"配置管理" }
      , { key:"skills",  text:"技能配置" }
      , { key:"general", text:"常规设置" }
      , { key:"buffers", text:"BUFF配置" }     ; 临时：点击进入旧对话
      , { key:"threads", text:"线程配置" }     ; 临时：点击进入旧对话
      , { type:"sep", text:"自动化" }
      , { key:"opener", text:"起手配置" }
      , { key:"tracks", text:"轮换轨道" }
      , { key:"gates",  text:"跳轨规则" }
      , { type:"sep", text:"系统" }
      , { key:"settings", text:"界面语言" }
    ]
    ; 左侧圆角卡片（更像参考图的侧栏）
    navCardRect := { x: main.MarginX, y: main.MarginY, w: NAV_W, h: 640 }
    navCard := UIX_Theme_CreateCardPanel(main.Hwnd, navCardRect, theme, theme.Radius)
    ; 卡片里的导航（去边框 + 行高）
    nav := UIX_Nav_BuildLV(navCard, NAV_PAD, NAV_PAD
    , NAV_W - NAV_PAD*2, 640 - NAV_PAD*2, navItems, theme, ROW_H)
    UIX_Theme_SkinListBox(nav.Ctrl, theme)
    panelRect := { x: main.MarginX + 160 + 8, y: main.MarginY, w: 860, h: 720 }
    state := { current: "", panel: 0, pageObj: 0 }

    builders := Map()
    builders["skills"]   := (ctx) => PG_Skills_Build(ctx, theme)
    builders["general"]  := (ctx) => PG_General_Build(ctx)              ; 新表单页
    builders["opener"]   := (ctx) => REUI_Page_Opener_Build(ctx)
    builders["tracks"]   := (ctx) => REUI_Page_Tracks_Build(ctx)
    builders["gates"]    := (ctx) => REUI_Page_Gates_Build(ctx)
    builders["settings"] := (ctx) => UI_ShellV2_SettingsShim(ctx)
    builders["buffers"]  := (ctx) => UI_ShellV2_JumpOld(() => BuffsManager_Show(), ctx)
    builders["threads"]  := (ctx) => UI_ShellV2_JumpOld(() => ThreadsManager_Show(), ctx)

    LoadPage(name) {
        if (state.current = name) {
            return
        }
        if (IsObject(state.panel) && state.panel && state.panel.Hwnd) {
            try {
                state.panel.Destroy()
            } catch {
            }
        }
        state.pageObj := 0

        panel := UIX_CreateChildPanel(main.Hwnd, panelRect)
        try {
            panel.BackColor := Format("0x{:06X}", theme.PanelBg)
        } catch {
        }
        UIX_Theme_RoundWindow(panel.Hwnd, theme.Radius)

        tabStub := { UseTab: (*) => 0, Hwnd: panel.Hwnd }
        ctx := { dlg: panel, tab: tabStub, cfg: App["ProfileData"].Rotation, prof: App["ProfileData"], theme: theme }

        if (builders.Has(name)) {
            try {
                obj := builders[name].Call(ctx)
                state.pageObj := obj
            } catch as e {
                UIX_Log("Builder error: " e.Message " @ " e.File ":" e.Line)
                MsgBox Format("加载页面失败：{1}`nFile: {2}`nLine: {3}`nWhat: {4}", e.Message, e.File, e.Line, e.What)
            }
        } else {
            panel.Add("Text", "xm ym", "页面未实现：" name)
        }

        state.current := name
        state.panel := panel

        UIX_SafeCall(state.pageObj, "Reflow", ctx)
    }

    main.OnEvent("Size", (gui, mm, w, h) => (
        ; 左侧卡片
        navCard.Move(gui.MarginX, gui.MarginY, NAV_W, Max(h - gui.MarginY*2, 360)),
        ; 卡片内导航
        (nav.Reflow).Call(NAV_PAD, NAV_PAD, NAV_W - NAV_PAD*2, Max(h - gui.MarginY*2, 360) - NAV_PAD*2),

        ; 右侧子面板区域（向右错开 NAV_W + GUTTER）
        panelRect.x := gui.MarginX + NAV_W + GUTTER,
        panelRect.y := gui.MarginY,
        panelRect.w := Max(w - panelRect.x - gui.MarginY, 520),
        panelRect.h := Max(h - gui.MarginY*2, 360),

        (IsObject(state.panel) && state.panel) ? state.panel.Move(panelRect.x, panelRect.y, panelRect.w, panelRect.h) : 0,
        UIX_SafeCall(state.pageObj, "Reflow", { dlg: state.panel, rect: panelRect, prof: App["ProfileData"], cfg: App["ProfileData"].Rotation, theme: theme })
    ))
    main.OnEvent("Close", (*) => (UI_ShellV2_Main := 0))

    (nav.SetOnChange).Call((key) => LoadPage(key))
    (nav.SelectKey).Call(startKey)

    main.Show("w1060 h760")
    UI_ShellV2_Main := main
    return main
}

UI_ShellV2_SettingsShim(ctx) {
    rc := UIX_PageRect(ctx.dlg)
    lab := ctx.dlg.Add("Text", Format("x{} y{} w260", rc.X, rc.Y), "使用旧设置页调整语言/输出后会重建界面")
    btn := ctx.dlg.Add("Button", Format("x{} y{} w160", rc.X, rc.Y + 36), "打开旧设置页")
    btn.OnEvent("Click", (*) => UI_Page_Settings_Build())
    return { Reflow: (c*) => 0, Save: (c*) => 0, Destroy: (c*) => 0 }
}

; 临时跳转旧对话（BUFF/线程），保持路由一致
UI_ShellV2_JumpOld(showFn, ctx) {
    btn := ctx.dlg.Add("Button", "xm ym w180", "打开旧对话框")
    btn.OnEvent("Click", (*) => showFn.Call())
    return { Reflow: (c*) => 0, Save: (c*) => 0, Destroy: (c*) => 0 }
}