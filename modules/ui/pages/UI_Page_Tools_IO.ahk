#Requires AutoHotkey v2

; 工具：导入/导出
; 前缀：TIO_

Page_ToolsIO_Build(page) {
    global UI, App
    rc := UI_GetPageRect()
    page.Controls := []

    ; 导出
    UI.TIO_GB_Exp := UI.Main.Add("GroupBox", Format("x{} y{} w{} h110", rc.X, rc.Y, rc.W), "导出")
    page.Controls.Push(UI.TIO_GB_Exp)

    curName := ""
    try {
        curName := App["CurrentProfile"]
    } catch {
        curName := ""
    }
    UI.TIO_L_Exp := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, rc.Y + 26, rc.W - 24)
        , "当前配置：" curName)
    page.Controls.Push(UI.TIO_L_Exp)

    UI.TIO_BtnExport := UI.Main.Add("Button", Format("x{} y{} w140 h28", rc.X + 12, rc.Y + 60), "导出当前配置")
    page.Controls.Push(UI.TIO_BtnExport)

    UI.TIO_BtnOpenExports := UI.Main.Add("Button", "x+8 w120 h28", "打开 Exports")
    page.Controls.Push(UI.TIO_BtnOpenExports)
    UI.TIO_BtnOpenProfiles := UI.Main.Add("Button", "x+8 w120 h28", "打开 Profiles")
    page.Controls.Push(UI.TIO_BtnOpenProfiles)

    ; 导入
    y2 := rc.Y + 120
    UI.TIO_GB_Imp := UI.Main.Add("GroupBox", Format("x{} y{} w{} h120", rc.X, y2, rc.W), "导入")
    page.Controls.Push(UI.TIO_GB_Imp)

    UI.TIO_L_Imp := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, y2 + 26, rc.W - 24)
        , "导入一个 .ini 为新配置（将复制到 Profiles 目录）")
    page.Controls.Push(UI.TIO_L_Imp)

    UI.TIO_BtnImport := UI.Main.Add("Button", Format("x{} y{} w140 h28", rc.X + 12, y2 + 60), "选择文件导入")
    page.Controls.Push(UI.TIO_BtnImport)

    ; 事件
    UI.TIO_BtnExport.OnEvent("Click", TIO_OnExport)
    UI.TIO_BtnOpenExports.OnEvent("Click", TIO_OnOpenExports)
    UI.TIO_BtnOpenProfiles.OnEvent("Click", TIO_OnOpenProfiles)
    UI.TIO_BtnImport.OnEvent("Click", TIO_OnImport)

    TIO_RefreshHeader()
}

Page_ToolsIO_Layout(rc) {
    try {
        UI.TIO_GB_Exp.Move(rc.X, rc.Y, rc.W)
        UI.TIO_GB_Imp.Move(rc.X, rc.Y + 120, rc.W)
    } catch {
    }
}

Page_ToolsIO_OnEnter(*) {
    TIO_RefreshHeader()
}

TIO_RefreshHeader() {
    global UI, App
    try {
        UI.TIO_L_Exp.Text := "当前配置：" App["CurrentProfile"]
    } catch {
    }
}

TIO_OnExport(*) {
    global App
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        Notify("没有选中的配置，无法导出")
        return
    }
    try {
        Exporter_ExportProfile(name)
    } catch {
        Notify("导出失败")
    }
}

TIO_OnOpenExports(*) {
    global App
    dir := ""
    try {
        dir := App["ExportDir"]
    } catch {
        dir := A_ScriptDir "\Exports"
    }
    Run(dir)
}

TIO_OnOpenProfiles(*) {
    global App
    dir := ""
    try {
        dir := App["ProfilesDir"]
    } catch {
        dir := A_ScriptDir "\Profiles"
    }
    Run(dir)
}

TIO_OnImport(*) {
    global App, UI

    sel := ""
    try {
        sel := FileSelect(3, A_Desktop, "选择要导入的配置 .ini", "配置文件 (*.ini)")
    } catch {
        sel := ""
    }
    if (sel = "") {
        return
    }

    base := ""
    try {
        base := RegExReplace(sel, ".*\\", "")
        base := RegExReplace(base, "\.ini$", "")
    } catch {
        base := "Imported"
    }

    nameBox := InputBox("为该配置取一个名称：", "导入配置", base)
    if (nameBox.Result != "OK") {
        return
    }
    newName := Trim(nameBox.Value)
    if (newName = "") {
        Notify("名称不可为空")
        return
    }

    target := ""
    dir := ""
    try {
        dir := App["ProfilesDir"]
    } catch {
        dir := A_ScriptDir "\Profiles"
    }
    target := dir "\" newName ".ini"

    if FileExist(target) {
        yesNo := MsgBox("已存在同名配置，是否覆盖？", "确认", "YesNo")
        if (yesNo != "Yes") {
            return
        }
    }

    ok := false
    try {
        FileCopy(sel, target, true)
        ok := true
    } catch {
        ok := false
    }

    if (ok) {
        ; 刷新列表并切换到新配置
        try {
            Profile_RefreshAll_Strong()
        } catch {
        }
        try {
            Profile_SwitchProfile_Strong(newName)
        } catch {
        }
        Notify("导入成功：" newName)
    } else {
        Notify("导入失败")
    }
}