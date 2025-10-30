#Requires AutoHotkey v2
; “设置”页：语言切换

UI_Page_Settings_Build() {
    global UI
    UI.LblLang := UI.Main.Add("Text", "x12 y12 w120", T("label.language","界面语言："))
    UI.DdLang  := UI.Main.Add("DropDownList", "x+6 w220")
    packs := Lang_ListPackages()
    names := []
    for _, p in packs
        names.Push(p.Name " (" p.Code ")")
    if names.Length
        UI.DdLang.Add(names)

    curCode := gLang.Has("Code") ? gLang["Code"] : "zh-CN"
    sel := 1
    for i, p in packs
        if (p.Code = curCode) {
            sel := i
            break
        }
    UI.DdLang.Value := sel

    UI.BtnApplyLang := UI.Main.Add("Button", "xm y+10 w120", T("btn.applyLang","应用语言"))
    UI.BtnOpenLang  := UI.Main.Add("Button", "x+8 w140", T("btn.openLangDir","打开语言目录"))
    UI.LblNote      := UI.Main.Add("Text", "xm y+8", T("label.noteRestart","应用后将重建界面"))
    UI.BtnApplyLang.OnEvent("Click", (*) => UI_Page_Settings_ApplyLang(UI.DdLang, packs))
    UI.BtnOpenLang.OnEvent("Click", (*) => Run(A_ScriptDir "\Languages"))
}

UI_Page_Settings_ApplyLang(dd, packs) {
    global UI
    idx := dd.Value
    if (idx < 1 || idx > packs.Length)
        return
    code := packs[idx].Code
    Lang_SetLanguage(code)
    AppConfig_Set("Language", code)
    AppConfig_Save()
    try UI.Main.Destroy()
    UI_ShowMain()
    Notify("Language: " code)
}