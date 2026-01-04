# Test syntax of all PowerShell files
$files = @(
    ".\setup\Setup.ps1",
    ".\setup\phases\01-Preflight.ps1",
    ".\setup\phases\02-Java.ps1",
    ".\setup\phases\03-PaperMC.ps1",
    ".\setup\phases\04-Plugins.ps1",
    ".\setup\phases\05-Configure.ps1",
    ".\scripts\Backup-Server.ps1",
    ".\scripts\Monitor-Server.ps1"
)

$allGood = $true

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        Write-Host "MISSING: $file" -ForegroundColor Red
        $allGood = $false
        continue
    }

    $errors = $null
    $content = Get-Content $file -Raw
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null

    if ($errors.Count -eq 0) {
        Write-Host "OK: $file" -ForegroundColor Green
    } else {
        Write-Host "ERRORS in $file" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        $allGood = $false
    }
}

Write-Host ""
if ($allGood) {
    Write-Host "All syntax checks passed!" -ForegroundColor Green
} else {
    Write-Host "Some files have issues" -ForegroundColor Red
}
