# Config.ps1
# Configuration management for ClaudeNPC Server Suite
# Version: 1.0.0

#region Configuration Schema

$script:DefaultConfig = @{
    ServerPath = "C:\MinecraftServer"
    ServerPort = 25565
    MaxPlayers = 20
    ViewDistance = 10
    SimulationDistance = 10
    Gamemode = "survival"
    Difficulty = "normal"
    OnlineMode = $true
    PVP = $true
    MemoryMin = "4G"
    MemoryMax = "8G"
    InstallProfile = "Standard"
    ClaudeAPIKey = ""
    AutoBackup = $true
    AcceptEULA = $false
}

#endregion

#region Configuration Loading

function Get-DefaultConfiguration {
    <#
    .SYNOPSIS
        Returns the default configuration
    #>
    return $script:DefaultConfig.Clone()
}

function Import-Configuration {
    <#
    .SYNOPSIS
        Imports configuration from JSON file
    .PARAMETER Path
        Path to configuration file
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Log -Message "Configuration file not found: $Path" -Level "WARNING"
        return Get-DefaultConfiguration
    }
    
    try {
        $json = Get-Content $Path -Raw | ConvertFrom-Json
        $config = Get-DefaultConfiguration
        
        # Merge loaded config with defaults
        foreach ($key in $config.Keys) {
            if ($json.PSObject.Properties.Name -contains $key) {
                $config[$key] = $json.$key
            }
        }
        
        Write-Log -Message "Configuration loaded from: $Path" -Level "SUCCESS"
        return $config
    } catch {
        Write-Log -Message "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
        return Get-DefaultConfiguration
    }
}

function Export-Configuration {
    <#
    .SYNOPSIS
        Exports configuration to JSON file
    .PARAMETER Config
        Configuration hashtable to export
    .PARAMETER Path
        Destination path for JSON file
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        Write-Log -Message "Configuration saved to: $Path" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log -Message "Failed to save configuration: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

#endregion

#region Interactive Configuration

function Get-UserConfiguration {
    <#
    .SYNOPSIS
        Interactively gathers configuration from user
    .PARAMETER Unattended
        Use default values without prompting
    #>
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Unattended
    )
    
    $config = Get-DefaultConfiguration
    
    if ($Unattended) {
        Write-StatusBox -Title "Unattended Mode" -Status "Using defaults" -Type "Info"
        return $config
    }
    
    Write-Section -Title "Server Configuration" -Icon $script:Icons.Gear
    Write-Host ""
    Write-Host "  Press Enter to accept defaults [shown in brackets]" -ForegroundColor Gray
    Write-Host ""
    
    # Server Path
    $input = Read-Host "  Server Path [$($config.ServerPath)]"
    if ($input) { $config.ServerPath = $input }
    
    # Server Port
    $input = Read-Host "  Server Port [$($config.ServerPort)]"
    if ($input -match '^\d+$') { $config.ServerPort = [int]$input }
    
    # Max Players
    $input = Read-Host "  Max Players [$($config.MaxPlayers)]"
    if ($input -match '^\d+$') { $config.MaxPlayers = [int]$input }
    
    # View Distance
    $input = Read-Host "  View Distance (chunks) [$($config.ViewDistance)]"
    if ($input -match '^\d+$') { $config.ViewDistance = [int]$input }
    
    # Gamemode
    $input = Read-Host "  Gamemode (survival/creative/adventure) [$($config.Gamemode)]"
    if ($input -and $input -in @("survival", "creative", "adventure", "spectator")) {
        $config.Gamemode = $input.ToLower()
    }
    
    # Difficulty
    $input = Read-Host "  Difficulty (peaceful/easy/normal/hard) [$($config.Difficulty)]"
    if ($input -and $input -in @("peaceful", "easy", "normal", "hard")) {
        $config.Difficulty = $input.ToLower()
    }
    
    # Memory
    $input = Read-Host "  Min Memory (e.g., 2G, 4G) [$($config.MemoryMin)]"
    if ($input -match '^\d+[GM]$') { $config.MemoryMin = $input }
    
    $input = Read-Host "  Max Memory (e.g., 4G, 8G) [$($config.MemoryMax)]"
    if ($input -match '^\d+[GM]$') { $config.MemoryMax = $input }
    
    # Install Profile
    $input = Read-Host "  Install Profile (Minimal/Standard/Full) [$($config.InstallProfile)]"
    if ($input -and $input -in @("Minimal", "Standard", "Full")) {
        $config.InstallProfile = $input
    }
    
    Write-Host ""
    Write-Host "  $($script:Icons.Robot) ClaudeNPC Configuration" -ForegroundColor Cyan
    Write-Host ""
    
    # Claude API Key
    $input = Read-Host "  Anthropic API Key (optional, configure later if skipped)"
    if ($input) { $config.ClaudeAPIKey = $input }
    
    return $config
}

#endregion

#region Profile Management

function Get-InstallProfile {
    <#
    .SYNOPSIS
        Gets plugin list for installation profile
    .PARAMETER ProfileName
        Name of profile (Minimal, Standard, Full)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Minimal", "Standard", "Full")]
        [string]$ProfileName
    )
    
    $profiles = @{
        Minimal = @{
            Name = "Minimal"
            Description = "ClaudeNPC + Citizens only"
            Plugins = @("Citizens")
        }
        Standard = @{
            Name = "Standard"
            Description = "Core plugins + security + ClaudeNPC"
            Plugins = @("Citizens", "Vault", "LuckPerms", "CoreProtect", "PlaceholderAPI")
        }
        Full = @{
            Name = "Full"
            Description = "Complete server suite with all features"
            Plugins = @(
                "Citizens", "Vault", "LuckPerms", "CoreProtect", "PlaceholderAPI",
                "WorldEdit", "WorldGuard", "EssentialsX", "Spark", "GriefPrevention"
            )
        }
    }
    
    return $profiles[$ProfileName]
}

function Show-ProfileComparison {
    <#
    .SYNOPSIS
        Displays comparison of installation profiles
    #>
    
    Write-Host ""
    Write-Host "  Installation Profiles:" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = @("Minimal", "Standard", "Full")
    
    foreach ($profile in $profiles) {
        $info = Get-InstallProfile -ProfileName $profile
        $marker = if ($profile -eq "Standard") { "* (Recommended)" } else { "" }
        
        Write-Host "  [$profile]$marker" -ForegroundColor White
        Write-Host "    $($info.Description)" -ForegroundColor Gray
        Write-Host "    Plugins: $($info.Plugins.Count)" -ForegroundColor Gray
        Write-Host ""
    }
}

#endregion

#region Configuration Validation

function Test-Configuration {
    <#
    .SYNOPSIS
        Validates configuration settings
    .PARAMETER Config
        Configuration to validate
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    $issues = @()
    
    # Validate server port
    if ($Config.ServerPort -lt 1024 -or $Config.ServerPort -gt 65535) {
        $issues += "Server port must be between 1024 and 65535"
    }
    
    # Validate max players
    if ($Config.MaxPlayers -lt 1 -or $Config.MaxPlayers -gt 1000) {
        $issues += "Max players must be between 1 and 1000"
    }
    
    # Validate view distance
    if ($Config.ViewDistance -lt 2 -or $Config.ViewDistance -gt 32) {
        $issues += "View distance must be between 2 and 32"
    }
    
    # Validate memory format
    if ($Config.MemoryMin -notmatch '^\d+[GM]$') {
        $issues += "Invalid memory format for MemoryMin (use format like '4G' or '512M')"
    }
    if ($Config.MemoryMax -notmatch '^\d+[GM]$') {
        $issues += "Invalid memory format for MemoryMax (use format like '8G' or '1024M')"
    }
    
    # Validate memory relationship
    $minMem = [int]($Config.MemoryMin -replace '[GM]', '')
    $maxMem = [int]($Config.MemoryMax -replace '[GM]', '')
    $minUnit = if ($Config.MemoryMin -match 'G') { 'G' } else { 'M' }
    $maxUnit = if ($Config.MemoryMax -match 'G') { 'G' } else { 'M' }
    
    # Convert to MB for comparison
    $minMB = if ($minUnit -eq 'G') { $minMem * 1024 } else { $minMem }
    $maxMB = if ($maxUnit -eq 'G') { $maxMem * 1024 } else { $maxMem }
    
    if ($minMB -gt $maxMB) {
        $issues += "Min memory cannot be greater than max memory"
    }
    
    # Validate server path
    $pathCheck = Test-PathSafety -Path $Config.ServerPath
    if (-not $pathCheck.Safe) {
        $issues += $pathCheck.Issues
    }
    
    return @{
        Valid = $issues.Count -eq 0
        Issues = $issues
    }
}

#endregion

#region Memory Calculation

function Get-RecommendedMemory {
    <#
    .SYNOPSIS
        Returns recommended memory allocation based on system RAM
    #>
    
    try {
        $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        
        $recommendation = if ($totalRAM -le 4) {
            @{Min = "2G"; Max = "3G"; Profile = "Light"}
        } elseif ($totalRAM -le 8) {
            @{Min = "2G"; Max = "4G"; Profile = "Medium"}
        } elseif ($totalRAM -le 16) {
            @{Min = "4G"; Max = "8G"; Profile = "Standard"}
        } else {
            @{Min = "8G"; Max = "12G"; Profile = "High"}
        }
        
        return @{
            TotalRAM = [math]::Round($totalRAM, 1)
            Recommendation = $recommendation
        }
    } catch {
        return @{
            TotalRAM = 0
            Recommendation = @{Min = "2G"; Max = "4G"; Profile = "Unknown"}
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-DefaultConfiguration',
    'Import-Configuration',
    'Export-Configuration',
    'Get-UserConfiguration',
    'Get-InstallProfile',
    'Show-ProfileComparison',
    'Test-Configuration',
    'Get-RecommendedMemory'
)
