; Pixel.ahk - 颜色/拾色工具 + 帧级取色缓存

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

; ---------- 帧级取色缓存 ----------
global gPxFrame := { id: 0, cache: Map() }

Pixel_FrameBegin() {
    global gPxFrame
    gPxFrame.id += 1
    gPxFrame.cache := Map()
}

Pixel_FrameGet(x, y) {
    global gPxFrame
    key := x "|" y
    if gPxFrame.cache.Has(key)
        return gPxFrame.cache[key]
    c := PixelGetColor(x, y, "RGB")
    gPxFrame.cache[key] := c
    return c
}
; -----------------------------------

; 支持避让参数的拾色对话：Pixel_PickPixel(parentGui?, offsetY?, dwellMs?)
Pixel_PickPixel(parentGui := 0, offsetY := 0, dwellMs := 0) {
    if parentGui
        parentGui.Hide()
    ToolTip "移动鼠标到目标像素，左键确认，Esc取消。"
        . (offsetY || dwellMs ? "`n提示：确认时将临时上移" offsetY "px，等待" dwellMs "ms后再取色" : "")
    local x, y, color
    while true {
        if GetKeyState("Esc", "P") {
            ToolTip()
            if parentGui
                parentGui.Show()
            return 0
        }
        if GetKeyState("LButton", "P") {
            Sleep 120
            MouseGetPos &x, &y
            color := Pixel_GetColorWithMouseAway(x, y, offsetY, dwellMs)
            ToolTip()
            if parentGui
                parentGui.Show()
            return {X: x, Y: y, Color: color}
        }
        MouseGetPos &mx, &my
        c := PixelGetColor(mx, my, "RGB")
        ToolTip "X:" mx " Y:" my "`n颜色: " Pixel_ColorToHex(c)
            . "`n左键确认 / Esc取消"
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