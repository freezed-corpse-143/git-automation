Write-Host "Git Auto Watch - Minimal Version" -ForegroundColor Green
Write-Host "Watching: $(Get-Location)" -ForegroundColor Cyan

# Check Git
if (-not (Test-Path ".git"))
{
    Write-Host "Error: Not a Git repository" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue))
{
    Write-Host "Error: Git not found" -ForegroundColor Red
    exit 1
}

$branch = git rev-parse --abbrev-ref HEAD
Write-Host "Branch: $branch" -ForegroundColor Cyan

$remote = git remote get-url origin 2>$null
if ($remote)
{
    Write-Host "Remote: $remote" -ForegroundColor Cyan
} else
{
    Write-Host "Warning: No remote" -ForegroundColor Yellow
}

Write-Host "Script ready - Press Ctrl+C to stop" -ForegroundColor Yellow

# Simple watch loop with remote sync - fixed version V3
$running = $true
$branch = git branch --show-current

Write-Host "Git Auto Watch - Minimal Version" -ForegroundColor Cyan
Write-Host "Watching: $(Get-Location)" -ForegroundColor Yellow
Write-Host "Branch: $branch" -ForegroundColor Yellow
Write-Host "Remote: $(git remote get-url origin)" -ForegroundColor Yellow
Write-Host "Script ready - Press Ctrl+C to stop" -ForegroundColor Green
Write-Host ""

while ($running)
{
    # Get remote update information
    git fetch origin $branch --quiet 2>$null

    # Check local and remote differences
    $local_commit = git rev-parse $branch
    $remote_commit = git rev-parse origin/$branch 2>$null

    # Check for uncommitted local changes
    $status = git status --porcelain

    # Only pull when remote actually has updates
    if ($remote_commit -and $local_commit -ne $remote_commit)
    {
        Write-Host "Remote is ahead, pulling changes..." -ForegroundColor Cyan

        # Stash if there are local changes
        $hasLocalChanges = -not [string]::IsNullOrWhiteSpace($status)
        if ($hasLocalChanges)
        {
            Write-Host "Local changes detected, stashing..." -ForegroundColor Yellow
            git stash push -m "Auto-stash before pull $(Get-Date)"
        }

        # Execute pull
        git pull origin $branch --quiet

        # Try to apply stash if exists
        $stashList = git stash list
        if ($stashList -match "Auto-stash before pull")
        {
            Write-Host "Applying stashed changes..." -ForegroundColor Yellow

            git stash apply --quiet 2>$null
            if ($LASTEXITCODE -eq 0)
            {
                git stash drop --quiet 2>$null
            }

            # Recheck status, as stash pop may create new files or conflicts
            $status = git status --porcelain
        }
    }

    # Check for local changes and commit - ensure not empty
    if (-not [string]::IsNullOrWhiteSpace($status))
    {
        Write-Host "Changes detected: $status" -ForegroundColor Yellow
        git add .
        git commit -m "Auto: $(Get-Date)"

        # Check remote status again to prevent new commits during local commit process
        git fetch origin $branch --quiet 2>$null
        $local_commit = git rev-parse $branch
        $remote_commit = git rev-parse origin/$branch 2>$null

        if ($remote_commit -and $local_commit -ne $remote_commit)
        {
            Write-Host "Remote changed during commit, pulling and rebasing..." -ForegroundColor Cyan
            git pull --rebase origin $branch --quiet
        }

        # Push commits
        git push origin $branch
        Write-Host "Changes committed and pushed at $(Get-Date)" -ForegroundColor Green

        # Key fix: reset status variable to empty
        $status = $null

        # Additional fix: wait a bit to avoid immediate re-detection
        Start-Sleep -Seconds 2
    }

    Start-Sleep -Seconds 5
}

Write-Host "Script stopped" -ForegroundColor Green
