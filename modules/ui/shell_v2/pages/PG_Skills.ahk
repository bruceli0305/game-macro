#Requires AutoHotkey v2
; modules\ui\shell_v2\pages\PG_Skills.ahk
#Include "..\UIX_Common.ahk"
#Include "..\UIX_Theme.ahk"
#Include "..\UIX_Controls.ahk"

PG_Skills_Build(ctx, theme := 0) {
    dlg := ctx.dlg
    if (!theme) {
        theme := UIX_Theme_Get()
    }

    rc := UIX_PageRect(dlg)

    ; ===== 标题（浅灰） =====
    ttl := dlg.Add("Text", Format("x{} y{} w800 cE6E6E6", rc.X, rc.Y), "配置管理 · 技能配置")
    ttl.SetFont("s13 Bold", "Segoe UI")

    ; ===== 胶囊页签 =====
    tabs := UIX_Pills_Create(dlg, rc.X, rc.Y + 44
        , ["角色配置","技能配置","BUFF配置","线程配置"], theme, 136, 36, 14)
    if (IsObject(tabs) && ObjHasOwnProp(tabs, "SetActive") && IsObject(tabs.SetActive)) {
        tabs.SetActive.Call(2)
    }
    OnTabsChanged(p*) {
        i := (p.Length >= 1) ? p[1] : 0
        if (i = 3) {
            BuffsManager_Show()
        } else if (i = 4) {
            ThreadsManager_Show()
        }
    }
    if (IsObject(tabs) && ObjHasOwnProp(tabs, "SetOnChange") && IsObject(tabs.SetOnChange)) {
        tabs.SetOnChange.Call(OnTabsChanged)
    }

    ; ===== 布局常量 =====
    topSpace := 44 + 40     ; 标题 + 胶囊下方留白
    toolH    := 36          ; 顶部工具栏高度（放“添加技能”）
    bottomH  := 40          ; 底部按钮区高度（放“删除技能”）
    rowH     := 40          ; 行高
    safePad  := 6           ; 列宽安全边距（避免水平滚动条）

    ; ===== 背景铺底（同一 Gui，不再用子 Gui 卡片） =====
    bg := dlg.Add("Text", Format("x{} y{} w{} h{}", rc.X, rc.Y + topSpace, rc.W, Max(220, rc.H - topSpace)), "")
    try {
        bg.BackColor := Format("0x{:06X}", theme.CardBg)
    } catch {
    }

    ; ===== 工具栏铺底（与卡片一致） =====
    toolBar := dlg.Add("Text", Format("x{} y{} w{} h{}", rc.X + 12, rc.Y + topSpace + 12, Max(200, rc.W - 24), toolH), "")
    try {
        toolBar.BackColor := Format("0x{:06X}", theme.CardBg)
    } catch {
    }

    ; ===== 添加按钮（OwnerDraw，HostBg=CardBg） =====
    btnAdd := UIX_Button_Primary(dlg, 0, 0, 118, 32, "添加技能", theme)
    try {
        info := UIX_OD.Map[btnAdd.Hwnd]
        if !IsObject(info.data) {
            info.data := Map()
        }
        info.data["HostBg"] := theme.CardBg
        UIX_OD.Map[btnAdd.Hwnd] := info
    } catch {
    }

    ; ===== ListView：原生表头 +Hdr，深色皮肤，去网格 =====
    lv := dlg.Add("ListView", "x12 y" (rc.Y + topSpace + 12 + toolH) " w760 h360 +Hdr +Report", ["ID","名称","快捷键","颜色","容差"])
    UIX_Theme_SkinListView(lv, theme, true)

    ; 确保整行选择 + 双缓冲
    LVM_GETEXTENDEDLISTVIEWSTYLE := 0x1037
    LVM_SETEXTENDEDLISTVIEWSTYLE := 0x1036
    LVS_EX_FULLROWSELECT := 0x0020
    LVS_EX_DOUBLEBUFFER  := 0x10000
    curEx := SendMessage(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0, lv)
    newEx := (curEx | LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER)
    if (newEx != curEx) {
        SendMessage(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, newEx, lv)
    }

    ; 行高：用小图像列表撑高
    try {
        hILRows := DllCall("comctl32\ImageList_Create", "int", 16, "int", rowH, "uint", 0x00000020, "int", 8, "int", 8, "ptr")
        if (hILRows) {
            bmi := Buffer(40, 0)
            NumPut("UInt", 40, bmi, 0)
            NumPut("Int", 1,  bmi, 4)
            NumPut("Int", -rowH, bmi, 8)
            NumPut("UShort", 1, bmi, 12)
            NumPut("UShort", 32, bmi, 14)
            hdc := DllCall("gdi32\CreateCompatibleDC", "ptr", 0, "ptr")
            pBits := 0
            hBmp := DllCall("gdi32\CreateDIBSection", "ptr", hdc, "ptr", bmi.Ptr, "uint", 0, "ptr*", &pBits, "ptr", 0, "uint", 0, "ptr")
            if (hBmp) {
                DllCall("comctl32\ImageList_Add", "ptr", hILRows, "ptr", hBmp, "ptr", 0)
                DllCall("gdi32\DeleteObject", "ptr", hBmp)
            }
            if (hdc) {
                DllCall("gdi32\DeleteDC", "ptr", hdc)
            }
            LVM_SETIMAGELIST := 0x1003
            LVSIL_SMALL := 1
            SendMessage(LVM_SETIMAGELIST, LVSIL_SMALL, hILRows, lv)
        }
    }

    ; 行间横线（全局分发器，页面销毁时 Detach）
    try UIX_LV_RowLines_Attach(lv, theme.Border)

    ; ===== 底部删除按钮 =====
    btnDel := UIX_Button_Secondary(dlg, 0, 0, 118, 32, "删除技能", theme)

    ; ===== 数据填充与列宽布局 =====
    FillFn   := PG_Skills_Fill.Bind(lv, ctx)
    LayoutFn := PG_Skills_LayoutCols.Bind(lv)

    btnAdd.OnEvent("Click", PG_Skills_OnAdd.Bind(ctx, FillFn))
    btnDel.OnEvent("Click", PG_Skills_OnDel.Bind(ctx, lv, FillFn))
    lv.OnEvent("DoubleClick", PG_Skills_OnEdit.Bind(ctx, lv))

    ; ===== Reflow：统一铺底，绝不重叠 =====
    ReflowFn := PG_Skills_Reflow.Bind(dlg, tabs
        , bg, toolBar
        , lv, btnAdd, btnDel
        , theme, topSpace, toolH, bottomH, safePad
        , LayoutFn)

    FillFn.Call()
    ReflowFn.Call()

    Destroy(*) {
        try UIX_LV_RowLines_Detach(lv)
        return 0
    }
    return { Reflow: (p*) => ReflowFn.Call(), Save: (p*) => 0, Destroy: Destroy }
}

; ---- 填充数据（第一列显示 ID）----
PG_Skills_Fill(lv, ctx) {
    try {
        lv.Opt("-Redraw")
        lv.Delete()
        prof := ctx.prof
        if (IsObject(prof.Skills) && prof.Skills.Length > 0) {
            for i, s in prof.Skills {
                hex := Pixel_ColorToHex(Pixel_HexToInt(s.Color))
                lv.Add("", i, s.Name, s.Key, hex, s.Tol)
            }
        }
    } catch {
    } finally {
        try lv.Opt("+Redraw")
        catch {
            
        }
    }
}

; ---- 列宽布局：固定 ID=64，剩余 40/18/24/18，最后一列吃余宽 ----
PG_Skills_LayoutCols(lv, lvW) {
    idW := 64
    restW := lvW - idW
    if (restW < 160) {
        restW := 160
    }

    wName := Floor(restW * 0.40)
    wKey  := Floor(restW * 0.18)
    wHex  := Floor(restW * 0.24)
    wTol  := restW - wName - wKey - wHex

    if (wTol < 60) {
        need := 60 - wTol
        wTol := 60
        if (wName > need + 80) {
            wName := wName - need
        } else if (wHex > need + 80) {
            wHex := wHex - need
        } else {
            tmp := wKey - need
            if (tmp < 60) {
                tmp := 60
            }
            wKey := tmp
        }
    }

    ; 最后一列吃余宽
    sum := idW + wName + wKey + wHex + wTol
    if (sum < lvW) {
        wTol := wTol + (lvW - sum)
    }

    try {
        lv.ModifyCol(1, idW)
        lv.ModifyCol(2, wName)
        lv.ModifyCol(3, wKey)
        lv.ModifyCol(4, wHex)
        lv.ModifyCol(5, wTol)
    }
}

; ---- Reflow：背景/工具栏铺底、按钮/表格不重叠 ----
PG_Skills_Reflow(dlg, tabs, bg, toolBar
    , lv, btnAdd, btnDel, theme, topSpace, toolH, bottomH, safePad, LayoutFn) {

    r := UIX_PageRect(dlg)
    if (IsObject(tabs) && ObjHasOwnProp(tabs, "Reflow") && IsObject(tabs.Reflow)) {
        tabs.Reflow.Call(r.X, r.Y + 44)
    }

    ; 背景铺底
    bg.Move(r.X, r.Y + topSpace, r.W, Max(220, r.H - topSpace))

    ; 工具栏铺满
    toolBar.Move(r.X + 12, r.Y + topSpace + 12, Max(200, r.W - 24), toolH)

    ; 右上按钮
    btnAdd.Move(r.X + r.W - 12 - 118, r.Y + topSpace + 12 + (toolH - 32)//2, 118, 32)

    ; ListView 可视区（扣工具栏与底部按钮）
    lvX := r.X + 12
    lvY := r.Y + topSpace + 12 + toolH
    lvW := r.W - 24
    lvH := r.H - (lvY - r.Y) - (bottomH + 12)
    if (lvH < 120) {
        lvH := 120
    }
    lv.Move(lvX, lvY, lvW, lvH)

    ; 列宽（留出 safePad 确保不出水平滚动）
    LayoutFn.Call(lvW - safePad)

    ; 右下按钮
    btnDel.Move(r.X + r.W - 12 - 118, r.Y + r.H - 12 - 32, 118, 32)
}

; ---- 行点击/编辑/新增/删除 ----
PG_Skills_OnAdd(ctx, FillFn, ctrl, info) {
    SkillEditor_Open({}, 0, PG_Skills_OnSavedNew.Bind(ctx, FillFn))
}
PG_Skills_OnSavedNew(ctx, FillFn, newSkill, idx) {
    try {
        ctx.prof.Skills.Push(newSkill)
        Storage_SaveProfile(ctx.prof)
    } catch {
    }
    FillFn.Call()
}
PG_Skills_OnEdit(ctx, lv, ctrl := 0, info := 0) {
    row := lv.GetNext(0, "Focused")
    if (!row) {
        MsgBox "请先选择一条记录。"
        return
    }
    idx := row
    cur := ctx.prof.Skills[idx]
    SkillEditor_Open(cur, idx, PG_Skills_OnSavedEdit.Bind(ctx, lv))
}
PG_Skills_OnSavedEdit(ctx, lv, newSkill, idx2) {
    try {
        ctx.prof.Skills[idx2] := newSkill
        Storage_SaveProfile(ctx.prof)
    } catch {
    }
    PG_Skills_Fill(lv, ctx)
}
PG_Skills_OnDel(ctx, lv, FillFn, ctrl, info) {
    row := lv.GetNext(0, "Focused")
    if (!row) {
        MsgBox "请先选择一条记录。"
        return
    }
    try {
        ctx.prof.Skills.RemoveAt(row)
        Storage_SaveProfile(ctx.prof)
    } catch {
    }
    FillFn.Call()
}