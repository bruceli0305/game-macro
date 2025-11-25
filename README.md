# Game Macro - AHK Game Macro Tool v0.2.0

A powerful AutoHotkey v2 game macro tool with pixel detection, skill rotation, and automation capabilities.

## Project Overview

Game Macro is a professional game automation tool designed for games requiring precise pixel detection and complex skill rotations. It features a modular architecture, multi-threading support, intelligent rule engine, and real-time debugging capabilities.

## Key Features

### 🎯 Core Features
- **Pixel Detection Engine**: High-performance screen pixel capture based on DXGI
- **Skill Rotation System**: Support for complex skill rotations and conditional judgments
- **Multi-threading Support**: Configurable independent execution threads
- **Intelligent Rule Engine**: Condition-based automation decision system

### 🛠️ Technical Features
- **Modular Architecture**: Clear code organization and easy extensibility
- **Real-time Debugging**: Built-in debugging tools and logging system
- **Multi-language Support**: Switch between Chinese and English interfaces
- **Configuration Management**: Complete configuration import/export functionality

### 📊 Advanced Features
- **BUFF Timer**: Automatic monitoring and management of buff effects
- **Skill Debugger**: Real-time viewing of cast bars and skill status
- **Capture Diagnostics**: Detailed pixel capture performance analysis
- **Black Screen Protection**: Intelligent detection and avoidance of black screen states

## Quick Start

### System Requirements
- Windows 10/11 operating system
- AutoHotkey v2.0 or higher
- Administrator privileges (for screen capture)

### Installation Steps

1. **Download Project**
   ```bash
   git clone https://github.com/your-repo/game-macro.git
   cd game-macro
   ```

2. **Install Dependencies**
   - Ensure AutoHotkey v2 is installed
   - Project includes pre-compiled DXGI libraries, no additional installation needed

3. **Run Program**
   ```bash
   # Double-click Main.ahk to run
   # Or use command line
   AutoHotkey64.exe Main.ahk
   ```

### Basic Configuration

1. **First Run**: Program automatically creates necessary configuration files and directories
2. **Interface Language**: Switch between Chinese and English in settings
3. **Hotkey Configuration**: Default uses F9 key to start/stop macro

## Usage Guide

### Skill Configuration
1. Open "Skills" page
2. Add skill name, hotkey, and pixel detection position
3. Configure color tolerance and detection parameters

### Rotation Rules
1. Create rules in "Rotation Rules" page
2. Set trigger conditions and execution actions
3. Configure priority and cooldown times

### Multi-threading Management
1. Manage execution threads in "Thread Configuration" page
2. Assign different skills and rules to different threads
3. Set thread priority and scheduling strategies

## Configuration Files

### Main Configuration Files
- `Config/AppConfig.ini` - Application global configuration
- `Languages/` - Language files directory
- `Profiles/` - User profile directory

### Configuration Example
```ini
[General]
Language=zh-CN
Version=0.1.3

[Logging]
Level=DEBUG
RotateSizeMB=10
RotateKeep=5
```

## Development Guide

### Module Extension
The project uses modular design, making it easy to add new features:

1. **Add New Engine**: Create new engine in `modules/engines/` directory
2. **Extend UI Pages**: Add new pages in `modules/ui/pages/`
3. **Custom Rules**: Extend condition judgment logic through RuleEngine

### API Documentation
Core modules provide clear API interfaces:

- `Core_Init()` - Initialize core system
- `Logger_Info()` - Log recording
- `Rotation_Start()` - Start rotation engine
- `Pixel_GetColor()` - Pixel color acquisition

## Troubleshooting

### Common Issues

**Q: Program cannot run with administrator privileges**
A: Right-click Main.ahk and select "Run as administrator"

**Q: Pixel detection is inaccurate**
A: Check color tolerance settings, use capture diagnostics tool for debugging

**Q: Hotkey conflicts**
A: Modify default hotkeys in hotkey configuration page

### Log Viewing
Program generates detailed log files in `Logs/` directory:
- Use "Log Viewer" page for real-time monitoring
- Or directly view log files for debugging

## Version Information

### Current Version
- Version: v0.2.0
- Release Date: 2024
- Main Features: Complete modular refactoring, added multi-language support

### Version History
- v0.1.0 - Basic functionality implementation
- v0.1.3 - UI optimization and stability improvements
- v0.2.0 - Modular refactoring, added advanced features

## Contributing

Welcome to submit Issues and Pull Requests to improve the project:

1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Disclaimer

This tool is for learning and research purposes only. Please comply with the terms of use of relevant games. The developers are not responsible for any consequences resulting from the use of this tool.

---

**Note**: Using game macros may violate the terms of service of some games. Please use this tool in a legal and compliant manner.
