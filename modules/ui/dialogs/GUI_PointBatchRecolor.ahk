; ================= modules\ui\dialogs\GUI_PointBatchRecolor.ahk =================
#Requires AutoHotkey v2

PointBatchRecolor_Open() {
    global g_PointBatchGui

    items := BatchRecolor_BuildItemList("Point")
    cnt := 0
    try {
        cnt := items.Length
    } catch {
        cnt := 0
    }
    if (cnt <= 0) {
        MsgBox "当前配置中没有取色点位。"
        return
    }

    g := Gui("+OwnDialogs", "点位批量取色")
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    g.Add("Text", "x10 y10 w520"
        , "请选择需要本次取色的点位，并设置延时（秒）：")

    g.Add("Text", "x10 y36 w80 Right", "延时（秒）：")
    edDelay := g.Add("Edit", "x+6 w60 Number", "3")

    lv := g.Add("ListView"
        , "x10 y64 w620 h260 Checked"
        , ["ID","名称","X","Y","当前颜色"])

    i := 1
    while (i <= items.Length) {
        it := items[i]
        id := 0
        name := ""
        x := 0
        y := 0
        col := "0x000000"

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
            col := OM_Get(it, "Color", "0x000000")
        } catch {
            col := "0x000000"
        }

        rowIdx := 0
        try {
            rowIdx := lv.Add("", id, name, x, y, col)
        } catch {
            rowIdx := 0
        }
        if (rowIdx > 0) {
            try {
                lv.Modify(rowIdx, "Check")
            } catch {
            }
        }

        i := i + 1
    }

    btnStart := g.Add("Button", "x10 y+10 w100 h28", "开始取色")
    btnCancel := g.Add("Button", "x+10 w80 h28", "取消")

    g_PointBatchGui := Map()
    g_PointBatchGui["Gui"] := g
    g_PointBatchGui["LV"] := lv
    g_PointBatchGui["EdDelay"] := edDelay
    g_PointBatchGui["Items"] := items

    btnStart.OnEvent("Click", PointBatchRecolor_OnStart.Bind(g))
    btnCancel.OnEvent("Click", PointBatchRecolor_OnCancel.Bind(g))
    g.OnEvent("Close", PointBatchRecolor_OnCancel.Bind(g))

    g.Show("w650 h360")
}

PointBatchRecolor_OnCancel(g, *) {
    global g_PointBatchGui
    try {
        g.Destroy()
    } catch {
    }
    g_PointBatchGui := Map()
}

PointBatchRecolor_OnStart(g, *) {
    global g_PointBatchGui

    lv := ""
    edDelay := ""
    items := []
    try {
        lv := g_PointBatchGui["LV"]
        edDelay := g_PointBatchGui["EdDelay"]
        items := g_PointBatchGui["Items"]
    } catch {
        MsgBox "内部错误：对话框状态丢失。"
        return
    }

    delaySec := 3
    try {
        if (edDelay.Value != "") {
            delaySec := Integer(edDelay.Value)
        }
    } catch {
        delaySec := 3
    }
    if (delaySec < 0) {
        delaySec := 0
    }

    selected := []
    row := 0
    try {
        row := lv.GetNext(0, "Checked")
    } catch {
        row := 0
    }
    while (row) {
        id := 0
        try {
            id := Integer(lv.GetText(row, 1))
        } catch {
            id := 0
        }

        if (id > 0) {
            it := 0
            i := 1
            while (i <= items.Length) {
                tmp := items[i]
                tmpId := 0
                try {
                    tmpId := OM_Get(tmp, "Id", 0)
                } catch {
                    tmpId := 0
                }
                if (tmpId = id) {
                    it := tmp
                    break
                }
                i := i + 1
            }
            if (it) {
                selected.Push(it)
            }
        }

        try {
            row := lv.GetNext(row, "Checked")
        } catch {
            row := 0
        }
    }

    cntSel := 0
    try {
        cntSel := selected.Length
    } catch {
        cntSel := 0
    }
    if (cntSel <= 0) {
        MsgBox "请至少勾选一个点位。"
        return
    }

    try {
        g.Destroy()
    } catch {
    }
    g_PointBatchGui := Map()

    BatchRecolor_Run("Point", selected, delaySec)
}