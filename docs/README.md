# Game Macro Development Manual

Comprehensive technical documentation for the Game Macro automation system, providing detailed information about each module's architecture, API, and usage.

[English Version](README.md) | [中文版本](cn/README.md)

## Overview

The Game Macro system is a sophisticated automation framework built with AutoHotkey v2, designed for game automation with pixel detection, skill casting, buff management, and rule-based automation capabilities.

## Module Documentation

### Core Modules

#### [Core Module](core/README.md)
- Global application state management
- Configuration file handling
- Default profile and settings management
- Application lifecycle control

#### [Runtime Module](runtime/README.md)
- Application lifecycle management
- Thread management system
- Performance monitoring and optimization
- Hotkey binding and management

#### [Utility Module](util/README.md)
- Generic utility functions
- Object manipulation tools
- ID generation system
- Common helper functions

### Engine Modules

#### [Pixel Engine](engines/pixel/README.md)
- High-performance pixel detection
- Color management system
- Frame-level caching
- ROI (Region of Interest) optimization

#### [DXGI Engine](engines/dup/README.md)
- Hardware-accelerated screen capture
- DirectX Graphics Infrastructure integration
- Multi-monitor support
- Dynamic FPS adjustment

#### [Cast Engine](engines/cast/README.md)
- Skill casting automation
- Cast bar detection
- Skill state tracking
- Cooldown management

#### [Buff Engine](engines/buff/README.md)
- Buff duration tracking
- Buff state detection
- Priority-based buff management
- Automatic buff renewal

#### [Rule Engine](engines/rules/README.md)
- Rule-based automation system
- Condition evaluation engine
- Action execution framework
- Priority and timing management

#### [Rotation Engine](engines/rotation/README.md)
- Skill rotation management
- Phase-based execution
- Black guard protection
- Opener sequence handling

### Infrastructure Modules

#### [Storage Module](storage/README.md)
- Profile management system
- Configuration persistence
- Export functionality
- File system operations

#### [Logging Module](logging/README.md)
- Comprehensive logging system
- Multiple sink support (file, memory, pipe)
- Log rotation and management
- Performance monitoring

#### [Internationalization (i18n) Module](i18n/README.md)
- Multi-language support
- Resource file management
- Dynamic language switching
- Translation system

#### [UI Framework](ui/README.md)
- User interface components
- Page-based navigation system
- Modal dialog management
- Responsive layout design

#### [Workers Module](workers/README.md)
- Background task management
- Worker thread pooling
- Asynchronous operation support
- Resource management

#### [Native Library](lib/README.md)
- C++ native implementations
- DXGI duplication functionality
- Performance-critical operations
- Hardware acceleration

## System Architecture

### High-Level Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    UI Layer     │◄──►│  Core Services   │◄──►│  Engine Layer   │
│                 │    │                 │    │                 │
│ • Pages         │    │ • Configuration │    │ • Pixel Detection│
│ • Dialogs       │    │ • State Mgmt    │    │ • Skill Casting │
│ • Navigation    │    │ • Logging       │    │ • Buff Tracking  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Storage Layer  │    │ Runtime Layer   │    │ Native Layer   │
│                 │    │                 │    │                 │
│ • Profile Mgmt  │    │ • Thread Pool   │    │ • DXGI Capture │
│ • File I/O      │    │ • Hotkey Mgmt   │    │ • Performance   │
│ • Export System │    │ • Polling       │    │ • Optimization  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow

1. **User Interaction** → UI Layer → Core Services
2. **Configuration** → Storage Layer → All Modules
3. **Automation** → Engine Layer → Native Layer
4. **Monitoring** → Runtime Layer → Logging System

## Getting Started

### Prerequisites
- AutoHotkey v2.0 or later
- Windows 10/11 operating system
- DirectX compatible graphics card
- Administrative privileges (for some features)

### Development Setup
1. Clone the repository
2. Review module documentation
3. Set up development environment
4. Configure application settings
5. Test with sample profiles

### Module Integration
Each module is designed for independent development and testing:
- Clear API boundaries
- Well-defined interfaces
- Comprehensive error handling
- Performance monitoring

## API Reference

### Core APIs
- **Configuration Management**: AppConfig_* functions
- **State Management**: Core_* functions
- **Logging**: Logger_* functions
- **Internationalization**: Lang_* functions

### Engine APIs
- **Pixel Detection**: Pixel_* functions
- **Screen Capture**: Dup_* functions
- **Skill Casting**: Cast_* functions
- **Buff Management**: Buff_* functions
- **Rule Execution**: Rule_* functions

### Utility APIs
- **Object Manipulation**: Obj_* functions
- **ID Generation**: IdGen_* functions
- **Common Utilities**: Utils_* functions

## Configuration Guide

### Application Configuration
Located in `Config/AppConfig.ini`:
```ini
[General]
Language=zh-CN
Version=2.0.0

[Logging]
Level=INFO
RotateSizeMB=10
RotateKeep=5
```

### Profile Configuration
Profiles stored in `Profiles/` directory:
- Skill configurations
- Rule definitions
- Buff settings
- Rotation sequences

## Performance Optimization

### Key Optimization Areas
1. **Pixel Detection**: Use ROI and frame caching
2. **Screen Capture**: Leverage DXGI hardware acceleration
3. **Rule Evaluation**: Optimize condition evaluation order
4. **Memory Management**: Efficient resource utilization
5. **Thread Management**: Proper worker thread allocation

### Monitoring Tools
- Built-in performance counters
- Detailed logging system
- Real-time status monitoring
- Error tracking and reporting

## Troubleshooting

### Common Issues
1. **DXGI Initialization Failures**: Check graphics drivers and permissions
2. **Pixel Detection Issues**: Verify color tolerance and coordinates
3. **Rule Execution Problems**: Review condition logic and priorities
4. **Performance Degradation**: Monitor system resources and optimize settings

### Debugging Techniques
- Enable debug logging
- Use diagnostic tools
- Review performance metrics
- Test with simplified configurations

## Contributing

### Development Guidelines
1. Follow established coding standards
2. Maintain comprehensive documentation
3. Include unit tests for new features
4. Perform thorough testing before submission

### Module Development
When adding new modules:
1. Create clear API documentation
2. Implement proper error handling
3. Include performance monitoring
4. Follow established architectural patterns

## License and Attribution

This documentation is part of the Game Macro system. Please refer to the project's license file for usage and distribution terms.

## Support

For technical support and development questions:
- Review module-specific documentation
- Check troubleshooting sections
- Examine example implementations
- Review API references

---

*This documentation is automatically generated and maintained as part of the Game Macro development process.*