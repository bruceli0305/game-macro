# DXGI Duplication Engine Documentation

The DXGI Duplication Engine provides high-performance screen capture capabilities using DirectX Graphics Infrastructure (DXGI) for the Game Macro system, offering hardware-accelerated pixel detection with optimal performance.

## Overview

The DXGI Duplication Engine provides:
- Hardware-accelerated screen capture via DirectX
- Multi-monitor support with automatic output selection
- Dynamic frame rate adjustment based on polling intervals
- Robust error handling and fallback mechanisms
- Performance monitoring and statistics
- Remote session detection and compatibility

## Architecture

The DXGI engine leverages DirectX Graphics Infrastructure for maximum performance:

### Dup.ahk (Main Engine)
High-level DXGI duplication management and integration.

### dxgi_dup.dll (Native Library)
C++ native library providing low-level DXGI duplication functionality.

### Integration Points
- **Pixel Engine**: Primary pixel detection source
- **Configuration System**: Dynamic FPS adjustment
- **Runtime System**: Thread-safe operation management
- **Logging System**: Performance monitoring and error reporting

## Key Components

### DXGI Configuration System
Manages DXGI engine settings and behavior.

#### Global DXGI Configuration
```ahk
global gDX := {
    Enabled: true,                 ; Master switch
    Ready: false,                  ; DXGI ready state
    OutIdx: 0,                    ; Current output index (0-based)
    FPS: 60,                      ; Current frame rate
    MonName: "",                  ; Monitor name
    L: 0, T: 0, R: 0, B: 0,      ; Monitor boundaries
    Debug: true,                  ; Debug mode
    Stats: {                      ; Performance statistics
        FrameNo: 0,               ; Frame counter
        Dx: 0,                    ; DXGI path usage
        Roi: 0,                   ; ROI path usage
        Gdi: 0,                   ; GDI path usage
        LastPath: "",            ; Last detection path
        LastLog: 0,               ; Last log frame
        LastReady: -1             ; Last ready state
    }
}
```

### Environment Detection System
Detects runtime environment and compatibility.

#### Environment Information
```ahk
EnvironmentInfo := {
    Architecture: "x64",          ; Process architecture
    AdminRights: true,            ; Administrator privileges
    RemoteSession: false,         ; Remote desktop session
    OSVersion: "10.0.19041",     ; Operating system version
    ScreenCount: 2,               ; Number of monitors
    PrimaryMonitor: "\\\\.\\DISPLAY1"  ; Primary monitor name
}
```

### Output Management System
Handles multi-monitor configuration and selection.

#### Output Information
```ahk
OutputInfo := {
    Index: 0,                     ; Output index (0-based)
    Name: "\\\\.\\DISPLAY1",        ; Output name
    Width: 1920,                  ; Output width
    Height: 1080,                 ; Output height
    Left: 0,                      ; Left boundary
    Top: 0,                       ; Top boundary
    Right: 1919,                 ; Right boundary
    Bottom: 1079,                ; Bottom boundary
    Primary: true                 ; Primary output flag
}
```

## Execution Flow

### Initialization Process
1. **Environment Check**: Detect remote sessions and compatibility
2. **Output Enumeration**: Discover available display outputs
3. **FPS Calculation**: Determine optimal frame rate from polling interval
4. **Output Selection**: Choose best output based on configuration
5. **DXGI Initialization**: Initialize DirectX duplication
6. **Monitor Detection**: Detect monitor boundaries and properties
7. **Ready State**: Set engine ready state

### Pixel Detection Process
1. **Ready Check**: Verify DXGI is ready and enabled
2. **Coordinate Mapping**: Convert screen coordinates to output coordinates
3. **Boundary Validation**: Check if coordinates are within current output
4. **Pixel Retrieval**: Use DXGI duplication to get pixel color
5. **Error Handling**: Handle out-of-bounds or unavailable scenarios

### Frame Management Process
1. **Frame Begin**: Start new frame processing
2. **Path Statistics**: Reset detection path counters
3. **Ready State Monitoring**: Track DXGI availability changes
4. **Performance Logging**: Log performance data at intervals
5. **Frame Completion**: Complete frame processing

## API Reference

### Core Initialization Functions

#### Dup_InitAuto(outputIdx, fps)
Automatically initializes DXGI duplication with optimal settings.

**Parameters:**
- `outputIdx` (Integer): Preferred output index (0-based)
- `fps` (Integer): Target frame rate (0 for auto-calculation)

**Returns:** Boolean indicating initialization success

#### Dup_Shutdown()
Shuts down DXGI duplication and releases resources.

**Parameters:** None

**Returns:** Boolean indicating shutdown success

### Environment Functions

#### Dup_IsRemoteSession()
Checks if running in a remote desktop session.

**Parameters:** None

**Returns:** Boolean indicating remote session

#### Dup_DumpEnv()
Dumps environment information for debugging.

**Parameters:** None

**Returns:** Environment information map

### Output Management Functions

#### Dup_SelectOutputIdx(idx)
Selects a specific display output.

**Parameters:**
- `idx` (Integer): Output index (0-based)

**Returns:** Boolean indicating selection success

#### Dup_UpdateMonitorRect()
Updates monitor boundary information for current output.

**Parameters:** None

**Returns:** Boolean indicating update success

#### Dup_ScreenToOutput(x, y)
Converts screen coordinates to output coordinates.

**Parameters:**
- `x` (Integer): Screen X coordinate
- `y` (Integer): Screen Y coordinate

**Returns:** Coordinate mapping result or error

### Pixel Detection Functions

#### Dup_GetPixelAtScreen(x, y)
Gets pixel color at screen coordinates using DXGI.

**Parameters:**
- `x` (Integer): Screen X coordinate
- `y` (Integer): Screen Y coordinate

**Returns:** Color integer or -1 if unavailable

### Configuration Functions

#### Dup_OnProfileChanged()
Handles profile changes and adjusts FPS accordingly.

**Parameters:** None

**Returns:** Boolean indicating adjustment success

#### Dup_Enable(flag)
Enables or disables DXGI engine.

**Parameters:**
- `flag` (Boolean): Enable/disable flag

**Returns:** Current enabled state

### Statistics Functions

#### Dup_FrameBegin()
Starts new frame processing and updates statistics.

**Parameters:** None

**Returns:** Boolean indicating success

#### Dup_NotifyPath(path)
Records detection path usage for statistics.

**Parameters:**
- `path` (String): Detection path ("DX", "ROI", "GDI")

**Returns:** Boolean indicating success

### Low-Level DXGI Functions

#### DX_Init(output, fps, dllPath)
Low-level DXGI initialization.

**Parameters:**
- `output` (Integer): Output index
- `fps` (Integer): Frame rate
- `dllPath` (String): DLL path

**Returns:** Integer result code

#### DX_IsReady()
Checks if DXGI is ready.

**Parameters:** None

**Returns:** Boolean indicating ready state

#### DX_GetPixel(x, y)
Low-level pixel retrieval.

**Parameters:**
- `x` (Integer): Output X coordinate
- `y` (Integer): Output Y coordinate

**Returns:** Color integer

#### DX_EnumOutputs()
Enumerates available outputs.

**Parameters:** None

**Returns:** Number of outputs

#### DX_GetOutputName(idx)
Gets output name by index.

**Parameters:**
- `idx` (Integer): Output index

**Returns:** Output name string

#### DX_SelectOutput(idx)
Selects output by index.

**Parameters:**
- `idx` (Integer): Output index

**Returns:** Integer result code

#### DX_SetFPS(fps)
Sets frame rate.

**Parameters:**
- `fps` (Integer): Frame rate

**Returns:** None

#### DX_LastError()
Gets last error information.

**Parameters:** None

**Returns:** Error information map

## Usage Examples

### Basic DXGI Initialization
```ahk
; Initialize DXGI with automatic settings
if (Dup_InitAuto()) {
    Logger_Info("DXGI", "Initialization successful")
    
    ; Get current output information
    outputName := gDX.MonName
    boundaries := Map("left", gDX.L, "top", gDX.T, "right", gDX.R, "bottom", gDX.B)
    
    Logger_Info("DXGI", "Output configured", Map(
        "name", outputName,
        "boundaries", boundaries,
        "fps", gDX.FPS
    ))
} else {
    Logger_Warn("DXGI", "Initialization failed, using fallback methods")
}
```

### Dynamic FPS Adjustment
```ahk
; Handle profile changes for dynamic FPS adjustment
function OnProfileLoaded(profile) {
    Dup_OnProfileChanged()
    
    Logger_Info("DXGI", "FPS adjusted for profile", Map(
        "pollInterval", profile.PollIntervalMs,
        "currentFPS", gDX.FPS
    ))
}

; Manual FPS adjustment
function SetCustomFPS(fps) {
    if (gDX.Ready) {
        DX_SetFPS(fps)
        gDX.FPS := fps
        Logger_Info("DXGI", "FPS manually set", Map("fps", fps))
    }
}
```

### Multi-Monitor Support
```ahk
; Enumerate and select available outputs
function ConfigureMultiMonitor() {
    outputCount := DX_EnumOutputs()
    outputs := []
    
    for i in Range(0, outputCount - 1) {
        outputName := DX_GetOutputName(i)
        outputs.Push(Map("index", i, "name", outputName))
    }
    
    Logger_Info("DXGI", "Available outputs", Map("count", outputCount, "outputs", outputs))
    
    ; Select specific output
    if (outputCount > 1) {
        ; Choose secondary monitor if available
        targetOutput := 1
        if (Dup_SelectOutputIdx(targetOutput)) {
            Logger_Info("DXGI", "Output selected", Map("index", targetOutput, "name", gDX.MonName))
        }
    }
}
```

### Performance-Optimized Pixel Detection
```ahk
; High-performance pixel detection loop
function OptimizedPixelDetection() {
    Dup_FrameBegin()
    
    ; Process all skills with DXGI optimization
    for skill in App["ProfileData"].Skills {
        color := Dup_GetPixelAtScreen(skill.X, skill.Y)
        
        if (color != -1) {
            ; Pixel retrieved successfully via DXGI
            Dup_NotifyPath("DX")
            ProcessSkillColor(skill, color)
        } else {
            ; DXGI unavailable, use fallback
            Logger_Debug("DXGI", "Pixel unavailable via DXGI", Map("x", skill.X, "y", skill.Y))
        }
    }
    
    ; Log performance statistics periodically
    if (gDX.Stats.FrameNo % 100 == 0) {
        LogPerformanceStats()
    }
}

function LogPerformanceStats() {
    stats := gDX.Stats
    efficiency := stats.Dx / (stats.Dx + stats.Roi + stats.Gdi)
    
    Logger_Info("DXGI", "Performance statistics", Map(
        "frames", stats.FrameNo,
        "dxgi_efficiency", efficiency,
        "current_path", stats.LastPath,
        "ready_state", stats.LastReady
    ))
}
```

### Error Handling and Recovery
```ahk
; Robust DXGI operation with error handling
function SafeDXGIOperation() {
    try {
        if (!gDX.Ready) {
            if (!Dup_InitAuto()) {
                Logger_Error("DXGI", "Failed to initialize")
                return false
            }
        }
        
        ; Check if DXGI is actually ready
        readyState := DX_IsReady()
        if (!readyState) {
            Logger_Warn("DXGI", "DXGI not ready, attempting recovery")
            
            ; Attempt recovery
            Dup_Shutdown()
            Sleep(100)
            if (!Dup_InitAuto()) {
                Logger_Error("DXGI", "Recovery failed")
                return false
            }
        }
        
        return true
        
    } catch e {
        Logger_Error("DXGI", "Exception during operation", Map("error", e.Message))
        return false
    }
}

; Get detailed error information
function GetDXGIErrorInfo() {
    errorInfo := DX_LastError()
    
    if (errorInfo.Code != 0) {
        Logger_Error("DXGI", "Last error details", Map(
            "code", errorInfo.Code,
            "message", errorInfo.Text
        ))
    }
    
    return errorInfo
}
```

### Remote Session Compatibility
```ahk
; Handle remote desktop scenarios
function CheckRemoteCompatibility() {
    if (Dup_IsRemoteSession()) {
        Logger_Warn("DXGI", "Running in remote session, DXGI may be limited")
        
        ; Adjust settings for remote compatibility
        gDX.Enabled := false  ; Disable DXGI in remote sessions
        
        return Map(
            "compatible", false,
            "reason", "Remote desktop session detected",
            "recommendation", "Use ROI or GDI fallback"
        )
    }
    
    return Map("compatible", true)
}

; Environment information dump
function DumpEnvironment() {
    envInfo := Dup_DumpEnv()
    Logger_Info("DXGI", "Environment information", envInfo)
}
```

## Configuration Integration

### DXGI Engine Configuration
DXGI settings are configured in the main application:

```ahk
App["DXGIConfig"] := {
    Enabled: true,                ; Master enable/disable
    AutoInitialize: true,        ; Auto-initialize on startup
    PreferredOutput: 0,          ; Preferred output index
    MaxFPS: 120,                 ; Maximum frame rate
    MinFPS: 20,                  ; Minimum frame rate
    DynamicFPS: true,            ; Adjust FPS based on polling
    RemoteSessionFallback: true, ; Auto-disable in remote sessions
    DebugMode: false,            ; Enable debug logging
    StatisticsInterval: 100       ; Statistics logging interval
}
```

### Performance Configuration
Performance-related settings:

```ahk
App["PerformanceConfig"] := {
    PollIntervalMs: 25,          ; Base polling interval
    DXGIPriority: "High",         ; DXGI detection priority
    FallbackOrder: ["ROI", "GDI"], ; Fallback detection order
    MemoryOptimization: true,    ; Enable memory optimization
    ResourceCleanup: true        ; Enable automatic cleanup
}
```

## Performance Considerations

### Optimization Strategies

#### 1. Dynamic FPS Adjustment
- Automatically adjusts FPS based on polling interval
- Balances performance and resource usage
- Prevents unnecessary high frame rates

#### 2. Output Selection
- Chooses optimal display output
- Prioritizes primary monitor
- Fallback to available outputs

#### 3. Boundary Validation
- Early rejection of out-of-bounds coordinates
- Reduces unnecessary DXGI calls
- Improves overall performance

#### 4. Frame Statistics
- Tracks detection path usage
- Monitors performance trends
- Enables proactive optimization

### Memory Management
- DXGI resources are managed by native library
- Automatic cleanup on shutdown
- Memory usage scales with frame rate and resolution
- Efficient buffer management

### Performance Monitoring
```ahk
; Comprehensive performance monitoring
function MonitorDXGIPerformance() {
    stats := gDX.Stats
    
    ; Calculate efficiency metrics
    totalDetections := stats.Dx + stats.Roi + stats.Gdi
    dxgiEfficiency := totalDetections > 0 ? stats.Dx / totalDetections : 0
    
    ; Monitor ready state stability
    readyStability := stats.LastReady == 1 ? "Stable" : "Unstable"
    
    ; Log performance insights
    Logger_Info("DXGI", "Performance insights", Map(
        "dxgi_efficiency", dxgiEfficiency,
        "ready_stability", readyStability,
        "current_path", stats.LastPath,
        "frame_count", stats.FrameNo
    ))
    
    ; Alert on performance issues
    if (dxgiEfficiency < 0.5) {
        Logger_Warn("DXGI", "Low DXGI efficiency", Map("efficiency", dxgiEfficiency))
    }
}
```

## Error Handling

The DXGI engine includes comprehensive error handling:
- Remote session detection and compatibility
- Output enumeration failures
- Initialization errors with fallback
- Coordinate boundary validation
- Resource allocation failures
- Native library loading errors

## Debugging Features

### DXGI Debug Interface
The engine provides extensive debugging capabilities:

```ahk
; Enable comprehensive debugging
function EnableDXGIDebugging() {
    gDX.Debug := true
    Logger_Info("DXGI", "Debug mode enabled")
}

; Get detailed debug information
function GetDXGIDebugInfo() {
    debugInfo := Map(
        "enabled", gDX.Enabled,
        "ready", gDX.Ready,
        "output_index", gDX.OutIdx,
        "monitor_name", gDX.MonName,
        "fps", gDX.FPS,
        "boundaries", Map("left", gDX.L, "top", gDX.T, "right", gDX.R, "bottom", gDX.B),
        "statistics", gDX.Stats
    )
    
    return debugInfo
}

; Test DXGI functionality
function TestDXGIFunctionality() {
    ; Test coordinate mapping
    testCoords := [[100, 200], [500, 300], [1920, 1080]]
    
    for coord in testCoords {
        mapping := Dup_ScreenToOutput(coord[1], coord[2])
        Logger_Debug("DXGI", "Coordinate mapping test", Map(
            "screen", coord,
            "mapping", mapping
        ))
    }
    
    ; Test pixel retrieval
    if (gDX.Ready) {
        testColor := Dup_GetPixelAtScreen(100, 200)
        Logger_Debug("DXGI", "Pixel retrieval test", Map(
            "color", testColor != -1 ? Pixel_ColorToHex(testColor) : "Unavailable"
        ))
    }
}
```

### Performance Profiling
Built-in tools for performance analysis:

```ahk
; Start performance profiling
function StartDXGIProfiling() {
    gDX.Stats.FrameNo := 0
    gDX.Stats.Dx := 0
    gDX.Stats.Roi := 0
    gDX.Stats.Gdi := 0
    
    Logger_Info("DXGI", "Performance profiling started")
}

; Analyze detection path efficiency
function AnalyzeDetectionPaths() {
    stats := gDX.Stats
    total := stats.Dx + stats.Roi + stats.Gdi
    
    if (total > 0) {
        efficiency := Map(
            "dxgi", stats.Dx / total,
            "roi", stats.Roi / total,
            "gdi", stats.Gdi / total
        )
        
        Logger_Info("DXGI", "Detection path analysis", efficiency)
        return efficiency
    }
    
    return Map("dxgi", 0, "roi", 0, "gdi", 0)
}
```

## Dependencies

- dxgi_dup.dll native library for DirectX integration
- DirectX Graphics Infrastructure (DXGI)
- GDI system for fallback operations
- Configuration system for dynamic settings
- Logging system for performance monitoring
- Runtime system for thread management

## Related Modules

- [Pixel Engine](../pixel/README.md) - Primary consumer of DXGI detection
- [ROI System](../pixel/README.md) - Fallback detection method
- [Configuration System](../../core/README.md) - Dynamic FPS adjustment
- [Runtime System](../../runtime/README.md) - Thread-safe operation management
- [Logging System](../../logging/README.md) - Performance monitoring and error reporting