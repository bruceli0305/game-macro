# Native Library Documentation

The Native Library module provides C++ implementations for performance-critical operations, particularly DirectX Graphics Infrastructure (DXGI) screen capture functionality.

[English Version](README.md) | [中文版本](../cn/lib/README.md)

## Overview

The Native Library module contains:
- **dxgi_dup.cpp**: C++ source code for DXGI duplication
- **dxgi_dup.dll**: Compiled native library for DXGI operations
- High-performance screen capture capabilities
- Hardware-accelerated pixel detection
- Multi-monitor support

## Architecture

The Native Library provides low-level access to DirectX functionality:

### dxgi_dup.cpp (C++ Source)
Native C++ implementation of DXGI duplication API.

### dxgi_dup.dll (Compiled Library)
Pre-compiled native library loaded by AutoHotkey scripts.

### Integration Points
- **DXGI Engine**: Primary consumer of native library
- **Pixel Detection**: Hardware-accelerated screen capture
- **Performance Monitoring**: Low-level performance metrics
- **Error Handling**: Native error reporting

## Key Components

### DXGI Duplication Interface
Low-level DirectX Graphics Infrastructure API wrapper.

#### Core DXGI Functions
```cpp
// Initialization and management
int DX_Init(int output, int fps, const char* dllPath);
int DX_Shutdown();
bool DX_IsReady();

// Pixel retrieval
int DX_GetPixel(int x, int y);

// Output management
int DX_EnumOutputs();
const char* DX_GetOutputName(int idx);
int DX_SelectOutput(int idx);

// Configuration
void DX_SetFPS(int fps);

// Error handling
DX_ErrorInfo DX_LastError();
```

### Error Handling System
Comprehensive error reporting and recovery mechanisms.

#### Error Information Structure
```cpp
struct DX_ErrorInfo {
    int Code;                    // Error code
    const char* Text;           // Error description
    const char* Function;       // Function name
    int Line;                   // Source line
    DWORD SystemError;          // System error code
};
```

### Performance Monitoring
Real-time performance metrics and statistics.

#### Performance Metrics
```cpp
struct DX_PerformanceStats {
    DWORD FrameCount;           // Total frames processed
    DWORD PixelRequests;       // Pixel retrieval requests
    DWORD Errors;              // Error count
    DWORD RecoveryAttempts;    // Recovery attempts
    DWORD LastFrameTime;       // Last frame processing time
    DWORD AverageFrameTime;    // Average frame time
};
```

## Execution Flow

### Library Initialization Process
1. **DLL Loading**: Load dxgi_dup.dll into memory
2. **Function Resolution**: Resolve exported function addresses
3. **DXGI Initialization**: Initialize DirectX Graphics Infrastructure
4. **Output Enumeration**: Discover available display outputs
5. **Duplication Setup**: Set up screen duplication
6. **Ready State**: Mark library as ready for operations

### Pixel Retrieval Process
1. **Coordinate Validation**: Validate screen coordinates
2. **Frame Acquisition**: Acquire current screen frame
3. **Pixel Access**: Access pixel data from frame buffer
4. **Color Extraction**: Extract RGB color values
5. **Frame Release**: Release frame resources
6. **Error Handling**: Handle retrieval failures

### Error Recovery Process
1. **Error Detection**: Monitor for DXGI errors
2. **State Assessment**: Assess current library state
3. **Resource Cleanup**: Release problematic resources
4. **Reinitialization**: Attempt library reinitialization
5. **Fallback Activation**: Activate fallback mechanisms

## API Reference

### Core Library Functions

#### DX_Init(output, fps, dllPath)
Initializes the DXGI duplication library.

**Parameters:**
- `output` (int): Display output index (0-based)
- `fps` (int): Target frame rate
- `dllPath` (const char*): Path to the DLL file

**Returns:** int (0 = success, negative = error)

**Error Codes:**
- `-1`: DLL loading failure
- `-2`: DXGI initialization failure
- `-3`: Output selection failure
- `-4`: Duplication setup failure

#### DX_Shutdown()
Shuts down the DXGI duplication library and releases resources.

**Parameters:** None

**Returns:** int (0 = success, negative = error)

#### DX_IsReady()
Checks if the DXGI library is ready for operations.

**Parameters:** None

**Returns:** bool (true = ready, false = not ready)

### Pixel Retrieval Functions

#### DX_GetPixel(x, y)
Retrieves the pixel color at the specified coordinates.

**Parameters:**
- `x` (int): X coordinate
- `y` (int): Y coordinate

**Returns:** int (RGB color value, -1 = error)

### Output Management Functions

#### DX_EnumOutputs()
Enumerates available display outputs.

**Parameters:** None

**Returns:** int (Number of available outputs)

#### DX_GetOutputName(idx)
Gets the name of the specified output.

**Parameters:**
- `idx` (int): Output index (0-based)

**Returns:** const char* (Output name, nullptr = error)

#### DX_SelectOutput(idx)
Selects the specified output for duplication.

**Parameters:**
- `idx` (int): Output index (0-based)

**Returns:** int (0 = success, negative = error)

### Configuration Functions

#### DX_SetFPS(fps)
Sets the frame rate for duplication.

**Parameters:**
- `fps` (int): Target frame rate

**Returns:** void

### Error Handling Functions

#### DX_LastError()
Gets the last error information.

**Parameters:** None

**Returns:** DX_ErrorInfo (Error information structure)

## Usage Examples

### Basic Library Integration
```cpp
// Example C++ integration
#include "dxgi_dup.h"

class DXGIManager {
private:
    bool initialized;
    int currentOutput;
    
public:
    DXGIManager() : initialized(false), currentOutput(0) {}
    
    bool Initialize(int output = 0, int fps = 60) {
        int result = DX_Init(output, fps, "dxgi_dup.dll");
        if (result == 0) {
            initialized = true;
            currentOutput = output;
            return true;
        }
        return false;
    }
    
    COLORREF GetPixelColor(int x, int y) {
        if (!initialized || !DX_IsReady()) {
            return -1;
        }
        return DX_GetPixel(x, y);
    }
    
    ~DXGIManager() {
        if (initialized) {
            DX_Shutdown();
        }
    }
};
```

### AutoHotkey Integration
```ahk
; AutoHotkey wrapper for DXGI functions
class DXGIWrapper {
    static __New() {
        this.hModule := DllCall("LoadLibrary", "Str", "dxgi_dup.dll", "Ptr")
        if (!this.hModule) {
            throw Error("Failed to load dxgi_dup.dll")
        }
        
        ; Resolve function addresses
        this.pDX_Init := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "DX_Init", "Ptr")
        this.pDX_GetPixel := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "DX_GetPixel", "Ptr")
        ; ... resolve other functions
    }
    
    static Init(output, fps) {
        return DllCall(this.pDX_Init, "Int", output, "Int", fps, "Str", "dxgi_dup.dll", "Int")
    }
    
    static GetPixel(x, y) {
        return DllCall(this.pDX_GetPixel, "Int", x, "Int", y, "Int")
    }
    
    ; ... other wrapper methods
}
```

### Error Handling Implementation
```cpp
// Comprehensive error handling
class DXGIErrorHandler {
public:
    static bool HandleInitError(int errorCode) {
        switch (errorCode) {
            case -1:
                LogError("DLL loading failure");
                return TryAlternativeDLL();
                
            case -2:
                LogError("DXGI initialization failure");
                return CheckDXGIAvailability();
                
            case -3:
                LogError("Output selection failure");
                return EnumerateAndSelectOutput();
                
            case -4:
                LogError("Duplication setup failure");
                return TryReducedFeatures();
                
            default:
                LogError("Unknown initialization error");
                return false;
        }
    }
    
    static DX_ErrorInfo GetDetailedError() {
        return DX_LastError();
    }
    
    static void LogError(const char* message) {
        DX_ErrorInfo error = DX_LastError();
        printf("Error: %s (Code: %d, Function: %s, Line: %d)\n", 
               message, error.Code, error.Function, error.Line);
    }
};
```

### Performance Monitoring
```cpp
// Performance monitoring implementation
class DXGIPerformanceMonitor {
private:
    DWORD startTime;
    DWORD frameCount;
    DWORD totalFrameTime;
    
public:
    DXGIPerformanceMonitor() : startTime(0), frameCount(0), totalFrameTime(0) {}
    
    void StartFrame() {
        startTime = GetTickCount();
    }
    
    void EndFrame() {
        DWORD endTime = GetTickCount();
        DWORD frameTime = endTime - startTime;
        
        frameCount++;
        totalFrameTime += frameTime;
        
        // Log performance every 100 frames
        if (frameCount % 100 == 0) {
            DWORD averageTime = totalFrameTime / frameCount;
            LogPerformance(averageTime, frameCount);
        }
    }
    
    DX_PerformanceStats GetStats() {
        DX_PerformanceStats stats = {0};
        stats.FrameCount = frameCount;
        stats.AverageFrameTime = frameCount > 0 ? totalFrameTime / frameCount : 0;
        return stats;
    }
};
```

## Configuration Integration

### Library Configuration
Native library configuration through function parameters:

```cpp
// Configuration structure
struct DX_Config {
    int OutputIndex;           // Display output selection
    int FrameRate;            // Target frame rate
    int TimeoutMs;           // Operation timeout
    bool DebugMode;          // Debug mode flag
    bool PerformanceMode;    // Performance optimization
};

// Configuration application
bool ApplyConfiguration(const DX_Config& config) {
    // Set output
    if (DX_SelectOutput(config.OutputIndex) != 0) {
        return false;
    }
    
    // Set frame rate
    DX_SetFPS(config.FrameRate);
    
    // Apply other configuration
    if (config.DebugMode) {
        EnableDebugFeatures();
    }
    
    if (config.PerformanceMode) {
        OptimizeForPerformance();
    }
    
    return true;
}
```

### AutoHotkey Configuration Integration
```ahk
; AutoHotkey configuration wrapper
class DXGIConfig {
    static Config := {
        OutputIndex: 0,
        FrameRate: 60,
        TimeoutMs: 1000,
        DebugMode: false,
        PerformanceMode: true
    }
    
    static Apply() {
        ; Set output
        result := DllCall(this.pDX_SelectOutput, "Int", this.Config.OutputIndex, "Int")
        if (result != 0) {
            Logger_Error("DXGI", "Output selection failed")
            return false
        }
        
        ; Set frame rate
        DllCall(this.pDX_SetFPS, "Int", this.Config.FrameRate)
        
        Logger_Info("DXGI", "Configuration applied", this.Config)
        return true
    }
}
```

## Performance Considerations

### Optimization Strategies

#### 1. Memory Management
- Efficient frame buffer management
- Minimal memory allocation during operations
- Proper resource cleanup

#### 2. Frame Rate Optimization
- Adaptive frame rate based on requirements
- Frame skipping for performance
- Dynamic FPS adjustment

#### 3. Error Recovery Optimization
- Fast error detection and recovery
- Minimal performance impact during recovery
- Graceful degradation

### Performance Monitoring
```cpp
// Real-time performance monitoring
class RealTimeMonitor {
public:
    static void MonitorPerformance() {
        static DWORD lastCheck = 0;
        DWORD currentTime = GetTickCount();
        
        // Check every second
        if (currentTime - lastCheck >= 1000) {
            DX_PerformanceStats stats = GetPerformanceStats();
            
            // Alert on performance issues
            if (stats.AverageFrameTime > 16) { // > 60 FPS threshold
                LogPerformanceWarning(stats);
            }
            
            lastCheck = currentTime;
        }
    }
    
    static DX_PerformanceStats GetPerformanceStats() {
        // Implementation to retrieve current stats
        DX_PerformanceStats stats = {0};
        // ... populate stats
        return stats;
    }
};
```

## Error Handling

The Native Library includes comprehensive error handling:
- DXGI API error reporting
- Resource allocation failures
- Invalid parameter validation
- System compatibility checks
- Recovery mechanism integration

### Error Recovery Mechanisms
```cpp
// Error recovery implementation
class DXGIErrorRecovery {
public:
    static bool AttemptRecovery(int errorCode) {
        switch (errorCode) {
            case DXGI_ERROR_DEVICE_REMOVED:
                return HandleDeviceRemoved();
                
            case DXGI_ERROR_DEVICE_RESET:
                return HandleDeviceReset();
                
            case DXGI_ERROR_ACCESS_LOST:
                return HandleAccessLost();
                
            default:
                return GenericRecovery();
        }
    }
    
private:
    static bool HandleDeviceRemoved() {
        // Reinitialize DXGI with new device
        DX_Shutdown();
        Sleep(100); // Brief pause
        return DX_Init(0, 60, "dxgi_dup.dll") == 0;
    }
    
    static bool GenericRecovery() {
        // Generic recovery attempt
        for (int attempt = 0; attempt < 3; attempt++) {
            DX_Shutdown();
            Sleep(200 * (attempt + 1)); // Increasing delay
            
            if (DX_Init(0, 60, "dxgi_dup.dll") == 0) {
                return true;
            }
        }
        return false;
    }
};
```

## Debugging Features

### Debug Interface
```cpp
// Debug functionality
class DXGIDebug {
public:
    static void EnableDebugMode() {
        SetDebugFlag(true);
        SetVerboseLogging(true);
    }
    
    static void DumpState() {
        printf("DXGI State Dump:\n");
        printf("  Ready: %s\n", DX_IsReady() ? "Yes" : "No");
        printf("  Outputs: %d\n", DX_EnumOutputs());
        
        DX_ErrorInfo error = DX_LastError();
        if (error.Code != 0) {
            printf("  Last Error: %s (Code: %d)\n", error.Text, error.Code);
        }
    }
    
    static void PerformanceReport() {
        DX_PerformanceStats stats = GetPerformanceStats();
        printf("Performance Report:\n");
        printf("  Frames: %lu\n", stats.FrameCount);
        printf("  Avg Frame Time: %lu ms\n", stats.AverageFrameTime);
        printf("  Pixel Requests: %lu\n", stats.PixelRequests);
    }
};
```

## Dependencies

- DirectX Graphics Infrastructure (DXGI)
- Windows Desktop Duplication API
- C++ Runtime Libraries
- Windows SDK headers and libraries

## Build Requirements

### Compilation Requirements
- Visual Studio 2019 or later
- Windows 10 SDK (10.0.17763.0 or later)
- DirectX SDK (June 2010 or later)

### Build Configuration
```cmake
# CMake configuration example
cmake_minimum_required(VERSION 3.15)
project(dxgi_dup)

set(CMAKE_CXX_STANDARD 17)

# Find required packages
find_package(dxgi REQUIRED)

# Source files
add_library(dxgi_dup SHARED dxgi_dup.cpp)

# Link libraries
target_link_libraries(dxgi_dup dxgi.lib)

# Compiler definitions
target_compile_definitions(dxgi_dup PRIVATE _WIN32_WINNT=0x0A00)
```

## Related Modules

- [DXGI Engine](../engines/dup/README.md) - High-level DXGI integration
- [Pixel Engine](../engines/pixel/README.md) - Pixel detection system
- [Performance Monitoring](../runtime/README.md) - System performance tracking
- [Error Handling](../util/README.md) - Utility functions for error management