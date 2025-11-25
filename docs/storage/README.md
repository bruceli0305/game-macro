# Storage Module Documentation

The Storage module manages data persistence, profile management, and export functionality for the Game Macro system.

[English Version](README.md) | [中文版本](../cn/storage/README.md)

## Overview

The Storage module provides:
- Profile data management and persistence
- File system operations and atomic writes
- Data export functionality
- Model definitions and data structures
- Profile normalization and validation

## Architecture

The storage system is organized into specialized components:

### Storage.ahk (Main Storage Controller)
Main storage management and coordination system.

### Exporter.ahk (Export Functionality)
Data export and external format conversion.

### Model Subsystem
Data model definitions and structures.

### Profile Subsystem
Profile management and file system operations.

### Integration Points
- **Core Module**: Profile data loading and saving
- **UI System**: Profile selection and management interface
- **All Engines**: Profile data access and modification
- **Configuration System**: Storage settings and paths

## Key Components

### Profile Management System
Manages game profiles including loading, saving, and validation.

#### Profile Structure
```ahk
Profile := {
    Id: "profile-001",
    Name: "Warrior Rotation",
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

### File System Operations
Provides atomic file operations and path management.

#### File System Structure
```ahk
FileSystem := {
    ProfilesDir: "profiles",
    ExportDir: "exports",
    BackupDir: "backups",
    TempDir: "temp"
}
```

### Export System
Manages data export to external formats.

#### Export Configuration
```ahk
ExportConfig := {
    Format: "JSON",
    IncludeSensitiveData: false,
    Compress: true,
    Timestamp: true
}
```

### Model Definitions
Defines data structures and validation schemas.

#### Model Structure
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

## Execution Flow

### Profile Loading Process
1. **Profile Selection**: User selects profile to load
2. **File Validation**: Validate profile file integrity
3. **Data Parsing**: Parse profile data from file
4. **Model Validation**: Validate data against model schemas
5. **Normalization**: Normalize data to current version
6. **Engine Integration**: Load data into engine systems

### Profile Saving Process
1. **Data Collection**: Collect current data from all engines
2. **Validation**: Validate data before saving
3. **Backup Creation**: Create backup of existing profile
4. **Atomic Write**: Perform atomic file write operation
5. **Metadata Update**: Update profile metadata
6. **Confirmation**: Confirm successful save

### Export Process
1. **Format Selection**: User selects export format
2. **Data Preparation**: Prepare data for export
3. **Conversion**: Convert data to target format
4. **File Creation**: Create export file
5. **Compression**: Compress if configured
6. **Completion**: Notify user of export completion

## API Reference

### Core Functions

#### Storage_Init()
Initializes the storage system.

**Parameters:** None

**Returns:** Boolean indicating success

#### Storage_LoadProfile(profileId)
Loads a profile by ID.

**Parameters:**
- `profileId` (String): Profile identifier

**Returns:** Loaded profile data

#### Storage_SaveProfile(profileData)
Saves profile data.

**Parameters:**
- `profileData` (Map): Profile data to save

**Returns:** Boolean indicating success

#### Storage_DeleteProfile(profileId)
Deletes a profile.

**Parameters:**
- `profileId` (String): Profile identifier

**Returns:** Boolean indicating success

### Profile Management

#### Storage_ListProfiles()
Lists all available profiles.

**Parameters:** None

**Returns:** Array of profile information

#### Storage_CreateProfile(profileConfig)
Creates a new profile.

**Parameters:**
- `profileConfig` (Map): Profile configuration

**Returns:** Created profile ID

#### Storage_DuplicateProfile(sourceId, newName)
Duplicates an existing profile.

**Parameters:**
- `sourceId` (String): Source profile ID
- `newName` (String): New profile name

**Returns:** New profile ID

#### Storage_ValidateProfile(profileData)
Validates profile data.

**Parameters:**
- `profileData` (Map): Profile data to validate

**Returns:** Validation result

### Export Functions

#### Storage_ExportProfile(profileId, exportConfig)
Exports a profile to external format.

**Parameters:**
- `profileId` (String): Profile identifier
- `exportConfig` (Map): Export configuration

**Returns:** Export file path

#### Storage_ImportProfile(filePath, importConfig)
Imports a profile from external file.

**Parameters:**
- `filePath` (String): Import file path
- `importConfig` (Map): Import configuration

**Returns:** Imported profile ID

#### Storage_GetExportFormats()
Gets available export formats.

**Parameters:** None

**Returns:** Array of export formats

### File System Operations

#### Storage_CreateBackup(profileId)
Creates a backup of a profile.

**Parameters:**
- `profileId` (String): Profile identifier

**Returns:** Backup file path

#### Storage_RestoreBackup(backupPath)
Restores a profile from backup.

**Parameters:**
- `backupPath` (String): Backup file path

**Returns:** Restored profile ID

#### Storage_GetProfilePath(profileId)
Gets the file path for a profile.

**Parameters:**
- `profileId` (String): Profile identifier

**Returns:** Profile file path

## Usage Examples

### Basic Profile Management
```ahk
; Initialize storage system
if (!Storage_Init()) {
    Logger_Error("Storage", "Failed to initialize storage system")
    ExitApp(1)
}

; List available profiles
profiles := Storage_ListProfiles()
for profile in profiles {
    Logger_Info("Storage", "Available profile", Map("name", profile["Name"], "id", profile["Id"]))
}

; Load a profile
profileData := Storage_LoadProfile("warrior-rotation")
if (profileData) {
    Logger_Info("Storage", "Profile loaded successfully", Map("name", profileData["Name"]))
}
```

### Profile Creation and Saving
```ahk
; Create a new profile
newProfile := {
    Name: "Mage Rotation",
    Game: "World of Warcraft", 
    Class: "Mage",
    Data: {
        Skills: [
            {
                Id: 1,
                Name: "Fireball",
                Key: "1",
                CooldownMs: 2000
            }
        ],
        Rotation: {
            Type: "Priority",
            Skills: [1]
        }
    }
}

profileId := Storage_CreateProfile(newProfile)
Logger_Info("Storage", "Profile created", Map("id", profileId))

; Save current profile data
if (Storage_SaveProfile(App["CurrentProfile"])) {
    Logger_Info("Storage", "Profile saved successfully")
}
```

### Export and Import Operations
```ahk
; Export profile to JSON
exportConfig := {
    Format: "JSON",
    IncludeSensitiveData: false,
    Compress: true
}

exportPath := Storage_ExportProfile("warrior-rotation", exportConfig)
Logger_Info("Storage", "Profile exported", Map("path", exportPath))

; Import profile from file
importConfig := {
    OverwriteExisting: false,
    ValidateData: true
}

importedId := Storage_ImportProfile("C:\backups\warrior-backup.json", importConfig)
Logger_Info("Storage", "Profile imported", Map("id", importedId))
```

### Backup and Restore
```ahk
; Create backup
backupPath := Storage_CreateBackup("warrior-rotation")
Logger_Info("Storage", "Backup created", Map("path", backupPath))

; Restore from backup
restoredId := Storage_RestoreBackup("C:\backups\warrior-rotation-backup.json")
Logger_Info("Storage", "Profile restored", Map("id", restoredId))
```

### Profile Validation
```ahk
; Validate profile data before saving
validationResult := Storage_ValidateProfile(profileData)
if (!validationResult["IsValid"]) {
    Logger_Error("Storage", "Profile validation failed", validationResult["Errors"])
    return false
}

; Save only if validation passes
Storage_SaveProfile(profileData)
```

## Configuration Integration

### Storage Settings
Storage settings are configured in the main application:

```ahk
App["StorageConfig"] := {
    ProfilesDir: "profiles",
    ExportDir: "exports", 
    BackupDir: "backups",
    AutoSave: true,
    AutoSaveInterval: 300000, ; 5 minutes
    MaxBackups: 10,
    Compression: true
}
```

### Profile Data Structure
Profile data follows a standardized structure:

```ahk
profile["Data"] := {
    Skills: [
        {
            Id: 1,
            Name: "Skill Name",
            Key: "1",
            X: 100,
            Y: 200,
            Color: "0xFF0000",
            CooldownMs: 2000
        }
    ],
    Buffs: [...],
    Rules: [...],
    Rotation: {
        Type: "Priority",
        Skills: [1, 2, 3],
        Conditions: [...]
    },
    Points: [...],
    General: {
        GameWindow: "World of Warcraft",
        PollingInterval: 100
    }
}
```

## Performance Considerations

### Optimization Strategies
1. **Lazy Loading**: Load profile data only when needed
2. **Incremental Saving**: Save only changed data
3. **Compression**: Use compression for large profiles
4. **Caching**: Cache frequently accessed profile data

### Memory Management
- Profile data is loaded on demand
- Unused profiles are unloaded from memory
- Large data sets are handled efficiently
- Proper cleanup on profile deletion

## Error Handling

The storage module includes comprehensive error handling:
- File system errors (permission, disk space)
- Data validation failures
- Import/export format errors
- Backup/restore failures
- Atomic write protection

## Debugging Features

### Storage Debug Interface
The module provides debugging capabilities:

```ahk
; Enable storage debugging
Storage_EnableDebug()

; Get debug information
debugInfo := Storage_GetDebugInfo()
```

### Logging Integration
All storage operations are logged for troubleshooting:
- Profile load/save operations
- Export/import activities
- Backup/restore operations
- Validation results
- Error conditions

## Dependencies

- File system utilities for atomic operations
- Compression libraries for data compression
- Model validation system for data integrity
- Configuration system for storage settings

## Related Modules

- [Core Module](../core/README.md) - Profile data integration
- [UI Module](../ui/README.md) - Profile management interface
- [All Engines](../engines/README.md) - Profile data consumers
- [Util Module](../util/README.md) - Utility functions for storage operations