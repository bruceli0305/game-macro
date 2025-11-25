# 国际化 (i18n) 模块文档

国际化模块为 Game Macro 系统提供多语言支持，实现本地化和语言切换功能。

[English Version](../../i18n/README.md) | [中文版本](README.md)

## 概述

国际化模块提供：
- 多语言文本管理
- 动态语言切换
- 字符串翻译和格式化
- 语言资源管理
- 区域特定格式化

## 架构

i18n 系统设计用于灵活的语言支持：

### Lang.ahk（主语言控制器）
主语言管理和翻译系统。

### 集成点
- **UI 系统**：用户界面元素的文本翻译
- **配置系统**：语言偏好管理
- **所有模块**：字符串翻译服务
- **存储模块**：语言资源持久化

## 关键组件

### 语言配置
可配置的语言设置和行为。

#### 语言配置结构
```ahk
LangConfig := {
    DefaultLanguage: "en-US",
    AvailableLanguages: ["en-US", "zh-CN", "ja-JP"],
    FallbackLanguage: "en-US",
    AutoDetect: true,
    ResourcePath: "Languages"
}
```

### 语言资源结构
结构化的语言资源文件。

#### 语言资源格式
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

### 翻译系统
具有参数替换的灵活翻译。

#### 翻译请求结构
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

## 执行流程

### 语言初始化过程
1. **配置加载**：加载语言配置
2. **资源检测**：检测可用语言资源
3. **语言选择**：确定活动语言
4. **资源加载**：加载选定的语言资源
5. **系统集成**：初始化翻译系统

### 翻译过程
1. **翻译请求**：模块请求翻译
2. **键解析**：解析翻译键
3. **参数替换**：替换翻译中的参数
4. **回退处理**：处理缺失的翻译
5. **结果返回**：返回翻译后的字符串

### 语言切换过程
1. **语言选择**：用户选择新语言
2. **资源验证**：验证新语言资源
3. **资源加载**：加载新语言资源
4. **UI 更新**：使用新翻译更新 UI 元素
5. **配置保存**：保存语言偏好

## API 参考

### 核心函数

#### Lang_Init(config)
初始化国际化系统。

**参数：**
- `config`（Map）：语言配置

**返回：**布尔值指示成功

#### Lang_Shutdown()
关闭国际化系统。

**参数：**无

**返回：**布尔值指示成功

#### Lang_GetCurrentLanguage()
获取当前活动语言。

**参数：**无

**返回：**当前语言代码

#### Lang_SetLanguage(languageCode)
设置活动语言。

**参数：**
- `languageCode`（字符串）：语言代码（例如 "en-US"）

**返回：**布尔值指示成功

### 翻译函数

#### Lang_Translate(key, params, defaultValue)
翻译字符串键。

**参数：**
- `key`（字符串）：翻译键
- `params`（Map）：翻译参数（可选）
- `defaultValue`（字符串）：如果键未找到的默认值（可选）

**返回：**翻译后的字符串

#### Lang_TranslateFormat(key, formatParams, translationParams)
翻译并格式化字符串。

**参数：**
- `key`（字符串）：翻译键
- `formatParams`（Map）：格式化参数
- `translationParams`（Map）：翻译参数（可选）

**返回：**格式化和翻译后的字符串

#### Lang_HasTranslation(key)
检查翻译键是否存在。

**参数：**
- `key`（字符串）：翻译键

**返回：**布尔值指示键存在

### 语言管理

#### Lang_GetAvailableLanguages()
获取所有可用语言。

**参数：**无

**返回：**可用语言信息数组

#### Lang_LoadLanguageResource(languageCode)
加载特定语言的语言资源。

**参数：**
- `languageCode`（字符串）：语言代码

**返回：**布尔值指示成功

#### Lang_GetLanguageInfo(languageCode)
获取特定语言的信息。

**参数：**
- `languageCode`（字符串）：语言代码

**返回：**语言信息映射

### 资源管理

#### Lang_AddTranslation(key, translation, languageCode)
添加自定义翻译。

**参数：**
- `key`（字符串）：翻译键
- `translation`（字符串）：翻译文本
- `languageCode`（字符串）：语言代码

**返回：**布尔值指示成功

#### Lang_RemoveTranslation(key, languageCode)
移除自定义翻译。

**参数：**
- `key`（字符串）：翻译键
- `languageCode`（字符串）：语言代码

**返回：**布尔值指示成功

#### Lang_ReloadResources()
重新加载所有语言资源。

**参数：**无

**返回：**布尔值指示成功

### 格式化函数

#### Lang_FormatDate(date, formatKey)
根据语言特定格式格式化日期。

**参数：**
- `date`（日期对象）：要格式化的日期
- `formatKey`（字符串）：格式键

**返回：**格式化后的日期字符串

#### Lang_FormatTime(time, formatKey)
根据语言特定格式格式化时间。

**参数：**
- `time`（时间对象）：要格式化的时间
- `formatKey`（字符串）：格式键

**返回：**格式化后的时间字符串

#### Lang_FormatNumber(number, formatKey)
根据语言特定格式格式化数字。

**参数：**
- `number`（数字）：要格式化的数字
- `formatKey`（字符串）：格式键

**返回：**格式化后的数字字符串

## 使用示例

### 基本翻译
```ahk
; 简单翻译
welcomeText := Lang_Translate("ui.main.welcome")
startButtonText := Lang_Translate("ui.main.start")
```

### 带参数的翻译
```ahk
; 带参数的翻译
userWelcome := Lang_Translate("ui.user.welcome", {
    "username": "John",
    "level": 5
})
```

### 语言切换
```ahk
; 切换到中文
if (Lang_SetLanguage("zh-CN")) {
    Logger_Info("i18n", "语言已切换到中文")
}
```

### 自定义翻译
```ahk
; 添加自定义翻译
Lang_AddTranslation("custom.message", "自定义消息", "zh-CN")
```

## 配置集成

### 配置文件集成
语言配置存储在配置文件数据中：

```ahk
profile := App["ProfileData"]
profile["Language"] := "zh-CN"
profile["LanguageConfig"] := LangConfig
```

### 资源文件结构
语言资源存储在单独的文件中：

```
Languages/
├── en-US.json
├── zh-CN.json
└── ja-JP.json
```

## 性能考虑

### 优化策略
1. **资源缓存**：缓存加载的语言资源
2. **键查找优化**：优化翻译键查找性能
3. **延迟加载**：按需加载语言资源
4. **内存管理**：高效管理翻译缓存

### 内存管理
- 语言资源在切换时清理
- 翻译缓存大小限制
- 无效资源检测和清理

## 错误处理

国际化模块包含全面的错误处理：
- 缺失语言资源
- 无效翻译键
- 格式错误
- 资源加载失败

## 调试功能

### 翻译调试接口
模块提供实时监控的调试接口：

```ahk
; 启用翻译调试
Lang_EnableDebug()

; 获取调试信息
debugInfo := Lang_GetDebugInfo()
```

### 日志集成
所有国际化活动都记录日志以便故障排除：
- 语言切换尝试
- 翻译请求
- 资源加载状态
- 错误条件

## 依赖项

- 配置系统用于语言偏好
- 存储模块用于资源持久化
- UI 系统用于文本显示
- 日志系统用于活动跟踪

## 相关模块

- [UI 系统](../ui/README.md) - 用户界面文本显示
- [配置系统](../core/README.md) - 语言偏好管理
- [存储模块](../storage/README.md) - 语言资源持久化
- [日志模块](../logging/README.md) - 活动跟踪