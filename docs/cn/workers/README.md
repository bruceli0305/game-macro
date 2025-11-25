# 工作者模块文档

工作者模块管理 Game Macro 系统的后台任务、异步操作和专用工作线程。

[English Version](../../workers/README.md) | [中文版本](README.md)

## 概述

工作者模块提供：
- 后台任务执行
- 异步操作管理
- 专用工作线程
- 资源隔离和管理
- 通过并行处理进行性能优化

## 架构

工作者系统设计用于专门的背景操作：

### Workers.ahk（主工作者管理器）
主工作者管理和协调系统。

### 集成点
- **运行时模块**：工作者线程生命周期管理
- **引擎**：引擎操作的专用工作者
- **UI 系统**：工作者状态监控
- **配置系统**：工作者配置管理

## 关键组件

### 工作者线程管理
管理不同任务的专用工作者线程。

#### 工作者配置
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

### 后台任务系统
管理长时间运行的后台任务。

#### 任务配置
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

### 异步操作系统
管理带有回调的异步操作。

#### 异步操作结构
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

## 执行流程

### 工作者线程生命周期
1. **工作者创建**：使用特定配置创建工作者
2. **资源分配**：分配所需资源
3. **线程启动**：启动工作者线程执行
4. **任务执行**：执行分配的任务
5. **资源清理**：停止时清理资源
6. **线程终止**：优雅地终止工作者线程

### 后台任务执行
1. **任务调度**：基于间隔调度任务
2. **执行前检查**：验证任务条件
3. **任务执行**：执行任务函数
4. **执行后处理**：处理结果和清理
5. **重新调度**：调度下一次执行

### 异步操作流程
1. **操作创建**：创建异步操作
2. **执行开始**：开始异步执行
3. **进度监控**：监控操作进度
4. **完成处理**：处理操作完成
5. **回调执行**：执行完成回调

## API 参考

### 核心函数

#### Workers_Init()
初始化工作者系统。

**参数：**无

**返回：**布尔值指示成功

#### Workers_Start()
启动所有启用的工作者。

**参数：**无

**返回：**布尔值指示成功

#### Workers_Stop()
停止所有工作者。

**参数：**无

**返回：**布尔值指示成功

#### Workers_Pause()
暂停所有工作者。

**参数：**无

**返回：**布尔值指示成功

#### Workers_Resume()
恢复所有工作者。

**参数：**无

**返回：**布尔值指示成功

### 工作者管理

#### Workers_CreateWorker(workerConfig)
创建新工作者。

**参数：**
- `workerConfig`（映射）：工作者配置

**返回：**工作者 ID

#### Workers_StartWorker(workerId)
启动特定工作者。

**参数：**
- `workerId`（整数）：工作者标识符

**返回：**布尔值指示成功

#### Workers_StopWorker(workerId)
停止特定工作者。

**参数：**
- `workerId`（整数）：工作者标识符

**返回：**布尔值指示成功

#### Workers_GetWorkerState(workerId)
获取特定工作者的状态。

**参数：**
- `workerId`（整数）：工作者标识符

**返回：**工作者状态映射

### 后台任务管理

#### Workers_AddBackgroundTask(taskConfig)
添加新的后台任务。

**参数：**
- `taskConfig`（映射）：任务配置

**返回：**任务 ID

#### Workers_RemoveBackgroundTask(taskId)
移除后台任务。

**参数：**
- `taskId`（整数）：任务标识符

**返回：**布尔值指示成功

#### Workers_ExecuteBackgroundTask(taskId)
立即执行后台任务。

**参数：**
- `taskId`（整数）：任务标识符

**返回：**布尔值指示成功

### 异步操作

#### Workers_CreateAsyncOperation(opConfig)
创建新的异步操作。

**参数：**
- `opConfig`（映射）：操作配置

**返回：**操作 ID

#### Workers_StartAsyncOperation(opId)
启动异步操作。

**参数：**
- `opId`（整数）：操作标识符

**返回：**布尔值指示成功

#### Workers_GetAsyncOperationStatus(opId)
获取异步操作的状态。

**参数：**
- `opId`（整数）：操作标识符

**返回：**操作状态映射

## 使用示例

### 基本工作者创建
```ahk
; 创建像素检测工作者
pixelWorker := {
    Id: 1,
    Name: "PixelDetectionWorker",
    Type: "Background",
    Priority: "High",
    IntervalMs: 50,
    Dependencies: ["PixelEngine"]
}

workerId := Workers_CreateWorker(pixelWorker)

; 启动工作者
if (Workers_StartWorker(workerId)) {
    Logger_Info("Workers", "像素检测工作者已启动", Map("workerId", workerId))
}
```

### 自动保存的后台任务
```ahk
; 创建自动保存后台任务
autoSaveTask := {
    Id: 1,
    Name: "ProfileAutoSave",
    Type: "Periodic",
    IntervalMs: 30000, ; 30 秒
    IsEnabled: true,
    Function: "AutoSaveProfiles",
    Parameters: {}
}

taskId := Workers_AddBackgroundTask(autoSaveTask)

; 自动保存函数
AutoSaveProfiles() {
    if (App["ProfileData"]["IsModified"]) {
        Storage_SaveProfile(App["CurrentProfile"])
        Logger_Info("Workers", "配置文件已自动保存")
    }
}
```

### 异步图像处理
```ahk
; 创建异步图像处理操作
imageOp := {
    Id: 1,
    Name: "ImageProcessing",
    Type: "Async",
    Callback: "ProcessImageComplete",
    ErrorHandler: "ProcessImageError"
}

opId := Workers_CreateAsyncOperation(imageOp)

; 启动操作
Workers_StartAsyncOperation(opId)

; 回调函数
ProcessImageComplete(result) {
    Logger_Info("Workers", "图像处理已完成", result)
    UI_UpdateImage(result["ProcessedImage"])
}

ProcessImageError(error) {
    Logger_Error("Workers", "图像处理失败", error)
    UI_ShowError("图像处理错误")
}
```

### 带资源监控的工作者
```ahk
; 带资源监控的工作者
resourceWorker := {
    Id: 2,
    Name: "ResourceMonitor",
    Type: "Monitoring",
    Priority: "Low",
    IntervalMs: 1000,
    Dependencies: []
}

resourceId := Workers_CreateWorker(resourceWorker)

; 带资源监控的工作者函数
Workers_RegisterWorkerFunction(resourceId, Func("MonitorResources"))

MonitorResources() {
    ; 监控系统资源
    cpuUsage := GetCPUUsage()
    memoryUsage := GetMemoryUsage()
    
    ; 记录资源使用情况
    Logger_Debug("Workers", "资源使用情况", Map(
        "CPU", cpuUsage,
        "Memory", memoryUsage
    ))
    
    ; 根据资源使用情况调整工作者优先级
    if (cpuUsage > 80) {
        Workers_AdjustPriorities("Low")
    }
}
```

### 工作者中的错误处理
```ahk
; 带错误处理的工作者
errorWorker := {
    Id: 3,
    Name: "ErrorHandlingWorker",
    Type: "ErrorRecovery",
    Priority: "Normal",
    IntervalMs: 5000,
    Dependencies: []
}

errorId := Workers_CreateWorker(errorWorker)

; 错误处理函数
Workers_RegisterWorkerFunction(errorId, Func("HandleWorkerErrors"))

HandleWorkerErrors() {
    ; 检查工作者错误
    errorWorkers := Workers_GetErrorWorkers()
    
    for worker in errorWorkers {
        Logger_Warning("Workers", "检测到工作者错误", Map(
            "workerId", worker["Id"],
            "errorCount", worker["ErrorCount"]
        ))
        
        ; 尝试恢复
        if (worker["ErrorCount"] < 3) {
            Workers_RestartWorker(worker["Id"])
        } else {
            ; 错误过多，禁用工作者
            Workers_StopWorker(worker["Id"])
            Logger_Error("Workers", "工作者因错误被禁用", Map("workerId", worker["Id"]))
        }
    }
}
```

## 配置集成

### 工作者设置
工作者设置存储在主配置中：

```ahk
App["WorkerConfig"] := {
    MaxWorkers: 5,
    DefaultInterval: 100,
    ResourceMonitoring: true,
    AutoRecovery: true,
    MaxErrorCount: 3
}
```

### 工作者特定配置
工作者配置可以是配置文件特定的：

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

## 性能考虑

### 优化策略
1. **工作者优先级分配**：根据任务重要性分配适当的优先级
2. **执行间隔优化**：平衡性能和响应性
3. **资源管理**：高效的资源分配和清理
4. **错误恢复**：快速错误恢复，最小化中断

### 内存管理
- 工作者资源被正确分配和释放
- 后台任务被高效管理
- 异步操作在完成后被清理

## 错误处理

工作者模块包含全面的错误处理：
- 工作者崩溃检测和恢复
- 后台任务错误处理
- 异步操作失败管理
- 资源分配错误

## 调试功能

### 工作者调试接口
模块提供用于实时监控的调试接口：

```ahk
; 启用工作者调试
Workers_EnableDebug()

; 获取调试信息
debugInfo := Workers_GetDebugInfo()
```

### 日志集成
所有工作者活动都被记录用于故障排除：
- 工作者生命周期事件
- 后台任务执行
- 异步操作状态变更
- 错误条件和恢复尝试

## 依赖项

- 运行时模块用于线程管理
- 引擎模块用于专用工作者操作
- UI 系统用于工作者状态显示
- 配置系统用于工作者设置

## 相关模块

- [运行时模块](../runtime/README.md) - 线程生命周期管理
- [引擎模块](../engines/README.md) - 引擎特定的工作者
- [UI 模块](../ui/README.md) - 工作者状态监控
- [核心模块](../core/README.md) - 核心应用程序功能