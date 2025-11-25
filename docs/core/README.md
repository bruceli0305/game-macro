# Core System Documentation

The Core module provides the foundation for the Game Macro application, handling configuration management, application state, and core functionality.

[English Version](README.md) | [中文版本](../cn/core/README.md)

## Overview

The Core system is responsible for:
- Application initialization and configuration
- Global state management
- Profile and data management
- Module coordination

## Key Components

### AppConfig.ahk
Handles application-wide configuration management.

#### Key Functions
- `AppConfig_Init()` - Initialize configuration system
- `AppConfig_Get(section, key, default)` - Get configuration value
- `AppConfig_Set(section, key, value)` - Set configuration value
- `AppConfig_GetLog(level, default)` - Get logging configuration

#### Configuration Structure
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
Manages global application state and provides core functionality.

#### Key Functions
- `Core_Init()` - Initialize core system
- `Core_DefaultProfileData()` - Get default profile structure
- `Core_LoadProfile(name)` - Load profile data
- `Core_SaveProfile(name)` - Save profile data

#### Application State Structure
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

#### Profile Data Structure
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

## Usage Examples

### Initializing the Core System
```ahk
#Include "modules\\core\\Core.ahk"
#Include "modules\\core\\AppConfig.ahk"

; Initialize configuration
AppConfig_Init()

; Initialize core system
Core_Init()

; Load a profile
Core_LoadProfile("MyProfile")
```

### Accessing Configuration
```ahk
; Get language setting
language := AppConfig_Get("General", "Language", "zh-CN")

; Set logging level
AppConfig_Set("Logging", "Level", "DEBUG")
```

### Working with Application State
```ahk
; Check if application is running
if (App["IsRunning"]) {
    ; Application is active
}

; Access current profile data
profile := App["ProfileData"]
startHotkey := profile["StartHotkey"]
```

## API Reference

### AppConfig Functions

#### AppConfig_Init()
Initializes the configuration system and loads configuration files.

**Parameters:** None

**Returns:** Nothing

#### AppConfig_Get(section, key, default)
Retrieves a configuration value.

**Parameters:**
- `section` (String): Configuration section
- `key` (String): Configuration key
- `default` (Any): Default value if not found

**Returns:** Configuration value or default

### Core Functions

#### Core_Init()
Initializes the core application system.

**Parameters:** None

**Returns:** Nothing

#### Core_DefaultProfileData()
Returns the default profile data structure.

**Parameters:** None

**Returns:** Map containing default profile data

## Dependencies

- Requires AutoHotkey v2.0+
- Depends on file system operations
- Uses INI file format for configuration

## Error Handling

The Core system includes error handling for:
- Configuration file access errors
- Invalid profile data
- Directory creation failures

## Best Practices

1. Always call `AppConfig_Init()` before accessing configuration
2. Use `Core_DefaultProfileData()` as template for new profiles
3. Validate profile data before saving
4. Handle configuration errors gracefully

## Related Modules

- [UI Framework](../ui/README.md) - User interface components
- [Storage System](../storage/README.md) - Data persistence
- [Logging System](../logging/README.md) - Log management