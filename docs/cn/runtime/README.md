# 运行时模块文档

运行时模块管理应用程序的执行生命周期、线程管理和实时操作控制。

[English Version](../../runtime/README.md) | [中文版本](README.md)

## 概述

运行时模块提供：
- 应用程序生命周期管理
- 多线程执行控制
- 实时操作监控
- 性能优化
- 错误处理和恢复

## 架构

运行时系统协调所有引擎组件：

### Runtime.ahk（主运行时控制器）
主运行时管理和协调系统。

### 集成点
- **所有引擎**：协调所有引擎模块的执行
- **UI 系统**：提供运行时状态和控制界面
- **配置系统**：管理运行时设置
- **日志系统**：运行时活动日志记录

## 关键组件

### 应用程序生命周期管理
管理从启动到关闭的完整应用程序生命周期。

#### 运行时状态
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

### 线程管理系统
管理多个执行线程以进行并行处理。

#### 线程配置
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

### 性能监控
跟踪运行时性能指标。

#### 性能指标
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

## 执行流程

### 应用程序启动过程
1. **初始化**：加载配置并初始化所有模块
2. **引擎设置**：初始化所有引擎组件
3. **线程创建**：创建执行线程
4. **UI 初始化**：初始化用户界面
5. **运行时启动**：开始主执行循环

### 线程执行周期
1. **执行前检查**：验证线程条件
2. **引擎协调**：协调引擎执行
3. **错误处理**：处理任何执行错误
4. **性能监控**：更新性能指标
5. **线程休眠**：等待下一个执行周期

### 应用程序关闭过程
1. **停止信号**：向所有线程发送停止信号
2. **线程终止**：优雅地终止所有线程
3. **引擎清理**：清理所有引擎资源
4. **配置保存**：保存当前配置
5. **应用程序退出**：最终清理和退出

## API 参考

### 核心函数

#### Runtime_Init()
初始化运行时系统。

**参数：**无

**返回：**布尔值指示成功

#### Runtime_Start()
开始主运行时执行。

**参数：**无

**返回：**布尔值指示成功

#### Runtime_Stop()
停止运行时执行。

**参数：**无

**返回：**布尔值指示成功

#### Runtime_Pause()
暂停运行时执行。

**参数：**无

**返回：**布尔值指示成功

#### Runtime_Resume()
恢复运行时执行。

**参数：**无

**返回：**布尔值指示成功

### 线程管理

#### Runtime_CreateThread(threadConfig)
创建新的执行线程。

**参数：**
- `threadConfig`（Map）：线程配置

**返回：**线程 ID

#### Runtime_StartThread(threadId)
启动特定线程。

**参数：**
- `threadId`（整数）：线程标识符

**返回：**布尔值指示成功

#### Runtime_StopThread(threadId)
停止特定线程。

**参数：**
- `threadId`（整数）：线程标识符

**返回：**布尔值指示成功

#### Runtime_GetThreadState(threadId)
获取特定线程的状态。

**参数：**
- `threadId`（整数）：线程标识符

**返回：**线程状态映射

### 性能监控

#### Runtime_GetPerformanceMetrics()
获取当前性能指标。

**参数：**无

**返回：**性能指标映射

#### Runtime_GetEnginePerformance(engineName)
获取特定引擎的性能指标。

**参数：**
- `engineName`（字符串）：引擎名称

**返回：**引擎性能指标

#### Runtime_ResetPerformanceMetrics()
重置性能指标。

**参数：**无

**返回：**布尔值指示成功

## 使用示例

### 基本运行时控制
```ahk
; 初始化运行时系统
if (Runtime_Init()) {
    ; 启动运行时
    if (Runtime_Start()) {
        Logger_Info("Runtime", "运行时已启动")
    }
}

; 暂停和恢复运行时
Runtime_Pause()
Sleep, 5000 ; 暂停 5 秒
Runtime_Resume()

; 停止运行时
Runtime_Stop()
```

### 线程管理
```ahk
; 创建新线程
threadConfig := {
    Name: "RotationThread",
    Priority: "Normal",
    IntervalMs: 100,
    EngineDependencies: ["RotationEngine", "CastEngine"]
}

threadId := Runtime_CreateThread(threadConfig)

; 启动线程
if (Runtime_StartThread(threadId)) {
    Logger_Info("Runtime", "线程已启动", {"threadId": threadId})
}

; 获取线程状态
threadState := Runtime_GetThreadState(threadId)
Logger_Info("Runtime", "线程状态", threadState)
```

### 性能监控
```ahk
; 获取性能指标
metrics := Runtime_GetPerformanceMetrics()
Logger_Info("Runtime", "性能指标", metrics)

; 获取特定引擎性能
rotationPerf := Runtime_GetEnginePerformance("RotationEngine")
Logger_Info("Runtime", "旋转引擎性能", rotationPerf)

; 重置性能指标
Runtime_ResetPerformanceMetrics()
```

## 配置集成

### 运行时配置
运行时设置存储在配置文件数据中：

```ahk
profile := App["ProfileData"]
profile["RuntimeConfig"] := {
    DefaultThreadPriority: "Normal",
    DefaultThreadInterval: 100,
    PerformanceMonitoring: true
}
```

### 线程配置
线程配置可以动态调整：

```ahk
; 动态调整线程间隔
threadState := Runtime_GetThreadState(threadId)
if (threadState["ErrorCount"] > 5) {
    ; 增加间隔以减少错误
    threadState["IntervalMs"] := 200
}
```

## 性能考虑

### 优化策略
1. **线程调度优化**：优化线程执行间隔
2. **资源管理**：高效管理线程资源
3. **错误恢复**：实现智能错误恢复机制
4. **性能监控**：实时监控系统性能

### 内存管理
- 线程资源在终止时正确释放
- 性能数据定期清理
- 内存泄漏检测和预防

## 错误处理

运行时模块包含全面的错误处理：
- 线程创建失败
- 引擎初始化错误
- 性能监控错误
- 资源分配失败

## 调试功能

### 运行时调试接口
模块提供实时监控的调试接口：

```ahk
; 启用运行时调试
Runtime_EnableDebug()

; 获取调试信息
debugInfo := Runtime_GetDebugInfo()
```

### 线程调试
详细的线程状态信息用于调试：

```ahk
; 获取所有线程状态
allThreads := Runtime_GetAllThreads()
for threadId, state in allThreads {
    Logger_Debug("Runtime", "线程状态", {"threadId": threadId, "state": state})
}
```

## 依赖项

- 所有引擎模块用于执行协调
- 配置系统用于运行时设置
- 日志系统用于活动跟踪
- UI 系统用于状态显示

## 相关模块

- [所有引擎模块](../engines/README.md) - 执行协调
- [配置系统](../core/README.md) - 运行时设置管理
- [日志模块](../logging/README.md) - 活动日志记录
- [UI 系统](../ui/README.md) - 状态显示界面