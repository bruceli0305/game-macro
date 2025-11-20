#Requires AutoHotkey v2
;modules\logging\sinks\FileSink.ahk
FileSink_WriteLine(path, text, rotateMB := 10, keep := 5) {
    dir := ""
    try {
        dir := RegExReplace(path, "(?i)\\[^\\]+$", "")
        DirCreate(dir)
    } catch {
    }

    try {
        FileSink__RotateIfNeeded(path, rotateMB, keep)
    } catch {
    }

    line := "" text
    if !(SubStr(line, -1) = "`n") {
        line := line . "`r`n"
    }

    FileSink__AppendAtomic(path, line)
}

FileSink__AppendAtomic(path, text) {
    h := 0
    ok := 0
    bytes := 0
    buf := 0

    try {
        h := DllCall("Kernel32\CreateFileW"
            , "WStr", path
            , "UInt", 0x0004
            , "UInt", 0x0003
            , "Ptr",  0
            , "UInt", 4
            , "UInt", 0x80
            , "Ptr",  0
            , "Ptr")
        if (h = -1) {
            throw Error("CreateFileW failed")
        }

        bytes := StrPut(text, "UTF-8") - 1
        buf := Buffer(bytes, 0)
        StrPut(text, buf, "UTF-8")

        written := 0
        ok := DllCall("Kernel32\WriteFile"
            , "Ptr", h
            , "Ptr", buf.Ptr
            , "UInt", bytes
            , "UInt*", &written
            , "Ptr", 0
            , "Int")
        if (ok = 0) {
            throw Error("WriteFile failed")
        }
    } catch {
        try {
            alt := A_Temp "\app.log"
            FileAppend(text, alt, "UTF-8")
        } catch {
        }
    } finally {
        if (h && h != -1) {
            DllCall("Kernel32\CloseHandle", "Ptr", h)
        }
    }
}

FileSink__RotateIfNeeded(path, rotateMB, keep) {
    if !FileExist(path) {
        return
    }
    size := 0
    try {
        size := FileGetSize(path)
    } catch {
        size := 0
    }
    limit := rotateMB * 1024 * 1024
    if (size < limit) {
        return
    }
    FileSink__Rotate(path, keep)
}

FileSink__Rotate(base, keep) {
    i := 0
    try {
        i := keep
        while (i >= 1) {
            src := base . "." . i
            dst := base . "." . (i + 1)
            if (i = keep) {
                if FileExist(src) {
                    try {
                        FileDelete(src)
                    } catch {
                    }
                }
            } else {
                if FileExist(src) {
                    try {
                        FileMove(src, dst, true)
                    } catch {
                    }
                }
            }
            i := i - 1
        }
        if FileExist(base) {
            try {
                FileMove(base, base . ".1", true)
            } catch {
            }
        }
    } catch {
    }
}