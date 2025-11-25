# Utility Module Documentation

The Utility module provides essential helper functions, object utilities, and ID generation services for the Game Macro system.

[English Version](README.md) | [中文版本](../cn/util/README.md)

## Overview

The Utility module provides:
- General-purpose helper functions
- Object manipulation utilities
- Unique ID generation
- Common utility operations
- Cross-module utility services

## Architecture

The utility system is organized into specialized utility components:

### Utils.ahk (General Utilities)
Main utility functions for common operations.

### Obj.ahk (Object Utilities)
Object manipulation and management utilities.

### IdGen.ahk (ID Generation)
Unique identifier generation system.

### Integration Points
- **All Modules**: Provides utility services to all system modules
- **Core Module**: Core utility functions
- **Configuration System**: Utility functions for configuration management

## Key Components

### General Utilities (Utils.ahk)
Provides common utility functions used throughout the system.

#### Utility Function Categories
- **String Operations**: String manipulation and formatting
- **Mathematical Functions**: Math utilities and calculations
- **File Operations**: File and path utilities
- **System Utilities**: System-level helper functions
- **Validation Functions**: Data validation utilities

### Object Utilities (Obj.ahk)
Provides object manipulation and management utilities.

#### Object Utility Functions
- **Object Creation**: Object instantiation utilities
- **Object Manipulation**: Property management and modification
- **Object Validation**: Object structure validation
- **Object Serialization**: Object serialization and deserialization

### ID Generation (IdGen.ahk)
Provides unique identifier generation services.

#### ID Generation Types
- **Sequential IDs**: Sequential number generation
- **UUID Generation**: Universally unique identifiers
- **Timestamp IDs**: Time-based identifiers
- **Custom IDs**: Custom format identifier generation

## API Reference

### General Utilities (Utils.ahk)

#### String Operations

##### Utils_Trim(str)
Trims whitespace from both ends of a string.

**Parameters:**
- `str` (String): Input string

**Returns:** Trimmed string

##### Utils_FormatString(format, args...)
Formats a string with provided arguments.

**Parameters:**
- `format` (String): Format string
- `args...` (Variadic): Format arguments

**Returns:** Formatted string

##### Utils_SplitString(str, delimiter)
Splits a string by delimiter.

**Parameters:**
- `str` (String): Input string
- `delimiter` (String): Delimiter character

**Returns:** Array of split strings

#### Mathematical Functions

##### Utils_Random(min, max)
Generates a random number between min and max.

**Parameters:**
- `min` (Number): Minimum value
- `max` (Number): Maximum value

**Returns:** Random number

##### Utils_Clamp(value, min, max)
Clamps a value between min and max.

**Parameters:**
- `value` (Number): Input value
- `min` (Number): Minimum value
- `max` (Number): Maximum value

**Returns:** Clamped value

##### Utils_Round(value, decimals)
Rounds a number to specified decimal places.

**Parameters:**
- `value` (Number): Input value
- `decimals` (Integer): Number of decimal places

**Returns:** Rounded number

#### File Operations

##### Utils_GetFileExtension(filename)
Gets the file extension from a filename.

**Parameters:**
- `filename` (String): Filename

**Returns:** File extension

##### Utils_JoinPath(parts...)
Joins path parts into a complete path.

**Parameters:**
- `parts...` (Variadic): Path components

**Returns:** Joined path string

##### Utils_FileExists(filepath)
Checks if a file exists.

**Parameters:**
- `filepath` (String): File path

**Returns:** Boolean indicating file existence

#### System Utilities

##### Utils_GetTimestamp()
Gets the current timestamp in milliseconds.

**Parameters:** None

**Returns:** Current timestamp

##### Utils_Sleep(ms)
Sleeps for specified milliseconds.

**Parameters:**
- `ms` (Integer): Milliseconds to sleep

**Returns:** None

##### Utils_GetSystemInfo()
Gets system information.

**Parameters:** None

**Returns:** System information map

#### Validation Functions

##### Utils_IsEmpty(value)
Checks if a value is empty.

**Parameters:**
- `value` (Any): Value to check

**Returns:** Boolean indicating emptiness

##### Utils_IsNumber(value)
Checks if a value is a number.

**Parameters:**
- `value` (Any): Value to check

**Returns:** Boolean indicating if value is a number

##### Utils_IsString(value)
Checks if a value is a string.

**Parameters:**
- `value` (Any): Value to check

**Returns:** Boolean indicating if value is a string

### Object Utilities (Obj.ahk)

#### Object Creation

##### Obj_Create(properties)
Creates a new object with specified properties.

**Parameters:**
- `properties` (Map): Object properties

**Returns:** New object

##### Obj_Clone(obj)
Creates a deep clone of an object.

**Parameters:**
- `obj` (Map): Object to clone

**Returns:** Cloned object

##### Obj_Merge(target, source)
Merges source object into target object.

**Parameters:**
- `target` (Map): Target object
- `source` (Map): Source object

**Returns:** Merged object

#### Object Manipulation

##### Obj_GetProperty(obj, propertyPath)
Gets a property from an object using dot notation.

**Parameters:**
- `obj` (Map): Source object
- `propertyPath` (String): Property path

**Returns:** Property value

##### Obj_SetProperty(obj, propertyPath, value)
Sets a property in an object using dot notation.

**Parameters:**
- `obj` (Map): Target object
- `propertyPath` (String): Property path
- `value` (Any): Value to set

**Returns:** Modified object

##### Obj_DeleteProperty(obj, propertyPath)
Deletes a property from an object.

**Parameters:**
- `obj` (Map): Target object
- `propertyPath` (String): Property path

**Returns:** Modified object

#### Object Validation

##### Obj_HasProperty(obj, propertyPath)
Checks if an object has a property.

**Parameters:**
- `obj` (Map): Object to check
- `propertyPath` (String): Property path

**Returns:** Boolean indicating property existence

##### Obj_ValidateStructure(obj, schema)
Validates an object against a schema.

**Parameters:**
- `obj` (Map): Object to validate
- `schema` (Map): Validation schema

**Returns:** Boolean indicating validation success

#### Object Serialization

##### Obj_Serialize(obj)
Serializes an object to a string.

**Parameters:**
- `obj` (Map): Object to serialize

**Returns:** Serialized string

##### Obj_Deserialize(str)
Deserializes a string to an object.

**Parameters:**
- `str` (String): Serialized string

**Returns:** Deserialized object

### ID Generation (IdGen.ahk)

#### Sequential ID Generation

##### IdGen_NextSequential()
Generates the next sequential ID.

**Parameters:** None

**Returns:** Sequential ID

##### IdGen_ResetSequential()
Resets the sequential ID counter.

**Parameters:** None

**Returns:** Boolean indicating success

#### UUID Generation

##### IdGen_GenerateUUID()
Generates a UUID.

**Parameters:** None

**Returns:** UUID string

##### IdGen_ValidateUUID(uuid)
Validates a UUID string.

**Parameters:**
- `uuid` (String): UUID to validate

**Returns:** Boolean indicating UUID validity

#### Timestamp ID Generation

##### IdGen_GenerateTimestampId()
Generates a timestamp-based ID.

**Parameters:** None

**Returns:** Timestamp ID

##### IdGen_ParseTimestampId(timestampId)
Parses a timestamp ID to extract timestamp.

**Parameters:**
- `timestampId` (String): Timestamp ID

**Returns:** Parsed timestamp

#### Custom ID Generation

##### IdGen_GenerateCustomId(prefix, suffix)
Generates a custom format ID.

**Parameters:**
- `prefix` (String): ID prefix
- `suffix` (String): ID suffix

**Returns:** Custom ID

##### IdGen_SetCustomFormat(format)
Sets the custom ID generation format.

**Parameters:**
- `format` (String): Custom format string

**Returns:** Boolean indicating success

## Usage Examples

### General Utilities Usage
```ahk
; String operations
trimmed := Utils_Trim("  hello world  ") ; "hello world"
formatted := Utils_FormatString("Hello {1}, you have {2} messages", "User", 5)
parts := Utils_SplitString("a,b,c,d", ",") ; ["a", "b", "c", "d"]

; Mathematical functions
random := Utils_Random(1, 100)
clamped := Utils_Clamp(150, 0, 100) ; 100
rounded := Utils_Round(3.14159, 2) ; 3.14

; File operations
extension := Utils_GetFileExtension("document.txt") ; ".txt"
fullPath := Utils_JoinPath("C:", "Users", "Documents", "file.txt")
exists := Utils_FileExists("C:\file.txt")

; System utilities
timestamp := Utils_GetTimestamp()
Utils_Sleep(1000) ; Sleep for 1 second
systemInfo := Utils_GetSystemInfo()

; Validation functions
isEmpty := Utils_IsEmpty("") ; true
isNumber := Utils_IsNumber("123") ; true
isString := Utils_IsString("hello") ; true
```

### Object Utilities Usage
```ahk
; Object creation
person := Obj_Create({"name": "John", "age": 30})
clone := Obj_Clone(person)
merged := Obj_Merge({"a": 1}, {"b": 2}) ; {"a": 1, "b": 2}

; Object manipulation
name := Obj_GetProperty(person, "name") ; "John"
Obj_SetProperty(person, "address.city", "New York")
Obj_DeleteProperty(person, "age")

; Object validation
hasName := Obj_HasProperty(person, "name") ; true
isValid := Obj_ValidateStructure(person, {"name": "string", "age": "number"})

; Object serialization
serialized := Obj_Serialize(person)
deserialized := Obj_Deserialize(serialized)
```

### ID Generation Usage
```ahk
; Sequential IDs
id1 := IdGen_NextSequential() ; 1
id2 := IdGen_NextSequential() ; 2
IdGen_ResetSequential()

; UUID generation
uuid := IdGen_GenerateUUID()
isValid := IdGen_ValidateUUID(uuid)

; Timestamp IDs
timestampId := IdGen_GenerateTimestampId()
parsedTime := IdGen_ParseTimestampId(timestampId)

; Custom IDs
customId := IdGen_GenerateCustomId("USER", "ID")
IdGen_SetCustomFormat("{prefix}-{timestamp}-{sequential}")
```

### Integration with Other Modules
```ahk
; Utility functions in configuration management
profilePath := Utils_JoinPath(App["ProfilesDir"], Utils_FormatString("{1}.json", profileName))

; Object utilities in rule engine
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

; ID generation for entities
skillId := IdGen_NextSequential()
buffId := IdGen_GenerateUUID()
```

## Configuration Integration

### Utility Settings
Utility settings can be configured in the main configuration:

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

## Performance Considerations

### Optimization Strategies
1. **Function Efficiency**: Utility functions are optimized for performance
2. **Memory Management**: Efficient memory usage in object operations
3. **Caching**: Appropriate caching for frequently used operations
4. **Validation Optimization**: Fast validation algorithms

### Best Practices
- Use appropriate utility functions for specific tasks
- Validate inputs before using utility functions
- Handle utility function return values properly
- Use object utilities for complex object manipulations

## Error Handling

The utility module includes comprehensive error handling:
- Input validation and error checking
- Graceful handling of invalid operations
- Clear error messages for debugging
- Safe default values for edge cases

## Debugging Features

### Utility Debug Interface
The module provides debugging capabilities:

```ahk
; Enable utility debugging
Utils_EnableDebug()

; Get debug information
debugInfo := Utils_GetDebugInfo()
```

### Logging Integration
Utility operations can be logged for troubleshooting:
- Function call logging
- Performance metrics
- Error conditions

## Dependencies

- No external dependencies
- Pure utility functions for internal use
- Cross-module utility services

## Related Modules

- [Core Module](../core/README.md) - Core application functionality
- [All Engine Modules](../engines/README.md) - Utility services for engines
- [UI Module](../ui/README.md) - Utility functions for UI operations
- [Runtime Module](../runtime/README.md) - System utility functions