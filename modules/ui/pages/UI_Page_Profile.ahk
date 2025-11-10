#Requires AutoHotkey v2

; 概览与配置面板（左侧菜单右侧面板版）
; 特性：
; - 严格块结构 if/try/catch
; - 首次构建后即执行“强力回退”刷新（不依赖 UI_Page_Config_ReloadProfiles）
; - 若无任何配置，自动创建一个默认配置并切换

Page_Profile_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ====== Group: 角色配置 ======
    UI.GB_Profile := UI.Main.Add("GroupBox", Format("x{} y{} w{} h80", rc.X, rc.Y, rc.W), T("group.profile","角色配置"))
    page.Controls.Push(UI.GB_Profile)

    UI.ProfilesDD := UI.Main.Add("DropDownList", Format("x{} y{} w280", rc.X + 12, rc.Y + 32))
    page.Controls.Push(UI.ProfilesDD)

    UI.BtnNew := UI.Main.Add("Button", "x+10 w80 h28", T("btn.new","新建"))
    UI.BtnClone := UI.Main.Add("Button", "x+8 w80 h28", T("btn.clone","复制"))
    UI.BtnDelete := UI.Main.Add("Button", "x+8 w80 h28", T("btn.delete","删除"))
    UI.BtnExport := UI.Main.Add("Button", "x+16 w92 h28", T("btn.export","导出打包"))
    page.Controls.Push(UI.BtnNew)
    page.Controls.Push(UI.BtnClone)
    page.Controls.Push(UI.BtnDelete)
    page.Controls.Push(UI.BtnExport)

    ; ====== Group: 热键与轮询 ======
    gy := rc.Y + 80 + 10
    UI.GB_General := UI.Main.Add("GroupBox", Format("x{} y{} w{} h152", rc.X, gy, rc.W), T("group.general","热键与轮询"))
    page.Controls.Push(UI.GB_General)

    UI.LblStartStop := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12, gy + 50), T("label.startStop","开始/停止："))
    page.Controls.Push(UI.LblStartStop)

    UI.HkStart := UI.Main.Add("Hotkey", Format("x{} y{} w180", rc.X + 12 + 90, gy + 46))
    page.Controls.Push(UI.HkStart)

    UI.BtnCapStartMouse := UI.Main.Add("Button", Format("x{} y{} w110 h28", rc.X + 12 + 90 + 186, gy + 44), T("btn.captureMouse","捕获鼠标键"))
    page.Controls.Push(UI.BtnCapStartMouse)

    UI.LblPoll := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12 + 90 + 186 + 116, gy + 50), T("label.pollMs","轮询(ms)："))
    page.Controls.Push(UI.LblPoll)
    UI.PollEdit := UI.Main.Add("Edit", "x+6 w90 Number Center")
    page.Controls.Push(UI.PollEdit)

    UI.LblDelay := UI.Main.Add("Text", "x+18", T("label.delayMs","全局延迟(ms)："))
    page.Controls.Push(UI.LblDelay)
    UI.CdEdit := UI.Main.Add("Edit", "x+6 w100 Number Center")
    page.Controls.Push(UI.CdEdit)

    UI.BtnApply := UI.Main.Add("Button", "x+18 w80 h28", T("btn.apply","应用"))
    page.Controls.Push(UI.BtnApply)

    ; 行2：取色避让与拾色确认键
    UI.LblPick := UI.Main.Add("Text", Format("x{} y{}", rc.X + 12, gy + 84), T("label.pickAvoid","取色避让："))
    page.Controls.Push(UI.LblPick)
    UI.ChkPick := UI.Main.Add("CheckBox", "x+6 w18 h18")
    page.Controls.Push(UI.ChkPick)

    UI.LblOffY := UI.Main.Add("Text", "x+14", T("label.offsetY","Y偏移(px)："))
    page.Controls.Push(UI.LblOffY)
    UI.OffYEdit := UI.Main.Add("Edit", "x+6 w80 Number Center")
    page.Controls.Push(UI.OffYEdit)

    UI.LblDwell := UI.Main.Add("Text", "x+14", T("label.dwellMs","等待(ms)："))
    page.Controls.Push(UI.LblDwell)
    UI.DwellEdit := UI.Main.Add("Edit", "x+6 w90 Number Center")
    page.Controls.Push(UI.DwellEdit)

    UI.LblPickKey := UI.Main.Add("Text", "x+14", T("label.pickKey","拾色热键："))
    page.Controls.Push(UI.LblPickKey)
    UI.DdPickKey := UI.Main.Add("DropDownList", "x+6 w120")
    UI.DdPickKey.Add(["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"])
    page.Controls.Push(UI.DdPickKey)

    ; ====== Group: 自动化入口 ======
    gy3 := gy + 152 + 10
    UI.GB_Auto := UI.Main.Add("GroupBox", Format("x{} y{} w{} h60", rc.X, gy3, rc.W), T("group.auto","自动化配置"))
    page.Controls.Push(UI.GB_Auto)

    UI.BtnThreads := UI.Main.Add("Button", Format("x{} y{} w100 h28", rc.X + 12, gy3 + 28), T("btn.threads","线程配置"))
    UI.BtnRules   := UI.Main.Add("Button", "x+8 w100 h28", T("btn.rules","循环配置"))
    UI.BtnBuffs   := UI.Main.Add("Button", "x+8 w100 h28", T("btn.buffs","计时器配置"))
    UI.BtnDefault := UI.Main.Add("Button", "x+8 w100 h28", T("btn.default","默认技能"))
    UI.BtnRotation:= UI.Main.Add("Button", "x+8 w100 h28", T("btn.rotation","轮换配置"))
    page.Controls.Push(UI.BtnThreads)
    page.Controls.Push(UI.BtnRules)
    page.Controls.Push(UI.BtnBuffs)
    page.Controls.Push(UI.BtnDefault)
    page.Controls.Push(UI.BtnRotation)

    ; ====== 事件绑定 ======
    try {
        UI.ProfilesDD.OnEvent("Change", Profile_OnProfilesChanged)
        UI.BtnNew.OnEvent("Click", UI_Page_Config_NewProfile)
        UI.BtnClone.OnEvent("Click", UI_Page_Config_CloneProfile)
        UI.BtnDelete.OnEvent("Click", UI_Page_Config_DeleteProfile)
        UI.BtnExport.OnEvent("Click", UI_Page_Config_OnExport)

        UI.BtnCapStartMouse.OnEvent("Click", UI_Page_Config_CaptureStartMouse)
        UI.BtnApply.OnEvent("Click", UI_Page_Config_ApplyGeneral)

        UI.BtnThreads.OnEvent("Click", ThreadsManager_Show)
        UI.BtnRules.OnEvent("Click", RulesManager_Show)
        UI.BtnBuffs.OnEvent("Click", BuffsManager_Show)
        UI.BtnDefault.OnEvent("Click", DefaultSkillEditor_Show)
        UI.BtnRotation.OnEvent("Click", RotationEditor_Show)
    } catch {
        ; 若某些函数尚未 #Include，不影响页面继续
    }

    ; ====== 强力回退刷新（不依赖外部页面函数），保证下拉有数据 ======
    Profile_RefreshAll_Strong()
}

Page_Profile_Layout(rc) {
    ; 轻量：只调整三大分组宽度，纵向位置保持构建时的布局
    try {
        UI.GB_Profile.Move(rc.X, rc.Y, rc.W)
        UI.GB_General.Move(rc.X, rc.Y + 90, rc.W)
        UI.GB_Auto.Move(rc.X, rc.Y + 90 + 162, rc.W)
    } catch {
    }
}

; ====== 本页内部：强力回退刷新 ======

Profile_OnProfilesChanged(*) {
    ; 有外部函数就用外部函数；否则使用内部强力回退切换
    try {
        UI_Page_Config_ProfileChanged()
        return
    } catch {
        ; ignore
    }
    try {
        name := UI.ProfilesDD.Text
        if (name != "") {
            Profile_SwitchProfile_Strong(name)
        }
    } catch {
    }
}

Profile_RefreshAll_Strong() {
    global App, UI

    ; 1) 确保 App 与目录
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

    ; 2) 枚举 profiles；若为空则创建默认配置
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

    ; 3) 填充下拉并选择当前
    try {
        UI.ProfilesDD.Delete()
    } catch {
    }
    try {
        if (names.Length > 0) {
            UI.ProfilesDD.Add(names)
            selName := ""
            if (App.Has("CurrentProfile") && App["CurrentProfile"] != "") {
                selName := App["CurrentProfile"]
            } else {
                selName := names[1]
            }
            sel := 1
            i := 0
            for _, nm in names {
                i += 1
                if (nm = selName) {
                    sel := i
                    break
                }
            }
            UI.ProfilesDD.Value := sel
            Profile_SwitchProfile_Strong(names[sel])
        }
    } catch {
    }
}

Profile_SwitchProfile_Strong(name) {
    global App, UI

    ; Load profile data
    prof := 0
    try {
        App["CurrentProfile"] := name
        prof := Storage_LoadProfile(name)
        App["ProfileData"] := prof
    } catch {
        return
    }

    ; 把基础项灌到控件
    try {
        UI.HkStart.Value := prof.StartHotkey
        UI.PollEdit.Value := prof.PollIntervalMs
        UI.CdEdit.Value := prof.SendCooldownMs
        UI.ChkPick.Value := (prof.PickHoverEnabled ? 1 : 0)
        UI.OffYEdit.Value := prof.PickHoverOffsetY
        UI.DwellEdit.Value := prof.PickHoverDwellMs

        ; 拾色确认键
        pk := "LButton"
        if (HasProp(prof, "PickConfirmKey")) {
            pk := prof.PickConfirmKey
        }
        opts := ["LButton","MButton","RButton","XButton1","XButton2","F10","F11","F12"]
        pos := 1
        idx := 0
        for _, v in opts {
            idx += 1
            if (v = pk) {
                pos := idx
                break
            }
        }
        UI.DdPickKey.Value := pos
    } catch {
    }

    ; 运行期相关：重绑热键、重建池、计数与 ROI、轮换引擎
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
}