#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerPath,

    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "$ServerPath\backups",

    [Parameter(Mandatory=$false)]
    [int]$KeepLast = 7
)

$moduleBase = Split-Path $PSScriptRoot -Parent
. "$moduleBase\setup\core\Display.ps1"
. "$moduleBase\setup\core\Logger.ps1"
. "$moduleBase\setup\core\Safety.ps1"

Show-Banner
$logFile = Initialize-Logger -LogPath "$ServerPath\logs"

Write-Section -Title "Server Backup" -Icon "📦"

try {
    # Create backup
    $backup = Backup-ExistingServer -ServerPath $ServerPath -BackupPath $BackupPath
    Write-StatusBox -Title "Backup Complete" -Status $backup -Type "Success"
    Write-Log -Message "Backup created: $backup" -Level "SUCCESS"

    # Cleanup old backups
    Write-StatusBox -Title "Cleaning old backups" -Status "Processing" -Type "Progress"

    $oldBackups = Get-ChildItem $BackupPath -Filter "*.zip" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $KeepLast

    foreach ($old in $oldBackups) {
        Remove-Item $old.FullName -Force
        Write-StatusBox -Title "Removed" -Status $old.Name -Type "Info"
        Write-Log -Message "Removed old backup: $($old.Name)" -Level "INFO"
    }

    Write-StatusBox -Title "Cleanup" -Status "Complete" -Type "Success"

    # Summary
    $backupCount = (Get-ChildItem $BackupPath -Filter "*.zip").Count
    Write-Host ""
    Write-Host "  Total backups: $backupCount" -ForegroundColor Cyan
    Write-Host "  Latest: $backup" -ForegroundColor Gray
    Write-Host ""

    Close-Logger -Success $true

} catch {
    Write-StatusBox -Title "Backup Failed" -Status $_.Exception.Message -Type "Error"
    Write-LogError -ErrorRecord $_
    Close-Logger -Success $false
    exit 1
}
