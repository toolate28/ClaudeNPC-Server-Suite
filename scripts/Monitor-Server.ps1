#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerPath,

    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 60
)

$moduleBase = Split-Path $PSScriptRoot -Parent
. "$moduleBase\setup\core\Display.ps1"
. "$moduleBase\setup\core\Safety.ps1"

Show-Banner

Write-Host ""
Write-Host "  Monitoring server every $IntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

while ($true) {
    Clear-Host
    Show-Banner
    Write-Section -Title "Server Status - $(Get-Date -Format 'HH:mm:ss')" -Icon "📊"

    $status = @()

    # Check if server is running
    $process = Get-Process java -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "*$ServerPath*"
    }

    if ($process) {
        $cpu = [math]::Round($process.CPU, 2)
        $memMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
        $status += @{
            Check = "Server Process"
            Status = "✓ Running"
            Details = "PID: $($process.Id), CPU: ${cpu}s, RAM: ${memMB}MB"
        }
    } else {
        $status += @{
            Check = "Server Process"
            Status = "✗ Not Running"
            Details = "Server offline"
        }
    }

    # Disk space
    $disk = Test-DiskSpace -Path $ServerPath -RequiredGB 5
    $status += @{
        Check = "Disk Space"
        Status = if ($disk.Success) { "✓ $($disk.FreeSpaceGB) GB" } else { "⚠ Low" }
        Details = "Available on $($disk.Drive):"
    }

    # Port
    $port = Test-PortAvailable -Port 25565
    $status += @{
        Check = "Port 25565"
        Status = if (-not $port) { "✓ In Use" } else { "⚠ Available" }
        Details = if (-not $port) { "Server listening" } else { "Port free" }
    }

    # Log file size
    $logDir = Join-Path $ServerPath "logs"
    if (Test-Path $logDir) {
        $logSize = (Get-ChildItem $logDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        $status += @{
            Check = "Log Files"
            Status = "ℹ $([math]::Round($logSize, 1)) MB"
            Details = "Total log size"
        }
    }

    # Backup age
    $backupDir = Join-Path $ServerPath "backups"
    if (Test-Path $backupDir) {
        $latestBackup = Get-ChildItem $backupDir -Filter "*.zip" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestBackup) {
            $age = (Get-Date) - $latestBackup.LastWriteTime
            $ageStr = if ($age.TotalHours -lt 1) {
                "$([math]::Round($age.TotalMinutes, 0)) minutes ago"
            } elseif ($age.TotalDays -lt 1) {
                "$([math]::Round($age.TotalHours, 1)) hours ago"
            } else {
                "$([math]::Round($age.TotalDays, 1)) days ago"
            }

            $status += @{
                Check = "Last Backup"
                Status = if ($age.TotalDays -lt 1) { "✓ $ageStr" } else { "⚠ $ageStr" }
                Details = $latestBackup.Name
            }
        }
    }

    Write-ResultsTable -Data $status -Headers @("Check", "Status", "Details")

    Start-Sleep -Seconds $IntervalSeconds
}
