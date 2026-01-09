#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerPath,

    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 60,

    [Parameter(Mandatory=$false)]
    [string]$ApiBaseUrl = "http://localhost:8080",

    [Parameter(Mandatory=$false)]
    [string]$ApiAuthToken = ""
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

    # === API Signals (Dynamic) ================================================
    $headers = @{}
    if ($ApiAuthToken) { $headers["Authorization"] = "Bearer $ApiAuthToken" }

    $apiHealthy = $false

    # 1) Primary health signal
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $resp = Invoke-WebRequest -Uri "$ApiBaseUrl/api/health" -Headers $headers `
                                  -UseBasicParsing -TimeoutSec 5
        $sw.Stop()

        $apiHealthy = ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300)

        $status += @{
            Check   = "Ops API Health"
            Status  = if ($apiHealthy) { "✓ Healthy" } else { "⚠ Degraded" }
            Details = "HTTP $($resp.StatusCode) in $([math]::Round($sw.ElapsedMilliseconds)) ms"
        }
    } catch {
        $status += @{
            Check   = "Ops API Health"
            Status  = "✗ Unreachable"
            Details = $_.Exception.Message
        }
    }

    # 2) Dynamic sub-checks – only when core health is OK
    if ($apiHealthy) {
        $apiChecks = @(
            @{
                Name   = "Wave Analyze"
                Method = "POST"
                Path   = "/api/wave/analyze"
                Body   = @{ text = "dashboard_probe"; mode = "ping" }
            },
            @{
                Name   = "BUMP Marker"
                Method = "POST"
                Path   = "/api/bump/create"
                Body   = @{ type = "dashboard_probe"; source = "monitor" }
            },
            @{
                Name   = "AWI Grant"
                Method = "POST"
                Path   = "/api/awi/request"
                Body   = @{ subject = "dashboard"; intent = "status-check" }
            },
            @{
                Name   = "ATOM Session"
                Method = "POST"
                Path   = "/api/atom/create"
                Body   = @{ id = "dashboard"; molecule = "status"; compound = "probe" }
            },
            @{
                Name   = "Context Storage"
                Method = "POST"
                Path   = "/api/context/store"
                Body   = @{ id = "dashboard-context"; domain = "ops-monitor" }
            }
        )

        foreach ($check in $apiChecks) {
            try {
                $sw2  = [System.Diagnostics.Stopwatch]::StartNew()
                $body = $null
                if ($check.Body) {
                    $body = $check.Body | ConvertTo-Json -Depth 5
                }

                $resp2 = Invoke-WebRequest `
                    -Uri    ($ApiBaseUrl + $check.Path) `
                    -Headers $headers `
                    -Method  $check.Method `
                    -ContentType "application/json" `
                    -Body   $body `
                    -UseBasicParsing `
                    -TimeoutSec 5

                $sw2.Stop()

                $status += @{
                    Check   = $check.Name
                    Status  = "✓ OK"
                    Details = "HTTP $($resp2.StatusCode) in $([math]::Round($sw2.ElapsedMilliseconds)) ms"
                }
            } catch {
                $status += @{
                    Check   = $check.Name
                    Status  = "⚠ Skipped/Failed"
                    Details = $_.Exception.Message
                }
            }
        }
    } else {
        # When core health isn’t OK, just record that deeper probes are inappropriate now
        $status += @{
            Check   = "API Deep Probes"
            Status  = "⚠ Skipped"
            Details = "Health not OK; deeper checks suppressed this cycle"
        }
    }
    # ========================================================================

    Write-ResultsTable -Data $status -Headers @("Check", "Status", "Details")

    Start-Sleep -Seconds $IntervalSeconds
}
