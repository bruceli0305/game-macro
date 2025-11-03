#Requires AutoHotkey v2
; 顶层外壳：创建主窗体、顶层Tab，委托各页面构建，首屏布局与切页显隐

global UI := Map()  ; 统一控件注册表
UI_EnablePerMonitorDPI() {
    ; 优先 Per-Monitor V2，失败回退到 Per-Monitor，再到 System DPI aware
    try DllCall("user32\SetProcessDpiAwarenessContext", "ptr", -4, "ptr")  ; PER_MONITOR_AWARE_V2
    catch {
        try DllCall("shcore\SetProcessDpiAwareness", "int", 2, "int")      ; PROCESS_PER_MONITOR_DPI_AWARE
        catch {
            try DllCall("user32\SetProcessDPIAware")                        ; 老 API，System DPI
        }
    }
}
UI_ShowMain() {
    global UI
    UI_EnablePerMonitorDPI()
    ; 语言兜底（若外部未初始化）
    try {
        if !(IsSet(gLang) && gLang.Has("Code"))
            Lang_Init("zh-CN")
    } catch {
        Lang_Init("zh-CN")
    }

    UI.Main := Gui("+Resize", T("app.title","输出取色宏 - v0.0.1-Alpha-0.1"))
    UI.Main.MarginX := 14, UI.Main.MarginY := 12
    UI.Main.SetFont("s10", "Segoe UI")
    UI.Main.Opt("+OwnDialogs")   ; 新增：让标准对话框属于主窗口
    UI.Main.OnEvent("Close", (*) => ExitApp())

    ; 顶层 Tab：第1页=配置，第2页=设置
    UI.TopTab := UI.Main.Add("Tab3", "xm ym w860 h720"
        , [ T("tab.main","配置"), T("tab.settings","设置") ])

    ; 第1页：配置
    UI.TopTab.UseTab(1)
    UI_Page_Config_Build()

    ; 第2页：设置
    UI.TopTab.UseTab(2)
    UI_Page_Settings_Build()

    ; 退出上下文
    UI.TopTab.UseTab()

    ; 切页与自适应布局
    UI.TopTab.OnEvent("Change", UI_OnTopTabChange)
    UI.Main.OnEvent("Size", UI_OnResize)

    ; 首屏先选第1页，隐藏布局后显示
    UI.TopTab.Value := 1
    UI.Main.Show("w890 h750 Hide")
    rc := Buffer(16, 0)
    DllCall("user32\GetClientRect", "ptr", UI.Main.Hwnd, "ptr", rc.Ptr)
    cw := NumGet(rc, 8, "Int"), ch := NumGet(rc, 12, "Int")
    UI_OnResize(UI.Main, 0, cw, ch)
    UI_ToggleSettingsPage(false)
    UI_ToggleMainPage(true)

    ; 新增：默认显示技能面板（已替代内层 Tab）
    try UI_Page_Config_ShowPane(1)

    UI.Main.Show()

    ; 数据加载
    UI_Page_Config_ReloadProfiles()
}