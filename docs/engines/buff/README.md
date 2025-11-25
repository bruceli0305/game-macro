# Buff Engine Documentation

The Buff Engine manages buffs, debuffs, and status effects detection and tracking for the Game Macro system.

[English Version](README.md) | [中文版本](../../cn/engines/buff/README.md)

## Overview

The Buff Engine provides:
- Buff/debuff detection via pixel recognition
- Status effect tracking and monitoring
- Buff duration management
- Buff stacking and priority handling
- Integration with skill execution

## Architecture

The engine is designed to work with the rotation and rule systems:

### BuffEngine.ahk (Main Engine)
Main buff detection and management system.

### Integration Points
- **Rotation Engine**: Provides buff state information for rotation decisions
- **Rule Engine**: Offers buff-based condition checking
- **Cast Engine**: Buff-dependent skill execution
- **UI System**: Buff monitoring interface

## Key Components

### Buff Detection System
Manages the detection of buffs and debuffs through pixel recognition.

#### Buff Configuration
```ahk
Buff := {
    Id: 1,
    Name: "Power Boost",
    Type: "buff",
    X: 100,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0xFF0000",
    Tolerance: 10,
    DurationMs: 15000,
    Priority: 1,
    Stackable: false,
    MaxStacks: 1,
    Required: false
}
```

### Status Effect Tracking
Tracks active buffs and their remaining durations.

#### Buff State Structure
```ahk
BuffState := {
    BuffId: 1,
    Name: "Power Boost",
    IsActive: true,
    StartTime: 0,
    EndTime: 15000,
    RemainingMs: 12000,
    Stacks: 1,
    IsExpired: false
}
```

### Buff Priority System
Handles buff priority for rotation decision making.

#### Priority Configuration
```ahk
BuffPriority := {
    High: ["Power Boost", "Critical Strike"],
    Medium: ["Haste", "Attack Power"],
    Low: ["Minor Buffs", "Defensive Cooldowns"]
}
```

## Execution Flow

### Buff Detection Process
1. **Pixel Sampling**: Sample buff icon areas
2. **Color Matching**: Compare with configured colors
3. **State Determination**: Determine buff active/inactive state
4. **Duration Tracking**: Track buff duration if active
5. **State Update**: Update buff state information

### Buff Monitoring Algorithm
1. Periodically check all configured buffs
2. Update active buff states
3. Handle buff expiration
4. Trigger buff-related actions

## API Reference

### Core Functions

#### BuffEngine_Init()
Initializes the buff engine.

**Parameters:** None

**Returns:** Boolean indicating success

#### BuffEngine_DetectBuffs()
Performs buff detection for all configured buffs.

**Parameters:** None

**Returns:** Array of detected buff states

#### BuffEngine_IsBuffActive(buffId)
Checks if a specific buff is active.

**Parameters:**
- `buffId` (Integer): Buff identifier

**Returns:** Boolean indicating buff active state

#### BuffEngine_GetBuffRemaining(buffId)
Gets the remaining duration for a buff.

**Parameters:**
- `buffId` (Integer): Buff identifier

**Returns:** Integer duration in milliseconds

### Buff Management

#### BuffEngine_AddBuff(buffConfig)
Adds a new buff to the detection system.

**Parameters:**
- `buffConfig` (Map): Buff configuration

**Returns:** Buff ID

#### BuffEngine_UpdateBuff(buffId, buffConfig)
Updates an existing buff configuration.

**Parameters:**
- `buffId` (Integer): Buff identifier
- `buffConfig` (Map): Updated buff configuration

**Returns:** Boolean indicating success

#### BuffEngine_RemoveBuff(buffId)
Removes a buff from the detection system.

**Parameters:**
- `buffId` (Integer): Buff identifier

**Returns:** Boolean indicating success

### Buff State Management

#### BuffEngine_GetActiveBuffs()
Gets all currently active buffs.

**Parameters:** None

**Returns:** Array of active buff states

#### BuffEngine_GetBuffState(buffId)
Gets the complete state of a specific buff.

**Parameters:**
- `buffId` (Integer): Buff identifier

**Returns:** Buff state map

#### BuffEngine_ResetBuff(buffId)
Resets the tracking for a specific buff.

**Parameters:**
- `buffId` (Integer): Buff identifier

**Returns:** Boolean indicating success

## Usage Examples

### Basic Buff Configuration
```ahk
; Configure a simple buff
powerBoost := {
    Id: 1,
    Name: "Power Boost",
    Type: "buff",
    X: 100,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0xFF0000",
    Tolerance: 10,
    DurationMs: 15000,
    Priority: 1,
    Stackable: false,
    MaxStacks: 1,
    Required: false
}

BuffEngine_AddBuff(powerBoost)
```

### Debuff Configuration
```ahk
; Configure a debuff
slowDebuff := {
    Id: 2,
    Name: "Slow",
    Type: "debuff",
    X: 150,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0x0000FF",
    Tolerance: 5,
    DurationMs: 10000,
    Priority: 2,
    Stackable: true,
    MaxStacks: 3,
    Required: false
}

BuffEngine_AddBuff(slowDebuff)
```

### Buff Detection in Rotation
```ahk
; Check buff state for rotation decisions
if (BuffEngine_IsBuffActive(powerBoostId)) {
    ; Buff is active, execute high priority skills
    RotationEngine_ExecuteHighPriority()
} else {
    ; Buff not active, execute normal rotation
    RotationEngine_ExecuteNormal()
}
```

### Buff-based Rule Conditions
```ahk
; Create rule based on buff state
rule := {
    Condition: {
        Type: "buff",
        BuffId: powerBoostId,
        Operator: "active",
        Duration: 5000
    },
    Action: {
        Type: "skill",
        SkillId: highDamageSkillId
    }
}

RuleEngine_AddRule(rule)
```

### Buff Monitoring Loop
```ahk
; Continuous buff monitoring
while (App["IsRunning"]) {
    activeBuffs := BuffEngine_DetectBuffs()
    
    ; Process buff states
    for buffState in activeBuffs {
        if (buffState["IsActive"]) {
            remaining := buffState["RemainingMs"]
            Logger_Info("BuffEngine", "Buff active", Map(
                "buffId", buffState["BuffId"],
                "remaining", remaining
            ))
        }
    }
    
    Sleep(100) ; Check every 100ms
}
```

## Configuration Integration

### Profile Integration
Buffs are stored in profile data and loaded with profiles:

```ahk
profile := App["ProfileData"]
profile["Buffs"] := [buff1, buff2, buff3]
```

### Buff Priority Configuration
Buff priorities can be configured per profile:

```ahk
profile["BuffPriority"] := {
    High: ["Power Boost", "Critical Strike"],
    Medium: ["Haste", "Attack Power"],
    Low: ["Minor Buffs", "Defensive Cooldowns"]
}
```

## Performance Considerations

### Optimization Strategies
1. **Selective Detection**: Only detect buffs relevant to current rotation
2. **Detection Frequency**: Adjust detection frequency based on buff duration
3. **Caching**: Cache buff states to reduce detection frequency
4. **Area Optimization**: Optimize pixel sampling areas

### Memory Management
- Buff configurations are validated on add
- Invalid configurations are rejected with error messages
- Buff states are cleaned up on expiration

## Error Handling

The buff engine includes comprehensive error handling:
- Invalid buff configurations
- Pixel detection failures
- State tracking errors
- Priority calculation issues

## Debugging Features

### Buff Debug Interface
The engine provides a debugging interface for real-time monitoring:

```ahk
; Enable buff debugging
BuffEngine_EnableDebug()

; Get debug information
debugInfo := BuffEngine_GetDebugInfo()
```

### Logging Integration
All buff engine activities are logged for troubleshooting:
- Buff detection results
- State changes
- Priority calculations
- Error conditions

## Dependencies

- Pixel detection engine for buff icon recognition
- Timing utilities for duration tracking
- Configuration system for buff persistence
- Rule engine for buff-based conditions

## Related Modules

- [Rotation Engine](../rotation/README.md) - Buff-based rotation decisions
- [Rule Engine](../rules/README.md) - Buff condition checking
- [Cast Engine](../cast/README.md) - Buff-dependent skill execution
- [UI System](../../ui/README.md) - Buff monitoring interface