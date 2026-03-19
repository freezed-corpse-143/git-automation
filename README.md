# Git Automation Toolkit

## 📋 Project Overview

A powerful Windows PowerShell automation toolkit for Git and GitHub workflows. This project provides two essential scripts for automating common Git operations:

- **`gitinit.ps1`** - Intelligent Git repository initialization and synchronization
- **`gitwatch.ps1`** - Continuous Git monitoring and automatic commit/push system

## ✨ Features

### GitInit Script
- **Smart Repository Detection**: Automatically detects existing repositories and handles them appropriately
- **Remote Repository Management**: Creates GitHub repositories via CLI or syncs with existing ones
- **Template Generation**: Creates `.gitignore` and `README.md` templates automatically
- **Idempotent Operations**: Safe to run multiple times without side effects
- **Branch Management**: Handles both `master` and `main` branch conventions
- **Backup Protection**: Safely backs up existing files before cloning

### GitWatch Script
- **Continuous Monitoring**: Watches for file changes every 5 seconds
- **Auto-Commit**: Automatically commits changes with timestamped messages
- **Remote Synchronization**: Pulls remote changes and pushes local commits
- **Conflict Handling**: Stashes local changes before pulling to avoid conflicts
- **Smart Status Detection**: Only acts when actual changes are detected

## 🚀 Quick Start

### Prerequisites

1. **Git Installation**
   ```cmd
   # Download from: https://git-scm.com/downloads
   git --version
   ```

2. **GitHub CLI Installation**
   ```cmd
   # Download from: https://github.com/cli/cli/releases
   # Extract and add to PATH:
   setx PATH "%PATH%;<github cli dir>"
   gh --version
   ```

3. **GitHub Authentication**
   ```cmd
   # Create token at: https://github.com/settings/tokens (classic)
   # Select at least: repo, read:org, workflow
   gh auth login
   ```

4. **Git Configuration**
   ```cmd
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### Installation Steps

1. **Clone or Download this Repository**
   ```powershell
   # Clone the repository
   git clone https://github.com/your-username/git-automation.git
   cd git-automation
   ```

2. **Make Scripts Executable (Optional)**
   ```powershell
   # In PowerShell, scripts are executable by default
   # You may need to set execution policy:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 📖 Usage Instructions

### GitInit Script - Repository Setup

**Basic Usage:**
```powershell
# Run from any directory to initialize Git repository
.\gitinit.ps1
```

**What it does:**
- Checks if remote repository exists on GitHub
- Creates repository if it doesn't exist
- Initializes local Git repository
- Generates `.gitignore` and `README.md` files
- Sets up remote tracking and pushes initial commit
- Handles existing repositories gracefully

**Example Output:**
```
[INFO] 14:30:25 - GitHub User: your-username
[INFO] 14:30:25 - Project Directory: C:\Projects\my-project
[INFO] 14:30:25 - Creating new remote repository...
[SUCCESS] 14:30:27 - Remote repository created successfully
[INFO] 14:30:27 - Initializing local repository...
[INFO] 14:30:27 - Generating .gitignore...
[SUCCESS] 14:30:27 - .gitignore generated successfully
[INFO] 14:30:27 - Generating README.md...
[SUCCESS] 14:30:27 - README.md created
[SUCCESS] 14:30:27 - Local initial commit completed
[INFO] 14:30:27 - Pushing code to main branch...
[SUCCESS] 14:30:29 - Code successfully pushed to https://github.com/your-username/my-project.git
[SUCCESS] 14:30:29 - >>> Project initialization process completed!
```

### GitWatch Script - Continuous Monitoring

**Basic Usage:**
```powershell
# Run from a Git repository directory
.\gitwatch.ps1
```

**What it does:**
- Monitors current directory for file changes every 5 seconds
- Automatically commits changes with timestamped messages
- Pulls remote changes before committing to avoid conflicts
- Stashes local changes temporarily during pull operations
- Pushes commits to remote repository
- Stops when you press Ctrl+C

**Example Output:**
```
Git Auto Watch - Minimal Version
Watching: C:\Projects\my-project
Branch: main
Remote: https://github.com/your-username/my-project.git
Script ready - Press Ctrl+C to stop

Changes detected: M  README.md
Changes committed and pushed at 3/19/2026 14:35:22
```

## 🛠 Configuration Options

### GitInit Customization

**GitIgnore Templates:**
The script includes multiple `.gitignore` templates:
- `Default` - General purpose (OS files, IDE, dependencies)
- `Windows` - Windows-specific files
- `Python` - Python development
- `Node` - Node.js/JavaScript development

**README Template:**
Automatically generates a professional README.md with placeholders for project-specific information.

### GitWatch Behavior

**Monitoring Interval:**
- Default: 5 seconds between checks
- Can be modified in the script by changing `Start-Sleep -Seconds 5`

**Commit Messages:**
- Format: "Auto: [timestamp]"
- Can be customized in the script

## 🚨 Important Notes

1. **GitHub CLI Required**: Both scripts depend on `gh` command-line tool
2. **Authentication**: Must be logged into GitHub CLI before running
3. **Execution Policy**: PowerShell execution policy may need adjustment
4. **Network Access**: Scripts require internet access for GitHub operations
5. **Backup**: `gitinit.ps1` creates backups of existing files before cloning

## 🔧 Troubleshooting

**Common Issues:**

1. **"GitHub CLI (gh) not detected"**
   - Install GitHub CLI and add to PATH
   - Restart PowerShell after installation

2. **"Please log in to GitHub CLI first"**
   - Run `gh auth login` and follow prompts
   - Ensure token has required permissions

3. **Execution Policy Restrictions**
   - Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

4. **Push Failures**
   - Check internet connection
   - Verify GitHub token permissions
   - Ensure repository exists on GitHub

## 📝 License

This project is licensed under the [MIT License](https://mit-license.org).

## 🙏 Acknowledgements

- **GitHub CLI Team** - For the excellent `gh` command-line tool
- **PowerShell Community** - For robust scripting capabilities
- **Git Development Team** - For the foundational version control system

---

**Happy Coding! 🚀**