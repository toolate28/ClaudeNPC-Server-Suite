package com.claudenpc;

import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;

/**
 * Command handler for /claudenpc
 */
public class ClaudeNPCCommand implements CommandExecutor {

    private final ClaudeNPC plugin;

    public ClaudeNPCCommand(ClaudeNPC plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!sender.hasPermission("claudenpc.admin")) {
            sender.sendMessage("§cYou don't have permission to use this command.");
            return true;
        }

        if (args.length == 0) {
            sendHelp(sender);
            return true;
        }

        switch (args[0].toLowerCase()) {
            case "reload":
                plugin.reloadConfig();
                plugin.getConfigManager().reload();
                sender.sendMessage("§aClaudeNPC configuration reloaded!");
                return true;

            case "status":
                sendStatus(sender);
                return true;

            case "help":
                sendHelp(sender);
                return true;

            default:
                sender.sendMessage("§cUnknown subcommand: " + args[0]);
                sendHelp(sender);
                return true;
        }
    }

    private void sendHelp(CommandSender sender) {
        sender.sendMessage("§6§lClaudeNPC Commands:");
        sender.sendMessage("§e/claudenpc reload §7- Reload configuration");
        sender.sendMessage("§e/claudenpc status §7- Show plugin status");
        sender.sendMessage("§e/claudenpc help §7- Show this help");
    }

    private void sendStatus(CommandSender sender) {
        sender.sendMessage("§6§lClaudeNPC Status:");
        sender.sendMessage("§7Version: §f" + plugin.getDescription().getVersion());
        sender.sendMessage("§7Model: §f" + plugin.getConfig().getString("claude.model"));
        sender.sendMessage("§7Memory Size: §f" + plugin.getConfig().getInt("npc.memory-size") + " messages");

        boolean hasKey = plugin.getConfigManager().hasAPIKey();
        sender.sendMessage("§7API Key: " + (hasKey ? "§aConfigured ✓" : "§cNot Set ✗"));

        if (!hasKey) {
            sender.sendMessage("§c⚠ Plugin won't work without API key!");
            sender.sendMessage("§7Add your key to config.yml");
        }
    }
}
