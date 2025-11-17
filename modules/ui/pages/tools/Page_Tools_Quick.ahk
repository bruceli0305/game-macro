#Requires AutoHotkey v2
;Page_Tools_Quick.ahk
; 工具 → 快捷测试
; 严格块结构 if/try/catch，不使用单行形式
; 控件前缀：TQ_

Page_ToolsQuick_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    ; ========= 一次性发键 =========
    UI.TQ_GB_Send := UI.Main.Add("GroupBox", Format("x{} y{} w{} h150", rc.X, rc.Y, rc.W), "发键测试（一次性 Fire&Forget）")
    page.Controls.Push(UI.TQ_GB_Send)

    x0 := rc.X + 12
    y0 := rc.Y + 26

    UI.TQ_L_Key := UI.Main.Add("Text", Format("x{} y{} w90 Right", x0, y0 + 4), "键序列：")
    page.Controls.Push(UI.TQ_L_Key)
    UI.TQ_EdKey := UI.Main.Add("Edit", "x+6 w120")
    page.Controls.Push(UI.TQ_EdKey)

    UI.TQ_L_Delay := UI.Main.Add("Text", "x+16 w90 Right", "延时(ms)：")
    page.Controls.Push(UI.TQ_L_Delay)
    UI.TQ_EdDelay := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.TQ_EdDelay)

    UI.TQ_L_Hold := UI.Main.Add("Text", "x+16 w90 Right", "按住(ms)：")
    page.Controls.Push(UI.TQ_L_Hold)
    UI.TQ_EdHold := UI.Main.Add("Edit", "x+6 w120 Number")
    page.Controls.Push(UI.TQ_EdHold)

    y1 := y0 + 34
    tip := "说明：可直接输入 a、F1、LButton，或使用 {Ctrl down}a{Ctrl up} 形式。"
    UI.TQ_Tip := UI.Main.Add("Text", Format("x{} y{} w{}", x0, y1, rc.W - 24), tip)
    page.Controls.Push(UI.TQ_Tip)

    y2 := y1 + 30
    UI.TQ_BtnSend := UI.Main.Add("Button", Format("x{} y{} w120 h28", x0, y2), "发送")
    page.Controls.Push(UI.TQ_BtnSend)

    ; ========= 拾色与计数 =========
    ry := rc.Y + 150 + 10
    UI.TQ_GB_Pick := UI.Main.Add("GroupBox", Format("x{} y{} w{} h140", rc.X, ry, rc.W), "拾色与计数")
    page.Controls.Push(UI.TQ_GB_Pick)

    UI.TQ_BtnPick := UI.Main.Add("Button", Format("x{} y{} w120 h28", x0, ry + 26), "拾取像素")
    page.Controls.Push(UI.TQ_BtnPick)

    UI.TQ_L_Pick := UI.Main.Add("Text", "x+10 w420", "X=-  Y=-  Hex=-")
    page.Controls.Push(UI.TQ_L_Pick)

    UI.TQ_BtnClrCnt := UI.Main.Add("Button", Format("x{} y{} w120 h28", x0, ry + 26 + 40), "清零计数")
    page.Controls.Push(UI.TQ_BtnClrCnt)

    UI.TQ_BtnOpenLogs := UI.Main.Add("Button", "x+10 w120 h28", "打开日志目录")
    page.Controls.Push(UI.TQ_BtnOpenLogs)

    ; 事件
    UI.TQ_BtnSend.OnEvent("Click", ToolsQuick_OnSend)
    UI.TQ_BtnPick.OnEvent("Click", ToolsQuick_OnPick)
    UI.TQ_BtnClrCnt.OnEvent("Click", ToolsQuick_OnClearCounters)
    UI.TQ_BtnOpenLogs.OnEvent("Click", ToolsQuick_OnOpenLogs)

    ; 默认值
    try {
        UI.TQ_EdDelay.Value := 0
        UI.TQ_EdHold.Value := 0
    } catch {
    }
}

Page_ToolsQuick_Layout(rc) {
    try {
        UI.TQ_GB_Send.Move(rc.X, rc.Y, rc.W)
        UI.TQ_GB_Pick.Move(rc.X, rc.Y + 150 + 10, rc.W)
        ; 其余控件相对排布，保持构建时位置即可
    } catch {
    }
}

; ========== 事件处理 ==========

ToolsQuick_OnSend(*) {
    key := ""
    delay := 0
    hold := 0

    try {
        key := Trim(UI.TQ_EdKey.Value)
    } catch {
        key := ""
    }
    if (key = "") {
        MsgBox "请先输入键序列。"
        return
    }

    try {
        if (UI.TQ_EdDelay.Value != "") {
            delay := Integer(UI.TQ_EdDelay.Value)
        }
        if (UI.TQ_EdHold.Value != "") {
            hold := Integer(UI.TQ_EdHold.Value)
        }
    } catch {
        delay := 0
        hold := 0
    }

    ok := false
    ; 优先用 WorkerPool_FireAndForget，失败再回退 SendEvent
    try {
        ok := WorkerPool_FireAndForget(key, Max(0, delay), Max(0, hold))
    } catch {
        ok := false
    }

    if (!ok) {
        try {
            if (hold > 0) {
                SendEvent "{" key " down}"
                Sleep Max(0, hold)
                SendEvent "{" key " up}"
            } else {
                SendEvent key
            }
            ok := true
        } catch {
            ok := false
        }
    }

    if (ok) {
        Notify("已发送：" key)
    } else {
        Notify("发送失败：" key)
    }
}

ToolsQuick_OnPick(*) {
    global App
    offY := 0
    dwell := 0

    try {
        if (IsSet(App) && App.Has("ProfileData")) {
            if (HasProp(App["ProfileData"], "PickHoverEnabled") && App["ProfileData"].PickHoverEnabled) {
                offY := HasProp(App["ProfileData"], "PickHoverOffsetY") ? App["ProfileData"].PickHoverOffsetY : 0
                dwell := HasProp(App["ProfileData"], "PickHoverDwellMs") ? App["ProfileData"].PickHoverDwellMs : 0
            }
        }
    } catch {
        offY := 0
        dwell := 0
    }

    res := 0
    try {
        res := Pixel_PickPixel(0, offY, dwell)
    } catch {
        res := 0
    }
    if (!res) {
        return
    }

    hex := ""
    try {
        hex := Pixel_ColorToHex(res.Color)
    } catch {
        hex := "0x000000"
    }

    try {
        UI.TQ_L_Pick.Text := "X=" res.X "  Y=" res.Y "  Hex=" hex
    } catch {
    }
}

ToolsQuick_OnClearCounters(*) {
    try {
        Counters_Init()
        Notify("计数已清零")
    } catch {
        Notify("计数清零失败")
    }
}

ToolsQuick_OnOpenLogs(*) {
    dir := A_ScriptDir "\Logs"
    try {
        DirCreate(dir)
    } catch {
    }
    try {
        Run dir
    } catch {
        MsgBox "无法打开目录：" dir
    }
}