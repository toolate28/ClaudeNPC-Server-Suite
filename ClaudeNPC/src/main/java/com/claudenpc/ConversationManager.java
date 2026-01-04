package com.claudenpc;

import com.claudenpc.ClaudeAPIClient.Message;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Manages conversations between players and NPCs
 */
public class ConversationManager {

    private final ClaudeNPC plugin;
    private final Map<String, ConversationHistory> conversations = new ConcurrentHashMap<>();

    public ConversationManager(ClaudeNPC plugin) {
        this.plugin = plugin;

        // Start cleanup task for old conversations
        int timeout = plugin.getConfig().getInt("npc.memory-timeout", 30);
        if (timeout > 0) {
            plugin.getServer().getScheduler().runTaskTimerAsynchronously(plugin, this::cleanupOldConversations, 20L * 60L, 20L * 60L);
        }
    }

    /**
     * Send a message to Claude and get a response
     * @param playerUUID Player's UUID
     * @param npcUUID NPC's UUID
     * @param message Player's message
     * @param systemPrompt NPC's personality/system prompt
     * @return CompletableFuture with Claude's response
     */
    public CompletableFuture<String> sendMessage(UUID playerUUID, UUID npcUUID, String message, String systemPrompt) {
        String conversationKey = playerUUID + ":" + npcUUID;

        // Get or create conversation history
        ConversationHistory history = conversations.computeIfAbsent(conversationKey,
                k -> new ConversationHistory(plugin.getConfig().getInt("npc.memory-size", 5)));

        // Add user message to history
        history.addMessage("user", message);

        // Get messages for API call
        List<Message> messages = history.getMessages();

        // Call Claude API
        return plugin.getAPIClient().sendMessage(messages, systemPrompt)
                .thenApply(response -> {
                    // Add assistant response to history
                    history.addMessage("assistant", response);
                    return response;
                });
    }

    /**
     * Clear conversation history for a player-NPC pair
     */
    public void clearConversation(UUID playerUUID, UUID npcUUID) {
        String conversationKey = playerUUID + ":" + npcUUID;
        conversations.remove(conversationKey);
    }

    /**
     * Clear all conversations for a player
     */
    public void clearPlayerConversations(UUID playerUUID) {
        conversations.keySet().removeIf(key -> key.startsWith(playerUUID.toString()));
    }

    /**
     * Clean up conversations that haven't been used recently
     */
    private void cleanupOldConversations() {
        int timeoutMinutes = plugin.getConfig().getInt("npc.memory-timeout", 30);
        if (timeoutMinutes <= 0) return;

        long cutoffTime = System.currentTimeMillis() - (timeoutMinutes * 60 * 1000);

        conversations.entrySet().removeIf(entry ->
                entry.getValue().getLastAccessTime() < cutoffTime
        );
    }

    /**
     * Save all conversations (called on plugin disable)
     */
    public void shutdown() {
        // Could save to file here if needed
        conversations.clear();
    }

    /**
     * Inner class to hold conversation history
     */
    private static class ConversationHistory {
        private final int maxSize;
        private final List<Message> messages = new ArrayList<>();
        private long lastAccessTime;

        public ConversationHistory(int maxSize) {
            this.maxSize = maxSize;
            this.lastAccessTime = System.currentTimeMillis();
        }

        public void addMessage(String role, String content) {
            messages.add(new Message(role, content));

            // Keep only last N messages (pairs of user+assistant)
            while (messages.size() > maxSize * 2) {
                messages.remove(0);
            }

            lastAccessTime = System.currentTimeMillis();
        }

        public List<Message> getMessages() {
            lastAccessTime = System.currentTimeMillis();
            return new ArrayList<>(messages);
        }

        public long getLastAccessTime() {
            return lastAccessTime;
        }
    }
}
