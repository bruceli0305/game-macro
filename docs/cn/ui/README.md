# UI 框架文档

UI 框架为 Game Macro 应用程序提供用户界面组件，采用模块化和可扩展设计。

[English Version](../../ui/README.md) | [中文版本](README.md)

## 概述

UI 系统围绕主外壳构建，具有导航树和动态页面加载功能。支持：
- 多语言界面
- 响应式布局
- 动态页面切换
- 模态对话框
- 实时更新

## 关键组件

### UI_Shell.ahk
主应用程序外壳，包含导航树和页面管理。

#### 关键函数
- `UI_ShowMain()` - 显示主应用程序窗口
- `UI_OnNavChange()` - 处理导航树选择
- `UI_OnResize_LeftNav()` - 处理窗口调整大小事件
- `UI_SwitchPage(key)` - 在不同页面间切换

#### 导航结构
```ahk
rootProfile := UI.Nav.Add("概览与配置")
rootData    := UI.Nav.Add("数据与检测")
rootAuto    := UI.Nav.Add("自动化")
rootAdv     := UI.Nav.Add("高级功能")
rootTools   := UI.Nav.Add("工具")
rootSet     := UI.Nav.Add("设置")
```

### UI_Layout.ahk
布局管理和响应式设计。

### UI_Framework.ahk
基础 UI 组件和框架工具。

## 页面系统

UI 使用基于页面的架构，每个功能区域都作为单独的页面实现。

### 页面注册
```ahk
UI_RegisterPage("profile", "概览与配置", Page_Profile_Build, Page_Profile_Layout, Page_Profile_OnEnter)
UI_RegisterPage("skills", "技能", Page_Skills_Build, Page_Skills_Layout)
UI_RegisterPage("rules", "循环规则", Page_Rules_Build, Page_Rules_Layout, Page_Rules_OnEnter)
```

### 可用页面

#### 配置文件页面
- 概览和配置管理
- 配置文件选择和创建
- 基础设置

#### 技能页面
- 技能配置和管理
- 热键分配
- 像素检测设置

#### 规则页面
- 规则创建和编辑
- 条件配置
- 动作分配

#### 高级页面
- 循环配置
- 诊断工具
- 日志查看器
- 施法调试

## 对话框系统

UI 包含各种模态对话框用于特定任务：

### 技能编辑器 (GUI_SkillEditor.ahk)
- 编辑技能属性
- 配置像素检测
- 设置热键和冷却时间

### 点编辑器 (GUI_PointEditor.ahk)
- 管理像素检测点
- 配置颜色容差
- 设置采样参数

### 规则编辑器 (GUI_RuleEditor.ahk)
- 创建和编辑自动化规则
- 配置条件和动作
- 设置优先级和时序

### 增益效果编辑器 (GUI_BuffEditor.ahk)
- 配置增益效果计时器
- 设置持续时间和效果
- 管理增益效果跟踪

### 施法调试 (GUI_CastDebug.ahk)
- 实时技能施法调试
- 施法条监控
- 性能分析

## 布局系统

UI 使用响应式布局系统，适应窗口大小变化。

### 主布局结构
```ahk
; 左侧导航树
UI.Nav := UI.Main.Add("TreeView", "xm ym w220 h620 +Lines +Buttons")

; 右侧内容区域
UI.Content := UI.Main.Add("GroupBox", "x+10 yp w600 h620", "Content")
```

### 响应式行为
- 导航树保持固定宽度
- 内容区域扩展以填充可用空间
- 控件根据可用空间重新定位
- 字体大小调整以提高可读性

## 国际化

UI 通过语言系统支持多种语言：

### 语言集成
```ahk
; 初始化语言系统
Lang_Init(AppConfig_Get("Language", "zh-CN"))

; 使用翻译文本
UI.Main.Title := T("app.title", "Game Macro")
```

### 语言文件
- `Languages/zh-CN.ini` - 中文翻译
- `Languages/en-US.ini` - 英文翻译

## 事件处理

UI 使用 AutoHotkey 的事件系统处理用户交互。

### 事件类型
- **点击事件**：按钮点击、树选择
- **变更事件**：输入字段变更
- **调整大小事件**：窗口大小变化
- **关闭事件**：应用程序终止

### 事件注册
```ahk
; 按钮点击事件
myButton.OnEvent("Click", MyButton_Click)

; 树视图选择
UI.Nav.OnEvent("Click", UI_OnNavChange)

; 窗口关闭
UI.Main.OnEvent("Close", UI_OnMainClose)
```

## 使用示例

### 创建简单页面
```ahk
Page_MyPage_Build() {
    global UI
    
    ; 创建控件
    UI.MyPage.Label := UI.Content.Add("Text", "xm ym", "我的页面标题")
    UI.MyPage.Button := UI.Content.Add("Button", "x+10", "点击我")
    
    ; 注册事件
    UI.MyPage.Button.OnEvent("Click", MyPage_ButtonClick)
}

Page_MyPage_Layout() {
    global UI
    
    ; 定位控件
    UI.MyPage.Label.Move(10, 10, 200, 20)
    UI.MyPage.Button.Move(220, 10, 100, 25)
}

MyPage_ButtonClick(*) {
    MsgBox "按钮被点击了！"
}
```

### 处理导航
```ahk
UI_OnNavChange(*) {
    global UI, UI_NavMap
    
    sel := UI.Nav.GetSelection()
    if (!sel || !UI_NavMap.Has(sel)) {
        return
    }
    
    key := UI_NavMap[sel]
    UI_SwitchPage(key)
}
```

### 模态对话框使用
```ahk
; 打开技能编辑器
GUI_SkillEditor_Show(skillData) {
    ; 创建对话框
    editor := GUI_SkillEditor_Create()
    
    ; 填充数据
    GUI_SkillEditor_LoadData(editor, skillData)
    
    ; 显示对话框
    editor.Show("Modal")
    
    ; 等待用户操作
    return GUI_SkillEditor_GetResult(editor)
}
```

### 响应式布局
```ahk
UI_OnResize_LeftNav(*) {
    global UI
    
    ; 获取窗口大小
    winWidth := UI.Main.Pos.W
    winHeight := UI.Main.Pos.H
    
    ; 调整导航树大小
    UI.Nav.Move(10, 10, 220, winHeight - 50)
    
    ; 调整内容区域大小
    UI.Content.Move(240, 10, winWidth - 260, winHeight - 50)
    
    ; 重新布局当前页面
    if (UI.CurrentPage) {
        UI.CurrentPage.Layout()
    }
}
```

## 配置集成

### UI 配置
UI 设置存储在配置文件中：

```ahk
uiConfig := {
    Language: "zh-CN",
    Theme: "dark",
    FontSize: 12,
    WindowSize: {Width: 1024, Height: 768},
    Navigation: {
        Expanded: true,
        Width: 220
    }
}
```

### 主题支持
UI 支持主题切换：

```ahk
; 设置主题
UI_SetTheme("dark") {
    ; 应用深色主题样式
    UI.Main.BackColor := "0x1E1E1E"
    UI.Main.SetFont("cWhite")
    
    ; 更新所有控件样式
    UI_UpdateThemeStyles()
}
```

## 性能考虑

### 优化策略
1. **延迟加载**：页面按需加载
2. **控件重用**：重用现有控件减少创建开销
3. **事件优化**：高效的事件处理
4. **内存管理**：及时清理未使用的控件

### 响应式优化
- 避免频繁的布局计算
- 使用缓存优化重复操作
- 批量更新减少重绘

## 错误处理

UI 框架包含全面的错误处理：
- 控件创建失败
- 事件处理错误
- 布局计算错误
- 对话框操作失败

## 调试功能

### UI 调试接口
模块提供实时监控的调试接口：

```ahk
; 启用 UI 调试
UI_EnableDebug()

; 获取调试信息
debugInfo := UI_GetDebugInfo()
```

### 布局调试
详细的布局信息用于调试：

```ahk
; 获取布局统计
layoutStats := UI_GetLayoutStats()
Logger_Debug("UI", "布局统计", layoutStats)
```

## 依赖项

- AutoHotkey v2.0+ 用于 GUI 功能
- 语言系统用于国际化
- 配置系统用于 UI 设置
- 日志系统用于调试信息

## 相关模块

- [核心模块](../core/README.md) - 应用程序基础
- [语言模块](../i18n/README.md) - 国际化支持
- [配置系统](../core/README.md) - UI 设置管理
- [日志模块](../logging/README.md) - 调试信息记录