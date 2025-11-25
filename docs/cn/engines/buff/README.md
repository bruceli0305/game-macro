# Buff 引擎文档

Buff 引擎管理 Game Macro 系统的增益效果、减益效果和状态效果的检测与跟踪。

[English Version](../../engines/buff/README.md) | [中文版本](README.md)

## 概述

Buff 引擎提供：
- 通过像素识别检测增益/减益效果
- 状态效果跟踪和监控
- 增益效果持续时间管理
- 增益效果堆叠和优先级处理
- 与技能执行的集成

## 架构

引擎设计用于与旋转和规则系统协同工作：

### BuffEngine.ahk（主引擎）
主增益效果检测和管理系统。

### 集成点
- **旋转引擎**：为旋转决策提供增益状态信息
- **规则引擎**：提供基于增益效果的条件检查
- **施法引擎**：依赖增益效果的技能执行
- **UI 系统**：增益效果监控界面

## 关键组件

### 增益效果检测系统
通过像素识别管理增益效果和减益效果的检测。

#### 增益效果配置
```ahk
Buff := {
    Id: 1,
    Name: "力量提升",
    Type: "buff",
    X: 100,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0xFF0000",
    Tolerance: 10,
    DurationMs: 15000,
    Priority: 1,
    Stackable: false,
    MaxStacks: 1,
    Required: false
}
```

### 状态效果跟踪
跟踪活动增益效果及其剩余持续时间。

#### 增益状态结构
```ahk
BuffState := {
    BuffId: 1,
    Name: "力量提升",
    IsActive: true,
    StartTime: 0,
    EndTime: 15000,
    RemainingMs: 12000,
    Stacks: 1,
    IsExpired: false
}
```

### 增益效果优先级系统
处理增益效果优先级以进行旋转决策。

#### 优先级配置
```ahk
BuffPriority := {
    High: ["力量提升", "致命一击"],
    Medium: ["急速", "攻击力"],
    Low: ["次要增益", "防御冷却"]
}
```

## 执行流程

### 增益效果检测过程
1. **像素采样**：采样增益效果图标区域
2. **颜色匹配**：与配置的颜色比较
3. **状态确定**：确定增益效果活动/非活动状态
4. **持续时间跟踪**：如果活动则跟踪增益效果持续时间
5. **状态更新**：更新增益状态信息

### 增益效果监控算法
1. 定期检查所有配置的增益效果
2. 更新活动增益状态
3. 处理增益效果过期
4. 触发增益相关操作

## API 参考

### 核心函数

#### BuffEngine_Init()
初始化增益引擎。

**参数：**无

**返回：**布尔值指示成功

#### BuffEngine_DetectBuffs()
对所有配置的增益效果执行增益检测。

**参数：**无

**返回：**检测到的增益状态数组

#### BuffEngine_IsBuffActive(buffId)
检查特定增益效果是否活动。

**参数：**
- `buffId`（整数）：增益效果标识符

**返回：**布尔值指示增益活动状态

#### BuffEngine_GetBuffRemaining(buffId)
获取增益效果的剩余持续时间。

**参数：**
- `buffId`（整数）：增益效果标识符

**返回：**整数持续时间（毫秒）

### 增益效果管理

#### BuffEngine_AddBuff(buffConfig)
向检测系统添加新增益效果。

**参数：**
- `buffConfig`（Map）：增益效果配置

**返回：**增益效果 ID

#### BuffEngine_UpdateBuff(buffId, buffConfig)
更新现有增益效果配置。

**参数：**
- `buffId`（整数）：增益效果标识符
- `buffConfig`（Map）：更新的增益效果配置

**返回：**布尔值指示成功

#### BuffEngine_RemoveBuff(buffId)
从检测系统移除增益效果。

**参数：**
- `buffId`（整数）：增益效果标识符

**返回：**布尔值指示成功

### 增益状态管理

#### BuffEngine_GetActiveBuffs()
获取所有当前活动的增益效果。

**参数：**无

**返回：**活动增益状态数组

#### BuffEngine_GetBuffState(buffId)
获取特定增益效果的完整状态。

**参数：**
- `buffId`（整数）：增益效果标识符

**返回：**增益状态映射

#### BuffEngine_ResetBuff(buffId)
重置特定增益效果的跟踪。

**参数：**
- `buffId`（整数）：增益效果标识符

**返回：**布尔值指示成功

## 使用示例

### 基本增益效果配置
```ahk
; 配置简单增益效果
powerBoost := {
    Id: 1,
    Name: "力量提升",
    Type: "buff",
    X: 100,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0xFF0000",
    Tolerance: 10,
    DurationMs: 15000,
    Priority: 1,
    Stackable: false,
    MaxStacks: 1,
    Required: false
}

BuffEngine_AddBuff(powerBoost)
```

### 减益效果配置
```ahk
; 配置减益效果
slowDebuff := {
    Id: 2,
    Name: "减速",
    Type: "debuff",
    X: 150,
    Y: 200,
    Width: 30,
    Height: 30,
    Color: "0x0000FF",
    Tolerance: 5,
    DurationMs: 10000,
    Priority: 2,
    Stackable: true,
    MaxStacks: 3,
    Required: false
}

BuffEngine_AddBuff(slowDebuff)
```

### 旋转中的增益效果检测
```ahk
; 检查增益状态以进行旋转决策
if (BuffEngine_IsBuffActive(powerBoostId)) {
    ; 增益效果活动，执行高优先级技能
    RotationEngine_ExecuteHighPriority()
} else {
    ; 增益效果不活动，执行正常旋转
    RotationEngine_ExecuteNormal()
}
```

### 基于增益效果的规则条件
```ahk
; 基于增益状态创建规则
rule := {
    Condition: {
        Type: "buff",
        BuffId: powerBoostId,
        Operator: "active",
        Duration: 5000
    },
    Action: {
        Type: "skill",
        SkillId: highDamageSkillId
    }
}

RuleEngine_AddRule(rule)
```

### 增益效果监控循环
```ahk
; 连续增益效果监控
while (App["IsRunning"]) {
    activeBuffs := BuffEngine_DetectBuffs()
    
    ; 处理增益状态
    for buffState in activeBuffs {
        if (buffState["IsActive"]) {
            remaining := buffState["RemainingMs"]
            Logger_Info("BuffEngine", "增益效果活动", Map(
                "buffId", buffState["BuffId"],
                "remaining", remaining
            ))
        }
    }
    
    Sleep(100) ; 每 100ms 检查一次
}
```

## 配置集成

### 配置文件集成
增益效果存储在配置文件数据中，随配置文件加载：

```ahk
profile := App["ProfileData"]
profile["Buffs"] := [buff1, buff2, buff3]
```

### 增益效果优先级配置
每个配置文件可以配置增益效果优先级：

```ahk
profile["BuffPriority"] := {
    High: ["力量提升", "致命一击"],
    Medium: ["急速", "攻击力"],
    Low: ["次要增益", "防御冷却"]
}
```

## 性能考虑

### 优化策略
1. **选择性检测**：仅检测与当前旋转相关的增益效果
2. **检测频率**：根据增益效果持续时间调整检测频率
3. **缓存**：缓存增益状态以减少检测频率
4. **区域优化**：优化像素采样区域

### 内存管理
- 增益效果配置在添加时验证
- 无效配置被拒绝并显示错误消息
- 增益状态在过期时清理

## 错误处理

增益引擎包含全面的错误处理：
- 无效增益效果配置
- 像素检测失败
- 状态跟踪错误
- 优先级计算问题

## 调试功能

### 增益效果调试接口
引擎提供实时监控的调试接口：

```ahk
; 启用增益效果调试
BuffEngine_EnableDebug()

; 获取调试信息
debugInfo := BuffEngine_GetDebugInfo()
```

### 日志集成
所有增益引擎活动都记录日志以便故障排除：
- 增益检测结果
- 状态更改
- 优先级计算
- 错误条件

## 依赖项

- 像素检测引擎用于增益效果图标识别
- 计时工具用于持续时间跟踪
- 配置系统用于增益效果持久化
- 规则引擎用于基于增益效果的条件

## 相关模块

- [旋转引擎](../rotation/README.md) - 基于增益效果的旋转决策
- [规则引擎](../rules/README.md) - 增益效果条件检查
- [施法引擎](../cast/README.md) - 依赖增益效果的技能执行
- [UI 系统](../../ui/README.md) - 增益效果监控界面