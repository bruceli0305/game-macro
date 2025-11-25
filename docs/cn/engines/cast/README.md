# Cast 引擎文档

Cast 引擎处理 Game Macro 系统的技能执行、施法机制和技能状态管理。

[English Version](../../engines/cast/README.md) | [中文版本](README.md)

## 概述

Cast 引擎提供：
- 技能执行和热键发送
- 施法条检测和监控
- 技能冷却时间跟踪
- 技能准备状态检查
- 多线程技能执行

## 架构

引擎设计用于与旋转和规则系统协同工作：

### CastEngine.ahk（主引擎）
主技能执行和管理系统。

### 集成点
- **旋转引擎**：接收技能执行请求
- **规则引擎**：提供技能状态信息
- **UI 系统**：提供施法调试界面

## 关键组件

### 技能执行系统
管理技能热键的实际发送和执行监控。

#### 技能配置
```ahk
Skill := {
    Id: 1,
    Name: "火球术",
    Key: "1",
    X: 100,
    Y: 200,
    Color: "0xFF0000",
    Tolerance: 10,
    CooldownMs: 2000,
    CastTimeMs: 1500,
    CheckReady: true,
    ThreadId: 1
}
```

### 施法条检测
监控施法条以确定技能执行状态。

#### 施法条配置
```ahk
CastBar := {
    Enabled: true,
    X: 500,
    Y: 600,
    Width: 200,
    Height: 20,
    ActiveColor: "0x00FF00",
    InactiveColor: "0x000000",
    Tolerance: 5
}
```

### 技能状态跟踪
跟踪所有技能的当前状态。

#### 技能状态结构
```ahk
SkillState := {
    IsCasting: false,
    CastStartTime: 0,
    CastEndTime: 0,
    LastUsed: 0,
    CooldownEnd: 0,
    IsReady: true
}
```

## 执行流程

### 技能执行过程
1. **执行前检查**：验证技能准备状态和条件
2. **热键发送**：发送技能热键
3. **施法监控**：如果启用则监控施法条
4. **状态更新**：更新技能冷却时间和状态
5. **执行后处理**：处理任何后续操作

### 施法条监控算法
1. 采样施法条区域
2. 检测活动施法状态
3. 跟踪施法进度
4. 检测施法完成
5. 相应更新技能状态

## API 参考

### 核心函数

#### CastEngine_Init()
初始化施法引擎。

**参数：**无

**返回：**布尔值指示成功

#### CastEngine_ExecuteSkill(skillId, threadId)
执行特定技能。

**参数：**
- `skillId`（整数）：技能标识符
- `threadId`（整数）：执行线程 ID

**返回：**布尔值指示执行成功

#### CastEngine_IsSkillReady(skillId)
检查技能是否准备使用。

**参数：**
- `skillId`（整数）：技能标识符

**返回：**布尔值指示技能准备状态

#### CastEngine_GetSkillCooldown(skillId)
获取技能的剩余冷却时间。

**参数：**
- `skillId`（整数）：技能标识符

**返回：**整数冷却时间（毫秒）

### 技能管理

#### CastEngine_AddSkill(skillConfig)
向引擎添加新技能。

**参数：**
- `skillConfig`（Map）：技能配置

**返回：**技能 ID

#### CastEngine_UpdateSkill(skillId, skillConfig)
更新现有技能配置。

**参数：**
- `skillId`（整数）：技能标识符
- `skillConfig`（Map）：更新的技能配置

**返回：**布尔值指示成功

#### CastEngine_RemoveSkill(skillId)
从引擎移除技能。

**参数：**
- `skillId`（整数）：技能标识符

**返回：**布尔值指示成功

### 施法条管理

#### CastEngine_EnableCastBar(skillId, config)
为技能启用施法条检测。

**参数：**
- `skillId`（整数）：技能标识符
- `config`（Map）：施法条配置

**返回：**布尔值指示成功

#### CastEngine_DisableCastBar(skillId)
为技能禁用施法条检测。

**参数：**
- `skillId`（整数）：技能标识符

**返回：**布尔值指示成功

## 使用示例

### 基本技能配置
```ahk
; 配置简单技能
fireballSkill := {
    Id: 1,
    Name: "火球术",
    Key: "1",
    X: 100,
    Y: 200,
    Color: "0xFF0000",
    Tolerance: 10,
    CooldownMs: 2000,
    CheckReady: true,
    ThreadId: 1
}

CastEngine_AddSkill(fireballSkill)
```

### 带施法条监控的技能
```ahk
; 带施法条检测的技能
healSkill := {
    Id: 2,
    Name: "治疗术",
    Key: "2",
    X: 150,
    Y: 200,
    Color: "0x00FF00",
    Tolerance: 5,
    CooldownMs: 3000,
    CastTimeMs: 2500,
    CheckReady: true,
    ThreadId: 1
}

; 添加施法条配置
castBarConfig := {
    Enabled: true,
    X: 500,
    Y: 600,
    Width: 200,
    Height: 20,
    ActiveColor: "0x00FF00",
    InactiveColor: "0x000000",
    Tolerance: 5
}

CastEngine_AddSkill(healSkill)
CastEngine_EnableCastBar(2, castBarConfig)
```

### 旋转中的技能执行
```ahk
; 作为旋转一部分执行技能
if (CastEngine_IsSkillReady(skillId)) {
    success := CastEngine_ExecuteSkill(skillId, threadId)
    if (success) {
        ; 技能执行成功
        Logger_Info("CastEngine", "技能已执行", Map("skillId", skillId))
    }
}
```

### 技能状态监控
```ahk
; 检查技能状态以进行规则条件
if (!CastEngine_IsSkillReady(skillId)) {
    cooldown := CastEngine_GetSkillCooldown(skillId)
    Logger_Info("CastEngine", "技能冷却中", Map("skillId", skillId, "cooldown", cooldown))
}
```

## 配置集成

### 配置文件集成
技能存储在配置文件数据中，随配置文件加载：

```ahk
profile := App["ProfileData"]
profile["Skills"] := [skill1, skill2, skill3]
```

### 线程管理
技能可以分配给不同的执行线程以进行并行处理。

## 性能考虑

### 优化策略
1. **像素采样优化**：最小化施法条采样频率
2. **冷却时间缓存**：缓存冷却时间计算
3. **状态验证**：执行前验证技能状态
4. **线程安全**：确保多线程执行的适当同步

### 内存管理
- 技能配置在添加时验证
- 无效配置被拒绝并显示错误消息
- 资源在技能移除时清理

## 错误处理

施法引擎包含全面的错误处理：
- 无效技能配置
- 施法条检测失败
- 热键发送错误
- 线程同步问题

## 调试功能

### 施法调试接口
引擎提供实时监控的调试接口：

```ahk
; 启用施法调试
CastEngine_EnableDebug()

; 获取调试信息
debugInfo := CastEngine_GetDebugInfo()
```

### 日志集成
所有施法引擎活动都记录日志以便故障排除：
- 技能执行尝试
- 施法条检测结果
- 冷却时间状态更改
- 错误条件

## 依赖项

- 像素检测引擎用于施法条监控
- 热键管理系统用于技能执行
- 计时工具用于冷却时间跟踪
- 配置系统用于技能持久化

## 相关模块

- [旋转引擎](../rotation/README.md) - 技能旋转自动化
- [规则引擎](../rules/README.md) - 条件技能执行
- [增益引擎](../buff/README.md) - 增益效果集成
- [UI 系统](../../ui/README.md) - 施法调试界面