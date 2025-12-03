; ============================================
; modules\gw2\GW2_DB.ahk
; GW2 职业 / 专精 / 技能索引（AHK v2）
; 依赖：modules\util\JsonWrapper.ahk （内部使用 jsongo.Parse）
; ============================================
#Requires AutoHotkey v2
#Include "..\util\JsonWrapper.ahk"

global GW2_DB_Ready       := false

global GW2_Professions    := Map()  ; "Guardian" => { Id, Name }
global GW2_SpecById       := Map()  ; specId => specObj (specializations.json 每一条)
global GW2_SkillIndex     := Map()  ; skillId => info Map
global GW2_SkillsByProf   := Map()  ; "Guardian" => [ info, info, ... ]

; 用于根据职业+专精名找到 specId
global GW2_SpecByProfName := Map()  ; "Guardian|Zeal" => specObj

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

    profObj := Json_Load(profStr)   ; Map("Guardian" => {...}, "Elementalist" => {...}, ...)
    specArr := Json_Load(specStr)  ; 专精数组
    skillArr:= Json_Load(skillStr) ; 技能数组

    GW2_BuildSpecIndex(specArr)
    GW2_BuildProfessionIndex(profObj)
    GW2_BuildSkillIndex(profObj, skillArr)

    GW2_DB_Ready := true

    ; 可选：打一个总 spec 数的日志，方便确认 JSON 是否全量
    ;Logger_Info("GW2_DB", "EnsureLoaded", Map("specCount", GW2_SpecById.Count, "profCount", GW2_Professions.Count))
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
; 完全基于 specializations.json 中的 profession 字段，不依赖 GW2_Professions.SpecList
GW2_GetSpecsByProf(profId) {
    global GW2_SpecById

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

    if (profId = "") {
        Logger_Info("GW2_DB", "GetSpecsByProf empty profId", Map("prof", profId, "count", arr.Length))
        return arr
    }

    for sid, spec in GW2_SpecById {
        profName := ""
        if spec.Has("profession") {
            profName := spec["profession"]
        }
        if (profName != profId) {
            continue
        }

        item := Map()
        item.Id := sid

        nm := ""
        if spec.Has("name") {
            nm := spec["name"]
        } else {
            nm := "" sid
        }

        eliteFlag := 0
        if spec.Has("elite") {
            if (spec["elite"]) {
                eliteFlag := 1
            }
        }

        if (eliteFlag) {
            item.Name := nm "（精英）"
        } else {
            item.Name := nm
        }

        arr.Push(item)
    }

    Logger_Info("GW2_DB", "GetSpecsByProf", Map("prof", profId, "count", arr.Length))
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

    idx := 1
    while (idx <= list.Length) {
        info := list[idx]

        if (bigCatKey != "") {
            if (info.Category != bigCatKey) {
                idx := idx + 1
                continue
            }
        }

        if (specIdFilter = -1) {
            ; 全部
        } else if (specIdFilter = 0) {
            if (info.SpecId != 0) {
                idx := idx + 1
                continue
            }
        } else {
            if (info.SpecId != specIdFilter) {
                idx := idx + 1
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
        idx := idx + 1
    }

    return result
}
; ============================================
; 内部构建：专精索引（specializations.json）
; ============================================

GW2_BuildSpecIndex(specObj) {
    global GW2_SpecById
    global GW2_SpecByProfName
    GW2_SpecById.Clear()
    GW2_SpecByProfName.Clear()
    for profKey, arr in specObj {
        ; 跳过非数组的值（防御）
        if !(arr is Array) {
            continue
        }

        idx := 1
        while (idx <= arr.Length) {
            spec := arr[idx]

            sid := 0
            if spec.Has("id") {
                sid := spec["id"]
            }
            if !IsInteger(sid) {
                idx := idx + 1
                continue
            }
            if (sid = 0) {
                idx := idx + 1
                continue
            }

            ; 存入全局 Id -> spec 表
            GW2_SpecById[sid] := spec

            ; profession 字段优先使用 JSON 里的，如果没有就用 profKey
            profName := profKey
            if spec.Has("profession") {
                profName := spec["profession"]
            }

            specName := ""
            if spec.Has("name") {
                specName := spec["name"]
            } else {
                specName := "" sid
            }

            key := profName "|" specName
            GW2_SpecByProfName[key] := spec

            idx := idx + 1
        }
    }

    ; 调试日志：专精总数
    Logger_Info("GW2_DB", "BuildSpecIndex", Map("specCount", GW2_SpecById.Count))
}
; ============================================
; 内部构建：职业索引（仅 Id / Name）
; ============================================

GW2_BuildProfessionIndex(profObj) {
    global GW2_Professions

    GW2_Professions.Clear()

    if (profObj is Array) {
        idx := 1
        while (idx <= profObj.Length) {
            p := profObj[idx]
            profKey := ""
            if p.Has("id") {
                profKey := p["id"]
            }
            if (profKey = "") {
                idx := idx + 1
                continue
            }

            info := Map()
            info.Id := profKey
            if p.Has("name") {
                info.Name := p["name"]
            } else {
                info.Name := profKey
            }

            GW2_Professions[profKey] := info
            idx := idx + 1
        }
    } else {
        ; Map 形式："Guardian" => {...}
        for profKey, p in profObj {
            info := Map()
            info.Id := profKey
            if p.Has("name") {
                info.Name := p["name"]
            } else {
                info.Name := profKey
            }
            GW2_Professions[profKey] := info
        }
    }

    ;Logger_Info("GW2_DB", "BuildProfessionIndex", Map("profCount", GW2_Professions.Count))
}

; ============================================
; 内部构建：技能索引（两遍）
; ============================================

GW2_BuildSkillIndex(profObj, skillArr) {
    global GW2_SkillIndex
    global GW2_SkillsByProf
    global GW2_SpecByProfName

    GW2_SkillIndex.Clear()
    GW2_SkillsByProf.Clear()

    ; 1) id->技能详细 Map
    skillById := Map()
    idx := 1
    while (idx <= skillArr.Length) {
        s := skillArr[idx]
        sid := 0
        if s.Has("id") {
            sid := s["id"]
        }
        if !IsInteger(sid) {
            idx := idx + 1
            continue
        }
        if (sid = 0) {
            idx := idx + 1
            continue
        }
        skillById[sid] := s
        idx := idx + 1
    }

    ; 2) 第一遍：p.skills / p.weapons[*].skills
    if (profObj is Array) {
        idx := 1
        while (idx <= profObj.Length) {
            p := profObj[idx]
            profKey := ""
            if p.Has("id") {
                profKey := p["id"]
            }
            if (profKey != "") {
                GW2_BuildSkillIndex_ForProf(profKey, p, skillById)
            }
            idx := idx + 1
        }
    } else {
        for profKey, p in profObj {
            GW2_BuildSkillIndex_ForProf(profKey, p, skillById)
        }
    }

    ; 3) 第二遍：通过 training 里的 Specializations/EliteSpecializations 给技能打 SpecId / SpecName
    if (profObj is Array) {
        idx := 1
        while (idx <= profObj.Length) {
            p := profObj[idx]
            profKey := ""
            if p.Has("id") {
                profKey := p["id"]
            }
            if (profKey != "") {
                GW2_BuildSkillIndex_AssignSpecs(profKey, p)
            }
            idx := idx + 1
        }
    } else {
        for profKey, p in profObj {
            GW2_BuildSkillIndex_AssignSpecs(profKey, p)
        }
    }
}

GW2_BuildSkillIndex_ForProf(profKey, p, skillById) {
    global GW2_SkillIndex
    global GW2_SkillsByProf

    if !GW2_SkillsByProf.Has(profKey) {
        GW2_SkillsByProf[profKey] := []
    }
    list := GW2_SkillsByProf[profKey]

    ; 职业技能：p.skills
    if p.Has("skills") {
        i := 1
        while (i <= p["skills"].Length) {
            ps := p["skills"][i]
            sid := 0
            if ps.Has("id") {
                sid := ps["id"]
            }
            if !IsInteger(sid) {
                i := i + 1
                continue
            }
            if (sid = 0) {
                i := i + 1
                continue
            }
            if !skillById.Has(sid) {
                i := i + 1
                continue
            }

            sfull := skillById[sid]
            stype := ""
            sslot := ""
            swt   := "None"

            if sfull.Has("type") {
                stype := sfull["type"]
            }
            if sfull.Has("slot") {
                sslot := sfull["slot"]
            }
            if sfull.Has("weapon_type") {
                swt := sfull["weapon_type"]
            }

            cat := ""
            if (stype = "Heal") {
                cat := "Heal"
            } else if (stype = "Utility") {
                cat := "Utility"
            } else if (stype = "Elite") {
                cat := "Elite"
            } else if (stype = "Profession") {
                cat := "Profession"
            } else if (stype = "Bundle") {
                cat := "Bundle"
            } else if (stype = "Toolbelt") {
                cat := "Toolbelt"
            } else if (stype = "Monster") {
                cat := "Monster"
            } else if (stype = "Pet") {
                cat := "Pet"
            } else {
                i := i + 1
                continue
            }

            info := Map()
            info.Id         := sid
            info.Name       := sfull["name"]
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

            i := i + 1
        }
    }

    ; 武器技能：p.weapons[weaponName].skills[]
    if p.Has("weapons") {
        for weaponName, w in p["weapons"] {
            wSpecId := 0
            if w.Has("specialization") {
                wSpecId := w["specialization"]
            }

            if w.Has("skills") {
                j := 1
                while (j <= w["skills"].Length) {
                    ws := w["skills"][j]
                    sid := 0
                    if ws.Has("id") {
                        sid := ws["id"]
                    }
                    if !IsInteger(sid) {
                        j := j + 1
                        continue
                    }
                    if (sid = 0) {
                        j := j + 1
                        continue
                    }
                    if !skillById.Has(sid) {
                        j := j + 1
                        continue
                    }

                    sfull := skillById[sid]
                    wslot := ""
                    if ws.Has("slot") {
                        wslot := ws["slot"]
                    }

                    info := Map()
                    info.Id         := sid
                    info.Name       := sfull["name"]
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

                    j := j + 1
                }
            }
        }
    }
}

GW2_BuildSkillIndex_AssignSpecs(profKey, p) {
    global GW2_SkillIndex
    global GW2_SpecByProfName

    if !p.Has("training") {
        return
    }

    i := 1
    while (i <= p["training"].Length) {
        t := p["training"][i]

        if !t.Has("category") {
            i := i + 1
            continue
        }
        cat := t["category"]
        if (cat != "Specializations" && cat != "EliteSpecializations") {
            i := i + 1
            continue
        }

        if !t.Has("name") {
            i := i + 1
            continue
        }
        tname := t["name"]

        key := profKey "|" tname
        if !GW2_SpecByProfName.Has(key) {
            i := i + 1
            continue
        }

        spec := GW2_SpecByProfName[key]
        specId   := 0
        specName := ""

        if spec.Has("id") {
            specId := spec["id"]
        }
        if spec.Has("name") {
            specName := spec["name"]
        }

        if !t.Has("track") {
            i := i + 1
            continue
        }

        j := 1
        while (j <= t["track"].Length) {
            step := t["track"][j]
            if !step.Has("type") {
                j := j + 1
                continue
            }
            stype := step["type"]
            if (stype != "Skill") {
                j := j + 1
                continue
            }

            sid := 0
            if step.Has("skill_id") {
                sid := step["skill_id"]
            }
            if !IsInteger(sid) {
                j := j + 1
                continue
            }
            if (sid = 0) {
                j := j + 1
                continue
            }
            if !GW2_SkillIndex.Has(sid) {
                j := j + 1
                continue
            }

            info := GW2_SkillIndex[sid]
            info.SpecId   := specId
            info.SpecName := specName

            j := j + 1
        }

        i := i + 1
    }
}