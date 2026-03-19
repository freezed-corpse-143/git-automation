<#
.SYNOPSIS
    Highly robust Git initialization script.
    Resolves path references, branch naming ambiguity, and remote synchronization issues.
    Supports idempotence: pulls if remote exists, creates and pushes if not.
#>

# --- Basic Configuration ---
$RepoName = (Get-Item .).Name
$DefaultBranch = "main"

# --- Template Configuration (editable) ---
$GitIgnoreTemplates = @{
    # Predefined gitignore combinations
    Default = @(
        "# Operating System Files",
        ".DS_Store",
        "Thumbs.db",
        "desktop.ini",
        "",
        "# IDE",
        ".vscode/",
        ".idea/",
        "*.swp",
        "*.swo",
        "*~",
        "",
        "# Dependencies",
        "node_modules/",
        "vendor/",
        "",
        "# Build outputs",
        "dist/",
        "build/",
        "*.exe",
        "*.dll",
        "*.so",
        "*.dylib",
        "",
        "# Logs and databases",
        "*.log",
        "*.sql",
        "*.sqlite",
        "",
        "# Environment files",
        ".env",
        ".venv",
        "venv/",
        "ENV/",
        "env/",
        "",
        "# Python",
        "__pycache__/",
        "*.py[cod]",
        "*$py.class",
        "*.so",
        ".Python",
        "pip-log.txt",
        "pip-delete-this-directory.txt",
        "",
        "# Node",
        "npm-debug.log*",
        "yarn-debug.log*",
        "yarn-error.log*",
        "package-lock.json",
        "yarn.lock",
        "",
        "# Testing",
        ".coverage",
        ".pytest_cache/",
        ".nyc_output/"
    )

    # Additional combinations can be added as needed
    Windows = @(
        "# Windows",
        "*.cab",
        "*.msi",
        "*.msm",
        "*.msp",
        "*.lnk"
    )

    Python = @(
        "# Python specific",
        "*.egg",
        "*.egg-info/",
        "dist/",
        "build/",
        ".tox/",
        "docs/_build/"
    )

    Node = @(
        "# Node specific",
        "node_modules/",
        "npm-debug.log*",
        "yarn-debug.log*",
        "yarn-error.log*",
        ".npm/",
        ".eslintcache",
        ".cache/"
    )
}

$ReadMeTemplate = @"
# {ProjectName}

## 📋 Project Introduction
[Briefly describe the purpose and functionality of the project here]

## ✨ Features
- Feature 1
- Feature 2
- Feature 3

## 🚀 Quick Start

### Requirements
- [List required software/dependencies]
- [Version requirements]

### Installation Steps


## 📖 Usage Instructions
[Detailed instructions on how to use this project]

### Basic Usage

### Configuration Options

## 📝 License
This project is licensed under the [MIT](https://mit-license.org) License.

## 🙏 Acknowledgements
- [People/Projects to thank]
- [Third-party libraries used]

"@

function Write-Log($Message, $Level = "INFO")
{
    $Color = switch($Level)
    {
        "WARN"
        { "Yellow"
        }
        "ERROR"
        { "Red"
        }
        "SUCCESS"
        { "Green"
        }
        Default
        { "Cyan"
        }
    }
    Write-Host "[$Level] $(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Color
}

# Modified New-GitIgnoreFile function
function New-GitIgnoreFile
{
    param(
        [string]$Path = ".gitignore",
        [string[]]$TemplateNames = @("Default"),
        [switch]$Append
    )

    $content = @()

    foreach ($templateName in $TemplateNames)
    {
        if ($GitIgnoreTemplates.ContainsKey($templateName))
        {
            if ($content.Count -gt 0)
            {
                $content += ""  # Add empty line to separate different templates
            }
            # Fix: Use += operator to merge array contents, not add the whole array as a single element
            $content += $GitIgnoreTemplates[$templateName]
        } else
        {
            Write-Log "Unknown gitignore template: $templateName" "WARN"
        }
    }

    # Add custom content marker
    $content += @(
        "",
        "# User-specific additions",
        "# Add your custom rules below this line"
    )

    if ($Append -and (Test-Path $Path))
    {
        # Append mode
        $existingContent = Get-Content $Path -Encoding UTF8
        $existingContent += $content
        Set-Content -Path $Path -Value $existingContent -Encoding UTF8
    } else
    {
        # Write directly, one entry per line
        Set-Content -Path $Path -Value $content -Encoding UTF8
    }
}

# Modified New-ReadMeFile function
function New-ReadMeFile
{
    param(
        [string]$Path = "README.md",
        [hashtable]$Tokens = @{}
    )

    $content = $ReadMeTemplate

    # Fix: Use ordered dictionary to avoid key duplication, or handle merging correctly
    $defaultTokens = @{
        "{ProjectName}" = $RepoName
        "{Username}" = $ghUser
        "{Date}" = (Get-Date -Format "yyyy-MM-dd")
    }

    # Create new dictionary to avoid key duplication issues
    $allTokens = @{}

    # First add default tokens
    foreach ($key in $defaultTokens.Keys)
    {
        $allTokens[$key] = $defaultTokens[$key]
    }

    # Then add custom tokens (will overwrite default tokens with the same name)
    foreach ($key in $Tokens.Keys)
    {
        $allTokens[$key] = $Tokens[$key]
    }

    foreach ($key in $allTokens.Keys)
    {
        $content = $content.Replace($key, $allTokens[$key])
    }

    Set-Content -Path $Path -Value $content -Encoding UTF8
}

# 1. Environment and Path Check
if (-not (Get-Command gh -ErrorAction SilentlyContinue))
{
    Write-Log "GitHub CLI (gh) not detected. Please install it first." "ERROR"
    exit 1
}

# Check GitHub login status
$ghUser = gh api user -q ".login" 2>$null
if (-not $ghUser)
{
    Write-Log "Please log in to GitHub CLI first: gh auth login" "ERROR"
    exit 1
}

Write-Log "GitHub User: $ghUser" "SUCCESS"
Write-Log "Project Directory: $(Get-Location)"

# 2. Check and set Git default branch (eliminate master warning)
$gitDefaultBranch = git config --global init.defaultBranch
if (-not $gitDefaultBranch)
{
    Write-Log "Setting Git default branch to $DefaultBranch" "INFO"
    git config --global init.defaultBranch $DefaultBranch
}

# 3. Check remote repository status
$remoteUrl = "https://github.com/$ghUser/$RepoName.git"
$remoteExists = $false

Write-Log "Checking remote repository: $ghUser/$RepoName" "INFO"

# Use gh api to directly check if repository exists (more accurate)
$repoCheck = gh api "repos/$ghUser/$RepoName" --silent 2>&1
if ($LASTEXITCODE -eq 0)
{
    $remoteExists = $true
    Write-Log "Remote repository already exists" "WARN"
} else
{
    Write-Log "Remote repository does not exist" "INFO"
}

# 4. Handle local repository based on remote status
$localRepoExists = Test-Path ".git"

if ($remoteExists)
{
    # Scenario 1: Remote exists
    Write-Log "Handling existing remote repository..." "INFO"

    if ($localRepoExists)
    {
        # Local repository exists, check and set remote
        Write-Log "Local repository exists, checking remote association..." "INFO"

        $currentRemote = git remote get-url origin 2>$null
        if (-not $currentRemote)
        {
            git remote add origin $remoteUrl
            Write-Log "Associated remote origin: $remoteUrl" "SUCCESS"
        } elseif ($currentRemote -ne $remoteUrl)
        {
            git remote set-url origin $remoteUrl
            Write-Log "Updated remote origin to: $remoteUrl" "SUCCESS"
        } else
        {
            Write-Log "Remote origin already correctly associated" "SUCCESS"
        }

        # Pull latest code
        Write-Log "Pulling remote code..." "INFO"

        # Get remote branch information
        git fetch origin

        # Check if there are any commits locally
        $hasCommits = git rev-parse --verify HEAD 2>$null

        if (-not $hasCommits)
        {
            # No local commits, attempt to reset to remote
            if (git ls-remote --heads origin $DefaultBranch | Select-String "refs/heads/$DefaultBranch")
            {
                Write-Log "No local commits, resetting to remote $DefaultBranch branch" "INFO"
                git reset --hard origin/$DefaultBranch
            } elseif (git ls-remote --heads origin master | Select-String "refs/heads/master")
            {
                Write-Log "No local commits, resetting to remote master branch" "INFO"
                git reset --hard origin/master
            }
        } else
        {
            # Local commits exist, attempt to merge
            $currentBranch = git branch --show-current
            if ($currentBranch)
            {
                # Check if there is a remote tracking branch
                $remoteBranch = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
                if ($remoteBranch)
                {
                    Write-Log "Merging remote changes into local $currentBranch..." "INFO"
                    $pullResult = git pull --rebase origin $currentBranch 2>&1
                    $pullExitCode = $LASTEXITCODE

                    # Process pull output
                    foreach ($line in $pullResult)
                    {
                        if ($pullExitCode -ne 0 -and ($line -match "^error:|^fatal:|^ERROR:|^! \[rejected\]"))
                        {
                            Write-Host "ERROR: $line" -ForegroundColor Red
                        } else
                        {
                            # Normal output or successful pull messages
                            Write-Host $line -ForegroundColor Gray
                        }
                    }

                    if ($pullExitCode -eq 0)
                    {
                        Write-Log "Pull completed successfully" "SUCCESS"
                    } else
                    {
                        Write-Log "Pull failed with exit code: $pullExitCode" "ERROR"
                    }
                }
            }
        }
    } else
    {
        # Local repository does not exist, clone
        Write-Log "Local repository does not exist, cloning remote repository..." "INFO"

        # Backup current directory contents (if any)
        $currentItems = Get-ChildItem -Exclude ".git", $MyInvocation.MyCommand.Name
        if ($currentItems)
        {
            $backupDir = "../${RepoName}_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Log "Current directory is not empty, backing up to: $backupDir" "WARN"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Move-Item -Path * -Destination $backupDir -Exclude $MyInvocation.MyCommand.Name -ErrorAction SilentlyContinue
        }

        # Clone the repository
        $cloneResult = git clone $remoteUrl . 2>&1
        if ($LASTEXITCODE -eq 0)
        {
            Write-Log "Repository clone completed" "SUCCESS"
        } else
        {
            Write-Log "Clone failed: $cloneResult" "ERROR"
        }
    }
} else
{
    # Scenario 2: Remote does not exist
    Write-Log "Creating new remote repository..." "INFO"

    # Create remote repository
    $createOutput = gh repo create $RepoName --public --description "Repository created by init script" 2>&1
    if ($LASTEXITCODE -eq 0)
    {
        Write-Log "Remote repository created successfully" "SUCCESS"
    } else
    {
        Write-Log "Failed to create remote repository" "ERROR"
        Write-Log "Error details: $createOutput" "ERROR"
        exit 1
    }

    # Handle local repository
    if (-not $localRepoExists)
    {
        Write-Log "Initializing local repository..." "INFO"
        git init

        # Set line ending handling
        git config core.autocrlf true

        # Create essential files
        if (-not (Test-Path ".gitignore"))
        {
            Write-Log "Generating .gitignore..."

            # Use template function to create .gitignore
            New-GitIgnoreFile -TemplateNames @("Default")

            # Optional: Add specific templates based on project type
            # Logic to detect project type and add corresponding templates
            if ((Test-Path "*.sln") -or (Test-Path "*.csproj"))
            {
                # If it's a .NET project, add more rules
                Write-Log "Detected .NET project, adding additional rules" "INFO"
                New-GitIgnoreFile -Append -TemplateNames @("Windows")
            }

            Write-Log ".gitignore generated successfully" "SUCCESS"
        }

        if (-not (Test-Path "README.md"))
        {
            Write-Log "Generating README.md..."

            # Use template function to create README.md
            $readmeTokens = @{
                "{ProjectName}" = $RepoName
                "{Username}" = $ghUser
                "{Date}" = (Get-Date -Format "yyyy-MM-dd")
            }

            New-ReadMeFile -Tokens $readmeTokens
            Write-Log "README.md created" "SUCCESS"
        }

        # Initial commit
        git add .
        if (git status --short)
        {
            git commit -m "chore: initial commit (auto-setup)"
            Write-Log "Local initial commit completed" "SUCCESS"
        }

        # Rename branch if necessary
        $currentBranch = git branch --show-current
        if ($currentBranch -eq "master")
        {
            Write-Log "Renaming master branch to $DefaultBranch" "INFO"
            git branch -m master $DefaultBranch
            $currentBranch = $DefaultBranch
        } else
        {
            $currentBranch = $DefaultBranch
        }
    } else
    {
        Write-Log "Local repository already exists, skipping initialization" "INFO"
        $currentBranch = git branch --show-current
    }

    # Associate remote repository
    if (-not (git remote | Select-String "origin"))
    {
        git remote add origin $remoteUrl
        Write-Log "Associated remote address: $remoteUrl" "SUCCESS"
    }

    # Push code - Fixed output handling
    if ($currentBranch)
    {
        Write-Log "Pushing code to $currentBranch branch..." "INFO"

        # Use Start-Process for better output handling
        $pushResult = git push -u origin $currentBranch 2>&1
        $exitCode = $LASTEXITCODE

        # Process output line by line, distinguishing between normal output and errors
        foreach ($line in $pushResult)
        {
            if ($exitCode -ne 0 -and ($line -match "^error:|^fatal:|^ERROR:|^remote: error|^! \[rejected\]"))
            {
                Write-Host "ERROR: $line" -ForegroundColor Red
            } elseif ($line -match "^remote:")
            {
                # GitHub's remote messages, usually not errors
                Write-Host $line -ForegroundColor Gray
            } else
            {
                # Normal output
                Write-Host $line -ForegroundColor Green
            }
        }

        if ($exitCode -eq 0)
        {
            Write-Log "Code successfully pushed to $remoteUrl" "SUCCESS"
        } else
        {
            Write-Log "Push failed, please check manually: git push -u origin $currentBranch" "ERROR"
        }
    }
}

# 5. Final status check
Write-Log ">>> Project initialization process completed!" "SUCCESS"
Write-Log "Current branch: $(git branch --show-current)" "INFO"
Write-Log "Remote address: $(git remote get-url origin 2>$null)" "INFO"
