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

    ; ===== 右侧卡片容器 =====
    headerH  := 32      ; 伪表头高度
    topSpace := 44 + 40 ; 标题+胶囊下的留白
    actionW  := 118     ; 右上“添加技能”操作区宽
    actionGap:= 12      ; 表格与按钮间隙
    rowH     := 40      ; 行高

    cardRect := { x: rc.X, y: rc.Y + topSpace, w: rc.W, h: Max(260, rc.H - topSpace - 60) }
    card := UIX_Theme_CreateCardPanel(dlg.Hwnd, cardRect, theme, theme.Radius)

    ; 伪表头（深色底 + 灰色底线）
    hbBg := card.Add("Text", Format("x12 y12 w{} h{}", Max(200, cardRect.w - 24), headerH), "")
    try {
        hbBg.BackColor := Format("0x{:06X}", theme.HeaderBg)
    }
    hbLine := card.Add("Text", Format("x12 y{} w{} h1", 12 + headerH - 1, Max(200, cardRect.w - 24)), "")
    try {
        hbLine.BackColor := Format("0x{:06X}", theme.Border)
    }

    ; 5 个列头文本（与列宽同步）
    hdrId   := card.Add("Text", "x12 y12 w60  h" headerH " +0x200 cDCDCDC", "ID")
    hdrName := card.Add("Text", "x12 y12 w100 h" headerH " +0x200 cDCDCDC", "名称")
    hdrKey  := card.Add("Text", "x12 y12 w100 h" headerH " +0x200 cDCDCDC", "快捷键")
    hdrHex  := card.Add("Text", "x12 y12 w100 h" headerH " +0x200 cDCDCDC", "颜色")
    hdrTol  := card.Add("Text", "x12 y12 w100 h" headerH " +0x200 cDCDCDC", "容差")
    for ctl in [hdrId, hdrName, hdrKey, hdrHex, hdrTol] {
        ctl.SetFont("s10 Bold", "Segoe UI")
        try {
            ctl.BackColor := Format("0x{:06X}", theme.HeaderBg)
        }
    }

    ; 按钮（统一宿主背景为 HeaderBg，消除边缘色差）
    btnAdd := UIX_Button_Primary(card, 0, 0, actionW, 32, "添加技能", theme)
    try {
        info := UIX_OD.Map[btnAdd.Hwnd]
        if !IsObject(info.data) {
            info.data := Map()
        }
        info.data["HostBg"] := theme.HeaderBg
        UIX_OD.Map[btnAdd.Hwnd] := info
    }
    btnDel := UIX_Button_Secondary(card, 0, 0, 118, 32, "删除技能", theme)

    ; ===== ListView：隐藏原生表头、深色、去网格 =====
    lv := card.Add("ListView", "x12 y" (12 + headerH) " w760 h360 -Hdr +Report", ["ID","名称","快捷键","颜色","容差"])
    UIX_Theme_SkinListView(lv, theme, true)

    ; 行高 = rowH（通过小图像列表）
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

    ; 行间横线（本页闭包绑定 OnMessage，避免全局依赖）
    DrawHLineCB := (wParam, lParam, msg, hwnd) => PG_Skills_DrawLines(lv.Hwnd, lParam, theme.Border)
    OnMessage(0x004E, DrawHLineCB)

    ; ===== 数据填充/列宽布局/交互：顶层函数 + Bind =====
    FillFn   := PG_Skills_Fill.Bind(lv, ctx)
    LayoutFn := PG_Skills_LayoutCols.Bind(lv, hdrId, hdrName, hdrKey, hdrHex, hdrTol, headerH)

    btnAdd.OnEvent("Click", PG_Skills_OnAdd.Bind(ctx, FillFn))
    btnDel.OnEvent("Click", PG_Skills_OnDel.Bind(ctx, lv, FillFn))
    lv.OnEvent("DoubleClick", PG_Skills_OnEdit.Bind(ctx, lv))

    ReflowFn := PG_Skills_Reflow.Bind(dlg, tabs, card
        , hbBg, hbLine
        , hdrId, hdrName, hdrKey, hdrHex, hdrTol
        , lv, btnAdd, btnDel
        , theme, headerH, topSpace, actionW, actionGap
        , LayoutFn)

    FillFn.Call()
    ReflowFn.Call()

    Destroy(*) {
        ; 解除本页的 OnMessage 绑定
        OnMessage(0x004E, 0)
        return 0
    }
    return { Reflow: (p*) => ReflowFn.Call(), Save: (p*) => 0, Destroy: Destroy }
}

; ================== 子函数（顶层，避免 nonlocal） ==================

; 数据填充（第一列显示 ID）
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
        try {
            lv.Opt("+Redraw")
        } catch {
        }
    }
}

; 列宽布局：固定 ID=64，其余按比例 40/18/24/18（最小值保障）
PG_Skills_LayoutCols(lv, hdrId, hdrName, hdrKey, hdrHex, hdrTol, headerH, lvW) {
    idW := 64
    restW := Max(160, lvW - idW)
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
            temp := wKey - need
            if (temp < 60) {
                temp := 60
            }
            wKey := temp
        }
    }

    try {
        lv.ModifyCol(1, idW)
        lv.ModifyCol(2, wName)
        lv.ModifyCol(3, wKey)
        lv.ModifyCol(4, wHex)
        lv.ModifyCol(5, wTol)
    } catch {
    }

    baseX := 12
    hdrId.Move(  baseX,                              12, idW,   headerH)
    hdrName.Move(baseX + idW,                        12, wName, headerH)
    hdrKey.Move( baseX + idW + wName,                12, wKey,  headerH)
    hdrHex.Move( baseX + idW + wName + wKey,         12, wHex,  headerH)
    hdrTol.Move( baseX + idW + wName + wKey + wHex,  12, wTol,  headerH)
}

; 布局：为按钮预留操作区，表格不重叠
PG_Skills_Reflow(dlg, tabs, card, hbBg, hbLine
    , hdrId, hdrName, hdrKey, hdrHex, hdrTol
    , lv, btnAdd, btnDel, theme, headerH, topSpace, actionW, actionGap, LayoutFn) {
    r := UIX_PageRect(dlg)

    if (IsObject(tabs) && ObjHasOwnProp(tabs, "Reflow") && IsObject(tabs.Reflow)) {
        tabs.Reflow.Call(r.X, r.Y + 44)
    }

    cRect := { x: r.X, y: r.Y + topSpace, w: r.W, h: Max(220, r.H - topSpace) }
    card.Move(cRect.x, cRect.y, cRect.w, cRect.h)
    UIX_Theme_RoundWindow(card.Hwnd, theme.Radius)

    hbW := Max(200, cRect.w - 24)
    hbBg.Move(12, 12, hbW, headerH)
    hbLine.Move(12, 12 + headerH - 1, hbW, 1)

    ; 表格可视宽度（扣掉右上按钮操作区）
    lvW := Max(320, cRect.w - 24 - actionW - actionGap - 1)
    lvH := cRect.h - (12 + headerH) - (12 + 40)

    ; 右上按钮
    btnAdd.Move(12 + lvW + actionGap, 12, actionW, 32)
    ; 表格区域（不与按钮重叠）
    lv.Move(12, 12 + headerH, lvW, Max(120, lvH))
    ; 右下按钮
    btnDel.Move(cRect.w - 12 - 118, cRect.h - 32 - 12, 118, 32)

    LayoutFn.Call(lvW)
}

; —— 本页自带的行间横线绘制（闭包 OnMessage 使用） ——
PG_Skills_DrawLines(targetHwnd, lParam, borderRGB) {
    try {
        hwndFrom := NumGet(lParam, 0, "ptr")
        code     := NumGet(lParam, 2*A_PtrSize, "UInt")
        if (code != 0xFFFFFFF4) {
            return 0
        }
        stage := NumGet(lParam, 2*A_PtrSize + 4, "UInt")
        hdc   := NumGet(lParam, 2*A_PtrSize + 8, "ptr")
        if (hwndFrom != targetHwnd) {
            return 0
        }
        CDDS_PREPAINT  := 0x00000001
        CDDS_POSTPAINT := 0x00000002
        if (stage = CDDS_PREPAINT) {
            return 0x00000010  ; CDRF_NOTIFYPOSTPAINT
        }
        if (stage = CDDS_POSTPAINT) {
            LVM_GETTOPINDEX     := 0x1027
            LVM_GETCOUNTPERPAGE := 0x1028
            LVM_GETITEMCOUNT    := 0x1004
            LVM_GETITEMRECT     := 0x100E
            LVIR_BOUNDS := 0

            top := SendMessage(LVM_GETTOPINDEX, 0, 0, "ahk_id " targetHwnd)
            per := SendMessage(LVM_GETCOUNTPERPAGE, 0, 0, "ahk_id " targetHwnd)
            cnt := SendMessage(LVM_GETITEMCOUNT, 0, 0, "ahk_id " targetHwnd)
            if (cnt <= 0) {
                return 0
            }
            last := Min(cnt - 1, top + per + 1)

            pen := DllCall("gdi32\CreatePen", "int", 0, "int", 1, "uint", UIX_Theme_ColorRef(borderRGB), "ptr")
            old := DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", pen, "ptr")

            i := top
            while (i <= last) {
                rc := Buffer(16, 0)
                NumPut("Int", LVIR_BOUNDS, rc, 0)
                SendMessage(LVM_GETITEMRECT, i, rc.Ptr, "ahk_id " targetHwnd)
                l := NumGet(rc, 0, "Int")
                t := NumGet(rc, 4, "Int")
                r := NumGet(rc, 8, "Int")
                b := NumGet(rc, 12, "Int")
                y := b - 1
                DllCall("gdi32\MoveToEx", "ptr", hdc, "int", l + 1, "int", y, "ptr", 0)
                DllCall("gdi32\LineTo",   "ptr", hdc, "int", r - 1, "int", y)
                i += 1
            }

            DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", old)
            DllCall("gdi32\DeleteObject", "ptr", pen)
            return 0
        }
    } catch {
    }
    return 0
}

; ===== 行为：按钮/列表事件（顶层） =====
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