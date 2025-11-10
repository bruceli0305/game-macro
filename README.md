# Game Macro - AutoHotkey Automation Tool

A game automation tool developed with AutoHotkey v2, supporting advanced features like pixel detection, skill rotation, buff timers, and more.

## Features

### 🎯 Core Features
- **Advanced Pixel Detection**: Support for DXGI screen capture, ROI detection, and GDI fallback methods
- **Multi-threading Support**: Multiple independent skill execution threads with worker pool management
- **Smart Avoidance**: Automatic mouse avoidance during color picking to prevent game interference
- **Rule Engine**: Conditional automation rule system with pixel and counter conditions
- **Buff Timers**: Automatic buff renewal functionality with priority-based execution
- **DXGI Screen Capture**: High-performance screen capture using DirectX Graphics Infrastructure
- **Rotation Management**: Complex skill rotation sequences with opener, tracks, and gates
- **Internationalization**: Multi-language support with configurable language packs

### 🛠️ Configuration Management
- **Multi-character Profiles**: Independent JSON-based configurations for different game characters
- **Visual Editor**: Graphical interface for configuring skills, points, rules, and rotations
- **Export Functionality**: Package configurations as standalone scripts
- **Internationalization Support**: Multi-language interface with INI-based language packs
- **Modular Architecture**: Organized code structure for easy maintenance and extension
- **Skill Management**: Comprehensive skill editor with pixel detection settings
- **Point Management**: Color detection point configuration with tolerance controls
- **Rule System**: Advanced rule editor with conditions and actions
- **Rotation Editor**: Complex rotation sequences with multiple phases

## Quick Start

### System Requirements
- Windows operating system
- AutoHotkey v2.0 or higher
- DirectX 11 compatible graphics card (for DXGI screen capture)

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
├── Config/                     # Application configuration
│   └── AppConfig.ini          # Main configuration file
├── Languages/                  # Internationalization files
│   ├── en-US.ini              # English language pack
│   └── zh-CN.ini              # Chinese language pack
├── modules/                    # Functional modules
│   ├── core/                   # Core functionality modules
│   │   ├── AppConfig.ahk      # Configuration management
│   │   └── Core.ahk           # Core system functions
│   ├── engines/                # Engine modules
│   │   ├── BuffEngine.ahk     # Buff management engine
│   │   ├── Dup.ahk            # DXGI screen capture engine
│   │   ├── Pixel.ahk          # Pixel detection engine
│   │   ├── Rotation.ahk        # Rotation management engine
│   │   └── RuleEngine.ahk      # Rule processing engine
│   ├── i18n/                   # Internationalization
│   │   └── Lang.ahk            # Language management
│   ├── lib/                    # External libraries
│   │   ├── dxgi_dup.cpp       # DXGI duplication C++ source
│   │   └── dxgi_dup.dll       # DXGI duplication library
│   ├── runtime/                # Runtime modules
│   │   ├── Counters.ahk        # Counter management
│   │   ├── Hotkeys.ahk         # Hotkey handling
│   │   └── Poller.ahk          # Polling system
│   ├── storage/                # Storage modules
│   │   ├── Exporter.ahk        # Configuration export
│   │   └── Storage.ahk         # Data storage
│   ├── ui/                     # User interface modules
│   │   ├── UI_Layout.ahk       # Layout management
│   │   ├── UI_Shell.ahk        # Shell interface
│   │   ├── dialogs/            # Dialog components
│   │   │   ├── GUI_BuffEditor.ahk      # Buff editor dialog
│   │   │   ├── GUI_PointEditor.ahk    # Point editor dialog
│   │   │   ├── GUI_RuleEditor.ahk      # Rule editor dialog
│   │   │   ├── GUI_SkillEditor.ahk     # Skill editor dialog
│   │   │   ├── GUI_Threads.ahk         # Threads manager dialog
│   │   │   └── UI_DefaultSkillDlg.ahk  # Default skill dialog
│   │   ├── pages/              # Page components
│   │   │   ├── UI_Page_Config.ahk      # Configuration page
│   │   │   └── UI_Page_Settings.ahk    # Settings page
│   │   └── rotation/           # Rotation editor components
│   │       ├── RE_UI_Common.ahk         # Common rotation UI
│   │       ├── RE_UI_Page_Gates.ahk    # Gates page
│   │       ├── RE_UI_Page_General.ahk  # General page
│   │       ├── RE_UI_Page_Opener.ahk  # Opener page
│   │       ├── RE_UI_Page_Tracks.ahk   # Tracks page
│   │       └── RE_UI_Shell.ahk          # Rotation shell
│   ├── util/                   # Utility modules
│   │   └── Utils.ahk           # Utility functions
│   └── workers/                # Worker modules
│       ├── WorkerHost.ahk       # Worker host management
│       └── WorkerPool.ahk       # Worker pool management
├── Profiles/                   # Character profile directory
└── Logs/                       # Log directory
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