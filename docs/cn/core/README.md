# 核心系统文档

核心模块为 Game Macro 应用程序提供基础，处理配置管理、应用程序状态和核心功能。

[English Version](../../core/README.md) | [中文版本](README.md)

## 概述

核心系统负责：
- 应用程序初始化和配置
- 全局状态管理
- 配置文件和数据管理
- 模块协调

## 关键组件

### AppConfig.ahk
处理应用程序范围的配置管理。

#### 关键函数
- `AppConfig_Init()` - 初始化配置系统
- `AppConfig_Get(section, key, default)` - 获取配置值
- `AppConfig_Set(section, key, value)` - 设置配置值
- `AppConfig_GetLog(level, default)` - 获取日志配置

#### 配置结构
```ini
[General]
Language=zh-CN
Version=0.1.3

[Logging]
Level=DEBUG
RotateSizeMB=10
RotateKeep=5
```

### Core.ahk
管理全局应用程序状态并提供核心功能。

#### 关键函数
- `Core_Init()` - 初始化核心系统
- `Core_DefaultProfileData()` - 获取默认配置文件结构
- `Core_LoadProfile(name)` - 加载配置文件数据
- `Core_SaveProfile(name)` - 保存配置文件数据

#### 应用程序状态结构
```ahk
global App := Map(
    "ProfilesDir", A_ScriptDir "\\Profiles",
    "ExportDir", A_ScriptDir "\\Exports",
    "ConfigExt", ".ini",
    "CurrentProfile", "",
    "Profiles", [],
    "ProfileData", Core_DefaultProfileData(),
    "IsRunning", false,
    "BoundHotkeys", Map()
)
```

#### 配置文件数据结构
```ahk
{
    Name: "Default",
    StartHotkey: "F9",
    PollIntervalMs: 25,
    SendCooldownMs: 250,
    PickHoverEnabled: 1,
    PickHoverOffsetY: -60,
    PickHoverDwellMs: 120,
    PickConfirmKey: "LButton",
    Skills: [],
    Points: [],
    Rules: [],
    Buffs: [],
    Threads: [ { Id: 1, Name: "默认线程" } ],
    DefaultSkill: {
        Enabled: 0,
        SkillIndex: 0,
        CheckReady: 1,
        ThreadId: 1,
        CooldownMs: 600,
        PreDelayMs: 0,
        LastFire: 0
    },
    Rotation: {
        Enabled: 0,
        DefaultTrackId: 1,
        SwapKey: "",
        BusyWindowMs: 200,
        ColorTolBlack: 16,
        RespectCastLock: 1,
        BlackGuard: { 
            Enabled: 1, 
            SampleCount: 5, 
            BlackRatioThresh: 0.7,
            WindowMs: 120, 
            CooldownMs: 600, 
            MinAfterSendMs: 60,
            MaxAfterSendMs: 800, 
            UniqueRequired: 1 
        },
        Opener: { 
            Enabled: 0, 
            MaxDurationMs: 4000, 
            Watch: [] 
        }
    }
}
```

## 使用示例

### 初始化核心系统
```ahk
#Include "modules\\core\\Core.ahk"
#Include "modules\\core\\AppConfig.ahk"

; 初始化配置
AppConfig_Init()

; 初始化核心系统
Core_Init()

; 加载配置文件
Core_LoadProfile("MyProfile")
```

### 访问配置
```ahk
; 获取语言设置
language := AppConfig_Get("General", "Language", "zh-CN")

; 设置日志级别
AppConfig_Set("Logging", "Level", "DEBUG")
```

### 处理应用程序状态
```ahk
; 检查应用程序是否正在运行
if (App["IsRunning"]) {
    ; 应用程序处于活动状态
}

; 访问当前配置文件数据
profile := App["ProfileData"]
startHotkey := profile["StartHotkey"]
```

## API 参考

### AppConfig 函数

#### AppConfig_Init()
初始化配置系统并加载配置文件。

**参数：** 无

**返回值：** 无

#### AppConfig_Get(section, key, default)
检索配置值。

**参数：**
- `section` (字符串): 配置部分
- `key` (字符串): 配置键
- `default` (任意): 未找到时的默认值

**返回值：** 配置值或默认值

### Core 函数

#### Core_Init()
初始化核心应用程序系统。

**参数：** 无

**返回值：** 无

#### Core_DefaultProfileData()
返回默认的配置文件数据结构。

**参数：** 无

**返回值：** 包含默认配置文件数据的映射

## 依赖关系

- 需要 AutoHotkey v2.0+
- 依赖文件系统操作
- 使用 INI 文件格式进行配置

## 错误处理

核心系统包含以下错误处理：
- 配置文件访问错误
- 无效的配置文件数据
- 目录创建失败

## 最佳实践

1. 在访问配置之前始终调用 `AppConfig_Init()`
2. 使用 `Core_DefaultProfileData()` 作为新配置文件的模板
3. 在保存之前验证配置文件数据
4. 优雅地处理配置错误

## 相关模块

- [UI 框架](../ui/README.md) - 用户界面组件
- [存储系统](../storage/README.md) - 数据持久化
- [日志系统](../logging/README.md) - 日志管理

[返回英文版本](../../core/README.md)