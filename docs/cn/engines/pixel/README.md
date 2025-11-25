# Pixel 引擎文档

Pixel 引擎为 Game Macro 系统提供高级像素检测、颜色匹配和屏幕捕获功能，通过帧级缓存和 ROI（感兴趣区域）加速实现优化性能。

[English Version](../../engines/pixel/README.md) | [中文版本](README.md)

## 概述

Pixel 引擎提供：
- 高性能像素颜色检测
- 帧级颜色缓存优化
- ROI（感兴趣区域）快照加速
- 支持容差的颜色匹配
- 基于鼠标的像素拾取工具
- 多源像素检测（DXGI、ROI、GDI）

## 架构

像素引擎设计为具有智能回退机制的最大性能：

### Pixel.ahk（主引擎）
核心像素检测和颜色管理系统。

### 集成点
- **DXGI 复制**：高性能屏幕捕获
- **ROI 系统**：优化的基于区域的检测
- **GDI 回退**：系统级像素检测
- **所有引擎**：基于颜色的条件评估

## 关键组件

### 颜色管理系统
处理颜色转换和匹配操作。

#### 颜色转换函数
```ahk
; 颜色转换工具
Pixel_ColorToHex(colorInt)     ; 整数 → 十六进制字符串
Pixel_HexToInt(hexStr)         ; 十六进制字符串 → 整数
Pixel_ColorMatch(curInt, targetInt, tol) ; 带容差的颜色匹配
```

#### 颜色匹配配置
```ahk
ColorMatchConfig := {
    Tolerance: 10,              ; 颜色容差 (0-255)
    RGBMode: true,             ; 使用 RGB 颜色空间
    FastMode: false            ; 启用快速匹配（精度较低）
}
```

### 帧级缓存系统
通过缓存帧数据优化像素检测。

#### 帧缓存结构
```ahk
FrameCache := {
    id: 0,                     ; 帧标识符
    cache: Map(),              ; 像素缓存："x|y" → 颜色
    stats: {
        hits: 0,              ; 缓存命中计数
        misses: 0,            ; 缓存未命中计数
        dxgi: 0,              ; DXGI 路径使用
        roi: 0,               ; ROI 路径使用  
        gdi: 0                ; GDI 路径使用
    }
}
```

### ROI（感兴趣区域）系统
通过聚焦特定屏幕区域加速像素检测。

#### ROI 配置
```ahk
ROIConfig := {
    enabled: true,             ; 启用/禁用 ROI
    rects: [],                ; ROI 矩形
    autoMode: true,           ; 从配置文件自动检测 ROI
    padding: 8,               ; 检测点周围的填充
    maxArea: 1000000,         ; 最大 ROI 区域
    minCount: 3               ; 自动 ROI 的最小点数
}
```

#### ROI 矩形结构
```ahk
ROIRect := {
    L: 100,                    ; 左坐标
    T: 200,                    ; 上坐标
    W: 300,                    ; 宽度
    H: 200,                    ; 高度
    R: 399,                    ; 右坐标 (L + W - 1)
    B: 399,                    ; 下坐标 (T + H - 1)
    hDC: 0,                    ; 设备上下文句柄
    hBmp: 0,                   ; 位图句柄
    hOld: 0,                   ; 旧对象句柄
    pBits: 0,                  ; 像素数据指针
    stride: 1200               ; 步幅 (W * 4)
}
```

### 像素检测路径
引擎按优先级顺序使用多个检测路径：

#### 1. DXGI 复制（最高优先级）
- 使用 DirectX 图形基础设施
- 硬件加速屏幕捕获
- 可用时最快的路径
- 限于当前输出显示

#### 2. ROI 快照（中等优先级）
- 基于 BitBlt 的区域捕获
- 内存位图缓存
- 针对频繁访问区域优化
- 需要 ROI 设置

#### 3. GDI 系统（回退）
- 系统级像素检测
- 兼容性最好但最慢
- 通用回退机制

## 执行流程

### 帧处理管道
1. **帧开始**：开始新帧处理
2. **ROI 快照**：如果启用则捕获 ROI 区域
3. **像素请求**：处理像素检测请求
4. **路径选择**：选择最佳检测路径
5. **缓存更新**：用结果更新帧缓存
6. **帧结束**：完成帧处理

### 像素检测过程
1. **缓存检查**：检查像素是否在帧缓存中
2. **DXGI 路径**：如果坐标在当前输出中则尝试 DXGI 复制
3. **ROI 路径**：如果坐标在 ROI 区域中则检查 ROI 缓存
4. **GDI 路径**：回退到系统像素检测
5. **缓存存储**：将结果存储在帧缓存中

### ROI 管理过程
1. **自动检测**：从配置文件技能/点检测 ROI
2. **验证**：验证 ROI 大小和边界
3. **设置**：为 ROI 区域创建内存位图
4. **快照**：每帧捕获 ROI 区域
5. **清理**：正确释放资源

## API 参考

### 核心颜色函数

#### Pixel_ColorToHex(colorInt)
将颜色整数转换为十六进制字符串。

**参数：**
- `colorInt`（整数）：颜色值 (0xRRGGBB)

**返回：**十六进制颜色字符串（例如 "0xFF0000"）

#### Pixel_HexToInt(hexStr)
将十六进制字符串转换为颜色整数。

**参数：**
- `hexStr`（字符串）：十六进制颜色字符串

**返回：**颜色整数 (0xRRGGBB)

#### Pixel_ColorMatch(curInt, targetInt, tol)
检查两种颜色是否在容差范围内匹配。

**参数：**
- `curInt`（整数）：当前颜色
- `targetInt`（整数）：目标颜色
- `tol`（整数）：容差值 (0-255)

**返回：**布尔值指示颜色匹配

### 帧管理

#### Pixel_FrameBegin()
开始新帧进行像素检测。

**参数：**无

**返回：**布尔值指示成功

#### Pixel_FrameGet(x, y)
获取指定坐标的像素颜色。

**参数：**
- `x`（整数）：X 坐标
- `y`（整数）：Y 坐标

**返回：**颜色整数 (0xRRGGBB)

### ROI 管理

#### Pixel_ROI_Enable(flag)
启用或禁用 ROI 系统。

**参数：**
- `flag`（布尔值）：启用/禁用标志

**返回：**当前 ROI 启用状态

#### Pixel_ROI_Clear()
清除所有 ROI 区域和资源。

**参数：**无

**返回：**布尔值指示成功

#### Pixel_ROI_Dispose()
释放 ROI 系统并释放资源。

**参数：**无

**返回：**布尔值指示成功

#### Pixel_ROI_SetRect(l, t, w, h)
设置单个 ROI 矩形。

**参数：**
- `l`（整数）：左坐标
- `t`（整数）：上坐标
- `w`（整数）：宽度
- `h`（整数）：高度

**返回：**布尔值指示成功

#### Pixel_ROI_SetAutoFromProfile(prof, pad, includePoints, maxArea, minCount)
从配置文件数据自动设置 ROI。

**参数：**
- `prof`（Map）：配置文件数据
- `pad`（整数）：点周围的填充
- `includePoints`（布尔值）：包含点坐标
- `maxArea`（整数）：最大 ROI 区域
- `minCount`（整数）：所需最小点数

**返回：**布尔值指示成功

#### Pixel_ROI_BeginSnapshot()
捕获 ROI 区域的快照。

**参数：**无

**返回：**布尔值指示成功

#### Pixel_ROI_GetIfInside(x, y)
如果坐标在 ROI 内则从 ROI 获取像素颜色。

**参数：**
- `x`（整数）：X 坐标
- `y`（整数）：Y 坐标

**返回：**颜色整数或 -1（如果在 ROI 外）

### 像素拾取工具

#### Pixel_PickPixel(parentGui, offsetY, dwellMs, confirmKey)
交互式像素拾取工具。

**参数：**
- `parentGui`（对象）：父 GUI 对象（可选）
- `offsetY`（整数）：鼠标偏移 Y（避免）
- `dwellMs`（整数）：捕获前的停留时间
- `confirmKey`（字符串）：确认键

**返回：**像素信息映射或取消时为 0

#### Pixel_GetColorWithMouseAway(x, y, offsetY, dwellMs)
使用鼠标避免获取像素颜色。

**参数：**
- `x`（整数）：X 坐标
- `y`（整数）：Y 坐标
- `offsetY`（整数）：鼠标偏移 Y
- `dwellMs`（整数）：停留时间

**返回：**颜色整数

## 使用示例

### 基本像素检测
```ahk
; 初始化像素检测
Pixel_FrameBegin()

; 获取特定坐标的像素颜色
color := Pixel_FrameGet(100, 200)
hexColor := Pixel_ColorToHex(color)

; 检查颜色是否匹配目标
targetColor := Pixel_HexToInt("0xFF0000")
matches := Pixel_ColorMatch(color, targetColor, 10)

if (matches) {
    Logger_Info("Pixel", "检测到颜色匹配", Map("color", hexColor))
}
```

### ROI 优化设置
```ahk
; 启用 ROI 系统
Pixel_ROI_Enable(true)

; 从配置文件技能自动检测 ROI
if (Pixel_ROI_SetAutoFromProfile(App["ProfileData"], 8, false, 1000000, 3)) {
    Logger_Info("ROI", "自动 ROI 配置成功")
} else {
    Logger_Warn("ROI", "自动 ROI 配置失败，使用回退")
}

; 在帧处理循环中
Pixel_FrameBegin()
Pixel_ROI_BeginSnapshot()  ; 捕获 ROI 区域

; 像素检测现在将使用 ROI 优化
for skill in App["ProfileData"].Skills {
    color := Pixel_FrameGet(skill.X, skill.Y)
    ; 处理技能颜色...
}
```

### 交互式像素拾取
```ahk
; 简单像素拾取
pixelInfo := Pixel_PickPixel()
if (pixelInfo != 0) {
    Logger_Info("Pixel", "像素已拾取", Map(
        "x", pixelInfo.X,
        "y", pixelInfo.Y, 
        "color", Pixel_ColorToHex(pixelInfo.Color)
    ))
}

; 带鼠标避免的高级像素拾取
pixelInfo := Pixel_PickPixel(0, 50, 100, "RButton")
if (pixelInfo != 0) {
    ; 使用拾取的像素坐标
    skillX := pixelInfo.X
    skillY := pixelInfo.Y
    skillColor := pixelInfo.Color
}
```

### 性能优化检测循环
```ahk
; 带帧缓存的优化检测
function OptimizedPixelDetection() {
    Pixel_FrameBegin()
    
    if (Pixel_ROI_Enabled()) {
        Pixel_ROI_BeginSnapshot()
    }
    
    ; 使用优化检测处理所有技能
    for skill in App["ProfileData"].Skills {
        color := Pixel_FrameGet(skill.X, skill.Y)
        targetColor := Pixel_HexToInt(skill.Color)
        
        if (Pixel_ColorMatch(color, targetColor, skill.Tolerance)) {
            ; 技能准备执行
            CastEngine_ExecuteSkill(skill.Id)
        }
    }
    
    ; 获取性能统计
    stats := Pixel_GetFrameStats()
    if (stats["misses"] > stats["hits"] * 0.1) {
        Logger_Warn("Pixel", "高缓存未命中率", stats)
    }
}
```

### 颜色分析和验证
```ahk
; 分析颜色变化
function AnalyzeColorStability(x, y, sampleCount) {
    colors := []
    
    for i in Range(1, sampleCount) {
        Pixel_FrameBegin()
        color := Pixel_FrameGet(x, y)
        colors.Push(color)
        Sleep(10)
    }
    
    ; 计算颜色稳定性
    avgColor := CalculateAverageColor(colors)
    stability := CalculateColorStability(colors, avgColor)
    
    return {
        average: avgColor,
        stability: stability,
        samples: colors
    }
}

; 验证技能颜色配置
function ValidateSkillColors(profile) {
    issues := []
    
    for skill in profile.Skills {
        targetColor := Pixel_HexToInt(skill.Color)
        
        if (targetColor = 0) {
            issues.Push(Map(
                "skill", skill.Name,
                "issue", "无效的颜色格式",
                "color", skill.Color
            ))
        }
        
        ; 在技能坐标测试颜色检测
        Pixel_FrameBegin()
        currentColor := Pixel_FrameGet(skill.X, skill.Y)
        
        if (!Pixel_ColorMatch(currentColor, targetColor, skill.Tolerance)) {
            issues.Push(Map(
                "skill", skill.Name,
                "issue", "坐标处颜色不匹配",
                "expected", skill.Color,
                "actual", Pixel_ColorToHex(currentColor)
            ))
        }
    }
    
    return issues
}
```

## 配置集成

### Pixel 引擎配置
像素引擎设置在主应用程序中配置：

```ahk
App["PixelConfig"] := {
    FrameCaching: true,          ; 启用帧级缓存
    ROIOptimization: true,      ; 启用 ROI 优化
    ColorTolerance: 10,         ; 默认颜色容差
    DetectionPaths: ["DXGI", "ROI", "GDI"], ; 检测路径优先级
    PerformanceMonitoring: true, ; 启用性能统计
    CacheValidation: false       ; 启用缓存验证
}
```

### 技能颜色配置
特定技能的颜色设置：

```ahk
Skill["ColorConfig"] := {
    Color: "0xFF0000",          ; 十六进制目标颜色
    Tolerance: 15,              ; 颜色容差
    CheckReady: true,           ; 启用颜色检查
    Coordinates: {
        X: 100,                 ; 屏幕 X 坐标
        Y: 200                  ; 屏幕 Y 坐标
    }
}
```

## 性能考虑

### 优化策略

#### 1. 帧缓存
- 每帧缓存像素颜色以避免冗余检测
- 适用于相同坐标的多次检查
- 减少检测开销 80-90%

#### 2. ROI 优化
- 聚焦检测相关屏幕区域
- 减少检测区域 60-95%
- 对聚集的技能点特别有效

#### 3. 路径优先级
- DXGI：最快但限于当前输出
- ROI：针对配置区域优化
- GDI：通用但最慢的回退

### 内存管理
- ROI 位图自动分配和管理
- 每帧清除帧缓存
- 关闭时正确释放资源
- 内存使用随 ROI 大小和检测频率扩展

### 性能监控
```ahk
; 获取性能统计
stats := Pixel_GetPerformanceStats()

; 监控缓存效率
cacheEfficiency := stats["hits"] / (stats["hits"] + stats["misses"])
if (cacheEfficiency < 0.8) {
    Logger_Warn("Pixel", "低缓存效率", Map("efficiency", cacheEfficiency))
}

; 监控检测路径使用
if (stats["gdi"] > stats["dxgi"] * 2) {
    Logger_Info("Pixel", "高 GDI 使用，考虑 ROI 优化")
}
```

## 错误处理

像素引擎包含全面的错误处理：
- 无效坐标处理
- 颜色转换错误
- ROI 资源分配失败
- 检测路径回退机制
- 内存分配错误恢复

## 调试功能

### 像素调试接口
引擎提供调试功能：

```ahk
; 启用像素调试
Pixel_EnableDebug()

; 获取调试信息
debugInfo := Pixel_GetDebugInfo()

; 在特定坐标测试像素检测
testResult := Pixel_TestDetection(100, 200, "0xFF0000", 10)

; 验证 ROI 配置
roiStatus := Pixel_ValidateROI()
```

### 性能分析
性能分析的内置工具：

```ahk
; 开始性能分析
Pixel_StartProfiling()

; 运行检测操作
for i in Range(1, 1000) {
    Pixel_FrameGet(100 + i, 200)
}

; 获取分析结果
profile := Pixel_GetProfileResults()

; 分析检测路径效率
pathEfficiency := AnalyzeDetectionPaths(profile)
```

## 依赖项

- DXGI 复制系统用于高性能捕获
- GDI 系统调用用于回退检测
- 内存管理工具用于 ROI 位图
- 配置系统用于引擎设置
- 日志系统用于性能监控

## 相关模块

- [DXGI 复制引擎](../dup/README.md) - 高性能屏幕捕获
- [规则引擎](../rules/README.md) - 基于颜色的条件评估
- [旋转引擎](../rotation/README.md) - 基于颜色检测的技能执行
- [UI 模块](../../ui/README.md) - 像素拾取界面工具