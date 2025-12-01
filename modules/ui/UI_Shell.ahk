; ============================== modules\ui\UI_Shell.ahk ==============================
#Requires AutoHotkey v2
#Include "pages\_index.ahk"

; 主壳：左侧 TreeView + 右侧面板（严格块结构）

UI_ShowMain() {
    global UI, UI_NavMap
    UI_EnablePerMonitorDPI()

    try {
        if !(IsSet(gLang) && gLang.Has("Code")) {
            Lang_Init("zh-CN")
        }
    } catch {
        Lang_Init("zh-CN")
    }

    UI.Main := Gui("+Resize +OwnDialogs", T("app.title", "输出取色宏 - 左侧菜单"))
    UI.Main.MarginX := 12
    UI.Main.MarginY := 10
    UI.Main.SetFont("s10", "Segoe UI")
    UI.Main.OnEvent("Size", UI_OnResize_LeftNav)
    UI.Main.OnEvent("Close", UI_OnMainClose)

    UI.Nav := UI.Main.Add("TreeView", "xm ym w220 h620 +Lines +Buttons")
    UI.Nav.OnEvent("Click", UI_OnNavChange)

    rootProfile := UI.Nav.Add("概览与配置")
    rootData    := UI.Nav.Add("数据与检测")
    rootAuto    := UI.Nav.Add("自动化")
    rootAdv     := UI.Nav.Add("高级功能")
    rootTools   := UI.Nav.Add("工具")
    rootSet     := UI.Nav.Add("设置")

    nodeProfile := UI.Nav.Add("概览与配置", rootProfile)

    nodeSkills  := UI.Nav.Add("技能",       rootData)
    nodePoints  := UI.Nav.Add("取色点位",   rootData)
    nodeDefault := UI.Nav.Add("默认技能",   rootData)

    nodeRules   := UI.Nav.Add("循环规则",       rootAuto)
    nodeBuffs   := UI.Nav.Add("计时器（BUFF）", rootAuto)
    nodeThreads := UI.Nav.Add("线程配置",       rootAuto)

    nodeRot     := UI.Nav.Add("轮换配置",             rootAdv)
    nodeDiag    := UI.Nav.Add("采集诊断（DXGI/ROI）", rootAdv)
    nodeLogs    := UI.Nav.Add("日志查看",             rootAdv)
    nodeCastDbg := UI.Nav.Add("技能调试 / 施法条",     rootAdv)
    ; 新增：轮换配置的三级菜单（第一步：常规、轨道）
    nodeRotGen    := UI.Nav.Add("常规", nodeRot)
    nodeRotTrks   := UI.Nav.Add("轨道", nodeRot)
    nodeRotGates  := UI.Nav.Add("跳轨", nodeRot)
    nodeRotOpener := UI.Nav.Add("起手", nodeRot)

    nodeToolsIO    := UI.Nav.Add("导入 / 导出", rootTools)
    nodeToolsQuick := UI.Nav.Add("快捷测试",    rootTools)

    nodeSettingsLang  := UI.Nav.Add("界面 / 语言", rootSet)
    nodeSettingsAbout := UI.Nav.Add("关于",       rootSet)

    try {
        UI.Nav.Modify(rootProfile, "Expand")
        UI.Nav.Modify(rootData,    "Expand")
        UI.Nav.Modify(rootAuto,    "Expand")
        UI.Nav.Modify(rootAdv,     "Expand")
        UI.Nav.Modify(rootTools,   "Expand")
        UI.Nav.Modify(rootSet,     "Expand")
    }
    UI_NavMap[nodeProfile]      := "profile"
    UI_NavMap[nodeSkills]       := "skills"
    UI_NavMap[nodePoints]       := "points"
    UI_NavMap[nodeDefault]      := "default_skill"
    UI_NavMap[nodeRules]        := "rules"
    UI_NavMap[nodeBuffs]        := "buffs"
    UI_NavMap[nodeThreads]      := "threads"
    UI_NavMap[nodeRot]          := "adv_rotation"
    UI_NavMap[nodeDiag]         := "adv_diag"
    UI_NavMap[nodeLogs]         := "adv_logs"
    UI_NavMap[nodeCastDbg]      := "adv_castdebug"
    ; 新增映射
    UI_NavMap[nodeRotGen]       := "adv_rotation_general"
    UI_NavMap[nodeRotTrks]      := "adv_rotation_tracks"
    UI_NavMap[nodeRotGates]     := "adv_rotation_gates"
    UI_NavMap[nodeRotOpener]    := "adv_rotation_opener"

    UI_NavMap[nodeToolsIO]      := "tools_io"
    UI_NavMap[nodeToolsQuick]   := "tools_quick"
    UI_NavMap[nodeSettingsLang] := "settings_lang"
    UI_NavMap[nodeSettingsAbout]:= "settings_about"

    UI_RegisterPage("profile",        "概览与配置", Page_Profile_Build,        Page_Profile_Layout, Page_Profile_OnEnter)
    UI_RegisterPage("skills",         "技能",       Page_Skills_Build,         Page_Skills_Layout)
    UI_RegisterPage("points",         "点位",       Page_Points_Build,         Page_Points_Layout)
    UI_RegisterPage("default_skill",  "默认技能",   Page_DefaultSkill_Build,   Page_DefaultSkill_Layout,  Page_DefaultSkill_OnEnter)

    UI_RegisterPage("rules",          "循环规则",   Page_Rules_Build,          Page_Rules_Layout,         Page_Rules_OnEnter)
    UI_RegisterPage("buffs",          "BUFF",       Page_Buffs_Build,          Page_Buffs_Layout,         Page_Buffs_OnEnter)
    UI_RegisterPage("threads",        "线程",       Page_Threads_Build,        Page_Threads_Layout,       Page_Threads_OnEnter)

    UI_RegisterPage("adv_rotation",   "轮换配置",   Page_Rotation_Build,       Page_Rotation_Layout,      Page_Rotation_OnEnter)
    UI_RegisterPage("adv_diag",       "采集诊断",   Page_Diag_Build,           Page_Diag_Layout)
    UI_RegisterPage("adv_logs",       "日志查看",   Page_Logs_Build,           Page_Logs_Layout,         Page_Logs_OnEnter)
    UI_RegisterPage("adv_castdebug",  "技能调试",   Page_CastDebug_Build, Page_CastDebug_Layout, Page_CastDebug_OnEnter)
    ; 新注册：轮换配置下的两页
    UI_RegisterPage("adv_rotation_general", "轮换-常规", Page_RotGen_Build,   Page_RotGen_Layout,   Page_RotGen_OnEnter)
    UI_RegisterPage("adv_rotation_tracks",  "轮换-轨道", Page_RotTracks_Build,Page_RotTracks_Layout,Page_RotTracks_OnEnter)
    UI_RegisterPage("adv_rotation_gates",   "轮换-跳轨",  Page_RotGates_Build,       Page_RotGates_Layout,      Page_RotGates_OnEnter)
    UI_RegisterPage("adv_rotation_opener",  "轮换-起手",  Page_RotOpener_Build,      Page_RotOpener_Layout,     Page_RotOpener_OnEnter)
    UI_RegisterPage("tools_io",       "导入导出",   Page_ToolsIO_Build,        Page_ToolsIO_Layout)
    UI_RegisterPage("tools_quick",    "快捷测试",   Page_ToolsQuick_Build,     Page_ToolsQuick_Layout)

    UI_RegisterPage("settings_lang",  "界面语言",   Page_Settings_Lang_Build,  Page_Settings_Lang_Layout, Page_Settings_Lang_OnEnter)
    UI_RegisterPage("settings_about", "关于",       Page_Settings_About_Build, Page_Settings_About_Layout,Page_Settings_About_OnEnter)

    UI.Main.Show("w1060 h780")

    try {
        UI.Nav.Modify(nodeProfile, "Select")
    }
    UI_OnNavChange()
}

UI_OnMainClose(*) {
    ExitApp()
}

UI_OnNavChange(*) {
    global UI, UI_NavMap

    sel := UI.Nav.GetSelection()
    if (!sel) {
        return
    }
    if (!UI_NavMap.Has(sel)) {
        try {
            UI.Nav.Modify(sel, "Expand")
        } catch {
        }
        return
    }
    key := UI_NavMap[sel]
    UI_SwitchPage(key)
}

UI_OnResize_LeftNav(gui, minmax, w, h) {
    global UI

    if (minmax = 1) {
        return
    }
    if (minmax = -1) {
        return
    }
    if (w <= 0 || h <= 0) {
        return
    }
    navW := 220
    UI.Nav.Move(UI.Main.MarginX, UI.Main.MarginY, navW, Max(h - UI.Main.MarginY * 2, 320))
    UI_LayoutCurrentPage()
}