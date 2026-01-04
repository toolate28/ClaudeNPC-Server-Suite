package com.claudenpc;

import net.citizensnpcs.api.CitizensAPI;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * ClaudeNPC - AI-powered NPCs using Claude API
 * Main plugin class
 */
public class ClaudeNPC extends JavaPlugin {

    private static ClaudeNPC instance;
    private ClaudeAPIClient apiClient;
    private ConversationManager conversationManager;
    private ConfigManager configManager;

    @Override
    public void onEnable() {
        instance = this;

        // Save default config if it doesn't exist
        saveDefaultConfig();

        // Initialize config manager
        configManager = new ConfigManager(this);

        // Check if Citizens is loaded
        if (getServer().getPluginManager().getPlugin("Citizens") == null) {
            getLogger().severe("Citizens plugin not found! ClaudeNPC requires Citizens to work.");
            getServer().getPluginManager().disablePlugin(this);
            return;
        }

        // Check API key
        String apiKey = getConfig().getString("claude.api-key", "");
        if (apiKey.isEmpty()) {
            getLogger().warning("Claude API key not set in config.yml!");
            getLogger().warning("Plugin will load but NPCs won't respond until API key is configured.");
        }

        // Initialize API client
        apiClient = new ClaudeAPIClient(this);

        // Initialize conversation manager
        conversationManager = new ConversationManager(this);

        // Register NPC listener
        getServer().getPluginManager().registerEvents(new NPCListener(this), this);

        // Register command
        getCommand("claudenpc").setExecutor(new ClaudeNPCCommand(this));

        getLogger().info("ClaudeNPC v" + getDescription().getVersion() + " enabled!");
        getLogger().info("Model: " + getConfig().getString("claude.model"));
        getLogger().info("Memory size: " + getConfig().getInt("npc.memory-size") + " messages");
    }

    @Override
    public void onDisable() {
        // Save all conversations
        if (conversationManager != null) {
            conversationManager.shutdown();
        }

        // Close API client
        if (apiClient != null) {
            apiClient.close();
        }

        getLogger().info("ClaudeNPC disabled!");
    }

    public static ClaudeNPC getInstance() {
        return instance;
    }

    public ClaudeAPIClient getAPIClient() {
        return apiClient;
    }

    public ConversationManager getConversationManager() {
        return conversationManager;
    }

    public ConfigManager getConfigManager() {
        return configManager;
    }
}
