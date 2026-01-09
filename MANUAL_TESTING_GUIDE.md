---
version: 1.0.0
Date: 2026-01-05
Status: Ready for Testing
---
# ClaudeNPC Manual Testing Guide

## Quick Start (15 minutes to first NPC conversation)

### Prerequisites

- Windows 10/11
- Java 17+ installed
- Maven installed (or use included wrapper)
- Claude API key from console.anthropic.com
- Minecraft Java Edition 1.20.1

### Step 1: Build the Plugin (5 minutes)

```powershell
cd C:\Users\iamto\repos\ClaudeNPC-Server-Suite\ClaudeNPC

# Build with Maven
mvn clean package

# Output: target/ClaudeNPC.jar (should be ~50KB)
```

**Expected Output:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: 15.234 s
```

### Step 2: Install PaperMC Server (5 minutes)

**Option A: Use Modular Setup Framework (Automated)**

```powershell
cd C:\Users\iamto\repos\ClaudeNPC-Server-Suite\modular-setup

# Run installer with testing profile
.\Install-PaperMC.ps1 -Profile testing -ServerPath "C:\Users\iamto\minecraft-test-server"
```

**Option B: Manual Installation**

1. Download PaperMC 1.20.1:
   ```powershell
   mkdir C:\Users\iamto\minecraft-test-server
   cd C:\Users\iamto\minecraft-test-server

   # Download latest Paper 1.20.1 build
   curl -o paper.jar https://api.papermc.io/v2/projects/paper/versions/1.20.1/builds/196/downloads/paper-1.20.1-196.jar
   ```

2. Accept EULA:
   ```powershell
   echo "eula=true" > eula.txt
   ```

3. Create startup script `start-server.bat`:
   ```batch
   @echo off
   java -Xms2G -Xmx4G -jar paper.jar nogui
   pause
   ```

### Step 3: Install Citizens Plugin

1. Download Citizens from: https://ci.citizensnpcs.co/job/Citizens2/
2. Place `Citizens.jar` in `plugins/` folder
3. Start server once to generate Citizens config:
   ```powershell
   .\start-server.bat
   ```
4. Stop server (type `stop` in console)

### Step 4: Install ClaudeNPC Plugin

1. Copy the built plugin:
   ```powershell
   copy C:\repos\ClaudeNPC-Server-Suite\ClaudeNPC\target\ClaudeNPC.jar plugins\
   ```

2. Configure API key:
   ```powershell
   # Create plugins/ClaudeNPC/config.yml
   mkdir plugins\ClaudeNPC
   ```

   Edit `plugins\ClaudeNPC\config.yml`:
   ```yaml
   api:
     key: "sk-ant-api03-YOUR-KEY-HERE"
     model: "claude-sonnet-4-5-20250929"
     max_tokens: 1024
     temperature: 1.0

   npc:
     default_personality: "You are a helpful villager in a Minecraft world. Respond concisely."
     conversation_timeout: 300000  # 5 minutes
     max_history: 10

   logging:
     level: INFO
     log_conversations: true
   ```

### Step 5: Start Server and Test (5 minutes)

1. Start server:
   ```powershell
   .\start-server.bat
   ```

2. Wait for "Done!" message in console

3. Join server:
   - Open Minecraft
   - Multiplayer → Direct Connect
   - Address: `localhost:25565`

4. Create a Claude NPC:
   ```
   /npc create ClaudeGuide
   /npc select
   /claudenpc enable
   ```

5. Test conversation:
   - Right-click the NPC
   - Type in chat: "Hello! What can you tell me about this village?"
   - NPC should respond using Claude API

---

## Testing Checklist

### Basic Functionality

- [ ] Plugin loads without errors
- [ ] Citizens dependency detected
- [ ] Config file created/loaded
- [ ] Can create NPC with `/npc create`
- [ ] Can enable Claude on NPC with `/claudenpc enable`
- [ ] Right-clicking NPC initiates conversation
- [ ] NPC responds to chat messages
- [ ] Conversation history maintained (up to 10 messages)
- [ ] Conversation times out after 5 minutes of inactivity

### API Integration

- [ ] API requests succeed (check server log)
- [ ] Response time < 5 seconds
- [ ] Proper error handling for invalid API key
- [ ] Proper error handling for network errors
- [ ] Proper error handling for rate limits

### Configuration

- [ ] Custom personality works
- [ ] Model selection works (opus, sonnet, haiku)
- [ ] Max tokens respected
- [ ] Temperature setting applied
- [ ] Conversation timeout setting works

### Edge Cases

- [ ] NPC handles rapid-fire messages
- [ ] Multiple players can talk to same NPC
- [ ] Multiple NPCs work simultaneously
- [ ] Server restart preserves NPC configurations
- [ ] Plugin reload works (`/reload confirm`)

---

## Common Issues and Solutions

### Issue: "Citizens plugin not found!"

**Cause:** Citizens not installed or wrong version
**Solution:**
```powershell
# Download Citizens 2.0.35 for 1.20.1
cd plugins
curl -o Citizens.jar https://ci.citizensnpcs.co/job/Citizens2/lastSuccessfulBuild/artifact/dist/target/Citizens-2.0.35-SNAPSHOT.jar
```

### Issue: "Invalid API key"

**Cause:** API key not configured or incorrect
**Solution:**
1. Get API key from https://console.anthropic.com/settings/keys
2. Update `plugins/ClaudeNPC/config.yml`
3. Restart server or `/reload confirm`

### Issue: NPC doesn't respond

**Troubleshooting:**
1. Check server console for errors
2. Verify NPC is enabled: `/claudenpc status`
3. Check network connectivity
4. Verify API key has credits: https://console.anthropic.com/settings/billing

### Issue: "java.lang.ClassNotFoundException"

**Cause:** Maven build failed or incomplete
**Solution:**
```powershell
cd ClaudeNPC
mvn clean package -U  # Force update dependencies
```

### Issue: Server crashes on startup

**Cause:** Incompatible Java version
**Solution:**
```powershell
# Check Java version
java -version

# Should be 17 or higher
# If not, download from: https://adoptium.net/
```

---

## Advanced Testing

### Custom Personalities

Create specialized NPCs:

**Quest Giver:**
```yaml
npc:
  default_personality: "You are Thorin, a grizzled warrior who gives epic quests. Speak in a dramatic, fantasy style. Offer challenging missions to brave adventurers."
```

**Merchant:**
```yaml
npc:
  default_personality: "You are a shrewd merchant named Marcus. You love to haggle and always try to make a profit. Be friendly but business-minded."
```

**Lore Master:**
```yaml
npc:
  default_personality: "You are an ancient wizard who knows the deep lore of this Minecraft world. Speak mysteriously about the history of structures and biomes."
```

### Multi-NPC Scenarios

Test with multiple NPCs having different roles:

```
/npc create Warrior -t player
/npc select
/claudenpc enable
/claudenpc setpersonality You are a brave warrior. Short, action-oriented responses.

/npc create Scholar -t player
/npc select
/claudenpc enable
/claudenpc setpersonality You are a wise scholar. Thoughtful, detailed explanations.

/npc create Merchant -t player
/npc select
/claudenpc enable
/claudenpc setpersonality You are a merchant. Focus on trades and business.
```

### Performance Testing

**Stress Test: 10 Concurrent Conversations**

```powershell
# Run this Python script to simulate multiple players

import requests
import threading

def talk_to_npc(player_name, message):
    # Simulate right-click + chat interaction
    # This would require a Minecraft protocol library like pycraft
    pass

threads = []
for i in range(10):
    t = threading.Thread(target=talk_to_npc, args=(f"Player{i}", "Hello!"))
    threads.append(t)
    t.start()

for t in threads:
    t.join()
```

---

## Integration with SpiralSafe Bridges

### ATOM Trail Logging

Enable ATOM trail logging for NPC conversations:

1. Install SpiralSafe bridges:
   ```powershell
   cd C:\Users\iamto\SpiralSafe-FromGitHub\bridges
   pip install -r requirements.txt
   ```

2. Configure ClaudeNPC to write ATOM entries:

   Add to `plugins/ClaudeNPC/config.yml`:
   ```yaml
   atom:
     enabled: true
     trail_path: "C:/Users/iamto/minecraft-npc.atom"
   ```

3. Watch ATOM trail in real-time:
   ```powershell
   python -c "
   import asyncio
   from atom import ATOMReader

   async def watch():
       reader = ATOMReader('C:/Users/iamto/minecraft-npc.atom')
       async for entry in reader.stream():
           print(f'[{entry.entry_type}] {entry.message}')

   asyncio.run(watch())
   "
   ```

### Hologram Visualization

Display NPC conversations on 3D hologram:

```powershell
cd C:\Users\iamto\SpiralSafe-FromGitHub\bridges

# Stream NPC conversations to hologram
python hologram-bridge.py --mode atom --trail C:/Users/iamto/minecraft-npc.atom
```

### Tartarus Macro Integration

Bind ClaudeNPC commands to Tartarus Pro keys:

```powershell
python tartarus-bridge.py --profile spiralsafe

# Key 1: Toggle NPC conversations on/off
# Key 2: Query last 10 NPC interactions
# Key 6: Switch NPC to Opus model
# Key 7: Switch NPC to Sonnet model
```

---

## Logs and Debugging

### Important Log Files

```
minecraft-test-server/
├── logs/
│   ├── latest.log         # Server log (contains ClaudeNPC activity)
│   └── 2026-01-05-1.log.gz
├── plugins/
│   └── ClaudeNPC/
│       ├── config.yml
│       └── conversations.log  # Detailed conversation history
```

### Enable Debug Logging

Edit `config.yml`:
```yaml
logging:
  level: DEBUG
  log_conversations: true
  log_api_requests: true
```

### Viewing Conversation Logs

```powershell
# Real-time tail
Get-Content plugins\ClaudeNPC\conversations.log -Wait -Tail 20

# Search for player interactions
Select-String -Path plugins\ClaudeNPC\conversations.log -Pattern "PlayerName"
```

---

## Next Steps After Testing

### 1. Deploy to Production Server

Use the modular setup framework:

```powershell
cd C:\Users\iamto\repos\ClaudeNPC-Server-Suite\modular-setup

.\Install-PaperMC.ps1 -Profile production -ServerPath "D:\MinecraftProd"
```

### 2. Add Quantum Circuit Building

Enable ClaudeNPCs to build quantum gates (see Python integration below).

### 3. Community Deployment

- Add to SpigotMC / Bukkit plugins
- Create demo video
- Publish on GitHub releases

---

## Python Integration (The "Python Brush" Concept)

Your idea: "would claudeNPC do better if python, pytorch etc was mc tool"

**Yes! Here's how:**

### Concept: ClaudeNPC executes Python scripts to build structures

Instead of just chatting, NPCs can:
1. Generate Python code on-the-fly
2. Execute it via bridge
3. Build Minecraft structures programmatically

### Implementation Plan

**Phase 1: Python Executor Bridge**

Create `ClaudeNPC/src/main/java/com/claudenpc/PythonExecutor.java`:

```java
public class PythonExecutor {
    private final File pythonPath;
    private final File scriptsPath;

    public String executePythonScript(String code, Map<String, Object> context) {
        // Write code to temp file
        File tempScript = new File(scriptsPath, "temp_" + System.currentTimeMillis() + ".py");
        Files.write(tempScript.toPath(), code.getBytes());

        // Execute via ProcessBuilder
        ProcessBuilder pb = new ProcessBuilder(
            pythonPath.getAbsolutePath(),
            tempScript.getAbsolutePath()
        );

        // Capture output
        Process process = pb.start();
        String output = new String(process.getInputStream().readAllBytes());

        // Cleanup
        tempScript.delete();

        return output;
    }

    public void buildStructureFromPython(String pythonCode, Location startLoc) {
        // Execute Python to get block list JSON
        String json = executePythonScript(pythonCode, Map.of("x", startLoc.getX(), ...));

        // Parse JSON and place blocks
        JSONArray blocks = new JSONArray(json);
        for (int i = 0; i < blocks.length(); i++) {
            JSONObject block = blocks.getJSONObject(i);
            Location loc = new Location(
                startLoc.getWorld(),
                startLoc.getX() + block.getInt("x"),
                startLoc.getY() + block.getInt("y"),
                startLoc.getZ() + block.getInt("z")
            );
            Material mat = Material.valueOf(block.getString("material"));
            loc.getBlock().setType(mat);
        }
    }
}
```

**Phase 2: Claude Generates Python**

Update `ConversationManager` to detect build requests:

```java
if (playerMessage.contains("build") || playerMessage.contains("create structure")) {
    // Ask Claude to generate Python code for the structure
    String prompt = originalPrompt +
        "\n\nGenerate Python code that returns a JSON array of blocks " +
        "to build this structure. Format: [{x,y,z,material}, ...]";

    String response = apiClient.sendMessage(prompt, history);

    // Extract Python code from response (between ```python and ```)
    String pythonCode = extractCodeBlock(response);

    // Execute it
    pythonExecutor.buildStructureFromPython(pythonCode, playerLocation);

    return "Structure built! Check it out.";
}
```

**Phase 3: Quantum Circuit Builder**

NPCs can now build quantum gates:

Player: "Build a Hadamard gate here"

Claude generates:
```python
import sys
import json

# Use quantum_circuit_generator.py
from quantum_circuit_generator import generate_hadamard

circuit = generate_hadamard()

# Convert to Minecraft coordinate format
blocks = []
for block in circuit.blocks:
    blocks.append({
        "x": block.x,
        "y": block.y,
        "z": block.z,
        "material": block.block_id.upper().replace("MINECRAFT:", "")
    })

print(json.dumps(blocks))
```

NPC executes → Hadamard gate appears in world!

---

## Testing the Python Bridge

### Manual Test

1. Add quantum_circuit_generator.py to server:
   ```powershell
   mkdir minecraft-test-server\python-scripts
   copy C:\Users\iamto\quantum-redstone-build\quantum_circuit_generator.py minecraft-test-server\python-scripts\
   ```

2. Create test command:
   ```
   /claudenpc execute-python generate_hadamard
   ```

3. Expected result: Hadamard circuit appears at NPC location

### Integration Test

```powershell
# Test script: test-python-integration.ps1

$server = "localhost:25565"

# Connect as test player
# Send: "Hey Claude, build a state preparation circuit here"

# Expected:
# 1. Claude generates Python code
# 2. Server executes quantum_circuit_generator.py
# 3. State preparation circuit built at player location
# 4. NPC responds: "State preparation circuit complete!"
```

---

## Performance Metrics

Target performance for production:

- NPC response time: < 3 seconds (95th percentile)
- Python execution time: < 1 second for circuits < 500 blocks
- Server TPS impact: < 5% with 10 active NPCs
- Memory usage: < 100MB per active NPC

Monitor with:
```powershell
# Server TPS
/tps

# Plugin metrics
/claudenpc stats

# Memory usage
/memory
```

---

## Success Criteria

You'll know ClaudeNPC is working when:

1. [ ] NPC responds to chat naturally
2. [ ] Conversations feel contextual (remembers last 10 messages)
3. [ ] Different personalities create distinct NPCs
4. [ ] Python integration builds structures correctly
5. [ ] Quantum gates can be built via conversation
6. [ ] ATOM trail logging captures all interactions
7. [ ] Hologram displays NPC activity
8. [ ] No server lag with multiple active NPCs

---

**ClaudeNPC is the bridge between AI and Minecraft creativity.**

With Python integration, NPCs become builders, not just talkers.

**The Evenstar Guides Us** ✦

