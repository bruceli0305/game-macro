#Requires AutoHotkey v2

; Lang - 简单多语言框架（INI 语言包）
; 约定：Languages\<code>.ini，UTF-8 保存
; 使用：T("key", "默认中文") 或 TF("key", Map("n", 1))
global gLang := Map()

; 安全语言目录解析：未初始化时回退到 A_ScriptDir\Languages
Lang_Dir() {
    try {
        global App
        if IsSet(App) && IsObject(App) && App.Has("LangDir") && App["LangDir"] != ""
            return App["LangDir"]
    }
    return A_ScriptDir "\Languages"
}

Lang_Init(code := "") {
    global App, gLang
    if !IsSet(App)
        App := Map()
    if !App.Has("LangDir")
        App["LangDir"] := A_ScriptDir "\Languages"
    DirCreate(App["LangDir"])  ; 确保目录存在

    if (code = "")
        code := "zh-CN"
    gLang := Map("Code", code, "Map", Map(), "Name", code)
    Lang_Load(code)
}

; 从 UTF-8 文件中解析 [meta] Name（优先）
Lang_ReadMetaNameUTF8(path) {
    try {
        content := FileRead(path, "UTF-8")
    } catch {
        return ""
    }
    cur := ""
    loop parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line = "" || SubStr(line,1,1) = ";")
            continue
        if (SubStr(line,1,1) = "[" && SubStr(line,-1) = "]") {
            cur := SubStr(line, 2, StrLen(line)-2)
            continue
        }
        if (StrLower(cur) != "meta")
            continue
        pos := InStr(line, "=")
        if (pos > 1) {
            key := Trim(SubStr(line, 1, pos-1))
            if (StrLower(key) = "name")
                return Trim(SubStr(line, pos+1))
        }
    }
    return ""
}

Lang_Load(code) {
    global gLang
    dir := Lang_Dir()
    file := dir "\" code ".ini"
    if !FileExist(file) {
        ; 尝试回退到 zh-CN；仍不存在则给空表
        if (code != "zh-CN") {
            Lang_Load("zh-CN")
            return
        }
        gLang["Map"] := Map()
        gLang["Code"] := code
        gLang["Name"] := code
        return
    }
    m := Map()
    try {
        ; 解析 strings 段（UTF-8）
        content := FileRead(file, "UTF-8")
        curSection := ""
        loop parse content, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line = "" || SubStr(line, 1, 1) = ";")
                continue
            if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                curSection := SubStr(line, 2, StrLen(line)-2)
                continue
            }
            if (StrLower(curSection) != "strings")
                continue
            pos := InStr(line, "=")
            if (pos > 1) {
                key := Trim(SubStr(line, 1, pos-1))
                val := SubStr(line, pos+1)
                m[key] := val
            }
        }
        ; 解析 meta.Name（UTF-8 优先，失败再回退 IniRead）
        name := Lang_ReadMetaNameUTF8(file)
        if (name = "") {
            try name := IniRead(file, "meta", "Name", code)
        }
        if (name = "")
            name := code

        gLang["Map"] := m
        gLang["Code"] := code
        gLang["Name"] := name
    } catch {
        gLang["Map"] := Map()
        gLang["Code"] := code
        gLang["Name"] := code
    }
}

Lang_ListPackages() {
    dir := Lang_Dir()
    DirCreate(dir)
    list := []
    found := false
    loop files, dir "\*.ini" {
        code := RegExReplace(A_LoopFileName, "\.ini$")
        name := Lang_ReadMetaNameUTF8(A_LoopFileFullPath)
        if (name = "") {
            try name := IniRead(A_LoopFileFullPath, "meta", "Name", code)
        }
        if (name = "")
            name := code
        list.Push({ Code: code, Name: name })
        found := true
    }
    ; 若目录为空，提供内置兜底列表，界面可切换但不强制要求文件存在
    if !found
        list := [{ Code: "zh-CN", Name: "简体中文" }, { Code: "en-US", Name: "English" }]
    return list
}

Lang_SetLanguage(code) {
    Lang_Load(code)
}

; 基础翻译：未命中返回默认文本，否则返回翻译
T(key, def := "") {
    global gLang
    if gLang.Has("Map") && gLang["Map"].Has(key)
        return gLang["Map"][key]
    return (def != "") ? def : key
}

; 带占位符格式化：{name} 替换
TF(key, vars := Map(), def := "") {
    s := T(key, def)
    for k, v in vars
        s := StrReplace(s, "{" k "}", v)
    return s
}