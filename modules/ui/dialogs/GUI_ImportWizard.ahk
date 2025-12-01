; ====================== modules\ui\dialogs\GUI_ImportWizard.ahk ======================
#Requires AutoHotkey v2

; 导入向导全局状态
global g_ImportWiz := Map()

; 入口：由 ToolsIO_StartImportWizard 调用
; tempDir: Exporter_UnpackToTemp 返回的临时目录
; manifest: Exporter_ReadManifest 返回的 Map
ImportWizard_Begin(tempDir, manifest) {
    global g_ImportWiz, App

    if (tempDir = "") {
        return
    }
    if !DirExist(tempDir) {
        return
    }
    if !IsObject(manifest) {
        return
    }

    g_ImportWiz.Clear()
    g_ImportWiz["TempDir"] := tempDir
    g_ImportWiz["Manifest"] := manifest
    g_ImportWiz["Profile"] := ""
    g_ImportWiz["Preview"] := []
    g_ImportWiz["Recalc"] := 1
    g_ImportWiz["ScaleMode"] := "XY"   ; 目前只实现 X/Y 独立缩放
    g_ImportWiz["SrcW"] := 0
    g_ImportWiz["SrcH"] := 0
    g_ImportWiz["DstW"] := 0
    g_ImportWiz["DstH"] := 0

    try {
        Logger_Info("Importer", "Begin", Map("tempDir", tempDir))
    } catch {
    }

    ImportWizard_ShowStep1()
}

; 步骤 1：环境信息 + 是否重算坐标
ImportWizard_ShowStep1() {
    global g_ImportWiz

    m := g_ImportWiz["Manifest"]

    srcW := 0
    srcH := 0
    expAt := ""
    profName := ""

    try {
        srcW := m["Environment"]["ScreenWidth"]
    } catch {
        srcW := A_ScreenWidth
    }
    try {
        srcH := m["Environment"]["ScreenHeight"]
    } catch {
        srcH := A_ScreenHeight
    }
    try {
        expAt := m["Meta"]["ExportedAt"]
    } catch {
        expAt := ""
    }
    try {
        profName := m["Meta"]["ProfileName"]
    } catch {
        profName := "Imported"
    }

    dstW := A_ScreenWidth
    dstH := A_ScreenHeight

    g_ImportWiz["SrcW"] := srcW
    g_ImportWiz["SrcH"] := srcH
    g_ImportWiz["DstW"] := dstW
    g_ImportWiz["DstH"] := dstH

    ; 计算宽高比差异
    ratioDiff := 0.0
    if (srcW > 0 && srcH > 0 && dstW > 0 && dstH > 0) {
        try {
            r1 := srcW / srcH * 1.0
            r2 := dstW / dstH * 1.0
            if (r1 > 0) {
                ratioDiff := Abs(r1 - r2)
            } else {
                ratioDiff := 0.0
            }
        } catch {
            ratioDiff := 0.0
        }
    }

    warnText := ""
    if (ratioDiff > 0.05) {
        warnText := "警告：导出时的屏幕宽高比与当前不一致。按 X/Y 分别缩放会导致取色坐标“拉伸”，" .
            "导入后请特别检查关键技能和点位。"
    }

    ; 是否默认勾选“重算坐标”
    defaultRecalc := 1
    if (srcW = dstW && srcH = dstH) {
        defaultRecalc := 0
    }
    g_ImportWiz["Recalc"] := defaultRecalc

    title := "导入配置向导 - 步骤 1/2"
    g := Gui("+OwnDialogs", title)
    g.MarginX := 12
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    txt1 := "导出配置名称：" profName
    txt2 := "导出时间：" expAt
    txt3 := "导出时分辨率：" srcW " x " srcH
    txt4 := "当前分辨率：" dstW " x " dstH

    g.Add("Text", "x12 y10 w460", txt1)
    g.Add("Text", "x12 y+6 w460", txt2)
    g.Add("Text", "x12 y+6 w460", txt3)
    g.Add("Text", "x12 y+6 w460", txt4)

    y := 10 + 4 * 22 + 12

    g.Add("Text", "x12 y" y " w460", "请选择是否根据分辨率重新计算技能和点位的坐标：")
    y += 26

    chkRe := g.Add("CheckBox"
        , "x24 y" y " w420"
        , "根据分辨率比例重新计算所有技能和点位坐标（按 X/Y 独立缩放）")
    chkRe.Value := defaultRecalc

    y += 28
    if (warnText != "") {
        warn := g.Add("Text"
            , "x24 y" y " w460 cRed"
            , warnText)
        y += 50
    }

    btnNext := g.Add("Button"
        , "x150 y+10 w90 h28"
        , "下一步")
    btnCancel := g.Add("Button"
        , "x+10 w90 h28"
        , "取消")

    ; 事件
    btnNext.OnEvent("Click", ImportWizard_OnStep1Next.Bind(g, chkRe))
    btnCancel.OnEvent("Click", ImportWizard_OnCancel.Bind(g))

    g_ImportWiz["Gui1"] := g
    g.Show("w520 h260")
}

ImportWizard_OnCancel(g, *) {
    global g_ImportWiz

    tempDir := ""
    try {
        tempDir := g_ImportWiz["TempDir"]
    } catch {
        tempDir := ""
    }

    try {
        g.Destroy()
    } catch {
    }

    if (tempDir != "") {
        try {
            DirDelete(tempDir, true)
        } catch {
        }
        try {
            Logger_Info("Importer", "Canceled and tempDir removed", Map("tempDir", tempDir))
        } catch {
        }
    }

    g_ImportWiz.Clear()
}

ImportWizard_OnStep1Next(g, chkRe, *) {
    global g_ImportWiz

    recalc := 1
    try {
        recalc := chkRe.Value ? 1 : 0
    } catch {
        recalc := 1
    }
    g_ImportWiz["Recalc"] := recalc

    try {
        g.Hide()
    } catch {
    }

    ok := false
    try {
        ok := ImportWizard_LoadProfileAndPreview()
    } catch as e {
        ok := false
        try {
            Logger_Exception("Importer", e, Map("where", "LoadProfileAndPreview"))
        } catch {
        }
    }

    if (!ok) {
        MsgBox "从临时目录加载配置失败，无法继续导入。"
        try {
            g.Destroy()
        } catch {
        }
        tempDir := ""
        try {
            tempDir := g_ImportWiz["TempDir"]
        } catch {
            tempDir := ""
        }
        if (tempDir != "") {
            try {
                DirDelete(tempDir, true)
            } catch {
            }
        }
        g_ImportWiz.Clear()
        return
    }

    try {
        g.Destroy()
    } catch {
    }

    ImportWizard_ShowStep2()
}

; 在临时目录下加载 profile，并计算预览数据
ImportWizard_LoadProfileAndPreview() {
    global g_ImportWiz, App

    tempDir := ""
    m := ""
    try {
        tempDir := g_ImportWiz["TempDir"]
        m := g_ImportWiz["Manifest"]
    } catch {
        return false
    }

    if (tempDir = "") {
        return false
    }

    profName := ""
    try {
        profName := m["Meta"]["ProfileName"]
    } catch {
        profName := "Imported"
    }

    ; ========= 1) 递归查找 meta.ini，确定真实 profile 目录 =========
    foundPath := ""
    foundName := ""

    try {
        loop files, tempDir "\meta.ini", "R" {
            ; A_LoopFileFullPath = ...\some\path\meta.ini
            full := A_LoopFileFullPath
            dir := A_LoopFileDir      ; meta.ini 所在目录
            ; 取目录最后一段作为 profile 目录名
            parts := StrSplit(dir, "\")
            last := parts[parts.Length]
            foundPath := dir
            foundName := last
            break
        }
    } catch {
        foundPath := ""
        foundName := ""
    }

    baseDir := tempDir
    realName := profName

    if (foundPath != "" && foundName != "") {
        realName := foundName
        ; baseDir = foundPath 的父目录
        try {
            baseDir := RegExReplace(foundPath, "(?i)\\[^\\]+$", "")
        } catch {
            baseDir := tempDir
        }
    }

    ; 记录探测结果
    try {
        Logger_Info("Importer", "Detect profile folder"
            , Map("manifestName", profName
                , "realName", realName
                , "tempDir", tempDir
                , "baseDir", baseDir
                , "foundPath", foundPath))
    } catch {
    }

    ; ========= 2) 暂时把 ProfilesDir 指向 baseDir，按 realName 加载 profile =========
    oldProfilesDir := ""
    try {
        oldProfilesDir := App["ProfilesDir"]
    } catch {
        oldProfilesDir := A_ScriptDir "\Profiles"
    }

    ok := false
    profile := ""

    ; 记录一下我们预期的 skills.ini / points.ini 路径
    skillsFilePath := baseDir "\" realName "\skills.ini"
    pointsFilePath := baseDir "\" realName "\points.ini"
    skillsExists := FileExist(skillsFilePath) ? 1 : 0
    pointsExists := FileExist(pointsFilePath) ? 1 : 0

    try {
        Logger_Info("Importer", "Before load from temp"
            , Map("skillsIni", skillsFilePath
                , "skillsIniExists", skillsExists
                , "pointsIni", pointsFilePath
                , "pointsIniExists", pointsExists))
    } catch {
    }

    try {
        App["ProfilesDir"] := baseDir
        profile := Storage_Profile_LoadFull(realName)
        ok := true
    } catch as e {
        ok := false
        try {
            Logger_Exception("Importer", e, Map("where", "LoadFromTemp", "profile", realName, "baseDir", baseDir))
        } catch {
        }
    } finally {
        try {
            App["ProfilesDir"] := oldProfilesDir
        } catch {
        }
    }

    if (!ok || !IsObject(profile)) {
        return false
    }

    g_ImportWiz["Profile"] := profile

    ; ========= 3) 计算缩放比例 =========
    srcW := g_ImportWiz["SrcW"]
    srcH := g_ImportWiz["SrcH"]
    dstW := g_ImportWiz["DstW"]
    dstH := g_ImportWiz["DstH"]
    recalc := g_ImportWiz["Recalc"]

    scaleX := 1.0
    scaleY := 1.0

    if (srcW > 0 && srcH > 0) {
        try {
            scaleX := dstW * 1.0 / srcW
            scaleY := dstH * 1.0 / srcH
        } catch {
            scaleX := 1.0
            scaleY := 1.0
        }
    }

    preview := []

    ; ========= 4) Skills 预览（使用 OM_Get 读取 Map 字段） =========
    if (profile.Has("Skills") && IsObject(profile["Skills"])) {
        i := 1
        while (i <= profile["Skills"].Length) {
            s := profile["Skills"][i]
            if (IsObject(s)) {
                id := 0
                name := ""
                x := 0
                y := 0

                try {
                    id := OM_Get(s, "Id", 0)
                } catch {
                    id := 0
                }
                try {
                    name := OM_Get(s, "Name", "")
                } catch {
                    name := ""
                }
                try {
                    x := OM_Get(s, "X", 0)
                } catch {
                    x := 0
                }
                try {
                    y := OM_Get(s, "Y", 0)
                } catch {
                    y := 0
                }

                newX := x
                newY := y
                if (recalc) {
                    try {
                        newX := Round(x * scaleX)
                    } catch {
                        newX := x
                    }
                    try {
                        newY := Round(y * scaleY)
                    } catch {
                        newY := y
                    }
                }

                row := Map()
                row["Kind"] := "Skill"
                row["Index"] := i
                row["Id"] := id
                row["Name"] := name
                row["OldX"] := x
                row["OldY"] := y
                row["NewX"] := newX
                row["NewY"] := newY
                preview.Push(row)
            }
            i := i + 1
        }
    }

    ; ========= 5) Points 预览（使用 OM_Get 读取 Map 字段） =========
    if (profile.Has("Points") && IsObject(profile["Points"])) {
        i := 1
        while (i <= profile["Points"].Length) {
            p := profile["Points"][i]
            if (IsObject(p)) {
                id := 0
                name := ""
                x := 0
                y := 0

                try {
                    id := OM_Get(p, "Id", 0)
                } catch {
                    id := 0
                }
                try {
                    name := OM_Get(p, "Name", "")
                } catch {
                    name := ""
                }
                try {
                    x := OM_Get(p, "X", 0)
                } catch {
                    x := 0
                }
                try {
                    y := OM_Get(p, "Y", 0)
                } catch {
                    y := 0
                }

                newX := x
                newY := y
                if (recalc) {
                    try {
                        newX := Round(x * scaleX)
                    } catch {
                        newX := x
                    }
                    try {
                        newY := Round(y * scaleY)
                    } catch {
                        newY := y
                    }
                }

                row := Map()
                row["Kind"] := "Point"
                row["Index"] := i
                row["Id"] := id
                row["Name"] := name
                row["OldX"] := x
                row["OldY"] := y
                row["NewX"] := newX
                row["NewY"] := newY
                preview.Push(row)
            }
            i := i + 1
        }
    }

    g_ImportWiz["Preview"] := preview

    ; ========= 6) 记录加载结果到日志 =========
    skCnt := 0
    ptCnt := 0
    try {
        if (profile.Has("Skills") && IsObject(profile["Skills"])) {
            skCnt := profile["Skills"].Length
        }
    } catch {
        skCnt := 0
    }
    try {
        if (profile.Has("Points") && IsObject(profile["Points"])) {
            ptCnt := profile["Points"].Length
        }
    } catch {
        ptCnt := 0
    }

    try {
        Logger_Info("Importer", "Preview built"
            , Map("profileName", realName
                , "skills", skCnt
                , "points", ptCnt
                , "previewRows", preview.Length))
    } catch {
    }

    return true
}
; 步骤 2：预览坐标变化 + 输入新配置名 + 确认导入
ImportWizard_ShowStep2() {
    global g_ImportWiz, App

    preview := g_ImportWiz["Preview"]
    profile := g_ImportWiz["Profile"]
    manifest := g_ImportWiz["Manifest"]

    if (!IsObject(profile)) {
        MsgBox "内部错误：Profile 未加载。"
        return
    }

    oldName := ""
    try {
        oldName := manifest["Meta"]["ProfileName"]
    } catch {
        oldName := "Imported"
    }

    ; 默认新名称
    newName := oldName "_Imported"

    title := "导入配置向导 - 步骤 2/2"
    g := Gui("+OwnDialogs +Resize", title)
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    g.Add("Text", "x10 y10 w520", "预览技能与点位坐标变化：")

    lv := g.Add("ListView"
        , "x10 y32 w620 h260"
        , ["类型", "名称", "旧X", "旧Y", "新X", "新Y", "是否改变"])
    ; 填充预览
    i := 1
    while (i <= preview.Length) {
        row := preview[i]
        kind := ""
        name := ""
        ox := 0
        oy := 0
        nx := 0
        ny := 0
        try {
            kind := row["Kind"]
        } catch {
            kind := ""
        }
        try {
            name := row["Name"]
        } catch {
            name := ""
        }
        try {
            ox := row["OldX"]
        } catch {
            ox := 0
        }
        try {
            oy := row["OldY"]
        } catch {
            oy := 0
        }
        try {
            nx := row["NewX"]
        } catch {
            nx := ox
        }
        try {
            ny := row["NewY"]
        } catch {
            ny := oy
        }

        changed := ""
        if (ox != nx || oy != ny) {
            changed := "是"
        } else {
            changed := "否"
        }

        try {
            lv.Add("", kind, name, ox, oy, nx, ny, changed)
        } catch {
        }

        i := i + 1
    }

    g.Add("Text", "x10 y+10 w120 Right", "新配置名称：")
    edName := g.Add("Edit", "x+6 w260", newName)

    btnOk := g.Add("Button", "x10 y+14 w100 h28", "确认导入并应用")
    btnCancel := g.Add("Button", "x+10 w80 h28", "取消")

    ; 保存到全局，供事件使用
    g_ImportWiz["Gui2"] := g
    g_ImportWiz["EdNewName"] := edName
    g_ImportWiz["ListView"] := lv

    btnOk.OnEvent("Click", ImportWizard_OnFinish.Bind(g))
    btnCancel.OnEvent("Click", ImportWizard_OnFinishCancel.Bind(g))

    g.OnEvent("Close", ImportWizard_OnFinishCancel.Bind(g))

    g.Show("w650 h380")
}

ImportWizard_OnFinishCancel(g, *) {
    global g_ImportWiz

    tempDir := ""
    try {
        tempDir := g_ImportWiz["TempDir"]
    } catch {
        tempDir := ""
    }

    try {
        g.Destroy()
    } catch {
    }

    if (tempDir != "") {
        try {
            DirDelete(tempDir, true)
        } catch {
        }
        try {
            Logger_Info("Importer", "Canceled at step2, tempDir removed", Map("tempDir", tempDir))
        } catch {
        }
    }

    g_ImportWiz.Clear()
}

ImportWizard_OnFinish(g, *) {
    global g_ImportWiz, App

    profile := ""
    preview := []
    edName := ""
    tempDir := ""

    try {
        profile := g_ImportWiz["Profile"]
        preview := g_ImportWiz["Preview"]
        edName := g_ImportWiz["EdNewName"]
        tempDir := g_ImportWiz["TempDir"]
    } catch {
    }

    if (!IsObject(profile)) {
        MsgBox "内部错误：Profile 未加载。"
        return
    }

    newName := ""
    try {
        newName := Trim(edName.Value)
    } catch {
        newName := ""
    }

    if (newName = "") {
        MsgBox "新配置名称不能为空。"
        return
    }

    ; 检查重名
    names := []
    try {
        names := FS_ListProfilesValid()
    } catch {
        names := []
    }
    i := 1
    while (i <= names.Length) {
        if (names[i] = newName) {
            MsgBox "已存在同名配置，请更换一个名称。"
            return
        }
        i := i + 1
    }

    ; 应用预览中的新坐标到 profile
    okApply := true
    try {
        i := 1
        while (i <= preview.Length) {
            row := preview[i]
            kind := ""
            idx := 0
            nx := 0
            ny := 0
            try {
                kind := row["Kind"]
            } catch {
                kind := ""
            }
            try {
                idx := row["Index"]
            } catch {
                idx := 0
            }
            try {
                nx := row["NewX"]
            } catch {
                nx := 0
            }
            try {
                ny := row["NewY"]
            } catch {
                ny := 0
            }

            if (kind = "Skill") {
                if (profile.Has("Skills") && IsObject(profile["Skills"])) {
                    if (idx >= 1 && idx <= profile["Skills"].Length) {
                        s := profile["Skills"][idx]
                        try {
                            s["X"] := nx
                        } catch {
                        }
                        try {
                            s["Y"] := ny
                        } catch {
                        }
                        profile["Skills"][idx] := s
                    }
                }
            } else if (kind = "Point") {
                if (profile.Has("Points") && IsObject(profile["Points"])) {
                    if (idx >= 1 && idx <= profile["Points"].Length) {
                        p := profile["Points"][idx]
                        try {
                            p["X"] := nx
                        } catch {
                        }
                        try {
                            p["Y"] := ny
                        } catch {
                        }
                        profile["Points"][idx] := p
                    }
                }
            }

            i := i + 1
        }
    } catch as e1 {
        okApply := false
        try {
            Logger_Exception("Importer", e1, Map("where", "ApplyPreview"))
        } catch {
        }
    }

    if (!okApply) {
        MsgBox "应用坐标变更失败，导入中止。"
        return
    }

    ; 设置新名称
    try {
        profile["Name"] := newName
    } catch {
    }
    try {
        if (profile.Has("Meta")) {
            profile["Meta"]["DisplayName"] := newName
        }
    } catch {
    }

    ; 保存为新 Profile
    okSave := false
    try {
        okSave := Storage_Profile_SaveAll(profile)
    } catch as e2 {
        okSave := false
        try {
            Logger_Exception("Importer", e2, Map("where", "SaveAll", "profile", newName))
        } catch {
        }
    }

    if (!okSave) {
        MsgBox "保存新配置失败，请查看日志。"
        return
    }

    ; 清理临时目录
    if (tempDir != "") {
        try {
            DirDelete(tempDir, true)
        } catch {
        }
    }

    try {
        Logger_Info("Importer", "Imported profile saved", Map("name", newName))
    } catch {
    }

    try {
        g.Destroy()
    } catch {
    }

    ; 可选：自动切换到新 profile
    switched := false
    try {
        switched := Profile_SwitchProfile_Strong(newName)
    } catch {
        switched := false
    }

    if (switched) {
        Notify("导入成功，已切换到新配置：" newName)
    } else {
        Notify("导入成功，请在概览页中选择新配置：" newName)
    }

    g_ImportWiz.Clear()
}
