# Workers Module Documentation

The Workers module manages background tasks, asynchronous operations, and specialized worker threads for the Game Macro system.

[English Version](README.md) | [中文版本](../cn/workers/README.md)

## Overview

The Workers module provides:
- Background task execution
- Asynchronous operation management
- Specialized worker threads
- Resource isolation and management
- Performance optimization through parallel processing

## Architecture

The workers system is designed for specialized background operations:

### Workers.ahk (Main Worker Manager)
Main worker management and coordination system.

### Integration Points
- **Runtime Module**: Worker thread lifecycle management
- **Engines**: Specialized workers for engine operations
- **UI System**: Worker status monitoring
- **Configuration System**: Worker configuration management

## Key Components

### Worker Thread Management
Manages specialized worker threads for different tasks.

#### Worker Configuration
```ahk
Worker := {
    Id: 1,
    Name: "PixelDetectionWorker",
    Type: "Background",
    Priority: "Normal",
    IntervalMs: 50,
    IsRunning: false,
    LastRunTime: 0,
    ErrorCount: 0,
    ResourceUsage: {
        CPU: 5.2,
        Memory: 15.3
    },
    Dependencies: ["PixelEngine"]
}
```

### Background Task System
Manages long-running background tasks.

#### Task Configuration
```ahk
BackgroundTask := {
    Id: 1,
    Name: "ProfileAutoSave",
    Type: "Periodic",
    IntervalMs: 30000,
    IsEnabled: true,
    LastExecution: 0,
    ExecutionCount: 0,
    Function: "AutoSaveProfiles",
    Parameters: {}
}
```

### Asynchronous Operation System
Manages asynchronous operations with callbacks.

#### Async Operation Structure
```ahk
AsyncOperation := {
    Id: 1,
    Name: "ImageProcessing",
    Type: "Async",
    Status: "Pending",
    StartTime: 0,
    EndTime: 0,
    Result: {},
    Callback: "ProcessImageComplete",
    ErrorHandler: "ProcessImageError"
}
```

## Execution Flow

### Worker Thread Lifecycle
1. **Worker Creation**: Create worker with specific configuration
2. **Resource Allocation**: Allocate required resources
3. **Thread Start**: Start worker thread execution
4. **Task Execution**: Execute assigned tasks
5. **Resource Cleanup**: Clean up resources on stop
6. **Thread Termination**: Gracefully terminate worker thread

### Background Task Execution
1. **Task Scheduling**: Schedule task based on interval
2. **Pre-execution Checks**: Validate task conditions
3. **Task Execution**: Execute the task function
4. **Post-execution**: Handle results and cleanup
5. **Reschedule**: Schedule next execution

### Asynchronous Operation Flow
1. **Operation Creation**: Create async operation
2. **Execution Start**: Start async execution
3. **Progress Monitoring**: Monitor operation progress
4. **Completion Handling**: Handle operation completion
5. **Callback Execution**: Execute completion callback

## API Reference

### Core Functions

#### Workers_Init()
Initializes the workers system.

**Parameters:** None

**Returns:** Boolean indicating success

#### Workers_Start()
Starts all enabled workers.

**Parameters:** None

**Returns:** Boolean indicating success

#### Workers_Stop()
Stops all workers.

**Parameters:** None

**Returns:** Boolean indicating success

#### Workers_Pause()
Pauses all workers.

**Parameters:** None

**Returns:** Boolean indicating success

#### Workers_Resume()
Resumes all workers.

**Parameters:** None

**Returns:** Boolean indicating success

### Worker Management

#### Workers_CreateWorker(workerConfig)
Creates a new worker.

**Parameters:**
- `workerConfig` (Map): Worker configuration

**Returns:** Worker ID

#### Workers_StartWorker(workerId)
Starts a specific worker.

**Parameters:**
- `workerId` (Integer): Worker identifier

**Returns:** Boolean indicating success

#### Workers_StopWorker(workerId)
Stops a specific worker.

**Parameters:**
- `workerId` (Integer): Worker identifier

**Returns:** Boolean indicating success

#### Workers_GetWorkerState(workerId)
Gets the state of a specific worker.

**Parameters:**
- `workerId` (Integer): Worker identifier

**Returns:** Worker state map

### Background Task Management

#### Workers_AddBackgroundTask(taskConfig)
Adds a new background task.

**Parameters:**
- `taskConfig` (Map): Task configuration

**Returns:** Task ID

#### Workers_RemoveBackgroundTask(taskId)
Removes a background task.

**Parameters:**
- `taskId` (Integer): Task identifier

**Returns:** Boolean indicating success

#### Workers_ExecuteBackgroundTask(taskId)
Executes a background task immediately.

**Parameters:**
- `taskId` (Integer): Task identifier

**Returns:** Boolean indicating success

### Asynchronous Operations

#### Workers_CreateAsyncOperation(opConfig)
Creates a new async operation.

**Parameters:**
- `opConfig` (Map): Operation configuration

**Returns:** Operation ID

#### Workers_StartAsyncOperation(opId)
Starts an async operation.

**Parameters:**
- `opId` (Integer): Operation identifier

**Returns:** Boolean indicating success

#### Workers_GetAsyncOperationStatus(opId)
Gets the status of an async operation.

**Parameters:**
- `opId` (Integer): Operation identifier

**Returns:** Operation status map

## Usage Examples

### Basic Worker Creation
```ahk
; Create a pixel detection worker
pixelWorker := {
    Id: 1,
    Name: "PixelDetectionWorker",
    Type: "Background",
    Priority: "High",
    IntervalMs: 50,
    Dependencies: ["PixelEngine"]
}

workerId := Workers_CreateWorker(pixelWorker)

; Start the worker
if (Workers_StartWorker(workerId)) {
    Logger_Info("Workers", "Pixel detection worker started", Map("workerId", workerId))
}
```

### Background Task for Auto-Save
```ahk
; Create auto-save background task
autoSaveTask := {
    Id: 1,
    Name: "ProfileAutoSave",
    Type: "Periodic",
    IntervalMs: 30000, ; 30 seconds
    IsEnabled: true,
    Function: "AutoSaveProfiles",
    Parameters: {}
}

taskId := Workers_AddBackgroundTask(autoSaveTask)

; Auto-save function
AutoSaveProfiles() {
    if (App["ProfileData"]["IsModified"]) {
        Storage_SaveProfile(App["CurrentProfile"])
        Logger_Info("Workers", "Profile auto-saved")
    }
}
```

### Asynchronous Image Processing
```ahk
; Create async image processing operation
imageOp := {
    Id: 1,
    Name: "ImageProcessing",
    Type: "Async",
    Callback: "ProcessImageComplete",
    ErrorHandler: "ProcessImageError"
}

opId := Workers_CreateAsyncOperation(imageOp)

; Start the operation
Workers_StartAsyncOperation(opId)

; Callback functions
ProcessImageComplete(result) {
    Logger_Info("Workers", "Image processing completed", result)
    UI_UpdateImage(result["ProcessedImage"])
}

ProcessImageError(error) {
    Logger_Error("Workers", "Image processing failed", error)
    UI_ShowError("Image processing error")
}
```

### Worker with Resource Monitoring
```ahk
; Worker with resource monitoring
resourceWorker := {
    Id: 2,
    Name: "ResourceMonitor",
    Type: "Monitoring",
    Priority: "Low",
    IntervalMs: 1000,
    Dependencies: []
}

resourceId := Workers_CreateWorker(resourceWorker)

; Worker function with resource monitoring
Workers_RegisterWorkerFunction(resourceId, Func("MonitorResources"))

MonitorResources() {
    ; Monitor system resources
    cpuUsage := GetCPUUsage()
    memoryUsage := GetMemoryUsage()
    
    ; Log resource usage
    Logger_Debug("Workers", "Resource usage", Map(
        "CPU", cpuUsage,
        "Memory", memoryUsage
    ))
    
    ; Adjust worker priorities based on resource usage
    if (cpuUsage > 80) {
        Workers_AdjustPriorities("Low")
    }
}
```

### Error Handling in Workers
```ahk
; Worker with error handling
errorWorker := {
    Id: 3,
    Name: "ErrorHandlingWorker",
    Type: "ErrorRecovery",
    Priority: "Normal",
    IntervalMs: 5000,
    Dependencies: []
}

errorId := Workers_CreateWorker(errorWorker)

; Error handling function
Workers_RegisterWorkerFunction(errorId, Func("HandleWorkerErrors"))

HandleWorkerErrors() {
    ; Check for worker errors
    errorWorkers := Workers_GetErrorWorkers()
    
    for worker in errorWorkers {
        Logger_Warning("Workers", "Worker error detected", Map(
            "workerId", worker["Id"],
            "errorCount", worker["ErrorCount"]
        ))
        
        ; Attempt recovery
        if (worker["ErrorCount"] < 3) {
            Workers_RestartWorker(worker["Id"])
        } else {
            ; Too many errors, disable worker
            Workers_StopWorker(worker["Id"])
            Logger_Error("Workers", "Worker disabled due to errors", Map("workerId", worker["Id"]))
        }
    }
}
```

## Configuration Integration

### Worker Settings
Worker settings are stored in the main configuration:

```ahk
App["WorkerConfig"] := {
    MaxWorkers: 5,
    DefaultInterval: 100,
    ResourceMonitoring: true,
    AutoRecovery: true,
    MaxErrorCount: 3
}
```

### Worker-Specific Configuration
Worker configurations can be profile-specific:

```ahk
profile["Workers"] := [
    {
        Name: "PixelDetection",
        Interval: 50,
        Priority: "High",
        Enabled: true
    },
    {
        Name: "ResourceMonitor",
        Interval: 1000,
        Priority: "Low",
        Enabled: true
    }
]
```

## Performance Considerations

### Optimization Strategies
1. **Worker Prioritization**: Assign appropriate priorities based on task importance
2. **Execution Interval Optimization**: Balance performance and responsiveness
3. **Resource Management**: Efficient resource allocation and cleanup
4. **Error Recovery**: Fast error recovery with minimal disruption

### Memory Management
- Worker resources are properly allocated and released
- Background tasks are managed efficiently
- Async operations are cleaned up after completion

## Error Handling

The workers module includes comprehensive error handling:
- Worker crash detection and recovery
- Background task error handling
- Async operation failure management
- Resource allocation errors

## Debugging Features

### Worker Debug Interface
The module provides a debugging interface for real-time monitoring:

```ahk
; Enable worker debugging
Workers_EnableDebug()

; Get debug information
debugInfo := Workers_GetDebugInfo()
```

### Logging Integration
All worker activities are logged for troubleshooting:
- Worker lifecycle events
- Background task executions
- Async operation status changes
- Error conditions and recovery attempts

## Dependencies

- Runtime module for thread management
- Engine modules for specialized worker operations
- UI system for worker status display
- Configuration system for worker settings

## Related Modules

- [Runtime Module](../runtime/README.md) - Thread lifecycle management
- [Engines](../engines/README.md) - Engine-specific workers
- [UI Module](../ui/README.md) - Worker status monitoring
- [Core Module](../core/README.md) - Core application functionality