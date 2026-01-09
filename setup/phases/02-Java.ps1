# 02-Java.ps1
# Java installation phase
# Version: 1.0.0

$scriptRoot = Split-Path $PSScriptRoot -Parent
Import-Module "$scriptRoot\core\Display.psd1" -Force -Global
Import-Module "$scriptRoot\core\Logger.psd1" -Force -Global
Import-Module "$scriptRoot\core\Safety.psd1" -Force -Global

function Invoke-JavaInstallation {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )

    Write-Section -Title "Java Installation" -Icon "☕"
    Write-Log -Message "Starting Java installation" -Level "INFO"

    try {
        # Check if Java already installed
        Write-StatusBox -Title "Checking for Java" -Status "Processing" -Type "Progress"

        $javaInstalled = $false
        try {
            $javaVersion = & java -version 2>&1 | Select-Object -First 1
            if ($javaVersion -match "(\d+)\.(\d+)\.(\d+)") {
                $major = [int]$Matches[1]
                if ($major -ge 17) {
                    $javaInstalled = $true
                    Write-StatusBox -Title "Java Found" -Status "Version $major" -Type "Success"
                    Write-Log -Message "Java already installed: $javaVersion" -Level "SUCCESS"
                }
            }
        } catch {
            # Java not found
        }

        if ($javaInstalled) {
            return @{
                Success = $true
                Message = "Java already installed"
                Data = @{JavaVersion = $javaVersion}
            }
        }

        # Find Java installer
        Write-StatusBox -Title "Searching for Java installer" -Status "Processing" -Type "Progress"

        $javaZip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "openjdk-*_windows-x64*.zip" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $javaZip) {
            # Try winget installation
            Write-StatusBox -Title "Java Installer" -Status "Trying winget..." -Type "Progress"

            $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
            if ($wingetAvailable) {
                Write-Host ""
                Write-Host "  Installing Java 21 via winget..." -ForegroundColor Cyan
                Write-Host ""

                try {
                    $installResult = & winget install Microsoft.OpenJDK.21 --accept-source-agreements --accept-package-agreements 2>&1

                    # Refresh PATH for current session
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

                    # Verify installation
                    Start-Sleep -Seconds 2
                    $javaCheck = & java -version 2>&1 | Select-Object -First 1
                    if ($javaCheck -match "21") {
                        Write-StatusBox -Title "Java 21" -Status "Installed via winget" -Type "Success"
                        Write-Log -Message "Java 21 installed via winget" -Level "SUCCESS"
                        return @{
                            Success = $true
                            Message = "Java installed via winget"
                            Data = @{JavaVersion = $javaCheck; Method = "winget"}
                        }
                    }
                } catch {
                    Write-Log -Message "Winget installation failed: $_" -Level "WARNING"
                }
            }

            Write-StatusBox -Title "Java Installer" -Status "Manual download required" -Type "Warning"
            Write-Host ""
            Write-Host "  Please download OpenJDK from:" -ForegroundColor Yellow
            Write-Host "  https://adoptium.net/temurin/releases/?version=21" -ForegroundColor White
            Write-Host ""
            Write-Host "  Or run: winget install Microsoft.OpenJDK.21" -ForegroundColor Cyan
            Write-Host ""

            return @{
                Success = $false
                Message = "Java installer not found - run: winget install Microsoft.OpenJDK.21"
                Data = @{}
            }
        }

        Write-StatusBox -Title "Java Installer Found" -Status $javaZip.Name -Type "Success"

        # Extract Java
        Write-StatusBox -Title "Extracting Java" -Status "Processing" -Type "Progress"

        $javaPath = "C:\Java"
        if (-not (Test-Path $javaPath)) {
            New-Item -ItemType Directory -Path $javaPath -Force | Out-Null
        }

        Expand-Archive -Path $javaZip.FullName -DestinationPath $javaPath -Force

        # Find extracted JDK folder (look for folder containing bin\java.exe)
        $jdkFolder = Get-ChildItem $javaPath -Directory -Recurse |
            Where-Object { Test-Path (Join-Path $_.FullName "bin\java.exe") } |
            Select-Object -First 1

        if (-not $jdkFolder) {
            throw "Could not find extracted JDK folder with java.exe"
        }

        $javaHome = $jdkFolder.FullName
        Write-StatusBox -Title "Java Extracted" -Status $javaHome -Type "Success"

        # Set JAVA_HOME
        Write-StatusBox -Title "Setting JAVA_HOME" -Status "Processing" -Type "Progress"
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
        Write-StatusBox -Title "JAVA_HOME" -Status "Set" -Type "Success"

        # Update PATH
        Write-StatusBox -Title "Updating PATH" -Status "Processing" -Type "Progress"
        $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $javaBin = Join-Path $javaHome "bin"
        if ($path -notlike "*$javaBin*") {
            $path = "$path;$javaBin"
            [Environment]::SetEnvironmentVariable("Path", $path, "Machine")
        }
        Write-StatusBox -Title "PATH" -Status "Updated" -Type "Success"

        # Refresh environment for current session
        $env:JAVA_HOME = $javaHome
        $env:Path = "$env:Path;$javaBin"

        # Verify installation
        Write-StatusBox -Title "Verifying Java" -Status "Processing" -Type "Progress"
        $javaExe = Join-Path $javaHome "bin\java.exe"

        # Java -version writes to stderr, so we need to capture it properly without triggering errors
        $savedErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $versionOutput = & $javaExe -version 2>&1
        $ErrorActionPreference = $savedErrorActionPreference

        $javaVersion = ($versionOutput | Select-Object -First 1).ToString().Trim()

        Write-StatusBox -Title "Java Installation" -Status "Complete" -Type "Success"
        Write-StatusBox -Title "Java Version" -Status $javaVersion -Type "Info"

        Write-Log -Message "Java installed successfully: $javaVersion" -Level "SUCCESS"

        return @{
            Success = $true
            Message = "Java installed successfully"
            Data = @{
                JavaHome = $javaHome
                JavaVersion = $javaVersion
            }
        }

    } catch {
        Write-StatusBox -Title "Java Installation Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        return @{Success = $false; Message = $_.Exception.Message; Data = @{}}
    }
}
