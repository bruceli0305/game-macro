; ============================================
; modules\ui\dialogs\GUI_SkillPresetImport.ahk
; 从 GW2 预设导入技能（带中文职业 / 特性 / 武器）
; 依赖：GW2_DB.ahk, Logger.ahk, Page_Skills.ahk (Skills_ImportFromPreset)
; ============================================
#Requires AutoHotkey v2
#Include "..\..\gw2\GW2_DB.ahk"

global SkillPresetGUI          := 0
global SkillPreset_ProfIds     := []   ; 职业 DDL：index -> ProfId (字符串，如 "Guardian")
global SkillPreset_SpecIds     := []   ; 特性 DDL：index -> SpecId (整数，-1=全部,0=基础)
global SkillPreset_WeaponTypes := []   ; 武器 DDL：index -> WeaponType (字符串，""=全部)

; ============================================
; 打开对话框
; ============================================
SkillPresetImport_Open() {
    global SkillPresetGUI
    global UI

    Logger_Info("UI_SkillPreset", "SkillPresetImport_Open enter")

    ; 确保数据已加载
    try {
        GW2_DB_EnsureLoaded()
    } catch {
        Logger_Error("UI_SkillPreset", "GW2_DB_EnsureLoaded failed")
        MsgBox "加载 GW2 数据失败，请查看日志。"
        return
    }

    ; 已有 GUI 时直接显示
    if (SkillPresetGUI) {
        try {
            SkillPresetGUI.Show()
        } catch {
        }
        Logger_Info("UI_SkillPreset", "SkillPresetImport_Open reuse existing GUI")
        return
    }

    ; ===== 创建 GUI =====
    SkillPresetGUI := Gui("+Owner" UI.Main.Hwnd " +Resize", "从 GW2 预设导入技能")
    SkillPresetGUI.SetFont("s9", "Segoe UI")
    SkillPresetGUI.OnEvent("Size", SkillPreset_OnResize)

    ; 顶部：职业 / 特性 / 类别 / 武器 / 刷新
    SkillPresetGUI.Add("Text", "xm ym", "职业：")
    ddlProf := SkillPresetGUI.Add("DropDownList", "x+4 w160")

    SkillPresetGUI.Add("Text", "x+8", "特性：")
    ddlSpec := SkillPresetGUI.Add("DropDownList", "x+4 w220")

    SkillPresetGUI.Add("Text", "x+8", "类别：")
    ddlCat := SkillPresetGUI.Add("DropDownList", "x+4 w80")

    SkillPresetGUI.Add("Text", "x+8", "武器：")
    ddlWeapon := SkillPresetGUI.Add("DropDownList", "x+4 w150")

    btnReload := SkillPresetGUI.Add("Button", "x+8 w80", "刷新列表")

    ; 中部：技能列表
    lv := SkillPresetGUI.Add("ListView"
        , "xm y+8 w860 h320 +Multi"
        , ["技能名","大类","武器","特性","Slot","GW2-ID"])

    ; 底部：导入 / 关闭
    btnImport := SkillPresetGUI.Add("Button", "xm y+8 w150", "导入到当前配置")
    btnClose  := SkillPresetGUI.Add("Button", "x+8 w80", "关闭")

    ; 保存控件引用
    SkillPresetGUI.DdlProf    := ddlProf
    SkillPresetGUI.DdlSpec    := ddlSpec
    SkillPresetGUI.DdlCat     := ddlCat
    SkillPresetGUI.DdlWeapon  := ddlWeapon
    SkillPresetGUI.LV         := lv
    SkillPresetGUI.BtnReload  := btnReload
    SkillPresetGUI.BtnImport  := btnImport
    SkillPresetGUI.BtnClose   := btnClose

    ; 事件绑定
    btnReload.OnEvent("Click", SkillPreset_OnReload)
    btnImport.OnEvent("Click", SkillPreset_OnImport)
    btnClose.OnEvent("Click", SkillPreset_OnClose)
    ddlProf.OnEvent("Change",  SkillPreset_OnProfChange)
    ddlSpec.OnEvent("Change",  SkillPreset_OnSpecChange)
    ddlCat.OnEvent("Change",   SkillPreset_OnCatChange)
    ddlWeapon.OnEvent("Change",SkillPreset_OnReload)

    ; 初始化下拉
    SkillPreset_FillProfessions(ddlProf)
    SkillPreset_FillCategories(ddlCat)

    ; 按当前职业刷新特性、武器和列表
    SkillPreset_OnProfChange(ddlProf)
    SkillPreset_OnReload(btnReload)

    SkillPresetGUI.Show("AutoSize")
    Logger_Info("UI_SkillPreset", "SkillPresetImport_Open GUI created")
}

; ============================================
; 职业下拉（带中文）
; ============================================
SkillPreset_FillProfessions(ddlProf) {
    global SkillPreset_ProfIds

    pros := []
    try {
        pros := GW2_GetProfessions()
    } catch {
        Logger_Error("UI_SkillPreset", "GW2_GetProfessions failed")
        pros := []
    }

    SkillPreset_ProfIds := []
    ddlProf.Delete()

    if (pros.Length = 0) {
        Logger_Warn("UI_SkillPreset", "No professions loaded")
        ddlProf.Add(["<无职业>"])
        ddlProf.Choose(1)
        return
    }

    items := []
    idx := 1
    while (idx <= pros.Length) {
        p := pros[idx]
        profId := p.Id

        displayName := SkillPreset_LocalizeProfession(profId)
        items.Push(displayName)
        SkillPreset_ProfIds.Push(profId)

        idx := idx + 1
    }

    ddlProf.Add(items)
    ddlProf.Choose(1)

    Logger_Info("UI_SkillPreset", "Professions filled", Map("count", pros.Length))
}

SkillPreset_LocalizeProfession(profId) {
    ; 英文职业 Id -> 中文名，你可以按需要修改汉字
    profNameMap := Map()
    profNameMap["Elementalist"] := "元素使"
    profNameMap["Engineer"]     := "工程师"
    profNameMap["Guardian"]     := "守护者"
    profNameMap["Mesmer"]       := "幻术师"
    profNameMap["Necromancer"]  := "死灵法师"
    profNameMap["Ranger"]       := "游侠"
    profNameMap["Revenant"]     := "魂武者"
    profNameMap["Thief"]        := "潜行者"
    profNameMap["Warrior"]      := "战士"

    if (profNameMap.Has(profId)) {
        return profNameMap[profId] . "（" . profId . "）"
    } else {
        return profId
    }
}

; ============================================
; 类别下拉
; ============================================
SkillPreset_FillCategories(ddlCat) {
    ddlCat.Delete()
    ddlCat.Add(["全部","武器","治疗","通用","职业","精英","工具包","工具带","怪物","宠物"])
    ddlCat.Choose(1)
}

; ============================================
; 特性下拉（按英文名映射中文）
; ============================================
SkillPreset_FillSpecs(ddlSpec, profId) {
    global SkillPreset_SpecIds

    specs := []
    try {
        specs := GW2_GetSpecsByProf(profId)
    } catch {
        Logger_Error("UI_SkillPreset", "GW2_GetSpecsByProf failed", Map("prof", profId))
        specs := []
    }

    SkillPreset_SpecIds := []
    ddlSpec.Delete()

    if (specs.Length = 0) {
        Logger_Warn("UI_SkillPreset", "No specs for profession", Map("prof", profId))
        ddlSpec.Add(["全部"])
        SkillPreset_SpecIds.Push(-1)
        ddlSpec.Choose(1)
        return
    }

    items := []
    idx := 1
    while (idx <= specs.Length) {
        s := specs[idx]
        specId := s.Id
        specName := s.Name

        displayName := SkillPreset_LocalizeSpecNameByName(specName)

        items.Push(displayName)
        SkillPreset_SpecIds.Push(specId)

        idx := idx + 1
    }

    ddlSpec.Add(items)
    ddlSpec.Choose(1)

    Logger_Info("UI_SkillPreset", "Specs filled", Map("prof", profId, "count", specs.Length))
}

; 特性本地化：按英文名字映射中文（核心+精英全职业）
SkillPreset_LocalizeSpecNameByName(nameIn) {
    ; 去掉“（精英）”后缀，保留原样以供回退
    baseName := nameIn
    pos := InStr(nameIn, "（")
    if (pos > 0) {
        baseName := SubStr(nameIn, 1, pos - 1)
    }

    specNameMap := Map()

    ; ===== Guardian 守护者 =====
    specNameMap["Zeal"]          := "热忱"
    specNameMap["Radiance"]      := "光辉"
    specNameMap["Valor"]         := "勇气"
    specNameMap["Honor"]         := "荣誉"
    specNameMap["Virtues"]       := "美德"
    specNameMap["Dragonhunter"]  := "猎龙手（精英）"
    specNameMap["Firebrand"]     := "燃火者（精英）"
    specNameMap["Willbender"]    := "破锋者（精英）"
    specNameMap["Luminary"]      := "圣辉者（精英）"

    ; ===== Warrior 战士 =====
    specNameMap["Strength"]      := "力量"
    specNameMap["Arms"]          := "武艺"
    specNameMap["Defense"]       := "防御"
    specNameMap["Tactics"]       := "战术"
    specNameMap["Discipline"]    := "纪律"
    specNameMap["Berserker"]     := "狂战士（精英）"
    specNameMap["Spellbreaker"]  := "破法者（精英）"
    specNameMap["Bladesworn"]    := "誓剑士（精英）"
    specNameMap["Paragon"]       := "圣言师（精英）"

    ; ===== Engineer 工程师 =====
    specNameMap["Explosives"]    := "爆破"
    specNameMap["Firearms"]      := "火器"
    specNameMap["Inventions"]    := "发明"
    specNameMap["Alchemy"]       := "炼金术"
    specNameMap["Tools"]         := "工具"
    specNameMap["Scrapper"]      := "机械师（精英）"
    specNameMap["Holosmith"]     := "全息师（精英）"
    specNameMap["Mechanist"]     := "玉堰师（精英）"
    specNameMap["Amalgam"]     := "鎏金师（精英）"

    ; ===== Ranger 游侠 =====
    specNameMap["Marksmanship"]       := "射术"
    specNameMap["Skirmishing"]        := "游击"
    specNameMap["Wilderness Survival"] := "荒野求生"
    specNameMap["Nature Magic"]       := "自然魔法"
    specNameMap["Beastmastery"]       := "驯兽"
    specNameMap["Druid"]              := "德鲁伊（精英）"
    specNameMap["Soulbeast"]          := "魂兽师（精英）"
    specNameMap["Untamed"]            := "狂兽师（精英）"
    specNameMap["Galeshot"]           := "风行者（精英）"

    ; ===== Thief 潜行者 =====
    specNameMap["Deadly Arts"]    := "致命技艺"
    specNameMap["Critical Strikes"]:= "暴击"
    specNameMap["Shadow Arts"]    := "暗影技艺"
    specNameMap["Acrobatics"]     := "杂技"
    specNameMap["Trickery"]       := "诡计"
    specNameMap["Daredevil"]      := "独行侠（精英）"
    specNameMap["Deadeye"]        := "神枪手（精英）"
    specNameMap["Specter"]        := "缚影者（精英）"
    specNameMap["Antiquary"]      := "彩戏师（精英）"

    ; ===== Elementalist 元素使 =====
    specNameMap["Fire"]           := "火焰"
    specNameMap["Air"]            := "空气"
    specNameMap["Earth"]          := "大地"
    specNameMap["Water"]          := "水系"
    specNameMap["Arcane"]         := "奥术"
    specNameMap["Tempest"]        := "风暴使（精英）"
    specNameMap["Weaver"]         := "编织者（精英）"
    specNameMap["Catalyst"]       := "元晶师（精英）"
    specNameMap["Evoker"]         := "唤元师（精英）"

    ; ===== Mesmer 幻术师 =====
    specNameMap["Domination"]     := "支配"
    specNameMap["Dueling"]        := "决斗"
    specNameMap["Chaos"]          := "混沌"
    specNameMap["Inspiration"]    := "灵感"
    specNameMap["Illusions"]      := "幻象"
    specNameMap["Chronomancer"]   := "时空术士（精英）"
    specNameMap["Mirage"]         := "幻象术士（精英）"
    specNameMap["Virtuoso"]       := "灵刃术士（精英）"
    specNameMap["Troubadour"]     := "吟游诗人（精英）"

    ; ===== Necromancer 死灵法师 =====
    specNameMap["Spite"]          := "恶意"
    specNameMap["Curses"]         := "诅咒"
    specNameMap["Death Magic"]    := "死亡魔法"
    specNameMap["Blood Magic"]    := "血魔法"
    specNameMap["Soul Reaping"]   := "灵魂收割"
    specNameMap["Reaper"]         := "夺魂者（精英）"
    specNameMap["Scourge"]        := "灾厄师（精英）"
    specNameMap["Harbinger"]      := "先驱者（精英）"
    specNameMap["Ritualist"]      := "祭祀者（精英）"

    ; ===== Revenant 魂武者 =====
    specNameMap["Corruption"]     := "腐化"
    specNameMap["Retribution"]    := "报复"
    specNameMap["Salvation"]      := "拯救"
    specNameMap["Invocation"]     := "祈愿"
    specNameMap["Devastation"]    := "毁灭"
    specNameMap["Herald"]         := "预告者（精英）"
    specNameMap["Renegade"]       := "龙魂使（精英）"
    specNameMap["Vindicator"]     := "裁决者（精英）"
    specNameMap["Conduit"]        := "契灵使（精英）"

    if (specNameMap.Has(baseName)) {
        return specNameMap[baseName]
    }

    ; 找不到映射则用原名（可能已经自带“（精英）”）
    return nameIn
}

; ============================================
; 武器下拉：根据当前职业+特性+类别填充
; ============================================
SkillPreset_FillWeapons(ddlWeapon, profId, specId, catKey) {
    global SkillPreset_WeaponTypes

    SkillPreset_WeaponTypes := []
    ddlWeapon.Delete()

    ; 非武器类别时，只显示“全部武器”
    if (catKey != "Weapon") {
        ddlWeapon.Add(["全部武器"])
        SkillPreset_WeaponTypes.Push("")
        ddlWeapon.Choose(1)
        return
    }

    ; 只看武器类技能，提取其中的 WeaponType
    skills := []
    try {
        skills := GW2_QuerySkills(profId, specId, "Weapon")
    } catch {
        Logger_Error("UI_SkillPreset", "GW2_QuerySkills for weapons failed", Map("prof", profId, "spec", specId))
        skills := []
    }

    typeSet := Map()
    idx := 1
    while (idx <= skills.Length) {
        s := skills[idx]
        wt := s.WeaponType
        if (wt != "") {
            if !typeSet.Has(wt) {
                typeSet[wt] := 1
            }
        }
        idx := idx + 1
    }

    ; 首项：全部武器
    items := []
    items.Push("全部武器")
    SkillPreset_WeaponTypes.Push("")

    ; 追加每种武器类型
    for wt, _ in typeSet {
        disp := SkillPreset_LocalizeWeaponType(wt)
        items.Push(disp)
        SkillPreset_WeaponTypes.Push(wt)
    }

    ddlWeapon.Add(items)
    ddlWeapon.Choose(1)

    Logger_Info("UI_SkillPreset", "Weapons filled", Map("prof", profId, "spec", specId, "count", typeSet.Count))
}

; 武器类型本地化：英文 WeaponType -> 中文名
SkillPreset_LocalizeWeaponType(wt) {
    wtMap := Map()
    wtMap["Axe"]       := "斧"
    wtMap["Dagger"]    := "匕首"
    wtMap["Focus"]     := "聚能器"
    wtMap["Greatsword"]:= "巨剑"
    wtMap["Hammer"]    := "巨锤"
    wtMap["Longbow"]   := "长弓"
    wtMap["Mace"]      := "钉锤"
    wtMap["Pistol"]    := "手枪"
    wtMap["Rifle"]     := "步枪"
    wtMap["Scepter"]   := "节杖"
    wtMap["Shield"]    := "盾牌"
    wtMap["Shortbow"]  := "短弓"
    wtMap["Staff"]     := "法杖"
    wtMap["Sword"]     := "单手剑"
    wtMap["Torch"]     := "火炬"
    wtMap["Warhorn"]   := "号角"
    wtMap["Trident"]   := "三叉戟"
    wtMap["Spear"]     := "长矛"
    wtMap["Speargun"]  := "鱼叉枪"

    ; 有些 JSON 里 weapon_type 可能为 "None" 或空
    if (wtMap.Has(wt)) {
        return wtMap[wt] . "（" . wt . "）"
    } else {
        if (wt = "" || wt = "None") {
            return "通用（无武器）"
        } else {
            return wt
        }
    }
}

; ============================================
; 获取当前选中的 职业 / 特性 / 类别 / 武器
; ============================================
SkillPreset_GetSelectedProfId() {
    global SkillPresetGUI
    global SkillPreset_ProfIds

    ddl := SkillPresetGUI.DdlProf
    idx := ddl.Value

    if (idx < 1) {
        return ""
    }
    if (idx > SkillPreset_ProfIds.Length) {
        return ""
    }

    return SkillPreset_ProfIds[idx]
}

SkillPreset_GetSelectedSpecId() {
    global SkillPresetGUI
    global SkillPreset_SpecIds

    ddl := SkillPresetGUI.DdlSpec
    idx := ddl.Value

    if (idx < 1) {
        return -1
    }
    if (idx > SkillPreset_SpecIds.Length) {
        return -1
    }

    return SkillPreset_SpecIds[idx]
}

SkillPreset_GetSelectedCatKey() {
    global SkillPresetGUI

    ddl := SkillPresetGUI.DdlCat
    txt := ddl.Text

    if (txt = "武器") {
        return "Weapon"
    }
    if (txt = "治疗") {
        return "Heal"
    }
    if (txt = "通用") {
        return "Utility"
    }
    if (txt = "职业") {
        return "Profession"
    }
    if (txt = "精英") {
        return "Elite"
    }
    if (txt = "工具包") {
        return "Bundle"
    }
    if (txt = "工具带") {
        return "Toolbelt"
    }
    if (txt = "怪物") {
        return "Monster"
    }
    if (txt = "宠物") {
        return "Pet"
    }
    return ""
}

SkillPreset_GetSelectedWeaponType() {
    global SkillPresetGUI
    global SkillPreset_WeaponTypes

    ddl := SkillPresetGUI.DdlWeapon
    idx := ddl.Value

    if (idx < 1) {
        return ""
    }
    if (idx > SkillPreset_WeaponTypes.Length) {
        return ""
    }

    return SkillPreset_WeaponTypes[idx]
}

; ============================================
; 事件：职业变更
; ============================================
SkillPreset_OnProfChange(ctrl, info := "") {
    global SkillPresetGUI

    profId := SkillPreset_GetSelectedProfId()
    if (profId = "") {
        Logger_Warn("UI_SkillPreset", "OnProfChange with empty profId")
        return
    }

    SkillPreset_FillSpecs(SkillPresetGUI.DdlSpec, profId)

    specId := SkillPreset_GetSelectedSpecId()
    catKey := SkillPreset_GetSelectedCatKey()

    SkillPreset_FillWeapons(SkillPresetGUI.DdlWeapon, profId, specId, catKey)
    SkillPreset_OnReload(SkillPresetGUI.BtnReload)
}

; ============================================
; 事件：特性变更
; ============================================
SkillPreset_OnSpecChange(ctrl, info := "") {
    global SkillPresetGUI

    profId := SkillPreset_GetSelectedProfId()
    if (profId = "") {
        Logger_Warn("UI_SkillPreset", "OnSpecChange with empty profId")
        return
    }

    specId := SkillPreset_GetSelectedSpecId()
    catKey := SkillPreset_GetSelectedCatKey()

    SkillPreset_FillWeapons(SkillPresetGUI.DdlWeapon, profId, specId, catKey)
    SkillPreset_OnReload(SkillPresetGUI.BtnReload)
}

; ============================================
; 事件：类别变更
; ============================================
SkillPreset_OnCatChange(ctrl, info := "") {
    global SkillPresetGUI

    profId := SkillPreset_GetSelectedProfId()
    if (profId = "") {
        Logger_Warn("UI_SkillPreset", "OnCatChange with empty profId")
        return
    }

    specId := SkillPreset_GetSelectedSpecId()
    catKey := SkillPreset_GetSelectedCatKey()

    SkillPreset_FillWeapons(SkillPresetGUI.DdlWeapon, profId, specId, catKey)
    SkillPreset_OnReload(SkillPresetGUI.BtnReload)
}

; ============================================
; 事件：刷新列表
; ============================================
SkillPreset_OnReload(ctrl, info := "") {
    global SkillPresetGUI

    profId := SkillPreset_GetSelectedProfId()
    if (profId = "") {
        Logger_Warn("UI_SkillPreset", "OnReload with empty profId")
        return
    }

    specId := SkillPreset_GetSelectedSpecId()
    catKey := SkillPreset_GetSelectedCatKey()
    weaponFilter := SkillPreset_GetSelectedWeaponType()

    skills := []
    try {
        skills := GW2_QuerySkills(profId, specId, catKey)
    } catch {
        Logger_Error("UI_SkillPreset", "GW2_QuerySkills failed", Map("prof", profId, "spec", specId, "cat", catKey))
        skills := []
    }

    Logger_Info("UI_SkillPreset", "Reload skills", Map("prof", profId, "spec", specId, "cat", catKey, "count", skills.Length, "weaponFilter", weaponFilter))

    lv := SkillPresetGUI.LV
    lv.Opt("-Redraw")
    lv.Delete()

    idx := 1
    while (idx <= skills.Length) {
        s := skills[idx]

        ; 按武器类型再过滤
        if (catKey = "Weapon") {
            if (weaponFilter != "") {
                if (s.WeaponType != weaponFilter) {
                    idx := idx + 1
                    continue
                }
            }
        }

        specName := "基础职业"
        if (s.SpecName != "") {
            specName := s.SpecName
        }

        weap := "-"
        if (s.WeaponType != "") {
            weap := s.WeaponType
        }

        lv.Add("", s.Name, s.Category, weap, specName, s.Slot, s.Id)

        idx := idx + 1
    }

    col := 1
    while (col <= 6) {
        try {
            lv.ModifyCol(col, "AutoHdr")
        } catch {
        }
        col := col + 1
    }

    lv.Opt("+Redraw")
}

; ============================================
; 事件：导入选中技能到当前配置
; 使用 Win32 LVM_GETNEXTITEM 枚举选中的行
; ============================================
SkillPreset_OnImport(ctrl, info := "") {
    global SkillPresetGUI

    lv := SkillPresetGUI.LV
    cand := []

    LVM_GETNEXTITEM := 0x100C
    LVNI_SELECTED   := 0x0002

    rowIndex := -1

    while (true) {
        rowIndex := DllCall("SendMessageW"
            , "ptr", lv.Hwnd
            , "uint", LVM_GETNEXTITEM
            , "ptr", rowIndex
            , "ptr", LVNI_SELECTED
            , "ptr")

        if (rowIndex = -1) {
            break
        }

        row := rowIndex + 1

        name := lv.GetText(row, 1)
        cat  := lv.GetText(row, 2)
        weap := lv.GetText(row, 3)
        spec := lv.GetText(row, 4)
        slot := lv.GetText(row, 5)
        idStr:= lv.GetText(row, 6)

        sid := 0
        try {
            sid := Integer(idStr)
        } catch {
            sid := 0
        }
        if (sid = 0) {
            continue
        }

        item := Map()
        item.Id         := sid
        item.Name       := name
        item.Category   := cat
        item.WeaponType := weap
        item.SpecName   := spec
        item.Slot       := slot

        cand.Push(item)
    }

    if (cand.Length = 0) {
        MsgBox "请先在列表中勾选至少一个技能。"
        return
    }

    Logger_Info("UI_SkillPreset", "Import skills", Map("count", cand.Length))
    Skills_ImportFromPreset(cand)
}

; ============================================
; 事件：关闭
; ============================================
SkillPreset_OnClose(ctrl, info := "") {
    global SkillPresetGUI

    if (SkillPresetGUI) {
        try {
            SkillPresetGUI.Hide()
        } catch {
        }
    }
}

; ============================================
; 事件：自适应布局
; ============================================
SkillPreset_OnResize(gui, minmax, w, h) {
    if (minmax = -1) {
        return
    }
    if (minmax = 1) {
        return
    }

    topY := 10
    gap  := 8
    leftX := 10
    rightMargin := 10

    try {
        gui.DdlProf.Move(leftX + 40, topY, 160)
        gui.DdlSpec.Move(,          topY, 220)
        gui.DdlCat.Move(,           topY, 80)
        gui.DdlWeapon.Move(,        topY, 150)
        gui.BtnReload.Move(,        topY, 80)
    } catch {
    }

    lvX := leftX
    lvY := topY + 28 + gap
    lvW := w - leftX - rightMargin
    lvH := h - lvY - 40
    if (lvH < 80) {
        lvH := 80
    }

    try {
        gui.LV.Move(lvX, lvY, lvW, lvH)
    } catch {
    }

    btnY := lvY + lvH + gap

    try {
        gui.BtnImport.Move(leftX, btnY, 150)
        gui.BtnClose.Move(,      btnY, 80)
    } catch {
    }
}