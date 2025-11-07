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
; 记录异常细节到 ui_shellv2.log
UIX_LogExc(e, where := "") {
    try {
        UIX_Log(Format("EXC[{1}] {2} @ {3}:{4} What={5}", where, e.Message, e.File, e.Line, e.What))
    } catch {
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

; 安全调用：函数对象 .Call，避免隐式多传 this
UIX_SafeCall(obj, method, args*) {
    try {
        if (IsObject(obj) && ObjHasOwnProp(obj, method)) {
            fn := obj.%method%
            if (IsObject(fn)) {
                return fn.Call(args*)
            }
        }
    } catch as e {
        UIX_LogExc(e, "SafeCall-Call")
        ; 回退：无参调用（比如页对象 Reflow() 不接参数）
        try {
            if (IsObject(obj) && ObjHasOwnProp(obj, method)) {
                fn2 := obj.%method%
                if (IsObject(fn2)) {
                    return fn2.Call()
                }
            }
        } catch as e2 {
            UIX_LogExc(e2, "SafeCall-Call0")
        }
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
; 深色导航（ListView 版）：去边框 + 行高 + 自适应列宽 + 右侧双遮罩 + 隐藏焦点
UIX_Nav_BuildLV(gui, x, y, w, h, items, theme := 0, rowH := 52) {
    if (!theme) {
        try {
            theme := UIX_Theme_Get()
        } catch {
            theme := { CardBg: 0x1C222B, Text: 0xE6E6E6 }
        }
    }

    ; 导航 LV：隐藏表头 + 报告视图
    lv := gui.Add("ListView", Format("x{} y{} w{} h{} -Hdr +Report", x, y, w, h), ["页"])
    ; 字体与行高匹配
    try {
        if (rowH >= 52) {
            lv.SetFont("s12 Bold")
        } else if (rowH >= 44) {
            lv.SetFont("s11 Bold")
        } else {
            lv.SetFont("s10 Bold")
        }
    }

    ; 去控件边框与凹陷边（白边来源）
    try {
        GWL_STYLE   := -16
        GWL_EXSTYLE := -20
        WS_BORDER       := 0x00800000
        WS_EX_CLIENTEDGE:= 0x00000200
        style := DllCall("user32\GetWindowLongPtr", "ptr", lv.Hwnd, "int", GWL_STYLE,   "ptr")
        exsty := DllCall("user32\GetWindowLongPtr", "ptr", lv.Hwnd, "int", GWL_EXSTYLE, "ptr")
        style := style & ~WS_BORDER
        exsty := exsty & ~WS_EX_CLIENTEDGE
        DllCall("user32\SetWindowLongPtr", "ptr", lv.Hwnd, "int", GWL_STYLE,   "ptr", style)
        DllCall("user32\SetWindowLongPtr", "ptr", lv.Hwnd, "int", GWL_EXSTYLE, "ptr", exsty)
        SWP_NOMOVE:=0x0002, SWP_NOSIZE:=0x0001, SWP_NOZORDER:=0x0004, SWP_FRAMECHANGED:=0x0020, SWP_SHOWWINDOW:=0x0040
        DllCall("user32\SetWindowPos", "ptr", lv.Hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0
            , "uint", SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED|SWP_SHOWWINDOW)
    }

    ; 深色皮肤 + 去网格 + 整行选择 + 双缓冲
    UIX_Theme_SkinListView(lv, theme, true)
    LVM_GETEXTENDEDLISTVIEWSTYLE := 0x1037
    LVM_SETEXTENDEDLISTVIEWSTYLE := 0x1036
    LVS_EX_GRIDLINES := 0x0001
    LVS_EX_FULLROWSELECT := 0x0020
    LVS_EX_DOUBLEBUFFER  := 0x10000
    curEx := SendMessage(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0, lv)
    newEx := (curEx | LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER) & ~LVS_EX_GRIDLINES
    if (newEx != curEx)
        SendMessage(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, newEx, lv)

    ; 隐藏焦点虚线（避免选中边框感）
    try {
        WM_CHANGEUISTATE := 0x0127, UIS_SET := 1, UISF_HIDEFOCUS := 0x0001
        wParam := UIS_SET | (UISF_HIDEFOCUS << 16)
        SendMessage(WM_CHANGEUISTATE, wParam, 0, lv)
    }

    ; 用小图像列表把行高撑到 rowH
    try {
        hIL := DllCall("comctl32\ImageList_Create", "int", 16, "int", rowH, "uint", 0x00000020, "int", 8, "int", 8, "ptr")
        if (hIL) {
            bmi := Buffer(40, 0)
            NumPut("UInt", 40, bmi, 0), NumPut("Int", 1, bmi, 4), NumPut("Int", -rowH, bmi, 8)
            NumPut("UShort", 1, bmi, 12), NumPut("UShort", 32, bmi, 14)
            hdc := DllCall("gdi32\CreateCompatibleDC", "ptr", 0, "ptr"), pBits := 0
            hBmp := DllCall("gdi32\CreateDIBSection", "ptr", hdc, "ptr", bmi.Ptr, "uint", 0, "ptr*", &pBits, "ptr", 0, "uint", 0, "ptr")
            if (hBmp) {
                DllCall("comctl32\ImageList_Add", "ptr", hIL, "ptr", hBmp, "ptr", 0)
                DllCall("gdi32\DeleteObject", "ptr", hBmp)
            }
            if (hdc)
                DllCall("gdi32\DeleteDC", "ptr", hdc)
            LVM_SETIMAGELIST := 0x1003, LVSIL_SMALL := 1
            SendMessage(LVM_SETIMAGELIST, LVSIL_SMALL, hIL, lv)
        }
    }

    ; 数据
    map := []
    for _, it in items {
        if (HasProp(it,"type") && it.type="sep") {
            lv.Add("", "— " it.text " —"), map.Push("")
        } else {
            txt := HasProp(it,"text") ? it.text : ""
            lv.Add("", "  " txt), map.Push(HasProp(it,"key") ? it.key : "")
        }
    }

    ; 右侧双遮罩：彻底覆盖系统“残线”
    ; 1) 紧贴 LV 客户区右缘 3px（内遮罩）
    maskInner := gui.Add("Text", Format("x{} y{} w3 h{}", x + w - 3, y, h), "")
    ; 2) 再在 LV 右缘外侧压 1px（外遮罩，紧贴卡片右内壁）
    maskEdge := gui.Add("Text", Format("x{} y{} w1 h{}", x + w, y, h), "")
    try {
        maskInner.BackColor := Format("0x{:06X}", theme.CardBg)
        maskEdge.BackColor  := Format("0x{:06X}", theme.CardBg)
        ; 置顶（同父窗口内）
        HWND_TOP := 0
        SWP_NOSIZE:=0x0001, SWP_NOMOVE:=0x0002, SWP_NOZORDER:=0x0004, SWP_SHOWWINDOW:=0x0040
        DllCall("user32\SetWindowPos", "ptr", maskInner.Hwnd, "ptr", HWND_TOP, "int", 0, "int", 0, "int", 0, "int", 0, "uint", SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW)
        DllCall("user32\SetWindowPos", "ptr", maskEdge.Hwnd,  "ptr", HWND_TOP, "int", 0, "int", 0, "int", 0, "int", 0, "uint", SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW)
    }

    ; 列宽 = 可视宽 - 3（与遮罩对齐）
    lv.ModifyCol(1, Max(160, w - 3))

    ; 事件/接口
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
                    lv.Modify(left, "Select Focus Vis"), moved := true
                    break
                }
                if (right <= map.Length && map[right] != "") {
                    lv.Modify(right, "Select Focus Vis"), moved := true
                    break
                }
                left -= 1, right += 1
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
        ; 遮罩随尺寸移动
        maskInner.Move(nx + nw - 3, ny, 3, nh)
        maskEdge.Move(nx + nw,     ny, 1, nh)
        lv.ModifyCol(1, Max(160, nw - 3))
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
           , MaskInner: maskInner
           , MaskEdge:  maskEdge
           , Reflow: UIX_NavLV_Reflow
           , SetOnChange: UIX_NavLV_SetOnChange
           , SelectKey: UIX_NavLV_SelectKey
           , GetKey: UIX_NavLV_GetKey }
}