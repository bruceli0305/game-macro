#Requires AutoHotkey v2
;Page_Profile_API.ahk
; Profile 公共 API（与页面解耦）
; 提供：Profile_RefreshAll_Strong() / Profile_SwitchProfile_Strong(name)
; 严格块结构 if/try/catch，不使用单行形式
; 增强：控件就绪判定更稳健，避免“未渲染”的误判；加入详细日志。

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Profile_RefreshAll_Strong() {
    global App, UI, g_Profile_Populating
    UI_Trace("Profile_RefreshAll_Strong begin")

    try {
        if !IsSet(App) {
            App := Map()
            UI_Trace("App map created")
        }
        if !App.Has("ProfilesDir") {
            App["ProfilesDir"] := A_ScriptDir "\Profiles"
            UI_Trace("ProfilesDir default=" App["ProfilesDir"])
        }
        if !App.Has("ConfigExt") {
            App["ConfigExt"] := ".ini"
        }
        DirCreate(App["ProfilesDir"])
    } catch as e {
        UI_Trace("Ensure App/dir exception: " e.Message)
    }

    names := []
    try {
        names := Storage_ListProfiles()
        UI_Trace("ListProfiles count=" names.Length)
    } catch as e {
        UI_Trace("ListProfiles exception: " e.Message)
        names := []
    }
    if (names.Length = 0) {
        try {
            data := Core_DefaultProfileData()
            Storage_SaveProfile(data)
            names := Storage_ListProfiles()
            UI_Trace("Created default profile, count=" names.Length)
        } catch as e {
            UI_Trace("Create default profile failed: " e.Message)
            names := []
        }
    }
    if (names.Length = 0) {
        UI_Trace("No profiles, abort")
        return false
    }

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
    UI_Trace("Target profile=" target)

    ; 4) 刷新 UI 下拉：直接探测控件对象可用性，避免 Has 判定误差
    dd := 0
    ready := false
    try {
        if (IsSet(UI)) {
            dd := UI.ProfilesDD
            if (dd) {
                ready := true
            }
        }
    } catch {
        ready := false
    }

    if (ready) {
        try {
            g_Profile_Populating := true
            UI_Trace("Fill ProfilesDD begin (ready=1)")
            dd.Delete()
            dd.Add(names)

            sel := 1
            i := 0
            for _, nm in names {
                i := i + 1
                if (nm = target) {
                    sel := i
                    break
                }
            }
            dd.Value := sel
            UI_Trace("Fill ProfilesDD done, sel=" sel)
        } catch as e {
            UI_Trace("Fill ProfilesDD exception: " e.Message)
        } finally {
            g_Profile_Populating := false
        }
    } else {
        UI_Trace("ProfilesDD not ready (skip fill)")
    }

    ok := false
    try {
        ok := Profile_SwitchProfile_Strong(target)
    } catch as e {
        UI_Trace("SwitchProfile exception: " e.Message)
        ok := false
    }
    UI_Trace("Profile_RefreshAll_Strong end ok=" ok)
    return ok
}

Profile_SwitchProfile_Strong(name) {
    global App, UI, UI_CurrentPage
    UI_Trace("SwitchProfile name=" name)

    prof := 0
    try {
        App["CurrentProfile"] := name
        prof := Storage_LoadProfile(name)
        App["ProfileData"] := prof
        nm := ""
        try {
            nm := HasProp(prof, "Name") ? prof.Name : ""
        } catch {
            nm := ""
        }
        UI_Trace("Profile loaded name=" nm)
    } catch as e {
        UI_Trace("Storage_LoadProfile exception: " e.Message)
        return false
    }

    ; 仅在 Profile 页激活且控件存在时，写回 UI
    canWriteUI := false
    try {
        if (IsSet(UI_CurrentPage) && UI_CurrentPage = "profile") {
            canWriteUI := true
        }
    } catch {
        canWriteUI := false
    }
    UI_Trace("SwitchProfile canWriteUI=" (canWriteUI ? 1 : 0) " currentPage=" UI_CurrentPage)

    if (canWriteUI) {
        try {
            if (IsSet(UI)) {
                try {
                    if (UI.HkStart) {
                        UI.HkStart.Value := prof.StartHotkey
                    }
                } catch {
                }
                try {
                    if (UI.PollEdit) {
                        UI.PollEdit.Value := prof.PollIntervalMs
                    }
                } catch {
                }
                try {
                    if (UI.CdEdit) {
                        UI.CdEdit.Value := prof.SendCooldownMs
                    }
                } catch {
                }
                try {
                    if (UI.ChkPick) {
                        UI.ChkPick.Value := (prof.PickHoverEnabled ? 1 : 0)
                    }
                } catch {
                }
                try {
                    if (UI.OffYEdit) {
                        UI.OffYEdit.Value := prof.PickHoverOffsetY
                    }
                } catch {
                }
                try {
                    if (UI.DwellEdit) {
                        UI.DwellEdit.Value := prof.PickHoverDwellMs
                    }
                } catch {
                }
                try {
                    if (UI.DdPickKey) {
                        pk := "LButton"
                        try {
                            if (HasProp(prof, "PickConfirmKey")) {
                                pk := prof.PickConfirmKey
                            }
                        } catch {
                            pk := "LButton"
                        }
                        opts := ["LButton", "MButton", "RButton", "XButton1", "XButton2", "F10", "F11", "F12"]
                        pos := 1
                        idx := 0
                        for _, v in opts {
                            idx := idx + 1
                            if (v = pk) {
                                pos := idx
                                break
                            }
                        }
                        UI.DdPickKey.Value := pos
                    }
                } catch {
                }
            }
        } catch {
        }
        UI_Trace("SwitchProfile wrote values to UI")
    } else {
        UI_Trace("SwitchProfile skipped UI write")
    }

    ; 运行期：热键/池/计数/ROI/Rotation/DXGI
    try {
        Hotkeys_BindStartHotkey(prof.StartHotkey)
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
        Pixel_ROI_SetAutoFromProfile(prof, 8, false)
    } catch {
    }
    try {
        if !HasProp(prof, "Rotation") {
            prof.Rotation := {}
        }
        prof.Rotation.Enabled := 1
        App["ProfileData"] := prof
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

    UI_Trace("SwitchProfile done")
    return true
}
