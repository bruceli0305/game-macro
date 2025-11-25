# 日志模块文档

日志模块为 Game Macro 系统提供全面的日志功能，包括多个日志接收器和灵活配置。

[English Version](../../logging/README.md) | [中文版本](README.md)

## 概述

日志模块提供：
- 多级别日志记录（DEBUG、INFO、WARNING、ERROR）
- 多个日志接收器（文件、内存、管道）
- 可配置的日志格式
- 日志轮转和管理
- 性能监控集成

## 架构

日志系统设计采用灵活的接收器架构：

### Logger.ahk（主日志控制器）
主日志管理和协调系统。

### 接收器子系统
用于不同目标的多个日志接收器实现。

#### FileSink.ahk
基于文件的日志记录，支持轮转和压缩。

#### MemorySink.ahk
内存日志记录，用于实时监控。

#### PipeSink.ahk
基于管道的日志记录，用于外部日志处理器。

### 集成点
- **所有模块**：为所有系统组件提供日志服务
- **UI 系统**：日志显示和监控界面
- **配置系统**：日志配置管理
- **运行时模块**：性能日志集成

## 关键组件

### 日志配置
可配置的日志设置和行为。

#### 日志配置结构
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

### 日志条目结构
标准化的日志条目格式。

#### 日志条目格式
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

### 日志接收器系统
用于不同日志目标的灵活接收器架构。

#### 接收器接口
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

## 执行流程

### 日志条目创建过程
1. **日志调用**：模块调用日志函数
2. **级别检查**：检查日志级别是否满足阈值
3. **条目创建**：创建结构化日志条目
4. **接收器路由**：将条目路由到启用的接收器
5. **条目处理**：每个接收器处理条目
6. **完成**：日志操作完成

### 接收器处理流程
1. **条目接收**：接收器接收日志条目
2. **格式化**：根据接收器配置格式化条目
3. **目标写入**：将格式化条目写入目标
4. **缓冲区管理**：管理内部缓冲区（如果适用）
5. **资源管理**：处理资源分配和清理

### 日志轮转过程
1. **大小检查**：检查当前日志文件大小
2. **轮转决策**：决定是否需要轮转
3. **文件轮转**：轮转当前日志文件
4. **归档管理**：管理归档的日志文件
5. **新文件创建**：创建新的日志文件

## API 参考

### 核心函数

#### Logger_Init(config)
初始化日志系统。

**参数：**
- `config`（Map）：日志配置

**返回：**布尔值指示成功

#### Logger_Shutdown()
关闭日志系统。

**参数：**无

**返回：**布尔值指示成功

#### Logger_SetLevel(level)
设置全局日志级别。

**参数：**
- `level`（字符串）：日志级别（DEBUG、INFO、WARNING、ERROR）

**返回：**布尔值指示成功

#### Logger_GetLevel()
获取当前日志级别。

**参数：**无

**返回：**当前日志级别

### 日志函数

#### Logger_Debug(module, message, data)
记录调试消息。

**参数：**
- `module`（字符串）：模块名称
- `message`（字符串）：日志消息
- `data`（Map）：附加数据（可选）

**返回：**布尔值指示成功

#### Logger_Info(module, message, data)
记录信息消息。

**参数：**
- `module`（字符串）：模块名称
- `message`（字符串）：日志消息
- `data`（Map）：附加数据（可选）

**返回：**布尔值指示成功

#### Logger_Warning(module, message, data)
记录警告消息。

**参数：**
- `module`（字符串）：模块名称
- `message`（字符串）：日志消息
- `data`（Map）：附加数据（可选）

**返回：**布尔值指示成功

#### Logger_Error(module, message, data)
记录错误消息。

**参数：**
- `module`（字符串）：模块名称
- `message`（字符串）：日志消息
- `data`（Map）：附加数据（可选）

**返回：**布尔值指示成功

### 接收器管理

#### Logger_AddSink(sinkConfig)
添加新的日志接收器。

**参数：**
- `sinkConfig`（Map）：接收器配置

**返回：**布尔值指示成功

#### Logger_RemoveSink(sinkId)
移除日志接收器。

**参数：**
- `sinkId`（字符串）：接收器标识符

**返回：**布尔值指示成功

#### Logger_EnableSink(sinkId)
启用日志接收器。

**参数：**
- `sinkId`（字符串）：接收器标识符

**返回：**布尔值指示成功

#### Logger_DisableSink(sinkId)
禁用日志接收器。

**参数：**
- `sinkId`（字符串）：接收器标识符

**返回：**布尔值指示成功

### 日志检索

#### Logger_GetEntries(level, module, limit)
检索日志条目。

**参数：**
- `level`（字符串）：日志级别过滤器（可选）
- `module`（字符串）：模块名称过滤器（可选）
- `limit`（整数）：返回条目数量限制（可选）

**返回：**日志条目数组

#### Logger_ClearEntries()
清除所有日志条目。

**参数：**无

**返回：**布尔值指示成功

## 使用示例

### 基本日志记录
```ahk
; 记录不同级别的消息
Logger_Debug("MyModule", "调试消息")
Logger_Info("MyModule", "信息消息")
Logger_Warning("MyModule", "警告消息")
Logger_Error("MyModule", "错误消息")
```

### 带附加数据的日志
```ahk
; 记录带附加数据的消息
Logger_Info("RotationEngine", "旋转开始", {
    "rotationId": 1,
    "skillCount": 5,
    "threadId": 1
})
```

### 自定义接收器配置
```ahk
; 配置文件接收器
fileSink := {
    Type: "File",
    Path: "logs/custom.log",
    MaxSize: 5242880, ; 5MB
    MaxFiles: 3
}

Logger_AddSink(fileSink)
```

### 日志检索和监控
```ahk
; 检索最近的错误日志
errors := Logger_GetEntries("ERROR", , 10)
for i, entry in errors {
    MsgBox, % "错误: " entry.Message
}
```

## 配置集成

### 配置文件集成
日志配置存储在配置文件数据中：

```ahk
profile := App["ProfileData"]
profile["LogConfig"] := LogConfig
```

### 运行时配置
日志设置可以在运行时动态调整：

```ahk
; 动态更改日志级别
Logger_SetLevel("DEBUG")

; 添加临时接收器
Logger_AddSink(temporarySink)
```

## 性能考虑

### 优化策略
1. **异步日志记录**：实现异步日志写入
2. **缓冲区管理**：优化接收器缓冲区大小
3. **级别过滤**：在调用前检查日志级别
4. **内存使用**：监控内存接收器的内存使用

### 内存管理
- 日志条目在达到限制时自动清理
- 接收器资源在关闭时正确释放
- 内存泄漏检测和预防

## 错误处理

日志模块包含全面的错误处理：
- 接收器写入失败
- 配置验证错误
- 资源分配失败
- 文件系统错误

## 调试功能

### 日志调试接口
模块提供实时监控的调试接口：

```ahk
; 启用详细日志调试
Logger_EnableDebug()

; 获取调试信息
debugInfo := Logger_GetDebugInfo()
```

### 性能监控
日志系统性能可以实时监控：

```ahk
; 获取性能统计
stats := Logger_GetPerformanceStats()
Logger_Info("Logger", "性能统计", stats)
```

## 依赖项

- 配置系统用于日志设置
- 文件系统用于文件接收器
- 内存管理用于内存接收器
- 线程系统用于异步操作

## 相关模块

- [配置系统](../core/README.md) - 日志配置管理
- [运行时模块](../runtime/README.md) - 性能监控集成
- [UI 系统](../ui/README.md) - 日志显示界面
- [存储模块](../storage/README.md) - 日志文件管理