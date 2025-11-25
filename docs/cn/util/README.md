# 工具模块文档

工具模块为 Game Macro 系统提供必要的辅助函数、对象工具和 ID 生成服务。

[English Version](../../util/README.md) | [中文版本](README.md)

## 概述

工具模块提供：
- 通用辅助函数
- 对象操作工具
- 唯一 ID 生成
- 常见工具操作
- 跨模块工具服务

## 架构

工具系统组织为专门的工具组件：

### Utils.ahk（通用工具）
用于常见操作的主要工具函数。

### Obj.ahk（对象工具）
对象操作和管理工具。

### IdGen.ahk（ID 生成）
唯一标识符生成系统。

### 集成点
- **所有模块**：为所有系统模块提供工具服务
- **核心模块**：核心工具函数
- **配置系统**：配置管理的工具函数

## 关键组件

### 通用工具 (Utils.ahk)
提供整个系统使用的通用工具函数。

#### 工具函数类别
- **字符串操作**：字符串处理和格式化
- **数学函数**：数学工具和计算
- **文件操作**：文件和路径工具
- **系统工具**：系统级辅助函数
- **验证函数**：数据验证工具

### 对象工具 (Obj.ahk)
提供对象操作和管理工具。

#### 对象工具函数
- **对象创建**：对象实例化工具
- **对象操作**：属性管理和修改
- **对象验证**：对象结构验证
- **对象序列化**：对象序列化和反序列化

### ID 生成 (IdGen.ahk)
提供唯一标识符生成服务。

#### ID 生成类型
- **顺序 ID**：顺序数字生成
- **UUID 生成**：通用唯一标识符
- **时间戳 ID**：基于时间的标识符
- **自定义 ID**：自定义格式标识符生成

## API 参考

### 通用工具 (Utils.ahk)

#### 字符串操作

##### Utils_Trim(str)
去除字符串两端的空白字符。

**参数：**
- `str`（字符串）：输入字符串

**返回：** 去除空白后的字符串

##### Utils_FormatString(format, args...)
使用提供的参数格式化字符串。

**参数：**
- `format`（字符串）：格式字符串
- `args...`（可变参数）：格式参数

**返回：** 格式化后的字符串

##### Utils_SplitString(str, delimiter)
按分隔符分割字符串。

**参数：**
- `str`（字符串）：输入字符串
- `delimiter`（字符串）：分隔符字符

**返回：** 分割后的字符串数组

#### 数学函数

##### Utils_Random(min, max)
生成 min 和 max 之间的随机数。

**参数：**
- `min`（数字）：最小值
- `max`（数字）：最大值

**返回：** 随机数

##### Utils_Clamp(value, min, max)
将值限制在 min 和 max 之间。

**参数：**
- `value`（数字）：输入值
- `min`（数字）：最小值
- `max`（数字）：最大值

**返回：** 限制后的值

##### Utils_Round(value, decimals)
将数字四舍五入到指定小数位。

**参数：**
- `value`（数字）：输入值
- `decimals`（整数）：小数位数

**返回：** 四舍五入后的数字

#### 文件操作

##### Utils_GetFileExtension(filename)
从文件名获取文件扩展名。

**参数：**
- `filename`（字符串）：文件名

**返回：** 文件扩展名

##### Utils_JoinPath(parts...)
将路径部分连接成完整路径。

**参数：**
- `parts...`（可变参数）：路径组件

**返回：** 连接后的路径字符串

##### Utils_FileExists(filepath)
检查文件是否存在。

**参数：**
- `filepath`（字符串）：文件路径

**返回：** 布尔值指示文件存在性

#### 系统工具

##### Utils_GetTimestamp()
获取当前时间戳（毫秒）。

**参数：**无

**返回：** 当前时间戳

##### Utils_Sleep(ms)
休眠指定的毫秒数。

**参数：**
- `ms`（整数）：休眠毫秒数

**返回：** 无

##### Utils_GetSystemInfo()
获取系统信息。

**参数：**无

**返回：** 系统信息映射

#### 验证函数

##### Utils_IsEmpty(value)
检查值是否为空。

**参数：**
- `value`（任意）：要检查的值

**返回：** 布尔值指示是否为空

##### Utils_IsNumber(value)
检查值是否为数字。

**参数：**
- `value`（任意）：要检查的值

**返回：** 布尔值指示是否为数字

##### Utils_IsString(value)
检查值是否为字符串。

**参数：**
- `value`（任意）：要检查的值

**返回：** 布尔值指示是否为字符串

### 对象工具 (Obj.ahk)

#### 对象创建

##### Obj_Create(properties)
创建具有指定属性的新对象。

**参数：**
- `properties`（映射）：对象属性

**返回：** 新对象

##### Obj_Clone(obj)
创建对象的深拷贝。

**参数：**
- `obj`（映射）：要克隆的对象

**返回：** 克隆的对象

##### Obj_Merge(target, source)
将源对象合并到目标对象中。

**参数：**
- `target`（映射）：目标对象
- `source`（映射）：源对象

**返回：** 合并后的对象

#### 对象操作

##### Obj_GetProperty(obj, propertyPath)
使用点符号从对象获取属性。

**参数：**
- `obj`（映射）：源对象
- `propertyPath`（字符串）：属性路径

**返回：** 属性值

##### Obj_SetProperty(obj, propertyPath, value)
使用点符号在对象中设置属性。

**参数：**
- `obj`（映射）：目标对象
- `propertyPath`（字符串）：属性路径
- `value`（任意）：要设置的值

**返回：** 修改后的对象

##### Obj_DeleteProperty(obj, propertyPath)
从对象中删除属性。

**参数：**
- `obj`（映射）：目标对象
- `propertyPath`（字符串）：属性路径

**返回：** 修改后的对象

#### 对象验证

##### Obj_HasProperty(obj, propertyPath)
检查对象是否具有属性。

**参数：**
- `obj`（映射）：要检查的对象
- `propertyPath`（字符串）：属性路径

**返回：** 布尔值指示属性存在性

##### Obj_ValidateStructure(obj, schema)
根据模式验证对象。

**参数：**
- `obj`（映射）：要验证的对象
- `schema`（映射）：验证模式

**返回：** 布尔值指示验证成功

#### 对象序列化

##### Obj_Serialize(obj)
将对象序列化为字符串。

**参数：**
- `obj`（映射）：要序列化的对象

**返回：** 序列化后的字符串

##### Obj_Deserialize(str)
将字符串反序列化为对象。

**参数：**
- `str`（字符串）：序列化后的字符串

**返回：** 反序列化后的对象

### ID 生成 (IdGen.ahk)

#### 顺序 ID 生成

##### IdGen_NextSequential()
生成下一个顺序 ID。

**参数：**无

**返回：** 顺序 ID

##### IdGen_ResetSequential()
重置顺序 ID 计数器。

**参数：**无

**返回：** 布尔值指示成功

#### UUID 生成

##### IdGen_GenerateUUID()
生成 UUID。

**参数：**无

**返回：** UUID 字符串

##### IdGen_ValidateUUID(uuid)
验证 UUID 字符串。

**参数：**
- `uuid`（字符串）：要验证的 UUID

**返回：** 布尔值指示 UUID 有效性

#### 时间戳 ID 生成

##### IdGen_GenerateTimestampId()
生成基于时间戳的 ID。

**参数：**无

**返回：** 时间戳 ID

##### IdGen_ParseTimestampId(timestampId)
解析时间戳 ID 以提取时间戳。

**参数：**
- `timestampId`（字符串）：时间戳 ID

**返回：** 解析后的时间戳

#### 自定义 ID 生成

##### IdGen_GenerateCustomId(prefix, suffix)
生成自定义格式 ID。

**参数：**
- `prefix`（字符串）：ID 前缀
- `suffix`（字符串）：ID 后缀

**返回：** 自定义 ID

##### IdGen_SetCustomFormat(format)
设置自定义 ID 生成格式。

**参数：**
- `format`（字符串）：自定义格式字符串

**返回：** 布尔值指示成功

## 使用示例

### 通用工具使用
```ahk
; 字符串操作
trimmed := Utils_Trim("  hello world  ") ; "hello world"
formatted := Utils_FormatString("Hello {1}, you have {2} messages", "User", 5)
parts := Utils_SplitString("a,b,c,d", ",") ; ["a", "b", "c", "d"]

; 数学函数
random := Utils_Random(1, 100)
clamped := Utils_Clamp(150, 0, 100) ; 100
rounded := Utils_Round(3.14159, 2) ; 3.14

; 文件操作
extension := Utils_GetFileExtension("document.txt") ; ".txt"
fullPath := Utils_JoinPath("C:", "Users", "Documents", "file.txt")
exists := Utils_FileExists("C:\file.txt")

; 系统工具
timestamp := Utils_GetTimestamp()
Utils_Sleep(1000) ; 休眠 1 秒
systemInfo := Utils_GetSystemInfo()

; 验证函数
isEmpty := Utils_IsEmpty("") ; true
isNumber := Utils_IsNumber("123") ; true
isString := Utils_IsString("hello") ; true
```

### 对象工具使用
```ahk
; 对象创建
person := Obj_Create({"name": "John", "age": 30})
clone := Obj_Clone(person)
merged := Obj_Merge({"a": 1}, {"b": 2}) ; {"a": 1, "b": 2}

; 对象操作
name := Obj_GetProperty(person, "name") ; "John"
Obj_SetProperty(person, "address.city", "New York")
Obj_DeleteProperty(person, "age")

; 对象验证
hasName := Obj_HasProperty(person, "name") ; true
isValid := Obj_ValidateStructure(person, {"name": "string", "age": "number"})

; 对象序列化
serialized := Obj_Serialize(person)
deserialized := Obj_Deserialize(serialized)
```

### ID 生成使用
```ahk
; 顺序 ID
id1 := IdGen_NextSequential() ; 1
id2 := IdGen_NextSequential() ; 2
IdGen_ResetSequential()

; UUID 生成
uuid := IdGen_GenerateUUID()
isValid := IdGen_ValidateUUID(uuid)

; 时间戳 ID
timestampId := IdGen_GenerateTimestampId()
parsedTime := IdGen_ParseTimestampId(timestampId)

; 自定义 ID
customId := IdGen_GenerateCustomId("USER", "ID")
IdGen_SetCustomFormat("{prefix}-{timestamp}-{sequential}")
```

### 与其他模块集成
```ahk
; 配置管理中的工具函数
profilePath := Utils_JoinPath(App["ProfilesDir"], Utils_FormatString("{1}.json", profileName))

; 规则引擎中的对象工具
rule := Obj_Create({
    "condition": {
        "type": "pixel",
        "x": 100,
        "y": 200,
        "color": "0xFF0000"
    },
    "action": {
        "type": "skill",
        "skillId": 1
    }
})

; 实体的 ID 生成
skillId := IdGen_NextSequential()
buffId := IdGen_GenerateUUID()
```

## 配置集成

### 工具设置
工具设置可以在主配置中配置：

```ahk
App["UtilityConfig"] := {
    StringFormat: "{1}",
    DefaultRandomSeed: 12345,
    IDGeneration: {
        SequentialStart: 1,
        UUIDFormat: "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
        TimestampFormat: "yyyyMMddHHmmss"
    }
}
```

## 性能考虑

### 优化策略
1. **函数效率**：工具函数针对性能进行了优化
2. **内存管理**：对象操作中的高效内存使用
3. **缓存**：对频繁使用的操作进行适当缓存
4. **验证优化**：快速验证算法

### 最佳实践
- 为特定任务使用适当的工具函数
- 在使用工具函数之前验证输入
- 正确处理工具函数的返回值
- 使用对象工具进行复杂的对象操作

## 错误处理

工具模块包含全面的错误处理：
- 输入验证和错误检查
- 对无效操作的优雅处理
- 用于调试的清晰错误消息
- 边界情况的安全默认值

## 调试功能

### 工具调试接口
模块提供调试功能：

```ahk
; 启用工具调试
Utils_EnableDebug()

; 获取调试信息
debugInfo := Utils_GetDebugInfo()
```

### 日志集成
工具操作可以记录用于故障排除：
- 函数调用日志记录
- 性能指标
- 错误条件

## 依赖项

- 无外部依赖
- 纯工具函数供内部使用
- 跨模块工具服务

## 相关模块

- [核心模块](../core/README.md) - 核心应用程序功能
- [所有引擎模块](../engines/README.md) - 引擎的工具服务
- [UI 模块](../ui/README.md) - UI 操作的工具函数
- [运行时模块](../runtime/README.md) - 系统工具函数