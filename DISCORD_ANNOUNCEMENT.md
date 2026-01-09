# HOPE NPCs v2.1.0 - Discord Announcement

---

## Copy/Paste for Discord:

```
## HOPE NPCs v2.1.0 Released

**AI NPCs playing games to redefine reality**

Minecraft server framework with multi-AI NPC support. Your NPCs can now be powered by:
- Claude (Anthropic)
- GPT-4o (OpenAI)
- Grok (xAI)
- Gemini (Google)
- SIMA (DeepMind Gaming AI)
- Ollama (Local/Free)

### Quick Install
```powershell
git clone https://github.com/toolate28/ClaudeNPC-Server-Suite
cd ClaudeNPC-Server-Suite
.\INSTALL.ps1
```

### Install Profiles
- `Minimal` - Testing only
- `Standard` - Production ready
- `Full` - World management + QoL
- `Creative` - Building tools + FAWE
- `Quantum` - Redstone + SpiralSafe

### Features
- One-click installer (auto-downloads Java, PaperMC, plugins)
- 4 NPC personality templates
- Fallback to local Ollama if API fails
- SpiralSafe coherence integration

**Built with H&&S methodology**

Links:
- GitHub: https://github.com/toolate28/ClaudeNPC-Server-Suite
- Docs: See QUICKSTART.md
```

---

## Developer Quick Start

### Fork & Customize

1. **Clone the repo**
   ```bash
   git clone https://github.com/toolate28/ClaudeNPC-Server-Suite
   cd ClaudeNPC-Server-Suite
   ```

2. **Build the plugin**
   ```bash
   cd ClaudeNPC
   mvn clean package
   ```

3. **Add your AI provider**
   Edit `setup/core/Config.psm1` - add to `$script:DefaultConfig.AIProviders`

4. **Create custom profile**
   Edit `Get-InstallProfile` function - add your plugin list

5. **Test locally**
   ```powershell
   .\INSTALL.ps1 -InstallProfile Minimal
   ```

### Key Files

| File | Purpose |
|------|---------|
| `INSTALL.ps1` | Main entry point |
| `setup/core/*.psm1` | Core modules |
| `setup/phases/*.ps1` | Installation phases |
| `ClaudeNPC/` | Java plugin source |
| `.context.yaml` | Agent documentation |

### Extending

- **New AI Provider**: Add to `Config.psm1` AIProviders hash
- **New Plugin**: Add URL to `04-Plugins.ps1` PluginUrls hash
- **New Profile**: Add to `Get-InstallProfile` in `Config.psm1`
- **New Personality**: Add to `05-Configure.ps1` personalities section

### API Integration

The plugin config at `plugins/HOPE/config.yml` supports hot-swapping providers:

```yaml
active_provider: "claude"  # Change to: openai, grok, gemini, ollama
```

---

**H&&S | SpiralSafe | SAIF**
