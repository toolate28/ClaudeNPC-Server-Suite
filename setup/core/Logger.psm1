# Logger.ps1
# Logging system for ClaudeNPC Server Suite
# Version: 1.0.0

#region Module Variables

$script:LogFile = $null
$script:LogPath = $null
$script:SessionId = (Get-Date -Format "yyyyMMdd-HHmmss")

#endregion

#region Initialization

function Initialize-Logger {
    <#
    .SYNOPSIS
        Initializes the logging system
    .PARAMETER LogPath
        Path to store log files
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )
    
    $script:LogPath = $LogPath
    
    # Ensure log directory exists
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    
    # Create session log file
    $script:LogFile = Join-Path $LogPath "setup-$($script:SessionId).log"
    
    # Write header
    $header = @"
================================================================================
ClaudeNPC Server Setup Suite - Installation Log
================================================================================
Session ID: $($script:SessionId)
Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
User: $env:USERNAME
Computer: $env:COMPUTERNAME
OS: $((Get-CimInstance Win32_OperatingSystem).Caption)
PowerShell: $($PSVersionTable.PSVersion.ToString())
================================================================================

"@
    Add-Content -Path $script:LogFile -Value $header
    
    return $script:LogFile
}

#endregion

#region Logging Functions

function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the log file
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        Log level (INFO, SUCCESS, WARNING, ERROR, DEBUG)
    .PARAMETER NoConsole
        Suppress console output
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    if ($script:LogFile) {
        try {
            Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
        } catch {
            # Silently fail if logging fails
        }
    }
    
    # Output to console if not suppressed
    if (-not $NoConsole) {
        $type = switch ($Level) {
            "SUCCESS" { "Success" }
            "ERROR" { "Error" }
            "WARNING" { "Warning" }
            "DEBUG" { "Info" }
            default { "Info" }
        }
        
        $status = switch ($Level) {
            "SUCCESS" { "Complete" }
            "ERROR" { "Failed" }
            "WARNING" { "Warning" }
            "DEBUG" { "Debug" }
            default { "Info" }
        }
        
        # Import Display module for console output
        if (Get-Command Write-StatusBox -ErrorAction SilentlyContinue) {
            Write-StatusBox -Title $Message -Status $status -Type $type
        }
    }
}

function Write-LogSection {
    <#
    .SYNOPSIS
        Writes a section divider to the log
    .PARAMETER Title
        Section title
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    $separator = "=" * 80
    $logEntry = @"

$separator
$Title
$separator

"@
    
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logEntry
    }
}

function Write-LogError {
    <#
    .SYNOPSIS
        Writes error details to log
    .PARAMETER ErrorRecord
        The error record to log
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $errorDetails = @"

ERROR DETAILS:
--------------
Message: $($ErrorRecord.Exception.Message)
Type: $($ErrorRecord.Exception.GetType().FullName)
Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)
Position: $($ErrorRecord.InvocationInfo.OffsetInLine)
Command: $($ErrorRecord.InvocationInfo.MyCommand)
Stack Trace:
$($ErrorRecord.ScriptStackTrace)

"@
    
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $errorDetails
    }
    
    Write-Log -Message "Error occurred: $($ErrorRecord.Exception.Message)" -Level "ERROR"
}

#endregion

#region Log Analysis

function Get-LogSummary {
    <#
    .SYNOPSIS
        Returns a summary of log entries
    #>
    
    if (-not (Test-Path $script:LogFile)) {
        return @{
            Total = 0
            Info = 0
            Success = 0
            Warning = 0
            Error = 0
            Debug = 0
        }
    }
    
    $content = Get-Content $script:LogFile
    
    return @{
        Total = ($content | Where-Object { $_ -match '^\[.*\] \[.*\]' }).Count
        Info = ($content | Select-String -Pattern '\[INFO\]').Count
        Success = ($content | Select-String -Pattern '\[SUCCESS\]').Count
        Warning = ($content | Select-String -Pattern '\[WARNING\]').Count
        Error = ($content | Select-String -Pattern '\[ERROR\]').Count
        Debug = ($content | Select-String -Pattern '\[DEBUG\]').Count
    }
}

function Get-LogErrors {
    <#
    .SYNOPSIS
        Returns all error entries from the log
    #>
    
    if (-not (Test-Path $script:LogFile)) {
        return @()
    }
    
    $errors = Get-Content $script:LogFile | Where-Object { $_ -match '\[ERROR\]' }
    return $errors
}

#endregion

#region Cleanup

function Close-Logger {
    <#
    .SYNOPSIS
        Closes the logger and writes summary
    #>
    param(
        [Parameter(Mandatory=$false)]
        [bool]$Success = $true
    )
    
    $summary = Get-LogSummary
    
    $footer = @"

================================================================================
Session Summary
================================================================================
End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Status: $(if ($Success) { "SUCCESS" } else { "FAILED" })
Total Entries: $($summary.Total)
  - Info: $($summary.Info)
  - Success: $($summary.Success)
  - Warnings: $($summary.Warning)
  - Errors: $($summary.Error)
  - Debug: $($summary.Debug)
================================================================================

"@
    
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $footer
    }
    
    # Cleanup old logs (keep last 30 days)
    if ($script:LogPath) {
        Get-ChildItem $script:LogPath -Filter "setup-*.log" | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-Log',
    'Write-LogSection',
    'Write-LogError',
    'Get-LogSummary',
    'Get-LogErrors',
    'Close-Logger'
)
