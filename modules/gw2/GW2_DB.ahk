; ============================================
; modules\gw2\GW2_DB.ahk
; GW2 职业 / 专精 / 技能索引（数据层）
; 依赖：modules\util\JsonWrapper.ahk（内部用 jsongo.Parse）
; ============================================
#Requires AutoHotkey v2
#Include "..\util\JsonWrapper.ahk"

global GW2_DB_Ready       := false
global GW2_Professions    := Map()  ; "Guardian" => { Id, Name, SpecIds:[], SpecList:[] }
global GW2_SpecById       := Map()  ; specId => specObj
global GW2_SpecByProfName := Map()  ; "Guardian|Dragonhunter" => specObj
global GW2_SkillIndex     := Map()  ; skillId => info Map
global GW2_SkillsByProf   := Map()  ; "Guardian" => [ info, info, ... ]

; ============================================
; 外部接口
; ============================================

GW2_DB_EnsureLoaded() {
    global GW2_DB_Ready

    if (GW2_DB_Ready) {
        return
    }

    profJsonFile  := A_ScriptDir "\data\gw2\professions\professions_all.json"
    specJsonFile  := A_ScriptDir "\data\gw2\professions\specializations_all.json"
    skillJsonFile := A_ScriptDir "\data\gw2\skills_all.json"

    if !FileExist(profJsonFile) {
        throw Error("找不到职业 JSON 文件: " profJsonFile)
    }
    if !FileExist(specJsonFile) {
        throw Error("找不到专精 JSON 文件: " specJsonFile)
    }
    if !FileExist(skillJsonFile) {
        throw Error("找不到技能 JSON 文件: " skillJsonFile)
    }

    profStr := FileRead(profJsonFile, "UTF-8")
    specStr := FileRead(specJsonFile, "UTF-8")
    skillStr:= FileRead(skillJsonFile, "UTF-8")

    profObj := Json_Load(profStr)   ; 可能是 Map("Guardian"=>{...},...) 或数组
    specArr := Json_Load(specStr)  ; 专精数组
    skillArr:= Json_Load(skillStr) ; 技能数组

    GW2_BuildSpecIndex(specArr)
    GW2_BuildProfessionIndex(profObj)
    GW2_BuildSkillIndex(profObj, skillArr)

    GW2_DB_Ready := true
}

; 返回：[{Id:"Guardian", Name:"Guardian"}, ...]
GW2_GetProfessions() {
    global GW2_Professions

    GW2_DB_EnsureLoaded()

    out := []
    for profKey, p in GW2_Professions {
        item := Map()
        item.Id   := p.Id
        item.Name := p.Name
        out.Push(item)
    }
    return out
}

; 返回：[{Id:-1, Name:"全部"}, {Id:0, Name:"基础职业"}, {Id:xx, Name:"某特性"}, ...]
GW2_GetSpecsByProf(profId) {
    global GW2_Professions

    GW2_DB_EnsureLoaded()

    arr := []

    allItem := Map()
    allItem.Id   := -1
    allItem.Name := "全部"
    arr.Push(allItem)

    coreItem := Map()
    coreItem.Id   := 0
    coreItem.Name := "基础职业"
    arr.Push(coreItem)

    if !GW2_Professions.Has(profId) {
        return arr
    }

    p := GW2_Professions[profId]

    for idx, s in p.SpecList {
        item := Map()
        item.Id := s.Id
        if (s.Elite) {
            item.Name := s.Name "（精英）"
        } else {
            item.Name := s.Name
        }
        arr.Push(item)
    }

    return arr
}

; specIdFilter: -1=全部, 0=基础职业, >0=指定特性线/精英
; bigCatKey: "Weapon" / "Heal" / "Utility"
; 返回：[{Id, Name, Category, WeaponType, SpecName, Slot}, ...]
GW2_QuerySkills(profId, specIdFilter, bigCatKey) {
    global GW2_SkillsByProf

    GW2_DB_EnsureLoaded()

    result := []

    if !GW2_SkillsByProf.Has(profId) {
        return result
    }

    list := GW2_SkillsByProf[profId]

    for idx, info in list {
        if (bigCatKey != "") {
            if (info.Category != bigCatKey) {
                continue
            }
        }

        if (specIdFilter = -1) {
            ; 全部
        } else if (specIdFilter = 0) {
            if (info.SpecId != 0) {
                continue
            }
        } else {
            if (info.SpecId != specIdFilter) {
                continue
            }
        }

        item := Map()
        item.Id         := info.Id
        item.Name       := info.Name
        item.Category   := info.Category
        item.WeaponType := info.WeaponType
        item.SpecName   := info.SpecName
        item.Slot       := info.Slot

        result.Push(item)
    }

    return result
}

; ============================================
; 内部构建：专精索引
; ============================================

GW2_BuildSpecIndex(specArr) {
    global GW2_SpecById
    global GW2_SpecByProfName

    for idx, spec in specArr {
        sid := 0
        if spec.Has("id") {
            sid := spec.id
        }

        if !IsInteger(sid) {
            continue
        }
        if (sid = 0) {
            continue
        }

        GW2_SpecById[sid] := spec

        prof := ""
        name := ""

        if spec.Has("profession") {
            prof := spec.profession
        }
        if spec.Has("name") {
            name := spec.name
        }

        if (prof != "" && name != "") {
            key := prof "|" name
            GW2_SpecByProfName[key] := spec
        }
    }
}

; ============================================
; 内部构建：职业索引（简要信息 + 专精列表）
; ============================================

GW2_BuildProfessionIndex(profObj) {
    global GW2_Professions
    global GW2_SpecById

    if (profObj is Array) {
        for idx, p in profObj {
            profKey := ""
            if p.Has("id") {
                profKey := p.id
            }
            if (profKey = "") {
                continue
            }

            info := Map()
            info.Id := profKey
            if p.Has("name") {
                info.Name := p.name
            } else {
                info.Name := profKey
            }

            specIds := []
            if p.Has("specializations") {
                for j, sid in p.specializations {
                    specIds.Push(sid)
                }
            }
            info.SpecIds := specIds

            specList := []
            for j, sid in specIds {
                if GW2_SpecById.Has(sid) {
                    s := GW2_SpecById[sid]
                    one := Map()
                    one.Id   := sid
                    one.Name := s.name
                    if s.Has("elite") {
                        if (s.elite) {
                            one.Elite := 1
                        } else {
                            one.Elite := 0
                        }
                    } else {
                        one.Elite := 0
                    }
                    specList.Push(one)
                }
            }
            info.SpecList := specList

            GW2_Professions[profKey] := info
        }
    } else {
        ; Map 形式："Guardian" => {...}
        for profKey, p in profObj {
            info := Map()
            info.Id := profKey
            if p.Has("name") {
                info.Name := p.name
            } else {
                info.Name := profKey
            }

            specIds := []
            if p.Has("specializations") {
                for j, sid in p.specializations {
                    specIds.Push(sid)
                }
            }
            info.SpecIds := specIds

            specList := []
            for j, sid in specIds {
                if GW2_SpecById.Has(sid) {
                    s := GW2_SpecById[sid]
                    one := Map()
                    one.Id   := sid
                    one.Name := s.name
                    if s.Has("elite") {
                        if (s.elite) {
                            one.Elite := 1
                        } else {
                            one.Elite := 0
                        }
                    } else {
                        one.Elite := 0
                    }
                    specList.Push(one)
                }
            }
            info.SpecList := specList

            GW2_Professions[profKey] := info
        }
    }
}

; ============================================
; 内部构建：技能索引（两遍）
; ============================================

GW2_BuildSkillIndex(profObj, skillArr) {
    global GW2_SkillIndex
    global GW2_SkillsByProf

    ; 1) 先把技能数组做成 id -> 完整技能 的 Map
    skillById := Map()
    for idx, s in skillArr {
        sid := 0
        if s.Has("id") {
            sid := s.id
        }
        if !IsInteger(sid) {
            continue
        }
        if (sid = 0) {
            continue
        }
        skillById[sid] := s
    }

    ; 2) 第一遍：根据 p.skills / p.weapons[*].skills 建基础索引
    if (profObj is Array) {
        for idx, p in profObj {
            profKey := ""
            if p.Has("id") {
                profKey := p.id
            }
            if (profKey = "") {
                continue
            }
            GW2_BuildSkillIndex_ForProf(profKey, p, skillById)
        }
    } else {
        for profKey, p in profObj {
            GW2_BuildSkillIndex_ForProf(profKey, p, skillById)
        }
    }

    ; 3) 第二遍：根据 p.training 把技能挂到对应 SpecId
    if (profObj is Array) {
        for idx, p in profObj {
            profKey := ""
            if p.Has("id") {
                profKey := p.id
            }
            if (profKey = "") {
                continue
            }
            GW2_BuildSkillIndex_AssignSpecs(profKey, p)
        }
    } else {
        for profKey, p in profObj {
            GW2_BuildSkillIndex_AssignSpecs(profKey, p)
        }
    }
}

; 单个职业：处理 p.skills 和 p.weapons[*].skills
GW2_BuildSkillIndex_ForProf(profKey, p, skillById) {
    global GW2_SkillIndex
    global GW2_SkillsByProf

    if !GW2_SkillsByProf.Has(profKey) {
        GW2_SkillsByProf[profKey] := []
    }
    list := GW2_SkillsByProf[profKey]

    ; 2.1 职业技能：Heal / Utility / Elite / Profession -> 归类到 Heal/Utility
    if p.Has("skills") {
        for i, ps in p.skills {
            sid := 0
            if ps.Has("id") {
                sid := ps.id
            }
            if !IsInteger(sid) {
                continue
            }
            if (sid = 0) {
                continue
            }
            if !skillById.Has(sid) {
                continue
            }

            sfull := skillById[sid]
            stype := ""
            sslot := ""
            swt   := "None"

            if sfull.Has("type") {
                stype := sfull.type
            }
            if sfull.Has("slot") {
                sslot := sfull.slot
            }
            if sfull.Has("weapon_type") {
                swt := sfull.weapon_type
            }

            cat := ""
            if (stype = "Heal") {
                cat := "Heal"
            } else if (stype = "Utility" || stype = "Elite" || stype = "Profession") {
                cat := "Utility"
            } else {
                continue
            }

            info := Map()
            info.Id         := sid
            info.Name       := sfull.name
            info.Profession := profKey
            info.Type       := stype
            info.Slot       := sslot
            info.WeaponType := swt
            info.Category   := cat
            info.SpecId     := 0
            info.SpecName   := ""
            info.Source     := "Profession"

            GW2_SkillIndex[sid] := info
            list.Push(info)
        }
    }

    ; 2.2 武器技能：p.weapons[weaponName].skills[] -> Category="Weapon"
    if p.Has("weapons") {
        for weaponName, w in p.weapons {
            wSpecId := 0
            if w.Has("specialization") {
                wSpecId := w.specialization
            }

            if w.Has("skills") {
                for j, ws in w.skills {
                    sid := 0
                    if ws.Has("id") {
                        sid := ws.id
                    }
                    if !IsInteger(sid) {
                        continue
                    }
                    if (sid = 0) {
                        continue
                    }
                    if !skillById.Has(sid) {
                        continue
                    }

                    sfull := skillById[sid]
                    wslot := ""
                    if ws.Has("slot") {
                        wslot := ws.slot
                    }

                    info := Map()
                    info.Id         := sid
                    info.Name       := sfull.name
                    info.Profession := profKey
                    info.Type       := "Weapon"
                    info.Slot       := wslot
                    info.WeaponType := weaponName
                    info.Category   := "Weapon"
                    info.SpecId     := wSpecId
                    info.SpecName   := ""
                    info.Source     := "Weapon"

                    GW2_SkillIndex[sid] := info
                    list.Push(info)
                }
            }
        }
    }
}

; 根据 p.training 里的 Specializations / EliteSpecializations 给技能标记 SpecId
GW2_BuildSkillIndex_AssignSpecs(profKey, p) {
    global GW2_SkillIndex
    global GW2_SpecByProfName

    if !p.Has("training") {
        return
    }

    for i, t in p.training {
        if !t.Has("category") {
            continue
        }
        cat := t.category
        if (cat != "Specializations" && cat != "EliteSpecializations") {
            continue
        }

        if !t.Has("name") {
            continue
        }
        tname := t.name

        key := profKey "|" tname
        if !GW2_SpecByProfName.Has(key) {
            continue
        }

        spec := GW2_SpecByProfName[key]
        specId   := 0
        specName := ""

        if spec.Has("id") {
            specId := spec.id
        }
        if spec.Has("name") {
            specName := spec.name
        }

        if !t.Has("track") {
            continue
        }

        for j, step in t.track {
            if !step.Has("type") {
                continue
            }
            stype := step.type
            if (stype != "Skill") {
                continue
            }

            sid := 0
            if step.Has("skill_id") {
                sid := step.skill_id
            }
            if !IsInteger(sid) {
                continue
            }
            if (sid = 0) {
                continue
            }
            if !GW2_SkillIndex.Has(sid) {
                continue
            }

            info := GW2_SkillIndex[sid]
            info.SpecId   := specId
            info.SpecName := specName
        }
    }
}