# 存储模块文档

存储模块管理 Game Macro 系统的数据持久化、配置文件管理和导出功能。

[English Version](../../storage/README.md) | [中文版本](README.md)

## 概述

存储模块提供：
- 配置文件数据管理和持久化
- 文件系统操作和原子写入
- 数据导出功能
- 模型定义和数据结构
- 配置文件规范化和验证

## 架构

存储系统组织为专门的组件：

### Storage.ahk（主存储控制器）
主存储管理和协调系统。

### Exporter.ahk（导出功能）
数据导出和外部格式转换。

### 模型子系统
数据模型定义和结构。

### 配置文件子系统
配置文件管理和文件系统操作。

### 集成点
- **核心模块**：配置文件数据加载和保存
- **UI 系统**：配置文件选择和管理界面
- **所有引擎**：配置文件数据访问和修改
- **配置系统**：存储设置和路径

## 关键组件

### 配置文件管理系统
管理游戏配置文件，包括加载、保存和验证。

#### 配置文件结构
```ahk
Profile := {
    Id: "profile-001",
    Name: "战士旋转",
    Version: "1.0.0",
    Game: "World of Warcraft",
    Class: "Warrior",
    Created: "2024-01-01T00:00:00Z",
    Modified: "2024-01-02T12:00:00Z",
    Data: {
        Skills: [...],
        Buffs: [...],
        Rules: [...],
        Rotation: {...},
        Points: [...],
        General: {...}
    }
}
```

### 文件系统操作
提供原子文件操作和路径管理。

#### 文件系统结构
```ahk
FileSystem := {
    ProfilesDir: "profiles",
    ExportDir: "exports",
    BackupDir: "backups",
    TempDir: "temp"
}
```

### 导出系统
管理数据导出到外部格式。

#### 导出配置
```ahk
ExportConfig := {
    Format: "JSON",
    IncludeSensitiveData: false,
    Compress: true,
    Timestamp: true
}
```

### 模型定义
定义数据结构和验证模式。

#### 模型结构
```ahk
Model := {
    Name: "Skill",
    Fields: {
        Id: {Type: "Integer", Required: true},
        Name: {Type: "String", Required: true},
        Key: {Type: "String", Required: true},
        CooldownMs: {Type: "Integer", Default: 0}
    },
    Validation: Func("ValidateSkill")
}
```

## 执行流程

### 配置文件加载过程
1. **配置文件选择**：用户选择要加载的配置文件
2. **文件验证**：验证配置文件文件完整性
3. **数据解析**：从文件解析配置文件数据
4. **模型验证**：根据模型模式验证数据
5. **规范化**：将数据规范化为当前版本
6. **引擎集成**：将数据加载到引擎系统中

### 配置文件保存过程
1. **数据收集**：从所有引擎收集当前数据
2. **验证**：保存前验证数据
3. **备份创建**：创建现有配置文件的备份
4. **原子写入**：执行原子文件写入操作
5. **元数据更新**：更新配置文件元数据
6. **确认**：确认保存成功

### 导出过程
1. **格式选择**：用户选择导出格式
2. **数据准备**：准备要导出的数据
3. **转换**：将数据转换为目标格式
4. **文件创建**：创建导出文件
5. **压缩**：如果配置则压缩
6. **完成**：通知用户导出完成

## API 参考

### 核心函数

#### Storage_Init()
初始化存储系统。

**参数：**无

**返回：**布尔值指示成功

#### Storage_LoadProfile(profileId)
按 ID 加载配置文件。

**参数：**
- `profileId`（字符串）：配置文件标识符

**返回：**加载的配置文件数据

#### Storage_SaveProfile(profileData)
保存配置文件数据。

**参数：**
- `profileData`（Map）：要保存的配置文件数据

**返回：**布尔值指示成功

#### Storage_DeleteProfile(profileId)
删除配置文件。

**参数：**
- `profileId`（字符串）：配置文件标识符

**返回：**布尔值指示成功

### 配置文件管理

#### Storage_ListProfiles()
列出所有可用配置文件。

**参数：**无

**返回：**配置文件信息数组

#### Storage_CreateProfile(profileConfig)
创建新配置文件。

**参数：**
- `profileConfig`（Map）：配置文件配置

**返回：**创建的配置文件 ID

#### Storage_DuplicateProfile(sourceId, newName)
复制现有配置文件。

**参数：**
- `sourceId`（字符串）：源配置文件 ID
- `newName`（字符串）：新配置文件名称

**返回：**新配置文件 ID

#### Storage_ValidateProfile(profileData)
验证配置文件数据。

**参数：**
- `profileData`（Map）：要验证的配置文件数据

**返回：**验证结果

### 导出函数

#### Storage_ExportProfile(profileId, exportConfig)
导出配置文件。

**参数：**
- `profileId`（字符串）：配置文件标识符
- `exportConfig`（Map）：导出配置

**返回：**布尔值指示成功

#### Storage_ExportAllProfiles(exportConfig)
导出所有配置文件。

**参数：**
- `exportConfig`（Map）：导出配置

**返回：**布尔值指示成功

#### Storage_GetExportFormats()
获取支持的导出格式。

**参数：**无

**返回：**支持的格式数组

### 文件系统操作

#### Storage_BackupProfile(profileId)
创建配置文件备份。

**参数：**
- `profileId`（字符串）：配置文件标识符

**返回：**布尔值指示成功

#### Storage_RestoreBackup(backupId)
从备份恢复配置文件。

**参数：**
- `backupId`（字符串）：备份标识符

**返回：**布尔值指示成功

#### Storage_ListBackups(profileId)
列出配置文件的备份。

**参数：**
- `profileId`（字符串）：配置文件标识符

**返回：**备份信息数组

## 使用示例

### 基本配置文件操作
```ahk
; 初始化存储系统
if (Storage_Init()) {
    ; 列出所有配置文件
    profiles := Storage_ListProfiles()
    
    ; 加载配置文件
    profileData := Storage_LoadProfile("profile-001")
    
    ; 修改配置文件数据
    profileData["Name"] := "修改后的配置"
    
    ; 保存配置文件
    if (Storage_SaveProfile(profileData)) {
        Logger_Info("Storage", "配置文件已保存")
    }
}
```

### 配置文件创建和复制
```ahk
; 创建新配置文件
newProfile := {
    Name: "新配置文件",
    Game: "World of Warcraft",
    Class: "Mage",
    Data: {
        Skills: [],
        Buffs: [],
        Rules: []
    }
}

profileId := Storage_CreateProfile(newProfile)

; 复制配置文件
newProfileId := Storage_DuplicateProfile("profile-001", "副本配置")
```

### 数据导出
```ahk
; 导出配置文件
exportConfig := {
    Format: "JSON",
    IncludeSensitiveData: false,
    Compress: true
}

if (Storage_ExportProfile("profile-001", exportConfig)) {
    Logger_Info("Storage", "配置文件已导出")
}

; 导出所有配置文件
if (Storage_ExportAllProfiles(exportConfig)) {
    Logger_Info("Storage", "所有配置文件已导出")
}
```

### 备份和恢复
```ahk
; 创建备份
if (Storage_BackupProfile("profile-001")) {
    Logger_Info("Storage", "备份已创建")
}

; 列出备份
backups := Storage_ListBackups("profile-001")

; 从备份恢复
if (Storage_RestoreBackup("backup-001")) {
    Logger_Info("Storage", "配置文件已从备份恢复")
}
```

## 配置集成

### 存储配置
存储设置存储在配置文件数据中：

```ahk
profile := App["ProfileData"]
profile["StorageConfig"] := {
    AutoBackup: true,
    BackupCount: 3,
    ExportPath: "exports",
    Compression: true
}
```

### 路径配置
存储路径可以动态配置：

```ahk
; 设置自定义存储路径
Storage_SetBasePath("D:/GameMacro/Profiles")
```

## 性能考虑

### 优化策略
1. **原子写入**：确保数据完整性的原子文件操作
2. **增量保存**：实现增量保存以减少写入操作
3. **缓存管理**：优化配置文件数据缓存
4. **压缩优化**：高效的数据压缩算法

### 内存管理
- 配置文件数据在加载时验证
- 大文件的分块处理
- 内存使用监控和限制

## 错误处理

存储模块包含全面的错误处理：
- 文件系统错误
- 数据验证失败
- 导出格式不支持
- 备份和恢复失败

## 调试功能

### 存储调试接口
模块提供实时监控的调试接口：

```ahk
; 启用存储调试
Storage_EnableDebug()

; 获取调试信息
debugInfo := Storage_GetDebugInfo()
```

### 文件操作监控
详细的文件操作信息用于调试：

```ahk
; 获取文件操作统计
fileStats := Storage_GetFileStats()
Logger_Debug("Storage", "文件统计", fileStats)
```

## 依赖项

- 文件系统用于数据持久化
- 配置系统用于存储设置
- 所有引擎用于数据收集
- UI 系统用于配置文件管理界面

## 相关模块

- [核心模块](../core/README.md) - 配置文件数据管理
- [UI 系统](../ui/README.md) - 配置文件管理界面
- [所有引擎模块](../engines/README.md) - 配置文件数据访问
- [配置系统](../core/README.md) - 存储设置管理