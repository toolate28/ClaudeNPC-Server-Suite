# ENHANCED PowerShell Profile for ClaudeNPC Development
# Copy this to: $PROFILE (C:\Users\iamto\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1)
# Version: 2.0.0 - Enhanced Edition
# Last Updated: 2025-12-09

#region Error Handling & Initialization
$ErrorActionPreference = "SilentlyContinue"  # Suppress module loading errors
$script:ProfileLoadTime = Get-Date
#endregion

#region Oh My Posh Configuration
# Initialize Oh My Posh with custom theme
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        # Use a clean, informative theme
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression
        $script:OhMyPoshLoaded = $true
    }
    catch {
        Write-Host "  [!] Oh My Posh failed to load" -ForegroundColor Yellow
        $script:OhMyPoshLoaded = $false
    }
} else {
    $script:OhMyPoshLoaded = $false
}
#endregion

#region PSReadLine Configuration (Enhanced Command Line Editing)
if (Get-Module -ListAvailable -Name PSReadLine) {
    try {
        Import-Module PSReadLine -ErrorAction Stop

        # History search with arrow keys
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

        # Tab completion menu
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

        # Ctrl+D to exit (like bash)
        Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

        # Predictive IntelliSense (PowerShell 7.1+)
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Set-PSReadLineOption -PredictionSource History
            Set-PSReadLineOption -PredictionViewStyle ListView
        }

        # Colors for syntax highlighting
        Set-PSReadLineOption -Colors @{
            Command = 'Cyan'
            Parameter = 'DarkCyan'
            String = 'Yellow'
            Comment = 'DarkGray'
            Variable = 'Green'
            Operator = 'Magenta'
        }

        # Better history handling
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -MaximumHistoryCount 10000
        Set-PSReadLineOption -HistorySavePath "$HOME\.powershell_history"

        $script:PSReadLineLoaded = $true
    }
    catch {
        $script:PSReadLineLoaded = $false
    }
}
#endregion

#region Environment Setup
# Set UTF-8 encoding for better Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Import useful modules (if available)
$modules = @{
    'posh-git' = 'Git integration'
    'Terminal-Icons' = 'Pretty file icons'
}

$script:LoadedModules = @()
foreach ($module in $modules.GetEnumerator()) {
    if (Get-Module -ListAvailable -Name $module.Key) {
        try {
            Import-Module $module.Key -ErrorAction Stop
            $script:LoadedModules += $module.Key
        }
        catch {
            # Module failed to load, continue silently
        }
    }
}
#endregion

#region Enhanced Aliases
# Unix-like commands
Set-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name la -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name grep -Value Select-String -ErrorAction SilentlyContinue
Set-Alias -Name touch -Value New-Item -ErrorAction SilentlyContinue
Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue
Set-Alias -Name clear -Value Clear-Host -ErrorAction SilentlyContinue
Set-Alias -Name cls -Value Clear-Host -ErrorAction SilentlyContinue

# Profile management
Set-Alias -Name ep -Value Edit-Profile -ErrorAction SilentlyContinue
Set-Alias -Name rp -Value Reload-Profile -ErrorAction SilentlyContinue

# ClaudeNPC shortcuts
Set-Alias -Name cnpc -Value Go-ClaudeNPC -ErrorAction SilentlyContinue
Set-Alias -Name mcstart -Value Start-ClaudeNPCServer -ErrorAction SilentlyContinue
Set-Alias -Name mcstatus -Value Get-ClaudeNPCStatus -ErrorAction SilentlyContinue
Set-Alias -Name cnpcsetup -Value Start-ClaudeNPCSetup -ErrorAction SilentlyContinue
#endregion

#region Navigation Functions
function Go-Kenl {
    Set-Location "C:\Users\iamto\.kenl"
}
Set-Alias -Name kenl -Value Go-Kenl

function Go-ClaudeLanding {
    Set-Location "C:\Users\iamto\.kenl\claude-landing"
}
Set-Alias -Name cl -Value Go-ClaudeLanding

function Go-ClaudeNPC {
    Set-Location "C:\Users\iamto\.kenl\claude-landing\claudenpc-server-suite"
}

function Go-MinecraftServer {
    Set-Location "C:\MinecraftServer"
}
Set-Alias -Name mcdir -Value Go-MinecraftServer

# Quick back navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
#endregion

#region Enhanced Directory Listing
function ll {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Force | Format-Table -AutoSize
}

function la {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Force -Hidden | Format-Table -AutoSize
}

function lt {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 20
}
#endregion

#region Git Shortcuts
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs { git status }
    function ga { git add @args }
    function gaa { git add --all }
    function gc { param($msg) git commit -m $msg }
    function gp { git push }
    function gl { git log --oneline --graph --decorate --all -n 10 }
    function gd { git diff @args }
    function gco { git checkout @args }
    function gb { git branch @args }
    function gpull { git pull }

    $script:GitAvailable = $true
} else {
    $script:GitAvailable = $false
}
#endregion

#region System Information Functions
function sysinfo {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                     System Information                               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Computer:        $env:COMPUTERNAME" -ForegroundColor Gray
    Write-Host "  User:            $env:USERNAME" -ForegroundColor Gray
    Write-Host "  PowerShell:      $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host "  OS:              $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
    Write-Host "  .NET Version:    $($PSVersionTable.PSEdition) $($PSVersionTable.CLRVersion)" -ForegroundColor Gray

    # Disk info
    $disk = Get-PSDrive C | Select-Object Used, Free
    $usedGB = [math]::Round($disk.Used / 1GB, 2)
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    $totalGB = $usedGB + $freeGB
    $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 1)

    Write-Host "  C: Drive:        $usedGB GB used / $totalGB GB total ($usedPercent%)" -ForegroundColor Gray
    Write-Host ""
}

function Get-SystemHealth {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                        System Health Check                           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Memory
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

    Write-Host "  Memory:   $usedRAM GB / $totalRAM GB ($ramPercent% used)" -ForegroundColor $(if ($ramPercent -gt 85) { "Red" } elseif ($ramPercent -gt 70) { "Yellow" } else { "Green" })

    # CPU
    $cpu = Get-CimInstance Win32_Processor
    Write-Host "  CPU:      $($cpu.Name)" -ForegroundColor Gray
    Write-Host "  Cores:    $($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads" -ForegroundColor Gray

    # Uptime
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host "  Uptime:   $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Gray

    Write-Host ""
}
#endregion

#region ClaudeNPC Server Functions
function Start-ClaudeNPCServer {
    param([string]$Path = "C:\MinecraftServer")

    if (Test-Path "$Path\start.bat") {
        Write-Host "Starting ClaudeNPC Server..." -ForegroundColor Cyan
        Set-Location $Path
        .\start.bat
    } else {
        Write-Host ""
        Write-Host "  [✗] Server not found at: $Path" -ForegroundColor Red
        Write-Host "  [i] Run setup: cnpcsetup" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Stop-ClaudeNPCServer {
    $process = Get-Process java -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -like "*Minecraft*" -or $_.CommandLine -like "*paper.jar*"
    }

    if ($process) {
        Write-Host "Stopping ClaudeNPC Server (PID: $($process.Id))..." -ForegroundColor Yellow
        $process | Stop-Process -Force
        Write-Host "Server stopped." -ForegroundColor Green
    } else {
        Write-Host "No Minecraft server process found." -ForegroundColor Gray
    }
}
Set-Alias -Name mcstop -Value Stop-ClaudeNPCServer

function Get-ClaudeNPCStatus {
    param(
        [switch]$Detailed,
        [switch]$ServerOnly
    )

    $statusScript = "C:\Users\iamto\.kenl\claude-landing\claudenpc-server-suite\Get-ClaudeNPCStatus.ps1"

    if (Test-Path $statusScript) {
        & $statusScript @PSBoundParameters
    } else {
        Write-Host ""
        Write-Host "  [!] Status script not found" -ForegroundColor Yellow
        Write-Host "  [i] Expected: $statusScript" -ForegroundColor Gray
        Write-Host ""
    }
}

function Start-ClaudeNPCSetup {
    $setupPath = "C:\Users\iamto\.kenl\claude-landing\claudenpc-server-suite\setup\Setup.ps1"
    if (Test-Path $setupPath) {
        Write-Host "Starting ClaudeNPC Setup..." -ForegroundColor Cyan
        & $setupPath
    } else {
        Write-Host ""
        Write-Host "  [✗] Setup script not found" -ForegroundColor Red
        Write-Host "  [i] Expected: $setupPath" -ForegroundColor Gray
        Write-Host ""
    }
}

function Watch-MinecraftLogs {
    param([string]$Path = "C:\MinecraftServer\logs\latest.log")

    if (Test-Path $Path) {
        Write-Host "Watching Minecraft logs (Ctrl+C to exit)..." -ForegroundColor Cyan
        Get-Content $Path -Tail 20 -Wait
    } else {
        Write-Host "Log file not found: $Path" -ForegroundColor Red
    }
}
Set-Alias -Name mclogs -Value Watch-MinecraftLogs
#endregion

#region Profile Management
function Edit-Profile {
    $editor = $null

    # Try to find an editor
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $editor = "code"
    } elseif (Get-Command notepad++ -ErrorAction SilentlyContinue) {
        $editor = "notepad++"
    } else {
        $editor = "notepad"
    }

    & $editor $PROFILE
}

function Reload-Profile {
    Write-Host ""
    Write-Host "  [⟳] Reloading PowerShell profile..." -ForegroundColor Cyan

    try {
        . $PROFILE
        Write-Host "  [✓] Profile reloaded successfully" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  [✗] Error reloading profile: $_" -ForegroundColor Red
        Write-Host ""
    }
}

function Test-Profile {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    Profile Component Status                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $components = @(
        @{Name="Oh My Posh"; Status=$script:OhMyPoshLoaded},
        @{Name="PSReadLine"; Status=$script:PSReadLineLoaded},
        @{Name="Git"; Status=$script:GitAvailable}
    )

    foreach ($comp in $components) {
        $status = if ($comp.Status) { "✓ Loaded" } else { "✗ Not Available" }
        $color = if ($comp.Status) { "Green" } else { "Yellow" }

        Write-Host "  $($comp.Name.PadRight(20)) " -NoNewline -ForegroundColor Gray
        Write-Host $status -ForegroundColor $color
    }

    if ($script:LoadedModules.Count -gt 0) {
        Write-Host ""
        Write-Host "  Loaded Modules:" -ForegroundColor Gray
        foreach ($mod in $script:LoadedModules) {
            Write-Host "    • $mod" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Profile loaded in: $(((Get-Date) - $script:ProfileLoadTime).TotalMilliseconds) ms" -ForegroundColor Gray
    Write-Host ""
}
#endregion

#region Enhanced Welcome Banner
function Show-WelcomeBanner {
    $hour = (Get-Date).Hour
    $greeting = if ($hour -lt 12) { "Good Morning" }
                elseif ($hour -lt 18) { "Good Afternoon" }
                else { "Good Evening" }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "║            $greeting, $env:USERNAME!".PadRight(70) "║" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📁 Location:    $(Get-Location)" -ForegroundColor Gray
    Write-Host "  📅 Date:        $(Get-Date -Format 'dddd, MMMM dd, yyyy')" -ForegroundColor Gray
    Write-Host "  🕒 Time:        $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray

    # Check if ClaudeNPC server is running
    $serverProcess = Get-Process java -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*paper.jar*"
    }

    if ($serverProcess) {
        $uptime = (Get-Date) - $serverProcess.StartTime
        $memoryMB = [math]::Round($serverProcess.WorkingSet64 / 1MB, 0)
        Write-Host "  🎮 Server:      " -NoNewline -ForegroundColor Gray
        Write-Host "RUNNING " -NoNewline -ForegroundColor Green
        Write-Host "(${memoryMB}MB, up $($uptime.Hours)h $($uptime.Minutes)m)" -ForegroundColor DarkGray
    } else {
        Write-Host "  🎮 Server:      " -NoNewline -ForegroundColor Gray
        Write-Host "STOPPED " -NoNewline -ForegroundColor Yellow
        Write-Host "(use 'mcstart' to start)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  💡 Quick Commands:" -ForegroundColor DarkCyan
    Write-Host "     mcstatus       → Server status dashboard" -ForegroundColor DarkGray
    Write-Host "     mcstart/mcstop → Start/stop server" -ForegroundColor DarkGray
    Write-Host "     cnpc           → Go to ClaudeNPC directory" -ForegroundColor DarkGray
    Write-Host "     sysinfo        → System information" -ForegroundColor DarkGray
    Write-Host ""
}

# Show banner on startup
Show-WelcomeBanner
#endregion

#region Custom Prompt (Fallback if Oh My Posh not available)
if (-not $script:OhMyPoshLoaded) {
    function prompt {
        $loc = Get-Location
        $gitBranch = ""

        # Show git branch if in a repo
        if ($script:GitAvailable) {
            $gitInfo = git branch --show-current 2>$null
            if ($gitInfo) {
                $gitBranch = " (git:$gitInfo)"
            }
        }

        # Check if in ClaudeNPC directory
        $inClaudeNPC = $loc.Path -like "*claudenpc*"
        $locationColor = if ($inClaudeNPC) { "Cyan" } else { "White" }

        Write-Host ""
        Write-Host " PS " -NoNewline -ForegroundColor Blue
        Write-Host "$loc" -NoNewline -ForegroundColor $locationColor
        Write-Host $gitBranch -NoNewline -ForegroundColor Yellow
        Write-Host ""
        Write-Host " ❯" -NoNewline -ForegroundColor Green
        return " "
    }
}
#endregion

#region Performance Optimizations
# Disable telemetry for faster startup
$env:POWERSHELL_TELEMETRY_OPTOUT = 1
$env:POWERSHELL_UPDATECHECK = 'Off'

# Increase command history
$MaximumHistoryCount = 10000

# Faster file completion (skip slow network paths)
$env:PSModulePath = $env:PSModulePath -split ';' | Where-Object { $_ -notlike '*OneDrive*' } | Join-Path ';'
#endregion

#region Utility Functions
function New-Directory {
    param([string]$Name)
    New-Item -ItemType Directory -Path $Name -Force | Out-Null
    Set-Location $Name
}
Set-Alias -Name mkcd -Value New-Directory

function Get-FileHash256 {
    param([string]$Path)
    if (Test-Path $Path) {
        Get-FileHash -Path $Path -Algorithm SHA256 | Select-Object Hash, Path
    }
}
Set-Alias -Name sha256 -Value Get-FileHash256

function Find-File {
    param([string]$Pattern)
    Get-ChildItem -Recurse -Filter $Pattern -ErrorAction SilentlyContinue
}
Set-Alias -Name ff -Value Find-File

function Get-ProcessMemory {
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name, @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet64/1MB,2)}}
}
Set-Alias -Name topmem -Value Get-ProcessMemory
#endregion

#region Final Status
# Show loaded status (silent if no issues)
$loadTime = ((Get-Date) - $script:ProfileLoadTime).TotalMilliseconds
Write-Host "  ✓ Profile loaded in $([math]::Round($loadTime, 0))ms" -ForegroundColor DarkGreen
Write-Host ""

# Reset error action
$ErrorActionPreference = "Continue"
#endregion

# End of Enhanced Profile
