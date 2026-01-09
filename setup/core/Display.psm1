# Display.ps1
# UI and display functions for ClaudeNPC Server Suite
# Version: 1.0.0

#region Theme Configuration

$script:Theme = @{
    Primary = "Cyan"
    Secondary = "Magenta"
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Gray"
    Highlight = "White"
    Accent = "DarkCyan"
}

$script:Icons = @{
    Success = "✓"
    Error = "✗"
    Warning = "⚠"
    Info = "ℹ"
    Robot = "🤖"
    Shield = "🛡️"
    Gear = "⚙️"
    Package = "📦"
    Check = "✅"
    Lightning = "⚡"
    Server = "🖥️"
    Lock = "🔒"
}

#endregion

#region Banner Functions

function Show-Banner {
    <#
    .SYNOPSIS
        Displays the HOPE branded banner
    #>
    Clear-Host

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "  ##                                                            ##" -ForegroundColor DarkCyan
    Write-Host "  ##   ##  ##  #####  #####  #####                              ##" -ForegroundColor Cyan
    Write-Host "  ##   ##  ## ##   ## ##  ## ##      " -ForegroundColor Cyan -NoNewline
    Write-Host "NPCs" -ForegroundColor DarkMagenta -NoNewline
    Write-Host "                   ##" -ForegroundColor DarkCyan
    Write-Host "  ##   ###### ##   ## #####  ####                               ##" -ForegroundColor Magenta
    Write-Host "  ##   ##  ## ##   ## ##     ##                                 ##" -ForegroundColor Magenta
    Write-Host "  ##   ##  ##  #####  ##     #####                              ##" -ForegroundColor Magenta
    Write-Host "  ##                                                            ##" -ForegroundColor DarkCyan
    Write-Host "  ##   AI NPCs playing games to redefine reality                ##" -ForegroundColor White
    Write-Host "  ##   Powered by Claude, GPT, Grok, Gemini & more              ##" -ForegroundColor DarkGray
    Write-Host "  ##                                                            ##" -ForegroundColor DarkCyan
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    # Status line
    Write-Host "  " -NoNewline
    Write-Host "[" -ForegroundColor DarkGray -NoNewline
    Write-Host "HOPE" -ForegroundColor Magenta -NoNewline
    Write-Host "]" -ForegroundColor DarkGray -NoNewline
    Write-Host " v2.1.0 " -ForegroundColor White -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " SpiralSafe " -ForegroundColor Cyan -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " H&&S " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host " MC 1.21.3 " -ForegroundColor Green
    Write-Host ""
}

#endregion

#region Status Display Functions

function Write-StatusBox {
    <#
    .SYNOPSIS
        Displays a status message with icon and color
    .PARAMETER Title
        The title of the status
    .PARAMETER Status
        The status text
    .PARAMETER Details
        Optional detailed information
    .PARAMETER Type
        Type of status (Success, Error, Warning, Info, Progress)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Status,
        
        [Parameter(Mandatory=$false)]
        [string]$Details = "",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Success", "Error", "Warning", "Info", "Progress")]
        [string]$Type = "Info"
    )
    
    $icon = switch ($Type) {
        "Success" { $script:Icons.Success }
        "Error" { $script:Icons.Error }
        "Warning" { $script:Icons.Warning }
        "Info" { $script:Icons.Info }
        "Progress" { $script:Icons.Gear }
    }
    
    $color = switch ($Type) {
        "Success" { $script:Theme.Success }
        "Error" { $script:Theme.Error }
        "Warning" { $script:Theme.Warning }
        "Info" { $script:Theme.Info }
        "Progress" { $script:Theme.Primary }
    }
    
    Write-Host "  $icon " -ForegroundColor $color -NoNewline
    Write-Host "$Title" -ForegroundColor $script:Theme.Highlight -NoNewline
    Write-Host " → " -ForegroundColor $script:Theme.Accent -NoNewline
    Write-Host $Status -ForegroundColor $color
    
    if ($Details) {
        Write-Host "     $Details" -ForegroundColor $script:Theme.Info
    }
}

function Write-Section {
    <#
    .SYNOPSIS
        Displays a section header
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Icon = $script:Icons.Gear
    )
    
    Write-Host ""
    Write-Host ("━" * 70) -ForegroundColor $script:Theme.Accent
    Write-Host "  $Icon  " -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Host $Title -ForegroundColor $script:Theme.Highlight
    Write-Host ("─" * 70) -ForegroundColor $script:Theme.Accent
}

function Write-ProgressBar {
    <#
    .SYNOPSIS
        Displays a progress bar
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Current,
        
        [Parameter(Mandatory=$true)]
        [int]$Total,
        
        [Parameter(Mandatory=$true)]
        [string]$Activity,
        
        [Parameter(Mandatory=$false)]
        [string]$Status = ""
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 40
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    
    Write-Host "`r  $bar " -NoNewline -ForegroundColor $script:Theme.Primary
    Write-Host "$percent% " -NoNewline -ForegroundColor $script:Theme.Highlight
    Write-Host "│ $Activity" -NoNewline -ForegroundColor $script:Theme.Info
    if ($Status) {
        Write-Host " → $Status" -NoNewline -ForegroundColor $script:Theme.Accent
    }
}

#endregion

#region Table Functions

function Write-ResultsTable {
    <#
    .SYNOPSIS
        Displays results in a formatted table
    .PARAMETER Data
        Array of hashtables with data
    .PARAMETER Headers
        Array of header names
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Headers
    )
    
    # Calculate column widths
    $widths = @{}
    foreach ($header in $Headers) {
        $widths[$header] = $header.Length
        foreach ($row in $Data) {
            if ($row[$header].ToString().Length -gt $widths[$header]) {
                $widths[$header] = $row[$header].ToString().Length
            }
        }
    }
    
    Write-Host ""
    
    # Header
    Write-Host "  ┌" -NoNewline -ForegroundColor $script:Theme.Accent
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        Write-Host ("─" * ($widths[$Headers[$i]] + 2)) -NoNewline -ForegroundColor $script:Theme.Accent
        if ($i -lt $Headers.Count - 1) {
            Write-Host "┬" -NoNewline -ForegroundColor $script:Theme.Accent
        }
    }
    Write-Host "┐" -ForegroundColor $script:Theme.Accent
    
    # Header text
    Write-Host "  │" -NoNewline -ForegroundColor $script:Theme.Accent
    foreach ($header in $Headers) {
        Write-Host " $($header.PadRight($widths[$header])) " -NoNewline -ForegroundColor $script:Theme.Highlight
        Write-Host "│" -NoNewline -ForegroundColor $script:Theme.Accent
    }
    Write-Host ""
    
    # Separator
    Write-Host "  ├" -NoNewline -ForegroundColor $script:Theme.Accent
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        Write-Host ("─" * ($widths[$Headers[$i]] + 2)) -NoNewline -ForegroundColor $script:Theme.Accent
        if ($i -lt $Headers.Count - 1) {
            Write-Host "┼" -NoNewline -ForegroundColor $script:Theme.Accent
        }
    }
    Write-Host "┤" -ForegroundColor $script:Theme.Accent
    
    # Rows
    foreach ($row in $Data) {
        Write-Host "  │" -NoNewline -ForegroundColor $script:Theme.Accent
        foreach ($header in $Headers) {
            $value = $row[$header].ToString()
            $color = $script:Theme.Info
            
            # Color based on content
            if ($value -match "✓|Pass|Success|Yes|Complete") {
                $color = $script:Theme.Success
            } elseif ($value -match "✗|Fail|Error|No") {
                $color = $script:Theme.Error
            } elseif ($value -match "⚠|Warning|Pending|Missing") {
                $color = $script:Theme.Warning
            }
            
            Write-Host " $($value.PadRight($widths[$header])) " -NoNewline -ForegroundColor $color
            Write-Host "│" -NoNewline -ForegroundColor $script:Theme.Accent
        }
        Write-Host ""
    }
    
    # Footer
    Write-Host "  └" -NoNewline -ForegroundColor $script:Theme.Accent
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        Write-Host ("─" * ($widths[$Headers[$i]] + 2)) -NoNewline -ForegroundColor $script:Theme.Accent
        if ($i -lt $Headers.Count - 1) {
            Write-Host "┴" -NoNewline -ForegroundColor $script:Theme.Accent
        }
    }
    Write-Host "┘" -ForegroundColor $script:Theme.Accent
    Write-Host ""
}

#endregion

#region Prompt Functions

function Read-Confirmation {
    <#
    .SYNOPSIS
        Prompts for yes/no confirmation
    .PARAMETER Message
        The confirmation message
    .PARAMETER DefaultYes
        Whether to default to Yes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [switch]$DefaultYes
    )
    
    $prompt = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    Write-Host "  $Message " -ForegroundColor $script:Theme.Info -NoNewline
    Write-Host $prompt -ForegroundColor $script:Theme.Accent -NoNewline
    Write-Host ": " -NoNewline
    
    $response = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return $response -match '^[Yy]'
}

function Read-Choice {
    <#
    .SYNOPSIS
        Prompts for a choice from multiple options
    .PARAMETER Message
        The prompt message
    .PARAMETER Options
        Hashtable of options (key = choice letter, value = description)
    .PARAMETER Default
        Default choice
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Options,
        
        [Parameter(Mandatory=$false)]
        [string]$Default = ""
    )
    
    Write-Host ""
    Write-Host "  $Message" -ForegroundColor $script:Theme.Info
    Write-Host ""
    
    foreach ($key in $Options.Keys | Sort-Object) {
        $marker = if ($key -eq $Default) { "*" } else { " " }
        Write-Host "    [$key]$marker $($Options[$key])" -ForegroundColor $script:Theme.Primary
    }
    
    Write-Host ""
    $prompt = if ($Default) { "Choice [$Default]" } else { "Choice" }
    Write-Host "  $prompt" -ForegroundColor $script:Theme.Accent -NoNewline
    Write-Host ": " -NoNewline
    
    $choice = Read-Host
    if ([string]::IsNullOrWhiteSpace($choice) -and $Default) {
        return $Default
    }
    
    return $choice.ToUpper()
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Show-Banner',
    'Write-StatusBox',
    'Write-Section',
    'Write-ProgressBar',
    'Write-ResultsTable',
    'Read-Confirmation',
    'Read-Choice'
)
