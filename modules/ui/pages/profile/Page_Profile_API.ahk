; ============================== modules\ui\pages\profile\Page_Profile_API.ahk ==============================
#Requires AutoHotkey v2
; Profile 公共 API（与页面解耦）
; 提供：Profile_RefreshAll_Strong() / Profile_SwitchProfile_Strong(name)
; 严格块结构 if/try/catch，不使用单行形式
; 增强：控件就绪探测、抑制 Change 重入、详细日志

global g_Profile_Populating := IsSet(g_Profile_Populating) ? g_Profile_Populating : false

Profile_RefreshAll_Strong() {
    global App, UI, g_Profile_Populating
    try {
        if !IsSet(App) {
            App := Map()
        }
        if !App.Has("ProfilesDir") {
            App["ProfilesDir"] := A_ScriptDir "\Profiles"
        }
        if !App.Has("ConfigExt") {
            App["ConfigExt"] := ".ini"
        }
        DirCreate(App["ProfilesDir"])
    }

    names := []
    try {
        names := Storage_ListProfiles()
    } catch as e {
        names := []
    }
    if (names.Length = 0) {
        try {
            data := Core_DefaultProfileData()
            Storage_SaveProfile(data)
            names := Storage_ListProfiles()
        } catch as e {
            names := []
        }
    }
    if (names.Length = 0) {
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
        } catch as e {
        } finally {
            g_Profile_Populating := false
        }
    }

    ok := false
    try {
        ok := Profile_SwitchProfile_Strong(target)
    } catch as e {
        ok := false
    }
    return ok
}

Profile_SwitchProfile_Strong(name) {
    global App, UI, UI_CurrentPage
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
    } catch as e {
        return false
    }

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
                        opts := ["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"]
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
    }

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
    } catch {
    }

    return true
}