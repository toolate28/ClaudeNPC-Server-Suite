# INSTALL.ps1
# Main orchestrator for ClaudeNPC Server Suite installation
# Version: 2.1.0 SpiralSafe Edition

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Minimal", "Standard", "Full")]
    [string]$InstallProfile = "Standard",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPreflight,
    
    [Parameter(Mandatory=$false)]
    [switch]$Unattended
)

$ErrorActionPreference = "Stop"
$script:SetupRoot = Join-Path $PSScriptRoot "setup"
$script:RepoRoot = $PSScriptRoot
$script:StartTime = Get-Date

#region Module Loading

function Import-SetupModule {
    <#
    .SYNOPSIS
        Imports a setup module
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )

    $modulePath = Join-Path $script:SetupRoot "core\$ModuleName.psd1"

    if (-not (Test-Path $modulePath)) {
        throw "Module not found: $modulePath"
    }

    Import-Module $modulePath -Force -Global
}

# Import core modules
try {
    Import-SetupModule -ModuleName "Display"
    Import-SetupModule -ModuleName "Logger"
    Import-SetupModule -ModuleName "Safety"
    Import-SetupModule -ModuleName "Config"
} catch {
    Write-Host "Failed to load core modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

#endregion

#region Main Execution

try {
    # Show banner
    Show-Banner
    
    # Initialize logging
    $logPath = Join-Path $script:RepoRoot "logs"
    $logFile = Initialize-Logger -LogPath $logPath
    
    Write-StatusBox -Title "Log File" -Status $logFile -Type "Info"
    Write-Log -Message "Setup started by $env:USERNAME on $env:COMPUTERNAME" -Level "INFO"
    
    # Load or create configuration
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        $config = Import-Configuration -Path $ConfigFile
        Write-StatusBox -Title "Configuration Loaded" -Status $ConfigFile -Type "Success"
    } else {
        $config = if ($Unattended) {
            $cfg = Get-DefaultConfiguration
            $cfg.InstallProfile = $InstallProfile
            $cfg
        } else {
            Get-UserConfiguration
        }
    }
    
    # Validate configuration
    $validation = Test-Configuration -Config $config
    if (-not $validation.Valid) {
        Write-Section -Title "Configuration Validation Failed" -Icon $script:Icons.Error
        foreach ($issue in $validation.Issues) {
            Write-StatusBox -Title "Issue" -Status $issue -Type "Error"
        }
        throw "Configuration validation failed"
    }
    
    # Save configuration
    $configPath = Join-Path $config.ServerPath "setup-config.json"
    if (-not (Test-Path $config.ServerPath)) {
        New-Item -ItemType Directory -Path $config.ServerPath -Force | Out-Null
    }
    Export-Configuration -Config $config -Path $configPath
    
    # Phase execution would go here
    # For now, show what would happen
    Write-Section -Title "Installation Plan" -Icon $script:Icons.Lightning
    
    Write-Host ""
    Write-Host "  The following phases will execute:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Preflight Checks    - Validate prerequisites" -ForegroundColor White
    Write-Host "  2. Safety Checks       - Check existing installation" -ForegroundColor White
    Write-Host "  3. Java Installation   - Install/verify Java" -ForegroundColor White
    Write-Host "  4. PaperMC Setup       - Install server" -ForegroundColor White
    Write-Host "  5. Plugin Installation - Install $($config.InstallProfile) profile" -ForegroundColor White
    Write-Host "  6. Configuration       - Apply settings" -ForegroundColor White
    Write-Host ""
    
    # Display configuration summary
    Write-Section -Title "Configuration Summary" -Icon $script:Icons.Gear
    
    $summaryData = @(
        @{Setting = "Server Path"; Value = $config.ServerPath},
        @{Setting = "Server Port"; Value = $config.ServerPort.ToString()},
        @{Setting = "Max Players"; Value = $config.MaxPlayers.ToString()},
        @{Setting = "View Distance"; Value = "$($config.ViewDistance) chunks"},
        @{Setting = "Memory"; Value = "$($config.MemoryMin) - $($config.MemoryMax)"},
        @{Setting = "Install Profile"; Value = $config.InstallProfile},
        @{Setting = "Claude API"; Value = if ($config.ClaudeAPIKey) { "Configured" } else { "Not configured" }}
    )
    
    Write-ResultsTable -Data $summaryData -Headers @("Setting", "Value")
    
    if (-not $Unattended) {
        Write-Host ""
        $proceed = Read-Confirmation -Message "Proceed with installation?" -DefaultYes
        if (-not $proceed) {
            Write-Log -Message "User cancelled installation" -Level "INFO"
            Write-Host ""
            Write-Host "  Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Section -Title "Starting Installation" -Icon $script:Icons.Rocket

    # Phase execution
    $phases = @(
        @{Number = "01"; Name = "Preflight"; Function = "Invoke-PreflightChecks"; Required = $true; Params = @{Config = $config; SkipPreflight = $SkipPreflight}},
        @{Number = "02"; Name = "Java"; Function = "Invoke-JavaInstallation"; Required = $true; Params = @{Config = $config}},
        @{Number = "03"; Name = "PaperMC"; Function = "Invoke-PaperMCSetup"; Required = $true; Params = @{Config = $config}},
        @{Number = "04"; Name = "Plugins"; Function = "Invoke-PluginInstallation"; Required = $true; Params = @{Config = $config}},
        @{Number = "05"; Name = "Configure"; Function = "Invoke-FinalConfiguration"; Required = $true; Params = @{Config = $config}}
    )

    $phaseResults = @()

    foreach ($phase in $phases) {
        Write-Host ""
        Write-Section -Title "Phase $($phase.Number): $($phase.Name)" -Icon "⚙️"
        Write-Log -Message "Starting phase: $($phase.Name)" -Level "INFO"

        $phaseFile = Join-Path $script:SetupRoot "phases\$($phase.Number)-$($phase.Name).ps1"

        if (-not (Test-Path $phaseFile)) {
            Write-StatusBox -Title "Phase $($phase.Number)" -Status "Not found: $phaseFile" -Type "Error"
            Write-Log -Message "Phase file not found: $phaseFile" -Level "ERROR"
            if ($phase.Required) {
                throw "Required phase not found: $($phase.Name)"
            }
            continue
        }

        # Load and execute phase
        . $phaseFile
        $params = $phase.Params
        $result = & $phase.Function @params

        $phaseResults += @{
            Phase = $phase.Name
            Result = $result
        }

        if (-not $result.Success) {
            Write-StatusBox -Title "Phase $($phase.Number)" -Status "Failed: $($result.Message)" -Type "Error"
            Write-Log -Message "Phase failed: $($phase.Name) - $($result.Message)" -Level "ERROR"
            if ($phase.Required) {
                throw "Required phase failed: $($phase.Name)"
            }
        } else {
            Write-StatusBox -Title "Phase $($phase.Number)" -Status "Complete" -Type "Success"
            Write-Log -Message "Phase complete: $($phase.Name)" -Level "SUCCESS"
        }
    }

    # Installation complete
    Write-Host ""
    Write-Section -Title "Installation Complete" -Icon $script:Icons.Check

    Write-Host ""
    Write-Host "  Your ClaudeNPC server is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Navigate to: $($config.ServerPath)" -ForegroundColor Gray
    Write-Host "  2. Run: start.bat" -ForegroundColor Gray
    Write-Host "  3. Connect to: localhost:$($config.ServerPort)" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-StatusBox -Title "Setup Failed" -Status $_.Exception.Message -Type "Error"
    Write-LogError -ErrorRecord $_
    
    Close-Logger -Success $false
    exit 1
}

#endregion

#region Cleanup

$endTime = Get-Date
$duration = $endTime - $script:StartTime

Write-Host ""
Write-Host ("═" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "  $($script:Icons.Check) " -ForegroundColor Green -NoNewline
Write-Host "ClaudeNPC Server Installation Complete" -ForegroundColor White
Write-Host ""
Write-Host "  Duration: " -ForegroundColor Gray -NoNewline
Write-Host "$($duration.ToString('mm\:ss'))" -ForegroundColor White
Write-Host "  Log File: " -ForegroundColor Gray -NoNewline
Write-Host $logFile -ForegroundColor White
Write-Host "  Server Path: " -ForegroundColor Gray -NoNewline
Write-Host $config.ServerPath -ForegroundColor White
Write-Host ""
Write-Host ("═" * 70) -ForegroundColor Cyan
Write-Host ""

Close-Logger -Success $true

#endregion
