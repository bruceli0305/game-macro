#Requires AutoHotkey v2
#Include "UI_Framework.ahk"
#Include "pages\UI_Page_Profile.ahk"
#Include "pages\UI_Page_Skills.ahk"
#Include "pages\UI_Page_Points.ahk"
#Include "pages\UI_Page_DefaultSkill.ahk"
#Include "pages\UI_Page_RotationSummary.ahk"

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

    ; 左侧导航（显示展开按钮）
    UI.Nav := UI.Main.Add("TreeView", "xm ym w200 h600 +Lines +Buttons")
    UI.Nav.OnEvent("Click", UI_OnNavChange)

    ; 分组
    rootProfile := UI.Nav.Add("概览与配置")
    rootData    := UI.Nav.Add("数据与检测")
    rootAdv     := UI.Nav.Add("高级功能")
    rootSet     := UI.Nav.Add("设置")

    ; 子节点
    nodeProfile := UI.Nav.Add("概览与配置", rootProfile)

    nodeSkills  := UI.Nav.Add("技能", rootData)
    nodePoints  := UI.Nav.Add("取色点位", rootData)
    nodeDefault := UI.Nav.Add("默认技能", rootData)

    nodeRot     := UI.Nav.Add("轮换配置", rootAdv)

    nodeSettings:= UI.Nav.Add("界面/语言", rootSet)

    ; 展开分组
    try {
        UI.Nav.Modify(rootProfile, "Expand")
        UI.Nav.Modify(rootData,    "Expand")
        UI.Nav.Modify(rootAdv,     "Expand")
        UI.Nav.Modify(rootSet,     "Expand")
    } catch {
    }

    ; 节点映射
    UI_NavMap[nodeProfile]  := "profile"
    UI_NavMap[nodeSkills]   := "skills"
    UI_NavMap[nodePoints]   := "points"
    UI_NavMap[nodeDefault]  := "default_skill"
    UI_NavMap[nodeRot]      := "adv_rotation"
    UI_NavMap[nodeSettings] := "settings_lang"

    ; 页面注册
    UI_RegisterPage("profile",       "概览与配置", Page_Profile_Build,       Page_Profile_Layout)
    UI_RegisterPage("skills",        "技能",       Page_Skills_Build,        Page_Skills_Layout)
    UI_RegisterPage("points",        "点位",       Page_Points_Build,        Page_Points_Layout)
    UI_RegisterPage("default_skill", "默认技能",   Page_DefaultSkill_Build,  Page_DefaultSkill_Layout, Page_DefaultSkill_OnEnter)
    UI_RegisterPage("adv_rotation",  "轮换配置",   Page_Rotation_Build,      Page_Rotation_Layout,     Page_Rotation_OnEnter)

    ; settings_lang 仍为占位或后续替换
    UI_RegisterPage("settings_lang", "设置"
        , (page) => Page_Settings_StubBuild(page)
        , (rc)   => 0)

    UI.Main.Show("w980 h720")
    UI.Nav.Modify(nodeProfile, "Select")
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
        ; 分组节点被点到时，仅展开，不切换
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
    navW := 200
    UI.Nav.Move(UI.Main.MarginX, UI.Main.MarginY, navW, Max(h - UI.Main.MarginY * 2, 300))
    UI_LayoutCurrentPage()
}

Page_Settings_StubBuild(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    txt := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X, rc.Y, rc.W)
        , "设置 / 界面语言`n点击下方按钮重建界面以应用语言。")
    page.Controls.Push(txt)

    btn := UI.Main.Add("Button", Format("x{} y{} w160 h28", rc.X, rc.Y + 60), "重建界面")
    btn.OnEvent("Click", UI_RebuildMain)
    page.Controls.Push(btn)
}

UI_RebuildMain(*) {
    global UI
    try {
        if (UI.Has("Main") && UI.Main) {
            UI.Main.Destroy()
        }
    } catch {
    }
    UI_ShowMain()
}