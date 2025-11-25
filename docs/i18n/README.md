# Internationalization (i18n) Module Documentation

The Internationalization module provides multi-language support for the Game Macro system, enabling localization and language switching capabilities.

[English Version](README.md) | [中文版本](../cn/i18n/README.md)

## Overview

The Internationalization module provides:
- Multi-language text management
- Dynamic language switching
- String translation and formatting
- Language resource management
- Locale-specific formatting

## Architecture

The i18n system is designed for flexible language support:

### Lang.ahk (Main Language Controller)
Main language management and translation system.

### Integration Points
- **UI System**: Text translation for user interface elements
- **Configuration System**: Language preference management
- **All Modules**: String translation services
- **Storage Module**: Language resource persistence

## Key Components

### Language Configuration
Configurable language settings and behavior.

#### Language Configuration Structure
```ahk
LangConfig := {
    DefaultLanguage: "en-US",
    AvailableLanguages: ["en-US", "zh-CN", "ja-JP"],
    FallbackLanguage: "en-US",
    AutoDetect: true,
    ResourcePath: "Languages"
}
```

### Language Resource Structure
Structured language resource files.

#### Language Resource Format
```ahk
LanguageResource := {
    Language: "en-US",
    Name: "English (United States)",
    Strings: {
        "ui.main.title": "Game Macro System",
        "ui.main.start": "Start",
        "ui.main.stop": "Stop",
        "ui.settings.language": "Language",
        "error.generic": "An error occurred",
        "success.profile_saved": "Profile saved successfully"
    },
    Formats: {
        "date.short": "MM/dd/yyyy",
        "time.short": "HH:mm",
        "number.decimal": "#,##0.00"
    }
}
```

### Translation System
Flexible translation with parameter substitution.

#### Translation Request Structure
```ahk
TranslationRequest := {
    Key: "ui.main.welcome",
    Params: {
        "username": "John",
        "level": 5
    },
    Default: "Welcome {username}!"
}
```

## Execution Flow

### Language Initialization Process
1. **Configuration Load**: Load language configuration
2. **Resource Detection**: Detect available language resources
3. **Language Selection**: Determine active language
4. **Resource Loading**: Load selected language resources
5. **System Integration**: Initialize translation system

### Translation Process
1. **Translation Request**: Module requests translation
2. **Key Resolution**: Resolve translation key
3. **Parameter Substitution**: Substitute parameters in translation
4. **Fallback Handling**: Handle missing translations
5. **Result Return**: Return translated string

### Language Switching Process
1. **Language Selection**: User selects new language
2. **Resource Validation**: Validate new language resources
3. **Resource Loading**: Load new language resources
4. **UI Update**: Update UI elements with new translations
5. **Configuration Save**: Save language preference

## API Reference

### Core Functions

#### Lang_Init(config)
Initializes the internationalization system.

**Parameters:**
- `config` (Map): Language configuration

**Returns:** Boolean indicating success

#### Lang_Shutdown()
Shuts down the internationalization system.

**Parameters:** None

**Returns:** Boolean indicating success

#### Lang_GetCurrentLanguage()
Gets the current active language.

**Parameters:** None

**Returns:** Current language code

#### Lang_SetLanguage(languageCode)
Sets the active language.

**Parameters:**
- `languageCode` (String): Language code (e.g., "en-US")

**Returns:** Boolean indicating success

### Translation Functions

#### Lang_Translate(key, params, defaultValue)
Translates a string key.

**Parameters:**
- `key` (String): Translation key
- `params` (Map): Translation parameters (optional)
- `defaultValue` (String): Default value if key not found (optional)

**Returns:** Translated string

#### Lang_TranslateFormat(key, formatParams, translationParams)
Translates and formats a string.

**Parameters:**
- `key` (String): Translation key
- `formatParams` (Map): Format parameters
- `translationParams` (Map): Translation parameters (optional)

**Returns:** Formatted and translated string

#### Lang_HasTranslation(key)
Checks if a translation key exists.

**Parameters:**
- `key` (String): Translation key

**Returns:** Boolean indicating key existence

### Language Management

#### Lang_GetAvailableLanguages()
Gets all available languages.

**Parameters:** None

**Returns:** Array of available language information

#### Lang_LoadLanguageResource(languageCode)
Loads language resources for a specific language.

**Parameters:**
- `languageCode` (String): Language code

**Returns:** Boolean indicating success

#### Lang_GetLanguageInfo(languageCode)
Gets information about a specific language.

**Parameters:**
- `languageCode` (String): Language code

**Returns:** Language information map

### Resource Management

#### Lang_AddTranslation(key, translation, languageCode)
Adds a custom translation.

**Parameters:**
- `key` (String): Translation key
- `translation` (String): Translation text
- `languageCode` (String): Language code (optional, defaults to current)

**Returns:** Boolean indicating success

#### Lang_RemoveTranslation(key, languageCode)
Removes a translation.

**Parameters:**
- `key` (String): Translation key
- `languageCode` (String): Language code (optional)

**Returns:** Boolean indicating success

#### Lang_ExportTranslations(languageCode, format)
Exports translations to external format.

**Parameters:**
- `languageCode` (String): Language code
- `format` (String): Export format ("JSON", "CSV")

**Returns:** Export data

## Usage Examples

### Basic Internationalization Setup
```ahk
; Initialize internationalization system
langConfig := {
    DefaultLanguage: "en-US",
    AvailableLanguages: ["en-US", "zh-CN", "ja-JP"],
    FallbackLanguage: "en-US",
    AutoDetect: true,
    ResourcePath: "Languages"
}

if (!Lang_Init(langConfig)) {
    Logger_Error("i18n", "Failed to initialize internationalization system")
    ExitApp(1)
}

; Basic translation
title := Lang_Translate("ui.main.title")
startButton := Lang_Translate("ui.main.start")
stopButton := Lang_Translate("ui.main.stop")
```

### Language Resource File Example
```ahk
; English language resource (en-US.ahk)
LanguageResource := {
    Language: "en-US",
    Name: "English (United States)",
    Strings: {
        "ui.main.title": "Game Macro System",
        "ui.main.start": "Start",
        "ui.main.stop": "Stop",
        "ui.main.welcome": "Welcome {username}! You are level {level}.",
        "ui.settings.language": "Language",
        "ui.settings.profiles": "Profiles",
        "error.generic": "An error occurred",
        "error.profile_not_found": "Profile '{profileName}' not found",
        "success.profile_saved": "Profile saved successfully",
        "status.running": "Running",
        "status.stopped": "Stopped",
        "status.paused": "Paused"
    },
    Formats: {
        "date.short": "MM/dd/yyyy",
        "time.short": "HH:mm:ss",
        "number.decimal": "#,##0.00"
    }
}
```

```ahk
; Chinese language resource (zh-CN.ahk)
LanguageResource := {
    Language: "zh-CN", 
    Name: "中文(简体)",
    Strings: {
        "ui.main.title": "游戏宏系统",
        "ui.main.start": "开始",
        "ui.main.stop": "停止",
        "ui.main.welcome": "欢迎 {username}！您的等级是 {level}。",
        "ui.settings.language": "语言",
        "ui.settings.profiles": "配置文件",
        "error.generic": "发生错误",
        "error.profile_not_found": "配置文件 '{profileName}' 未找到",
        "success.profile_saved": "配置文件保存成功",
        "status.running": "运行中",
        "status.stopped": "已停止", 
        "status.paused": "已暂停"
    },
    Formats: {
        "date.short": "yyyy年MM月dd日",
        "time.short": "HH时mm分ss秒",
        "number.decimal": "#,##0.00"
    }
}
```

### Advanced Translation Usage
```ahk
; Translation with parameters
username := "Player123"
level := 25
welcomeMessage := Lang_Translate("ui.main.welcome", {
    "username": username,
    "level": level
})
; Result: "Welcome Player123! You are level 25."

; Error message with dynamic content
profileName := "Warrior Rotation"
errorMessage := Lang_Translate("error.profile_not_found", {
    "profileName": profileName
})
; Result: "Profile 'Warrior Rotation' not found"

; Check if translation exists before using
if (Lang_HasTranslation("ui.advanced.feature")) {
    featureText := Lang_Translate("ui.advanced.feature")
} else {
    featureText := "Advanced Feature" ; Fallback
}
```

### Language Switching Implementation
```ahk
; Language selection in UI
UI_CreateLanguageSelector() {
    languages := Lang_GetAvailableLanguages()
    
    for lang in languages {
        UI_AddLanguageOption(lang["Code"], lang["Name"])
    }
    
    ; Set current selection
    currentLang := Lang_GetCurrentLanguage()
    UI_SetSelectedLanguage(currentLang)
}

; Handle language change
UI_OnLanguageChange(newLanguage) {
    if (Lang_SetLanguage(newLanguage)) {
        ; Update all UI elements
        UI_UpdateAllTexts()
        
        ; Save preference
        App["Config"]["Language"] := newLanguage
        Config_Save()
        
        Logger_Info("i18n", "Language changed", Map("language", newLanguage))
    } else {
        Logger_Error("i18n", "Failed to change language", Map("language", newLanguage))
    }
}
```

### Module Integration Examples
```ahk
; Rotation engine with internationalization
RotationEngine_GetStatusText(status) {
    switch status {
        case "running":
            return Lang_Translate("status.running")
        case "stopped":
            return Lang_Translate("status.stopped") 
        case "paused":
            return Lang_Translate("status.paused")
        default:
            return Lang_Translate("status.unknown")
    }
}

; Error handling with translation
HandleProfileError(errorType, details) {
    errorKey := "error." . errorType
    
    if (Lang_HasTranslation(errorKey)) {
        errorMessage := Lang_Translate(errorKey, details)
    } else {
        errorMessage := Lang_Translate("error.generic")
    }
    
    UI_ShowError(errorMessage)
    Logger_Error("Profile", errorMessage, details)
}

; Success messages with translation
ShowSuccessMessage(messageKey, params) {
    message := Lang_Translate(messageKey, params)
    UI_ShowSuccess(message)
    Logger_Info("UI", message)
}
```

### Custom Translation Management
```ahk
; Add custom translations for specific features
Lang_AddTranslation("ui.custom.feature", "Custom Feature", "en-US")
Lang_AddTranslation("ui.custom.feature", "自定义功能", "zh-CN")

; Export translations for external editing
exportData := Lang_ExportTranslations("en-US", "JSON")
FileWrite("translations_en.json", exportData)

; Import custom translations from file
customTranslations := FileRead("custom_translations.json")
for translation in customTranslations {
    Lang_AddTranslation(translation["key"], translation["text"], translation["language"])
}
```

## Configuration Integration

### Language Settings
Language settings are configured in the main application:

```ahk
App["LanguageConfig"] := {
    DefaultLanguage: "en-US",
    AvailableLanguages: ["en-US", "zh-CN", "ja-JP", "ko-KR"],
    FallbackLanguage: "en-US",
    AutoDetect: true,
    ResourcePath: "Languages",
    CacheResources: true,
    HotReload: false
}
```

### UI Text Configuration
UI text keys are organized by module and component:

```ahk
; UI text key conventions
App["UITextKeys"] := {
    MainWindow: {
        Title: "ui.main.title",
        StartButton: "ui.main.start",
        StopButton: "ui.main.stop",
        StatusLabel: "ui.main.status"
    },
    Settings: {
        Title: "ui.settings.title",
        LanguageLabel: "ui.settings.language",
        ProfilesLabel: "ui.settings.profiles"
    },
    Errors: {
        Generic: "error.generic",
        ProfileNotFound: "error.profile_not_found",
        SaveFailed: "error.save_failed"
    }
}
```

## Performance Considerations

### Optimization Strategies
1. **Resource Caching**: Cache loaded language resources
2. **Lazy Loading**: Load language resources on demand
3. **Key Indexing**: Optimize translation key lookup
4. **Memory Management**: Efficient memory usage for large resource files

### Best Practices
- Use consistent naming conventions for translation keys
- Group related keys by module and functionality
- Include context comments in resource files
- Test translations with different parameter combinations
- Handle missing translations gracefully

## Error Handling

The internationalization module includes comprehensive error handling:
- Missing language resource files
- Invalid translation keys
- Parameter substitution errors
- Language switching failures
- Resource loading errors

## Debugging Features

### i18n Debug Interface
The module provides debugging capabilities:

```ahk
; Enable i18n debugging
Lang_EnableDebug()

; Get debug information
debugInfo := Lang_GetDebugInfo()

; Test translation functionality
Lang_TestTranslations()
```

### Translation Validation
Built-in tools for translation validation:

```ahk
; Validate translation coverage
coverage := Lang_ValidateCoverage({
    RequiredKeys: ["ui.main.title", "ui.main.start", "ui.main.stop"],
    Languages: ["en-US", "zh-CN"]
})

; Generate translation report
report := Lang_GenerateTranslationReport({
    Language: "zh-CN",
    Format: "HTML"
})
```

## Dependencies

- File system utilities for resource file management
- String manipulation utilities for parameter substitution
- Configuration system for language settings
- UI system for text display and updating

## Related Modules

- [UI Module](../ui/README.md) - Text display and user interface
- [Core Module](../core/README.md) - Application configuration
- [Storage Module](../storage/README.md) - Language resource persistence
- [Util Module](../util/README.md) - Utility functions for string operations