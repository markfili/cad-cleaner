# Quick Start - Push CAD Cleaner to GitHub

## TL;DR (30 seconds)

1. **Download all files** from this folder
2. **Create project folder**: `mkdir cad-cleaner && cd cad-cleaner`
3. **Copy all files** into the folder
4. **Run setup script**:
   - **Windows CMD/PowerShell**: Double-click `setup_github.bat` OR `setup_github.ps1`
   - **Terminal**: `setup_github.bat` or `powershell -ExecutionPolicy Bypass -File setup_github.ps1`
5. **Done!** Your code is on GitHub

---

## Files You're Getting

### Core Flutter App
- `lib/main.dart` - UI wizard interface (4 steps)
- `lib/autocad_uninstaller.dart` - Uninstallation logic
- `pubspec.yaml` - Flutter dependencies

### Configuration Files
- `.gitignore` - Ignore build files
- `LICENSE` - MIT license
- `README.md` - Full documentation

### Setup & Documentation
- `FLUTTER_BUILD_GUIDE.md` - Detailed build instructions
- `GITHUB_SETUP.md` - Manual GitHub setup guide
- `setup_github.ps1` - PowerShell auto-setup script
- `setup_github.bat` - Batch auto-setup script
- `QUICK_START.md` - This file

---

## Prerequisites

### Required
- ✅ **Git** - Download: https://git-scm.com/download/win
- ✅ **GitHub Account** - Sign up: https://github.com

### Optional (for development)
- Flutter SDK (only needed if building yourself)
- Visual Studio Build Tools (for compilation)

---

## Step-by-Step Instructions

### Option A: Automatic Setup (Recommended)

#### Windows PowerShell
```powershell
# 1. Create folder
mkdir cad-cleaner
cd cad-cleaner

# 2. Copy all files here (Download them first)

# 3. Run setup script
powershell -ExecutionPolicy Bypass -File setup_github.ps1

# 4. Enter GitHub credentials when prompted
```

#### Windows Command Prompt
```cmd
REM 1. Create folder
mkdir cad-cleaner
cd cad-cleaner

REM 2. Copy all files here (Download them first)

REM 3. Double-click setup_github.bat OR run:
setup_github.bat

REM 4. Follow prompts
```

### Option B: Manual Setup (Step by Step)

```bash
# 1. Create and enter directory
mkdir cad-cleaner
cd cad-cleaner

# 2. Initialize Git
git init

# 3. Add all files
git add .

# 4. Create initial commit
git commit -m "Initial commit: Flutter AutoCAD uninstall wizard"

# 5. Add remote
git remote add origin https://github.com/markfili/cad-cleaner.git

# 6. Create main branch
git branch -M main

# 7. Push to GitHub
git push -u origin main
```

---

## During Setup - You'll Be Asked To:

### When Running Script
1. **Confirm files** - Are you ready to push? (y/n)
2. **GitHub credentials** - Appear in browser/terminal
   - Username: `markfili`
   - Password: Use GitHub Personal Access Token
   - [Get token here](https://github.com/settings/tokens)

### If Using SSH (Skip unless configured)
- You'll need to set up SSH keys first
- See GITHUB_SETUP.md for instructions

---

## Troubleshooting

### "Git is not recognized"
```cmd
# Install Git from: https://git-scm.com/download/win
# Restart your terminal after install
```

### "Authentication failed"
```cmd
# Use a Personal Access Token instead of password:
# https://github.com/settings/tokens
# Select: repo, workflow scopes
# Use token as password
```

### "fatal: not a git repository"
```cmd
# Make sure you're in the cad-cleaner directory
cd cad-cleaner
git status
```

### "remote origin already exists"
```cmd
git remote remove origin
git remote add origin https://github.com/markfili/cad-cleaner.git
```

### PowerShell Script Won't Run
```powershell
# Try this:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
powershell -ExecutionPolicy Bypass -File setup_github.ps1

# Or use batch version instead:
setup_github.bat
```

---

## After Push - Next Steps

### 1. Verify Upload
- Visit: https://github.com/markfili/cad-cleaner
- You should see all your files

### 2. Build the Executable (Optional)
```bash
# Install Flutter first from: https://flutter.dev/docs/get-started/install/windows

# In the cad-cleaner directory:
flutter pub get
flutter build windows --release

# Executable will be at:
# build/windows/runner/Release/cad_cleaner.exe
```

### 3. Create a Release on GitHub
1. Go to: https://github.com/markfili/cad-cleaner/releases
2. Click "Create a new release"
3. Version: `v1.0.0`
4. Title: `Version 1.0 - Initial Release`
5. Upload compiled `cad_cleaner.exe` file
6. Publish

### 4. Make it Public (Optional)
1. Go to repository settings
2. Scroll to "Danger Zone"
3. Change visibility to "Public"
4. Now anyone can see and use your project

---

## File Organization

After setup, your directory should look like:

```
cad-cleaner/
├── .git/                          (Auto-created)
├── .gitignore
├── lib/
│   ├── main.dart
│   └── autocad_uninstaller.dart
├── windows/                       (Auto-created by Flutter)
├── LICENSE
├── pubspec.yaml
├── README.md
├── FLUTTER_BUILD_GUIDE.md
├── GITHUB_SETUP.md
├── QUICK_START.md
├── setup_github.bat
└── setup_github.ps1
```

---

## Git Workflow (For Future Updates)

After initial setup, here's how to update your code:

```bash
# Make changes to files

# Check status
git status

# Stage changes
git add .

# Commit
git commit -m "Your descriptive message here"

# Push to GitHub
git push
```

---

## Common Commands Reference

```bash
# Check git status
git status

# See commit history
git log --oneline

# View remote configuration
git remote -v

# Make a new version tag
git tag -a v1.0.1 -m "Bug fix release"
git push origin v1.0.1

# Switch branches
git branch -a
git checkout branch-name
```

---

## Getting Help

### For Git Issues
- Official Git Help: https://git-scm.com/doc
- GitHub Docs: https://docs.github.com
- Git Tutorial: https://guides.github.com

### For Flutter Issues
- Flutter Docs: https://flutter.dev/docs
- Flutter Windows: https://docs.flutter.dev/development/platform-integration/windows

### For This Project
- Check GITHUB_SETUP.md for detailed steps
- Check FLUTTER_BUILD_GUIDE.md for building
- Review README.md for project info

---

## Quick Checklist

Before running setup:
- ✅ Git installed? → https://git-scm.com/download/win
- ✅ GitHub account created? → https://github.com
- ✅ All files downloaded?
- ✅ Running in correct directory (cad-cleaner folder)?
- ✅ Internet connection active?

When running setup:
- ✅ Watch for credential prompts
- ✅ Note any error messages
- ✅ Check if files appear on GitHub

After upload:
- ✅ Verify files on GitHub
- ✅ Check README displays properly
- ✅ Consider building executable
- ✅ Create GitHub release

---

## Success Indicators

✅ You've succeeded when:
1. Setup script completes without errors
2. You see "Successfully pushed to GitHub!" message
3. Repository appears at: https://github.com/markfili/cad-cleaner
4. All files are visible in GitHub repository
5. README.md displays properly on GitHub

---

## Final Note

This is your project now! You can:
- 🔧 Modify the code
- 🎨 Customize the UI
- 🚀 Build and release executables
- 🤝 Invite collaborators
- 📈 Track issues and improvements

Everything is set up for success. Happy coding! 🎉

---

**Need help?** Check the detailed guides:
- Manual setup → GITHUB_SETUP.md
- Building the app → FLUTTER_BUILD_GUIDE.md
- Project info → README.md
