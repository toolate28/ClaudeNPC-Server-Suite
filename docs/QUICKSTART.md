# HOPE NPCs - Quick Start Guide

**Part of the [SpiralSafe Ecosystem](https://github.com/toolate28/SpiralSafe)**

**Version:** 2.1.0 SpiralSafe Edition

Get your AI-powered Minecraft NPC server running in minutes.

---

## Prerequisites

Before you begin, ensure you have:

- **Windows 10/11** with PowerShell 5.1+
- **Administrator access** for installation
- **Internet connection** for downloads
- **8GB+ RAM** recommended
- **10GB+ free disk space**

---

## Installation (3 Steps)

### Step 1: Download

```powershell
# Clone the repository
git clone https://github.com/toolate28/ClaudeNPC-Server-Suite.git
cd ClaudeNPC-Server-Suite
```

Or download the ZIP from GitHub and extract it.

### Step 2: Run Installer

```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File INSTALL.ps1
```

The installer will:
1. Check prerequisites
2. Install Java 21 if needed
3. Download PaperMC server
4. Install required plugins (Citizens, Vault, LuckPerms)
5. Configure the ClaudeNPC plugin

### Step 3: Configure API Key

Edit `plugins/ClaudeNPC/config.yml`:

```yaml
api:
  key: "YOUR_ANTHROPIC_API_KEY"
  model: "claude-sonnet-4-20250514"
```

Get your API key from [console.anthropic.com](https://console.anthropic.com)

---

## Start the Server

```powershell
# From the server directory
.\start.bat
```

Or manually:
```powershell
java -Xmx4G -Xms2G -jar paper.jar nogui
```

---

## Create Your First NPC

1. Join your server: `localhost:25565`
2. Run in-game commands:

```
/npc create MyGuide
/npc select
/cnpc set personality friendly helpful curious
/cnpc set greeting "Hello traveler! How can I help you today?"
```

3. Right-click the NPC to chat!

---

## Install Profiles

Choose your setup level:

| Profile | Plugins | Use Case |
|---------|---------|----------|
| **Minimal** | Citizens, ClaudeNPC | Testing only |
| **Standard** | + Vault, LuckPerms | Most servers |
| **Full** | + WorldEdit, WorldGuard, EssentialsX | Production |

```powershell
# Specify during install
.\INSTALL.ps1 -InstallProfile Full
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `server.properties` | Minecraft server settings |
| `plugins/ClaudeNPC/config.yml` | API and NPC defaults |
| `plugins/Citizens/config.yml` | NPC spawn settings |

---

## Verify Installation

Run the test suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File test-core-modules.ps1
```

Expected output:
```
Display.psm1: PASS
Logger.psm1: PASS
Safety.psm1: PASS
Config.psm1: PASS

ALL CORE MODULES PASSED!
```

---

## SpiralSafe Integration (Optional)

For advanced AI orchestration:

```powershell
# Add to your PowerShell profile
$env:SPIRALSAFE_API_BASE = "https://api.spiralsafe.org"
```

Features:
- **Wave analysis** - Check NPC dialogue coherence
- **Bump routing** - Hand off conversations between NPCs
- **AWI permissions** - Fine-grained Claude API access control

---

## Troubleshooting

### "Java not found"
```powershell
# Install Java 21 manually
winget install Microsoft.OpenJDK.21
```

### "Port 25565 in use"
Edit `server.properties`:
```
server-port=25566
```

### "API rate limited"
Reduce NPC response frequency in `config.yml`:
```yaml
rate_limit:
  requests_per_minute: 10
  cooldown_seconds: 5
```

---

## Next Steps

- Read the [full documentation](README.md)
- Explore [NPC personality templates](docs/PERSONALITIES.md)
- Join the [Discord community](#)
- Check out [example worlds](examples/)

---

**Built with SAIF Methodology | Powered by [SpiralSafe](https://github.com/toolate28/SpiralSafe) | H&&S**
