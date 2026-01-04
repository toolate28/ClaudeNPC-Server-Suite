# Fix Unicode encoding issues in PowerShell files
# This script re-saves files with UTF-8 BOM encoding

$files = @(
    # Core modules
    ".\setup\core\Display.ps1",
    ".\setup\core\Logger.ps1",
    ".\setup\core\Safety.ps1",
    ".\setup\core\Config.ps1",

    # Phase modules
    ".\setup\phases\01-Preflight.ps1",
    ".\setup\phases\02-Java.ps1",
    ".\setup\phases\03-PaperMC.ps1",
    ".\setup\phases\04-Plugins.ps1",
    ".\setup\phases\05-Configure.ps1",

    # Utility scripts
    ".\scripts\Backup-Server.ps1",
    ".\scripts\Monitor-Server.ps1",

    # Test scripts
    ".\test-core-modules.ps1",

    # Main setup
    ".\setup\Setup.ps1"
)

Write-Host "Fixing Unicode encoding for PowerShell files..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        Write-Host "SKIP: $file (not found)" -ForegroundColor Yellow
        continue
    }

    try {
        # Read file content as UTF-8
        $content = Get-Content $file -Raw -Encoding UTF8

        # Save with UTF-8 BOM encoding
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText((Resolve-Path $file), $content, $utf8BOM)

        Write-Host "FIXED: $file" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $file - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Encoding fix complete!" -ForegroundColor Green
Write-Host "Re-run test-syntax.ps1 to verify" -ForegroundColor Cyan
