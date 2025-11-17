# Game Macro - AutoHotkey Automation Tool

An advanced game automation tool developed with AutoHotkey v2, supporting powerful features like pixel detection, skill cycling, BUFF timing, DXGI screen capture, and rotation engine.

## Features

### 🎯 Core Functions
- **Advanced Pixel Detection**: Support DXGI screen capture, ROI detection, GDI fallback
- **Multi-threading Support**: Multiple independent skill execution threads with worker pool management
- **Smart Evasion**: Automatic mouse avoidance to prevent interference during color sampling
- **Rule Engine**: Conditional automation rule system supporting pixel and counter conditions
- **BUFF Timer**: Automatic BUFF refresh functionality with priority execution
- **DXGI Screen Capture**: High-performance screen capture using DirectX Graphics Infrastructure
- **Rotation Management**: Complex skill cycling sequences supporting opener, tracks, and gates
- **Internationalization**: Multi-language support with configurable language packs
- **Automation Pages**: Complete thread, BUFF, rule, and cycle management interface
- **Real-time Monitoring**: Real-time status monitoring with summary pages and detailed lists

### 🛠️ Configuration Management
- **Multi-profile Support**: Independent JSON format configuration files supporting different game characters
- **Visual Editing**: Complete graphical interface for configuring skills, points, rules, and rotations
- **Configuration Export**: Package configurations as standalone scripts
- **Internationalization Support**: Multi-language interface based on INI language pack system
- **Modular Architecture**: Well-organized code structure for easy maintenance and extension
- **Skill Management**: Comprehensive skill editor supporting pixel detection configuration
- **Point Management**: Color detection point configuration with tolerance control
- **Rule System**: Advanced rule editor supporting condition and action configuration
- **Rotation Editor**: Complex cycling sequences supporting multi-stage configuration

## Quick Start

### Option 1: Portable EXE (Recommended for Beginners)
1. **Download Latest Release**: Download ZIP file from `releases/` folder
2. **Extract ZIP File**: Extract to any directory
3. **Run `game-macro.exe`**: No installation required, run directly

### Option 2: Source Code Version (For Developers)
#### System Requirements
- **Windows Operating System**
- **AutoHotkey v2.0 or higher**
- **DirectX 11 compatible graphics card** (for DXGI screen capture)

#### Installation Steps
1. Download and install [AutoHotkey v2](https://www.autohotkey.com/)
2. Clone or download this project locally
3. Double-click `Main.ahk` to launch the configuration tool

### Basic Usage Flow
1. **Launch Tool**: Run `Main.ahk` to open configuration interface
2. **Create Configuration**: Click "New" to create character configuration
3. **Configure Skills**: Add skills in the "Skill List" tab
4. **Setup Rotation**: Configure skill cycling sequences (optional)
5. **Create Rules**: Set up conditional automation rules (optional)
6. **Configure BUFF**: Add automatic BUFF refresh timers (optional)
7. **Set Hotkeys**: Configure start/stop hotkeys (default: F9)
8. **Save Configuration**: Click "Save Configuration" button
9. **Start Using**: Press hotkey in game to start macro

## Detailed Configuration

### Skill Configuration
Each skill contains the following parameters:
- **Skill Name**: Custom name
- **Key**: Skill hotkey in game
- **Coordinates**: Position of skill icon on screen
- **Color**: Pixel color when skill cooldown is complete
- **Tolerance**: Color matching tolerance range

### Point Configuration
Independent color sampling points for detecting game state:
- **Name**: Point description
- **Coordinates**: Screen coordinates
- **Color**: Expected color value
- **Tolerance**: Color matching tolerance

### Rule System
Conditional automation rules:
- **Conditions**: Pixel detection, counter and other condition judgments
- **Actions**: Execute skills, delays and other operations
- **Thread**: Specified execution thread
- **Priority**: Rule execution priority

### BUFF Timer
Automatic BUFF refresh functionality:
- **BUFF Name**: Custom name
- **Duration**: BUFF duration (milliseconds)
- **Early Refresh**: Early refresh time
- **Related Skill**: Skill used for BUFF refresh

## Project Architecture

The project adopts a modular architecture design with clear module responsibilities for easy maintenance and extension:

- **Core Module** (`core/`): Application configuration management and core system functionality
- **Engine Module** (`engines/`): Pixel detection, rule processing, BUFF management, rotation management, DXGI capture, etc.
- **UI Module** (`ui/`): Graphical interface framework, page management, dialog components
- **Runtime Module** (`runtime/`): Hotkey processing, polling system, counter management
- **Storage Module** (`storage/`): Configuration export and data storage
- **Internationalization Module** (`i18n/`): Multi-language support
- **Utility Module** (`util/`): General utility functions
- **Worker Module** (`workers/`): Worker pool management

For detailed project structure and implementation, please refer to the documentation in the `docs/` directory.

## Usage Examples

### Basic Skill Cycling
1. Add skills that need to be cycled
2. Set skill detection coordinates and colors
3. Configure polling interval (default 25ms)
4. Set global delay to prevent skill spam

### Conditional Trigger Rules
1. Create rules and set conditions
2. Configure actions when conditions are met
3. Set rule priority and cooldown time
4. Specify execution thread

### BUFF Auto Refresh
1. Add BUFF timers
2. Set BUFF duration and early refresh time
3. Associate refresh skills
4. Configure detection conditions

## Notes

### ⚠️ Important Reminders
- This tool is for learning and research purposes only
- Please comply with game service terms and use automation features reasonably
- Excessive use may pose account risks
- Recommended for use in single-player games or allowed environments

### 🔧 Technical Limitations
- Depends on screen pixel detection; resolution changes require reconfiguration
- Game updates may cause configurations to become invalid
- Does not support games in full-screen exclusive mode

## Development Guide

### Extension Development
The project adopts a modular design for easy extension of new features:
- New modules only need to be included in `Main.ahk`
- Follow existing naming and interface specifications
- Use global `App` Map for state management

### Debugging Tips
- Check log files in the `Logs/` directory
- Use test functions to verify skill detection
- Adjust tolerance parameters to optimize detection accuracy

## License

This project uses the MIT License - see [LICENSE](LICENSE) file for details.

### License Summary

The MIT License is a permissive open source license that allows:
- ✅ Commercial use
- ✅ Modification and distribution
- ✅ Private use
- ✅ Inclusion in proprietary software

The only requirement is to retain the original copyright notice and license text.

### Important Reminder

Although this software is open source, please use it responsibly:
- Follow game service terms
- Only use automation features in allowed environments
- Avoid affecting other players' gaming experience

## Changelog

### v0.0.3 (Current Version)
- **DXGI Screen Capture Engine**: Integrated high-performance DirectX screen capture functionality
- **Advanced Rotation System**: Support for complex skill cycling with opener, tracks, and gates
- **Rule Engine Upgrade**: Enhanced conditional judgment and action execution system
- **Multi-language Support**: Complete internationalization system supporting Chinese and English switching
- **Modular Refactoring**: Clearer code architecture and module organization

### v0.0.1-Alpha-0.2
- **UI Framework Enhancement**: Added complete automation management pages
- **Real-time Monitoring**: Implemented summary pages for threads, BUFFs, and rules
- **Layout Optimization**: Improved UI layout calculation for better visual effects
- **Dynamic Height Calculation**: Enhanced GroupBox height calculation based on content
- **Button Position Optimization**: Optimized button positions for better user experience

### v0.0.1-Alpha-0.1
- Initial version release
- Basic skill detection functionality
- Graphical configuration interface
- Rule engine and BUFF timer

## Contributing

Issue and Pull Request submissions are welcome to improve the project.

## Support

For questions, please check:
1. Check error information in log files
2. Verify skill coordinates and color configuration
3. Confirm game window is not blocked
4. Adjust detection parameters to optimize accuracy

---

**中文版本**: [README_CN.md](README_CN.md)