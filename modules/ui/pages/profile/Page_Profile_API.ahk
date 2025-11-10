#Requires AutoHotkey v2

; Profile 公共 API（与页面解耦）
; 提供：Profile_RefreshAll_Strong() / Profile_SwitchProfile_Strong(name)
; 说明：
; - 若 UI 控件存在（UI.ProfilesDD、UI.HkStart 等），会一并刷新
; - 若 UI 控件未创建，仅刷新 App 状态与运行时引擎（Hotkeys/WorkerPool/ROI/Rotation/DXGI）
; - 全部块结构 if/try/catch

Profile_RefreshAll_Strong() {
    global App, UI

    ; 1) 确保 App/目录
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
    } catch {
    }

    ; 2) 枚举/兜底
    names := []
    try {
        names := Storage_ListProfiles()
    } catch {
        names := []
    }
    if (names.Length = 0) {
        try {
            data := Core_DefaultProfileData()
            Storage_SaveProfile(data)
            names := Storage_ListProfiles()
        } catch {
            names := []
        }
    }
    if (names.Length = 0) {
        return false
    }

    ; 3) 选择目标
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

    ; 4) 刷新 UI 下拉（若存在）
    try {
        if (IsSet(UI) && UI.Has("ProfilesDD") && UI.ProfilesDD) {
            UI.ProfilesDD.Delete()
            UI.ProfilesDD.Add(names)

            sel := 1
            i := 0
            for _, nm in names {
                i := i + 1
                if (nm = target) {
                    sel := i
                    break
                }
            }
            UI.ProfilesDD.Value := sel
        }
    } catch {
    }

    ; 5) 切换到目标（含运行时引擎）
    ok := Profile_SwitchProfile_Strong(target)
    return ok
}

Profile_SwitchProfile_Strong(name) {
    global App, UI

    prof := 0
    try {
        App["CurrentProfile"] := name
        prof := Storage_LoadProfile(name)
        App["ProfileData"] := prof
    } catch {
        return false
    }

    ; 若 UI 控件存在则灌控件
    try {
        if (IsSet(UI) && UI.Has("HkStart") && UI.HkStart) {
            UI.HkStart.Value := prof.StartHotkey
        }
        if (IsSet(UI) && UI.Has("PollEdit") && UI.PollEdit) {
            UI.PollEdit.Value := prof.PollIntervalMs
        }
        if (IsSet(UI) && UI.Has("CdEdit") && UI.CdEdit) {
            UI.CdEdit.Value := prof.SendCooldownMs
        }
        if (IsSet(UI) && UI.Has("ChkPick") && UI.ChkPick) {
            UI.ChkPick.Value := (prof.PickHoverEnabled ? 1 : 0)
        }
        if (IsSet(UI) && UI.Has("OffYEdit") && UI.OffYEdit) {
            UI.OffYEdit.Value := prof.PickHoverOffsetY
        }
        if (IsSet(UI) && UI.Has("DwellEdit") && UI.DwellEdit) {
            UI.DwellEdit.Value := prof.PickHoverDwellMs
        }
        if (IsSet(UI) && UI.Has("DdPickKey") && UI.DdPickKey) {
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

    return true
}