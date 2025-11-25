# UI Framework Documentation

The UI framework provides the user interface components for the Game Macro application, featuring a modular and extensible design.

[English Version](README.md) | [中文版本](../cn/ui/README.md)

## Overview

The UI system is built around a main shell with navigation tree and dynamic page loading. It supports:
- Multi-language interface
- Responsive layout
- Dynamic page switching
- Modal dialogs
- Real-time updates

## Key Components

### UI_Shell.ahk
Main application shell with navigation tree and page management.

#### Key Functions
- `UI_ShowMain()` - Display main application window
- `UI_OnNavChange()` - Handle navigation tree selection
- `UI_OnResize_LeftNav()` - Handle window resize events
- `UI_SwitchPage(key)` - Switch between different pages

#### Navigation Structure
```ahk
rootProfile := UI.Nav.Add("概览与配置")
rootData    := UI.Nav.Add("数据与检测")
rootAuto    := UI.Nav.Add("自动化")
rootAdv     := UI.Nav.Add("高级功能")
rootTools   := UI.Nav.Add("工具")
rootSet     := UI.Nav.Add("设置")
```

### UI_Layout.ahk
Layout management and responsive design.

### UI_Framework.ahk
Base UI components and framework utilities.

## Page System

The UI uses a page-based architecture where each functional area is implemented as a separate page.

### Page Registration
```ahk
UI_RegisterPage("profile", "概览与配置", Page_Profile_Build, Page_Profile_Layout, Page_Profile_OnEnter)
UI_RegisterPage("skills", "技能", Page_Skills_Build, Page_Skills_Layout)
UI_RegisterPage("rules", "循环规则", Page_Rules_Build, Page_Rules_Layout, Page_Rules_OnEnter)
```

### Available Pages

#### Profile Page
- Overview and configuration management
- Profile selection and creation
- Basic settings

#### Skills Page
- Skill configuration and management
- Hotkey assignment
- Pixel detection setup

#### Rules Page
- Rule creation and editing
- Condition configuration
- Action assignment

#### Advanced Pages
- Rotation configuration
- Diagnostic tools
- Log viewer
- Cast debugging

## Dialog System

The UI includes various modal dialogs for specific tasks:

### Skill Editor (GUI_SkillEditor.ahk)
- Edit skill properties
- Configure pixel detection
- Set hotkeys and cooldowns

### Point Editor (GUI_PointEditor.ahk)
- Manage pixel detection points
- Configure color tolerance
- Set sampling parameters

### Rule Editor (GUI_RuleEditor.ahk)
- Create and edit automation rules
- Configure conditions and actions
- Set priorities and timing

### Buff Editor (GUI_BuffEditor.ahk)
- Configure buff timers
- Set duration and effects
- Manage buff tracking

### Cast Debug (GUI_CastDebug.ahk)
- Real-time skill casting debug
- Cast bar monitoring
- Performance analysis

## Layout System

The UI uses a responsive layout system that adapts to window size changes.

### Main Layout Structure
```ahk
; Left navigation tree
UI.Nav := UI.Main.Add("TreeView", "xm ym w220 h620 +Lines +Buttons")

; Right content area
UI.Content := UI.Main.Add("GroupBox", "x+10 yp w600 h620", "Content")
```

### Responsive Behavior
- Navigation tree maintains fixed width
- Content area expands to fill available space
- Controls reposition based on available space
- Font sizes adjust for readability

## Internationalization

The UI supports multiple languages through the language system:

### Language Integration
```ahk
; Initialize language system
Lang_Init(AppConfig_Get("Language", "zh-CN"))

; Use translated text
UI.Main.Title := T("app.title", "Game Macro")
```

### Language Files
- `Languages/zh-CN.ini` - Chinese translations
- `Languages/en-US.ini` - English translations

## Event Handling

The UI uses AutoHotkey's event system for user interactions.

### Event Types
- **Click Events**: Button clicks, tree selection
- **Change Events**: Input field changes
- **Resize Events**: Window size changes
- **Close Events**: Application termination

### Event Registration
```ahk
; Button click event
myButton.OnEvent("Click", MyButton_Click)

; Tree view selection
UI.Nav.OnEvent("Click", UI_OnNavChange)

; Window close
UI.Main.OnEvent("Close", UI_OnMainClose)
```

## Usage Examples

### Creating a Simple Page
```ahk
Page_MyPage_Build() {
    global UI
    
    ; Create controls
    UI.MyPage.Label := UI.Content.Add("Text", "xm ym", "My Page Title")
    UI.MyPage.Button := UI.Content.Add("Button", "x+10", "Click Me")
    
    ; Register events
    UI.MyPage.Button.OnEvent("Click", MyPage_ButtonClick)
}

Page_MyPage_Layout() {
    global UI
    
    ; Position controls
    UI.MyPage.Label.Move(10, 10, 200, 20)
    UI.MyPage.Button.Move(220, 10, 100, 25)
}

MyPage_ButtonClick(*) {
    MsgBox "Button clicked!"
}
```

### Handling Navigation
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

## API Reference

### UI_Shell Functions

#### UI_ShowMain()
Creates and displays the main application window.

**Parameters:** None

**Returns:** Nothing

#### UI_SwitchPage(key)
Switches to the specified page.

**Parameters:**
- `key` (String): Page identifier

**Returns:** Nothing

### Page Registration

#### UI_RegisterPage(key, name, buildFunc, layoutFunc, enterFunc)
Registers a new page with the UI system.

**Parameters:**
- `key` (String): Unique page identifier
- `name` (String): Display name
- `buildFunc` (Function): Function to build page controls
- `layoutFunc` (Function): Function to layout page controls
- `enterFunc` (Function): Optional function called when page is entered

**Returns:** Nothing

## Dependencies

- AutoHotkey v2.0 GUI system
- Language module for internationalization
- Core module for configuration

## Best Practices

1. Use the page registration system for new features
2. Follow the established layout patterns
3. Implement proper event handling
4. Support internationalization
5. Test responsive behavior

## Related Modules

- [Core System](../core/README.md) - Configuration and state management
- [Language System](../i18n/README.md) - Internationalization support
- [Engine Modules](../engines/README.md) - Backend functionality