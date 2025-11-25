# Rule Engine Documentation

The Rule Engine provides a flexible system for creating conditional automation rules that can trigger actions based on game state conditions.

## Overview

The Rule Engine enables:
- Conditional automation based on game state
- Complex condition combinations
- Priority-based rule execution
- Real-time condition evaluation
- Extensible condition types

## Architecture

The engine is designed with modularity in mind:

### RuleEngine.ahk (Main Engine)
Main rule processing and management.

### Condition Types
- **Pixel Conditions**: Color detection at specific coordinates
- **Timer Conditions**: Time-based triggers
- **Skill Conditions**: Skill state and cooldown checks
- **Composite Conditions**: Multiple condition combinations

## Key Components

### Rule Structure
Each rule consists of conditions and actions.

#### Rule Configuration
```ahk
Rule := {
    Id: 1,
    Name: "Health Low Rule",
    Enabled: true,
    Priority: 1,
    CooldownMs: 1000,
    LastTrigger: 0,
    Conditions: [
        {
            Type: "Pixel",
            X: 500,
            Y: 300,
            Color: "0xFF0000",
            Tolerance: 10,
            Operator: "Equals"
        }
    ],
    Actions: [
        {
            Type: "Skill",
            SkillId: 5,
            DelayMs: 0
        }
    ]
}
```

### Condition System
Supports various condition types for flexible rule creation.

#### Pixel Condition
```ahk
PixelCondition := {
    Type: "Pixel",
    X: 100,
    Y: 200,
    Color: "0xRRGGBB",
    Tolerance: 5,
    Operator: "Equals" | "NotEquals" | "GreaterThan" | "LessThan"
}
```

#### Timer Condition
```ahk
TimerCondition := {
    Type: "Timer",
    IntervalMs: 5000,
    LastTrigger: 0,
    OneShot: false
}
```

#### Skill Condition
```ahk
SkillCondition := {
    Type: "Skill",
    SkillId: 1,
    CheckType: "Ready" | "Cooldown" | "Active",
    Value: 0  ; Cooldown remaining or threshold
}
```

#### Composite Condition
```ahk
CompositeCondition := {
    Type: "Composite",
    Operator: "AND" | "OR" | "NOT",
    Conditions: [
        { ... },  // Sub-condition 1
        { ... }   // Sub-condition 2
    ]
}
```

### Action System
Defines what happens when rule conditions are met.

#### Skill Action
```ahk
SkillAction := {
    Type: "Skill",
    SkillId: 1,
    DelayMs: 0,
    ThreadId: 1
}
```

#### Key Action
```ahk
KeyAction := {
    Type: "Key",
    Key: "F1",
    DelayMs: 0
}
```

#### Script Action
```ahk
ScriptAction := {
    Type: "Script",
    Script: "MyFunction()",
    DelayMs: 0
}
```

## Execution Flow

### Rule Evaluation Process
1. **Rule Filtering**: Filter enabled rules and check cooldowns
2. **Condition Evaluation**: Evaluate all conditions for each rule
3. **Priority Sorting**: Sort rules by priority
4. **Action Execution**: Execute actions for triggered rules
5. **State Update**: Update rule timers and state

### Condition Evaluation Algorithm
1. Parse condition type
2. Gather required data (pixel colors, skill states, etc.)
3. Apply condition operator
4. Return evaluation result

## API Reference

### Core Functions

#### RuleEngine_Init()
Initializes the rule engine.

**Parameters:** None

**Returns:** Boolean indicating success

#### RuleEngine_AddRule(ruleConfig)
Adds a new rule to the engine.

**Parameters:**
- `ruleConfig` (Map): Rule configuration

**Returns:** Rule ID

#### RuleEngine_RemoveRule(ruleId)
Removes a rule from the engine.

**Parameters:**
- `ruleId` (Integer): Rule identifier

**Returns:** Boolean indicating success

#### RuleEngine_EvaluateRules()
Evaluates all rules and executes triggered actions.

**Parameters:** None

**Returns:** Number of rules triggered

### Condition Management

#### RuleEngine_RegisterConditionType(typeName, evalFunc)
Registers a new condition type.

**Parameters:**
- `typeName` (String): Condition type identifier
- `evalFunc` (Function): Evaluation function

**Returns:** Boolean indicating success

#### RuleEngine_EvaluateCondition(condition)
Evaluates a single condition.

**Parameters:**
- `condition` (Map): Condition configuration

**Returns:** Boolean evaluation result

### Action Management

#### RuleEngine_RegisterActionType(typeName, execFunc)
Registers a new action type.

**Parameters:**
- `typeName` (String): Action type identifier
- `execFunc` (Function): Execution function

**Returns:** Boolean indicating success

#### RuleEngine_ExecuteAction(action)
Executes a single action.

**Parameters:**
- `action` (Map): Action configuration

**Returns:** Boolean indicating success

## Usage Examples

### Basic Health Monitoring Rule
```ahk
; Create a rule that uses a health potion when health is low
healthRule := {
    Id: 1,
    Name: "Use Health Potion",
    Enabled: true,
    Priority: 10,
    CooldownMs: 30000,
    Conditions: [
        {
            Type: "Pixel",
            X: 400,
            Y: 250,
            Color: "0xFF0000",
            Tolerance: 5,
            Operator: "Equals"
        }
    ],
    Actions: [
        {
            Type: "Key",
            Key: "5",  ; Health potion hotkey
            DelayMs: 100
        }
    ]
}

RuleEngine_AddRule(healthRule)
```

### Complex Composite Rule
```ahk
; Rule that triggers only when multiple conditions are met
compositeRule := {
    Id: 2,
    Name: "Boss Phase Change",
    Enabled: true,
    Priority: 5,
    Conditions: [
        {
            Type: "Composite",
            Operator: "AND",
            Conditions: [
                {
                    Type: "Pixel",
                    X: 600,
                    Y: 300,
                    Color: "0x00FF00",
                    Tolerance: 10
                },
                {
                    Type: "Timer",
                    IntervalMs: 10000,
                    OneShot: true
                }
            ]
        }
    ],
    Actions: [
        {
            Type: "Skill",
            SkillId: 8,
            DelayMs: 0
        }
    ]
}
```

### Custom Condition Type
```ahk
; Register a custom condition type for buff detection
RuleEngine_RegisterConditionType("Buff", BuffCondition_Evaluate)

BuffCondition_Evaluate(condition) {
    ; Custom buff detection logic
    buffActive := CheckBuff(condition["BuffId"])
    return buffActive
}

; Use the custom condition
buffRule := {
    Conditions: [
        {
            Type: "Buff",
            BuffId: 123
        }
    ],
    Actions: [ ... ]
}
```

## Configuration Integration

### Profile Integration
Rules are stored in profile data and loaded with profiles:

```ahk
profile := App["ProfileData"]
profile["Rules"] := [rule1, rule2, rule3]
```

### Rule Persistence
Rules are automatically saved with profile data and restored on load.

## Performance Considerations

### Optimization Strategies
1. **Condition Caching**: Cache expensive condition evaluations
2. **Priority Sorting**: Evaluate high-priority rules first
3. **Early Termination**: Stop evaluation when rule triggers
4. **Cooldown Management**: Skip recently triggered rules

### Memory Management
- Rule configurations are validated on add
- Invalid rules are rejected with error messages
- Resources are cleaned up on rule removal

## Error Handling

The rule engine includes comprehensive error handling:
- Invalid condition configurations
- Missing action implementations
- Evaluation failures
- Resource allocation errors

## Extensibility

The engine is designed for easy extension:

### Adding New Condition Types
1. Implement evaluation function
2. Register with `RuleEngine_RegisterConditionType()`
3. Use in rule configurations

### Adding New Action Types
1. Implement execution function
2. Register with `RuleEngine_RegisterActionType()`
3. Use in rule configurations

## Dependencies

- Pixel detection engine for color conditions
- Skill management system for skill conditions
- Timing utilities for timer conditions
- Configuration system for rule persistence

## Related Modules

- [Rotation Engine](../rotation/README.md) - Skill rotation automation
- [Buff Engine](../buff/README.md) - Buff and effect tracking
- [Cast Engine](../cast/README.md) - Skill execution system