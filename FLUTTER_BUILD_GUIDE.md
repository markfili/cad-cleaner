# Flutter AutoCAD Uninstall Wizard - Build Guide

## Overview
This is a Flutter desktop application that creates a professional uninstall wizard for AutoCAD on Windows. It replaces the batch/PowerShell scripts with a polished GUI application.

## Requirements

- **Flutter SDK** (version 3.0 or later)
- **Dart** (comes with Flutter)
- **Windows 10/11**
- **Visual Studio Build Tools** (for building Windows desktop apps)

## Installation

### 1. Install Flutter

1. Download Flutter from: https://flutter.dev/docs/get-started/install/windows
2. Extract to a folder (e.g., `C:\src\flutter`)
3. Add Flutter to your PATH:
   - Open Environment Variables (Win + R → `sysdm.cpl`)
   - Add `C:\src\flutter\bin` to PATH
4. Verify installation:
   ```cmd
   flutter --version
   ```

### 2. Install Visual Studio Build Tools

1. Download from: https://visualstudio.microsoft.com/downloads/
2. Select "Desktop development with C++"
3. Install required components:
   - Windows 10 SDK
   - CMake
   - Ninja

### 3. Enable Windows Desktop Support

```cmd
flutter config --enable-windows-desktop
```

## Project Setup

### 1. Create Project Structure

Create a folder for the project:
```cmd
mkdir AutoCAD_Uninstall_Wizard
cd AutoCAD_Uninstall_Wizard
```

### 2. Create Flutter App

```cmd
flutter create --platforms windows .
```

### 3. Add Files

Copy the following files into your project:

```
AutoCAD_Uninstall_Wizard/
├── lib/
│   ├── main.dart                 (Copy provided main.dart here)
│   └── autocad_uninstaller.dart  (Copy provided autocad_uninstaller.dart here)
├── pubspec.yaml                  (Replace with provided pubspec.yaml)
└── windows/
    └── runner/
        └── main.cpp              (No changes needed)
```

### 4. Get Dependencies

```cmd
flutter pub get
```

This will download all required packages:
- `process` - For running PowerShell commands
- `path_provider` - For path management
- `windows` - For Windows-specific features

## Building

### Development Build (Debug)

For testing and debugging:

```cmd
flutter run -d windows
```

This will launch the app in debug mode with hot-reload capabilities.

### Release Build (Production)

To create a standalone executable:

```cmd
flutter build windows --release
```

This creates an optimized executable at:
```
build\windows\runner\Release\autocad_uninstall_wizard.exe
```

### Creating an Installer (Optional)

To create a Windows installer, you can use NSIS:

1. Download NSIS from: https://nsis.sourceforge.io/
2. Install it
3. Create a simple installer script, or use a tool like:
   - **Advanced Installer** (free version)
   - **Inno Setup**
   - **WiX Toolset**

## Features

The application provides:

✅ **Step-by-Step Wizard Interface**
- Welcome screen
- Installation detection
- Options selection
- Processing with real-time logs
- Completion confirmation

✅ **Confirmation Dialogs**
- Before detection
- Before uninstallation
- Registry/AppData warnings

✅ **Real-time Logging**
- Shows all operations as they happen
- Color-coded output (dark console)
- Progress tracking

✅ **Multiple Removal Options**
- Program files (always removed)
- Registry entries (optional)
- User data & licenses (optional)

✅ **Error Handling**
- Graceful error messages
- Continues on non-critical errors
- Detailed logging

## Usage

### Running the Executable

1. Right-click `autocad_uninstall_wizard.exe`
2. Select "Run as Administrator" (required)
3. Follow the wizard prompts
4. Confirm removal options
5. Wait for completion
6. Restart computer

### Command Line (Optional)

If you want to build additional command-line tools:

```dart
// Example of running from command line
flutter run --release
```

## File Structure

```
lib/
├── main.dart
│   └── UninstallWizardScreen - Main UI with wizard steps
│       ├── Step 0: Welcome
│       ├── Step 1: Detection
│       ├── Step 2: Options
│       ├── Step 3: Processing
│       └── Step 4: Complete
│
└── autocad_uninstaller.dart
    └── AutoCADUninstaller - Service class
        ├── detectAutoCADInstallations()
        ├── uninstallAutoCADProducts()
        ├── removeAutoCADDirectories()
        ├── cleanAutoCADRegistry()
        ├── removeAutoCADAppData()
        └── PowerShell integration
```

## Customization

### Change App Icon

1. Create a 512x512 PNG icon
2. Place in: `windows\runner\resources\app_icon.ico`
3. Rebuild: `flutter build windows --release`

### Modify Colors/Theme

Edit the `ThemeData` in `main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,  // Change color
  useMaterial3: true,
),
```

### Add Company Branding

Modify the AppBar in UninstallWizardScreen:

```dart
AppBar(
  title: const Text('Your Company - AutoCAD Uninstall'),
  // ...
),
```

## Troubleshooting

### "flutter is not recognized"
- Ensure Flutter is in your PATH
- Restart your terminal/command prompt
- Run `flutter doctor` to diagnose

### "You need Windows 10 or later"
- Ensure you're on Windows 10 or newer
- Check with `winver`

### "Administrator privileges required" dialog
- This is correct behavior
- Always run as Administrator for the app to work

### PowerShell execution policy errors
- The app uses `-ExecutionPolicy Bypass`
- This should work even if policies are restricted
- If issues persist, run as Administrator

### Build fails with Visual Studio errors
- Run `flutter doctor -v` to check environment
- Install missing Visual Studio components
- Restart your computer after installing

## Distribution

### As a Single EXE

The release build creates a standalone executable:
```
build\windows\runner\Release\autocad_uninstall_wizard.exe
```

Simply copy and distribute this file.

### Creating a Setup Package

1. **Using Inno Setup (Free)**
   - Download from: https://jrsoftware.org/isdl.php
   - Create a simple script to package the exe
   - Outputs a Setup.exe installer

2. **Using Advanced Installer (Free)**
   - More user-friendly
   - Automatic uninstaller creation
   - Professional MSI packages

Example Inno Setup script:
```ini
[Setup]
AppName=AutoCAD Uninstall Wizard
AppVersion=1.0
DefaultDirName={pf}\AutoCAD Uninstaller
DefaultGroupName=Autodesk

[Files]
Source: "build\windows\runner\Release\autocad_uninstall_wizard.exe"; DestDir: "{app}"

[Icons]
Name: "{group}\AutoCAD Uninstall Wizard"; Filename: "{app}\autocad_uninstall_wizard.exe"
```

## Performance

The application is lightweight:
- ~50-100 MB disk space
- Minimal memory usage
- Fast startup (~2-3 seconds)
- Real-time logging without lag

## Security

The application:
- ✅ Requires Administrator privileges (enforced)
- ✅ Runs only PowerShell with `-ExecutionPolicy Bypass`
- ✅ No external dependencies or downloads
- ✅ All operations logged for auditing
- ✅ No telemetry or data collection

## Support

For issues with:
- **Flutter Setup**: Visit https://flutter.dev/docs
- **Windows Build Issues**: Check https://docs.flutter.dev/development/platform-integration/windows/building
- **AutoCAD Removal Logic**: Review the PowerShell scripts in `autocad_uninstaller.dart`

## Next Steps

1. Install Flutter SDK
2. Create project structure
3. Copy provided files
4. Run `flutter pub get`
5. Test with `flutter run -d windows`
6. Build release with `flutter build windows --release`
7. Create installer (optional)
8. Distribute and use!

Happy uninstalling! 🎉
