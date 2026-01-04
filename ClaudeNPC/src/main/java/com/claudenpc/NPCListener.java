package com.claudenpc;

import net.citizensnpcs.api.event.NPCRightClickEvent;
import net.citizensnpcs.api.npc.NPC;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Listens for player interactions with NPCs
 */
public class NPCListener implements Listener {

    private final ClaudeNPC plugin;
    private final Map<UUID, NPC> activeTalking = new HashMap<>();

    public NPCListener(ClaudeNPC plugin) {
        this.plugin = plugin;
    }

    /**
     * Handle right-click on NPC
     */
    @EventHandler
    public void onNPCRightClick(NPCRightClickEvent event) {
        Player player = event.getClicker();
        NPC npc = event.getNPC();

        // Check permission
        if (!player.hasPermission("claudenpc.talk")) {
            player.sendMessage("§cYou don't have permission to talk to NPCs.");
            return;
        }

        // Check if NPC is a Claude NPC (has metadata)
        if (!npc.data().has("claudenpc.enabled")) {
            // Not a Claude NPC, ignore
            return;
        }

        // Start conversation
        activeTalking.put(player.getUniqueId(), npc);
        player.sendMessage("§7§o[You are now talking to " + npc.getName() + ". Type your message in chat!]");
        player.sendMessage("§7§o[Type 'bye' or 'exit' to stop talking]");
    }

    /**
     * Handle player chat - if they're talking to an NPC, send to Claude
     */
    @EventHandler
    public void onPlayerChat(AsyncPlayerChatEvent event) {
        Player player = event.getPlayer();
        UUID playerUUID = player.getUniqueId();

        // Check if player is talking to an NPC
        if (!activeTalking.containsKey(playerUUID)) {
            return;
        }

        NPC npc = activeTalking.get(playerUUID);
        String message = event.getMessage();

        // Cancel the chat event so it doesn't broadcast
        event.setCancelled(true);

        // Check for exit commands
        if (message.equalsIgnoreCase("bye") || message.equalsIgnoreCase("exit") || message.equalsIgnoreCase("quit")) {
            activeTalking.remove(playerUUID);
            player.sendMessage("§7§o[Conversation ended with " + npc.getName() + "]");
            return;
        }

        // Show player's message
        player.sendMessage("§7You: §f" + message);

        // Get conversation manager
        ConversationManager convManager = plugin.getConversationManager();

        // Get NPC's personality (custom or default)
        String personality = npc.data().get("claudenpc.personality",
                plugin.getConfig().getString("npc.default-personality"));

        // Send to Claude (async)
        convManager.sendMessage(playerUUID, npc.getUniqueId(), message, personality)
                .thenAccept(response -> {
                    // Send response on main thread
                    plugin.getServer().getScheduler().runTask(plugin, () -> {
                        player.sendMessage("§e" + npc.getName() + ": §f" + response);
                    });
                })
                .exceptionally(throwable -> {
                    plugin.getServer().getScheduler().runTask(plugin, () -> {
                        player.sendMessage("§c" + npc.getName() + " seems confused and can't respond right now.");
                        plugin.getLogger().warning("Error getting response for " + player.getName() + ": " + throwable.getMessage());
                    });
                    return null;
                });
    }

    /**
     * Clear active conversation for a player
     */
    public void clearConversation(UUID playerUUID) {
        activeTalking.remove(playerUUID);
    }
}
