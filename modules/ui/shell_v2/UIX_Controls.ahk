#Requires AutoHotkey v2
#Include "UIX_Theme.ahk"

; ------------------ Owner-Draw 基础（一次性挂 WM_DRAWITEM） ------------------
global UIX_OD := { Inited: false, Map: Map() }   ; hwnd -> { kind, theme, data }

UIX_OD_Init() {
    global UIX_OD
    if (!UIX_OD.Inited) {
        OnMessage(0x002B, UIX_OD_OnDrawItem) ; WM_DRAWITEM
        UIX_OD.Inited := true
    }
}
UIX_OD_Register(btn, kind, theme := 0, data := 0) {
    global UIX_OD
    UIX_OD_Init()
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    if !IsObject(data) {
        data := Map()
    }
    UIX_OD.Map[btn.Hwnd] := { kind: kind, theme: theme, data: data }

    ; 设置 BS_OWNERDRAW
    GWL_STYLE := -16
    BS_OWNERDRAW := 0x0000000B
    style := DllCall("user32\GetWindowLongPtr", "ptr", btn.Hwnd, "int", GWL_STYLE, "ptr")
    style := (style | BS_OWNERDRAW)
    DllCall("user32\SetWindowLongPtr", "ptr", btn.Hwnd, "int", GWL_STYLE, "ptr", style)
    DllCall("user32\InvalidateRect", "ptr", btn.Hwnd, "ptr", 0, "int", 1)
}

; 颜色辅助
UIX_RGB_Shade(rgb, pct) {        ; pct: -60..+60
    k := pct / 100.0
    r := (rgb >> 16) & 0xFF, g := (rgb >> 8) & 0xFF, b := rgb & 0xFF
    if (k >= 0) {
        r := r + Round((255 - r) * k), g := g + Round((255 - g) * k), b := b + Round((255 - b) * k)
    } else {
        r := Round(r * (1 + k)), g := Round(g * (1 + k)), b := Round(b * (1 + k))
    }
    r := Max(0, Min(255, r)), g := Max(0, Min(255, g)), b := Max(0, Min(255, b))
    return (r << 16) | (g << 8) | b
}

; 文本获取
UIX_GetWndText(hwnd) {
    len := DllCall("user32\GetWindowTextLengthW", "ptr", hwnd, "int")
    buf := Buffer((len + 1) * 2, 0)
    DllCall("user32\GetWindowTextW", "ptr", hwnd, "ptr", buf.Ptr, "int", len + 1)
    return StrGet(buf, "UTF-16")
}

UIX_OD_OnDrawItem(wParam, lParam, msg, hwnd) {
    try {
        ; --- 结构解析 ---
        CtlType   := NumGet(lParam, 0, "UInt")                         ; 4=ODT_BUTTON
        itemState := NumGet(lParam, 16, "UInt")
        offH := (A_PtrSize = 8) ? 24 : 20
        offD := (A_PtrSize = 8) ? 32 : 24
        hwndItem := NumGet(lParam, offH, "Ptr")
        hDC      := NumGet(lParam, offD, "Ptr")
        rcL := NumGet(lParam, (A_PtrSize=8)?40:28, "Int")
        rcT := NumGet(lParam, (A_PtrSize=8)?44:32, "Int")
        rcR := NumGet(lParam, (A_PtrSize=8)?48:36, "Int")
        rcB := NumGet(lParam, (A_PtrSize=8)?52:40, "Int")

        if (CtlType != 4) {
            return 0
        }
        global UIX_OD
        if !UIX_OD.Map.Has(hwndItem) {
            return 0
        }
        info := UIX_OD.Map[hwndItem]
        theme := info.theme
        kind  := info.kind
        data  := info.data
        if !IsObject(data) {
            data := Map()
        }

        ; --- 状态 ---
        active := 0
        if (kind = "pill") {
            if (data.Has("Active")) {
                try active := data["Active"] ? 1 : 0
            }
        }
        pressed  := (itemState & 0x0001) ? 1 : 0
        disabled := (itemState & 0x0004) ? 1 : 0

        ; --- 颜色 ---
        bg := theme.HeaderBg, fg := theme.Text, bd := theme.Border, rad := theme.Radius
        if (kind = "primary") {
            bg := pressed ? UIX_RGB_Shade(theme.Accent, -10) : theme.Accent
            fg := theme.AccentText
            bd := UIX_RGB_Shade(theme.Accent, -20)
        } else if (kind = "secondary") {
            bg := pressed ? UIX_RGB_Shade(theme.HeaderBg, -10) : theme.HeaderBg
            fg := theme.Text
            bd := UIX_RGB_Shade(theme.Border, -10)
        } else if (kind = "pill") {
            if (active) {
                bg := pressed ? UIX_RGB_Shade(theme.Accent, -10) : theme.Accent
                fg := theme.AccentText
                bd := UIX_RGB_Shade(theme.Accent, -20)
            } else {
                bg := pressed ? UIX_RGB_Shade(theme.HeaderBg, -10) : theme.HeaderBg
                fg := theme.Text
                bd := UIX_RGB_Shade(theme.Border, -10)
            }
        }
        if (disabled) {
            fg := UIX_RGB_Shade(fg, -40)
            bd := UIX_RGB_Shade(bd, -30)
            bg := UIX_RGB_Shade(bg, -20)
        }

        ; --- 绘制 ---
        br := DllCall("gdi32\CreateSolidBrush", "uint", UIX_Theme_ColorRef(bg), "ptr")
        pn := DllCall("gdi32\CreatePen", "int", 0, "int", 1, "uint", UIX_Theme_ColorRef(bd), "ptr")
        oldPn := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", pn, "ptr")
        oldBr := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", br, "ptr")
        left := rcL + 1, top := rcT + 1, right := rcR - 1, bottom := rcB - 1
        DllCall("gdi32\RoundRect", "ptr", hDC, "int", left, "int", top, "int", right, "int", bottom, "int", rad*2, "int", rad*2)

        text := UIX_GetWndText(hwndItem)
        DllCall("gdi32\SetBkMode", "ptr", hDC, "int", 1)
        DllCall("gdi32\SetTextColor", "ptr", hDC, "int", UIX_Theme_ColorRef(fg))
        rc := Buffer(16, 0)
        NumPut("Int", rcL, rc, 0), NumPut("Int", rcT, rc, 4), NumPut("Int", rcR, rc, 8), NumPut("Int", rcB, rc, 12)
        DT_CENTER := 0x00000001, DT_VCENTER := 0x00000004, DT_SINGLELINE := 0x00000020
        DllCall("user32\DrawTextW", "ptr", hDC, "wstr", text, "int", StrLen(text), "ptr", rc.Ptr, "uint", DT_CENTER | DT_VCENTER | DT_SINGLELINE)

        DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", oldPn)
        DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", oldBr)
        DllCall("gdi32\DeleteObject", "ptr", pn)
        DllCall("gdi32\DeleteObject", "ptr", br)
        return 1
    } catch as e {
        ; 不让异常冒到 Builder，避免“加载页面失败”
        try UIX_Log("OD_OnDraw error: " e.Message " @ " e.File ":" e.Line)
        return 0
    }
}

; ------------------ 胶囊页签（Pill Tabs） ------------------
; 例： tabs := UIX_Pills_Create(dlg, x, y, ["角色配置","技能配置","BUFF配置","线程配置"], theme, 110, 28, 8)
;      tabs.SetActive(2), tabs.SetOnChange((i)=> ...)
UIX_Pills_Create(dlg, x, y, labels, theme := 0, w := 110, h := 28, gap := 8) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    btns := []
    active := 1
    onChanged := 0

    Create() {
        bx := x
        for i, t in labels {
            btn := dlg.Add("Button", Format("x{} y{} w{} h{}", bx, y, w, h), t)
            d := Map()
            d["Active"] := (i = active ? 1 : 0)
            UIX_OD_Register(btn, "pill", theme, d)
            btn.OnEvent("Click", (*) => OnClick(i))
            btns.Push(btn)
            bx += w + gap
        }
    }

    OnClick(i) {
        SetActive(i)
        if (onChanged) {
            try onChanged.Call(i)
        }
    }

    SetActive(i) {
        active := Max(1, Min(labels.Length, i))
        for idx, b in btns {
            if UIX_OD.Map.Has(b.Hwnd) {
                info := UIX_OD.Map[b.Hwnd]
                if !IsObject(info.data)
                    info.data := Map()
                info.data["Active"] := (idx = active ? 1 : 0)
                UIX_OD.Map[b.Hwnd] := info
                DllCall("user32\InvalidateRect", "ptr", b.Hwnd, "ptr", 0, "int", 1)
            }
        }
    }

    Reflow(nx, ny, *) {
        x := nx, y := ny
        bx := x
        for _, b in btns {
            b.Move(bx, y, w, h)
            bx += w + gap
        }
    }

    SetOnChange(cb) {
        onChanged := cb
    }

    Destroy(*) {
        for _, b in btns {
            try b.Destroy()
        }
        btns := []
    }

    Create()
    return { SetActive: SetActive, Reflow: Reflow, SetOnChange: SetOnChange, Destroy: Destroy }
}

; ------------------ 主次按钮（圆角） ------------------
; 用法： btn1 := UIX_Button_Primary(dlg, x, y, 110, 28, "添加技能", theme)
;       btn2 := UIX_Button_Secondary(dlg, x, y, 110, 28, "删除技能", theme)
UIX_Button_Primary(dlg, x, y, w, h, text, theme := 0) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    btn := dlg.Add("Button", Format("x{} y{} w{} h{}", x, y, w, h), text)
    UIX_OD_Register(btn, "primary", theme)
    return btn
}
UIX_Button_Secondary(dlg, x, y, w, h, text, theme := 0) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    btn := dlg.Add("Button", Format("x{} y{} w{} h{}", x, y, w, h), text)
    UIX_OD_Register(btn, "secondary", theme)
    return btn
}