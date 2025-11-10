#Requires AutoHotkey v2
; UI_Page_Skills.ahk
; 技能面板：复用现有增删改查与测试、保存逻辑
Page_Skills_Build(page) {
    global UI
    rc := UI_GetPageRect()
    page.Controls := []

    UI.SkillLV := UI.Main.Add("ListView", Format("x{} y{} w{} h{}", rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        , [T("col.skill.id","ID"), T("col.skill.name","技能名"), T("col.skill.key","键位")
        , T("col.skill.x","X"), T("col.skill.y","Y"), T("col.skill.color","颜色"), T("col.skill.tol","容差")])
    page.Controls.Push(UI.SkillLV)

    UI.BtnAddSkill  := UI.Main.Add("Button", Format("x{} y{} w96 h28", rc.X, rc.Y + rc.H - 30), T("btn.addSkill","新增技能"))
    UI.BtnEditSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.editSkill","编辑技能"))
    UI.BtnDelSkill  := UI.Main.Add("Button", "x+8 w96 h28", T("btn.delSkill","删除技能"))
    UI.BtnTestSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.testSkill","测试检测"))
    UI.BtnSaveSkill := UI.Main.Add("Button", "x+8 w96 h28", T("btn.save","保存配置"))
    for c in [UI.BtnAddSkill,UI.BtnEditSkill,UI.BtnDelSkill,UI.BtnTestSkill,UI.BtnSaveSkill]
        page.Controls.Push(c)

    UI.SkillLV.OnEvent("DoubleClick", (*) => UI_Page_Config_EditSelectedSkill())
    UI.BtnAddSkill.OnEvent("Click", (*) => UI_Page_Config_AddSkill())
    UI.BtnEditSkill.OnEvent("Click", (*) => UI_Page_Config_EditSelectedSkill())
    UI.BtnDelSkill.OnEvent("Click", (*) => UI_Page_Config_DeleteSelectedSkill())
    UI.BtnTestSkill.OnEvent("Click", (*) => UI_Page_Config_TestSelectedSkill())
    UI.BtnSaveSkill.OnEvent("Click", (*) => UI_Page_Config_SaveProfile())

    ; 首次填充
    UI_Page_Config_RefreshSkillList()
}

Page_Skills_Layout(rc) {
    try {
        UI.SkillLV.Move(rc.X, rc.Y, rc.W, rc.H - 40 - 8)
        y := rc.Y + rc.H - 30
        UI.BtnAddSkill.Move(rc.X, y)
        UI.BtnEditSkill.Move(, y)
        UI.BtnDelSkill.Move(, y)
        UI.BtnTestSkill.Move(, y)
        UI.BtnSaveSkill.Move(, y)
    }
}