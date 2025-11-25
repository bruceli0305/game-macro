# Logging Module Documentation

The Logging module provides comprehensive logging functionality for the Game Macro system, including multiple log sinks and flexible configuration.

[English Version](README.md) | [中文版本](../cn/logging/README.md)

## Overview

The Logging module provides:
- Multi-level logging (DEBUG, INFO, WARNING, ERROR)
- Multiple log sinks (File, Memory, Pipe)
- Configurable log formatting
- Log rotation and management
- Performance monitoring integration

## Architecture

The logging system is designed with a flexible sink architecture:

### Logger.ahk (Main Logging Controller)
Main logging management and coordination system.

### Sink Subsystem
Multiple log sink implementations for different destinations.

#### FileSink.ahk
File-based logging with rotation and compression.

#### MemorySink.ahk
In-memory logging for real-time monitoring.

#### PipeSink.ahk
Pipe-based logging for external log processors.

### Integration Points
- **All Modules**: Provides logging services to all system components
- **UI System**: Log display and monitoring interface
- **Configuration System**: Logging configuration management
- **Runtime Module**: Performance logging integration

## Key Components

### Logging Configuration
Configurable logging settings and behavior.

#### Log Configuration Structure
```ahk
LogConfig := {
    Level: "INFO",
    Format: "{timestamp} [{level}] {module}: {message}",
    Sinks: ["File", "Memory"],
    FileConfig: {
        Path: "logs/app.log",
        MaxSize: 10485760, ; 10MB
        MaxFiles: 5,
        Compress: true
    },
    MemoryConfig: {
        MaxEntries: 1000,
        AutoFlush: true
    }
}
```

### Log Entry Structure
Standardized log entry format.

#### Log Entry Format
```ahk
LogEntry := {
    Timestamp: "2024-01-01T12:00:00.000Z",
    Level: "INFO",
    Module: "RotationEngine",
    Message: "Rotation started successfully",
    Data: {},
    ThreadId: 1
}
```

### Log Sink System
Flexible sink architecture for different logging destinations.

#### Sink Interface
```ahk
Sink := {
    Type: "File",
    IsEnabled: true,
    Level: "INFO",
    Write: Func("WriteLogEntry"),
    Flush: Func("FlushSink"),
    Close: Func("CloseSink")
}
```

## Execution Flow

### Log Entry Creation Process
1. **Log Call**: Module calls logging function
2. **Level Check**: Check if log level meets threshold
3. **Entry Creation**: Create structured log entry
4. **Sink Routing**: Route entry to enabled sinks
5. **Entry Processing**: Each sink processes the entry
6. **Completion**: Logging operation complete

### Sink Processing Flow
1. **Entry Reception**: Sink receives log entry
2. **Formatting**: Format entry according to sink configuration
3. **Destination Write**: Write formatted entry to destination
4. **Buffer Management**: Manage internal buffers if applicable
5. **Resource Management**: Handle resource allocation and cleanup

### Log Rotation Process
1. **Size Check**: Check current log file size
2. **Rotation Decision**: Decide if rotation is needed
3. **File Rotation**: Rotate current log file
4. **Archive Management**: Manage archived log files
5. **New File Creation**: Create new log file

## API Reference

### Core Functions

#### Logger_Init(config)
Initializes the logging system.

**Parameters:**
- `config` (Map): Logging configuration

**Returns:** Boolean indicating success

#### Logger_Shutdown()
Shuts down the logging system.

**Parameters:** None

**Returns:** Boolean indicating success

#### Logger_SetLevel(level)
Sets the global log level.

**Parameters:**
- `level` (String): Log level (DEBUG, INFO, WARNING, ERROR)

**Returns:** Boolean indicating success

#### Logger_GetLevel()
Gets the current log level.

**Parameters:** None

**Returns:** Current log level

### Logging Functions

#### Logger_Debug(module, message, data)
Logs a debug message.

**Parameters:**
- `module` (String): Module name
- `message` (String): Log message
- `data` (Map): Additional data (optional)

**Returns:** Boolean indicating success

#### Logger_Info(module, message, data)
Logs an info message.

**Parameters:**
- `module` (String): Module name
- `message` (String): Log message
- `data` (Map): Additional data (optional)

**Returns:** Boolean indicating success

#### Logger_Warning(module, message, data)
Logs a warning message.

**Parameters:**
- `module` (String): Module name
- `message` (String): Log message
- `data` (Map): Additional data (optional)

**Returns:** Boolean indicating success

#### Logger_Error(module, message, data)
Logs an error message.

**Parameters:**
- `module` (String): Module name
- `message` (String): Log message
- `data` (Map): Additional data (optional)

**Returns:** Boolean indicating success

### Sink Management

#### Logger_AddSink(sinkConfig)
Adds a new log sink.

**Parameters:**
- `sinkConfig` (Map): Sink configuration

**Returns:** Sink ID

#### Logger_RemoveSink(sinkId)
Removes a log sink.

**Parameters:**
- `sinkId` (String): Sink identifier

**Returns:** Boolean indicating success

#### Logger_EnableSink(sinkId)
Enables a log sink.

**Parameters:**
- `sinkId` (String): Sink identifier

**Returns:** Boolean indicating success

#### Logger_DisableSink(sinkId)
Disables a log sink.

**Parameters:**
- `sinkId` (String): Sink identifier

**Returns:** Boolean indicating success

### Log Management

#### Logger_GetLogEntries(filter)
Gets log entries with optional filtering.

**Parameters:**
- `filter` (Map): Filter criteria (optional)

**Returns:** Array of log entries

#### Logger_ClearLogs()
Clears all log entries.

**Parameters:** None

**Returns:** Boolean indicating success

#### Logger_Flush()
Flushes all log sinks.

**Parameters:** None

**Returns:** Boolean indicating success

## Usage Examples

### Basic Logging Setup
```ahk
; Initialize logging system
logConfig := {
    Level: "INFO",
    Format: "{timestamp} [{level}] {module}: {message}",
    Sinks: ["File", "Memory"]
}

if (!Logger_Init(logConfig)) {
    MsgBox("Failed to initialize logging system")
    ExitApp(1)
}

; Basic logging
Logger_Info("Main", "Application started successfully")
Logger_Debug("Config", "Configuration loaded", App["Config"])
```

### Advanced Logging Configuration
```ahk
; Advanced logging configuration
advancedConfig := {
    Level: "DEBUG",
    Format: "{timestamp} [{level:5}] {module:15} {message}",
    Sinks: ["File", "Memory", "Pipe"],
    FileConfig: {
        Path: "logs/game-macro.log",
        MaxSize: 10485760, ; 10MB
        MaxFiles: 10,
        Compress: true
    },
    MemoryConfig: {
        MaxEntries: 2000,
        AutoFlush: false
    },
    PipeConfig: {
        PipeName: "GameMacroLogs",
        BufferSize: 4096
    }
}

Logger_Init(advancedConfig)
```

### Module-Specific Logging
```ahk
; Rotation engine logging
RotationEngine_Start() {
    Logger_Info("RotationEngine", "Starting rotation engine")
    
    ; Engine initialization
    if (!Engine_Init()) {
        Logger_Error("RotationEngine", "Failed to initialize engine")
        return false
    }
    
    Logger_Debug("RotationEngine", "Engine initialized successfully")
    return true
}

; Rule engine logging with data
RuleEngine_AddRule(rule) {
    Logger_Info("RuleEngine", "Adding new rule", Map(
        "ruleId", rule["Id"],
        "conditionType", rule["Condition"]["Type"]
    ))
    
    ; Rule validation and addition
    if (ValidateRule(rule)) {
        Rules[rule["Id"]] := rule
        Logger_Debug("RuleEngine", "Rule added successfully")
    } else {
        Logger_Warning("RuleEngine", "Invalid rule rejected")
    }
}
```

### Error Handling with Logging
```ahk
; Comprehensive error handling
HandleSkillExecution(skillId) {
    try {
        Logger_Debug("CastEngine", "Executing skill", Map("skillId", skillId))
        
        if (!CastEngine_IsSkillReady(skillId)) {
            Logger_Warning("CastEngine", "Skill not ready", Map("skillId", skillId))
            return false
        }
        
        result := CastEngine_ExecuteSkill(skillId)
        if (result) {
            Logger_Info("CastEngine", "Skill executed successfully", Map("skillId", skillId))
        } else {
            Logger_Error("CastEngine", "Skill execution failed", Map("skillId", skillId))
        }
        
        return result
    } catch e {
        Logger_Error("CastEngine", "Skill execution error", Map(
            "skillId", skillId,
            "error", e.Message,
            "stack", e.Stack
        ))
        return false
    }
}
```

### Log Management and Monitoring
```ahk
; Log monitoring function
MonitorLogs() {
    ; Get recent error logs
    errorLogs := Logger_GetLogEntries({
        Level: "ERROR",
        Since: Utils_GetTimestamp() - 300000 ; Last 5 minutes
    })
    
    if (errorLogs.Length > 0) {
        Logger_Warning("Monitor", "Errors detected in recent logs", Map("count", errorLogs.Length))
        
        ; Send alert or take action
        for log in errorLogs {
            UI_ShowAlert("Error detected: " . log["Message"])
        }
    }
    
    ; Check log file size
    fileInfo := Logger_GetFileInfo()
    if (fileInfo["Size"] > fileInfo["MaxSize"] * 0.8) {
        Logger_Info("Monitor", "Log file approaching size limit")
    }
}

; Log cleanup
CleanupOldLogs() {
    ; Clear logs older than 7 days
    cutoff := Utils_GetTimestamp() - 7 * 24 * 60 * 60 * 1000
    oldLogs := Logger_GetLogEntries({"Before": cutoff})
    
    if (oldLogs.Length > 0) {
        Logger_Info("Cleanup", "Cleaning up old logs", Map("count", oldLogs.Length))
        Logger_ClearLogs({"Before": cutoff})
    }
}
```

## Configuration Integration

### Logging Settings
Logging settings are configured in the main application:

```ahk
App["LoggingConfig"] := {
    Level: "INFO",
    Format: "{timestamp} [{level}] {module}: {message}",
    Sinks: ["File", "Memory"],
    File: {
        Path: "logs/app.log",
        MaxSize: 10485760,
        MaxFiles: 5,
        Compress: true
    },
    Memory: {
        MaxEntries: 1000
    },
    Performance: {
        EnableMetrics: true,
        SampleInterval: 60000
    }
}
```

### Module-Specific Logging
Individual modules can have specific logging configurations:

```ahk
; Module-specific logging levels
App["ModuleLogLevels"] := {
    "RotationEngine": "DEBUG",
    "CastEngine": "INFO", 
    "BuffEngine": "WARNING",
    "UI": "ERROR"
}
```

## Performance Considerations

### Optimization Strategies
1. **Asynchronous Logging**: Use async operations for file I/O
2. **Batch Processing**: Batch log entries for efficient writing
3. **Memory Management**: Efficient memory usage for in-memory logs
4. **Selective Logging**: Log only necessary information

### Best Practices
- Use appropriate log levels for different scenarios
- Include relevant context data in log entries
- Avoid logging sensitive information
- Regularly monitor and manage log files
- Use structured logging for better analysis

## Error Handling

The logging module includes comprehensive error handling:
- File system errors (permission, disk space)
- Sink initialization failures
- Log formatting errors
- Resource allocation failures
- Graceful degradation when logging fails

## Debugging Features

### Log Debug Interface
The module provides debugging capabilities:

```ahk
; Enable logging debugging
Logger_EnableDebug()

; Get debug information
debugInfo := Logger_GetDebugInfo()

; Test logging functionality
Logger_TestSinks()
```

### Log Analysis Tools
Built-in tools for log analysis:

```ahk
; Analyze log patterns
patterns := Logger_AnalyzePatterns({
    TimeRange: "last-hour",
    Module: "RotationEngine"
})

; Generate log reports
report := Logger_GenerateReport({
    Period: "daily",
    Format: "HTML"
})
```

## Dependencies

- File system utilities for log file management
- Compression libraries for log compression
- Date/time utilities for timestamp formatting
- Configuration system for logging settings

## Related Modules

- [Core Module](../core/README.md) - Application initialization and configuration
- [UI Module](../ui/README.md) - Log display interface
- [Runtime Module](../runtime/README.md) - Performance logging integration
- [Util Module](../util/README.md) - Utility functions for logging operations