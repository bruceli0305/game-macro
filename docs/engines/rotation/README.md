# Rotation Engine Documentation

The Rotation Engine is the core automation system that manages skill rotations, track switching, and complex automation logic.

## Overview

The Rotation Engine provides:
- Multi-track skill rotation management
- Conditional track switching (gates)
- Black screen detection and protection
- Opener sequence management
- Real-time rotation state tracking

## Architecture

The engine is divided into specialized sub-modules:

### Rotation.ahk (Main Aggregator)
Main entry point that includes all sub-modules.

### Sub-Modules
- **Rotation_State.ahk** - Rotation state management
- **Rotation_Config.ahk** - Configuration handling
- **Rotation_Phase.ahk** - Phase management
- **Rotation_BlackGuard.ahk** - Black screen protection
- **Rotation_Watch.ahk** - Watch conditions
- **Rotation_Filter.ahk** - Skill filtering
- **Rotation_Gate.ahk** - Track switching logic
- **Rotation_Opener.ahk** - Opener sequence
- **Rotation_Tick.ahk** - Main execution loop

## Key Components

### Rotation State
Manages the current state of rotation execution.

#### State Structure
```ahk
RotationState := {
    IsRunning: false,
    CurrentTrack: 1,
    LastSkillTime: 0,
    BlackGuard: {
        LastCheck: 0,
        BlackCount: 0,
        IsBlack: false
    },
    Opener: {
        Active: false,
        StartTime: 0,
        CurrentStep: 0
    }
}
```

### Track System
Supports multiple skill tracks with different priorities and conditions.

#### Track Configuration
```ahk
Track := {
    Id: 1,
    Name: "Default Track",
    Skills: [1, 2, 3],  ; Skill indices
    Priority: 1,
    Conditions: [],     ; Activation conditions
    Cooldown: 1000      ; Track cooldown
}
```

### Gate System
Conditional track switching based on game state.

#### Gate Types
- **Pixel-based gates**: Color detection conditions
- **Timer gates**: Time-based switching
- **Skill gates**: Skill cooldown conditions
- **Composite gates**: Multiple condition combinations

#### Gate Configuration
```ahk
Gate := {
    SourceTrack: 1,
    TargetTrack: 2,
    Conditions: [
        {
            Type: "Pixel",
            X: 100,
            Y: 200,
            Color: "0xFF0000",
            Tolerance: 10
        }
    ],
    Priority: 1
}
```

### Black Guard System
Protects against black screen states by detecting and avoiding them.

#### Black Guard Configuration
```ahk
BlackGuard := {
    Enabled: 1,
    SampleCount: 5,
    BlackRatioThresh: 0.7,
    WindowMs: 120,
    CooldownMs: 600,
    MinAfterSendMs: 60,
    MaxAfterSendMs: 800,
    UniqueRequired: 1
}
```

### Opener System
Manages initial skill sequences for combat initiation.

#### Opener Configuration
```ahk
Opener := {
    Enabled: 0,
    MaxDurationMs: 4000,
    Watch: [
        {
            Type: "Skill",
            SkillId: 1,
            Condition: "Ready"
        }
    ],
    Steps: [
        {Skill: 1, Delay: 0},
        {Skill: 2, Delay: 500},
        {Skill: 3, Delay: 1000}
    ]
}
```

## Execution Flow

### Main Tick Loop
1. **State Check**: Verify rotation is active and conditions are met
2. **Black Guard**: Check for black screen conditions
3. **Opener Check**: Handle opener sequence if active
4. **Track Selection**: Determine which track to execute
5. **Skill Selection**: Choose the next skill to cast
6. **Execution**: Send the skill command
7. **State Update**: Update rotation state and timers

### Track Selection Algorithm
1. Check active opener sequence
2. Evaluate gate conditions for track switching
3. Select highest priority valid track
4. Apply track cooldown constraints
5. Execute selected track's skills

## API Reference

### Core Functions

#### Rotation_Start()
Starts the rotation engine.

**Parameters:** None

**Returns:** Boolean indicating success

#### Rotation_Stop()
Stops the rotation engine.

**Parameters:** None

**Returns:** Boolean indicating success

#### Rotation_IsRunning()
Checks if the rotation engine is active.

**Parameters:** None

**Returns:** Boolean indicating running state

### Track Management

#### Rotation_AddTrack(trackConfig)
Adds a new skill track.

**Parameters:**
- `trackConfig` (Map): Track configuration

**Returns:** Track ID

#### Rotation_RemoveTrack(trackId)
Removes a skill track.

**Parameters:**
- `trackId` (Integer): Track identifier

**Returns:** Boolean indicating success

### Gate Management

#### Rotation_AddGate(gateConfig)
Adds a new track switching gate.

**Parameters:**
- `gateConfig` (Map): Gate configuration

**Returns:** Gate ID

#### Rotation_EvaluateGates()
Evaluates all gate conditions for track switching.

**Parameters:** None

**Returns:** New track ID if switching should occur

## Configuration

### Rotation Configuration Structure
```ahk
RotationConfig := {
    Enabled: 0,
    DefaultTrackId: 1,
    SwapKey: "",
    BusyWindowMs: 200,
    ColorTolBlack: 16,
    RespectCastLock: 1,
    BlackGuard: { ... },
    Opener: { ... }
}
```

### Skill Configuration Integration
Skills are configured separately and referenced by index in tracks.

## Usage Examples

### Basic Rotation Setup
```ahk
; Configure skills first
skills := [
    {Name: "Skill 1", Key: "1", X: 100, Y: 200, Color: "0xFF0000", Tol: 10},
    {Name: "Skill 2", Key: "2", X: 150, Y: 200, Color: "0x00FF00", Tol: 10}
]

; Create a simple track
track := {
    Id: 1,
    Name: "Basic Rotation",
    Skills: [1, 2],  ; Reference skill indices
    Priority: 1
}

; Add track to rotation
Rotation_AddTrack(track)

; Start rotation
Rotation_Start()
```

### Advanced Gate Configuration
```ahk
; Create a gate that switches tracks based on pixel color
gate := {
    SourceTrack: 1,
    TargetTrack: 2,
    Conditions: [
        {
            Type: "Pixel",
            X: 300,
            Y: 400,
            Color: "0x0000FF",
            Tolerance: 5,
            Operator: "Equals"
        }
    ]
}

Rotation_AddGate(gate)
```

## Error Handling

The rotation engine includes comprehensive error handling:
- Invalid track configurations
- Missing skill references
- Pixel detection failures
- Timing and cooldown violations

## Performance Considerations

### Optimization Tips
1. Use appropriate poll intervals
2. Minimize pixel sampling frequency
3. Cache frequently accessed configurations
4. Use efficient condition evaluation

### Memory Management
- Rotation state is cleared on stop
- Track configurations are validated
- Resources are properly released

## Dependencies

- Pixel detection engine for color sampling
- Skill management system
- Configuration system
- Timing and polling utilities

## Related Modules

- [Rule Engine](../rules/README.md) - Conditional rule processing
- [Cast Engine](../cast/README.md) - Skill execution
- [Buff Engine](../buff/README.md) - Buff and effect tracking