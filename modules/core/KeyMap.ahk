#Requires AutoHotkey v2

; =============================
; KeyMap.ahk
; 纯映射模块：Key 字符串 → HID 键码
; 不依赖 KeyOut / DLL / WorkerHost
; =============================

KeyMap_ResolveKey(key)
{
    info := Map()
    info["CanQmk"] := false
    info["HidCode"] := 0
    info["Reason"] := ""

    s := Trim(key)
    if (s = "")
    {
        info["Reason"] := "Empty"
        return info
    }

    ; 复杂 AHK 语法（含组合/特殊格式）直接标记为不能 QMK
    if (RegExMatch(s, "[\{\}\^\!\+\#]"))
    {
        info["Reason"] := "ComplexSyntax"
        return info
    }

    ; 鼠标键
    mouseRe := "i)^(LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight)$"
    if (RegExMatch(s, mouseRe))
    {
        info["Reason"] := "Mouse"
        return info
    }

    ; 媒体/浏览器键
    mediaRe := "i)^(Volume_(Up|Down|Mute)|Media_(Next|Prev|Play_Pause|Stop)|Browser_(Back|Forward|Home|Refresh|Stop|Search|Favorites))$"
    if (RegExMatch(s, mediaRe))
    {
        info["Reason"] := "MediaOrBrowser"
        return info
    }

    code := 0

    if (StrLen(s) = 1)
    {
        code := KeyMap_MapCharToHid(s)
    }
    else
    {
        code := KeyMap_MapNamedKeyToHid(s)
    }

    if (code > 0 && code < 256)
    {
        info["CanQmk"] := true
        info["HidCode"] := code
        info["Reason"] := "OK"
    }
    else
    {
        info["CanQmk"] := false
        info["HidCode"] := 0
        info["Reason"] := "UnknownKeyName"
    }

    return info
}

KeyMap_MapCharToHid(ch)
{
    static inited := false
    static digitMap := Map()
    static punctMap := Map()

    if (!inited)
    {
        ; 数字行 1–0
        digitMap["1"] := 0x1E
        digitMap["2"] := 0x1F
        digitMap["3"] := 0x20
        digitMap["4"] := 0x21
        digitMap["5"] := 0x22
        digitMap["6"] := 0x23
        digitMap["7"] := 0x24
        digitMap["8"] := 0x25
        digitMap["9"] := 0x26
        digitMap["0"] := 0x27

        ; 标点符号（US 布局）
        punctMap["-"] := 0x2D
        punctMap["="] := 0x2E
        punctMap["["] := 0x2F
        punctMap["]"] := 0x30
        punctMap["\\"] := 0x31
        punctMap[";"] := 0x33
        punctMap["'"] := 0x34
        key := Chr(0x60)     ; 反引号 `
        punctMap[key] := 0x35
        punctMap[","] := 0x36
        punctMap["."] := 0x37
        punctMap["/"] := 0x38

        inited := true
    }

    ; 字母 A–Z
    u := StrUpper(ch)
    c := Ord(u)
    if (c >= Ord("A") && c <= Ord("Z"))
    {
        return 0x04 + (c - Ord("A"))
    }

    ; 数字行
    if (digitMap.Has(ch))
    {
        return digitMap[ch]
    }

    ; 标点符号
    if (punctMap.Has(ch))
    {
        return punctMap[ch]
    }

    return 0
}

KeyMap_MapNamedKeyToHid(name)
{
    static inited := false
    static namedMap := Map()

    if (!inited)
    {
        ; 基本控制键
        namedMap["ENTER"] := 0x28
        namedMap["RETURN"] := 0x28
        namedMap["ESC"] := 0x29
        namedMap["ESCAPE"] := 0x29
        namedMap["BACKSPACE"] := 0x2A
        namedMap["BS"] := 0x2A
        namedMap["TAB"] := 0x2B
        namedMap["SPACE"] := 0x2C

        ; 导航/编辑
        namedMap["DELETE"] := 0x4C
        namedMap["DEL"] := 0x4C
        namedMap["INSERT"] := 0x49
        namedMap["INS"] := 0x49
        namedMap["HOME"] := 0x4A
        namedMap["END"] := 0x4D
        namedMap["PGUP"] := 0x4B
        namedMap["PAGEUP"] := 0x4B
        namedMap["PGDN"] := 0x4E
        namedMap["PAGEDOWN"] := 0x4E
        namedMap["UP"] := 0x52
        namedMap["DOWN"] := 0x51
        namedMap["LEFT"] := 0x50
        namedMap["RIGHT"] := 0x4F

        ; 锁定键
        namedMap["CAPSLOCK"] := 0x39
        namedMap["NUMLOCK"] := 0x53
        namedMap["SCROLLLOCK"] := 0x47

        ; 系统键
        namedMap["PRINTSCREEN"] := 0x46
        namedMap["PRTSC"] := 0x46
        namedMap["PAUSE"] := 0x48
        namedMap["BREAK"] := 0x48
        namedMap["APPSKEY"] := 0x65

        ; 修饰键（不带 L/R 的默认映射为左侧）
        namedMap["LCTRL"] := 0xE0
        namedMap["LCONTROL"] := 0xE0
        namedMap["RCTRL"] := 0xE4
        namedMap["RCONTROL"] := 0xE4
        namedMap["CTRL"] := 0xE0
        namedMap["CONTROL"] := 0xE0

        namedMap["LSHIFT"] := 0xE1
        namedMap["RSHIFT"] := 0xE5
        namedMap["SHIFT"] := 0xE1

        namedMap["LALT"] := 0xE2
        namedMap["RALT"] := 0xE6
        namedMap["ALT"] := 0xE2

        namedMap["LWIN"] := 0xE3
        namedMap["RWIN"] := 0xE7
        namedMap["WIN"] := 0xE3

        inited := true
    }

    upper := StrUpper(Trim(name))

    ; F1–F24
    m := 0
    if (RegExMatch(upper, "^F(\d+)$", &m))
    {
        n := Integer(m[1])
        if (n >= 1 && n <= 12)
        {
            return 0x3A + (n - 1)
        }
        if (n >= 13 && n <= 24)
        {
            return 0x68 + (n - 13)
        }
        return 0
    }

    ; Numpad 数字
    m := 0
    if (RegExMatch(upper, "^NUMPAD(\d)$", &m))
    {
        n := Integer(m[1])
        if (n = 0)
        {
            return 0x62
        }
        if (n = 1)
        {
            return 0x59
        }
        if (n = 2)
        {
            return 0x5A
        }
        if (n = 3)
        {
            return 0x5B
        }
        if (n = 4)
        {
            return 0x5C
        }
        if (n = 5)
        {
            return 0x5D
        }
        if (n = 6)
        {
            return 0x5E
        }
        if (n = 7)
        {
            return 0x5F
        }
        if (n = 8)
        {
            return 0x60
        }
        if (n = 9)
        {
            return 0x61
        }
        return 0
    }

    ; Numpad 运算键
    if (upper = "NUMPADDIV")
    {
        return 0x54
    }
    if (upper = "NUMPADMULT")
    {
        return 0x55
    }
    if (upper = "NUMPADSUB")
    {
        return 0x56
    }
    if (upper = "NUMPADADD")
    {
        return 0x57
    }
    if (upper = "NUMPADENTER")
    {
        return 0x58
    }
    if (upper = "NUMPADDOT" || upper = "NUMPADDECIMAL")
    {
        return 0x63
    }

    if (namedMap.Has(upper))
    {
        return namedMap[upper]
    }

    return 0
}