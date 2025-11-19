; ============================== modules\ui\pages\profile\Page_Profile_API.ahk ==============================
#Requires AutoHotkey v2
; Profile 公共 API（与页面解耦）
; 提供：Profile_RefreshAll_Strong() / Profile_SwitchProfile_Strong(name)
; 严格块结构 if/try/catch，不使用单行形式
#Include "../../../storage/model/_index.ahk"
#Include "../../../storage/profile/_index.ahk"
#Include "../../../storage/profile/Normalize_Runtime.ahk"
#Include "../../../storage/profile/List.ahk"

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Profile_RefreshAll_Strong() {
    global App, UI, g_Profile_Populating

    ; 1) 列出“有效配置”目录（含 meta.ini）
    names := []
    try {
        names := FS_ListProfilesValid()
        Logger_Info("Storage", "ListProfilesValid", Map("dir", App["ProfilesDir"], "count", names.Length))
    } catch {
        names := []
    }

    ; 2) 没有则创建 Default 并重列
    if (names.Length = 0) {
        try {
            Storage_Profile_Create("Default")
        } catch {
        }
        try {
            names := FS_ListProfilesValid()
            Logger_Info("Storage", "ListProfilesValid", Map("dir", App["ProfilesDir"], "count", names.Length))
        } catch {
            names := []
        }
    }
    if (names.Length = 0) {
        ; 仍为空 -> 说明目录不可写或创建失败
        return false
    }

    ; 3) 选中目标
    target := ""
    try {
        if (App.Has("CurrentProfile") && App["CurrentProfile"] != "") {
            target := App["CurrentProfile"]
        }
    } catch {
        target := ""
    }
    if (target = "") {
        target := names[1]
    }

    ; 4) 回填下拉（控件存在才填）
    if (IsSet(UI) && UI.Has("ProfilesDD") && UI.ProfilesDD) {
        g_Profile_Populating := true
        try {
            UI.ProfilesDD.Delete()
            UI.ProfilesDD.Add(names)
            sel := 1
            i := 1
            while (i <= names.Length) {
                if (names[i] = target) {
                    sel := i
                    break
                }
                i := i + 1
            }
            UI.ProfilesDD.Value := sel
        } catch {
        }
        g_Profile_Populating := false
    }

    ; 5) 加载规范化（保持你之前的逻辑）
    ok := false
    try {
        p := Storage_Profile_LoadFull(target)
        rt := PM_ToRuntime(p)
        App["CurrentProfile"] := target
        App["ProfileData"] := rt
        ok := true
    } catch {
        ok := false
    }

    ; 6) 运行时后续（绑定热键/重建引擎/ROI），同你既有代码
    try Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    catch
    try WorkerPool_Rebuild()
    catch
    try Counters_Init()
    catch
    try Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    catch
    try Rotation_Reset(), Rotation_InitFromProfile()
    catch

    return ok
}

Profile_SwitchProfile_Strong(name) {
    global App, UI, UI_CurrentPage

    ; 加载文件夹配置 → 规范化
    ok := false
    try {
        p := Storage_Profile_LoadFull(name)
        rt := PM_ToRuntime(p)
        App["CurrentProfile"] := name
        App["ProfileData"] := rt
        ok := true
    } catch {
        ok := false
    }
    if (!ok) {
        return false
    }

    ; 将值回填到“概览与配置”页（若当前页）
    canWriteUI := false
    try {
        if (IsSet(UI_CurrentPage) && UI_CurrentPage = "profile") {
            canWriteUI := true
        }
    } catch {
        canWriteUI := false
    }
    if (canWriteUI) {
        try UI.HkStart.Value := App["ProfileData"].StartHotkey
        try UI.PollEdit.Value := App["ProfileData"].PollIntervalMs
        try UI.CdEdit.Value := App["ProfileData"].SendCooldownMs
        try UI.ChkPick.Value := (App["ProfileData"].PickHoverEnabled ? 1 : 0)
        try UI.OffYEdit.Value := App["ProfileData"].PickHoverOffsetY
        try UI.DwellEdit.Value := App["ProfileData"].PickHoverDwellMs
        try {
            pk := "LButton"
            try pk := App["ProfileData"].PickConfirmKey
            opts := ["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"]
            pos := 1
            i := 1
            while (i <= opts.Length) {
                if (opts[i] = pk) {
                    pos := i
                    break
                }
                i := i + 1
            }
            UI.DdPickKey.Value := pos
        } catch {
        }
        try {
            Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
        } catch {
        }
    }

    ; 运行时重建
    try {
        Hotkeys_BindStartHotkey(App["ProfileData"].StartHotkey)
    } catch {
    }
    try {
        WorkerPool_Rebuild()
    } catch {
    }
    try {
        Counters_Init()
    } catch {
    }
    try {
        Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false)
    } catch {
    }
    try {
        Rotation_Reset()
        Rotation_InitFromProfile()
    } catch {
    }
    try {
        Dup_OnProfileChanged()
    } catch {
    }

    return true
}
; 填充配置下拉（仅 UI；不做加载/重建）
Profile_UI_PopulateProfilesDD(target := "") {
    global UI, App, g_Profile_Populating

    names := []
    try {
        names := FS_ListProfilesValid()
    } catch {
        names := []
    }

    ; 如首次启动仍无有效配置，尝试创建 Default 再重列
    if (names.Length = 0) {
        try {
            Storage_Profile_Create("Default")
        } catch {
        }
        try {
            names := FS_ListProfilesValid()
        } catch {
            names := []
        }
    }
    if (names.Length = 0) {
        ; 仍为空，目录不可写或其他原因，UI 保持空
        return false
    }

    ; 计算目标项：优先传入 target，其次 App.CurrentProfile，最后第一个
    if (target = "") {
        try {
            if (IsSet(App) && App.Has("CurrentProfile") && App["CurrentProfile"] != "") {
                target := App["CurrentProfile"]
            }
        } catch {
            target := ""
        }
        if (target = "") {
            target := names[1]
        }
    }

    ; 控件存在时填充
    if !(IsSet(UI) && UI.Has("ProfilesDD") && UI.ProfilesDD) {
        return false
    }

    g_Profile_Populating := true
    try {
        UI.ProfilesDD.Delete()
    } catch {
    }
    try {
        UI.ProfilesDD.Add(names)
    } catch {
    }

    sel := 1
    i := 1
    while (i <= names.Length) {
        if (names[i] = target) {
            sel := i
            break
        }
        i := i + 1
    }
    try {
        UI.ProfilesDD.Value := sel
    } catch {
    }
    g_Profile_Populating := false
    return true
}