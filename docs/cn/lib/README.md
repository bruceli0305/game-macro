# 原生库文档

原生库模块为性能关键操作提供 C++ 实现，特别是 DirectX Graphics Infrastructure (DXGI) 屏幕捕获功能。

[English Version](../../lib/README.md) | [中文版本](README.md)

## 概述

原生库模块包含：
- **dxgi_dup.cpp**：DXGI 复制的 C++ 源代码
- **dxgi_dup.dll**：用于 DXGI 操作的编译原生库
- 高性能屏幕捕获功能
- 硬件加速像素检测
- 多显示器支持

## 架构

原生库提供对 DirectX 功能的低级访问：

### dxgi_dup.cpp（C++ 源代码）
DXGI 复制 API 的原生 C++ 实现。

### dxgi_dup.dll（编译库）
由 AutoHotkey 脚本加载的预编译原生库。

### 集成点
- **DXGI 引擎**：原生库的主要使用者
- **像素检测**：硬件加速屏幕捕获
- **性能监控**：低级性能指标
- **错误处理**：原生错误报告

## 关键组件

### DXGI 复制接口
低级 DirectX Graphics Infrastructure API 包装器。

#### 核心 DXGI 函数
```cpp
// 初始化和管理
int DX_Init(int output, int fps, const char* dllPath);
int DX_Shutdown();
bool DX_IsReady();

// 像素检索
int DX_GetPixel(int x, int y);

// 输出管理
int DX_EnumOutputs();
const char* DX_GetOutputName(int idx);
int DX_SelectOutput(int idx);

// 配置
void DX_SetFPS(int fps);

// 错误处理
DX_ErrorInfo DX_LastError();
```

### 错误处理系统
全面的错误报告和恢复机制。

#### 错误信息结构
```cpp
struct DX_ErrorInfo {
    int Code;                    // 错误代码
    const char* Text;           // 错误描述
    const char* Function;       // 函数名
    int Line;                   // 源代码行
    DWORD SystemError;          // 系统错误代码
};
```

### 性能监控
实时性能指标和统计信息。

#### 性能指标
```cpp
struct DX_PerformanceStats {
    DWORD FrameCount;           // 处理的总帧数
    DWORD PixelRequests;       // 像素检索请求
    DWORD Errors;              // 错误计数
    DWORD RecoveryAttempts;    // 恢复尝试
    DWORD LastFrameTime;       // 最后帧处理时间
    DWORD AverageFrameTime;    // 平均帧时间
};
```

## 执行流程

### 库初始化过程
1. **DLL 加载**：将 dxgi_dup.dll 加载到内存中
2. **函数解析**：解析导出的函数地址
3. **DXGI 初始化**：初始化 DirectX Graphics Infrastructure
4. **输出枚举**：发现可用的显示输出
5. **复制设置**：设置屏幕复制
6. **就绪状态**：将库标记为可操作状态

### 像素检索过程
1. **坐标验证**：验证屏幕坐标
2. **帧获取**：获取当前屏幕帧
3. **像素访问**：从帧缓冲区访问像素数据
4. **颜色提取**：提取 RGB 颜色值
5. **帧释放**：释放帧资源
6. **错误处理**：处理检索失败

### 错误恢复过程
1. **错误检测**：监控 DXGI 错误
2. **状态评估**：评估当前库状态
3. **资源清理**：释放有问题的资源
4. **重新初始化**：尝试库重新初始化
5. **回退激活**：激活回退机制

## API 参考

### 核心库函数

#### DX_Init(output, fps, dllPath)
初始化 DXGI 复制库。

**参数：**
- `output`（整数）：显示输出索引（从 0 开始）
- `fps`（整数）：目标帧率
- `dllPath`（const char*）：DLL 文件路径

**返回：**整数（0 = 成功，负数 = 错误）

**错误代码：**
- `-1`：DLL 加载失败
- `-2`：DXGI 初始化失败
- `-3`：输出选择失败
- `-4`：复制设置失败

#### DX_Shutdown()
关闭 DXGI 复制库并释放资源。

**参数：**无

**返回：**整数（0 = 成功，负数 = 错误）

#### DX_IsReady()
检查 DXGI 库是否准备好进行操作。

**参数：**无

**返回：**布尔值（true = 就绪，false = 未就绪）

### 像素检索函数

#### DX_GetPixel(x, y)
检索指定坐标处的像素颜色。

**参数：**
- `x`（整数）：X 坐标
- `y`（整数）：Y 坐标

**返回：**整数（RGB 颜色值，-1 = 错误）

### 输出管理函数

#### DX_EnumOutputs()
枚举可用的显示输出。

**参数：**无

**返回：**整数（可用输出数量）

#### DX_GetOutputName(idx)
获取指定输出的名称。

**参数：**
- `idx`（整数）：输出索引（从 0 开始）

**返回：**const char*（输出名称，nullptr = 错误）

#### DX_SelectOutput(idx)
选择指定输出进行复制。

**参数：**
- `idx`（整数）：输出索引（从 0 开始）

**返回：**整数（0 = 成功，负数 = 错误）

### 配置函数

#### DX_SetFPS(fps)
设置复制的帧率。

**参数：**
- `fps`（整数）：目标帧率

**返回：**void

### 错误处理函数

#### DX_LastError()
获取最后的错误信息。

**参数：**无

**返回：**DX_ErrorInfo（错误信息结构）

## 使用示例

### 基本库初始化
```cpp
// 初始化 DXGI 库
int result = DX_Init(0, 60, "dxgi_dup.dll");
if (result == 0) {
    // 库初始化成功
    printf("DXGI 库初始化成功\n");
} else {
    // 处理错误
    DX_ErrorInfo error = DX_LastError();
    printf("初始化失败: %s\n", error.Text);
}
```

### 像素检索
```cpp
// 检查库状态
if (DX_IsReady()) {
    // 检索像素颜色
    int color = DX_GetPixel(100, 200);
    if (color != -1) {
        printf("像素颜色: 0x%06X\n", color);
    } else {
        DX_ErrorInfo error = DX_LastError();
        printf("像素检索失败: %s\n", error.Text);
    }
}
```

### 输出管理
```cpp
// 枚举可用输出
int outputCount = DX_EnumOutputs();
printf("可用输出数量: %d\n", outputCount);

// 列出所有输出名称
for (int i = 0; i < outputCount; i++) {
    const char* name = DX_GetOutputName(i);
    if (name) {
        printf("输出 %d: %s\n", i, name);
    }
}
```

### 错误处理
```cpp
// 尝试操作并处理错误
int result = DX_SelectOutput(1);
if (result != 0) {
    DX_ErrorInfo error = DX_LastError();
    printf("错误代码: %d\n", error.Code);
    printf("错误描述: %s\n", error.Text);
    printf("函数: %s\n", error.Function);
    printf("行号: %d\n", error.Line);
}
```

## 配置集成

### 库路径配置
DLL 路径可以通过配置文件指定：

```cpp
// 从配置加载 DLL 路径
const char* dllPath = Config_GetString("DXGI", "DllPath", "dxgi_dup.dll");
```

### 性能配置
帧率和其他性能设置可以通过配置调整：

```cpp
// 从配置加载帧率设置
int targetFPS = Config_GetInt("DXGI", "TargetFPS", 60);
DX_SetFPS(targetFPS);
```

## 性能考虑

### 优化策略
1. **帧率控制**：根据需求调整目标帧率
2. **错误恢复**：实现智能错误恢复机制
3. **资源管理**：高效管理 DirectX 资源
4. **内存使用**：优化内存分配和释放

### 内存管理
- DirectX 资源在关闭时正确释放
- 错误状态下的资源清理
- 内存泄漏检测和预防

## 错误处理

原生库包含全面的错误处理：
- DXGI API 错误
- 资源分配失败
- 硬件兼容性问题
- 系统级错误

## 调试功能

### 性能监控接口
库提供实时性能监控：

```cpp
// 获取性能统计
DX_PerformanceStats stats = DX_GetPerformanceStats();
printf("帧数: %lu\n", stats.FrameCount);
printf("平均帧时间: %lu ms\n", stats.AverageFrameTime);
```

### 错误调试接口
详细的错误信息用于调试：

```cpp
// 启用详细错误报告
DX_EnableDebug(true);

// 获取调试信息
DX_DebugInfo debugInfo = DX_GetDebugInfo();
```

## 依赖项

- DirectX Graphics Infrastructure (DXGI)
- Windows API 用于系统集成
- C++ 运行时库
- 硬件图形驱动程序

## 相关模块

- [DXGI 引擎](../engines/pixel/README.md) - 主要使用者
- [像素检测系统](../engines/pixel/README.md) - 像素检索功能
- [性能监控模块](../runtime/README.md) - 性能指标集成