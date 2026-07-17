# CAD Cleaner - Automated GitHub Setup Script
# Run this script from the cad-cleaner directory

param(
    [string]$RepoUrl = "https://github.com/markfili/cad-cleaner.git",
    [string]$Branch = "main",
    [switch]$UseSSH = $false
)

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CAD Cleaner - GitHub Repository Setup               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$gitCheck = git --version 2>$null
if ($null -eq $gitCheck) {
    Write-Host "✗ Git is not installed!" -ForegroundColor Red
    Write-Host "  Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Git is installed" -ForegroundColor Green
Write-Host ""

# Check if we're in a project directory with Flutter files
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "✗ pubspec.yaml not found!" -ForegroundColor Red
    Write-Host "  Please run this script from the cad-cleaner directory" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Project files found" -ForegroundColor Green
Write-Host ""

# Initialize Git if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✓ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "✓ Git repository already initialized" -ForegroundColor Green
}
Write-Host ""

# Add all files
Write-Host "Adding files to Git..." -ForegroundColor Yellow
git add .
Write-Host "✓ Files added" -ForegroundColor Green
Write-Host ""

# Check if there are changes to commit
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Creating initial commit..." -ForegroundColor Yellow
    git commit -m "Initial commit: Flutter AutoCAD uninstall wizard"
    Write-Host "✓ Initial commit created" -ForegroundColor Green
} else {
    Write-Host "ℹ No changes to commit" -ForegroundColor Yellow
}
Write-Host ""

# Configure remote
Write-Host "Configuring remote repository..." -ForegroundColor Yellow

# Check if remote already exists
$remoteExists = git config --get remote.origin.url 2>$null
if ($remoteExists) {
    Write-Host "Remote origin already exists: $remoteExists" -ForegroundColor Yellow
    $removeRemote = Read-Host "Replace with new URL? (y/n)"
    if ($removeRemote -eq "y" -or $removeRemote -eq "Y") {
        git remote remove origin
        Write-Host "✓ Old remote removed" -ForegroundColor Green
    } else {
        Write-Host "Using existing remote" -ForegroundColor Yellow
    }
}

if (-not (git config --get remote.origin.url 2>$null)) {
    if ($UseSSH) {
        $sshUrl = "git@github.com:markfili/cad-cleaner.git"
        git remote add origin $sshUrl
        Write-Host "✓ SSH remote added: $sshUrl" -ForegroundColor Green
    } else {
        git remote add origin $RepoUrl
        Write-Host "✓ HTTPS remote added: $RepoUrl" -ForegroundColor Green
    }
}
Write-Host ""

# Create/switch to main branch
Write-Host "Setting up main branch..." -ForegroundColor Yellow
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
if ($currentBranch -ne $Branch) {
    git branch -M $Branch
    Write-Host "✓ Branch renamed to: $Branch" -ForegroundColor Green
} else {
    Write-Host "✓ Already on branch: $Branch" -ForegroundColor Green
}
Write-Host ""

# Push to GitHub
Write-Host "═════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Ready to push to GitHub!" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Repository URL: $RepoUrl" -ForegroundColor Cyan
Write-Host "Branch: $Branch" -ForegroundColor Cyan
Write-Host ""

$proceed = Read-Host "Push to GitHub now? (y/n)"
if ($proceed -eq "y" -or $proceed -eq "Y") {
    Write-Host ""
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    Write-Host "(You may be prompted for credentials)" -ForegroundColor Gray
    Write-Host ""
    
    $pushResult = git push -u origin $Branch 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║              ✓ Successfully pushed to GitHub!          ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your repository is now available at:" -ForegroundColor Green
        Write-Host "  $RepoUrl" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Visit: https://github.com/markfili/cad-cleaner" -ForegroundColor Yellow
        Write-Host "  2. Build the project: flutter build windows --release" -ForegroundColor Yellow
        Write-Host "  3. Create a release with the compiled exe" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "✗ Push failed!" -ForegroundColor Red
        Write-Host "Error output:" -ForegroundColor Yellow
        Write-Host $pushResult
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  • Check your internet connection" -ForegroundColor Yellow
        Write-Host "  • Verify GitHub credentials are set up" -ForegroundColor Yellow
        Write-Host "  • See GITHUB_SETUP.md for detailed instructions" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "Push cancelled by user" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To push manually, run:" -ForegroundColor Gray
    Write-Host "  git push -u origin $Branch" -ForegroundColor Gray
    Write-Host ""
}

# Show status
Write-Host "Git Status:" -ForegroundColor Cyan
git status

Read-Host "`nPress Enter to exit"
