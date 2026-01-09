# 04-Plugins.ps1
# Plugin installation phase
# Version: 2.0.0 - Enhanced with auto-download

$scriptRoot = Split-Path $PSScriptRoot -Parent
Import-Module "$scriptRoot\core\Display.psd1" -Force -Global
Import-Module "$scriptRoot\core\Logger.psd1" -Force -Global
Import-Module "$scriptRoot\core\Config.psd1" -Force -Global

# Plugin download URLs - Updated 2026-01-09
$script:PluginUrls = @{
    # Core plugins
    "Citizens" = "https://ci.citizensnpcs.co/job/Citizens2/lastSuccessfulBuild/artifact/dist/target/Citizens.jar"
    "Vault" = "https://github.com/MilkBowl/Vault/releases/download/1.7.3/Vault.jar"
    "LuckPerms" = "https://download.luckperms.net/1563/bukkit/loader/LuckPerms-Bukkit-5.4.148.jar"
    "CoreProtect" = "https://github.com/PlayPro/CoreProtect/releases/download/23.0/CoreProtect-23.0.jar"
    "PlaceholderAPI" = "https://github.com/PlaceholderAPI/PlaceholderAPI/releases/download/2.11.7/PlaceholderAPI-2.11.7.jar"
    # Full profile plugins
    "WorldEdit" = "https://mediafilez.forgecdn.net/files/5821/785/worldedit-bukkit-7.3.10.jar"
    "WorldGuard" = "https://mediafilez.forgecdn.net/files/5821/788/worldguard-bukkit-7.0.13.jar"
    "EssentialsX" = "https://github.com/EssentialsX/Essentials/releases/download/2.20.1/EssentialsX-2.20.1.jar"
    "Spark" = "https://ci.lucko.me/job/spark/465/artifact/spark-bukkit/build/libs/spark-1.10.119-bukkit.jar"
    "GriefPrevention" = "https://github.com/TechFortress/GriefPrevention/releases/download/16.18.4/GriefPrevention.jar"
}

function Download-Plugin {
    param(
        [string]$PluginName,
        [string]$DestinationPath
    )

    if (-not $script:PluginUrls.ContainsKey($PluginName)) {
        Write-Log -Message "No download URL configured for: $PluginName" -Level "WARNING"
        return $false
    }

    $url = $script:PluginUrls[$PluginName]
    $fileName = Split-Path $url -Leaf
    $destFile = Join-Path $DestinationPath $fileName

    try {
        Write-StatusBox -Title $PluginName -Status "Downloading..." -Type "Progress"
        Write-Log -Message "Downloading $PluginName from $url" -Level "INFO"

        # Download with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $destFile -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = 'Continue'

        Write-StatusBox -Title $PluginName -Status "Downloaded" -Type "Success"
        Write-Log -Message "Downloaded $PluginName successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-StatusBox -Title $PluginName -Status "Download failed" -Type "Error"
        Write-Log -Message "Failed to download $PluginName : $_" -Level "ERROR"
        return $false
    }
}

function Invoke-PluginInstallation {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,

        [Parameter(Mandatory=$false)]
        [switch]$AutoDownload = $true
    )

    Write-Section -Title "Plugin Installation" -Icon "🔌"
    Write-Log -Message "Starting plugin installation (AutoDownload: $AutoDownload)" -Level "INFO"

    try {
        $pluginsPath = Join-Path $Config.ServerPath "plugins"
        if (-not (Test-Path $pluginsPath)) {
            New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
        }

        # Get install profile
        $profile = Get-InstallProfile -ProfileName $Config.InstallProfile
        Write-StatusBox -Title "Install Profile" -Status $profile.Name -Type "Info"
        Write-Host ""
        Write-Host "  Plugins to install: $($profile.Plugins.Count)" -ForegroundColor Gray
        if ($AutoDownload) {
            Write-Host "  Auto-download: Enabled" -ForegroundColor Green
        }
        Write-Host ""

        $installed = @()
        $downloaded = @()
        $failed = @()

        # Special handling for ClaudeNPC - copy from build
        $repoRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent
        $claudeNPCJar = Join-Path $repoRoot "ClaudeNPC\target\ClaudeNPC.jar"

        if (Test-Path $claudeNPCJar) {
            Write-StatusBox -Title "ClaudeNPC" -Status "Installing from build..." -Type "Progress"
            $destClaudeNPC = Join-Path $pluginsPath "ClaudeNPC.jar"
            Copy-Item $claudeNPCJar $destClaudeNPC -Force
            Write-StatusBox -Title "ClaudeNPC" -Status "Installed (v2.1.0)" -Type "Success"
            Write-Log -Message "ClaudeNPC plugin installed from local build" -Level "SUCCESS"
            $installed += "ClaudeNPC"
        } else {
            Write-StatusBox -Title "ClaudeNPC" -Status "Build not found - run: mvn package in ClaudeNPC/" -Type "Warning"
            Write-Log -Message "ClaudeNPC JAR not found at: $claudeNPCJar" -Level "WARNING"
        }

        foreach ($plugin in $profile.Plugins) {
            # Skip ClaudeNPC if in profile - we handled it specially above
            if ($plugin -eq "ClaudeNPC") { continue }
            Write-StatusBox -Title "Installing $plugin" -Status "Checking..." -Type "Progress"

            # First, check if already installed
            $existingPlugin = Get-ChildItem $pluginsPath -Filter "$plugin*.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($existingPlugin) {
                Write-StatusBox -Title $plugin -Status "Already installed" -Type "Info"
                Write-Log -Message "Plugin already exists: $plugin" -Level "INFO"
                $installed += $plugin
                continue
            }

            # Search for plugin in Downloads folder
            $pluginJar = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "$plugin*.jar" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

            if ($pluginJar) {
                # Found in Downloads, copy it
                $dest = Join-Path $pluginsPath $pluginJar.Name
                Copy-Item $pluginJar.FullName $dest -Force
                Write-StatusBox -Title $plugin -Status "Installed from Downloads" -Type "Success"
                Write-Log -Message "Plugin installed from Downloads: $plugin" -Level "SUCCESS"
                $installed += $plugin
                continue
            }

            # Not found locally, try auto-download if enabled
            if ($AutoDownload) {
                $downloadSuccess = Download-Plugin -PluginName $plugin -DestinationPath $pluginsPath
                if ($downloadSuccess) {
                    $downloaded += $plugin
                    $installed += $plugin
                    continue
                }
            }

            # Failed to install
            Write-StatusBox -Title $plugin -Status "Not available" -Type "Warning"
            Write-Log -Message "Plugin not found: $plugin" -Level "WARNING"
            $failed += $plugin
        }

        # Summary
        Write-Host ""
        Write-Host "  Installation Summary:" -ForegroundColor Cyan
        Write-Host "  - Installed: $($installed.Count)" -ForegroundColor Green
        if ($downloaded.Count -gt 0) {
            Write-Host "  - Downloaded: $($downloaded.Count)" -ForegroundColor Cyan
        }
        Write-Host "  - Failed: $($failed.Count)" -ForegroundColor $(if ($failed.Count -gt 0) { "Yellow" } else { "Gray" })
        Write-Host ""

        if ($installed.Count -gt 0) {
            Write-Host "  Installed plugins:" -ForegroundColor Gray
            foreach ($p in $installed) {
                $mark = if ($downloaded -contains $p) { " (downloaded)" } else { "" }
                Write-Host "    • $p$mark" -ForegroundColor Gray
            }
            Write-Host ""
        }

        if ($failed.Count -gt 0) {
            Write-Host "  Failed plugins:" -ForegroundColor Yellow
            foreach ($p in $failed) {
                Write-Host "    • $p" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "  Note: Re-run installation to retry failed downloads" -ForegroundColor Gray
            Write-Host ""
        }

        # Check if Citizens (required) was installed
        $citizensInstalled = $installed -contains "Citizens"
        if (-not $citizensInstalled) {
            Write-StatusBox -Title "Citizens Plugin" -Status "REQUIRED - Not installed" -Type "Warning"
            Write-Host ""
            Write-Host "  Citizens is REQUIRED for ClaudeNPC to work!" -ForegroundColor Yellow
            Write-Host "  The installation will continue, but ClaudeNPC won't function without it." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  You can re-run the installation to retry the download." -ForegroundColor Cyan
            Write-Host ""
            Write-Log -Message "Citizens plugin not installed (required for ClaudeNPC)" -Level "WARNING"
        }

        $success = $installed.Count -gt 0
        $message = if ($success) {
            "Installed $($installed.Count) plugin(s)"
        } else {
            "No plugins installed"
        }

        if ($success) {
            Write-StatusBox -Title "Plugin Installation" -Status $message -Type "Success"
            Write-Log -Message "Plugin installation complete. Installed: $($installed.Count), Downloaded: $($downloaded.Count), Failed: $($failed.Count)" -Level "SUCCESS"
        } else {
            Write-StatusBox -Title "Plugin Installation" -Status $message -Type "Warning"
            Write-Log -Message "Plugin installation had issues. Installed: $($installed.Count), Failed: $($failed.Count)" -Level "WARNING"
        }

        return @{
            Success = $true  # Don't fail the installation, just warn
            Message = $message
            Data = @{
                Installed = $installed
                Downloaded = $downloaded
                Failed = $failed
                Profile = $profile.Name
                CitizensInstalled = $citizensInstalled
            }
        }

    } catch {
        Write-StatusBox -Title "Plugin Installation Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        return @{Success = $false; Message = $_.Exception.Message; Data = @{}}
    }
}
