; ==================== modules\ui\pages\tools\Page_Tools_IO.ahk ====================
#Requires AutoHotkey v2

; 依赖：Exporter_ExportProfile / Exporter_UnpackToTemp
; 以及后续将实现的 ImportWizard_Begin(tempDir, manifest)

Page_ToolsIO_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    margin := 8
    halfH := rc.H // 2 - margin * 2

    ; 导出区域 GroupBox
    UI.GB_Export := UI.Main.Add("GroupBox"
        , Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, halfH)
        , "导出配置")
    page.Controls.Push(UI.GB_Export)

    xLabel := rc.X + 16
    yCur   := rc.Y + 32
    labelW := 100
    editW  := 260

    ; 当前配置
    UI.TxtCurProfile := UI.Main.Add("Text"
        , Format("x{} y{} w{}", xLabel, yCur + 3, labelW + 80)
        , "")
    page.Controls.Push(UI.TxtCurProfile)

    yCur += 32
    UI.LblGameName := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", xLabel, yCur + 3, labelW)
        , "游戏名称：")
    page.Controls.Push(UI.LblGameName)

    UI.EdGameName := UI.Main.Add("Edit"
        , Format("x{} y{} w{}", xLabel + labelW + 8, yCur, editW)
        , "")
    page.Controls.Push(UI.EdGameName)

    yCur += 32
    UI.LblGameScale := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", xLabel, yCur + 3, labelW)
        , "游戏内缩放：")
    page.Controls.Push(UI.LblGameScale)

    UI.ChkGameScale := UI.Main.Add("CheckBox"
        , Format("x{} y{} w{}", xLabel + labelW + 8, yCur, editW)
        , "开启")
    page.Controls.Push(UI.ChkGameScale)

    yCur += 32
    UI.LblHudScale := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", xLabel, yCur + 3, labelW)
        , "HUD 缩放：")
    page.Controls.Push(UI.LblHudScale)

    UI.EdHudScale := UI.Main.Add("Edit"
        , Format("x{} y{} w{} Number", xLabel + labelW + 8, yCur, editW)
        , "1.0")
    page.Controls.Push(UI.EdHudScale)

    yCur += 32
    UI.LblZipPwd := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", xLabel, yCur + 3, labelW)
        , "ZIP 密码：")
    page.Controls.Push(UI.LblZipPwd)

    UI.EdZipPwd := UI.Main.Add("Edit"
        , Format("x{} y{} w{} Password", xLabel + labelW + 8, yCur, editW)
        , "")
    page.Controls.Push(UI.EdZipPwd)

    yCur += 32
    UI.LblExportPath := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", xLabel, yCur + 3, labelW)
        , "导出路径：")
    page.Controls.Push(UI.LblExportPath)

    UI.EdExportPath := UI.Main.Add("Edit"
        , Format("x{} y{} w{}",
            xLabel + labelW + 8, yCur, editW + 160)
        , "")
    page.Controls.Push(UI.EdExportPath)

    UI.BtnBrowseExport := UI.Main.Add("Button"
        , "x+8 w80 h24"
        , "浏览...")
    page.Controls.Push(UI.BtnBrowseExport)

    yCur += 40
    UI.BtnDoExport := UI.Main.Add("Button"
        , Format("x{} y{} w120 h30", xLabel + labelW + 8, yCur)
        , "开始导出")
    page.Controls.Push(UI.BtnDoExport)

    ; 导入区域 GroupBox
    gy2 := rc.Y + halfH + margin * 2
    UI.GB_Import := UI.Main.Add("GroupBox"
        , Format("x{} y{} w{} h{}", rc.X, gy2, rc.W, halfH)
        , "导入配置")
    page.Controls.Push(UI.GB_Import)

    x2 := rc.X + 16
    y2 := gy2 + 32

    UI.LblZipPath := UI.Main.Add("Text"
        , Format("x{} y{} w{} Right", x2, y2 + 3, labelW)
        , "Zip 文件：")
    page.Controls.Push(UI.LblZipPath)

    UI.EdZipPath := UI.Main.Add("Edit"
        , Format("x{} y{} w{}",
            x2 + labelW + 8, y2, editW + 160)
        , "")
    page.Controls.Push(UI.EdZipPath)

    UI.BtnBrowseZip := UI.Main.Add("Button"
        , "x+8 w80 h24"
        , "浏览...")
    page.Controls.Push(UI.BtnBrowseZip)

    y2 += 40
    UI.BtnDoImport := UI.Main.Add("Button"
        , Format("x{} y{} w120 h30", x2 + labelW + 8, y2)
        , "开始导入")
    page.Controls.Push(UI.BtnDoImport)

    ; 事件
    try {
        UI.BtnBrowseExport.OnEvent("Click", ToolsIO_OnBrowseExport)
        UI.BtnDoExport.OnEvent("Click", ToolsIO_OnExport)
        UI.BtnBrowseZip.OnEvent("Click", ToolsIO_OnBrowseZip)
        UI.BtnDoImport.OnEvent("Click", ToolsIO_OnImport)
    } catch {
    }

    ; 初始化导出路径与当前配置显示
    ToolsIO_UpdateCurrentProfile()
    ToolsIO_InitExportPath()
}

Page_ToolsIO_Layout(rc) {
    ; 简单使用 Build 中的布局，不做复杂自适应
    ToolsIO_UpdateCurrentProfile()
}

Page_ToolsIO_OnEnter(*) {
    ToolsIO_UpdateCurrentProfile()
    ToolsIO_InitExportPath()
}

ToolsIO_UpdateCurrentProfile() {
    global App, UI
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    txt := "当前配置：" (name != "" ? name : "（未选择）")
    try {
        UI.TxtCurProfile.Text := txt
    } catch {
    }
}

ToolsIO_InitExportPath() {
    global App, UI
    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        return
    }

    base := ""
    try {
        base := App["ExportDir"]
    } catch {
        base := A_ScriptDir "\Exports"
    }
    try {
        DirCreate(base)
    } catch {
    }

    ts := ""
    try {
        ts := FormatTime(, "yyyyMMdd_HHmmss")
    } catch {
        ts := ""
    }

    path := base "\" name "_" ts ".zip"
    try {
        UI.EdExportPath.Value := path
    } catch {
    }
}

ToolsIO_OnBrowseExport(*) {
    global UI
    sel := FileSelect("S16", UI.EdExportPath.Value, "选择导出位置", "Zip 文件 (*.zip)")
    if (sel = "") {
        return
    }
    try {
        UI.EdExportPath.Value := sel
    } catch {
    }
}

ToolsIO_OnExport(*) {
    global App, UI

    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置，无法导出。"
        return
    }

    target := ""
    try {
        target := UI.EdExportPath.Value
    } catch {
        target := ""
    }
    if (target = "") {
        MsgBox "请先指定导出路径。"
        return
    }

    gname := ""
    try {
        gname := UI.EdGameName.Value
    } catch {
        gname := ""
    }

    scaleOn := 0
    try {
        scaleOn := (UI.ChkGameScale.Value ? 1 : 0)
    } catch {
        scaleOn := 0
    }

    hud := 1.0
    try {
        if (UI.EdHudScale.Value != "") {
            hud := UI.EdHudScale.Value + 0  ; 简单转数值
        }
    } catch {
        hud := 1.0
    }

    pwd := ""
    try {
        pwd := UI.EdZipPwd.Value
    } catch {
        pwd := ""
    }

    opts := Map()
    opts["TargetZip"] := target
    opts["GameName"] := gname
    opts["GameScaleEnabled"] := scaleOn
    opts["HudScale"] := hud
    opts["Password"] := pwd

    ok := Exporter_ExportProfile(name, opts)
    if (!ok) {
        try {
            Logger_Warn("Exporter", "ExportProfile failed", Map("name", name, "zip", target))
        } catch {
        }
    }
}

ToolsIO_OnBrowseZip(*) {
    global UI
    sel := FileSelect("1", UI.EdZipPath.Value, "选择导入 Zip 文件", "Zip 文件 (*.zip)")
    if (sel = "") {
        return
    }
    try {
        UI.EdZipPath.Value := sel
    } catch {
    }
}

ToolsIO_OnImport(*) {
    global UI

    zipPath := ""
    try {
        zipPath := UI.EdZipPath.Value
    } catch {
        zipPath := ""
    }
    if (zipPath = "") {
        MsgBox "请先选择要导入的 Zip 文件。"
        return
    }
    if !FileExist(zipPath) {
        MsgBox "指定的 Zip 文件不存在。"
        return
    }

    ; 先尝试无密码解包
    res := Exporter_UnpackToTemp(zipPath, "")
    if (res.Has("Ok")) {
        if (res["Ok"]) {
            ; 无密码或无需密码，直接进入导入向导
            ToolsIO_StartImportWizard(res["TempDir"], res["Manifest"])
            return
        }
    }

    ; 需要密码的情况：弹出一次输入框
    ib := InputBox("请输入 Zip 密码（留空取消）：", "导入配置 - 需要密码")
    if (ib.Result = "Cancel") {
        return
    }
    pwd := Trim(ib.Value)
    if (pwd = "") {
        return
    }

    res2 := Exporter_UnpackToTemp(zipPath, pwd)
    if !(res2.Has("Ok") && res2["Ok"]) {
        MsgBox "解压失败，密码可能不正确或压缩包已损坏。"
        return
    }

    ToolsIO_StartImportWizard(res2["TempDir"], res2["Manifest"])
}

; 调用导入向导的入口（后续我们会实现 GUI_ImportWizard.ahk 中的 ImportWizard_Begin）
ToolsIO_StartImportWizard(tempDir, manifest) {
    try {
        ImportWizard_Begin(tempDir, manifest)
    } catch as e {
        try {
            Logger_Exception("Importer", e, Map("where", "ToolsIO_StartImportWizard", "tempDir", tempDir))
        } catch {
        }
        MsgBox "导入向导启动失败，请查看日志。"
    }
}