# Create module manifests for all core modules
$modulePath = ".\setup\core"

# Logger manifest
New-ModuleManifest -Path "$modulePath\Logger.psd1" `
    -RootModule 'Logger.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'ClaudeNPC' `
    -Description 'Logging system for ClaudeNPC setup' `
    -FunctionsToExport @('Initialize-Logger', 'Write-Log', 'Write-LogSection', 'Write-LogError', 'Get-LogSummary', 'Close-Logger', 'Remove-OldLogs')

Write-Host "Created Logger.psd1" -ForegroundColor Green

# Safety manifest
New-ModuleManifest -Path "$modulePath\Safety.psd1" `
    -RootModule 'Safety.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'ClaudeNPC' `
    -Description 'Safety and validation functions for ClaudeNPC setup' `
    -FunctionsToExport @('Test-ExistingInstallation', 'Invoke-BackupPrompt', 'Backup-ExistingServer', 'Test-DiskSpace', 'Test-NetworkConnectivity', 'Test-PortAvailable', 'Test-FileIntegrity', 'Test-PathSafety', 'Remove-DirectorySafely')

Write-Host "Created Safety.psd1" -ForegroundColor Green

# Config manifest
New-ModuleManifest -Path "$modulePath\Config.psd1" `
    -RootModule 'Config.psm1' `
    -ModuleVersion '1.0.0' `
    -Author 'ClaudeNPC' `
    -Description 'Configuration management for ClaudeNPC setup' `
    -FunctionsToExport @('Get-DefaultConfiguration', 'Import-Configuration', 'Export-Configuration', 'Get-UserConfiguration', 'Test-Configuration', 'Get-InstallProfile', 'Get-RecommendedMemory', 'Show-ProfileComparison')

Write-Host "Created Config.psd1" -ForegroundColor Green

Write-Host ""
Write-Host "All module manifests created successfully!" -ForegroundColor Cyan
