; ================= modules\ui\dialogs\GUI_SkillBatchRecolor.ahk =================
#Requires AutoHotkey v2

; 打开技能批量取色对话框
SkillBatchRecolor_Open() {
    global g_SkillBatchGui

    items := BatchRecolor_BuildItemList("Skill")
    cnt := 0
    try {
        cnt := items.Length
    } catch {
        cnt := 0
    }
    if (cnt <= 0) {
        MsgBox "当前配置中没有技能。"
        return
    }

    g := Gui("+OwnDialogs", "技能批量取色")
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s10", "Segoe UI")

    g.Add("Text", "x10 y10 w520"
        , "请选择需要本次取色的技能，并设置延时（秒）：")

    g.Add("Text", "x10 y36 w80 Right", "延时（秒）：")
    edDelay := g.Add("Edit", "x+6 w60 Number", "3")

    lv := g.Add("ListView"
        , "x10 y64 w620 h260 Checked"
        , ["ID","技能名","X","Y","当前颜色"])

    ; 填充列表并默认全选
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

    ; 保存到全局，供事件使用
    g_SkillBatchGui := Map()
    g_SkillBatchGui["Gui"] := g
    g_SkillBatchGui["LV"] := lv
    g_SkillBatchGui["EdDelay"] := edDelay
    g_SkillBatchGui["Items"] := items

    btnStart.OnEvent("Click", SkillBatchRecolor_OnStart.Bind(g))
    btnCancel.OnEvent("Click", SkillBatchRecolor_OnCancel.Bind(g))
    g.OnEvent("Close", SkillBatchRecolor_OnCancel.Bind(g))

    g.Show("w650 h360")
}

SkillBatchRecolor_OnCancel(g, *) {
    global g_SkillBatchGui
    try {
        g.Destroy()
    } catch {
    }
    g_SkillBatchGui := Map()
}

SkillBatchRecolor_OnStart(g, *) {
    global g_SkillBatchGui

    lv := ""
    edDelay := ""
    items := []
    try {
        lv := g_SkillBatchGui["LV"]
        edDelay := g_SkillBatchGui["EdDelay"]
        items := g_SkillBatchGui["Items"]
    } catch {
        MsgBox "内部错误：对话框状态丢失。"
        return
    }

    ; 读取延时
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

    ; 收集勾选项
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
            ; 按 Id 在 items 中查找
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
        MsgBox "请至少勾选一个技能。"
        return
    }

    try {
        g.Destroy()
    } catch {
    }
    g_SkillBatchGui := Map()

    BatchRecolor_Run("Skill", selected, delaySec)
}