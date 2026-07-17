# GitHub Setup & Push Instructions

This guide will help you push the CAD Cleaner project to your GitHub repository.

## Prerequisites

1. **Git installed** - Download from https://git-scm.com/download/win
2. **GitHub account** - https://github.com
3. **Repository created** - https://github.com/markfili/cad-cleaner.git
4. **SSH or HTTPS credentials** - Set up GitHub credentials locally

## Step-by-Step Instructions

### 1. Create Project Directory

```bash
# Open Command Prompt or PowerShell
mkdir cad-cleaner
cd cad-cleaner
```

### 2. Copy All Files

Copy these files into the `cad-cleaner` directory:

```
cad-cleaner/
├── lib/
│   ├── main.dart
│   └── autocad_uninstaller.dart
├── windows/
│   └── (existing Flutter structure)
├── .gitignore
├── pubspec.yaml
├── README.md
├── FLUTTER_BUILD_GUIDE.md
├── GITHUB_SETUP.md
└── LICENSE (optional)
```

### 3. Initialize Git Repository

```bash
cd cad-cleaner
git init
```

### 4. Create Initial Commit

```bash
# Add all files
git add .

# Commit with message
git commit -m "Initial commit: Flutter AutoCAD uninstall wizard"
```

### 5. Add Remote Repository

Replace `USERNAME` with your GitHub username if different:

```bash
git remote add origin https://github.com/markfili/cad-cleaner.git
```

Or using SSH (if configured):

```bash
git remote add origin git@github.com:markfili/cad-cleaner.git
```

### 6. Create Main Branch

```bash
git branch -M main
```

### 7. Push to GitHub

```bash
git push -u origin main
```

If prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Your GitHub personal access token (not your GitHub password)

## Setting Up GitHub Credentials

### If Using HTTPS (Recommended for First Time)

1. Go to https://github.com/settings/tokens
2. Click "Generate new token"
3. Select scopes: `repo`, `workflow`
4. Copy the token (you won't see it again)
5. Use the token as your password when pushing

### If Using SSH (More Secure)

1. **Generate SSH key**:
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

2. **Press Enter** to accept default location

3. **Add to SSH agent**:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

4. **Copy public key**:
```bash
type C:\Users\YOUR_USERNAME\.ssh\id_ed25519.pub
# Copy the output
```

5. **Add to GitHub**:
   - Go to https://github.com/settings/keys
   - Click "New SSH key"
   - Paste the key
   - Click "Add SSH key"

## Automated Setup Script

Save this as `setup_github.bat` and run it:

```batch
@echo off
REM CAD Cleaner - GitHub Setup Script

echo Setting up CAD Cleaner project...
echo.

REM Initialize Git
git init
echo ✓ Git initialized

REM Add all files
git add .
echo ✓ Files added

REM Create initial commit
git commit -m "Initial commit: Flutter AutoCAD uninstall wizard"
echo ✓ Initial commit created

REM Add remote
git remote add origin https://github.com/markfili/cad-cleaner.git
echo ✓ Remote repository added

REM Create main branch
git branch -M main
echo ✓ Main branch created

REM Push to GitHub
echo.
echo Pushing to GitHub (you may be prompted for credentials)...
git push -u origin main

echo.
echo ✓ Setup complete!
echo.
echo Your project is now available at: https://github.com/markfili/cad-cleaner
pause
```

## After Initial Push

### For Future Updates

```bash
# Make changes to files

# Stage changes
git add .

# Commit
git commit -m "Your descriptive message"

# Push to GitHub
git push
```

### Create Release Tags

```bash
# Tag a version
git tag -a v1.0.0 -m "First release"

# Push tag to GitHub
git push origin v1.0.0
```

## Project Structure on GitHub

After successful push, your repository should look like:

```
cad-cleaner/
├── lib/
│   ├── main.dart
│   └── autocad_uninstaller.dart
├── windows/
│   ├── runner/
│   │   ├── resources/
│   │   │   └── app_icon.ico
│   │   └── main.cpp
│   ├── CMakeLists.txt
│   └── flutter/
├── .gitignore
├── pubspec.yaml
├── README.md
├── FLUTTER_BUILD_GUIDE.md
├── GITHUB_SETUP.md
└── LICENSE
```

## Verify Upload

1. Go to https://github.com/markfili/cad-cleaner
2. You should see your files
3. README.md will display on the main page
4. Code is ready for collaboration

## Creating Releases

To create a release on GitHub:

1. Go to your repository
2. Click "Releases" on the right sidebar
3. Click "Create a new release"
4. Enter version number (e.g., `v1.0.0`)
5. Give it a title (e.g., "Version 1.0 - Initial Release")
6. Add release notes
7. Optionally upload the compiled `cad_cleaner.exe` file
8. Click "Publish release"

## Troubleshooting

### "fatal: not a git repository"
```bash
# Make sure you're in the cad-cleaner directory
cd cad-cleaner
git status
```

### "remote origin already exists"
```bash
# Remove the existing remote
git remote remove origin

# Add the correct one
git remote add origin https://github.com/markfili/cad-cleaner.git
```

### "Permission denied (publickey)"
- You're using SSH but haven't configured it
- Use HTTPS instead or set up SSH properly
- See "Setting Up GitHub Credentials" above

### "fatal: could not read Username"
- You're using HTTPS but haven't set up credentials
- Generate a personal access token (see GitHub credentials section)
- Use token as password

### Changes not appearing after push
```bash
# Force refresh
git status
git log --oneline

# If needed, force push (use carefully)
git push -u origin main --force
```

## Next Steps

1. ✅ Push code to GitHub
2. 🏷️ Create a release with compiled exe
3. 📝 Update README with installation instructions
4. ⭐ Get stars and share with others
5. 🤝 Accept pull requests from contributors
6. 📊 Monitor issues for bug reports

## GitHub Actions (Optional)

To set up automatic builds, create `.github/workflows/build.yml`:

```yaml
name: Flutter Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - run: flutter pub get
      
      - run: flutter build windows --release
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: cad-cleaner-windows
          path: build/windows/runner/Release/cad_cleaner.exe
```

## Support

For GitHub-specific help:
- GitHub Docs: https://docs.github.com
- Git Tutorial: https://git-scm.com/doc
- GitHub Guides: https://guides.github.com

---

Good luck! Your CAD Cleaner project is now on GitHub! 🚀
