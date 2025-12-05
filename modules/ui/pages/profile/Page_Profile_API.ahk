; ============================== modules\ui\pages\profile\Page_Profile_API.ahk ==============================
#Requires AutoHotkey v2
; Profile 公共 API（与页面解耦）
; 提供：Profile_RefreshAll_Strong() / Profile_SwitchProfile_Strong(name)
; 严格块结构，不使用单行 if/try/catch
global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Profile_RefreshAll_Strong() {
    global App, UI, g_Profile_Populating

    ; 1) 列出“有效配置”目录（含 meta.ini）
    names := []
    try {
        names := FS_ListProfilesValid()
        try {
            Logger_Info("Storage", "ListProfilesValid", Map("dir", App["ProfilesDir"], "count", names.Length))
        } catch {
        }
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
            try {
                Logger_Info("Storage", "ListProfilesValid", Map("dir", App["ProfilesDir"], "count", names.Length))
            } catch {
            }
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
    canFill := false
    if (IsSet(UI)) {
        try {
            if (HasProp(UI, "ProfilesDD") && UI.ProfilesDD) {
                canFill := true
            }
        } catch {
            canFill := false
        }
    }
    if (canFill) {
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
    }

    ; 5) 加载规范化（新存储）
    ok := false
    try {
        p := Storage_Profile_LoadFull(target)
        rt := PM_ToRuntime(p)
        App["CurrentProfile"] := target
        App["ProfileData"] := rt
        ok := true
    } catch as e {
        ok := false
        try {
            Logger_Exception("Storage", e, Map("where","Profile_RefreshAll_Strong.Load", "target", target))
        } catch {
        }
    }
    ; 首次进入也回填 General 区域，并初始化 Cast 引擎
    if (ok) {
        try {
            Profile_UI_ApplyGeneralFromApp()
        } catch {
        }
        try {
            CastEngine_InitFromProfile()
        } catch {
        }
        try {
            if HasProp(App["ProfileData"], "CastDebug") {
                CastDebug_RebindHotkey(App["ProfileData"].CastDebug.Hotkey)
                CastDebug_ApplyConfigFromProfile()
            }
        } catch {
        }
    }
    ; 6) 运行时后续（绑定热键/重建引擎/ROI）
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
    } catch as e {
        ok := false
        try {
            Logger_Exception("Storage", e, Map("where","Profile_SwitchProfile_Strong.Load", "name", name))
        } catch {
        }
    }
    if (!ok) {
        return false
    }
    ; 初始化 Cast 引擎（基于新的 ProfileData）
    try {
        CastEngine_InitFromProfile()
    } catch {
    }
    try {
        if HasProp(App["ProfileData"], "CastDebug") {
            CastDebug_RebindHotkey(App["ProfileData"].CastDebug.Hotkey)
            CastDebug_ApplyConfigFromProfile()
        }
    } catch {
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
        try {
            UI.HkStart.Value := App["ProfileData"].StartHotkey
        } catch {
        }
        try {
            UI.PollEdit.Value := App["ProfileData"].PollIntervalMs
        } catch {
        }
        try {
            UI.CdEdit.Value := App["ProfileData"].SendCooldownMs
        } catch {
        }
        try {
            UI.ChkPick.Value := (App["ProfileData"].PickHoverEnabled ? 1 : 0)
        } catch {
        }
        try {
            UI.OffYEdit.Value := App["ProfileData"].PickHoverOffsetY
        } catch {
        }
        try {
            UI.DwellEdit.Value := App["ProfileData"].PickHoverDwellMs
        } catch {
        }
        try {
            pk := "LButton"
            try {
                pk := App["ProfileData"].PickConfirmKey
            } catch {
                pk := "LButton"
            }
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

    ; 控件存在时填充（使用 HasProp 检测属性）
    canFill := false
    if (IsSet(UI)) {
        try {
            if (HasProp(UI, "ProfilesDD") && UI.ProfilesDD) {
                canFill := true
            }
        } catch {
            canFill := false
        }
    }
    if (!canFill) {
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
; 将 App.ProfileData 写回“概览与配置”页控件（仅在当前页为 profile 时生效）
Profile_UI_ApplyGeneralFromApp() {
    global UI, App, UI_CurrentPage, g_Profile_Populating

    canWriteUI := false
    try {
        if (IsSet(UI_CurrentPage) && UI_CurrentPage = "profile") {
            canWriteUI := true
        }
    } catch {
        canWriteUI := false
    }
    if (!canWriteUI) {
        return
    }

    g_Profile_Populating := true
    ; 热键（用回显逻辑，自动处理鼠标热键）
    try {
        Profile_UI_SetStartHotkeyEcho(App["ProfileData"].StartHotkey)
    } catch {
    }

    ; 数值类
    try {
        UI.PollEdit.Value := App["ProfileData"].PollIntervalMs
    } catch {
    }
    try {
        UI.CdEdit.Value := App["ProfileData"].SendCooldownMs
    } catch {
    }
    try {
        UI.ChkPick.Value := (App["ProfileData"].PickHoverEnabled ? 1 : 0)
    } catch {
    }
    try {
        UI.OffYEdit.Value := App["ProfileData"].PickHoverOffsetY
    } catch {
    }
    try {
        UI.DwellEdit.Value := App["ProfileData"].PickHoverDwellMs
    } catch {
    }

    ; 拾色热键下拉
    try {
        pk := "LButton"
        try {
            pk := App["ProfileData"].PickConfirmKey
        } catch {
            pk := "LButton"
        }
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

    g_Profile_Populating := false
}