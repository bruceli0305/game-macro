#Requires AutoHotkey v2
;Page_Tools_IO.ahk
; 工具 → 导入/导出
; 严格块结构的 if/try/catch，不使用单行形式
; 控件前缀：TIO_

Page_ToolsIO_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 分组：导入/导出
    UI.TIO_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h200", rc.X, rc.Y, rc.W), "导入 / 导出")
    page.Controls.Push(UI.TIO_GB)

    ; 说明
    msg := ""
    msg .= "说明：" . "`r`n"
    msg .= "• 导出当前配置为可分发包（包含脚本与配置、WorkerHost 可执行文件 视部署而定）。" . "`r`n"
    msg .= "• 导入可将 .ini 复制到 Profiles 目录后生效；导入后可在“概览与配置”页选择该新配置。" . "`r`n"
    UI.TIO_Tip := UI.Main.Add("Text", Format("x{} y{} w{}", rc.X + 12, rc.Y + 26, rc.W - 24), msg)
    page.Controls.Push(UI.TIO_Tip)

    ; 行：按钮
    yb := rc.Y + 26 + 80
    UI.TIO_BtnExport := UI.Main.Add("Button", Format("x{} y{} w150 h28", rc.X + 12, yb), "导出当前配置")
    page.Controls.Push(UI.TIO_BtnExport)

    UI.TIO_BtnOpenExports := UI.Main.Add("Button", "x+8 w120 h28", "打开导出目录")
    page.Controls.Push(UI.TIO_BtnOpenExports)

    UI.TIO_BtnOpenProfiles := UI.Main.Add("Button", "x+8 w120 h28", "打开配置目录")
    page.Controls.Push(UI.TIO_BtnOpenProfiles)

    UI.TIO_BtnImport := UI.Main.Add("Button", "x+8 w170 h28", "从 .ini 导入为新配置")
    page.Controls.Push(UI.TIO_BtnImport)

    ; 事件
    UI.TIO_BtnExport.OnEvent("Click", ToolsIO_OnExport)
    UI.TIO_BtnOpenExports.OnEvent("Click", ToolsIO_OnOpenExports)
    UI.TIO_BtnOpenProfiles.OnEvent("Click", ToolsIO_OnOpenProfiles)
    UI.TIO_BtnImport.OnEvent("Click", ToolsIO_OnImportIni)
}

Page_ToolsIO_Layout(rc) {
    try {
        UI.TIO_GB.Move(rc.X, rc.Y, rc.W)
        UI.TIO_Tip.Move(rc.X + 12, rc.Y + 26, rc.W - 24)
        ; 按钮横向布局，保持初始创建的相对位置
    } catch {
    }
}

; ============== 事件实现 ==============

ToolsIO_OnExport(*) {
    global App
    cur := ""
    try {
        if (IsSet(App) && App.Has("CurrentProfile")) {
            cur := App["CurrentProfile"]
        }
    } catch {
        cur := ""
    }
    if (cur = "") {
        MsgBox "未选择配置，无法导出。请先在“概览与配置”页选择或创建一个配置。"
        return
    }
    try {
        Exporter_ExportProfile(cur)
    } catch as e {
        MsgBox "导出失败：" e.Message
    }
}

ToolsIO_OnOpenExports(*) {
    dir := A_ScriptDir "\Exports"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox "无法打开目录：" dir
    }
}

ToolsIO_OnOpenProfiles(*) {
    global App
    dir := ""
    try {
        if !(IsSet(App) && App.Has("ProfilesDir")) {
            App := IsSet(App) ? App : Map()
            App["ProfilesDir"] := A_ScriptDir "\Profiles"
        }
        dir := App["ProfilesDir"]
        DirCreate(dir)
    } catch {
        dir := A_ScriptDir "\Profiles"
    }
    try {
        Run dir
    } catch {
        MsgBox "无法打开目录：" dir
    }
}

ToolsIO_OnImportIni(*) {
    global App

    ; 选择 .ini 文件
    path := ""
    try {
        ; v2 签名：FileSelect(Options?, RootDir?, Prompt?, Filter?)
        path := FileSelect("", A_ScriptDir, "选择 .ini 文件", "Ini (*.ini)")
    } catch {
        path := ""
    }
    if (path = "") {
        return
    }

    ; 建议的新名称：基于文件名（不含扩展名）
    base := ""
    try {
        base := RegExReplace(path, "i)^.*\\", "")
        base := RegExReplace(base, "\.ini$", "")
    } catch {
        base := "NewProfile"
    }

    ; 询问名称
    newName := ""
    try {
        ib := InputBox("导入为新配置名称：", "导入 .ini 为配置", base)
        if (ib.Result = "Cancel") {
            return
        }
        newName := Trim(ib.Value)
    } catch {
        newName := base
    }
    if (newName = "") {
        MsgBox "名称不可为空。"
        return
    }

    ; 复制到 Profiles 目录
    profDir := ""
    try {
        if !(IsSet(App) && App.Has("ProfilesDir")) {
            App := IsSet(App) ? App : Map()
            App["ProfilesDir"] := A_ScriptDir "\Profiles"
        }
        profDir := App["ProfilesDir"]
        DirCreate(profDir)
    } catch {
        profDir := A_ScriptDir "\Profiles"
    }

    dest := profDir "\" newName ".ini"
    if FileExist(dest) {
        ans := MsgBox("目标已存在，是否覆盖？`r`n" dest, , "YesNo")
        if (ans != "Yes") {
            return
        }
    }
    ok := true
    try {
        FileCopy path, dest, true
    } catch as e {
        ok := false
        MsgBox "导入失败：" e.Message
    }
    if (!ok) {
        return
    }

    ; 优先尝试：若“概览与配置”页的强力刷新函数存在则调用
    did := 0
    try {
        Profile_RefreshAll_Strong()
        did := 1
    } catch {
        did := 0
    }

    ; 若页面尚未构建或函数不可用，则回退：只更新 App 状态
    if (did = 0) {
        try {
            App["CurrentProfile"] := newName
            App["ProfileData"] := Storage_LoadProfile(newName)
        } catch {
        }
    }

    Notify("已导入为配置：" newName)
}