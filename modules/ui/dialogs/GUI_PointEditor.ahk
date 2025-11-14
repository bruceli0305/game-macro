; GUI_PointEditor.ahk - 取色点位编辑对话框
; PointEditor_Open(pointObj, idx, onSavedCallback)
; - pointObj: {} 新增 或 现有点位对象
; - idx: 0 表示新增；>0 表示编辑该索引
; - onSavedCallback: (newPoint, idx) => void
PointEditor_Open(point, idx := 0, onSaved := 0) {
    isNew := (idx = 0)

    defaults := Map("Name", "", "X", 0, "Y", 0, "Color", "0x000000", "Tol", 10)
    if !IsObject(point)
        point := {}
    for k, v in defaults
        if !HasProp(point, k)
            point.%k% := v

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增点位" : "编辑点位")
    dlg.MarginX := 14, dlg.MarginY := 12
    dlg.SetFont("s10", "Segoe UI")

    dlg.Add("Text", "w70 Right", "名称：")
    tbName := dlg.Add("Edit", "x+10 w336", point.Name)

    dlg.Add("Text", "xm w70 Right", "坐标X：")
    tbX := dlg.Add("Edit", "x+10 w120 Number", point.X)
    dlg.Add("Text", "x+16 w70 Right", "坐标Y：")
    tbY := dlg.Add("Edit", "x+10 w120 Number", point.Y)
    btnPick := dlg.Add("Button", "x+16 w110 h28", "拾取像素")

    dlg.Add("Text", "xm w70 Right", "颜色：")
    tbColor := dlg.Add("Edit", "x+10 w120", point.Color)
    dlg.Add("Text", "x+16 w70 Right", "容差：")
    tbTol := dlg.Add("Edit", "x+10 w120 Number", point.Tol)

    btnSave := dlg.Add("Button", "xm w96 h30", "保存")
    btnCancel := dlg.Add("Button", "x+8 w96 h30", "取消")

    btnPick.OnEvent("Click", OnPick)
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show()

    OnPick(*) {
        global App
        offY := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverOffsetY : 0
        dwell := App["ProfileData"].PickHoverEnabled ? App["ProfileData"].PickHoverDwellMs : 0
        res := Pixel_PickPixel(dlg, offY, dwell)
        if res {
            tbX.Value := res.X
            tbY.Value := res.Y
            tbColor.Value := Pixel_ColorToHex(res.Color)
        }
    }

    OnSave(*) {
        name := Trim(tbName.Value)
        ; 数值做容错，空值给默认
        x := (tbX.Value != "") ? Integer(tbX.Value) : 0
        y := (tbY.Value != "") ? Integer(tbY.Value) : 0
        col := Trim(tbColor.Value)
        tol := (tbTol.Value != "") ? Integer(tbTol.Value) : 10

        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        if (col = "") {
            MsgBox "请设置颜色"
            return
        }

        col := Pixel_ColorToHex(Pixel_HexToInt(col))
        newPoint := { Name: name, X: x, Y: y, Color: col, Tol: tol }

        if onSaved
            onSaved(newPoint, idx)

        dlg.Destroy()
        UI_ActivateMain()                 ; 新增：回到主窗
        Notify(isNew ? "已新增点位" : "已保存点位")
    }
}
