#Requires AutoHotkey v2
; modules\ui\shell_v2\UIX_Controls.ahk
#Include "UIX_Theme.ahk"

; =================================================================
; Owner-Draw 基础（圆角按钮 / 胶囊）
; =================================================================

; 全局注册表：保存每个被接管的控件信息（hwnd -> {kind, theme, data})
global UIX_OD := { Inited: false, Map: Map() }

UIX_OD_Init() {
    global UIX_OD
    if (!UIX_OD.Inited) {
        OnMessage(0x002B, UIX_OD_OnDrawItem) ; WM_DRAWITEM
        UIX_OD.Inited := true
    }
}

; 注册一个被接管的按钮
; kind: "primary" | "secondary" | "pill"
; data: Map，可包含 Active(0/1)、HostBg(0xRRGGBB)
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

    ; 设置 OwnerDraw
    GWL_STYLE := -16
    BS_OWNERDRAW := 0x0000000B
    style := DllCall("user32\GetWindowLongPtr", "ptr", btn.Hwnd, "int", GWL_STYLE, "ptr")
    style := style | BS_OWNERDRAW
    DllCall("user32\SetWindowLongPtr", "ptr", btn.Hwnd, "int", GWL_STYLE, "ptr", style)

    ; 重绘
    DllCall("user32\InvalidateRect", "ptr", btn.Hwnd, "ptr", 0, "int", 1)
}

; 颜色明暗调整（-60..+60）
UIX_RGB_Shade(rgb, pct) {
    k := pct / 100.0
    r := (rgb >> 16) & 0xFF
    g := (rgb >> 8) & 0xFF
    b := rgb & 0xFF
    if (k >= 0) {
        r := r + Round((255 - r) * k)
        g := g + Round((255 - g) * k)
        b := b + Round((255 - b) * k)
    } else {
        r := Round(r * (1 + k))
        g := Round(g * (1 + k))
        b := Round(b * (1 + k))
    }
    if (r < 0)  r := 0
    if (r > 255) r := 255
    if (g < 0)  g := 0
    if (g > 255) g := 255
    if (b < 0)  b := 0
    if (b > 255) b := 255
    return (r << 16) | (g << 8) | b
}

; 取窗口文本
UIX_GetWndText(hwnd) {
    len := DllCall("user32\GetWindowTextLengthW", "ptr", hwnd, "int")
    buf := Buffer((len + 1) * 2, 0)
    DllCall("user32\GetWindowTextW", "ptr", hwnd, "ptr", buf.Ptr, "int", len + 1)
    return StrGet(buf, "UTF-16")
}

; WM_DRAWITEM 回调：绘制圆角胶囊/按钮
UIX_OD_OnDrawItem(wParam, lParam, msg, hwnd) {
    try {
        ; DRAWITEMSTRUCT
        CtlType   := NumGet(lParam, 0, "UInt")       ; 4=ODT_BUTTON
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

        ; 先铺宿主背景，避免四角白边
        hostBg := theme.PanelBg
        if (data.Has("HostBg")) {
            hostBg := data["HostBg"]
        }
        hostBr := DllCall("gdi32\CreateSolidBrush", "uint", UIX_Theme_ColorRef(hostBg), "ptr")
        rcAll := Buffer(16, 0)
        NumPut("Int", rcL, rcAll, 0)
        NumPut("Int", rcT, rcAll, 4)
        NumPut("Int", rcR, rcAll, 8)
        NumPut("Int", rcB, rcAll, 12)
        DllCall("user32\FillRect", "ptr", hDC, "ptr", rcAll.Ptr, "ptr", hostBr)
        DllCall("gdi32\DeleteObject", "ptr", hostBr)

        ; 状态
        active := 0
        if (kind = "pill") {
            if (data.Has("Active")) {
                if (data["Active"]) {
                    active := 1
                }
            }
        }
        pressed  := (itemState & 0x0001) ? 1 : 0     ; ODS_SELECTED
        disabled := (itemState & 0x0004) ? 1 : 0     ; ODS_DISABLED

        ; 颜色
        bg := theme.HeaderBg
        fg := theme.Text
        bd := theme.Border
        rad := theme.Radius

        if (kind = "primary") {
            if (pressed) {
                bg := UIX_RGB_Shade(theme.Accent, -10)
            } else {
                bg := theme.Accent
            }
            fg := theme.AccentText
            bd := UIX_RGB_Shade(theme.Accent, -20)
        } else if (kind = "secondary") {
            if (pressed) {
                bg := UIX_RGB_Shade(theme.HeaderBg, -10)
            } else {
                bg := theme.HeaderBg
            }
            fg := theme.Text
            bd := UIX_RGB_Shade(theme.Border, -10)
        } else if (kind = "pill") {
            if (active) {
                if (pressed) {
                    bg := UIX_RGB_Shade(theme.Accent, -10)
                } else {
                    bg := theme.Accent
                }
                fg := theme.AccentText
                bd := UIX_RGB_Shade(theme.Accent, -20)
            } else {
                if (pressed) {
                    bg := UIX_RGB_Shade(theme.HeaderBg, -10)
                } else {
                    bg := theme.HeaderBg
                }
                fg := theme.Text
                bd := UIX_RGB_Shade(theme.Border, -10)
            }
        }

        if (disabled) {
            fg := UIX_RGB_Shade(fg, -40)
            bd := UIX_RGB_Shade(bd, -30)
            bg := UIX_RGB_Shade(bg, -20)
        }

        ; 画圆角底与描边（内缩 1px）
        br := DllCall("gdi32\CreateSolidBrush", "uint", UIX_Theme_ColorRef(bg), "ptr")
        pn := DllCall("gdi32\CreatePen", "int", 0, "int", 1, "uint", UIX_Theme_ColorRef(bd), "ptr")
        oldPn := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", pn, "ptr")
        oldBr := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", br, "ptr")
        left := rcL + 1
        top  := rcT + 1
        right := rcR - 1
        bottom:= rcB - 1
        DllCall("gdi32\RoundRect", "ptr", hDC, "int", left, "int", top, "int", right, "int", bottom, "int", rad*2, "int", rad*2)

        ; 文本
        text := UIX_GetWndText(hwndItem)
        DllCall("gdi32\SetBkMode", "ptr", hDC, "int", 1) ; TRANSPARENT
        DllCall("gdi32\SetTextColor", "ptr", hDC, "int", UIX_Theme_ColorRef(fg))
        rcTxt := Buffer(16, 0)
        NumPut("Int", rcL, rcTxt, 0)
        NumPut("Int", rcT, rcTxt, 4)
        NumPut("Int", rcR, rcTxt, 8)
        NumPut("Int", rcB, rcTxt, 12)
        DT_CENTER := 0x00000001
        DT_VCENTER:= 0x00000004
        DT_SINGLELINE := 0x00000020
        DllCall("user32\DrawTextW", "ptr", hDC, "wstr", text, "int", StrLen(text), "ptr", rcTxt.Ptr, "uint", DT_CENTER | DT_VCENTER | DT_SINGLELINE)

        ; 清理
        DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", oldPn)
        DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", oldBr)
        DllCall("gdi32\DeleteObject", "ptr", pn)
        DllCall("gdi32\DeleteObject", "ptr", br)

        return 1
    } catch {
        return 0
    }
}

; =================================================================
; 胶囊页签（Pill Tabs）：稳定版（无 nonlocal、无 Func()）
; =================================================================

; 用法：
;   tabs := UIX_Pills_Create(dlg, x, y, ["角色","技能","BUFF","线程"], theme, 136, 36, 14)
;   tabs.SetActive.Call(2)
;   tabs.SetOnChange.Call(CallbackFunc)  ; CallbackFunc(i)
;   tabs.Reflow.Call(newX, newY)
UIX_Pills_Create(dlg, x, y, labels, theme := 0, w := 110, h := 28, gap := 8) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }

    state := Map()
    state["dlg"] := dlg
    state["x"] := x
    state["y"] := y
    state["labels"] := labels
    state["theme"] := theme
    state["w"] := w
    state["h"] := h
    state["gap"] := gap
    state["active"] := 1
    state["btns"] := []
    state["onChanged"] := 0  ; 仅接受函数对象

    bx := x
    for i, t in labels {
        btn := dlg.Add("Button", Format("x{} y{} w{} h{}", bx, y, w, h), t)
        d := Map()
        d["Active"] := (i = state["active"] ? 1 : 0)
        d["HostBg"] := theme.PanelBg
        UIX_OD_Register(btn, "pill", theme, d)
        ; 点击：固定签名 (state, idx, ctrl?, info?)
        btn.OnEvent("Click", UIX_Pills_OnClick.Bind(state, i))
        state["btns"].Push(btn)
        bx += w + gap
    }

    ret := {}
    ret.SetActive   := UIX_Pills_SetActive.Bind(state)
    ret.Reflow      := UIX_Pills_Reflow.Bind(state)
    ret.SetOnChange := UIX_Pills_SetOnChange.Bind(state)
    ret.Destroy     := UIX_Pills_Destroy.Bind(state)
    return ret
}

UIX_Pills_OnClick(state, idx, ctrl := 0, info := 0) {
    UIX_Pills_SetActive(state, idx)
    cb := 0
    try cb := state["onChanged"]
    if (IsObject(cb)) {
        try cb.Call(idx)
    }
}

UIX_Pills_SetActive(state, i) {
    max := 0
    try max := state["labels"].Length
    if (max <= 0) {
        max := 1
    }
    ai := i
    if (ai < 1) {
        ai := 1
    } else if (ai > max) {
        ai := max
    }
    state["active"] := ai

    for idx, b in state["btns"] {
        global UIX_OD
        if UIX_OD.Map.Has(b.Hwnd) {
            info := UIX_OD.Map[b.Hwnd]
            if !IsObject(info.data) {
                info.data := Map()
            }
            info.data["Active"] := (idx = ai ? 1 : 0)
            UIX_OD.Map[b.Hwnd] := info
            DllCall("user32\InvalidateRect", "ptr", b.Hwnd, "ptr", 0, "int", 1)
        }
    }
}

UIX_Pills_Reflow(state, nx, ny) {
    state["x"] := nx
    state["y"] := ny
    bx := nx
    w := state["w"]
    h := state["h"]
    gap := state["gap"]
    for _, b in state["btns"] {
        b.Move(bx, ny, w, h)
        bx += w + gap
    }
}

UIX_Pills_SetOnChange(state, cb) {
    if (IsObject(cb)) {
        state["onChanged"] := cb
    } else {
        state["onChanged"] := 0
    }
}

UIX_Pills_Destroy(state, p*) {
    for _, b in state["btns"] {
        try b.Destroy()
    }
    state["btns"] := []
}

; =================================================================
; 圆角按钮（主/次）
; =================================================================

UIX_Button_Primary(dlg, x, y, w, h, text, theme := 0) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    btn := dlg.Add("Button", Format("x{} y{} w{} h{}", x, y, w, h), text)
    d := Map()
    d["HostBg"] := theme.CardBg
    UIX_OD_Register(btn, "primary", theme, d)
    return btn
}

UIX_Button_Secondary(dlg, x, y, w, h, text, theme := 0) {
    if (!theme) {
        theme := UIX_Theme_Get()
    }
    btn := dlg.Add("Button", Format("x{} y{} w{} h{}", x, y, w, h), text)
    d := Map()
    d["HostBg"] := theme.CardBg
    UIX_OD_Register(btn, "secondary", theme, d)
    return btn
}