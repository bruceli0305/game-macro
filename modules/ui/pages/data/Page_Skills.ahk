#Requires AutoHotkey v2
; modules\ui\pages\data\Page_Skills.ahk
; 数据与检测 → 技能（嵌入页）
; 严格块结构 if/try/catch，不使用单行语句
; 依赖：OM_Get（modules\util\Obj.ahk 已由 Main.ahk 全局引入）

Page_Skills_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; 列表
    UI.SkillLV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        , ["ID","技能名","键位","X","Y","颜色","容差","读条ms","锁定","超时ms"])
    page.Controls.Push(UI.SkillLV)

    ; 按钮行
    yBtn := rc.Y + rc.H - 30
    UI.BtnAddSkill  := UI.Main.Add("Button", Format("x{} y{} w96 h28", rc.X, yBtn), "新增")
    UI.BtnEditSkill := UI.Main.Add("Button", "x+8 w96 h28", "编辑")
    UI.BtnDelSkill  := UI.Main.Add("Button", "x+8 w96 h28", "删除")
    UI.BtnTestSkill := UI.Main.Add("Button", "x+8 w96 h28", "测试检测")
    UI.BtnBatchSkill := UI.Main.Add("Button", "x+8 w96 h28", "批量取色")
    UI.BtnImportPreset := UI.Main.Add("Button", "x+8 w110 h28", "从预设导入")
    UI.BtnSaveSkill := UI.Main.Add("Button", "x+8 w96 h28", "保存")
    page.Controls.Push(UI.BtnAddSkill)
    page.Controls.Push(UI.BtnEditSkill)
    page.Controls.Push(UI.BtnDelSkill)
    page.Controls.Push(UI.BtnTestSkill)
    page.Controls.Push(UI.BtnBatchSkill)
    page.Controls.Push(UI.BtnImportPreset)
    page.Controls.Push(UI.BtnSaveSkill)

    ; 事件绑定（全部为本页回调）
    UI.SkillLV.OnEvent("DoubleClick", Skills_OnEditSelected)
    UI.BtnAddSkill.OnEvent("Click", Skills_OnAdd)
    UI.BtnEditSkill.OnEvent("Click", Skills_OnEditSelected)
    UI.BtnDelSkill.OnEvent("Click", Skills_OnDelete)
    UI.BtnTestSkill.OnEvent("Click", Skills_OnTest)
    UI.BtnBatchSkill.OnEvent("Click", Skills_OnBatchRecolor)
    UI.BtnImportPreset.OnEvent("Click", Skills_OnImportPreset)
    UI.BtnSaveSkill.OnEvent("Click", Skills_OnSaveProfile)

    ; 首次填充
    Skills_RefreshList()
}

Page_Skills_Layout(rc) {
    try {
        btnH := 28
        try {
            UI.BtnAddSkill.GetPos(,,, &btnH)
        } catch {
        }

        gap := 8
        listH := rc.H - btnH - gap
        if (listH < 120) {
            listH := 120
        }

        UI.SkillLV.Move(rc.X, rc.Y, rc.W, listH)

        yBtn := rc.Y + rc.H - btnH
        UI.BtnAddSkill.Move(rc.X, yBtn)
        UI.BtnEditSkill.Move(,    yBtn)
        UI.BtnDelSkill.Move(,     yBtn)
        UI.BtnTestSkill.Move(,    yBtn)
        UI.BtnBatchSkill.Move(,   yBtn)
        UI.BtnImportPreset.Move(, yBtn)
        UI.BtnSaveSkill.Move(,    yBtn)

        loop 10 {
            try {
                UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    }
}

Page_Skills_OnEnter(*) {
    Skills_RefreshList()
}

; ================= 工具与事件 =================

Skills_RefreshList() {
    global App, UI
    try {
        UI.SkillLV.Opt("-Redraw")
        UI.SkillLV.Delete()
    } catch {
    }

    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        for idx, s in App["ProfileData"].Skills {
            id   := OM_Get(s, "Id", 0)
            name := OM_Get(s, "Name", "")
            key  := OM_Get(s, "Key", "")
            x    := OM_Get(s, "X", 0)
            y    := OM_Get(s, "Y", 0)
            col  := OM_Get(s, "Color", "0x000000")
            tol  := OM_Get(s, "Tol", 10)
            cast := OM_Get(s, "CastMs", 0)

            lock := 1
            try {
                lock := OM_Get(s, "LockDuringCast", 1)
            } catch {
                lock := 1
            }
            tmo := 0
            try {
                tmo := OM_Get(s, "CastTimeoutMs", 0)
            } catch {
                tmo := 0
            }

            lockText := ""
            if (lock) {
                lockText := "√"
            }

            UI.SkillLV.Add("", id, name, key, x, y, col, tol, cast, lockText, tmo)
        }
        loop 10 {
            try {
                UI.SkillLV.ModifyCol(A_Index, "AutoHdr")
            } catch {
            }
        }
    } catch {
    } finally {
        try {
            UI.SkillLV.Opt("+Redraw")
        } catch {
        }
    }
}

; 从列表选中行读取稳定 Id（列1）
Skills_GetSelectedId() {
    global UI
    row := 0
    try {
        row := UI.SkillLV.GetNext(0, "Focused")
    } catch {
        row := 0
    }
    if (row = 0) {
        MsgBox "请先选中一个技能行。"
        return 0
    }
    id := 0
    try {
        id := Integer(UI.SkillLV.GetText(row, 1))
    } catch {
        id := 0
    }
    return id
}

; 按稳定 Id 查找当前运行时索引
Skills_IndexById(id) {
    global App
    if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
        return 0
    }

    i := 1
    while (i <= App["ProfileData"].Skills.Length) {
        sid := 0
        try {
            sid := OM_Get(App["ProfileData"].Skills[i], "Id", 0)
        } catch {
            sid := 0
        }
        if (sid = id) {
            return i
        }
        i := i + 1
    }
    return 0
}

; ---- 新增 ----
Skills_OnAdd(*) {
    try {
        SkillEditor_Open({}, 0, Skills_OnSaved_New)
    } catch {
        MsgBox "无法打开技能编辑器。"
    }
}

Skills_OnSaved_New(newSkill, idxParam) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        if !HasProp(newSkill, "Id") {
            try {
                newSkill.Id := 0
            } catch {
            }
        }
        App["ProfileData"].Skills.Push(newSkill)
        Skills_RefreshList()
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 编辑 ----
Skills_OnEditSelected(*) {
    global App
    id := Skills_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Skills_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    cur := 0
    try {
        cur := App["ProfileData"].Skills[idx]
    } catch {
        cur := 0
    }
    try {
        SkillEditor_Open(cur, idx, Skills_OnSaved_Edit)
    } catch {
        MsgBox "无法打开技能编辑器。"
    }
}

Skills_OnSaved_Edit(newSkill, idx2) {
    global App
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        if (idx2 >= 1 && idx2 <= App["ProfileData"].Skills.Length) {
            old := 0
            try {
                old := App["ProfileData"].Skills[idx2]
            } catch {
                old := 0
            }
            try {
                if (old && HasProp(old, "Id")) {
                    newSkill.Id := old.Id
                }
            } catch {
            }
            App["ProfileData"].Skills[idx2] := newSkill
        }
        Skills_RefreshList()
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 删除 ----
Skills_OnDelete(*) {
    global App
    id := Skills_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Skills_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }
    try {
        if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
            return
        }
        if (idx < 1 || idx > App["ProfileData"].Skills.Length) {
            MsgBox "索引异常，列表与配置不同步。"
            return
        }
        App["ProfileData"].Skills.RemoveAt(idx)
        Skills_RefreshList()
        Notify("已删除技能")
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
}

; ---- 测试 ----
Skills_OnTest(*) {
    global App
    id := Skills_GetSelectedId()
    if (id = 0) {
        return
    }
    idx := Skills_IndexById(id)
    if (idx = 0) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }

    s := 0
    try {
        s := App["ProfileData"].Skills[idx]
    } catch {
        s := 0
    }
    if (!s) {
        MsgBox "索引异常，列表与配置不同步。"
        return
    }

    offY := 0
    dwell := 0
    try {
        if (HasProp(App["ProfileData"], "PickHoverEnabled") && App["ProfileData"].PickHoverEnabled) {
            try {
                offY := HasProp(App["ProfileData"], "PickHoverOffsetY") ? App["ProfileData"].PickHoverOffsetY : 0
            } catch {
                offY := 0
            }
            try {
                dwell := HasProp(App["ProfileData"], "PickHoverDwellMs") ? App["ProfileData"].PickHoverDwellMs : 0
            } catch {
                dwell := 0
            }
        }
    } catch {
        offY := 0
        dwell := 0
    }

    x   := OM_Get(s, "X", 0)
    y   := OM_Get(s, "Y", 0)
    col := OM_Get(s, "Color", "0x000000")
    tol := OM_Get(s, "Tol", 10)

    c := 0
    try {
        c := Pixel_GetColorWithMouseAway(x, y, offY, dwell)
    } catch {
        c := 0
    }

    tgt := 0
    try {
        tgt := Pixel_HexToInt(col)
    } catch {
        tgt := 0
    }
    match := false
    try {
        match := Pixel_ColorMatch(c, tgt, tol)
    } catch {
        match := false
    }

    try {
        MsgBox "检测点: X=" x " Y=" y "`n"
            . "当前颜色: " Pixel_ColorToHex(c) "`n"
            . "目标颜色: " col "`n"
            . "容差: " tol "`n"
            . "结果: " (match ? "匹配" : "不匹配")
    } catch {
    }
}

; 保存：仅写 skills.ini（新存储），并重载规范化
Skills_OnSaveProfile(*) {
    global App

    if !(IsSet(App) && App.Has("CurrentProfile") && App.Has("ProfileData")) {
        MsgBox "未选择配置或配置未加载。"
        return
    }

    name := ""
    try {
        name := App["CurrentProfile"]
    } catch {
        name := ""
    }
    if (name = "") {
        MsgBox "未选择配置。"
        return
    }

    ; 1) 加载文件夹模型（Id 引用）
    p := 0
    try {
        p := Storage_Profile_LoadFull(name)
    } catch as e1 {
        try {
            Logger_Exception("Skills", e1, Map("where", "LoadFull", "profile", name))
        } catch {
        }
        MsgBox "加载配置失败。"
        return
    }

    ; 2) 构建旧技能表（Id -> 对象）
    oldMap := Map()
    try {
        if (p.Has("Skills") && IsObject(p["Skills"])) {
            i := 1
            while (i <= p["Skills"].Length) {
                oid := 0
                try {
                    oid := OM_Get(p["Skills"][i], "Id", 0)
                } catch {
                    oid := 0
                }
                if (oid > 0) {
                    oldMap[oid] := p["Skills"][i]
                }
                i := i + 1
            }
        }
    } catch {
    }

    ; 3) 合并运行时到文件夹模型（按稳定 Id）
    newArr := []
    try {
        if (HasProp(App["ProfileData"], "Skills") && IsObject(App["ProfileData"].Skills)) {
            i := 1
            while (i <= App["ProfileData"].Skills.Length) {
                rs := App["ProfileData"].Skills[i]
                rid  := OM_Get(rs, "Id", 0)
                nm   := OM_Get(rs, "Name", "")
                key  := OM_Get(rs, "Key", "")
                x    := OM_Get(rs, "X", 0)
                y    := OM_Get(rs, "Y", 0)
                col  := OM_Get(rs, "Color", "0x000000")
                tol  := OM_Get(rs, "Tol", 10)
                cast := OM_Get(rs, "CastMs", 0)
                lock := OM_Get(rs, "LockDuringCast", 1)
                cto  := OM_Get(rs, "CastTimeoutMs", 0)

                ps := 0
                if (rid > 0 && oldMap.Has(rid)) {
                    try {
                        ps := oldMap[rid]
                        ps["Name"] := nm
                        ps["Key"] := key
                        ps["X"] := x
                        ps["Y"] := y
                        ps["Color"] := col
                        ps["Tol"] := tol
                        ps["CastMs"] := cast
                        ps["LockDuringCast"] := lock
                        ps["CastTimeoutMs"] := cto
                    } catch {
                        ps := PM_NewSkill(nm)
                        ps["Id"] := rid
                        ps["Key"] := key
                        ps["X"] := x
                        ps["Y"] := y
                        ps["Color"] := col
                        ps["Tol"] := tol
                        ps["CastMs"] := cast
                        ps["LockDuringCast"] := lock
                        ps["CastTimeoutMs"] := cto
                    }
                } else {
                    ps := PM_NewSkill(nm)
                    ps["Id"] := 0
                    ps["Key"] := key
                    ps["X"] := x
                    ps["Y"] := y
                    ps["Color"] := col
                    ps["Tol"] := tol
                    ps["CastMs"] := cast
                    ps["LockDuringCast"] := lock
                    ps["CastTimeoutMs"] := cto
                }

                newArr.Push(ps)
                i := i + 1
            }
        }
    } catch {
    }

    p["Skills"] := newArr

    ; 4) 保存到 skills.ini（原子），并触摸 meta
    ok := false
    try {
        SaveModule_Skills(p)
        ok := true
    } catch as e2 {
        ok := false
        try {
            Logger_Exception("Skills", e2, Map("where","SaveModule_Skills", "profile", name))
        } catch {
        }
    }
    if (!ok) {
        MsgBox "保存失败。"
        return
    }

    ; 5) 重新加载 → 规范化到运行时 → 刷新列表与 ROI
    try {
        p2 := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p2)
        App["ProfileData"] := rt
    } catch as e3 {
        try {
            Logger_Exception("Skills", e3, Map("where","ReloadNormalize", "profile", name))
        } catch {
        }
        MsgBox "保存成功，但重新加载失败，请切换配置后重试。"
        return
    }

    try {
        Skills_RefreshList()
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }

    Notify("配置已保存")
}
Skills_OnBatchRecolor(*) {
    try {
        SkillBatchRecolor_Open()
    } catch as e {
        try {
            Logger_Exception("BatchRecolor", e, Map("where", "Skills_OnBatchRecolor"))
        } catch {
        }
        MsgBox "无法打开技能批量取色对话框。"
    }
}
; ============================================
; 从 GW2 预设导入相关
; ============================================

Skills_OnImportPreset(*) {
    SkillPresetImport_Open()
}

; candList: [{ Id, Name, Category, WeaponType, SpecName, Slot }, ...]
Skills_ImportFromPreset(candList) {
    global App

    if !(IsSet(App) && App.Has("ProfileData") && HasProp(App["ProfileData"], "Skills")) {
        MsgBox "当前没有加载中的配置，无法导入。"
        return
    }

    count := 0
    idx := 1
    while (idx <= candList.Length) {
        s := candList[idx]

        sk := Map()
        sk.Name := s.Name
        sk.Key  := SkillPreset_GuessKeyFromSlot(s.Slot)

        sk.X    := 0
        sk.Y    := 0
        sk.Color:= "0x000000"
        sk.Tol  := 10
        sk.LockDuringCast := 1
        sk.CastTimeoutMs  := 0

        ; 记录 GW2 技能 ID，方便以后追踪（不会影响现有逻辑）
        sk.Gw2SkillId := s.Id

        ; Id 暂给 0，保存时会重新分配稳定 Id
        sk.Id := 0

        App["ProfileData"].Skills.Push(sk)
        count := count + 1

        idx := idx + 1
    }

    Skills_RefreshList()

    ; 同步 ROI
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }

    Notify("已从预设导入 " count " 个技能，请记得批量取色。")
}

SkillPreset_GuessKeyFromSlot(slot) {
    if (slot = "Weapon_1") {
        return "1"
    }
    if (slot = "Weapon_2") {
        return "2"
    }
    if (slot = "Weapon_3") {
        return "3"
    }
    if (slot = "Weapon_4") {
        return "4"
    }
    if (slot = "Weapon_5") {
        return "5"
    }
    if (slot = "Heal") {
        return "6"
    }
    if (slot = "Utility") {
        ; 很难自动区分 7/8/9，留空给用户自己填
        return ""
    }
    if (slot = "Elite") {
        ; 看你键位习惯，这里示例用 0
        return "0"
    }
    return ""
}