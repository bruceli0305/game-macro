#Requires AutoHotkey v2
;modules\storage\model\IdUtil.ahk 数据模型 Id 工具
; 确保 NextId 存在
PM_InitNextId(profile) {
    if !IsObject(profile) {
        return
    }
    if !profile.Has("Meta") {
        profile["Meta"] := Map()
    }
    meta := profile["Meta"]
    if !meta.Has("NextId") {
        nexts := Map()
        nexts["Skill"]  := 1
        nexts["Point"]  := 1
        nexts["Rule"]   := 1
        nexts["Track"]  := 1
        nexts["Gate"]   := 1
        nexts["Buff"]   := 1
        nexts["Thread"] := 1
        meta["NextId"] := nexts
    }
}

; 分配一个新 Id（自增，不回收）
PM_NextId(profile, moduleName) {
    PM_InitNextId(profile)
    id := 0
    try {
        id := profile["Meta"]["NextId"][moduleName]
    } catch {
        id := 1
    }
    if (id < 1) {
        id := 1
    }
    ; 下一个
    try {
        profile["Meta"]["NextId"][moduleName] := id + 1
    } catch {
    }
    return id
}

; 若对象无 Id，则分配；若已有 Id，确保 NextId 大于它
PM_AssignIdIfMissing(profile, moduleName, obj) {
    if !IsObject(obj) {
        return
    }
    if HasProp(obj, "Id") {
        if (obj.Id > 0) {
            PM_InitNextId(profile)
            cur := 0
            try {
                cur := profile["Meta"]["NextId"][moduleName]
            } catch {
                cur := 1
            }
            if (obj.Id >= cur) {
                profile["Meta"]["NextId"][moduleName] := obj.Id + 1
            }
            return
        }
    }
    newId := PM_NextId(profile, moduleName)
    obj.Id := newId
}

; 更新 ModifiedAt
PM_TouchModified(profile) {
    if IsObject(profile) && profile.Has("Meta") {
        try {
            profile["Meta"]["ModifiedAt"] := PM_NowStr()
        } catch {
        }
    }
}