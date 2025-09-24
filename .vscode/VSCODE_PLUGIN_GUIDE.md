# 🎯 VS Code Plugin for Drive Speed Testing

This VS Code workspace configuration provides easy-to-use tasks and shortcuts for running Raspberry Pi 5 drive speed tests directly from your editor.

## 🚀 Quick Access Methods

### Method 1: Command Palette
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Tasks: Run Task"
3. Select from available drive speed test tasks

### Method 2: Keyboard Shortcuts
- **`Ctrl+Shift+T`** - Run Complete Drive Speed Report
- **`Ctrl+Shift+F`** - Run Filesystem Speed Test
- **`Ctrl+Shift+Q`** - Quick Performance Test
- **`Ctrl+Shift+M`** - Make Scripts Executable

### Method 3: Terminal Menu
1. Go to **Terminal** → **Run Task...**
2. Select your desired test from the list

### Method 4: Status Bar
Look for task icons in the VS Code status bar (if available)

## 📋 Available Tasks

### 🚀 Complete Drive Speed Report
- **Purpose**: Generate comprehensive performance report
- **Usage**: Best for detailed analysis and documentation
- **Output**: Formatted report with system info and benchmarks

### 💾 Filesystem Speed Test
- **Purpose**: Test mounted filesystem performance
- **Usage**: Works in containers and restricted environments
- **Output**: Table showing read/write speeds by filesystem

### 🔧 Hardware Drive Test (Requires Sudo)
- **Purpose**: Test raw hardware drive performance
- **Usage**: Only for Raspberry Pi 5 with external drives
- **Output**: NVMe and USB drive performance data
- **Note**: Requires sudo privileges

### 📊 Generate Speed Report to File
- **Purpose**: Save test results to timestamped file
- **Usage**: For keeping historical performance records
- **Output**: Creates `speed_report_YYYYMMDD_HHMMSS.txt`

### 🧪 Quick Performance Test
- **Purpose**: Fast 50MB write speed check
- **Usage**: Quick validation of storage performance
- **Output**: Single line with write speed

### 🛠️ Make Scripts Executable
- **Purpose**: Set proper permissions on all shell scripts
- **Usage**: Run once after downloading/cloning repository
- **Output**: Confirmation message

### 📁 Open Reports Directory
- **Purpose**: List all generated report files
- **Usage**: Review previous test results
- **Output**: List of all `.txt` report files

## 🎮 VS Code Features Enabled

### Auto-completion & Syntax Highlighting
- Shell script syntax highlighting
- ShellCheck integration for error detection
- Bash IDE features for better development experience

### File Organization
- Automatic file nesting (reports grouped under scripts)
- Proper file associations for `.sh` files
- Hidden clutter files for cleaner workspace

### Terminal Integration
- Tasks run in integrated terminal
- Colorized output for better readability
- Persistent terminal sessions

### Debugging Support
- Launch configurations for script debugging
- Breakpoint support (with bash-debug extension)
- Step-through debugging capabilities

## 🔧 Recommended Extensions

The workspace automatically suggests these extensions:
- **ShellCheck** - Bash/shell script linting
- **Bash Debug** - Debug shell scripts with breakpoints
- **Shell Format** - Auto-format shell scripts
- **Bash IDE** - Enhanced bash development features

## 📖 Usage Examples

### Running Your First Test
1. Open VS Code in the `rpi5` repository
2. Press `Ctrl+Shift+M` to make scripts executable
3. Press `Ctrl+Shift+F` to run filesystem test
4. View results in the integrated terminal

### Generating Reports for Documentation
1. Press `Ctrl+Shift+P` → "Tasks: Run Task"
2. Select "📊 Generate Speed Report to File"
3. Check the `read-write-rpi5-drive-speed-test/` folder for the new report

### Quick Performance Validation
1. Press `Ctrl+Shift+Q` for instant 50MB write test
2. Get immediate feedback on storage performance

### Hardware Testing (Raspberry Pi 5 only)
1. Ensure you're on actual Pi 5 hardware with connected drives
2. Press `Ctrl+Shift+P` → "Tasks: Run Task"
3. Select "🔧 Hardware Drive Test (Requires Sudo)"
4. Enter sudo password when prompted

## 🎯 Tips for Best Experience

### Performance Testing Tips
- Run tests multiple times for consistency
- Ensure adequate free disk space (>500MB recommended)
- Close other applications during testing for accurate results

### VS Code Optimization
- Use split terminals to compare multiple test outputs
- Pin frequently used tasks to the command palette
- Customize keyboard shortcuts in File → Preferences → Keyboard Shortcuts

### Report Management
- Reports are automatically timestamped
- Use the "📁 Open Reports Directory" task to manage old reports
- Archive important reports outside the project directory

## 🚨 Troubleshooting

### Task Not Found
- Check that you're in the correct workspace (`rpi5` repository)
- Verify `.vscode/tasks.json` exists in the workspace root

### Permission Denied
- Run the "🛠️ Make Scripts Executable" task first
- For hardware tests, ensure you have sudo privileges

### Extension Errors
- Install recommended extensions via the popup notification
- Reload VS Code window: `Ctrl+Shift+P` → "Developer: Reload Window"

### Script Execution Fails
- Check that you're in a Linux environment (required for drive tests)
- Verify all dependencies are installed (handled automatically by scripts)

## 📚 Further Reading

- See `README.md` for complete script documentation
- See `USAGE.md` for command-line usage examples
- Check individual script files for detailed parameter options

---

**Pro Tip**: Bookmark this workspace and use the tasks regularly to monitor your Raspberry Pi 5's storage performance over time!
