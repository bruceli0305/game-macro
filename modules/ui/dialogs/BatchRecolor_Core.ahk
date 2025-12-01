; ================== modules\ui\dialogs\BatchRecolor_Core.ahk ==================
#Requires AutoHotkey v2

; 公共批量取色状态
global g_BatchRecolor := Map()

; 构建可选条目列表（从当前运行时 ProfileData）
; kind: "Skill" 或 "Point"
; 返回数组：[{Id, Name, X, Y, Color}]
BatchRecolor_BuildItemList(kind) {
    global App

    items := []

    if !(IsSet(App) && App.Has("ProfileData")) {
        return items
    }

    pd := App["ProfileData"]

    if (kind = "Skill") {
        if !(HasProp(pd, "Skills") && IsObject(pd.Skills)) {
            return items
        }
        i := 1
        while (i <= pd.Skills.Length) {
            s := pd.Skills[i]
            if (IsObject(s)) {
                id := 0
                name := ""
                x := 0
                y := 0
                col := "0x000000"

                try {
                    id := OM_Get(s, "Id", 0)
                } catch {
                    id := 0
                }
                try {
                    name := OM_Get(s, "Name", "")
                } catch {
                    name := ""
                }
                try {
                    x := OM_Get(s, "X", 0)
                } catch {
                    x := 0
                }
                try {
                    y := OM_Get(s, "Y", 0)
                } catch {
                    y := 0
                }
                try {
                    col := OM_Get(s, "Color", "0x000000")
                } catch {
                    col := "0x000000"
                }

                item := Map()
                item["Id"] := id
                item["Name"] := name
                item["X"] := x
                item["Y"] := y
                item["Color"] := col
                items.Push(item)
            }
            i := i + 1
        }
    } else if (kind = "Point") {
        if !(HasProp(pd, "Points") && IsObject(pd.Points)) {
            return items
        }
        i := 1
        while (i <= pd.Points.Length) {
            p := pd.Points[i]
            if (IsObject(p)) {
                id := 0
                name := ""
                x := 0
                y := 0
                col := "0x000000"

                try {
                    id := OM_Get(p, "Id", 0)
                } catch {
                    id := 0
                }
                try {
                    name := OM_Get(p, "Name", "")
                } catch {
                    name := ""
                }
                try {
                    x := OM_Get(p, "X", 0)
                } catch {
                    x := 0
                }
                try {
                    y := OM_Get(p, "Y", 0)
                } catch {
                    y := 0
                }
                try {
                    col := OM_Get(p, "Color", "0x000000")
                } catch {
                    col := "0x000000"
                }

                item := Map()
                item["Id"] := id
                item["Name"] := name
                item["X"] := x
                item["Y"] := y
                item["Color"] := col
                items.Push(item)
            }
            i := i + 1
        }
    }

    return items
}

; 执行批量取色
; kind: "Skill"/"Point"
; selectedItems: [{Id, Name, X, Y, Color}]
; delaySec: 延时秒数
BatchRecolor_Run(kind, selectedItems, delaySec) {
    global App, UI

    if !IsObject(selectedItems) {
        MsgBox "未选择任何条目。"
        return
    }

    cnt := 0
    try {
        cnt := selectedItems.Length
    } catch {
        cnt := 0
    }
    if (cnt <= 0) {
        MsgBox "未选择任何条目。"
        return
    }

    isRunning := 0
    try {
        if (IsSet(App) && App.Has("IsRunning") && App["IsRunning"]) {
            isRunning := 1
        } else {
            isRunning := 0
        }
    } catch {
        isRunning := 0
    }
    if (isRunning) {
        MsgBox "宏正在运行，请先停止后再进行批量取色。"
        return
    }

    if (delaySec < 0) {
        delaySec := 0
    }

    ; 读取避让参数
    offY := 0
    dwell := 0
    try {
        if (App.Has("ProfileData")) {
            pd := App["ProfileData"]
            if (HasProp(pd, "PickHoverEnabled") && pd.PickHoverEnabled) {
                try {
                    if (HasProp(pd, "PickHoverOffsetY")) {
                        offY := pd.PickHoverOffsetY
                    }
                } catch {
                    offY := 0
                }
                try {
                    if (HasProp(pd, "PickHoverDwellMs")) {
                        dwell := pd.PickHoverDwellMs
                    }
                } catch {
                    dwell := 0
                }
            }
        }
    } catch {
        offY := 0
        dwell := 0
    }

    ; 隐藏主窗口，避免遮挡
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Hide()
        }
    } catch {
    }

    ; 倒计时提示
    msg := "即将开始批量取色，约 " delaySec " 秒后执行，请切换到游戏界面并保持角色与界面不动。"
    try {
        ToolTip(msg)
    } catch {
    }

    if (delaySec > 0) {
        try {
            Sleep Integer(delaySec * 1000)
        } catch {
        }
    }

    try {
        ToolTip()
    } catch {
    }

    results := []

    i := 1
    while (i <= cnt) {
        it := selectedItems[i]
        id := 0
        name := ""
        x := 0
        y := 0
        oldCol := "0x000000"

        try {
            id := OM_Get(it, "Id", 0)
        } catch {
            id := 0
        }
        try {
            name := OM_Get(it, "Name", "")
        } catch {
            name := ""
        }
        try {
            x := OM_Get(it, "X", 0)
        } catch {
            x := 0
        }
        try {
            y := OM_Get(it, "Y", 0)
        } catch {
            y := 0
        }
        try {
            oldCol := OM_Get(it, "Color", "0x000000")
        } catch {
            oldCol := "0x000000"
        }

        ; 进度提示
        prog := "正在取色 " i "/" cnt "：" name
        try {
            ToolTip(prog)
        } catch {
        }

        c := 0
        try {
            c := Pixel_GetColorWithMouseAway(x, y, offY, dwell)
        } catch {
            c := 0
        }

        newCol := "0x000000"
        try {
            newCol := Pixel_ColorToHex(c)
        } catch {
            newCol := "0x000000"
        }

        row := Map()
        row["Id"] := id
        row["Name"] := name
        row["X"] := x
        row["Y"] := y
        row["OldColor"] := oldCol
        row["NewColor"] := newCol
        results.Push(row)

        i := i + 1
    }

    try {
        ToolTip()
    } catch {
    }

    ; 恢复主窗口
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            UI.Main.Show()
            UI_LayoutCurrentPage()
        }
    } catch {
    }

    ; 记录一条日志
    try {
        Logger_Info("BatchRecolor", "Run finished", Map("kind", kind, "count", results.Length))
    } catch {
    }

    ; 展示结果对话框
    BatchRecolor_ShowResult(kind, results)
}

; 结果预览与应用
BatchRecolor_ShowResult(kind, results) {
    global g_BatchRecolor

    g_BatchRecolor["Kind"] := kind
    g_BatchRecolor["Results"] := results

    title := ""
    if (kind = "Skill") {
        title := "技能批量取色结果"
    } else if (kind = "Point") {
        title := "点位批量取色结果"
    } else {
        title := "批量取色结果"
    }

    g := Gui("+OwnDialogs", title)
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    g.Add("Text", "x10 y10 w520", "以下是本次批量取色的结果：")

    lv := g.Add("ListView"
        , "x10 y32 w620 h260"
        , ["名称","X","Y","原颜色","新颜色","是否改变"])

    if IsObject(results) {
        i := 1
        while (i <= results.Length) {
            r := results[i]
            name := ""
            x := 0
            y := 0
            oc := "0x000000"
            nc := "0x000000"

            try {
                name := OM_Get(r, "Name", "")
            } catch {
                name := ""
            }
            try {
                x := OM_Get(r, "X", 0)
            } catch {
                x := 0
            }
            try {
                y := OM_Get(r, "Y", 0)
            } catch {
                y := 0
            }
            try {
                oc := OM_Get(r, "OldColor", "0x000000")
            } catch {
                oc := "0x000000"
            }
            try {
                nc := OM_Get(r, "NewColor", "0x000000")
            } catch {
                nc := "0x000000"
            }

            changed := ""
            if (oc != nc) {
                changed := "是"
            } else {
                changed := "否"
            }

            try {
                lv.Add("", name, x, y, oc, nc, changed)
            } catch {
            }

            i := i + 1
        }
    }

    btnApply := g.Add("Button", "x10 y+12 w160 h28", "应用新颜色（仅更新当前配置）")
    btnClose := g.Add("Button", "x+12 w80 h28", "关闭")

    g_BatchRecolor["GuiResult"] := g
    g_BatchRecolor["LV"] := lv

    btnApply.OnEvent("Click", BatchRecolor_OnApply.Bind(g))
    btnClose.OnEvent("Click", BatchRecolor_OnClose.Bind(g))
    g.OnEvent("Close", BatchRecolor_OnClose.Bind(g))

    g.Show("w650 h360")
}

BatchRecolor_OnClose(g, *) {
    global g_BatchRecolor
    try {
        g.Destroy()
    } catch {
    }
    g_BatchRecolor.Clear()
}

BatchRecolor_OnApply(g, *) {
    global g_BatchRecolor, App

    kind := ""
    results := []
    try {
        kind := g_BatchRecolor["Kind"]
    } catch {
        kind := ""
    }
    try {
        results := g_BatchRecolor["Results"]
    } catch {
        results := []
    }

    if !(IsSet(App) && App.Has("ProfileData")) {
        MsgBox "当前没有加载配置，无法应用颜色。"
        return
    }

    pd := App["ProfileData"]

    if !IsObject(results) {
        results := []
    }

    cnt := 0
    try {
        cnt := results.Length
    } catch {
        cnt := 0
    }

    i := 1
    while (i <= cnt) {
        r := results[i]
        id := 0
        oc := "0x000000"
        nc := "0x000000"

        try {
            id := OM_Get(r, "Id", 0)
        } catch {
            id := 0
        }
        try {
            oc := OM_Get(r, "OldColor", "0x000000")
        } catch {
            oc := "0x000000"
        }
        try {
            nc := OM_Get(r, "NewColor", "0x000000")
        } catch {
            nc := "0x000000"
        }

        if (id > 0) {
            if (nc != oc) {
                if (kind = "Skill") {
                    idx := Skills_IndexById(id)
                    if (idx > 0) {
                        try {
                            s := pd.Skills[idx]
                        } catch {
                            s := 0
                        }
                        if (s) {
                            try {
                                s.Color := nc
                            } catch {
                            }
                            try {
                                pd.Skills[idx] := s
                            } catch {
                            }
                        }
                    }
                } else if (kind = "Point") {
                    idx2 := Points_IndexById(id)
                    if (idx2 > 0) {
                        try {
                            p := pd.Points[idx2]
                        } catch {
                            p := 0
                        }
                        if (p) {
                            try {
                                p.Color := nc
                            } catch {
                            }
                            try {
                                pd.Points[idx2] := p
                            } catch {
                            }
                        }
                    }
                }
            }
        }

        i := i + 1
    }

    ; 写回 App.ProfileData
    try {
        App["ProfileData"] := pd
    } catch {
    }

    ; 刷新列表（不落盘）
    if (kind = "Skill") {
        try {
            Skills_RefreshList()
        } catch {
        }
    } else if (kind = "Point") {
        try {
            Points_RefreshList()
        } catch {
        }
    }

    try {
        Logger_Info("BatchRecolor", "Applied", Map("kind", kind, "count", cnt))
    } catch {
    }

    MsgBox "批量取色结果已应用到当前配置（仅内存）。如需写入文件，请在页面中点击“保存”按钮。"

    try {
        g.Destroy()
    } catch {
    }
    g_BatchRecolor.Clear()
}