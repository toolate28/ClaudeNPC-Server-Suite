# 01-Preflight.ps1
# Prerequisites checking phase
# Version: 1.0.0

$scriptRoot = Split-Path $PSScriptRoot -Parent
Import-Module "$scriptRoot\core\Display.psd1" -Force -Global
Import-Module "$scriptRoot\core\Logger.psd1" -Force -Global
Import-Module "$scriptRoot\core\Safety.psd1" -Force -Global

function Invoke-PreflightChecks {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,

        [Parameter(Mandatory=$false)]
        [switch]$SkipPreflight
    )

    if ($SkipPreflight) {
        Write-StatusBox -Title "Preflight" -Status "Skipped" -Type "Warning"
        return @{Success = $true; Message = "Skipped"; Data = @{}}
    }

    Write-Section -Title "Preflight Checks" -Icon "✓"
    Write-Log -Message "Running preflight checks" -Level "INFO"

    $checks = @()

    try {
        # Check 1: PowerShell Version
        $psVersion = $PSVersionTable.PSVersion
        $psOK = $psVersion.Major -ge 5
        $checks += @{
            Check = "PowerShell"
            Status = if ($psOK) { "✓ Pass" } else { "✗ Fail" }
            Details = "Version $($psVersion.Major).$($psVersion.Minor)"
        }

        # Check 2: Administrator Rights
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $checks += @{
            Check = "Admin Rights"
            Status = if ($isAdmin) { "✓ Pass" } else { "✗ Fail" }
            Details = if ($isAdmin) { "Running as Administrator" } else { "Not Administrator" }
        }

        # Check 3: Disk Space
        $disk = Test-DiskSpace -Path $Config.ServerPath -RequiredGB 10
        $checks += @{
            Check = "Disk Space"
            Status = if ($disk.Success) { "✓ Pass" } else { "⚠ Warning" }
            Details = "$($disk.FreeSpaceGB) GB free on $($disk.Drive):"
        }

        # Check 4: Network Connectivity
        $network = Test-NetworkConnectivity
        $checks += @{
            Check = "Network"
            Status = if ($network.AllConnected) { "✓ Pass" } else { "⚠ Warning" }
            Details = "$($network.Results.Count) services tested"
        }

        # Check 5: PaperMC JAR
        $paperJar = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "paper-*.jar" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        $checks += @{
            Check = "PaperMC JAR"
            Status = if ($paperJar) { "✓ Pass" } else { "⚠ Warning" }
            Details = if ($paperJar) { $paperJar.Name } else { "Not found in Downloads" }
        }

        # Check 6: Java
        $javaVersion = $null
        try {
            $javaVersion = & java -version 2>&1 | Select-Object -First 1
        } catch {}
        $checks += @{
            Check = "Java"
            Status = if ($javaVersion) { "✓ Pass" } else { "ℹ Info" }
            Details = if ($javaVersion) { $javaVersion } else { "Will be installed in Phase 2" }
        }

        # Display results
        Write-ResultsTable -Data $checks -Headers @("Check", "Status", "Details")

        # Evaluate
        $failed = $checks | Where-Object { $_.Status -like "*✗*" }
        $warnings = $checks | Where-Object { $_.Status -like "*⚠*" }

        if ($failed.Count -gt 0) {
            Write-StatusBox -Title "Preflight" -Status "$($failed.Count) critical failures" -Type "Error"
            Write-Log -Message "Preflight failed: $($failed.Count) critical failures" -Level "ERROR"
            return @{
                Success = $false
                Message = "Critical preflight checks failed"
                Data = @{Checks = $checks}
            }
        }

        if ($warnings.Count -gt 0) {
            Write-StatusBox -Title "Preflight" -Status "$($warnings.Count) warnings" -Type "Warning"
            $proceed = Read-Confirmation -Message "Continue with warnings?" -DefaultYes:$false
            if (-not $proceed) {
                return @{Success = $false; Message = "User cancelled"; Data = @{}}
            }
        }

        Write-StatusBox -Title "Preflight Checks" -Status "Complete" -Type "Success"
        Write-Log -Message "Preflight checks passed" -Level "SUCCESS"

        return @{
            Success = $true
            Message = "All checks passed"
            Data = @{Checks = $checks}
        }

    } catch {
        Write-StatusBox -Title "Preflight Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        return @{Success = $false; Message = $_.Exception.Message; Data = @{}}
    }
}
