#Requires AutoHotkey v2
;Page_Settings_About.ahk
; 设置 → 关于（正式页）
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：SA_

Page_Settings_About_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 分组：关于与环境
    UI.SA_GB := UI.Main.Add("GroupBox", Format("x{} y{} w{} h270", rc.X, rc.Y, rc.W), T("about.title","关于与环境"))
    page.Controls.Push(UI.SA_GB)

    UI.SA_Info := UI.Main.Add("Edit", Format("x{} y{} w{} r10 ReadOnly", rc.X + 12, rc.Y + 26, rc.W - 24))
    page.Controls.Push(UI.SA_Info)

    ; 按钮行1：目录
    y1 := rc.Y + 26 + 10*22 + 12
    UI.SA_BtnLogs     := UI.Main.Add("Button", Format("x{} y{} w120 h26", rc.X + 12, y1), T("about.openLogs","打开日志目录"))
    UI.SA_BtnProfiles := UI.Main.Add("Button", "x+8 w120 h26", T("about.openProfiles","打开配置目录"))
    UI.SA_BtnExports  := UI.Main.Add("Button", "x+8 w120 h26", T("about.openExports","打开导出目录"))
    UI.SA_BtnLangDir  := UI.Main.Add("Button", "x+8 w120 h26", T("about.openLangDir","打开语言目录"))
    page.Controls.Push(UI.SA_BtnLogs)
    page.Controls.Push(UI.SA_BtnProfiles)
    page.Controls.Push(UI.SA_BtnExports)
    page.Controls.Push(UI.SA_BtnLangDir)

    ; 按钮行2：日志与依赖
    y2 := y1 + 34
    UI.SA_BtnNative := UI.Main.Add("Button", Format("x{} y{} w150 h26", rc.X + 12, y2), T("about.openNative","打开 DXGI 原生日志"))
    UI.SA_BtnHost   := UI.Main.Add("Button", "x+8 w150 h26", T("about.openHost","打开 WorkerHost 位置"))
    UI.SA_BtnGitHub := UI.Main.Add("Button", "x+8 w150 h26", T("about.openGitHub","打开 GitHub 项目"))
    UI.SA_BtnRefresh:= UI.Main.Add("Button", "x+8 w100 h26", T("btn.refresh","刷新"))
    page.Controls.Push(UI.SA_BtnNative)
    page.Controls.Push(UI.SA_BtnHost)
    page.Controls.Push(UI.SA_BtnGitHub)
    page.Controls.Push(UI.SA_BtnRefresh)

    ; 事件
    UI.SA_BtnLogs.OnEvent("Click", SettingsAbout_OnOpenLogs)
    UI.SA_BtnProfiles.OnEvent("Click", SettingsAbout_OnOpenProfiles)
    UI.SA_BtnExports.OnEvent("Click", SettingsAbout_OnOpenExports)
    UI.SA_BtnLangDir.OnEvent("Click", SettingsAbout_OnOpenLangDir)
    UI.SA_BtnNative.OnEvent("Click", SettingsAbout_OnOpenNativeLog)
    UI.SA_BtnHost.OnEvent("Click", SettingsAbout_OnOpenWorkerHost)
    UI.SA_BtnGitHub.OnEvent("Click", SettingsAbout_OnOpenGitHub)
    UI.SA_BtnRefresh.OnEvent("Click", SettingsAbout_OnRefresh)

    ; 初次刷新
    SettingsAbout_OnRefresh()
}

Page_Settings_About_Layout(rc) {
    try {
        UI.SA_GB.Move(rc.X, rc.Y, rc.W)
        UI.SA_Info.Move(rc.X + 12, rc.Y + 26, rc.W - 24)

        y1 := rc.Y + 26 + 10*22 + 12
        UI.SA_BtnLogs.Move(rc.X + 12, y1)
        UI.SA_BtnProfiles.Move(, y1)
        UI.SA_BtnExports.Move(, y1)
        UI.SA_BtnLangDir.Move(, y1)

        y2 := y1 + 34
        UI.SA_BtnNative.Move(rc.X + 12, y2)
        UI.SA_BtnHost.Move(, y2)
        UI.SA_BtnGitHub.Move(, y2)
        UI.SA_BtnRefresh.Move(, y2)
    } catch {
    }
}

Page_Settings_About_OnEnter(*) {
    SettingsAbout_OnRefresh()
}

; ====== 刷新与信息构造 ======

SettingsAbout_OnRefresh(*) {
    text := SettingsAbout_BuildSummary()
    try {
        UI.SA_Info.Value := text
    } catch {
    }
}

SettingsAbout_BuildSummary() {
    global App
    sum := ""

    ; 版本与路径
    ver := "unknown"
    try {
        if (IsSet(App) && App.Has("Version")) {
            ver := App["Version"]
        } else {
            ver := "v0"
        }
    } catch {
        ver := "unknown"
    }
    root := A_ScriptDir
    logs := A_ScriptDir "\Logs"
    profiles := ""
    exports := A_ScriptDir "\Exports"
    langs := A_ScriptDir "\Languages"

    try {
        if !(IsSet(App) && App.Has("ProfilesDir")) {
            App := IsSet(App) ? App : Map()
            App["ProfilesDir"] := A_ScriptDir "\Profiles"
        }
        profiles := App["ProfilesDir"]
    } catch {
        profiles := A_ScriptDir "\Profiles"
    }

    ; 环境
    arch := ""
    try {
        arch := (A_PtrSize = 8) ? "x64" : "x86"
    } catch {
        arch := "?"
    }
    os := ""
    try {
        os := A_OSVersion
    } catch {
        os := "Windows"
    }
    admin := ""
    try {
        admin := A_IsAdmin ? "Admin" : "User"
    } catch {
        admin := "?"
    }

    ; DXGI 概要
    dx_en := 0, dx_ready := 0, outIdx := 0, monName := "", fps := 0
    rect := ""
    try {
        dx_en := gDX.Enabled ? 1 : 0
    } catch {
        dx_en := 0
    }
    try {
        dx_ready := DX_IsReady()
    } catch {
        dx_ready := 0
    }
    try {
        outIdx := gDX.OutIdx
        monName := gDX.MonName
        fps := gDX.FPS
        rect := "(" gDX.L "," gDX.T ") - (" gDX.R "," gDX.B ")"
    } catch {
        rect := "-"
    }

    ; WorkerHost 存在性
    hostPath := SettingsAbout_FindWorkerHost()
    hostShown := hostPath != "" ? hostPath : "(未找到)"

    sum .= "版本: " ver "`r`n"
    sum .= "架构: " arch "    权限: " admin "    OS: " os "`r`n"
    sum .= "脚本目录: " root "`r`n"
    sum .= "Profiles: " profiles "`r`n"
    sum .= "Exports:  " exports  "`r`n"
    sum .= "Logs:     " logs     "`r`n"
    sum .= "Languages:" langs    "`r`n"
    sum .= "GitHub:   https://github.com/bruceli0305/game-macro" "`r`n"
    sum .= "`r`n"
    sum .= "DXGI: Enabled=" dx_en " Ready=" dx_ready " FPS=" fps "`r`n"
    sum .= "OutIdx: " outIdx "  Name: " monName "  Rect: " rect "`r`n"
    sum .= "WorkerHost: " hostShown "`r`n"

    return sum
}

SettingsAbout_FindWorkerHost() {
    ; 返回实际存在的 WorkerHost 路径（优先 exe）
    candidates := [
        A_ScriptDir "\modules\workers\WorkerHost.exe"
      , A_ScriptDir "\modules\WorkerHost.exe"
      , A_ScriptDir "\WorkerHost.exe"
      , A_ScriptDir "\modules\workers\WorkerHost.ahk"
      , A_ScriptDir "\modules\WorkerHost.ahk"
      , A_ScriptDir "\WorkerHost.ahk"
    ]
    for _, p in candidates {
        if FileExist(p) {
            return p
        }
    }
    return ""
}

; ====== 打开目录与文件 ======

SettingsAbout_OnOpenLogs(*) {
    dir := A_ScriptDir "\Logs"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox T("about.failOpen","无法打开目录：") dir
    }
}

SettingsAbout_OnOpenProfiles(*) {
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
        MsgBox T("about.failOpen","无法打开目录：") dir
    }
}

SettingsAbout_OnOpenExports(*) {
    dir := A_ScriptDir "\Exports"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox T("about.failOpen","无法打开目录：") dir
    }
}

SettingsAbout_OnOpenLangDir(*) {
    dir := A_ScriptDir "\Languages"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox T("about.failOpen","无法打开目录：") dir
    }
}

SettingsAbout_OnOpenNativeLog(*) {
    path := ""
    try {
        path := A_Temp "\dxgi_dup_native.log"
    } catch {
        path := ""
    }
    if (path = "") {
        return
    }
    try {
        Run path
    } catch {
        MsgBox T("about.failOpen","无法打开文件：") path
    }
}

SettingsAbout_OnOpenWorkerHost(*) {
    path := SettingsAbout_FindWorkerHost()
    if (path = "") {
        MsgBox "未找到 WorkerHost（请确认 modules\\workers\\WorkerHost.exe 是否存在）。"
        return
    }
    dir := ""
    try {
        dir := RegExReplace(path, "\\[^\\]+$", "")
    } catch {
        dir := A_ScriptDir
    }
    try {
        Run dir
    } catch {
        MsgBox T("about.failOpen","无法打开目录：") dir
    }
}

SettingsAbout_OnOpenGitHub(*) {
    ; 打开GitHub项目页面
    githubUrl := "https://github.com/bruceli0305/game-macro"
    try {
        Run githubUrl
    } catch {
        MsgBox "无法打开浏览器访问GitHub项目页面：" githubUrl
    }
}