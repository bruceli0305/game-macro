; modules\ui\shell_v2\UIX_Common.ahk
#Requires AutoHotkey v2

; ---------- 日志 ----------
UIX_Log(msg) {
    try {
        DirCreate(A_ScriptDir "\Logs")
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [ShellV2] " msg "`r`n"
            , A_ScriptDir "\Logs\ui_shellv2.log", "UTF-8")
    }
}
; ---------- DPI ----------
UIX_EnablePerMonitorDPI() {
    try {
        DllCall("user32\SetProcessDpiAwarenessContext", "ptr", -4, "ptr")  ; PER_MONITOR_AWARE_V2
    } catch {
        try {
            DllCall("shcore\SetProcessDpiAwareness", "int", 2, "int")      ; PROCESS_PER_MONITOR_DPI_AWARE
        } catch {
            try {
                DllCall("user32\SetProcessDPIAware")                        ; System DPI aware
            } catch {
            }
        }
    }
}

UIX_GetScale(hwnd) {
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
        dpi := DllCall("gdi32\GetDeviceCaps", "ptr", hdc, "int", 88, "int")
        DllCall("user32\ReleaseDC", "ptr", hwnd, "ptr", hdc)
        if (dpi) {
            return dpi / 96.0
        }
    }
    return 1.0
}

; ---------- 判断是否为 Tab 控件 ----------
UIX_IsTab(hwnd) {
    if (!hwnd) {
        return 0
    }
    buf := Buffer(512, 0)  ; 256 个 UTF-16 字符
    len := DllCall("user32\GetClassNameW", "ptr", hwnd, "ptr", buf.Ptr, "int", buf.Size // 2, "int")
    if (len <= 0) {
        return 0
    }
    cls := StrGet(buf.Ptr, len, "UTF-16")
    return (cls = "SysTabControl32") ? 1 : 0
}

; ---------- 页面矩形（Tab 用 UI_TabPageRect；普通子 Gui 用自身 ClientRect） ----------
UIX_PageRect(ctrl) {
    try {
        if (IsObject(ctrl) && HasProp(ctrl, "Hwnd")) {
            if (UIX_IsTab(ctrl.Hwnd)) {
                r := UI_TabPageRect(ctrl)
                if (IsObject(r)) {
                    return r
                }
            }
            rc := Buffer(16, 0)
            DllCall("user32\GetClientRect", "ptr", ctrl.Hwnd, "ptr", rc.Ptr)
            wpx := NumGet(rc, 8, "Int")
            hpx := NumGet(rc, 12, "Int")
            s := UIX_GetScale(ctrl.Hwnd)
            w := Round(wpx / s)
            h := Round(hpx / s)
            return { X: 12, Y: 12, W: Max(60, w - 24), H: Max(60, h - 24) }
        }
    } catch {
    }
    return { X: 12, Y: 12, W: 820, H: 520 }
}
; ---------- 通用 Owner ----------
UIX_CreateOwnedGui(title := "", owned := true) {
    if (owned) {
        try {
            if IsSet(UI) && IsObject(UI) && UI.Has("Main") && UI.Main && UI.Main.Hwnd
                return Gui("+Owner" UI.Main.Hwnd, title)
        }
    }
    return Gui(, title)
}

; ---------- 枚举子窗口 ----------
; 同时把 UIX_EnumChildHwnds() 也改成块级 finally（避免单行 finally 造成解析歧义）
UIX_EnumChildHwnds(hwndParent) {
    arr := []
    cb := CallbackCreate((h, lParam) => (arr.Push(h), 1), "Fast")
    try {
        DllCall("user32\EnumChildWindows", "ptr", hwndParent, "ptr", cb, "ptr", 0)
    } finally {
        try CallbackFree(cb)
    }
    return arr
}

; ---------- 左侧导航（分组不可选） ----------
; items = [{type:"sep",text:"配置"},{key:"general",text:"常规设置"},...]
; 请用以下版本替换 modules\ui\shell_v2\UIX_Common.ahk 中的 UIX_Nav_Build()
; 以及 UIX_EnumChildHwnds()（严格 v2：catch/ finally 都使用块级大括号）

UIX_Nav_Build(gui, x, y, w, h, items) {
    lb := gui.Add("ListBox", Format("x{} y{} w{} h{}", x, y, w, h))
    map := []
    lastSelectable := 0
    onChanged := 0

    ; 适配不同 v2 版本：优先数组，失败回退字符串（块级 try/catch）
    AddItem(text) {
        try {
            lb.Add([text])            ; 新版 v2 需要数组
        } catch {
            lb.Add(text)              ; 兼容旧版 v2
        }
    }

    ; 填充行
    for _, it in items {
        if (HasProp(it, "type") && it.type = "sep") {
            AddItem("— " it.text " —")
            map.Push("")
        } else {
            AddItem("  " it.text)
            map.Push(HasProp(it, "key") ? it.key : "")
            lastSelectable := map.Length
        }
    }

    lb.OnEvent("Change", (*) => NavChange())

    NavChange() {
        idx := lb.Value
        if (idx < 1 || idx > map.Length)
            return
        if (map[idx] = "") {
            left := idx - 1, right := idx + 1, moved := false
            while (left >= 1 || right <= map.Length) {
                if (left >= 1 && map[left] != "") {
                    lb.Value := left, moved := true
                    break
                }
                if (right <= map.Length && map[right] != "") {
                    lb.Value := right, moved := true
                    break
                }
                left -= 1, right += 1
            }
            if (!moved && lastSelectable)
                lb.Value := lastSelectable
        }
        if (onChanged) {
            try {
                onChanged.Call(UIX_Nav_GetKey())
            } catch as e {
                ; 可选：日志/提示
            }
        }
    }

    ; 这三个函数使用可变参形式，允许点号调用时传入多余参数
    UIX_Nav_GetKey(*) {
        idx := lb.Value
        if (idx >= 1 && idx <= map.Length)
            return map[idx]
        return ""
    }
    UIX_Nav_SelectKey(key, *) {
        if (key = "")
            return
        for i, k in map {
            if (k = key) {
                lb.Value := i
                if (onChanged) {
                    try onChanged.Call(key)
                }
                return
            }
        }
    }
    UIX_Nav_SetOnChange(cb, *) {
        onChanged := cb
    }

    return { Ctrl: lb
           , Map: map
           , GetKey: UIX_Nav_GetKey
           , SelectKey: UIX_Nav_SelectKey
           , SetOnChange: UIX_Nav_SetOnChange }
}

; ---------- 列表 + 右侧按钮列（保留，以便需要时使用） ----------
UIX_ListWithButtonColumn(gui, baseX, baseY, totalW, rows, columns, btnW := 82, gap := 8) {
    listW := totalW - btnW - gap
    if (listW < 360)
        listW := 360
    lv := gui.Add("ListView", Format("x{} y{} w{} r{} +Grid", baseX, baseY, listW, rows), columns)
    lv.GetPos(&lx, &ly, &lw, &lh)
    btnX := lx + lw + gap
    btnY := ly
    nextY := ly + lh + 12
    return { lv: lv, btnX: btnX, btnY: btnY, btnW: btnW, nextY: nextY, listW: lw }
}

; ---------- 两列区域 & 安全 Move ----------
UIX_Cols2(rc, leftRatio := 0.58, gutter := 12) {
    lr := Max(0.3, Min(0.75, leftRatio))
    Lw := Round(rc.W * lr) - gutter
    Rw := rc.W - Lw - gutter
    L := { X: rc.X,           Y: rc.Y, W: Lw, H: rc.H }
    R := { X: rc.X + Lw + gutter, Y: rc.Y, W: Rw, H: rc.H }
    return { L: L, R: R }
}
UIX_Move(ctrl, x, y, w := "", h := "") {
    try {
        if (w = "" && h = "")
            ctrl.Move(x, y)
        else if (h = "")
            ctrl.Move(x, y, w)
        else
            ctrl.Move(x, y, w, h)
    }
}
; modules\ui\shell_v2\UIX_Common.ahk
UIX_IndexClamp(v, max) {
    v := Integer(v)
    max := Integer(max)
    return (max <= 0) ? 0 : Min(Max(v, 1), max)
}

; ---------- 创建真正的子面板（WS_CHILD） ----------
UIX_CreateChildPanel(mainHwnd, rect) {
    panel := Gui()
    panel.MarginX := 10
    panel.MarginY := 10
    panel.Opt("-Caption -SysMenu -MinimizeBox -MaximizeBox -Border +Theme")

    DllCall("user32\SetParent", "ptr", panel.Hwnd, "ptr", mainHwnd)

    GWL_STYLE := -16
    WS_CHILD := 0x40000000
    WS_POPUP := 0x80000000
    WS_CLIPCHILDREN := 0x02000000
    WS_CLIPSIBLINGS := 0x04000000

    style := DllCall("user32\GetWindowLongPtr", "ptr", panel.Hwnd, "int", GWL_STYLE, "ptr")
    style := (style & ~WS_POPUP) | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
    DllCall("user32\SetWindowLongPtr", "ptr", panel.Hwnd, "int", GWL_STYLE, "ptr", style)

    SWP_NOZORDER := 0x0004
    SWP_FRAMECHANGED := 0x0020
    SWP_SHOWWINDOW := 0x0040
    DllCall("user32\SetWindowPos", "ptr", panel.Hwnd, "ptr", 0
        , "int", rect.x, "int", rect.y, "int", rect.w, "int", rect.h
        , "uint", SWP_NOZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW)
    return panel
}

; ---------- 安全调用（避免 Method 不存在时报错） ----------
UIX_SafeCall(obj, method, args*) {
    try {
        if (UIX_ObjHasMethod(obj, method)) {
            return obj.%method%(args*)
        }
    } catch {
    }
    return 0
}

; 注意：改名为 UIX_ObjHasMethod，避免与其他模块的 HasMethod 冲突
UIX_ObjHasMethod(obj, name) {
    try {
        return IsObject(obj) && ObjHasOwnProp(obj, name) && IsObject(obj.%name%)
    } catch {
        return false
    }
}
; ---------- 深色导航（ListView 版，带自适应列宽） ----------
UIX_Nav_BuildLV(gui, x, y, w, h, items, theme := 0) {
    if (!theme) {
        try theme := UIX_Theme_Get()
    }
    lv := gui.Add("ListView", Format("x{} y{} w{} h{} -Hdr +Report", x, y, w, h), ["页"])
    try UIX_Theme_SkinListView(lv, theme, true)
    try lv.SetFont("s10")

    ; 列表 EX 样式（整行/双缓冲/去网格）
    LVM_GETEXTENDEDLISTVIEWSTYLE := 0x1037
    LVM_SETEXTENDEDLISTVIEWSTYLE := 0x1036
    LVS_EX_GRIDLINES := 0x0001
    LVS_EX_FULLROWSELECT := 0x0020
    LVS_EX_DOUBLEBUFFER  := 0x10000
    curEx := SendMessage(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0, lv)
    newEx := (curEx | LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER) & ~LVS_EX_GRIDLINES
    if (newEx != curEx) {
        SendMessage(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, newEx, lv)
    }

    map := []
    for _, it in items {
        if (HasProp(it, "type") && it.type = "sep") {
            lv.Add("", "— " it.text " —")
            map.Push("")
        } else {
            txt := HasProp(it, "text") ? it.text : ""
            lv.Add("", "  " txt)
            map.Push(HasProp(it, "key") ? it.key : "")
        }
    }
    ; 首次列宽
    lv.ModifyCol(1, Max(60, w - 8))

    onChanged := 0
    lv.OnEvent("Click", NavChange)
    lv.OnEvent("ItemFocus", NavChange)

    NavChange(*) {
        row := lv.GetNext(0, "Focused")
        if (row < 1 || row > map.Length)
            return
        if (map[row] = "") {
            left := row - 1, right := row + 1, moved := false
            while (left >= 1 || right <= map.Length) {
                if (left >= 1 && map[left] != "") {
                    lv.Modify(left, "Select Focus Vis")
                    moved := true
                    break
                }
                if (right <= map.Length && map[right] != "") {
                    lv.Modify(right, "Select Focus Vis")
                    moved := true
                    break
                }
                left -= 1
                right += 1
            }
            if (!moved)
                return
            row := lv.GetNext(0, "Focused")
        }
        if (onChanged) {
            try onChanged.Call(map[row])
        }
    }

    UIX_NavLV_Reflow(nx, ny, nw, nh, *) {
        lv.Move(nx, ny, nw, nh)
        lv.ModifyCol(1, Max(60, nw - 8))
    }
    UIX_NavLV_SetOnChange(cb, *) {
        onChanged := cb
    }
    UIX_NavLV_SelectKey(key, *) {
        if (key = "")
            return
        for i, k in map {
            if (k = key) {
                lv.Modify(i, "Select Focus Vis")
                if (onChanged) {
                    try onChanged.Call(key)
                }
                return
            }
        }
    }
    UIX_NavLV_GetKey(*) {
        row := lv.GetNext(0, "Focused")
        return (row>=1 && row<=map.Length) ? map[row] : ""
    }

    return { Ctrl: lv
           , Reflow: UIX_NavLV_Reflow
           , SetOnChange: UIX_NavLV_SetOnChange
           , SelectKey: UIX_NavLV_SelectKey
           , GetKey: UIX_NavLV_GetKey }
}