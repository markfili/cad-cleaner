@echo off
REM CAD Cleaner - GitHub Setup Script (Batch Version)
REM Run this script from the cad-cleaner directory

setlocal enabledelayedexpansion

color 0B
echo.
echo ========================================
echo  CAD Cleaner - GitHub Repository Setup
echo ========================================
echo.

REM Check if Git is installed
echo Checking if Git is installed...
git --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Git is not installed!
    echo Download from: https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)
color 0B
echo [OK] Git is installed
echo.

REM Check if pubspec.yaml exists
if not exist "pubspec.yaml" (
    color 0C
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the cad-cleaner directory
    echo.
    pause
    exit /b 1
)
echo [OK] Project files found
echo.

REM Initialize Git if needed
if not exist ".git" (
    echo Initializing Git repository...
    git init
    echo [OK] Git repository initialized
) else (
    echo [OK] Git repository already initialized
)
echo.

REM Add all files
echo Adding files to Git...
git add .
echo [OK] Files added
echo.

REM Create initial commit
echo Creating initial commit...
git commit -m "Initial commit: Flutter AutoCAD uninstall wizard"
if errorlevel 0 (
    echo [OK] Initial commit created
) else (
    echo [OK] Commit already exists
)
echo.

REM Configure remote
echo Configuring remote repository...
git remote remove origin 2>nul
git remote add origin https://github.com/markfili/cad-cleaner.git
echo [OK] Remote repository configured
echo.

REM Create/switch to main branch
echo Setting up main branch...
git branch -M main
echo [OK] Main branch ready
echo.

REM Summary
echo ========================================
echo Ready to push to GitHub!
echo ========================================
echo.
echo Repository: https://github.com/markfili/cad-cleaner.git
echo Branch: main
echo.
set /p proceed="Push to GitHub now? (y/n): "

if /i not "%proceed%"=="y" (
    echo Push cancelled
    echo.
    echo To push manually, run:
    echo   git push -u origin main
    echo.
    pause
    exit /b 0
)

echo.
echo Pushing to GitHub...
echo (You may be prompted for GitHub credentials)
echo.
git push -u origin main

if errorlevel 0 (
    color 0A
    echo.
    echo ========================================
    echo [SUCCESS] Pushed to GitHub!
    echo ========================================
    echo.
    echo Repository: https://github.com/markfili/cad-cleaner
    echo.
    echo Next steps:
    echo   1. Visit the repository link above
    echo   2. Build: flutter build windows --release
    echo   3. Create a release with the exe file
    echo.
) else (
    color 0C
    echo.
    echo [ERROR] Push failed!
    echo Check your internet connection and GitHub credentials
    echo.
)

pause
exit /b 0
