# Safety.ps1
# Safety checks and validation for ClaudeNPC Server Suite
# Version: 1.0.0

#region Safety Checks

function Test-ExistingInstallation {
    <#
    .SYNOPSIS
        Checks for existing server installation
    .PARAMETER ServerPath
        Path to check for existing installation
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerPath
    )
    
    $existingFiles = @()
    
    $criticalPaths = @(
        @{Path = "server.properties"; Type = "File"; Description = "Server configuration"},
        @{Path = "world"; Type = "Directory"; Description = "Game world data"},
        @{Path = "plugins"; Type = "Directory"; Description = "Plugin directory"},
        @{Path = "paper.jar"; Type = "File"; Description = "Server JAR"}
    )
    
    foreach ($item in $criticalPaths) {
        $fullPath = Join-Path $ServerPath $item.Path
        $exists = if ($item.Type -eq "File") {
            Test-Path $fullPath -PathType Leaf
        } else {
            Test-Path $fullPath -PathType Container
        }
        
        if ($exists) {
            $existingFiles += @{
                Path = $item.Path
                Description = $item.Description
                FullPath = $fullPath
            }
        }
    }
    
    return @{
        Exists = $existingFiles.Count -gt 0
        Files = $existingFiles
    }
}

function Invoke-BackupPrompt {
    <#
    .SYNOPSIS
        Prompts user for backup decision
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$ExistingFiles
    )
    
    Write-Section -Title "Existing Installation Detected" -Icon $script:Icons.Warning
    Write-Host ""
    Write-Host "  The following files/directories exist:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($file in $ExistingFiles) {
        Write-Host "    • $($file.Description)" -ForegroundColor White -NoNewline
        Write-Host " ($($file.Path))" -ForegroundColor Gray
    }
    
    $options = @{
        'B' = 'Backup existing and continue'
        'O' = 'Overwrite (DESTRUCTIVE - will delete data)'
        'C' = 'Cancel installation'
    }
    
    $choice = Read-Choice -Message "How would you like to proceed?" -Options $options -Default 'B'
    
    return $choice
}

function Backup-ExistingServer {
    <#
    .SYNOPSIS
        Creates backup of existing server
    .PARAMETER ServerPath
        Path to server directory
    .PARAMETER BackupPath
        Path to store backups
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerPath,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    
    Write-Section -Title "Creating Backup" -Icon $script:Icons.Package
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupName = "server-backup-$timestamp"
    $tempBackupPath = Join-Path $BackupPath $backupName
    $zipPath = "$tempBackupPath.zip"
    
    try {
        # Ensure backup directory exists
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        New-Item -ItemType Directory -Path $tempBackupPath -Force | Out-Null
        
        # Items to backup
        $backupItems = @("world", "world_nether", "world_the_end", "plugins", 
                         "server.properties", "bukkit.yml", "spigot.yml", "paper-global.yml")
        
        $backedUp = 0
        foreach ($item in $backupItems) {
            $sourcePath = Join-Path $ServerPath $item
            if (Test-Path $sourcePath) {
                $destPath = Join-Path $tempBackupPath $item
                Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop
                $backedUp++
                Write-StatusBox -Title "Backed up: $item" -Status "Complete" -Type "Success"
            }
        }
        
        # Compress backup
        Write-StatusBox -Title "Compressing backup" -Status "In Progress" -Type "Progress"
        Compress-Archive -Path $tempBackupPath -DestinationPath $zipPath -CompressionLevel Optimal
        Remove-Item -Path $tempBackupPath -Recurse -Force
        
        $backupSize = (Get-Item $zipPath).Length / 1MB
        Write-StatusBox -Title "Backup Complete" -Status "$([math]::Round($backupSize, 2)) MB" -Details $zipPath -Type "Success"
        Write-Log -Message "Backup created: $zipPath ($([math]::Round($backupSize, 2)) MB)" -Level "SUCCESS"
        
        return $zipPath
    } catch {
        Write-StatusBox -Title "Backup Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        throw
    }
}

#endregion

#region Disk Space Checks

function Test-DiskSpace {
    <#
    .SYNOPSIS
        Checks available disk space
    .PARAMETER Path
        Path to check disk space for
    .PARAMETER RequiredGB
        Minimum required space in GB
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [int]$RequiredGB = 10
    )
    
    try {
        $drive = (Get-Item $Path -ErrorAction Stop).PSDrive.Name
        $freeSpace = (Get-PSDrive $drive).Free / 1GB
        
        return @{
            Success = $freeSpace -ge $RequiredGB
            FreeSpaceGB = [math]::Round($freeSpace, 2)
            RequiredGB = $RequiredGB
            Drive = $drive
        }
    } catch {
        # If path doesn't exist, check parent
        $parent = Split-Path $Path -Parent
        if ($parent) {
            return Test-DiskSpace -Path $parent -RequiredGB $RequiredGB
        }
        
        # Default to C: drive
        $freeSpace = (Get-PSDrive C).Free / 1GB
        return @{
            Success = $freeSpace -ge $RequiredGB
            FreeSpaceGB = [math]::Round($freeSpace, 2)
            RequiredGB = $RequiredGB
            Drive = "C"
        }
    }
}

#endregion

#region Network Checks

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity to required services
    #>
    
    $tests = @(
        @{Host = "papermc.io"; Port = 443; Service = "PaperMC"},
        @{Host = "api.anthropic.com"; Port = 443; Service = "Anthropic API"},
        @{Host = "www.spigotmc.org"; Port = 443; Service = "SpigotMC"}
    )
    
    $results = @()
    
    foreach ($test in $tests) {
        try {
            $result = Test-NetConnection -ComputerName $test.Host -Port $test.Port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop
            $results += @{
                Service = $test.Service
                Host = $test.Host
                Connected = $result
            }
        } catch {
            $results += @{
                Service = $test.Service
                Host = $test.Host
                Connected = $false
            }
        }
    }
    
    return @{
        AllConnected = ($results | Where-Object { -not $_.Connected }).Count -eq 0
        Results = $results
    }
}

#endregion

#region Port Checks

function Test-PortAvailable {
    <#
    .SYNOPSIS
        Tests if a port is available
    .PARAMETER Port
        Port number to test
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

#endregion

#region File Validation

function Test-FileIntegrity {
    <#
    .SYNOPSIS
        Validates file exists and is readable
    .PARAMETER Path
        Path to file
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        return @{
            Valid = $false
            Reason = "File not found"
        }
    }
    
    try {
        $file = Get-Item $Path -ErrorAction Stop
        
        if ($file.Length -eq 0) {
            return @{
                Valid = $false
                Reason = "File is empty"
            }
        }
        
        return @{
            Valid = $true
            Size = $file.Length
            SizeMB = [math]::Round($file.Length / 1MB, 2)
        }
    } catch {
        return @{
            Valid = $false
            Reason = $_.Exception.Message
        }
    }
}

#endregion

#region Path Validation

function Test-PathSafety {
    <#
    .SYNOPSIS
        Validates path is safe for installation
    .PARAMETER Path
        Path to validate
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    $issues = @()
    
    # Check for spaces
    if ($Path -match '\s') {
        $issues += "Path contains spaces (may cause issues with some plugins)"
    }
    
    # Check for special characters
    if ($Path -match '[^\w\:\\\-\.]') {
        $issues += "Path contains special characters"
    }
    
    # Check path length
    if ($Path.Length -gt 180) {
        $issues += "Path is very long ($($Path.Length) characters)"
    }
    
    # Check if path is in system directory
    $systemPaths = @("C:\Windows", "C:\Program Files", "C:\Program Files (x86)")
    foreach ($sysPath in $systemPaths) {
        if ($Path.StartsWith($sysPath)) {
            $issues += "Path is in system directory (not recommended)"
        }
    }
    
    return @{
        Safe = $issues.Count -eq 0
        Issues = $issues
    }
}

#endregion

#region Cleanup Safety

function Remove-SafeDirectory {
    <#
    .SYNOPSIS
        Safely removes a directory with confirmation
    .PARAMETER Path
        Directory to remove
    .PARAMETER Force
        Skip confirmation
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    if (-not (Test-Path $Path)) {
        return $true
    }
    
    if (-not $Force) {
        $confirm = Read-Confirmation -Message "Are you sure you want to delete $Path?" -DefaultYes:$false
        if (-not $confirm) {
            return $false
        }
    }
    
    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        Write-Log -Message "Removed directory: $Path" -Level "INFO"
        return $true
    } catch {
        Write-LogError -ErrorRecord $_
        return $false
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Test-ExistingInstallation',
    'Invoke-BackupPrompt',
    'Backup-ExistingServer',
    'Test-DiskSpace',
    'Test-NetworkConnectivity',
    'Test-PortAvailable',
    'Test-FileIntegrity',
    'Test-PathSafety',
    'Remove-SafeDirectory'
)
