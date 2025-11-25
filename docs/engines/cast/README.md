# Cast Engine Documentation

The Cast Engine handles skill execution, casting mechanics, and skill state management for the Game Macro system.

[English Version](README.md) | [中文版本](../../cn/engines/cast/README.md)

## Overview

The Cast Engine provides:
- Skill execution and hotkey sending
- Cast bar detection and monitoring
- Skill cooldown tracking
- Skill readiness checking
- Multi-threaded skill execution

## Architecture

The engine is designed to work with the rotation and rule systems:

### CastEngine.ahk (Main Engine)
Main skill execution and management system.

### Integration Points
- **Rotation Engine**: Receives skill execution requests
- **Rule Engine**: Provides skill state information
- **UI System**: Offers cast debugging interface

## Key Components

### Skill Execution System
Manages the actual sending of skill hotkeys and monitoring execution.

#### Skill Configuration
```ahk
Skill := {
    Id: 1,
    Name: "Fireball",
    Key: "1",
    X: 100,
    Y: 200,
    Color: "0xFF0000",
    Tolerance: 10,
    CooldownMs: 2000,
    CastTimeMs: 1500,
    CheckReady: true,
    ThreadId: 1
}
```

### Cast Bar Detection
Monitors cast bars to determine skill execution status.

#### Cast Bar Configuration
```ahk
CastBar := {
    Enabled: true,
    X: 500,
    Y: 600,
    Width: 200,
    Height: 20,
    ActiveColor: "0x00FF00",
    InactiveColor: "0x000000",
    Tolerance: 5
}
```

### Skill State Tracking
Tracks the current state of all skills.

#### Skill State Structure
```ahk
SkillState := {
    IsCasting: false,
    CastStartTime: 0,
    CastEndTime: 0,
    LastUsed: 0,
    CooldownEnd: 0,
    IsReady: true
}
```

## Execution Flow

### Skill Execution Process
1. **Pre-execution Checks**: Verify skill readiness and conditions
2. **Hotkey Sending**: Send the skill hotkey
3. **Cast Monitoring**: Monitor cast bar if enabled
4. **State Update**: Update skill cooldown and state
5. **Post-execution**: Handle any follow-up actions

### Cast Bar Monitoring Algorithm
1. Sample cast bar area
2. Detect active casting state
3. Track cast progress
4. Detect cast completion
5. Update skill state accordingly

## API Reference

### Core Functions

#### CastEngine_Init()
Initializes the cast engine.

**Parameters:** None

**Returns:** Boolean indicating success

#### CastEngine_ExecuteSkill(skillId, threadId)
Executes a specific skill.

**Parameters:**
- `skillId` (Integer): Skill identifier
- `threadId` (Integer): Execution thread ID

**Returns:** Boolean indicating execution success

#### CastEngine_IsSkillReady(skillId)
Checks if a skill is ready to use.

**Parameters:**
- `skillId` (Integer): Skill identifier

**Returns:** Boolean indicating skill readiness

#### CastEngine_GetSkillCooldown(skillId)
Gets the remaining cooldown for a skill.

**Parameters:**
- `skillId` (Integer): Skill identifier

**Returns:** Integer cooldown in milliseconds

### Skill Management

#### CastEngine_AddSkill(skillConfig)
Adds a new skill to the engine.

**Parameters:**
- `skillConfig` (Map): Skill configuration

**Returns:** Skill ID

#### CastEngine_UpdateSkill(skillId, skillConfig)
Updates an existing skill configuration.

**Parameters:**
- `skillId` (Integer): Skill identifier
- `skillConfig` (Map): Updated skill configuration

**Returns:** Boolean indicating success

#### CastEngine_RemoveSkill(skillId)
Removes a skill from the engine.

**Parameters:**
- `skillId` (Integer): Skill identifier

**Returns:** Boolean indicating success

### Cast Bar Management

#### CastEngine_EnableCastBar(skillId, config)
Enables cast bar detection for a skill.

**Parameters:**
- `skillId` (Integer): Skill identifier
- `config` (Map): Cast bar configuration

**Returns:** Boolean indicating success

#### CastEngine_DisableCastBar(skillId)
Disables cast bar detection for a skill.

**Parameters:**
- `skillId` (Integer): Skill identifier

**Returns:** Boolean indicating success

## Usage Examples

### Basic Skill Configuration
```ahk
; Configure a simple skill
fireballSkill := {
    Id: 1,
    Name: "Fireball",
    Key: "1",
    X: 100,
    Y: 200,
    Color: "0xFF0000",
    Tolerance: 10,
    CooldownMs: 2000,
    CheckReady: true,
    ThreadId: 1
}

CastEngine_AddSkill(fireballSkill)
```

### Skill with Cast Bar Monitoring
```ahk
; Skill with cast bar detection
healSkill := {
    Id: 2,
    Name: "Heal",
    Key: "2",
    X: 150,
    Y: 200,
    Color: "0x00FF00",
    Tolerance: 5,
    CooldownMs: 3000,
    CastTimeMs: 2500,
    CheckReady: true,
    ThreadId: 1
}

; Add cast bar configuration
castBarConfig := {
    Enabled: true,
    X: 500,
    Y: 600,
    Width: 200,
    Height: 20,
    ActiveColor: "0x00FF00",
    InactiveColor: "0x000000",
    Tolerance: 5
}

CastEngine_AddSkill(healSkill)
CastEngine_EnableCastBar(2, castBarConfig)
```

### Skill Execution in Rotation
```ahk
; Execute skill as part of rotation
if (CastEngine_IsSkillReady(skillId)) {
    success := CastEngine_ExecuteSkill(skillId, threadId)
    if (success) {
        ; Skill executed successfully
        Logger_Info("CastEngine", "Skill executed", Map("skillId", skillId))
    }
}
```

### Skill State Monitoring
```ahk
; Check skill state for rule conditions
if (!CastEngine_IsSkillReady(skillId)) {
    cooldown := CastEngine_GetSkillCooldown(skillId)
    Logger_Info("CastEngine", "Skill on cooldown", Map("skillId", skillId, "cooldown", cooldown))
}
```

## Configuration Integration

### Profile Integration
Skills are stored in profile data and loaded with profiles:

```ahk
profile := App["ProfileData"]
profile["Skills"] := [skill1, skill2, skill3]
```

### Thread Management
Skills can be assigned to different execution threads for parallel processing.

## Performance Considerations

### Optimization Strategies
1. **Pixel Sampling Optimization**: Minimize cast bar sampling frequency
2. **Cooldown Caching**: Cache cooldown calculations
3. **State Validation**: Validate skill states before execution
4. **Thread Safety**: Ensure proper synchronization for multi-threaded execution

### Memory Management
- Skill configurations are validated on add
- Invalid configurations are rejected with error messages
- Resources are cleaned up on skill removal

## Error Handling

The cast engine includes comprehensive error handling:
- Invalid skill configurations
- Cast bar detection failures
- Hotkey sending errors
- Thread synchronization issues

## Debugging Features

### Cast Debug Interface
The engine provides a debugging interface for real-time monitoring:

```ahk
; Enable cast debugging
CastEngine_EnableDebug()

; Get debug information
debugInfo := CastEngine_GetDebugInfo()
```

### Logging Integration
All cast engine activities are logged for troubleshooting:
- Skill execution attempts
- Cast bar detection results
- Cooldown state changes
- Error conditions

## Dependencies

- Pixel detection engine for cast bar monitoring
- Hotkey management system for skill execution
- Timing utilities for cooldown tracking
- Configuration system for skill persistence

## Related Modules

- [Rotation Engine](../rotation/README.md) - Skill rotation automation
- [Rule Engine](../rules/README.md) - Conditional skill execution
- [Buff Engine](../buff/README.md) - Buff and effect integration
- [UI System](../../ui/README.md) - Cast debugging interface