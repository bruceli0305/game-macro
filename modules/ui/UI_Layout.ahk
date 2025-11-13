#Requires AutoHotkey v2
; UI_Layout.ahk (Left-Nav Only + Common helpers)
; 说明：
; - 适配当前左侧菜单新架构
; - 提供通用 DPI/重绘方法
; - 恢复 UI_TabPageRect（供旋转编辑器等内部 Tab 使用）
; - 严格块结构 if/try/catch，不使用单行形式

; 获取窗口 DPI 缩放比（DPI/96.0）
UI_GetScale(hwnd := 0) {
    try {
        if (hwnd) {
            dpi := DllCall("user32\GetDpiForWindow", "ptr", hwnd, "uint")
            if (dpi) {
                return dpi / 96.0
            }
        }
    } catch {
    }
    hdc := DllCall("user32\GetDC", "ptr", hwnd, "ptr")
    if (hdc) {
        LOGPIXELSX := 88
        dpi := 96
        try {
            dpi := DllCall("gdi32\GetDeviceCaps", "ptr", hdc, "int", LOGPIXELSX, "int")
        } catch {
            dpi := 96
        }
        DllCall("user32\ReleaseDC", "ptr", hwnd, "ptr", hdc)
        if (dpi) {
            return dpi / 96.0
        }
    }
    return 1.0
}

; 计算 Tab 当前页的内容矩形（px -> DIPs），供内部 Tab 控件使用
UI_TabPageRect(tabCtrl) {
    ; 兼容性与安全检查
    if (!IsObject(tabCtrl)) {
        return { X: 0, Y: 0, W: 0, H: 0 }
    }

    rc := Buffer(16, 0)
    try {
        DllCall("user32\GetClientRect", "ptr", tabCtrl.Hwnd, "ptr", rc.Ptr)
    } catch {
        return { X: 0, Y: 0, W: 0, H: 0 }
    }

    ; TCM_ADJUSTRECT 把客户区转换为“显示矩形”（px）
    try {
        DllCall("user32\SendMessage", "ptr", tabCtrl.Hwnd, "uint", 0x1328, "ptr", 0, "ptr", rc.Ptr)
    } catch {
    }

    ; 映射到父窗口坐标（像素）
    parent := 0
    try {
        parent := DllCall("user32\GetParent", "ptr", tabCtrl.Hwnd, "ptr")
        DllCall("user32\MapWindowPoints", "ptr", tabCtrl.Hwnd, "ptr", parent, "ptr", rc.Ptr, "uint", 2)
    } catch {
    }

    x_px := NumGet(rc, 0, "Int")
    y_px := NumGet(rc, 4, "Int")
    w_px := NumGet(rc, 8, "Int") - x_px
    h_px := NumGet(rc, 12, "Int") - y_px

    ; 转为 DIPs（AHK Move 使用的坐标体系）
    scale := 1.0
    try {
        scale := UI_GetScale(tabCtrl.Hwnd)
    } catch {
        scale := 1.0
    }

    x := Round(x_px / scale)
    y := Round(y_px / scale)
    w := Round(w_px / scale)
    h := Round(h_px / scale)

    return { X: x, Y: y, W: w, H: h }
}

; 强制重绘主窗体及全部子控件（修复恢复后未重绘）
UI_ForceRedrawAll() {
    global UI
    try {
        if (IsSet(UI) && UI.Has("Main") && UI.Main) {
            flags := 0x0001 | 0x0080 | 0x0100   ; RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_UPDATENOW
            DllCall("user32\RedrawWindow", "ptr", UI.Main.Hwnd, "ptr", 0, "ptr", 0, "uint", flags)
        }
    } catch {
    }
}

; 安全移动控件（供各页面可选使用）
UI_MoveSafe(ctrl, x := "", y := "", w := "", h := "") {
    try {
        if (w = "" && h = "") {
            ctrl.Move(x, y)
        } else if (h = "") {
            ctrl.Move(x, y, w)
        } else {
            ctrl.Move(x, y, w, h)
        }
    } catch {
    }
}