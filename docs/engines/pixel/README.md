# Pixel Engine Documentation

The Pixel Engine provides advanced pixel detection, color matching, and screen capture capabilities for the Game Macro system, with optimized performance through frame-level caching and ROI (Region of Interest) acceleration.

[English Version](README.md) | [中文版本](../../cn/engines/pixel/README.md)

## Overview

The Pixel Engine provides:
- High-performance pixel color detection
- Frame-level color caching for optimization
- ROI (Region of Interest) snapshot acceleration
- Color matching with tolerance support
- Mouse-based pixel picking tools
- Multi-source pixel detection (DXGI, ROI, GDI)

## Architecture

The pixel engine is designed for maximum performance with intelligent fallback mechanisms:

### Pixel.ahk (Main Engine)
Core pixel detection and color management system.

### Integration Points
- **DXGI Duplication**: High-performance screen capture
- **ROI System**: Optimized region-based detection
- **GDI Fallback**: System-level pixel detection
- **All Engines**: Color-based condition evaluation

## Key Components

### Color Management System
Handles color conversion and matching operations.

#### Color Conversion Functions
```ahk
; Color conversion utilities
Pixel_ColorToHex(colorInt)     ; Integer → Hex string
Pixel_HexToInt(hexStr)         ; Hex string → Integer
Pixel_ColorMatch(curInt, targetInt, tol) ; Color matching with tolerance
```

#### Color Matching Configuration
```ahk
ColorMatchConfig := {
    Tolerance: 10,              ; Color tolerance (0-255)
    RGBMode: true,             ; Use RGB color space
    FastMode: false            ; Enable fast matching (less accurate)
}
```

### Frame-Level Caching System
Optimizes pixel detection by caching frame data.

#### Frame Cache Structure
```ahk
FrameCache := {
    id: 0,                     ; Frame identifier
    cache: Map(),              ; Pixel cache: "x|y" → color
    stats: {
        hits: 0,              ; Cache hit count
        misses: 0,            ; Cache miss count
        dxgi: 0,              ; DXGI path usage
        roi: 0,               ; ROI path usage  
        gdi: 0                ; GDI path usage
    }
}
```

### ROI (Region of Interest) System
Accelerates pixel detection by focusing on specific screen regions.

#### ROI Configuration
```ahk
ROIConfig := {
    enabled: true,             ; Enable/disable ROI
    rects: [],                ; ROI rectangles
    autoMode: true,           ; Auto-detect ROI from profile
    padding: 8,               ; Padding around detected points
    maxArea: 1000000,         ; Maximum ROI area
    minCount: 3               ; Minimum points for auto-ROI
}
```

#### ROI Rectangle Structure
```ahk
ROIRect := {
    L: 100,                    ; Left coordinate
    T: 200,                    ; Top coordinate
    W: 300,                    ; Width
    H: 200,                    ; Height
    R: 399,                    ; Right coordinate (L + W - 1)
    B: 399,                    ; Bottom coordinate (T + H - 1)
    hDC: 0,                    ; Device context handle
    hBmp: 0,                   ; Bitmap handle
    hOld: 0,                   ; Old object handle
    pBits: 0,                  ; Pixel data pointer
    stride: 1200               ; Stride (W * 4)
}
```

### Pixel Detection Paths
The engine uses multiple detection paths in priority order:

#### 1. DXGI Duplication (Highest Priority)
- Uses DirectX Graphics Infrastructure
- Hardware-accelerated screen capture
- Fastest path when available
- Limited to current output display

#### 2. ROI Snapshot (Medium Priority)
- BitBlt-based region capture
- Memory bitmap caching
- Optimized for frequently accessed areas
- Requires ROI setup

#### 3. GDI System (Fallback)
- System-level pixel detection
- Most compatible but slowest
- Universal fallback mechanism

## Execution Flow

### Frame Processing Pipeline
1. **Frame Begin**: Start new frame processing
2. **ROI Snapshot**: Capture ROI regions if enabled
3. **Pixel Requests**: Handle pixel detection requests
4. **Path Selection**: Choose optimal detection path
5. **Cache Update**: Update frame cache with results
6. **Frame End**: Complete frame processing

### Pixel Detection Process
1. **Cache Check**: Check if pixel is in frame cache
2. **DXGI Path**: Try DXGI duplication if coordinates in current output
3. **ROI Path**: Check ROI cache if coordinates in ROI regions
4. **GDI Path**: Fallback to system pixel detection
5. **Cache Store**: Store result in frame cache

### ROI Management Process
1. **Auto-Detection**: Detect ROI from profile skills/points
2. **Validation**: Validate ROI size and boundaries
3. **Setup**: Create memory bitmaps for ROI regions
4. **Snapshot**: Capture ROI regions each frame
5. **Cleanup**: Proper resource disposal

## API Reference

### Core Color Functions

#### Pixel_ColorToHex(colorInt)
Converts color integer to hex string.

**Parameters:**
- `colorInt` (Integer): Color value (0xRRGGBB)

**Returns:** Hex color string (e.g., "0xFF0000")

#### Pixel_HexToInt(hexStr)
Converts hex string to color integer.

**Parameters:**
- `hexStr` (String): Hex color string

**Returns:** Color integer (0xRRGGBB)

#### Pixel_ColorMatch(curInt, targetInt, tol)
Checks if two colors match within tolerance.

**Parameters:**
- `curInt` (Integer): Current color
- `targetInt` (Integer): Target color
- `tol` (Integer): Tolerance value (0-255)

**Returns:** Boolean indicating color match

### Frame Management

#### Pixel_FrameBegin()
Starts a new frame for pixel detection.

**Parameters:** None

**Returns:** Boolean indicating success

#### Pixel_FrameGet(x, y)
Gets pixel color at specified coordinates.

**Parameters:**
- `x` (Integer): X coordinate
- `y` (Integer): Y coordinate

**Returns:** Color integer (0xRRGGBB)

### ROI Management

#### Pixel_ROI_Enable(flag)
Enables or disables ROI system.

**Parameters:**
- `flag` (Boolean): Enable/disable flag

**Returns:** Current ROI enabled state

#### Pixel_ROI_Clear()
Clears all ROI regions and resources.

**Parameters:** None

**Returns:** Boolean indicating success

#### Pixel_ROI_Dispose()
Disposes ROI system and releases resources.

**Parameters:** None

**Returns:** Boolean indicating success

#### Pixel_ROI_SetRect(l, t, w, h)
Sets a single ROI rectangle.

**Parameters:**
- `l` (Integer): Left coordinate
- `t` (Integer): Top coordinate
- `w` (Integer): Width
- `h` (Integer): Height

**Returns:** Boolean indicating success

#### Pixel_ROI_SetAutoFromProfile(prof, pad, includePoints, maxArea, minCount)
Automatically sets ROI from profile data.

**Parameters:**
- `prof` (Map): Profile data
- `pad` (Integer): Padding around points
- `includePoints` (Boolean): Include point coordinates
- `maxArea` (Integer): Maximum ROI area
- `minCount` (Integer): Minimum points required

**Returns:** Boolean indicating success

#### Pixel_ROI_BeginSnapshot()
Captures snapshot of ROI regions.

**Parameters:** None

**Returns:** Boolean indicating success

#### Pixel_ROI_GetIfInside(x, y)
Gets pixel color from ROI if coordinates inside.

**Parameters:**
- `x` (Integer): X coordinate
- `y` (Integer): Y coordinate

**Returns:** Color integer or -1 if outside ROI

### Pixel Picking Tools

#### Pixel_PickPixel(parentGui, offsetY, dwellMs, confirmKey)
Interactive pixel picking tool.

**Parameters:**
- `parentGui` (Object): Parent GUI object (optional)
- `offsetY` (Integer): Mouse offset Y (avoidance)
- `dwellMs` (Integer): Dwell time before capture
- `confirmKey` (String): Confirmation key

**Returns:** Pixel information map or 0 on cancel

#### Pixel_GetColorWithMouseAway(x, y, offsetY, dwellMs)
Gets pixel color with mouse avoidance.

**Parameters:**
- `x` (Integer): X coordinate
- `y` (Integer): Y coordinate
- `offsetY` (Integer): Mouse offset Y
- `dwellMs` (Integer): Dwell time

**Returns:** Color integer

## Usage Examples

### Basic Pixel Detection
```ahk
; Initialize pixel detection
Pixel_FrameBegin()

; Get pixel color at specific coordinates
color := Pixel_FrameGet(100, 200)
hexColor := Pixel_ColorToHex(color)

; Check if color matches target
targetColor := Pixel_HexToInt("0xFF0000")
matches := Pixel_ColorMatch(color, targetColor, 10)

if (matches) {
    Logger_Info("Pixel", "Color match detected", Map("color", hexColor))
}
```

### ROI Optimization Setup
```ahk
; Enable ROI system
Pixel_ROI_Enable(true)

; Auto-detect ROI from profile skills
if (Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false, 1000000, 3)) {
    Logger_Info("ROI", "Auto ROI configured successfully")
} else {
    Logger_Warn("ROI", "Auto ROI configuration failed, using fallback")
}

; In frame processing loop
Pixel_FrameBegin()
Pixel_ROI_BeginSnapshot()  ; Capture ROI regions

; Pixel detection will now use ROI optimization
for skill in App["ProfileData"].Skills {
    color := Pixel_FrameGet(skill.X, skill.Y)
    ; Process skill color...
}
```

### Interactive Pixel Picking
```ahk
; Simple pixel picking
pixelInfo := Pixel_PickPixel()
if (pixelInfo != 0) {
    Logger_Info("Pixel", "Pixel picked", Map(
        "x", pixelInfo.X,
        "y", pixelInfo.Y, 
        "color", Pixel_ColorToHex(pixelInfo.Color)
    ))
}

; Advanced pixel picking with mouse avoidance
pixelInfo := Pixel_PickPixel(0, 50, 100, "RButton")
if (pixelInfo != 0) {
    ; Use picked pixel coordinates
    skillX := pixelInfo.X
    skillY := pixelInfo.Y
    skillColor := pixelInfo.Color
}
```

### Performance-Optimized Detection Loop
```ahk
; Optimized detection with frame caching
function OptimizedPixelDetection() {
    Pixel_FrameBegin()
    
    if (Pixel_ROI_Enabled()) {
        Pixel_ROI_BeginSnapshot()
    }
    
    ; Process all skills with optimized detection
    for skill in App["ProfileData"].Skills {
        color := Pixel_FrameGet(skill.X, skill.Y)
        targetColor := Pixel_HexToInt(skill.Color)
        
        if (Pixel_ColorMatch(color, targetColor, skill.Tolerance)) {
            ; Skill is ready for execution
            CastEngine_ExecuteSkill(skill.Id)
        }
    }
    
    ; Get performance statistics
    stats := Pixel_GetFrameStats()
    if (stats["misses"] > stats["hits"] * 0.1) {
        Logger_Warn("Pixel", "High cache miss rate", stats)
    }
}
```

### Color Analysis and Validation
```ahk
; Analyze color variations
function AnalyzeColorStability(x, y, sampleCount) {
    colors := []
    
    for i in Range(1, sampleCount) {
        Pixel_FrameBegin()
        color := Pixel_FrameGet(x, y)
        colors.Push(color)
        Sleep(10)
    }
    
    ; Calculate color stability
    avgColor := CalculateAverageColor(colors)
    stability := CalculateColorStability(colors, avgColor)
    
    return {
        average: avgColor,
        stability: stability,
        samples: colors
    }
}

; Validate skill color configuration
function ValidateSkillColors(profile) {
    issues := []
    
    for skill in profile.Skills {
        targetColor := Pixel_HexToInt(skill.Color)
        
        if (targetColor = 0) {
            issues.Push(Map(
                "skill", skill.Name,
                "issue", "Invalid color format",
                "color", skill.Color
            ))
        }
        
        ; Test color detection at skill coordinates
        Pixel_FrameBegin()
        currentColor := Pixel_FrameGet(skill.X, skill.Y)
        
        if (!Pixel_ColorMatch(currentColor, targetColor, skill.Tolerance)) {
            issues.Push(Map(
                "skill", skill.Name,
                "issue", "Color mismatch at coordinates",
                "expected", skill.Color,
                "actual", Pixel_ColorToHex(currentColor)
            ))
        }
    }
    
    return issues
}
```

## Configuration Integration

### Pixel Engine Configuration
Pixel engine settings are configured in the main application:

```ahk
App["PixelConfig"] := {
    FrameCaching: true,          ; Enable frame-level caching
    ROIOptimization: true,      ; Enable ROI optimization
    ColorTolerance: 10,         ; Default color tolerance
    DetectionPaths: ["DXGI", "ROI", "GDI"], ; Detection path priority
    PerformanceMonitoring: true, ; Enable performance stats
    CacheValidation: false       ; Enable cache validation
}
```

### Skill Color Configuration
Skill-specific color settings:

```ahk
Skill["ColorConfig"] := {
    Color: "0xFF0000",          ; Target color in hex
    Tolerance: 15,              ; Color tolerance
    CheckReady: true,           ; Enable color checking
    Coordinates: {
        X: 100,                 ; Screen X coordinate
        Y: 200                  ; Screen Y coordinate
    }
}
```

## Performance Considerations

### Optimization Strategies

#### 1. Frame Caching
- Cache pixel colors per frame to avoid redundant detection
- Ideal for multiple checks at same coordinates
- Reduces detection overhead by 80-90%

#### 2. ROI Optimization
- Focus detection on relevant screen regions
- Reduces detection area by 60-95%
- Especially effective for clustered skill points

#### 3. Path Priority
- DXGI: Fastest but limited to current output
- ROI: Optimized for configured regions
- GDI: Universal but slowest fallback

### Memory Management
- ROI bitmaps are allocated and managed automatically
- Frame cache is cleared each frame
- Resources are properly disposed on shutdown
- Memory usage scales with ROI size and detection frequency

### Performance Monitoring
```ahk
; Get performance statistics
stats := Pixel_GetPerformanceStats()

; Monitor cache efficiency
cacheEfficiency := stats["hits"] / (stats["hits"] + stats["misses"])
if (cacheEfficiency < 0.8) {
    Logger_Warn("Pixel", "Low cache efficiency", Map("efficiency", cacheEfficiency))
}

; Monitor detection path usage
if (stats["gdi"] > stats["dxgi"] * 2) {
    Logger_Info("Pixel", "High GDI usage, consider ROI optimization")
}
```

## Error Handling

The pixel engine includes comprehensive error handling:
- Invalid coordinate handling
- Color conversion errors
- ROI resource allocation failures
- Detection path fallback mechanisms
- Memory allocation error recovery

## Debugging Features

### Pixel Debug Interface
The engine provides debugging capabilities:

```ahk
; Enable pixel debugging
Pixel_EnableDebug()

; Get debug information
debugInfo := Pixel_GetDebugInfo()

; Test pixel detection at specific coordinates
testResult := Pixel_TestDetection(100, 200, "0xFF0000", 10)

; Validate ROI configuration
roiStatus := Pixel_ValidateROI()
```

### Performance Profiling
Built-in tools for performance analysis:

```ahk
; Start performance profiling
Pixel_StartProfiling()

; Run detection operations
for i in Range(1, 1000) {
    Pixel_FrameGet(100 + i, 200)
}

; Get profiling results
profile := Pixel_GetProfileResults()

; Analyze detection path efficiency
pathEfficiency := AnalyzeDetectionPaths(profile)
```

## Dependencies

- DXGI duplication system for high-performance capture
- GDI system calls for fallback detection
- Memory management utilities for ROI bitmaps
- Configuration system for engine settings
- Logging system for performance monitoring

## Related Modules

- [DXGI Duplication Engine](../dup/README.md) - High-performance screen capture
- [Rule Engine](../rules/README.md) - Color-based condition evaluation
- [Rotation Engine](../rotation/README.md) - Skill execution based on color detection
- [UI Module](../../ui/README.md) - Pixel picking interface tools