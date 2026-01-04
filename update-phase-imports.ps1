# Update all phase modules to use Import-Module instead of dot-sourcing

$phaseFiles = @(
    ".\setup\phases\01-Preflight.ps1",
    ".\setup\phases\02-Java.ps1",
    ".\setup\phases\03-PaperMC.ps1",
    ".\setup\phases\04-Plugins.ps1",
    ".\setup\phases\05-Configure.ps1"
)

foreach ($file in $phaseFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "SKIP: $file (not found)" -ForegroundColor Yellow
        continue
    }

    $content = Get-Content $file -Raw

    # Replace dot-sourcing with Import-Module
    $content = $content -replace '\. "\$scriptRoot\\core\\Display\.ps1"', 'Import-Module "$scriptRoot\core\Display.psd1" -Force -Global'
    $content = $content -replace '\. "\$scriptRoot\\core\\Logger\.ps1"', 'Import-Module "$scriptRoot\core\Logger.psd1" -Force -Global'
    $content = $content -replace '\. "\$scriptRoot\\core\\Safety\.ps1"', 'Import-Module "$scriptRoot\core\Safety.psd1" -Force -Global'
    $content = $content -replace '\. "\$scriptRoot\\core\\Config\.ps1"', 'Import-Module "$scriptRoot\core\Config.psd1" -Force -Global'

    # Save with UTF-8 BOM
    $utf8BOM = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText((Resolve-Path $file), $content, $utf8BOM)

    Write-Host "UPDATED: $file" -ForegroundColor Green
}

Write-Host ""
Write-Host "All phase modules updated to use Import-Module!" -ForegroundColor Cyan
