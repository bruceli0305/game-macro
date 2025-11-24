#Requires AutoHotkey v2
; RuleEditor_Dialog.ahk
; 规则编辑器主对话框（字段 + 条件/动作容器）
; 导出：RuleEditor_Open(rule, idx := 0, onSaved := 0)

#Include "Rules_UI_Common.ahk"
#Include "Rules_Editor_Lists.ahk"

RuleEditor_Open(rule, idx := 0, onSaved := 0) {
    global App
    isNew := (idx = 0)

    if !IsObject(rule) {
        rule := {}
    }
    defaults := Map("Name", "新规则", "Enabled", 1, "Logic", "AND", "CooldownMs", 500, "Priority", 1, "ActionGapMs", 60, "ThreadId", 1)
    for k, v in defaults {
        if !HasProp(rule, k) {
            rule.%k% := v
        }
    }
    if !HasProp(rule, "Conditions") {
        rule.Conditions := []
    }
    if !HasProp(rule, "Actions") {
        rule.Actions := []
    }

    dlg := Gui("+Owner" UI.Main.Hwnd, isNew ? "新增规则" : "编辑规则")
    dlg.MarginX := 12
    dlg.MarginY := 10
    dlg.SetFont("s10", "Segoe UI")

    ; 第1行：名称 + 启用
    dlg.Add("Text", "w130 Right", "名称：")
    tbName := dlg.Add("Edit", "x+6 w200", rule.Name)
    cbEn := dlg.Add("CheckBox", "x+12 w80", "启用")
    try cbEn.Value := rule.Enabled ? 1 : 0

    ; 第2行：逻辑 + 冷却 + 优先级
    dlg.Add("Text", "xm y+16 w130 Right", "逻辑：")
    ddLogic := dlg.Add("DropDownList", "x+6 w200", ["AND", "OR"])
    try ddLogic.Value := (StrUpper(OM_Get(rule, "Logic", "AND")) = "OR") ? 2 : 1

    dlg.Add("Text", "x+20 w130 Right", "冷却(ms)：")
    edCd := dlg.Add("Edit", "x+6 w200 Number", OM_Get(rule, "CooldownMs", 500))

    dlg.Add("Text", "x+20 w130 Right", "优先级：")
    edPrio := dlg.Add("Edit", "x+6 w200 Number", OM_Get(rule, "Priority", 1))

    ; 第3行：间隔 + 会话超时 + 中止冷却
    dlg.Add("Text", "xm y+10 w130 Right", "间隔(ms)：")
    edGap := dlg.Add("Edit", "x+6 w200 Number", OM_Get(rule, "ActionGapMs", 60))

    dlg.Add("Text", "x+20 w130 Right", "会话超时(ms)：")
    edSessTO := dlg.Add("Edit", "x+6 w200 Number", OM_Get(rule, "SessionTimeoutMs", 0))

    dlg.Add("Text", "x+20 w130 Right", "中止冷却(ms)：")
    edAbortCd := dlg.Add("Edit", "x+6 w200 Number", OM_Get(rule, "AbortCooldownMs", 0))

    ; 第4行：线程
    dlg.Add("Text", "xm y+10 w130 Right", "线程：")
    ddThread := dlg.Add("DropDownList", "x+6 w200")
    thrNames := []
    try {
        if (HasProp(App["ProfileData"], "Threads") && IsObject(App["ProfileData"].Threads)) {
            for _, t in App["ProfileData"].Threads {
                try thrNames.Push(t.Name)
            }
        }
    }
    if (thrNames.Length > 0) {
        try ddThread.Add(thrNames)
    } else {
        try ddThread.Add(["默认线程"])
    }
    curTid := OM_Get(rule, "ThreadId", 1)
    try {
        if (curTid >= 1 && curTid <= Max(thrNames.Length, 1)) {
            ddThread.Value := curTid
        } else {
            ddThread.Value := 1
        }
    }

    ; 条件列表
    dlg.Add("Text", "xm y+10", "条件：")
    lvC := dlg.Add("ListView", "xm w760 r7 +Grid", ["类型", "引用", "操作", "使用引用坐标", "X", "Y"])
    btnCAdd := dlg.Add("Button", "xm w90", "新增条件")
    btnCEdit := dlg.Add("Button", "x+8 w90", "编辑条件")
    btnCDel := dlg.Add("Button", "x+8 w90", "删除条件")

    ; 动作列表
    dlg.Add("Text", "xm y+10", "动作（释放技能步骤）：")
    lvA := dlg.Add("ListView", "xm w760 r6 +Grid", ["序", "技能名", "延时(ms)", "按住(ms)", "需就绪", "验证", "重试"])
    btnAAdd := dlg.Add("Button", "xm w110", "新增动作")
    btnAEdit := dlg.Add("Button", "x+8 w110", "编辑动作")
    btnADel := dlg.Add("Button", "x+8 w110", "删除动作")
    btnAUp := dlg.Add("Button", "x+20 w90", "上移")
    btnADn := dlg.Add("Button", "x+8 w90", "下移")

    ; 保存/取消
    btnSave := dlg.Add("Button", "xm y+10 w100", "保存")
    btnCancel := dlg.Add("Button", "x+8 w100", "取消")

    ; 上下文
    ctx := { dlg: dlg
           , rule: rule
           , idx: idx
           , onSaved: onSaved
           , ctrls: Map("lvC", lvC, "btnCAdd", btnCAdd, "btnCEdit", btnCEdit, "btnCDel", btnCDel
                      , "lvA", lvA, "btnAAdd", btnAAdd, "btnAEdit", btnAEdit, "btnADel", btnADel, "btnAUp", btnAUp, "btnADn", btnADn) }

    ; 初始化列表逻辑
    RE_Lists_Init(ctx)

    ; 事件：保存/取消
    btnSave.OnEvent("Click", SaveRule)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    SaveRule(*) {
        name := ""
        try name := Trim(tbName.Value)
        if (name = "") {
            MsgBox "名称不可为空"
            return
        }
        try rule.Name := name
        try rule.Enabled := (cbEn.Value ? 1 : 0)
        try rule.Logic := ((ddLogic.Value = 2) ? "OR" : "AND")
        try rule.CooldownMs := (edCd.Value != "") ? Integer(edCd.Value) : 500
        try rule.Priority := (edPrio.Value != "") ? Integer(edPrio.Value) : 1
        try rule.ActionGapMs := (edGap.Value != "") ? Integer(edGap.Value) : 60
        try rule.ThreadId := (ddThread.Value ? ddThread.Value : 1)
        try rule.SessionTimeoutMs := (edSessTO.Value != "") ? Integer(edSessTO.Value) : 0
        try rule.AbortCooldownMs := (edAbortCd.Value != "") ? Integer(edAbortCd.Value) : 0

        if (onSaved) {
            try onSaved(rule, idx)
        }
        try dlg.Destroy()
        Notify(isNew ? "已新增规则" : "已保存规则")
    }
}