# 03-PaperMC.ps1
# PaperMC server installation phase
# Version: 1.0.0

$scriptRoot = Split-Path $PSScriptRoot -Parent
Import-Module "$scriptRoot\core\Display.psd1" -Force -Global
Import-Module "$scriptRoot\core\Logger.psd1" -Force -Global
Import-Module "$scriptRoot\core\Safety.psd1" -Force -Global

function Invoke-PaperMCSetup {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )

    Write-Section -Title "PaperMC Server Setup" -Icon "📄"
    Write-Log -Message "Starting PaperMC setup" -Level "INFO"

    try {
        # Check for existing installation
        $existing = Test-ExistingInstallation -ServerPath $Config.ServerPath
        if ($existing.Exists) {
            $choice = Invoke-BackupPrompt -ExistingFiles $existing.Files

            switch ($choice) {
                'B' {
                    $backupPath = Join-Path (Split-Path $Config.ServerPath -Parent) "backups"
                    Backup-ExistingServer -ServerPath $Config.ServerPath -BackupPath $backupPath
                }
                'O' {
                    Write-Host ""
                    Write-Host "  Type 'DELETE' to confirm deletion: " -ForegroundColor Red -NoNewline
                    $confirm = Read-Host
                    if ($confirm -ne 'DELETE') {
                        return @{Success = $false; Message = "User cancelled"; Data = @{}}
                    }
                    Remove-SafeDirectory -Path $Config.ServerPath -Force
                }
                'C' {
                    return @{Success = $false; Message = "User cancelled"; Data = @{}}
                }
            }
        }

        # Create directory structure
        Write-StatusBox -Title "Creating directories" -Status "Processing" -Type "Progress"

        $dirs = @("plugins", "world", "logs", "backups")
        foreach ($dir in $dirs) {
            $path = Join-Path $Config.ServerPath $dir
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
            }
        }
        Write-StatusBox -Title "Directories Created" -Status "Complete" -Type "Success"

        # Find PaperMC JAR
        Write-StatusBox -Title "Searching for PaperMC" -Status "Processing" -Type "Progress"

        $paperJar = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "paper-*.jar" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $paperJar) {
            # Auto-download from PaperMC API
            Write-StatusBox -Title "PaperMC" -Status "Downloading latest..." -Type "Progress"

            try {
                $mcVersion = "1.21.3"
                Write-Host ""
                Write-Host "  Fetching latest PaperMC build for Minecraft $mcVersion..." -ForegroundColor Cyan

                # Get latest build number from PaperMC API
                $buildsUrl = "https://api.papermc.io/v2/projects/paper/versions/$mcVersion/builds"
                $buildsResponse = Invoke-RestMethod -Uri $buildsUrl -UseBasicParsing
                $latestBuild = $buildsResponse.builds | Sort-Object build -Descending | Select-Object -First 1

                if (-not $latestBuild) {
                    throw "Could not find builds for MC $mcVersion"
                }

                $buildNumber = $latestBuild.build
                $downloadName = $latestBuild.downloads.application.name

                Write-Host "  Found build #$buildNumber" -ForegroundColor Green

                # Download the JAR
                $downloadUrl = "https://api.papermc.io/v2/projects/paper/versions/$mcVersion/builds/$buildNumber/downloads/$downloadName"
                $destJarDirect = Join-Path $Config.ServerPath "paper.jar"

                Write-Host "  Downloading $downloadName..." -ForegroundColor Cyan

                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $downloadUrl -OutFile $destJarDirect -UseBasicParsing
                $ProgressPreference = 'Continue'

                Write-StatusBox -Title "PaperMC $mcVersion" -Status "Downloaded (build #$buildNumber)" -Type "Success"
                Write-Log -Message "Downloaded PaperMC $mcVersion build #$buildNumber" -Level "SUCCESS"

                # Skip the copy step since we downloaded directly
                $paperJar = Get-Item $destJarDirect
                $skipCopy = $true

            } catch {
                Write-StatusBox -Title "PaperMC Download" -Status "Failed: $_" -Type "Error"
                Write-Host ""
                Write-Host "  Manual download required:" -ForegroundColor Yellow
                Write-Host "  https://papermc.io/downloads/paper" -ForegroundColor White
                Write-Host "  Save to Downloads folder and re-run." -ForegroundColor Gray
                Write-Host ""
                return @{Success = $false; Message = "PaperMC download failed"; Data = @{}}
            }
        }

        # Copy JAR (if not already downloaded directly)
        $destJar = Join-Path $Config.ServerPath "paper.jar"
        if (-not $skipCopy) {
            Copy-Item $paperJar.FullName $destJar -Force
            Write-StatusBox -Title "PaperMC JAR" -Status "Copied" -Type "Success"
        }

        # Create start.bat
        Write-StatusBox -Title "Creating start.bat" -Status "Processing" -Type "Progress"

        $startBat = @"
@echo off
title ClaudeNPC Minecraft Server
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║           ClaudeNPC Minecraft Server                     ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

java -Xms$($Config.MemoryMin) -Xmx$($Config.MemoryMax) ^
  -XX:+UseG1GC ^
  -XX:+ParallelRefProcEnabled ^
  -XX:MaxGCPauseMillis=200 ^
  -XX:+UnlockExperimentalVMOptions ^
  -XX:+DisableExplicitGC ^
  -XX:+AlwaysPreTouch ^
  -XX:G1HeapWastePercent=5 ^
  -XX:G1MixedGCCountTarget=4 ^
  -XX:G1MixedGCLiveThresholdPercent=90 ^
  -XX:G1RSetUpdatingPauseTimePercent=5 ^
  -XX:SurvivorRatio=32 ^
  -XX:+PerfDisableSharedMem ^
  -XX:MaxTenuringThreshold=1 ^
  -jar paper.jar nogui

echo.
echo [INFO] Server stopped.
pause
"@
        $startBat | Set-Content (Join-Path $Config.ServerPath "start.bat") -Encoding ASCII
        Write-StatusBox -Title "start.bat" -Status "Created" -Type "Success"

        # Accept EULA
        Write-StatusBox -Title "Accepting EULA" -Status "Processing" -Type "Progress"
        "eula=true" | Set-Content (Join-Path $Config.ServerPath "eula.txt")
        Write-StatusBox -Title "EULA" -Status "Accepted" -Type "Success"

        # Initial server start
        Write-StatusBox -Title "Initial server start" -Status "Generating configs..." -Type "Progress"
        Write-Host ""
        Write-Host "  This will take 1-2 minutes. The server will start and stop automatically." -ForegroundColor Gray
        Write-Host ""

        $process = Start-Process -FilePath "java" `
            -ArgumentList @("-Xms1G", "-Xmx2G", "-jar", $destJar, "nogui") `
            -WorkingDirectory $Config.ServerPath `
            -PassThru `
            -NoNewWindow

        # Wait for server.properties to be created
        $timeout = 120
        $elapsed = 0
        while (-not (Test-Path (Join-Path $Config.ServerPath "server.properties")) -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 2
            $elapsed += 2
        }

        # Stop server
        if (-not $process.HasExited) {
            $process | Stop-Process -Force
            Start-Sleep -Seconds 2
        }

        Write-StatusBox -Title "Server Configuration" -Status "Generated" -Type "Success"
        Write-Log -Message "PaperMC setup complete" -Level "SUCCESS"

        return @{
            Success = $true
            Message = "PaperMC setup complete"
            Data = @{ServerPath = $Config.ServerPath}
        }

    } catch {
        Write-StatusBox -Title "PaperMC Setup Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        return @{Success = $false; Message = $_.Exception.Message; Data = @{}}
    }
}
