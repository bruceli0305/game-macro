#Requires AutoHotkey v2

; 点位面板：复用现有增删改查与测试、保存逻辑
Page_Points_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.PointLV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        , [T("col.point.id","ID"), T("col.point.name","名称"), T("col.point.x","X")
        , T("col.point.y","Y"), T("col.point.color","颜色"), T("col.point.tol","容差")])
    page.Controls.Push(UI.PointLV)

    UI.BtnAddPoint  := UI.Main.Add("Button", Format("x{} y{} w96 h28", rc.X, rc.Y + rc.H - 30), T("btn.addPoint","新增点位"))
    UI.BtnEditPoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.editPoint","编辑点位"))
    UI.BtnDelPoint  := UI.Main.Add("Button", "x+8 w96 h28", T("btn.delPoint","删除点位"))
    UI.BtnTestPoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.testPoint","测试点位"))
    UI.BtnSavePoint := UI.Main.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    for c in [UI.BtnAddPoint,UI.BtnEditPoint,UI.BtnDelPoint,UI.BtnTestPoint,UI.BtnSavePoint]
        page.Controls.Push(c)

    UI.PointLV.OnEvent("DoubleClick", (*) => UI_Page_Config_EditSelectedPoint())
    UI.BtnAddPoint.OnEvent("Click", (*) => UI_Page_Config_AddPoint())
    UI.BtnEditPoint.OnEvent("Click", (*) => UI_Page_Config_EditSelectedPoint())
    UI.BtnDelPoint.OnEvent("Click", (*) => UI_Page_Config_DeleteSelectedPoint())
    UI.BtnTestPoint.OnEvent("Click", (*) => UI_Page_Config_TestSelectedPoint())
    UI.BtnSavePoint.OnEvent("Click", (*) => UI_Page_Config_SaveProfile())

    UI_Page_Config_RefreshPointList()
}

Page_Points_Layout(rc) {
    try {
        UI.PointLV.Move(rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        y := rc.Y + rc.H - 30
        UI.BtnAddPoint.Move(rc.X, y)
        UI.BtnEditPoint.Move(, y)
        UI.BtnDelPoint.Move(, y)
        UI.BtnTestPoint.Move(, y)
        UI.BtnSavePoint.Move(, y)
    }
}