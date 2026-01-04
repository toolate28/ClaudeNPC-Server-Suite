# Create Intelligent Symlinks for Easy Navigation
# Run as Administrator for symlink creation on Windows

param(
    [switch]$Remove
)

# Define symlink mappings
$symlinks = @{
    "QUICK_START" = "IMPROVEMENTS_COMPLETE.md"
    "DOC_INDEX" = "DOCUMENT_REGISTER.md"
    "GUIDE" = "CLAUDE_INSTANCE_GUIDE.md"
    "LATEST_FEATURES" = "IMPROVEMENTS_COMPLETE.md"
    "INSTALL" = "setup\Setup.ps1"
    "00-README" = "START_HERE.md"
}

# Parent directory symlinks
$parentSymlinks = @{
    "claudenpc-installer" = "claudenpc-server-suite"
    "server-suite" = "claudenpc-server-suite"
}

if ($Remove) {
    Write-Host "Removing symlinks..."
    foreach ($link in $symlinks.Keys) {
        if (Test-Path $link) {
            Remove-Item $link -Force
            Write-Host "[REMOVED] $link"
        }
    }
    Write-Host "Symlinks removed."
    exit
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator." -ForegroundColor Yellow
    Write-Host "Symlinks may not be created. Use hardlinks instead? (y/n)"
    $response = Read-Host
    $useHardLink = ($response -eq 'y')
} else {
    $useHardLink = $false
}

Write-Host "Creating navigation symlinks..."
Write-Host ""

# Create symlinks in current directory
foreach ($link in $symlinks.GetEnumerator()) {
    $linkPath = $link.Key
    $targetPath = $link.Value

    if (-not (Test-Path $targetPath)) {
        Write-Host "[SKIP] $linkPath -> $targetPath (target not found)" -ForegroundColor Yellow
        continue
    }

    # Remove existing link if present
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }

    try {
        if ($useHardLink -and ((Get-Item $targetPath) -is [System.IO.FileInfo])) {
            # Create hardlink for files (doesn't require admin)
            New-Item -ItemType HardLink -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
            Write-Host "[HARDLINK] $linkPath -> $targetPath" -ForegroundColor Green
        } else {
            # Create symbolic link (requires admin on Windows)
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
            Write-Host "[SYMLINK] $linkPath -> $targetPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[ERROR] $linkPath -> $targetPath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create parent directory symlinks
Write-Host ""
Write-Host "Creating parent directory symlinks..."
$parentDir = Split-Path $PSScriptRoot -Parent

foreach ($link in $parentSymlinks.GetEnumerator()) {
    $linkPath = Join-Path $parentDir $link.Key
    $targetPath = $PSScriptRoot

    if (Test-Path $linkPath) {
        Write-Host "[EXISTS] $($link.Key) already exists" -ForegroundColor Yellow
        continue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
        Write-Host "[SYMLINK] $($link.Key) -> claudenpc-server-suite" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] $($link.Key) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Symlink creation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Quick Navigation:"
Write-Host "  QUICK_START       -> Latest features (v2.0.0)"
Write-Host "  DOC_INDEX         -> Complete document register"
Write-Host "  GUIDE             -> Claude instance guide"
Write-Host "  00-README         -> Primary entry point"
Write-Host "  INSTALL           -> Run installation"
