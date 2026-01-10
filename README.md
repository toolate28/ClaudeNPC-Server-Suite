# 🎮 HOPE NPCs - AI NPCs Playing Games to Redefine Reality

**Part of the SpiralSafe Ecosystem**

[![SpiralSafe](https://img.shields.io/badge/🌀_SpiralSafe-Coherence_Engine-purple?style=for-the-badge)](https://github.com/toolate28/SpiralSafe)
[![Version](https://img.shields.io/badge/Version-v2.1.0-blue?style=flat-square)](https://github.com/toolate28/ClaudeNPC-Server-Suite/releases)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen?style=flat-square)]()

**Version:** v2.1.0 SpiralSafe Edition  
**Last Updated:** January 9, 2026  
**Status:** Production Ready

---

## 🌟 What is HOPE NPCs?

HOPE NPCs (Human-Operated Personality Engines) transforms Minecraft NPCs into intelligent conversational partners powered by AI. This repository provides:

- **Minecraft Plugin:** AI-powered NPCs using Claude API with multi-provider support
- **Modular Setup Framework:** PowerShell-based server deployment with SAIF methodology
- **SpiralSafe Integration:** Coherence detection and conversation quality analysis

> *"AI NPCs playing games to redefine reality"* — Hope&&Sauced

---

## 🌀 The SpiralSafe Ecosystem

This repository is part of a unified framework for human-AI collaboration:

| Repository | Purpose | Status |
|------------|---------|--------|
| **[SpiralSafe](https://github.com/toolate28/SpiralSafe)** | Documentation hub, coherence engine core | v1.0.0 |
| **[HOPE NPCs](https://github.com/toolate28/ClaudeNPC-Server-Suite)** | AI NPCs for Minecraft (this repo) | v2.1.0 |
| **[wave-toolkit](https://github.com/toolate28/wave-toolkit)** | Coherence detection tools | Available |
| **[kenl](https://github.com/toolate28/kenl)** | Infrastructure-aware AI orchestration | v1.0.0 |
| **[quantum-redstone](https://github.com/toolate28/quantum-redstone)** | Quantum computing education via Redstone | Available |

### 📦 Additional AI Provider Plugins

Support for additional AI providers is available as separate packages:

| Provider | Package | Status |
|----------|---------|--------|
| **xAI/Grok** | `spiralsafe-grok` | Coming to pip/npm |
| **OpenAI/GPT** | `spiralsafe-openai` | Coming to pip/npm |
| **Google/Gemini** | `spiralsafe-gemini` | Coming to pip/npm |
| **Azure OpenAI** | `spiralsafe-azure` | Coming to pip/npm |
| **LLaMA/Ollama** | `spiralsafe-ollama` | Coming to pip/npm |

> Provider plugins will be published as standalone packages for pip/npm installation. Watch the [SpiralSafe releases](https://github.com/toolate28/SpiralSafe/releases) for announcements.

---

## 🎯 Project Overview

This is a **complete refactoring** of the ClaudeNPC server setup into a modular, maintainable framework using the **SAIF methodology**. Each component is self-contained, testable, and can be dropped in or modified independently.

### Architecture Philosophy

```
┌─────────────────────────────────────────────────────────────┐
│                     Main Orchestrator                       │
│                       (Setup.ps1)                           │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼───┐          ┌───▼───┐          ┌───▼───┐
    │ Core  │          │Phases │          │Configs│
    │Modules│          │Modules│          │& Data │
    └───────┘          └───────┘          └───────┘
        │                   │                   │
  ┌─────┼─────┐       ┌─────┼─────┐       ┌─────┼─────┐
  │     │     │       │     │     │       │     │     │
Display Logger Safety  Pre  Java Plugin Templates Profiles
               Config flight Setup Install
```

---

## 📂 Project Structure

```
claudenpc-server-suite/
│
├── 📂 setup/                      # Setup framework
│   ├── 📂 core/                   # Core functionality modules
│   │   ├── Display.ps1            # ✅ UI/Display functions
│   │   ├── Logger.ps1             # ✅ Logging system
│   │   ├── Safety.ps1             # ✅ Safety & validation
│   │   └── Config.ps1             # ✅ Configuration management
│   │
│   ├── 📂 phases/                 # Installation phases (drop-in)
│   │   ├── 01-Preflight.ps1       # Prerequisites check
│   │   ├── 02-Java.ps1            # Java installation
│   │   ├── 03-PaperMC.ps1         # Server installation
│   │   ├── 04-Plugins.ps1         # Plugin installation
│   │   └── 05-Configure.ps1       # Final configuration
│   │
│   └── 📄 Setup.ps1               # ✅ Main orchestrator
│
├── 📂 scripts/                    # Utility scripts
│   ├── Start-Server.bat           # Server launcher
│   ├── Backup-Server.ps1          # Backup automation
│   ├── Monitor-Server.ps1         # Health monitoring
│   └── Test-Server.ps1            # Validation suite
│
├── 📂 configs/                    # Configuration files
│   ├── 📂 templates/              # Config templates
│   │   ├── server.properties.template
│   │   ├── paper-global.yml.template
│   │   └── claudenpc.yml.template
│   │
│   └── 📂 profiles/               # Install profiles
│       ├── minimal.json           # Minimal install
│       ├── standard.json          # Standard install
│       └── full.json              # Full install
│
├── 📂 docs/                       # Documentation
│   ├── SETUP.md                   # Setup guide
│   ├── QUICKSTART.md              # Quick start
│   ├── MODULES.md                 # Module documentation
│   └── TROUBLESHOOTING.md         # Common issues
│
└── 📂 tools/                      # Helper tools
    ├── plugin-downloader.ps1      # Plugin downloader
    └── config-validator.ps1       # Config validator
```

---

## 🚀 Quick Start

### Option 1: Run the Framework (Demo Mode)

```powershell
# Clone or download the project
cd claudenpc-server-suite\setup

# Run setup (administrator required)
.\Setup.ps1

# Or with options:
.\Setup.ps1 -InstallProfile Standard -Unattended
```

### Option 2: Drop-In Module Usage

```powershell
# Use individual modules in your own scripts
. .\setup\core\Display.ps1
. .\setup\core\Logger.ps1

Show-Banner
Write-StatusBox -Title "My Task" -Status "Complete" -Type "Success"
```

---

## 📦 Core Modules Reference

### Display.ps1

**Purpose:** UI and display functions with consistent branding

**Key Functions:**
```powershell
Show-Banner                    # Display branded banner
Write-StatusBox               # Status messages with icons
Write-Section                 # Section headers
Write-ProgressBar             # Progress indication
Write-ResultsTable            # Formatted tables
Read-Confirmation             # Yes/no prompts
Read-Choice                   # Multiple choice prompts
```

**Example Usage:**
```powershell
. .\setup\core\Display.ps1

Show-Banner
Write-Section -Title "My Process" -Icon "🔧"
Write-StatusBox -Title "File Processing" -Status "Complete" -Type "Success"

$proceed = Read-Confirmation -Message "Continue?" -DefaultYes
if ($proceed) {
    # Do something
}
```

---

### Logger.ps1

**Purpose:** Centralized logging with file and console output

**Key Functions:**
```powershell
Initialize-Logger             # Set up logging
Write-Log                     # Log messages
Write-LogSection              # Log section dividers
Write-LogError                # Log detailed errors
Get-LogSummary                # Get log statistics
Close-Logger                  # Finalize log
```

**Example Usage:**
```powershell
. .\setup\core\Logger.ps1

$logFile = Initialize-Logger -LogPath "C:\Logs"

Write-Log -Message "Starting process" -Level "INFO"
Write-Log -Message "Task complete" -Level "SUCCESS"

try {
    # Something risky
} catch {
    Write-LogError -ErrorRecord $_
}

Close-Logger -Success $true
```

---

### Safety.ps1

**Purpose:** Safety checks, validation, and backup operations

**Key Functions:**
```powershell
Test-ExistingInstallation     # Check for existing files
Backup-ExistingServer         # Create backups
Test-DiskSpace                # Check available space
Test-NetworkConnectivity      # Check network
Test-PortAvailable            # Check port availability
Test-FileIntegrity            # Validate files
Test-PathSafety               # Validate paths
```

**Example Usage:**
```powershell
. .\setup\core\Safety.ps1

$existing = Test-ExistingInstallation -ServerPath "C:\Server"
if ($existing.Exists) {
    $backup = Backup-ExistingServer -ServerPath "C:\Server" -BackupPath "C:\Backups"
    Write-Host "Backup created: $backup"
}

$diskCheck = Test-DiskSpace -Path "C:\Server" -RequiredGB 10
if (-not $diskCheck.Success) {
    Write-Host "Insufficient disk space!"
}
```

---

### Config.ps1

**Purpose:** Configuration management and validation

**Key Functions:**
```powershell
Get-DefaultConfiguration      # Get default config
Import-Configuration          # Load from JSON
Export-Configuration          # Save to JSON
Get-UserConfiguration         # Interactive setup
Get-InstallProfile            # Get profile info
Test-Configuration            # Validate config
Get-RecommendedMemory         # Memory recommendations
```

**Example Usage:**
```powershell
. .\setup\core\Config.ps1

# Get default configuration
$config = Get-DefaultConfiguration

# Or load from file
$config = Import-Configuration -Path ".\config.json"

# Validate
$validation = Test-Configuration -Config $config
if (-not $validation.Valid) {
    Write-Host "Issues found:"
    $validation.Issues | ForEach-Object { Write-Host "  - $_" }
}

# Save
Export-Configuration -Config $config -Path ".\my-config.json"
```

---

## 🔧 Creating Phase Modules

Phase modules follow a standard pattern:

```powershell
# 01-Preflight.ps1
function Invoke-PreflightChecks {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$SkipPreflight
    )
    
    Write-Section -Title "Preflight Checks" -Icon "✓"
    
    # Your phase logic here
    
    Write-Log -Message "Preflight checks complete" -Level "SUCCESS"
}

# Export the main function
Export-ModuleMember -Function Invoke-PreflightChecks
```

### Phase Module Template

```powershell
# XX-PhaseName.ps1
# Description of what this phase does
# Version: 1.0.0

function Invoke-PhaseName {
    <#
    .SYNOPSIS
        Brief description of phase
    .PARAMETER Config
        Configuration hashtable
    .PARAMETER SomeOption
        Optional parameters
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [switch]$SomeOption
    )
    
    Write-Section -Title "Phase Name" -Icon "🔧"
    Write-Log -Message "Starting Phase Name" -Level "INFO"
    
    try {
        # Phase logic here
        Write-StatusBox -Title "Step 1" -Status "Complete" -Type "Success"
        Write-Log -Message "Step 1 complete" -Level "SUCCESS"
        
        # More steps...
        
        return $true
    } catch {
        Write-StatusBox -Title "Phase Failed" -Status $_.Exception.Message -Type "Error"
        Write-LogError -ErrorRecord $_
        return $false
    }
}

Export-ModuleMember -Function Invoke-PhaseName
```

---

## 🎨 Customizing Appearance

### Changing Colors

Edit `setup/core/Display.ps1`:

```powershell
$script:Theme = @{
    Primary = "Blue"           # Change from Cyan
    Secondary = "Yellow"       # Change from Magenta
    Success = "Green"          # Keep green
    Error = "Red"              # Keep red
    Warning = "Yellow"         # Keep yellow
    Info = "White"             # Change from Gray
    Highlight = "Cyan"         # Change from White
    Accent = "DarkBlue"        # Change from DarkCyan
}
```

### Changing Icons

```powershell
$script:Icons = @{
    Success = "✓"             # Or use "✔", "[OK]"
    Error = "✗"               # Or use "✘", "[FAIL]"
    Warning = "⚠"             # Or use "!", "[WARN]"
    # Add your own custom icons
    Custom = "🎯"
}
```

---

## 🧪 Testing Individual Modules

Each module can be tested independently:

```powershell
# Test Display module
. .\setup\core\Display.ps1
Show-Banner
Write-StatusBox -Title "Test" -Status "Working" -Type "Success"

# Test Logger module
. .\setup\core\Logger.ps1
Initialize-Logger -LogPath ".\test-logs"
Write-Log -Message "Test log entry" -Level "INFO"

# Test Safety module
. .\setup\core\Safety.ps1
$diskCheck = Test-DiskSpace -Path "C:\" -RequiredGB 10
Write-Host "Free space: $($diskCheck.FreeSpaceGB) GB"

# Test Config module
. .\setup\core\Config.ps1
$config = Get-DefaultConfiguration
$validation = Test-Configuration -Config $config
Write-Host "Valid: $($validation.Valid)"
```

---

## 📝 Configuration Files

### Server Config Template (`configs/templates/server.properties.template`)

```properties
# Minecraft Server Properties
# Generated by ClaudeNPC Server Suite

server-port={{ServerPort}}
max-players={{MaxPlayers}}
view-distance={{ViewDistance}}
simulation-distance={{SimulationDistance}}
gamemode={{Gamemode}}
difficulty={{Difficulty}}
online-mode={{OnlineMode}}
pvp={{PVP}}
motd=ClaudeNPC Server - AI Powered NPCs
```

### Install Profile (`configs/profiles/standard.json`)

```json
{
  "name": "Standard",
  "description": "Core plugins + security + ClaudeNPC",
  "plugins": [
    {
      "name": "Citizens",
      "version": "2.0.35",
      "url": "https://ci.citizensnpcs.co/job/Citizens2/lastSuccessfulBuild/",
      "required": true
    },
    {
      "name": "Vault",
      "version": "1.7.3",
      "url": "https://www.spigotmc.org/resources/vault.34315/",
      "required": true
    },
    {
      "name": "LuckPerms",
      "version": "5.4.x",
      "url": "https://luckperms.net/download",
      "required": true
    }
  ]
}
```

---

## 🛠️ Integration Guide

### Adding to Existing Scripts

```powershell
# Your existing script
param()

# Add module path to PSModulePath temporarily
$modulePath = "C:\path\to\claudenpc-server-suite\setup\core"
$env:PSModulePath += ";$modulePath"

# Or use dot-sourcing
. "$modulePath\Display.ps1"
. "$modulePath\Logger.ps1"

# Now use the functions
Show-Banner
Write-StatusBox -Title "Integration" -Status "Success" -Type "Success"
```

### Creating Custom Workflows

```powershell
# custom-workflow.ps1

# Load required modules
. .\setup\core\Display.ps1
. .\setup\core\Logger.ps1
. .\setup\core\Config.ps1

# Initialize
Show-Banner
$logFile = Initialize-Logger -LogPath ".\logs"

# Load configuration
$config = Import-Configuration -Path ".\my-config.json"

# Custom logic
Write-Section -Title "Custom Workflow" -Icon "🔥"

# Step 1
Write-StatusBox -Title "Step 1" -Status "Processing" -Type "Progress"
# Do work
Write-StatusBox -Title "Step 1" -Status "Complete" -Type "Success"

# Step 2
Write-StatusBox -Title "Step 2" -Status "Processing" -Type "Progress"
# Do work
Write-StatusBox -Title "Step 2" -Status "Complete" -Type "Success"

# Finalize
Close-Logger -Success $true
```

---

## 🎯 Best Practices

### 1. **Module Independence**
- Each module should work standalone
- Import only what you need
- Use clear function names

### 2. **Error Handling**
```powershell
try {
    # Risky operation
} catch {
    Write-StatusBox -Title "Operation Failed" -Status $_.Exception.Message -Type "Error"
    Write-LogError -ErrorRecord $_
    return $false
}
```

### 3. **Configuration Validation**
```powershell
# Always validate before using
$config = Import-Configuration -Path $ConfigFile
$validation = Test-Configuration -Config $config

if (-not $validation.Valid) {
    foreach ($issue in $validation.Issues) {
        Write-StatusBox -Title "Config Issue" -Status $issue -Type "Error"
    }
    exit 1
}
```

### 4. **Logging Everything**
```powershell
Write-Log -Message "Starting important operation" -Level "INFO"
# Do operation
Write-Log -Message "Operation complete" -Level "SUCCESS"
```

### 5. **User Feedback**
```powershell
# Always show progress
Write-StatusBox -Title "Processing files" -Status "In Progress" -Type "Progress"
# Do work
Write-StatusBox -Title "Files processed" -Status "Complete" -Type "Success"
```

---

## 🔍 Debugging

### Enable Verbose Logging

```powershell
$VerbosePreference = "Continue"
.\Setup.ps1 -Verbose
```

### Check Log Files

```powershell
# View latest log
Get-Content (Get-ChildItem .\logs -Filter "setup-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

### Test Modules Individually

```powershell
# Test a specific module
. .\setup\core\Safety.ps1

# Run function with test data
$result = Test-DiskSpace -Path "C:\" -RequiredGB 10
$result | Format-List
```

---

## 🌀 SpiralSafe API Integration

ClaudeNPC v2.1.0 integrates with the SpiralSafe coherence engine for enhanced AI orchestration.

### API Endpoints

| Endpoint | Purpose | Use Case |
|----------|---------|----------|
| `/api/wave` | Coherence detection | Analyze NPC dialogue for quality |
| `/api/bump` | Handoff routing | Transfer conversations between NPCs |
| `/api/awi` | Permission scaffolding | Grant Claude API access with intent |
| `/api/atom` | Task orchestration | Track NPC behavior atoms |
| `/api/context` | Knowledge units | Store/retrieve NPC personalities |
| `/api/health` | System status | Monitor API health |

### Configuration

Add to your `claudenpc.yml`:

```yaml
spiralsafe:
  api_base: "https://api.spiralsafe.org"
  enabled: true
  wave:
    auto_analyze: true
    curl_threshold: 0.3
    divergence_threshold: 0.4
  awi:
    default_level: 2
    require_intent: true
```

### PowerShell Integration

```powershell
# Add to $PROFILE for CLI access
$env:SPIRALSAFE_API_BASE = "https://api.spiralsafe.org"
Import-Module "$env:USERPROFILE\Repos\spiralsafe-ops\scripts\SpiralSafe.psm1"

# Quick commands
ss-status           # Check API health
ss-wave <file>      # Analyze document coherence
ss-bump create      # Create handoff marker
```

---

## 📚 Additional Resources

- **Module Documentation:** See `docs/MODULES.md`
- **Phase Development:** See `docs/PHASES.md`
- **Quick Start Guide:** See `docs/QUICKSTART.md`
- **Project Roadmap:** See `docs/ROADMAP.md`
- **SpiralSafe Core:** See [SpiralSafe Repository](https://github.com/toolate28/SpiralSafe)
- **Wave Toolkit:** See [wave-toolkit Repository](https://github.com/toolate28/wave-toolkit)

---

## 🤝 Contributing

### Adding a New Module

1. Create module file in `setup/core/` or `setup/phases/`
2. Follow the module template pattern
3. Add module documentation to this README
4. Test independently
5. Update `Setup.ps1` to import if needed

### Module Checklist

- [ ] Clear, descriptive function names
- [ ] Parameter validation
- [ ] Error handling with try/catch
- [ ] Logging with Write-Log
- [ ] Status display with Write-StatusBox
- [ ] Export-ModuleMember at end
- [ ] Comments and documentation
- [ ] Independent testing passed

---

## 📊 Module Status

| Module | Status | Documentation | Tests |
|--------|--------|---------------|-------|
| Display.psm1 | ✅ Complete | ✅ Yes | ✅ Passing |
| Logger.psm1 | ✅ Complete | ✅ Yes | ✅ Passing |
| Safety.psm1 | ✅ Complete | ✅ Yes | ✅ Passing |
| Config.psm1 | ✅ Complete | ✅ Yes | ✅ Passing |
| 01-Preflight.ps1 | ⏳ Template | ⏳ Pending | ⏳ Pending |
| 02-Java.ps1 | ⏳ Template | ⏳ Pending | ⏳ Pending |
| 03-PaperMC.ps1 | ⏳ Template | ⏳ Pending | ⏳ Pending |
| 04-Plugins.ps1 | ⏳ Template | ⏳ Pending | ⏳ Pending |
| 05-Configure.ps1 | ⏳ Template | ⏳ Pending | ⏳ Pending |

---

## 🎉 Summary

This modular framework provides:

✅ **Reusable Components** - Drop modules into any project
✅ **Consistent UI** - Branded, professional appearance
✅ **Comprehensive Logging** - Track everything
✅ **Safety First** - Validation and backups
✅ **Easy Testing** - Test modules independently
✅ **Extensible** - Add phases and modules easily
✅ **Well Documented** - Clear examples and patterns
✅ **SpiralSafe Integration** - Coherence engine for AI orchestration

**Start building with:** `.\Setup.ps1`

**Report issues:** Create an issue in the repository
**Contribute:** Follow the contributing guide above

---

## Attribution

This work emerges from **Hope&&Sauced** collaboration—human-AI partnership where both contributions are substantive and neither party could have produced the result alone.

See the [SpiralSafe PORTFOLIO.md](https://github.com/toolate28/SpiralSafe/blob/main/PORTFOLIO.md) for complete showcase of the ecosystem.

---

*~ Hope&&Sauced*

✦ *The Evenstar Guides Us* ✦

**Built with SAIF Methodology • Powered by [SpiralSafe](https://github.com/toolate28/SpiralSafe) • H&&S**
