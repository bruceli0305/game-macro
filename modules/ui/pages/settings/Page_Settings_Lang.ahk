#Requires AutoHotkey v2
;Page_Settings_Lang.ahk
; 设置 → 界面与语言（正式页，替换占位）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：SL_

global UI_SL_Packs := []  ; [{Code,Name}], 与下拉索引对应

Page_Settings_Lang_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 分组
    UI.SL_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h180", rc.X, rc.Y, rc.W), T("set.lang.title","界面与语言"))
    page.Controls.Push(UI.SL_GB)

    ; 行1：下拉 + 应用
    x0 := rc.X + 12
    y0 := rc.Y + 26

    UI.SL_Lang := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y0 + 4), T("label.language","界面语言："))
    page.Controls.Push(UI.SL_Lang)

    UI.SL_Dd := UI.Main.Add("DropDownList", "x+6 w280")
    page.Controls.Push(UI.SL_Dd)

    UI.SL_BtnApply := UI.Main.Add("Button", "x+8 w120 h26", T("btn.applyLang","应用语言"))
    page.Controls.Push(UI.SL_BtnApply)

    ; 行2：操作按钮
    y1 := y0 + 40
    UI.SL_BtnOpenDir := UI.Main.Add("Button", Format("x{} y{} w140 h26", x0, y1), T("btn.openLangDir","打开语言目录"))
    page.Controls.Push(UI.SL_BtnOpenDir)

    UI.SL_BtnRefresh := UI.Main.Add("Button", "x+8 w100 h26", T("btn.refresh","刷新"))
    page.Controls.Push(UI.SL_BtnRefresh)

    ; 行3：说明
    y2 := y1 + 40
    note := T("label.noteRestart","应用后将重建界面以生效（窗口会刷新）。")
    UI.SL_Note := UI.Main.Add("Text", Format("x{} y{} w{}", x0, y2, rc.W - 24), note)
    page.Controls.Push(UI.SL_Note)

    ; 事件
    UI.SL_BtnApply.OnEvent("Click", SettingsLang_OnApply)
    UI.SL_BtnOpenDir.OnEvent("Click", SettingsLang_OnOpenDir)
    UI.SL_BtnRefresh.OnEvent("Click", SettingsLang_OnRefresh)

    ; 初次载入
    SettingsLang_RefreshList()
}

Page_Settings_Lang_Layout(rc) {
    try {
        UI.SL_GB.Move(rc.X, rc.Y, rc.W)
        ; 其余控件采用相对布局，构建时已放置到合适位置，此处无需每次移动
    } catch {
    }
}

Page_Settings_Lang_OnEnter(*) {
    SettingsLang_RefreshList()
}

; ====== 数据与事件 ======

SettingsLang_RefreshList() {
    global UI, UI_SL_Packs

    UI_SL_Packs := []

    ; 列出语言包
    packs := []
    try {
        packs := Lang_ListPackages()
    } catch {
        packs := []
    }

    ; 填充下拉
    try {
        UI.SL_Dd.Delete()
    } catch {
    }

    shown := []
    if (packs.Length > 0) {
        i := 0
        for _, p in packs {
            shown.Push(p.Name " (" p.Code ")")
            i += 1
            UI_SL_Packs.Push({ Code: p.Code, Name: p.Name })
        }
        try {
            UI.SL_Dd.Add(shown)
        } catch {
        }
    } else {
        ; 兜底
        UI_SL_Packs := [{ Code:"zh-CN", Name:"简体中文" }, { Code:"en-US", Name:"English" }]
        shown := ["简体中文 (zh-CN)", "English (en-US)"]
        try {
            UI.SL_Dd.Add(shown)
        } catch {
        }
    }

    ; 选择当前语言
    cur := "zh-CN"
    try {
        if (IsSet(gLang) && gLang.Has("Code")) {
            cur := gLang["Code"]
        }
    } catch {
        cur := "zh-CN"
    }

    sel := 1
    idx := 0
    for _, item in UI_SL_Packs {
        idx += 1
        if (item.Code = cur) {
            sel := idx
            break
        }
    }
    try {
        UI.SL_Dd.Value := sel
    } catch {
    }
}

SettingsLang_OnApply(*) {
    global UI, UI_SL_Packs

    idx := 0
    try {
        idx := UI.SL_Dd.Value
    } catch {
        idx := 0
    }
    if (idx < 1 or idx > UI_SL_Packs.Length) {
        MsgBox T("msg.selectLang","请选择一个语言包。")
        return
    }

    code := UI_SL_Packs[idx].Code

    ; 设置语言并保存到 AppConfig
    try Lang_SetLanguage(code)
    try {
        AppConfig_Set("Language", code)
        AppConfig_Save()
    }

    Notify(T("msg.langApplied","语言已应用，界面将重建。"))

    ; 不再销毁主窗/新建窗口，改为在当前窗口内重建页面
    ; 用 SetTimer 延后执行，避免在当前按钮事件内销毁控件
    SetTimer(SettingsLang_DoRelocalize, -1)
}

SettingsLang_DoRelocalize() {
    try {
        UI_RelocalizeInPlace()
    } catch {
        ; 若极端情况下失败，再回退到彻底重建（可选）
        ; UI_RebuildMain()
    }
}

SettingsLang_OnOpenDir(*) {
    dir := ""
    try {
        dir := A_ScriptDir "\Languages"
        DirCreate(dir)
    } catch {
        dir := A_ScriptDir "\Languages"
    }
    try {
        Run dir
    } catch {
        MsgBox T("msg.openDirFail","无法打开目录：") dir
    }
}

SettingsLang_OnRefresh(*) {
    SettingsLang_RefreshList()
}