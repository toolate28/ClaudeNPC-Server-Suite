# Get-ClaudeNPCStatus.ps1
# PowerShell Environment & Server Status Dashboard
# Version: 1.0.0

function Get-ClaudeNPCStatus {
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        [switch]$ServerOnly
    )

    $ErrorActionPreference = "SilentlyContinue"

    # Color scheme
    $colors = @{
        Header = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
        Info = "White"
        Dim = "Gray"
    }

    function Write-StatusBox {
        param(
            [string]$Title,
            [string]$Status,
            [string]$Color = "White"
        )
        $maxLength = 70
        $padding = $maxLength - $Title.Length - $Status.Length - 2
        Write-Host "  " -NoNewline
        Write-Host $Title -NoNewline -ForegroundColor $colors.Info
        Write-Host (" " * $padding) -NoNewline
        Write-Host $Status -ForegroundColor $colors[$Color]
    }

    # ============================================================================
    # HEADER
    # ============================================================================
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
    Write-Host "║                                                                        ║" -ForegroundColor $colors.Header
    Write-Host "║              CLAUDENPC SERVER SUITE - STATUS DASHBOARD                 ║" -ForegroundColor $colors.Header
    Write-Host "║                                                                        ║" -ForegroundColor $colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header
    Write-Host ""

    if (-not $ServerOnly) {
        # ============================================================================
        # POWERSHELL ENVIRONMENT
        # ============================================================================
        Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
        Write-Host "║  PowerShell Environment                                                ║" -ForegroundColor $colors.Header
        Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

        # PowerShell Version
        $psVersion = $PSVersionTable.PSVersion
        Write-StatusBox -Title "PowerShell Version" -Status "$($psVersion.Major).$($psVersion.Minor).$($psVersion.Patch)" -Color "Success"

        # Execution Policy
        $execPolicy = Get-ExecutionPolicy
        $policyColor = if ($execPolicy -eq "RemoteSigned" -or $execPolicy -eq "Bypass") { "Success" } else { "Warning" }
        Write-StatusBox -Title "Execution Policy" -Status $execPolicy -Color $policyColor

        # Profile Status
        $profileExists = Test-Path $PROFILE
        $profileColor = if ($profileExists) { "Success" } else { "Warning" }
        $profileStatus = if ($profileExists) { "Loaded" } else { "Not Found" }
        Write-StatusBox -Title "PowerShell Profile" -Status $profileStatus -Color $profileColor

        # Oh My Posh
        $ohMyPoshInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue
        $ohMyPoshStatus = if ($ohMyPoshInstalled) { "✓ Installed" } else { "✗ Not Installed" }
        $ohMyPoshColor = if ($ohMyPoshInstalled) { "Success" } else { "Dim" }
        Write-StatusBox -Title "Oh My Posh (Theme)" -Status $ohMyPoshStatus -Color $ohMyPoshColor

        if ($ohMyPoshInstalled -and $Detailed) {
            $themeEnv = $env:POSH_THEMES_PATH
            if ($themeEnv) {
                Write-Host "    └─ Theme Path: $themeEnv" -ForegroundColor $colors.Dim
            }
        }

        # posh-git
        $poshGitModule = Get-Module posh-git
        $poshGitStatus = if ($poshGitModule) { "✓ Loaded" } else { "✗ Not Loaded" }
        $poshGitColor = if ($poshGitModule) { "Success" } else { "Warning" }
        Write-StatusBox -Title "posh-git (Git Integration)" -Status $poshGitStatus -Color $poshGitColor

        if (-not $poshGitModule -and (Get-InstalledModule posh-git -ErrorAction SilentlyContinue)) {
            Write-Host "    └─ Installed but not imported. Run: Import-Module posh-git" -ForegroundColor $colors.Warning
        }

        Write-Host ""

        # ============================================================================
        # AVAILABLE MODULES
        # ============================================================================
        Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
        Write-Host "║  PowerShell Modules                                                    ║" -ForegroundColor $colors.Header
        Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

        $importantModules = @(
            @{Name="posh-git"; Description="Git integration for prompt"},
            @{Name="PSReadLine"; Description="Command line editing"},
            @{Name="PowerShellGet"; Description="Module management"},
            @{Name="PackageManagement"; Description="Package provider"}
        )

        foreach ($mod in $importantModules) {
            $module = Get-Module $mod.Name
            $installed = Get-Module $mod.Name -ListAvailable | Select-Object -First 1

            if ($module) {
                Write-StatusBox -Title $mod.Name -Status "✓ Loaded" -Color "Success"
                if ($Detailed -and $installed) {
                    Write-Host "    └─ Version: $($installed.Version) | $($mod.Description)" -ForegroundColor $colors.Dim
                }
            } elseif ($installed) {
                Write-StatusBox -Title $mod.Name -Status "○ Available (not loaded)" -Color "Info"
                if ($Detailed) {
                    Write-Host "    └─ Version: $($installed.Version) | Import with: Import-Module $($mod.Name)" -ForegroundColor $colors.Dim
                }
            } else {
                Write-StatusBox -Title $mod.Name -Status "✗ Not Installed" -Color "Dim"
            }
        }

        Write-Host ""
    }

    # ============================================================================
    # MINECRAFT SERVER STATUS
    # ============================================================================
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
    Write-Host "║  ClaudeNPC Minecraft Server                                            ║" -ForegroundColor $colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

    # Server Path
    $serverPath = "C:\MinecraftServer"
    $serverExists = Test-Path $serverPath

    if (-not $serverExists) {
        Write-StatusBox -Title "Server Installation" -Status "✗ Not Found" -Color "Error"
        Write-Host "    └─ Run installation: .\setup\Setup.ps1" -ForegroundColor $colors.Warning
        Write-Host ""
        return
    }

    Write-StatusBox -Title "Server Path" -Status $serverPath -Color "Success"

    # Server Process
    $javaProcess = Get-Process java -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*paper.jar*" -or $_.MainWindowTitle -like "*Minecraft*"
    }

    if ($javaProcess) {
        Write-StatusBox -Title "Server Status" -Status "✓ RUNNING" -Color "Success"
        Write-StatusBox -Title "Process ID" -Status $javaProcess.Id -Color "Info"

        # Memory Usage
        $memoryMB = [math]::Round($javaProcess.WorkingSet64 / 1MB, 2)
        $memoryColor = if ($memoryMB -lt 6144) { "Success" } elseif ($memoryMB -lt 7168) { "Warning" } else { "Error" }
        Write-StatusBox -Title "Memory Usage" -Status "$memoryMB MB" -Color $memoryColor

        # CPU Usage
        $cpu = [math]::Round($javaProcess.CPU, 2)
        Write-StatusBox -Title "CPU Time" -Status "$cpu seconds" -Color "Info"

        # Uptime
        $uptime = (Get-Date) - $javaProcess.StartTime
        $uptimeStr = "{0:D2}h {1:D2}m {2:D2}s" -f $uptime.Hours, $uptime.Minutes, $uptime.Seconds
        Write-StatusBox -Title "Uptime" -Status $uptimeStr -Color "Info"
    } else {
        Write-StatusBox -Title "Server Status" -Status "✗ STOPPED" -Color "Warning"
        Write-Host "    └─ Start server: cd C:\MinecraftServer; .\start.bat" -ForegroundColor $colors.Info
    }

    # Server Files
    $paperJar = Test-Path "$serverPath\paper.jar"
    $eula = Test-Path "$serverPath\eula.txt"
    $startBat = Test-Path "$serverPath\start.bat"

    Write-StatusBox -Title "paper.jar" -Status $(if ($paperJar) { "✓ Present" } else { "✗ Missing" }) -Color $(if ($paperJar) { "Success" } else { "Error" })
    Write-StatusBox -Title "start.bat" -Status $(if ($startBat) { "✓ Present" } else { "✗ Missing" }) -Color $(if ($startBat) { "Success" } else { "Error" })
    Write-StatusBox -Title "EULA Accepted" -Status $(if ($eula) { "✓ Yes" } else { "✗ No" }) -Color $(if ($eula) { "Success" } else { "Warning" })

    Write-Host ""

    # ============================================================================
    # PLUGINS STATUS
    # ============================================================================
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
    Write-Host "║  Installed Plugins                                                     ║" -ForegroundColor $colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

    $pluginsPath = "$serverPath\plugins"
    if (Test-Path $pluginsPath) {
        $plugins = Get-ChildItem $pluginsPath -Filter "*.jar" | Select-Object Name

        $expectedPlugins = @{
            "Citizens" = "✓ Required for NPCs"
            "Vault" = "✓ Economy & Permissions API"
            "LuckPerms" = "✓ Permission Management"
            "PlaceholderAPI" = "✓ Placeholder System"
            "EssentialsX" = "○ Recommended (Admin Commands)"
            "CoreProtect" = "○ Recommended (Logging)"
        }

        foreach ($plugin in $expectedPlugins.GetEnumerator()) {
            $installed = $plugins | Where-Object { $_.Name -like "$($plugin.Key)*.jar" }
            if ($installed) {
                Write-StatusBox -Title $plugin.Key -Status "✓ Installed" -Color "Success"
                if ($Detailed) {
                    Write-Host "    └─ $($plugin.Value)" -ForegroundColor $colors.Dim
                }
            } else {
                $status = if ($plugin.Value -like "✓*") { "✗ MISSING (Required)" } else { "○ Not Installed" }
                $color = if ($plugin.Value -like "✓*") { "Error" } else { "Dim" }
                Write-StatusBox -Title $plugin.Key -Status $status -Color $color
            }
        }

        # Additional plugins
        $additional = $plugins | Where-Object {
            $name = $_.Name
            -not ($expectedPlugins.Keys | Where-Object { $name -like "$_*.jar" })
        }

        if ($additional) {
            Write-Host ""
            Write-Host "  Additional Plugins:" -ForegroundColor $colors.Info
            foreach ($plugin in $additional) {
                Write-Host "    • $($plugin.Name)" -ForegroundColor $colors.Dim
            }
        }
    } else {
        Write-StatusBox -Title "Plugins Directory" -Status "✗ Not Found" -Color "Error"
    }

    Write-Host ""

    # ============================================================================
    # RECENT LOGS
    # ============================================================================
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
    Write-Host "║  Server Logs (Last 3 Errors)                                           ║" -ForegroundColor $colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

    $logFile = "$serverPath\logs\latest.log"
    if (Test-Path $logFile) {
        $errors = Get-Content $logFile | Where-Object { $_ -match "\[ERROR\]" } | Select-Object -Last 3

        if ($errors) {
            foreach ($error in $errors) {
                # Extract timestamp and message
                if ($error -match "\[(\d{2}:\d{2}:\d{2})\].*\[ERROR\]: (.+)") {
                    $time = $Matches[1]
                    $msg = $Matches[2]
                    if ($msg.Length -gt 60) {
                        $msg = $msg.Substring(0, 57) + "..."
                    }
                    Write-Host "  [$time]" -NoNewline -ForegroundColor $colors.Dim
                    Write-Host " $msg" -ForegroundColor $colors.Error
                }
            }
        } else {
            Write-Host "  ✓ No errors in recent logs!" -ForegroundColor $colors.Success
        }

        # Log file info
        $logInfo = Get-Item $logFile
        $logSize = [math]::Round($logInfo.Length / 1KB, 2)
        $logModified = $logInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        Write-Host ""
        Write-StatusBox -Title "Log File Size" -Status "$logSize KB" -Color "Info"
        Write-StatusBox -Title "Last Modified" -Status $logModified -Color "Info"
    } else {
        Write-Host "  ○ No log file found (server not started yet)" -ForegroundColor $colors.Dim
    }

    Write-Host ""

    # ============================================================================
    # SERVER CONFIGURATION
    # ============================================================================
    if ($Detailed) {
        Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
        Write-Host "║  Server Configuration                                                  ║" -ForegroundColor $colors.Header
        Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

        $configFile = "$serverPath\setup-config.json"
        if (Test-Path $configFile) {
            $config = Get-Content $configFile | ConvertFrom-Json

            Write-StatusBox -Title "Server Port" -Status $config.ServerPort -Color "Info"
            Write-StatusBox -Title "Max Players" -Status $config.MaxPlayers -Color "Info"
            Write-StatusBox -Title "View Distance" -Status "$($config.ViewDistance) chunks" -Color "Info"
            Write-StatusBox -Title "Memory" -Status "$($config.MemoryMin) - $($config.MemoryMax)" -Color "Info"
            Write-StatusBox -Title "Install Profile" -Status $config.InstallProfile -Color "Info"
        } else {
            Write-Host "  ○ No configuration file found" -ForegroundColor $colors.Dim
        }

        Write-Host ""
    }

    # ============================================================================
    # QUICK ACTIONS
    # ============================================================================
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colors.Header
    Write-Host "║  Quick Actions                                                         ║" -ForegroundColor $colors.Header
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colors.Header

    if ($javaProcess) {
        Write-Host "  • Stop Server:  " -NoNewline -ForegroundColor $colors.Info
        Write-Host "Get-Process java | Stop-Process -Force" -ForegroundColor $colors.Dim

        Write-Host "  • View Console: " -NoNewline -ForegroundColor $colors.Info
        Write-Host "Get-Content C:\MinecraftServer\logs\latest.log -Tail 20 -Wait" -ForegroundColor $colors.Dim
    } else {
        Write-Host "  • Start Server: " -NoNewline -ForegroundColor $colors.Info
        Write-Host "cd C:\MinecraftServer; .\start.bat" -ForegroundColor $colors.Dim

        Write-Host "  • Reinstall:    " -NoNewline -ForegroundColor $colors.Info
        Write-Host "cd setup; .\Setup.ps1" -ForegroundColor $colors.Dim
    }

    Write-Host "  • Check Status: " -NoNewline -ForegroundColor $colors.Info
    Write-Host "Get-ClaudeNPCStatus -Detailed" -ForegroundColor $colors.Dim

    Write-Host "  • Edit Config:  " -NoNewline -ForegroundColor $colors.Info
    Write-Host "code C:\MinecraftServer\plugins\Citizens\config.yml" -ForegroundColor $colors.Dim

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════" -ForegroundColor $colors.Header
    Write-Host ""
}

# Export function
Export-ModuleMember -Function Get-ClaudeNPCStatus

# Auto-run if script is executed directly
if ($MyInvocation.InvocationName -eq "&") {
    Get-ClaudeNPCStatus @args
}
