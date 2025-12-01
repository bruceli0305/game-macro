;modules\engines\Pixel.ahk - 颜色/拾色工具 + 帧级取色缓存 + ROI 快照加速

Pixel_ColorToHex(colorInt) {
    return Format("0x{:06X}", colorInt & 0xFFFFFF)
}

Pixel_HexToInt(hexStr) {
    s := Trim(hexStr)
    if (SubStr(s, 1, 1) = "#")
        s := "0x" SubStr(s, 2)
    else if (SubStr(s, 1, 2) != "0x")
        s := "0x" s
    try {
        return Integer(s)
    } catch {
        return 0
    }
}

Pixel_ColorMatch(curInt, targetInt, tol := 10) {
    r1 := (curInt >> 16) & 0xFF, g1 := (curInt >> 8) & 0xFF, b1 := curInt & 0xFF
    r2 := (targetInt >> 16) & 0xFF, g2 := (targetInt >> 8) & 0xFF, b2 := targetInt & 0xFF
    return Abs(r1 - r2) <= tol && Abs(g1 - g2) <= tol && Abs(b1 - b2) <= tol
}

; ---------------- 帧级取色缓存 ----------------
global gPxFrame := { id: 0, cache: Map() }

Pixel_FrameBegin() {
    global gPxFrame
    try Dup_FrameBegin()          ; 新增：统计与日志（安全调用）
    gPxFrame.id += 1
    gPxFrame.cache := Map()
}

; 优先从 DXGI Dup -> ROI -> 系统取色
Pixel_FrameGet(x, y) {
    global gPxFrame
    key := x "|" y
    if gPxFrame.cache.Has(key)
        return gPxFrame.cache[key]

    ; 1) DXGI Dup 优先（仅当坐标落在当前输出）
    try {
        cdx := Dup_GetPixelAtScreen(x, y)    ; -1=不在输出或未就绪；0..=有效颜色
        if (cdx != -1) {
            gPxFrame.cache[key] := cdx
            try Dup_NotifyPath("DX")         ; 新增
            return cdx
        }
    } catch {
        ; 忽略异常，继续回退路径
    }

    ; 2) ROI 缓存
    c := Pixel_ROI_GetIfInside(x, y)  ; -1 = 不在 ROI
    if (c != -1) {
        gPxFrame.cache[key] := c
        try Dup_NotifyPath("ROI")            ; 新增
        return c
    }

    ; 3) GDI 取色
    c := PixelGetColor(x, y, "RGB")
    gPxFrame.cache[key] := c
    try Dup_NotifyPath("GDI")                ; 新增
    return c
}

; ---------------- ROI 快照（单矩形） ----------------
; 说明：
; - 每帧 Pixel_ROI_BeginSnapshot() 用 BitBlt 把 ROI 矩形拷到内存位图
; - Pixel_ROI_GetIfInside(x,y) 直接从内存位图读 BGRA 并转换为 RGB
; - 提供自动计算 ROI：基于 Skills（可选包含 Points）的包围盒 + padding

global gROI := { enabled: false, rects: [] }

Pixel_ROI_Enable(flag := true) {
    global gROI
    gROI.enabled := !!flag
    return gROI.enabled
}

Pixel_ROI_Clear() {
    global gROI
    if IsObject(gROI) && HasProp(gROI, "rects") {
        for _, r in gROI.rects {
            try {
                if (r.hDC && r.hOld)
                    DllCall("gdi32\SelectObject", "ptr", r.hDC, "ptr", r.hOld, "ptr")
                if (r.hBmp)
                    DllCall("gdi32\DeleteObject", "ptr", r.hBmp)
                if (r.hDC)
                    DllCall("gdi32\DeleteDC", "ptr", r.hDC)
            }
        }
        gROI.rects := []
    }
}

Pixel_ROI_Dispose() {
    Pixel_ROI_Clear()
    global gROI
    gROI.enabled := false
}

; 内部：添加一个 ROI 矩形并创建 DIB 缓存
Pixel_ROI_AddRect(l, t, w, h) {
    global gROI
    if (w <= 0 || h <= 0)
        return false

    hDC := DllCall("gdi32\CreateCompatibleDC", "ptr", 0, "ptr")
    if !hDC
        return false

    bmi := Buffer(40, 0) ; BITMAPINFOHEADER
    NumPut("UInt", 40, bmi, 0)           ; biSize
    NumPut("Int", w, bmi, 4)           ; biWidth
    NumPut("Int", -h, bmi, 8)           ; biHeight (负数=top-down)
    NumPut("UShort", 1, bmi, 12)         ; biPlanes
    NumPut("UShort", 32, bmi, 14)        ; biBitCount
    NumPut("UInt", 0, bmi, 16)           ; biCompression = BI_RGB
    ; 其余默认 0

    pBits := 0
    hBmp := DllCall("gdi32\CreateDIBSection"
        , "ptr", hDC, "ptr", bmi.Ptr, "uint", 0   ; DIB_RGB_COLORS
        , "ptr*", &pBits, "ptr", 0, "uint", 0, "ptr")
    if (!hBmp || !pBits) {
        DllCall("gdi32\DeleteDC", "ptr", hDC)
        return false
    }

    hOld := DllCall("gdi32\SelectObject", "ptr", hDC, "ptr", hBmp, "ptr")
    rect := {
        L: l, T: t, W: w, H: h, R: (l + w - 1), B: (t + h - 1), hDC: hDC, hBmp: hBmp, hOld: hOld, pBits: pBits, stride: (
            w * 4)
    }
    gROI.rects.Push(rect)
    return true
}

Pixel_ROI_SetRect(l, t, w, h) {
    Pixel_ROI_Clear()
    return Pixel_ROI_AddRect(l, t, w, h)
}

; 自动设置 ROI：基于 Skills（可选包含 Points）的包围盒 + padding
; 超过 maxArea 或不足 minCount 个点时自动禁用
Pixel_ROI_SetAutoFromProfile(prof, pad := 8, includePoints := false, maxArea := 1000000, minCount := 3) {
    try {
        pts := []

        ; 收集技能坐标
        if HasProp(prof, "Skills") && IsObject(prof.Skills) {
            for _, s in prof.Skills {
                ; 统一转为整数，避免类型干扰
                x := Integer(s.X)
                y := Integer(s.Y)
                pts.Push([x, y])
            }
        }

        ; 可选：包含“取色点位”
        if includePoints && HasProp(prof, "Points") && IsObject(prof.Points) {
            for _, p in prof.Points {
                x := Integer(p.X)
                y := Integer(p.Y)
                pts.Push([x, y])
            }
        }

        ; 点太少则禁用 ROI
        if (pts.Length < minCount) {
            Pixel_ROI_Enable(false)
            Pixel_ROI_Clear()
            return false
        }

        ; 用第一个点初始化包围盒
        minX := pts[1][1]
        minY := pts[1][2]
        maxX := minX
        maxY := minY

        ; 扫描其余点
        if (pts.Length >= 2) {
            loop pts.Length - 1 {
                i := A_Index + 1
                x := pts[i][1]
                y := pts[i][2]
                if (x < minX)
                    minX := x
                if (y < minY)
                    minY := y
                if (x > maxX)
                    maxX := x
                if (y > maxY)
                    maxY := y
            }
        }

        ; padding + 屏幕边界夹取
        l := Max(0, minX - pad)
        t := Max(0, minY - pad)
        r := Min(A_ScreenWidth - 1, maxX + pad)
        b := Min(A_ScreenHeight - 1, maxY + pad)
        w := r - l + 1
        h := b - t + 1

        ; 面积过大或异常 → 禁用 ROI
        if (w <= 0 || h <= 0 || w * h > maxArea) {
            Pixel_ROI_Enable(false)
            Pixel_ROI_Clear()
            return false
        }

        ; 建立 ROI
        Pixel_ROI_SetRect(l, t, w, h)
        Pixel_ROI_Enable(true)
        try {
            Logger_Info("ROI", "SetAuto OK", Map("l", l, "t", t, "w", w, "h", h))
        } catch {
        }
        return true
    } catch {
        Pixel_ROI_Enable(false)
        Pixel_ROI_Clear()
        Logger_Warn("ROI", "SetAuto FAIL", Map())
        return false
    }
}

; 每帧刷新 ROI 图像（BitBlt）
Pixel_ROI_BeginSnapshot() {
    global gROI
    if !gROI.enabled
        return
    if (gROI.rects.Length = 0)
        return
    hScr := DllCall("user32\GetDC", "ptr", 0, "ptr")
    if !hScr
        return
    for _, r in gROI.rects {
        DllCall("gdi32\BitBlt"
            , "ptr", r.hDC, "int", 0, "int", 0, "int", r.W, "int", r.H
            , "ptr", hScr, "int", r.L, "int", r.T, "uint", 0x00CC0020) ; SRCCOPY
    }
    DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hScr)
}

; 点是否在 ROI 内？在则从 DIB 读取 RGB；否则返回 -1
Pixel_ROI_GetIfInside(x, y) {
    global gROI
    if !gROI.enabled
        return -1
    for _, r in gROI.rects {
        if (x >= r.L && x <= r.R && y >= r.T && y <= r.B) {
            dx := x - r.L
            dy := y - r.T
            off := dy * r.stride + dx * 4
            px := NumGet(r.pBits, off, "UInt")        ; BGRA
            b := px & 0xFF
            g := (px >> 8) & 0xFF
            r8 := (px >> 16) & 0xFF
            return (r8 << 16) | (g << 8) | b          ; RGB
        }
    }
    return -1
}
; ------------------------------------------------

; 支持避让参数与自定义确认键：Pixel_PickPixel(parentGui?, offsetY?, dwellMs?, confirmKey?)
Pixel_PickPixel(parentGui := 0, offsetY := 0, dwellMs := 0, confirmKey := "") {
    global App
    if (confirmKey = "") {
        try {
            if IsObject(App) && App.Has("ProfileData") {           ; Map 检查用 Has
                prof := App["ProfileData"]
                if IsObject(prof) && HasProp(prof, "PickConfirmKey") && prof.PickConfirmKey != ""
                    confirmKey := prof.PickConfirmKey              ; 对象用 HasProp
            }
        }
        ; 兜底
        if (confirmKey = "")
            confirmKey := "LButton"
    }
    if parentGui
        parentGui.Hide()
    ToolTip "移动鼠标到目标像素，按 [" confirmKey "] 确认，Esc 取消。"
        . (offsetY || dwellMs ? "`n提示：确认时将临时上移" offsetY "px，等待" dwellMs "ms后再取色" : "")
    local x, y, color
    while true {
        if GetKeyState("Esc", "P") {
            ToolTip()
            if parentGui
                parentGui.Show()
            return 0
        }
        if GetKeyState(confirmKey, "P") {
            Sleep 120
            MouseGetPos &x, &y
            color := Pixel_GetColorWithMouseAway(x, y, offsetY, dwellMs)
            ToolTip()
            if parentGui
                parentGui.Show()
            return { X: x, Y: y, Color: color }
        }
        MouseGetPos &mx, &my
        c := PixelGetColor(mx, my, "RGB")
        ToolTip "X:" mx " Y:" my "`n颜色: " Pixel_ColorToHex(c)
        . "`n确认键: " confirmKey " / Esc 取消"
        . (offsetY || dwellMs ? "`n将上移避让后再取色" : "")
        Sleep 25
    }
}

; 将鼠标临时上移 offsetY 像素，在原坐标 (x,y) 取色后再把鼠标移回
Pixel_GetColorWithMouseAway(x, y, offsetY := 0, dwellMs := 0) {
    if (offsetY = 0 && dwellMs = 0)
        return PixelGetColor(x, y, "RGB")

    MouseGetPos &cx, &cy
    destX := cx
    destY := cy + offsetY
    maxY := A_ScreenHeight - 1
    if destY < 0
        destY := 0
    else if destY > maxY
        destY := maxY

    MouseMove destX, destY, 0
    if (dwellMs > 0)
        Sleep dwellMs
    color := PixelGetColor(x, y, "RGB")
    MouseMove cx, cy, 0
    return color
}
