#Requires AutoHotkey v2
#Include "..\UIX_Common.ahk"
#Include "..\UIX_Theme.ahk"
#Include "..\UIX_Controls.ahk"

PG_Skills_Build(ctx, theme := 0) {
    dlg := ctx.dlg
    if (!theme) {
        theme := UIX_Theme_Get()
    }

    rc := UIX_PageRect(dlg)

    ; 标题
    ttl := dlg.Add("Text", Format("x{} y{} w420", rc.X, rc.Y), "配置管理 · 技能配置")
    ttl.SetFont("s12 Bold", "Segoe UI")

    ; 胶囊页签（替代原四个按钮）
    tabs := UIX_Pills_Create(dlg, rc.X, rc.Y + 36, ["角色配置","技能配置","BUFF配置","线程配置"], theme, 110, 28, 10)
    tabs.SetActive(2)
    tabs.SetOnChange((i) => (
        (i=1) ? 0
      : (i=2) ? 0
      : (i=3) ? BuffsManager_Show()
      : (i=4) ? ThreadsManager_Show() : 0
    ))

    ; 卡片：ListView + 按钮
    cardRect := { x: rc.X, y: rc.Y + 36 + 40, w: rc.W, h: Max(260, rc.H - 36 - 40 - 60) }
    card := UIX_Theme_CreateCardPanel(dlg.Hwnd, cardRect, theme, theme.Radius)

    ; 主/次按钮（圆角）
    btnAdd := UIX_Button_Primary(card, 0, 0, 110, 28, "添加技能", theme)
    btnDel := UIX_Button_Secondary(card, 0, 0, 110, 28, "删除技能", theme)

    ; 深色 ListView（去网格，保留表头）
    lv := card.Add("ListView", "x12 y48 w760 h360 +Report", ["", "名称", "快捷键", "颜色", "容差"])
    UIX_Theme_SkinListView(lv, theme, true)

    ; 色块图标缓存
    hIL := 0
    colorIconMap := Map()  ; hex -> image index

    Fill() {
        lv.Opt("-Redraw")
        lv.Delete()

        prof := ctx.prof
        if (IsObject(prof.Skills) && prof.Skills.Length > 0) {
            for i, s in prof.Skills {
                hex := Pixel_ColorToHex(Pixel_HexToInt(s.Color))
                idx := 0
                if colorIconMap.Has(hex) {
                    idx := colorIconMap[hex]
                } else {
                    rgb := Pixel_HexToInt(hex)
                    hIL := UIX_Theme_AddColorIconToImageList(hIL, rgb)
                    idx := DllCall("comctl32\ImageList_GetImageCount", "ptr", hIL, "int")
                    colorIconMap[hex] := idx
                    ; 绑定到 ListView（小图标）
                    LVM_SETIMAGELIST := 0x1003
                    LVSIL_SMALL := 1
                    SendMessage(LVM_SETIMAGELIST, LVSIL_SMALL, hIL, lv)
                }
                ; 第一列图标：IconN
                lv.Add("Icon" idx, "", s.Name, s.Key, hex, s.Tol)
            }
        }
        ; 列宽：首列给色块，其他自适应
        lv.ModifyCol(1, 26)
        loop 4
            lv.ModifyCol(A_Index + 1, "AutoHdr")

        lv.Opt("+Redraw")
    }

    OnAdd(*) {
        SkillEditor_Open({}, 0, OnSavedNew)
    }
    OnSavedNew(newSkill, idx) {
        global App
        App["ProfileData"].Skills.Push(newSkill)
        Storage_SaveProfile(App["ProfileData"])
        Fill()
    }

    OnEdit(*) {
        row := lv.GetNext(0, "Focused")
        if (!row) {
            MsgBox "请先选择一条记录。"
            return
        }
        idx := row
        cur := ctx.prof.Skills[idx]
        SkillEditor_Open(cur, idx, OnSavedEdit)
    }
    OnSavedEdit(newSkill, idx2) {
        global App
        App["ProfileData"].Skills[idx2] := newSkill
        Storage_SaveProfile(App["ProfileData"])
        Fill()
    }

    OnDel(*) {
        row := lv.GetNext(0, "Focused")
        if (!row) {
            MsgBox "请先选择一条记录。"
            return
        }
        idx := row
        ctx.prof.Skills.RemoveAt(idx)
        Storage_SaveProfile(ctx.prof)
        Fill()
    }

    btnAdd.OnEvent("Click", OnAdd)
    btnDel.OnEvent("Click", OnDel)
    lv.OnEvent("DoubleClick", OnEdit)

    Reflow(ctx2 := 0) {
        r := UIX_PageRect(dlg)
        ttl.Move(r.X, r.Y, 420, 28)

        ; 胶囊页签位置
        xTab := r.X
        yTab := r.Y + 36
        (tabs.Reflow).Call(xTab, yTab)

        ; 卡片区域
        cRect := { x: r.X, y: yTab + 40, w: r.W, h: Max(220, r.H - (yTab + 40 - r.Y) - 20) }
        card.Move(cRect.x, cRect.y, cRect.w, cRect.h)
        UIX_Theme_RoundWindow(card.Hwnd, theme.Radius)

        ; 卡片内控件布局
        btnAdd.Move(cRect.w - 12 - 110, 12, 110, 28)
        lv.Move(12, 48, cRect.w - 24, cRect.h - 48 - 52)
        btnDel.Move(cRect.w - 12 - 110, cRect.h - 40, 110, 28)
    }

    Fill()
    Reflow()
    return { Reflow: Reflow, Save: (c*) => 0, Destroy: (c*) => 0 }
}