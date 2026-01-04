package com.claudenpc;

/**
 * Manages plugin configuration
 */
public class ConfigManager {

    private final ClaudeNPC plugin;

    public ConfigManager(ClaudeNPC plugin) {
        this.plugin = plugin;
    }

    /**
     * Reload configuration from file
     */
    public void reload() {
        plugin.reloadConfig();
    }

    /**
     * Check if API key is configured
     */
    public boolean hasAPIKey() {
        String apiKey = plugin.getConfig().getString("claude.api-key", "");
        return apiKey != null && !apiKey.isEmpty();
    }

    /**
     * Get configured model name
     */
    public String getModel() {
        return plugin.getConfig().getString("claude.model", "claude-3-5-haiku-20241022");
    }

    /**
     * Get memory size
     */
    public int getMemorySize() {
        return plugin.getConfig().getInt("npc.memory-size", 5);
    }

    /**
     * Get default personality
     */
    public String getDefaultPersonality() {
        return plugin.getConfig().getString("npc.default-personality",
                "You are a helpful NPC in a Minecraft server. Keep responses concise (1-3 sentences).");
    }
}
