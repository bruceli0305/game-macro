# Runtime Module Documentation

The Runtime module manages the application's execution lifecycle, thread management, and real-time operation control.

[English Version](README.md) | [中文版本](../cn/runtime/README.md)

## Overview

The Runtime module provides:
- Application lifecycle management
- Multi-threaded execution control
- Real-time operation monitoring
- Performance optimization
- Error handling and recovery

## Architecture

The runtime system coordinates all engine components:

### Runtime.ahk (Main Runtime Controller)
Main runtime management and coordination system.

### Integration Points
- **All Engines**: Coordinates execution across all engine modules
- **UI System**: Provides runtime status and control interface
- **Configuration System**: Manages runtime settings
- **Logging System**: Runtime activity logging

## Key Components

### Application Lifecycle Management
Manages the complete application lifecycle from startup to shutdown.

#### Runtime States
```ahk
RuntimeState := {
    IsInitialized: false,
    IsRunning: false,
    IsPaused: false,
    IsStopping: false,
    StartTime: 0,
    UptimeMs: 0,
    ThreadCount: 0,
    ActiveEngines: []
}
```

### Thread Management System
Manages multiple execution threads for parallel processing.

#### Thread Configuration
```ahk
Thread := {
    Id: 1,
    Name: "MainRotation",
    Priority: "Normal",
    IntervalMs: 100,
    IsRunning: false,
    LastRunTime: 0,
    ErrorCount: 0,
    EngineDependencies: ["RotationEngine", "CastEngine"]
}
```

### Performance Monitoring
Tracks runtime performance metrics.

#### Performance Metrics
```ahk
PerformanceMetrics := {
    FPS: 60,
    CPUUsage: 15.5,
    MemoryUsage: 102.4,
    ThreadLatency: [5, 8, 12],
    EnginePerformance: {
        RotationEngine: 2.1,
        CastEngine: 1.8,
        BuffEngine: 0.9
    }
}
```

## Execution Flow

### Application Startup Process
1. **Initialization**: Load configuration and initialize all modules
2. **Engine Setup**: Initialize all engine components
3. **Thread Creation**: Create execution threads
4. **UI Initialization**: Initialize user interface
5. **Runtime Start**: Begin main execution loop

### Thread Execution Cycle
1. **Pre-execution Checks**: Validate thread conditions
2. **Engine Coordination**: Coordinate engine execution
3. **Error Handling**: Handle any execution errors
4. **Performance Monitoring**: Update performance metrics
5. **Thread Sleep**: Wait for next execution cycle

### Application Shutdown Process
1. **Stop Signal**: Send stop signal to all threads
2. **Thread Termination**: Gracefully terminate all threads
3. **Engine Cleanup**: Clean up all engine resources
4. **Configuration Save**: Save current configuration
5. **Application Exit**: Final cleanup and exit

## API Reference

### Core Functions

#### Runtime_Init()
Initializes the runtime system.

**Parameters:** None

**Returns:** Boolean indicating success

#### Runtime_Start()
Starts the main runtime execution.

**Parameters:** None

**Returns:** Boolean indicating success

#### Runtime_Stop()
Stops the runtime execution.

**Parameters:** None

**Returns:** Boolean indicating success

#### Runtime_Pause()
Pauses the runtime execution.

**Parameters:** None

**Returns:** Boolean indicating success

#### Runtime_Resume()
Resumes the runtime execution.

**Parameters:** None

**Returns:** Boolean indicating success

### Thread Management

#### Runtime_CreateThread(threadConfig)
Creates a new execution thread.

**Parameters:**
- `threadConfig` (Map): Thread configuration

**Returns:** Thread ID

#### Runtime_StartThread(threadId)
Starts a specific thread.

**Parameters:**
- `threadId` (Integer): Thread identifier

**Returns:** Boolean indicating success

#### Runtime_StopThread(threadId)
Stops a specific thread.

**Parameters:**
- `threadId` (Integer): Thread identifier

**Returns:** Boolean indicating success

#### Runtime_GetThreadState(threadId)
Gets the state of a specific thread.

**Parameters:**
- `threadId` (Integer): Thread identifier

**Returns:** Thread state map

### Performance Monitoring

#### Runtime_GetPerformanceMetrics()
Gets current performance metrics.

**Parameters:** None

**Returns:** Performance metrics map

#### Runtime_GetEnginePerformance(engineName)
Gets performance metrics for a specific engine.

**Parameters:**
- `engineName` (String): Engine name

**Returns:** Engine performance metrics

#### Runtime_ResetPerformanceMetrics()
Resets performance metrics.

**Parameters:** None

**Returns:** Boolean indicating success

## Usage Examples

### Basic Runtime Initialization
```ahk
; Initialize runtime system
if (!Runtime_Init()) {
    Logger_Error("Runtime", "Failed to initialize runtime system")
    ExitApp(1)
}

; Start runtime execution
if (!Runtime_Start()) {
    Logger_Error("Runtime", "Failed to start runtime")
    ExitApp(1)
}
```

### Thread Creation and Management
```ahk
; Create a rotation thread
rotationThread := {
    Id: 1,
    Name: "MainRotation",
    Priority: "Normal",
    IntervalMs: 100,
    EngineDependencies: ["RotationEngine", "CastEngine", "BuffEngine"]
}

threadId := Runtime_CreateThread(rotationThread)

; Start the thread
if (Runtime_StartThread(threadId)) {
    Logger_Info("Runtime", "Rotation thread started", Map("threadId", threadId))
}
```

### Runtime Control with UI Integration
```ahk
; Handle UI control events
UI_RegisterControl("startButton", "Runtime_Start")
UI_RegisterControl("stopButton", "Runtime_Stop")
UI_RegisterControl("pauseButton", "Runtime_Pause")
UI_RegisterControl("resumeButton", "Runtime_Resume")

; Update UI with runtime status
UI_UpdateStatus("runtimeStatus", Runtime_GetState())
```

### Performance Monitoring Loop
```ahk
; Performance monitoring thread
monitoringThread := {
    Id: 2,
    Name: "PerformanceMonitor",
    Priority: "Low",
    IntervalMs: 1000,
    EngineDependencies: []
}

monitorId := Runtime_CreateThread(monitoringThread)

; Monitoring function
Runtime_RegisterThreadFunction(monitorId, Func("MonitorPerformance"))

MonitorPerformance() {
    metrics := Runtime_GetPerformanceMetrics()
    
    ; Log performance metrics
    Logger_Debug("Runtime", "Performance metrics", metrics)
    
    ; Update UI with performance data
    UI_UpdatePerformance(metrics)
    
    ; Check for performance issues
    if (metrics["CPUUsage"] > 80) {
        Logger_Warning("Runtime", "High CPU usage detected", metrics)
    }
}
```

### Error Handling and Recovery
```ahk
; Error handling in thread execution
Runtime_RegisterErrorHandler(Func("HandleRuntimeError"))

HandleRuntimeError(errorInfo) {
    Logger_Error("Runtime", "Runtime error occurred", errorInfo)
    
    ; Attempt recovery based on error type
    switch errorInfo["Type"] {
        case "ThreadCrash":
            ; Restart crashed thread
            Runtime_RestartThread(errorInfo["ThreadId"])
        case "EngineFailure":
            ; Reinitialize failed engine
            Engine_Reinitialize(errorInfo["EngineName"])
        case "PerformanceDegradation":
            ; Adjust thread priorities
            Runtime_AdjustThreadPriorities()
    }
}
```

## Configuration Integration

### Runtime Settings
Runtime settings are stored in the main configuration:

```ahk
App["RuntimeConfig"] := {
    ThreadCount: 3,
    DefaultInterval: 100,
    PerformanceMonitoring: true,
    AutoRecovery: true,
    MaxErrorCount: 10
}
```

### Thread Configuration
Thread configurations are part of profile data:

```ahk
profile["Threads"] := [
    {
        Name: "RotationThread",
        Interval: 100,
        Engines: ["Rotation", "Cast", "Buff"]
    },
    {
        Name: "DetectionThread", 
        Interval: 50,
        Engines: ["Pixel", "Timer"]
    }
]
```

## Performance Considerations

### Optimization Strategies
1. **Thread Prioritization**: Assign appropriate priorities to threads
2. **Execution Interval Optimization**: Adjust intervals based on requirements
3. **Resource Management**: Efficient resource allocation and cleanup
4. **Error Recovery**: Fast error recovery mechanisms

### Memory Management
- Thread resources are properly allocated and released
- Engine dependencies are managed efficiently
- Performance metrics are optimized for minimal overhead

## Error Handling

The runtime module includes comprehensive error handling:
- Thread crash detection and recovery
- Engine failure handling
- Performance degradation detection
- Resource allocation errors

## Debugging Features

### Runtime Debug Interface
The module provides a debugging interface for real-time monitoring:

```ahk
; Enable runtime debugging
Runtime_EnableDebug()

; Get debug information
debugInfo := Runtime_GetDebugInfo()
```

### Logging Integration
All runtime activities are logged for troubleshooting:
- Thread lifecycle events
- Performance metrics
- Error conditions and recovery attempts
- Engine coordination activities

## Dependencies

- All engine modules for coordinated execution
- UI system for status display and control
- Configuration system for runtime settings
- Logging system for activity tracking

## Related Modules

- [Core Module](../core/README.md) - Application core functionality
- [UI Module](../ui/README.md) - Runtime control interface
- [Engines](../engines/README.md) - All engine modules coordinated by runtime
- [Workers](../workers/README.md) - Worker thread management