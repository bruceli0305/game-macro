#Requires AutoHotkey v2

UIX_Theme_Get() {
    return {
        Bg:        0x14181E
      , PanelBg:   0x161B22
      , CardBg:    0x1C222B
      , Border:    0x2A313B
      , Text:      0xE6E6E6
      , Subtext:   0xC8C8C8
      , HeaderBg:  0x222A33
      , HeaderFg:  0xDCDCDC
      , Grid:      0x2B333D
      , Accent:    0x3D7EFF
      , AccentText:0xFFFFFF
      , Radius:    10
    }
}

UIX_Theme_ColorRef(rgb) {
    return ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 0xFF)
}

UIX_Theme_ApplyWindow(gui, theme := 0) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    try {
        gui.BackColor := Format("0x{:06X}", theme.Bg)
    } catch {
    }
    UIX_Theme_EnableDarkForWindow(gui.Hwnd)
}

UIX_Theme_EnableDarkForWindow(hwnd) {
    try {
        DWMWA_USE_IMMERSIVE_DARK_MODE := 20
        pv := Buffer(4, 0)
        NumPut("UInt", 1, pv, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "ptr", pv.Ptr, "int", 4)
    } catch {
    }
}

UIX_Theme_SetDarkTheme(hwnd) {
    try {
        DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "wstr", "DarkMode_Explorer", "ptr", 0)
    } catch {
    }
}

UIX_Theme_SkinListView(lv, theme := 0, disableGrid := true) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    try {
        UIX_Theme_SetDarkTheme(lv.Hwnd)
        bg := UIX_Theme_ColorRef(theme.CardBg)
        fg := UIX_Theme_ColorRef(theme.Text)
        SendMessage 0x1001, 0, bg, lv    ; LVM_SETBKCOLOR
        SendMessage 0x1024, 0, fg, lv    ; LVM_SETTEXTCOLOR
        SendMessage 0x1026, 0, bg, lv    ; LVM_SETTEXTBKCOLOR

        ; 扩展样式：整行选择 + 双缓冲；按需去网格
        LVM_GETEXTENDEDLISTVIEWSTYLE := 0x1037
        LVM_SETEXTENDEDLISTVIEWSTYLE := 0x1036
        LVS_EX_GRIDLINES := 0x0001
        LVS_EX_FULLROWSELECT := 0x0020
        LVS_EX_DOUBLEBUFFER  := 0x10000
        curEx := SendMessage(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0, lv)
        newEx := (curEx | LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER)
        if (disableGrid) {
            newEx := newEx & ~LVS_EX_GRIDLINES
        }
        if (newEx != curEx) {
            SendMessage(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, newEx, lv)
        }

        ; Header 深色（能用就用）
        LVM_GETHEADER := 0x101F
        hHdr := SendMessage(LVM_GETHEADER, 0, 0, lv)
        if (hHdr) {
            UIX_Theme_SetDarkTheme(hHdr)
        }
    } catch {
    }
}

UIX_Theme_CreateCardPanel(parentHwnd, rect, theme := 0, radius := 10) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    card := Gui()
    card.MarginX := 12
    card.MarginY := 12
    card.Opt("-Caption -SysMenu -MinimizeBox -MaximizeBox -Border +Theme")
    try {
        card.BackColor := Format("0x{:06X}", theme.CardBg)
    } catch {
    }

    DllCall("user32\SetParent", "ptr", card.Hwnd, "ptr", parentHwnd)

    GWL_STYLE := -16
    WS_CHILD := 0x40000000
    WS_POPUP := 0x80000000
    WS_CLIPCHILDREN := 0x02000000
    WS_CLIPSIBLINGS := 0x04000000
    style := DllCall("user32\GetWindowLongPtr", "ptr", card.Hwnd, "int", GWL_STYLE, "ptr")
    style := (style & ~WS_POPUP) | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
    DllCall("user32\SetWindowLongPtr", "ptr", card.Hwnd, "int", GWL_STYLE, "ptr", style)

    SWP_NOZORDER := 0x0004
    SWP_FRAMECHANGED := 0x0020
    SWP_SHOWWINDOW := 0x0040
    DllCall("user32\SetWindowPos", "ptr", card.Hwnd, "ptr", 0
        , "int", rect.x, "int", rect.y, "int", rect.w, "int", rect.h
        , "uint", SWP_NOZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW)

    UIX_Theme_RoundWindow(card.Hwnd, radius)
    return card
}

UIX_Theme_RoundWindow(hwnd, radius := 10) {
    r := DllCall("gdi32\CreateRoundRectRgn", "int", 0, "int", 0, "int", 0x7FFF, "int", 0x7FFF
        , "int", radius*2, "int", radius*2, "ptr")
    if (r) {
        DllCall("user32\SetWindowRgn", "ptr", hwnd, "ptr", r, "int", 1)
    }
}

UIX_Theme_AddColorIconToImageList(hIL, rgb, w := 14, h := 10) {
    if (!hIL) {
        hIL := DllCall("comctl32\ImageList_Create", "int", 16, "int", 16, "uint", 0x00000020, "int", 8, "int", 8, "ptr")
    }
    bmi := Buffer(40, 0)
    NumPut("UInt", 40, bmi, 0)
    NumPut("Int", w,  bmi, 4)
    NumPut("Int", -h, bmi, 8)
    NumPut("UShort", 1, bmi, 12)
    NumPut("UShort", 32, bmi, 14)

    hdc := DllCall("gdi32\CreateCompatibleDC", "ptr", 0, "ptr")
    pBits := 0
    hBmp := DllCall("gdi32\CreateDIBSection", "ptr", hdc, "ptr", bmi.Ptr, "uint", 0
        , "ptr*", &pBits, "ptr", 0, "uint", 0, "ptr")
    if (!hBmp || !pBits) {
        if (hdc) {
            DllCall("gdi32\DeleteDC", "ptr", hdc)
        }
        return hIL
    }
    stride := w * 4
    r := (rgb >> 16) & 0xFF
    g := (rgb >> 8) & 0xFF
    b :=  rgb        & 0xFF
    y := 0
    loop h {
        x := 0
        loop w {
            off := y * stride + x * 4
            NumPut("UInt", (0xFF << 24) | (r << 16) | (g << 8) | b, pBits, off)
            x += 1
        }
        y += 1
    }
    hOld := DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", hBmp, "ptr")
    DllCall("comctl32\ImageList_Add", "ptr", hIL, "ptr", hBmp, "ptr", 0)
    if (hOld) {
        DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", hOld)
    }
    DllCall("gdi32\DeleteObject", "ptr", hBmp)
    DllCall("gdi32\DeleteDC", "ptr", hdc)
    return hIL
}

; ---------- 深色 ListBox 皮肤（用于左侧导航） ----------
; 通过 WM_CTLCOLORLISTBOX 设置文本/背景色
global UIX_Theme__LB := Map()
global UIX_Theme__LB_Initialized := false

UIX_Theme_SkinListBox(lb, theme := 0) {
    global UIX_Theme__LB, UIX_Theme__LB_Initialized
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    UIX_Theme__LB[lb.Hwnd] := {
        FG: UIX_Theme_ColorRef(theme.Text)
      , BG: UIX_Theme_ColorRef(theme.PanelBg)
      , Brush: DllCall("gdi32\CreateSolidBrush", "uint", UIX_Theme_ColorRef(theme.PanelBg), "ptr")
    }
    if (!UIX_Theme__LB_Initialized) {
        OnMessage(0x0134, UIX_Theme__OnCtlColorListBox)  ; WM_CTLCOLORLISTBOX
        UIX_Theme__LB_Initialized := true
    }
}

UIX_Theme__OnCtlColorListBox(wParam, lParam, msg, hwnd) {
    global UIX_Theme__LB
    try {
        if (UIX_Theme__LB.Has(lParam)) {
            data := UIX_Theme__LB[lParam]
            ; 设置 DC 颜色
            DllCall("gdi32\SetTextColor", "ptr", wParam, "int", data.FG)
            DllCall("gdi32\SetBkColor",   "ptr", wParam, "int", data.BG)
            return data.Brush
        }
    } catch {
    }
    return 0
}