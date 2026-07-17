# CAD Cleaner - AutoCAD Uninstall Wizard

A professional Flutter desktop application for Windows that safely and completely removes AutoCAD installations from your computer.

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✨ **Professional Wizard Interface**
- Step-by-step guided uninstallation process
- Clear visual progress tracking
- Color-coded status messages

🔍 **Smart Detection**
- Automatically scans for all AutoCAD installations
- Detects Autodesk Design Suite, Revit, Civil 3D, and more
- Registry-based detection for accuracy

🛡️ **Safe Removal**
- Kills running AutoCAD processes automatically
- Multiple confirmation dialogs before deletion
- Option to preserve user settings or remove everything
- Real-time logging of all operations

⚙️ **Comprehensive Cleanup**
- Removes program files from Program Files and Program Files (x86)
- Cleans registry entries (optional)
- Removes user data and license information (optional)
- Handles both 32-bit and 64-bit installations

📋 **Real-time Logging**
- View all operations as they happen
- Detailed error messages
- Export logs for troubleshooting

## System Requirements

- **OS**: Windows 10 or later
- **Architecture**: x64 (Intel/AMD)
- **Privileges**: Administrator access required
- **Disk Space**: ~100 MB (application + dependencies)

## Installation

### Option 1: Download Pre-built Executable

1. Go to [Releases](https://github.com/markfili/cad-cleaner/releases)
2. Download the latest `cad-cleaner.exe`
3. Right-click and select "Run as Administrator"

### Option 2: Build from Source

#### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (3.0 or later)
- [Dart](https://dart.dev/get-dart) (included with Flutter)
- [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) with Windows SDK
- Git

#### Build Steps

```bash
# Clone the repository
git clone https://github.com/markfili/cad-cleaner.git
cd cad-cleaner

# Get dependencies
flutter pub get

# Run in debug mode (development)
flutter run -d windows

# Build release executable
flutter build windows --release
```

The compiled executable will be at:
```
build/windows/x64/runner/Release/CadService.exe
```

`CadService.exe` is not standalone — it needs the DLLs and `data\` folder built
alongside it. Run it from that folder, or use the installer from the
[Releases](https://github.com/markfili/cad-cleaner/releases) page.

### Running on macOS / Linux

The removal logic is Windows-only, but the wizard runs anywhere for development:

```bash
fvm flutter run -d macos
```

Non-Windows hosts use a simulated backend (`MockCadService`) that fakes
detection, removal, and the GstarCAD install with realistic delays. Nothing on
the host is read or modified, and the app shows a banner saying so.

## Usage

1. **Download or build** the application
2. **Right-click** the executable and **select "Run as Administrator"**
3. The **home screen** scans automatically and shows two cards:
   - **AutoCAD** — whether it is installed, and which products were found
   - **GstarCAD** — whether it is installed, and whether the installer has
     already been downloaded
4. Start whichever wizard you need from its card
5. **Restart your computer** after an uninstall (recommended)

## The Home Screen

Both checks run on open, and again whenever a wizard closes, so the cards always
reflect the current state. Nothing is modified until you start a wizard.

The **Start Uninstall Wizard** button is disabled when no AutoCAD is found —
there is nothing to remove.

## Uninstall Wizard (4 steps)

1. **Review** — the products found, and the warning that this cannot be undone
2. **Options** — remove registry entries and/or user data (program files always go)
3. **Processing** — real-time log of every operation
4. **Complete** — confirmation, full log, restart recommendation

A confirmation dialog listing exactly what will be removed gates the destructive
work.

## Install Wizard (3 steps)

1. **Review** — the vendor URL, and whether the installer is already downloaded
2. **Downloading & Launching** — download progress, then handoff
3. **Complete** — the vendor's setup window takes over

If the installer is already on disk the download is skipped, unless you tick
"Download a fresh copy anyway". The install is **not** unattended: this wizard
downloads and launches the vendor installer, and you complete it in GstarCAD's
own setup UI.

## What Gets Removed

### Always Removed
- `C:\Program Files\Autodesk`
- `C:\Program Files (x86)\Autodesk`
- AutoCAD executable and all program files

### Optionally Removed
- Registry entries (`HKLM:\Software\Autodesk`, `HKCU:\Software\Autodesk`)
- User data (`%APPDATA%\Autodesk`, `%LOCALAPPDATA%\Autodesk`)
- Licenses and preferences
- File associations (`.dwg`, `.dxf`)

## Project Structure

```
cad-cleaner/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── screens/
│   │   ├── home_screen.dart          # Landing: status of both products
│   │   ├── uninstall_wizard_screen.dart  # AutoCAD removal flow
│   │   └── install_wizard_screen.dart    # GstarCAD install flow
│   ├── widgets/                      # Shared log panel + simulation banner
│   └── cad/
│       ├── cad_service.dart          # Platform-agnostic interface + factory
│       ├── windows_cad_service.dart  # Real removal/install (Windows only)
│       └── mock_cad_service.dart     # Simulated backend (macOS/Linux)
├── windows/
│   ├── runner/main.cpp               # Windows entry point
│   ├── CMakeLists.txt                # Build config (BINARY_NAME=CadService)
│   └── installer.iss                 # Inno Setup script for the installer
├── .github/workflows/release.yml     # Tag-triggered build + GitHub Release
├── .githooks/pre-push                # Asks whether to bump the version + tag
├── .fvmrc                            # Pinned Flutter SDK version
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # This file
```

The `CadService.forPlatform()` factory picks the backend: the real Windows
implementation on Windows, the mock everywhere else. Adding a platform means
adding one subclass — the UI is unchanged.

## Dependencies

- **flutter**: Flutter framework (3.0+)
- **process**: Running external processes
- **path_provider**: Cross-platform path access
- **windows**: Windows-specific APIs

## Building an Installer

To create a Windows installer (`.msi` or Setup.exe):

### Using Inno Setup (Free)

1. Download [Inno Setup](https://jrsoftware.org/isdl.php)
2. Create a script file `installer.iss`:

```ini
[Setup]
AppName=CAD Cleaner
AppVersion=1.0
DefaultDirName={pf}\CAD Cleaner
DefaultGroupName=CAD Cleaner
OutputBaseFilename=CAD_Cleaner_Setup
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\runner\Release\cad_cleaner.exe"; DestDir: "{app}"

[Icons]
Name: "{group}\CAD Cleaner"; Filename: "{app}\cad_cleaner.exe"
Name: "{commondesktop}\CAD Cleaner"; Filename: "{app}\cad_cleaner.exe"
```

3. Run: `ISCC.exe installer.iss`

### Using Advanced Installer (Free)

1. Download [Advanced Installer](https://www.advancedinstaller.com/)
2. Import the exe file
3. Configure and build

## Security & Privacy

- ✅ No external internet connections
- ✅ No telemetry or data collection
- ✅ Requires Administrator privileges (enforced)
- ✅ All operations logged and visible
- ✅ No third-party services used

## Troubleshooting

### Application won't start
- Ensure you're running as Administrator
- Check Windows 10/11 compatibility
- Verify you have 100+ MB free disk space

### "Administrator privileges required" message
- Close the app
- Right-click the executable
- Select "Run as Administrator"

### PowerShell execution policy errors
- The app uses `-ExecutionPolicy Bypass` automatically
- If errors persist, try running as Administrator

### AutoCAD not detected
- Ensure AutoCAD is installed on the system
- Close any running AutoCAD applications
- Run detection step again

### Files couldn't be removed
- Some files may be locked by system processes
- Restart your computer
- Run the wizard again to clean remaining files

## FAQ

**Q: Is it safe to use?**
A: Yes. The application shows all operations before executing them and requires multiple confirmations.

**Q: Can I undo the uninstallation?**
A: No. Make backups of important AutoCAD files before using this tool.

**Q: Will this remove my AutoCAD drawings?**
A: No. It only removes the application and system files. User documents in other locations are not affected.

**Q: Does it work with all Autodesk products?**
A: It's designed for AutoCAD but also detects other Autodesk products (Revit, Civil 3D, etc.).

**Q: Why do I need Administrator access?**
A: Registry modification, system file deletion, and process management require Administrator privileges.

## Releasing

Releases are driven by tags: pushing a `v*.*.*` tag builds the Windows
executable and publishes a GitHub Release with the installer, the portable zip,
and notes generated from the commits since the previous tag.

Enable the pre-push hook once per clone:

```bash
git config core.hooksPath .githooks
```

From then on, `git push` asks whether to bump the version first:

```
  Current version: 1.0.0 (build 1)
  No tag v1.0.0 yet.

  Bump version and tag a release before pushing? [p]atch / [m]inor / [M]ajor / [n]o (default: n):
```

Answer `n` for an ordinary push. Answer `p`/`m`/`M` and the hook bumps
`pubspec.yaml`, commits, and tags — then stops the push, because the new commit
and tag were not part of it. Run the command it prints to send them:

```bash
git push && git push origin v1.0.1
```

The tag push is what triggers the release. CI fails the build if the tag and the
`pubspec.yaml` version disagree, so the two can't drift apart. Use
`git push --no-verify` to skip the prompt entirely.

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Known Issues

- Windows Defender may flag the app as potentially suspicious (false positive). This is normal for unsigned executables.
- Some registry entries may require additional permissions on restricted systems.

## Future Enhancements

- [ ] Support for macOS and Linux
- [ ] Selective product removal (choose which Autodesk products to remove)
- [ ] Backup before deletion
- [ ] Detailed system report
- [ ] Multiple language support
- [ ] Command-line interface (CLI) mode

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

Use this tool at your own risk. Ensure you have backups of important files before uninstalling AutoCAD. The authors assume no responsibility for data loss or system issues.

## Support

For issues, feature requests, or questions:

1. Check the [Issues](https://github.com/markfili/cad-cleaner/issues) page
2. Create a new issue with:
   - Windows version
   - AutoCAD version
   - Detailed steps to reproduce
   - Screenshots/logs if applicable

## Credits

Built with [Flutter](https://flutter.dev) and [Dart](https://dart.dev)

---

**Happy cleaning!** 🎉
