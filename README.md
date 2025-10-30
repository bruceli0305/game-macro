# Game Macro - AutoHotkey Automation Tool

A game automation tool developed with AutoHotkey v2, supporting advanced features like pixel detection, skill rotation, buff timers, and more.

## Features

### 🎯 Core Features
- **Pixel Detection**: Detect skill cooldown status through screen pixel color analysis
- **Multi-threading Support**: Multiple independent skill execution threads
- **Smart Avoidance**: Automatic mouse avoidance during color picking to prevent game interference
- **Rule Engine**: Conditional automation rule system
- **Buff Timers**: Automatic buff renewal functionality

### 🛠️ Configuration Management
- **Multi-character Profiles**: Independent configurations for different game characters
- **Visual Editor**: Graphical interface for configuring skills, points, and rules
- **Export Functionality**: Package configurations as standalone scripts

## Quick Start

### System Requirements
- Windows operating system
- AutoHotkey v2.0 or higher

### Installation Steps
1. Download and install [AutoHotkey v2](https://www.autohotkey.com/)
2. Clone or download this project to your local machine
3. Double-click `Main.ahk` to start the configuration tool

### Basic Usage
1. **Start Tool**: Run `Main.ahk` to open the configuration interface
2. **Create Profile**: Click "New" to create a character configuration
3. **Configure Skills**: Add skills in the "Skill List" tab
4. **Set Hotkey**: Configure start/stop hotkey (default: F9)
5. **Save Configuration**: Click "Save Configuration" button
6. **Start Using**: Press the hotkey in-game to activate the macro

## Detailed Configuration

### Skill Configuration
Each skill includes the following parameters:
- **Skill Name**: Custom name
- **Key**: In-game skill hotkey
- **Coordinates**: Screen position of skill icon
- **Color**: Pixel color when skill is ready
- **Tolerance**: Color matching tolerance range

### Point Configuration
Independent color detection points for game state monitoring:
- **Name**: Point description
- **Coordinates**: Screen coordinates
- **Color**: Expected color value
- **Tolerance**: Color matching tolerance

### Rule System
Condition-based automation rules:
- **Conditions**: Pixel detection, counter conditions, etc.
- **Actions**: Execute skills, delays, etc.
- **Threads**: Specify execution thread
- **Priority**: Rule execution priority

### Buff Timers
Automatic buff renewal functionality:
- **Buff Name**: Custom name
- **Duration**: Buff duration (milliseconds)
- **Refresh Before**: Early refresh time
- **Associated Skills**: Skills used for buff renewal

## Project Structure

```
game-macro/
├── Main.ahk                    # Main program entry
├── modules/                    # Functional modules
│   ├── Core.ahk               # Core functionality
│   ├── GUI_Main.ahk           # Main interface
│   ├── GUI_SkillEditor.ahk    # Skill editor
│   ├── GUI_PointEditor.ahk    # Point editor
│   ├── GUI_RuleEditor.ahk    # Rule editor
│   ├── GUI_BuffEditor.ahk    # Buff editor
│   ├── GUI_Threads.ahk       # Thread management
│   ├── RuleEngine.ahk        # Rule engine
│   ├── BuffEngine.ahk        # Buff engine
│   ├── WorkerPool.ahk        # Worker thread pool
│   ├── Poller.ahk            # Poller
│   ├── Pixel.ahk             # Pixel detection
│   ├── Storage.ahk           # Configuration storage
│   ├── Exporter.ahk          # Configuration export
│   ├── Hotkeys.ahk           # Hotkey management
│   ├── Counters.ahk          # Counters
│   └── Utils.ahk             # Utility functions
├── Profiles/                  # Configuration directory
│   └── Default.ini           # Default configuration
├── Exports/                   # Export directory
│   └── Default/                  # Example export configuration
└── Logs/                      # Log directory
```

## Usage Examples

### Basic Skill Rotation
1. Add skills for rotation
2. Set detection coordinates and colors
3. Configure polling interval (default: 25ms)
4. Set global delay to prevent skill spamming

### Conditional Trigger Rules
1. Create rules with conditions
2. Configure actions when conditions are met
3. Set rule priority and cooldown
4. Specify execution thread

### Automatic Buff Renewal
1. Add buff timer
2. Set buff duration and early refresh time
3. Associate buff renewal skills
4. Configure detection conditions

## Important Notes

### ⚠️ Important Reminders
- This tool is for learning and research purposes only
- Please comply with game service terms, use automation features responsibly
- Excessive use may result in account risks
- Recommended for use in single-player games or permitted environments

### 🔧 Technical Limitations
- Relies on screen pixel detection, resolution changes require reconfiguration
- Game updates may cause configurations to become invalid
- Does not support full-screen exclusive mode games

## Development Information

### Extending Functionality
The project uses modular design, making it easy to extend:
- Add new modules by including them in `Main.ahk`
- Follow existing naming and interface conventions
- Use global `App` Map for state management

### Debugging Tips
- Check log files in the `Logs/` directory
- Use test functions to verify skill detection
- Adjust tolerance parameters to optimize detection accuracy

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### License Summary

MIT License is a permissive open-source license that allows:
- ✅ Commercial use
- ✅ Modification and distribution
- ✅ Private use
- ✅ Inclusion in proprietary software

The only requirement is to retain the original copyright notice and license text.

### Important Usage Reminder

While this software is open-source, please use it responsibly:
- Comply with game service terms
- Use automation features only in permitted environments
- Avoid affecting other players' gaming experience

## Changelog

### v0.0.1-Alpha-0.1
- Initial version release
- Basic skill detection functionality
- Graphical configuration interface
- Rule engine and buff timers

## Contributing

Welcome to submit Issues and Pull Requests to improve the project.

## Support

If you encounter problems, please check:
1. Error messages in log files
2. Verify skill coordinates and color configurations
3. Confirm game window is not obscured
4. Adjust detection parameters for better accuracy