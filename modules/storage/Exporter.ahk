; ========================== modules\storage\Exporter.ahk ==========================
#Requires AutoHotkey v2

#Include "..\zip\Minizip.ahk"

; 导出当前 profileName 到 opts["TargetZip"]
; opts: Map("TargetZip","GameName","GameScaleEnabled","HudScale","Password")
Exporter_ExportProfile(profileName, opts) {
    global App

    if (profileName = "") {
        MsgBox "未选择配置，无法导出。"
        return false
    }

    baseProfiles := ""
    try {
        baseProfiles := App["ProfilesDir"]
    } catch {
        baseProfiles := A_ScriptDir "\Profiles"
    }

    srcDir := baseProfiles "\" profileName
    if !DirExist(srcDir) {
        MsgBox "配置目录不存在，无法导出。`n" srcDir
        return false
    }

    targetZip := ""
    try {
        targetZip := opts["TargetZip"]
    } catch {
        targetZip := ""
    }
    if (targetZip = "") {
        MsgBox "请指定导出 zip 路径。"
        return false
    }

    ; 临时目录根：Exports\_tmp
    tempBase := ""
    try {
        tempBase := App["ExportDir"] "\_tmp"
    } catch {
        tempBase := A_ScriptDir "\Exports\_tmp"
    }
    try {
        DirCreate(tempBase)
    } catch {
    }

    ts := ""
    try {
        ts := FormatTime(, "yyyyMMdd_HHmmss")
    } catch {
        ts := ""
    }

    ; 用时间戳和随机数构造唯一临时目录
    rnd := Random(1000, 9999)
    tempDir := tempBase "\export_" ts "_" rnd

    try {
        DirCreate(tempDir)
    } catch {
    }

    ; 拷贝 profile 文件夹到 tempDir\profileName
    dstProfileDir := tempDir "\" profileName
    okCopy := true
    try {
        DirCopy(srcDir, dstProfileDir, true)
    } catch {
        okCopy := false
    }
    if (!okCopy) {
        try {
            Logger_Error("Exporter", "DirCopy failed", Map("src", srcDir, "dst", dstProfileDir))
        } catch {
        }
        MsgBox "复制配置目录失败，导出中止。"
        return false
    }

    ; 采集环境信息并写 manifest
    manifestPath := tempDir "\export_manifest.ini"
    Exporter_WriteManifest(manifestPath, profileName, opts)

    ; 调用 Minizip 打包
    okZip := Minizip_ZipFolder(targetZip, tempDir, Exporter_GetPassword(opts))
    if (!okZip) {
        try {
            Logger_Error("Exporter", "ZipFolder failed", Map("zip", targetZip, "tempDir", tempDir))
        } catch {
        }
        MsgBox "压缩失败，请检查 minizip 配置或查看日志。"
        return false
    }

    ; 成功后删除临时目录
    try {
        DirDelete(tempDir, true)
    } catch {
    }

    Notify("配置已导出到：`n" targetZip)
    return true
}

Exporter_GetPassword(opts) {
    pwd := ""
    if IsObject(opts) {
        try {
            if (opts.Has("Password")) {
                pwd := opts["Password"]
            }
        } catch {
            pwd := ""
        }
    }
    return pwd
}

; 写 export_manifest.ini
Exporter_WriteManifest(manifestPath, profileName, opts) {
    ; Meta
    try {
        IniWrite(1, manifestPath, "Meta", "SchemaVersion")
    } catch {
    }
    try {
        IniWrite(profileName, manifestPath, "Meta", "ProfileName")
    } catch {
    }
    expAt := ""
    try {
        expAt := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    } catch {
        expAt := ""
    }
    try {
        IniWrite(expAt, manifestPath, "Meta", "ExportedAt")
    } catch {
    }

    ; Environment
    sw := A_ScreenWidth
    sh := A_ScreenHeight
    try {
        IniWrite(sw, manifestPath, "Environment", "ScreenWidth")
    } catch {
    }
    try {
        IniWrite(sh, manifestPath, "Environment", "ScreenHeight")
    } catch {
    }

    ; DPI 与 Scale，简单使用主屏 DPI
    dpiX := 96
    dpiY := 96
    scaleX := 1.0
    scaleY := 1.0

    try {
        hdc := DllCall("user32\GetDC", "ptr", 0, "ptr")
        if (hdc) {
            LOGPIXELSX := 88
            LOGPIXELSY := 90
            dx := DllCall("gdi32\GetDeviceCaps", "ptr", hdc, "int", LOGPIXELSX, "int")
            dy := DllCall("gdi32\GetDeviceCaps", "ptr", hdc, "int", LOGPIXELSY, "int")
            DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hdc)
            if (dx > 0) {
                dpiX := dx
            }
            if (dy > 0) {
                dpiY := dy
            }
        }
    } catch {
    }

    try {
        scaleX := dpiX / 96.0
    } catch {
        scaleX := 1.0
    }
    try {
        scaleY := dpiY / 96.0
    } catch {
        scaleY := 1.0
    }

    try {
        IniWrite(dpiX, manifestPath, "Environment", "DpiX")
    } catch {
    }
    try {
        IniWrite(dpiY, manifestPath, "Environment", "DpiY")
    } catch {
    }
    try {
        IniWrite(scaleX, manifestPath, "Environment", "ScaleX")
    } catch {
    }
    try {
        IniWrite(scaleY, manifestPath, "Environment", "ScaleY")
    } catch {
    }
    try {
        IniWrite(A_OSVersion, manifestPath, "Environment", "OSVersion")
    } catch {
    }
    arch := ""
    try {
        arch := (A_PtrSize = 8) ? "x64" : "x86"
    } catch {
        arch := ""
    }
    try {
        IniWrite(arch, manifestPath, "Environment", "Arch")
    } catch {
    }

    ; Game
    gname := ""
    gscaleEnabled := 0
    ghud := 1.0
    if IsObject(opts) {
        try {
            if (opts.Has("GameName")) {
                gname := opts["GameName"]
            }
        } catch {
        }
        try {
            if (opts.Has("GameScaleEnabled")) {
                gscaleEnabled := opts["GameScaleEnabled"] ? 1 : 0
            }
        } catch {
        }
        try {
            if (opts.Has("HudScale")) {
                ghud := opts["HudScale"]
            }
        } catch {
        }
    }
    try {
        IniWrite(gname, manifestPath, "Game", "Name")
    } catch {
    }
    try {
        IniWrite(gscaleEnabled, manifestPath, "Game", "InternalScaleEnabled")
    } catch {
    }
    try {
        IniWrite(ghud, manifestPath, "Game", "HudScale")
    } catch {
    }

    ; Options
    hasPwd := 0
    if IsObject(opts) {
        try {
            if (opts.Has("Password")) {
                if (opts["Password"] != "") {
                    hasPwd := 1
                }
            }
        } catch {
            hasPwd := 0
        }
    }
    try {
        IniWrite(hasPwd, manifestPath, "Options", "HasPassword")
    } catch {
    }
}

; 解包 zip 到临时目录，并读取 manifest
; 返回 result Map: { Ok:0/1, TempDir:"", Manifest:Map() }
Exporter_UnpackToTemp(zipPath, password := "") {
    global App

    result := Map()
    result["Ok"] := 0
    result["TempDir"] := ""
    result["Manifest"] := Map()

    if (zipPath = "") {
        return result
    }
    if !FileExist(zipPath) {
        return result
    }

    tempBase := ""
    try {
        tempBase := App["ExportDir"] "\_tmp"
    } catch {
        tempBase := A_ScriptDir "\Exports\_tmp"
    }
    try {
        DirCreate(tempBase)
    } catch {
    }

    ts := ""
    try {
        ts := FormatTime(, "yyyyMMdd_HHmmss")
    } catch {
        ts := ""
    }
    rnd := Random(1000, 9999)
    tempDir := tempBase "\import_" ts "_" rnd

    try {
        DirCreate(tempDir)
    } catch {
    }

    okUnzip := Minizip_UnzipToFolder(zipPath, tempDir, password)
    if (!okUnzip) {
        ; 解压失败，删除临时目录
        try {
            DirDelete(tempDir, true)
        } catch {
        }
        return result
    }

    manifestPath := tempDir "\export_manifest.ini"
    if !FileExist(manifestPath) {
        ; 无清单，视为不合法
        try {
            Logger_Error("Exporter", "Manifest not found in tempDir", Map("tempDir", tempDir))
        } catch {
        }
        try {
            DirDelete(tempDir, true)
        } catch {
        }
        return result
    }

    manifest := Exporter_ReadManifest(manifestPath)
    result["Ok"] := 1
    result["TempDir"] := tempDir
    result["Manifest"] := manifest
    return result
}

; 读取 manifest.ini 到 Map
Exporter_ReadManifest(path) {
    m := Map()

    meta := Map()
    env := Map()
    game := Map()
    opt  := Map()

    ; Meta
    try {
        meta["SchemaVersion"] := Integer(IniRead(path, "Meta", "SchemaVersion", 1))
    } catch {
        meta["SchemaVersion"] := 1
    }
    try {
        meta["ProfileName"] := IniRead(path, "Meta", "ProfileName", "Imported")
    } catch {
        meta["ProfileName"] := "Imported"
    }
    try {
        meta["ExportedAt"] := IniRead(path, "Meta", "ExportedAt", "")
    } catch {
        meta["ExportedAt"] := ""
    }

    ; Environment
    try {
        env["ScreenWidth"] := Integer(IniRead(path, "Environment", "ScreenWidth", A_ScreenWidth))
    } catch {
        env["ScreenWidth"] := A_ScreenWidth
    }
    try {
        env["ScreenHeight"] := Integer(IniRead(path, "Environment", "ScreenHeight", A_ScreenHeight))
    } catch {
        env["ScreenHeight"] := A_ScreenHeight
    }
    try {
        env["DpiX"] := Integer(IniRead(path, "Environment", "DpiX", 96))
    } catch {
        env["DpiX"] := 96
    }
    try {
        env["DpiY"] := Integer(IniRead(path, "Environment", "DpiY", 96))
    } catch {
        env["DpiY"] := 96
    }
    try {
        env["ScaleX"] := IniRead(path, "Environment", "ScaleX", 1.0)
    } catch {
        env["ScaleX"] := 1.0
    }
    try {
        env["ScaleY"] := IniRead(path, "Environment", "ScaleY", 1.0)
    } catch {
        env["ScaleY"] := 1.0
    }
    try {
        env["OSVersion"] := IniRead(path, "Environment", "OSVersion", A_OSVersion)
    } catch {
        env["OSVersion"] := A_OSVersion
    }
    try {
        env["Arch"] := IniRead(path, "Environment", "Arch", "")
    } catch {
        env["Arch"] := ""
    }

    ; Game
    try {
        game["Name"] := IniRead(path, "Game", "Name", "")
    } catch {
        game["Name"] := ""
    }
    try {
        game["InternalScaleEnabled"] := Integer(IniRead(path, "Game", "InternalScaleEnabled", 0))
    } catch {
        game["InternalScaleEnabled"] := 0
    }
    try {
        game["HudScale"] := IniRead(path, "Game", "HudScale", 1.0)
    } catch {
        game["HudScale"] := 1.0
    }

    ; Options
    try {
        opt["HasPassword"] := Integer(IniRead(path, "Options", "HasPassword", 0))
    } catch {
        opt["HasPassword"] := 0
    }

    m["Meta"] := meta
    m["Environment"] := env
    m["Game"] := game
    m["Options"] := opt
    return m
}