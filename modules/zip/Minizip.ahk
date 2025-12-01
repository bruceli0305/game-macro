; ========================== modules\zip\Minizip.ahk ==========================
#Requires AutoHotkey v2

; 取得 minizip.exe 路径：
; 1) 优先从 AppConfig: [General] MinizipPath
; 2) 其次：A_ScriptDir "\lib\minizip.exe"
; 3) 否则：使用 "minizip.exe"（要求已在 PATH）
Minizip_GetExePath() {
    exe := ""
    try {
        exe := AppConfig_Get("MinizipPath", "")
    } catch {
        exe := ""
    }

    if (exe != "") {
        if FileExist(exe) {
            return exe
        }
    }

    fallback := ""
    try {
        fallback := A_ScriptDir "\modules\lib\minizip.exe"
    } catch {
        fallback := ""
    }

    if (fallback != "") {
        if FileExist(fallback) {
            return fallback
        }
    }

    ; 最后退回 PATH 中的 minizip.exe
    return "minizip.exe"
}

; 压缩整个目录 rootFolder 到 zipPath
; password 可为空字符串（无密码）
Minizip_ZipFolder(zipPath, rootFolder, password := "") {
    if (zipPath = "") {
        return false
    }
    if (rootFolder = "") {
        return false
    }
    if !DirExist(rootFolder) {
        return false
    }

    exe := Minizip_GetExePath()
    if !FileExist(exe) {
        try {
            Logger_Error("Minizip", "minizip.exe not found", Map("exe", exe))
        } catch {
        }
        return false
    }

    ; 确保输出目录存在
    outDir := ""
    try {
        outDir := RegExReplace(zipPath, "(?i)\\[^\\]+$", "")
    } catch {
        outDir := ""
    }
    if (outDir != "") {
        try {
            DirCreate(outDir)
        } catch {
        }
    }

    ; 收集 rootFolder 下的所有文件（相对路径）
    files := []
    loop files, rootFolder "\*", "R" {
        rel := ""
        try {
            rel := SubStr(A_LoopFileFullPath, StrLen(rootFolder) + 2)
        } catch {
            rel := A_LoopFileName
        }
        if (rel = "") {
            continue
        }
        files.Push(rel)
    }

    if (files.Length = 0) {
        try {
            Logger_Warn("Minizip", "ZipFolder: no files", Map("root", rootFolder))
        } catch {
        }
        return false
    }

    ; 典型 4.x 用法类似：
    ;   minizip.exe -o [-p 密码] "zipPath" "file1" "file2" ...
    cmd := ""
    try {
        cmd := '"' exe '" -o'
    } catch {
        cmd := ""
    }

    if (password != "") {
        try {
            ; 结果： -p "xxx"
            cmd := cmd . ' -p "' . password . '"'
        } catch {
        }
    }

    try {
        cmd := cmd . ' "' . zipPath . '"'
    } catch {
    }

    i := 1
    while (i <= files.Length) {
        f := files[i]
        try {
            cmd := cmd . ' "' . f . '"'
        } catch {
        }
        i := i + 1
    }

    oldDir := A_WorkingDir
    try {
        SetWorkingDir(rootFolder)
    } catch {
    }

    exitCode := 0
    try {
        ; v2：RunWait 返回进程退出码
        exitCode := RunWait(cmd, , "Hide")
    } catch {
        exitCode := -1
    }

    try {
        SetWorkingDir(oldDir)
    } catch {
    }

    if (exitCode != 0) {
        try {
            Logger_Error("Minizip", "ZipFolder failed", Map("code", exitCode, "cmd", cmd))
        } catch {
        }
        return false
    }

    try {
        Logger_Info("Minizip", "ZipFolder ok", Map("zip", zipPath, "root", rootFolder))
    } catch {
    }
    return true
}

; 解压 zipPath 到 destFolder，password 可为空
Minizip_UnzipToFolder(zipPath, destFolder, password := "") {
    if (zipPath = "") {
        return false
    }
    if !FileExist(zipPath) {
        return false
    }
    if (destFolder = "") {
        return false
    }

    exe := Minizip_GetExePath()
    if !FileExist(exe) {
        try {
            Logger_Error("Minizip", "minizip.exe not found", Map("exe", exe))
        } catch {
        }
        return false
    }

    try {
        DirCreate(destFolder)
    } catch {
    }

    ; 典型 4.x：
    ;   minizip.exe -x -d "destFolder" [-p 密码] "zipPath"
    cmd := ""
    try {
        cmd := '"' exe '" -x -d "' destFolder '"'
    } catch {
        cmd := ""
    }

    if (password != "") {
        try {
            cmd := cmd . ' -p "' . password . '"'
        } catch {
        }
    }

    try {
        cmd := cmd . ' "' . zipPath . '"'
    } catch {
    }

    exitCode := 0
    try {
        exitCode := RunWait(cmd, , "Hide")
    } catch {
        exitCode := -1
    }

    if (exitCode != 0) {
        try {
            Logger_Error("Minizip", "UnzipToFolder failed", Map("code", exitCode, "cmd", cmd))
        } catch {
        }
        return false
    }

    try {
        Logger_Info("Minizip", "UnzipToFolder ok", Map("zip", zipPath, "dest", destFolder))
    } catch {
    }
    return true
}