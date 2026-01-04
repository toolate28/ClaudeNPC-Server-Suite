package com.claudenpc;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import okhttp3.*;
import org.bukkit.Bukkit;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Client for communicating with Claude API
 */
public class ClaudeAPIClient {

    private static final String API_URL = "https://api.anthropic.com/v1/messages";
    private static final String API_VERSION = "2023-06-01";

    private final ClaudeNPC plugin;
    private final OkHttpClient httpClient;
    private final Gson gson;

    public ClaudeAPIClient(ClaudeNPC plugin) {
        this.plugin = plugin;
        this.gson = new Gson();

        int timeout = plugin.getConfig().getInt("claude.timeout", 30);
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(timeout, TimeUnit.SECONDS)
                .readTimeout(timeout, TimeUnit.SECONDS)
                .writeTimeout(timeout, TimeUnit.SECONDS)
                .build();
    }

    /**
     * Send a message to Claude API and get a response
     * @param messages List of conversation messages
     * @param systemPrompt System prompt for the NPC's personality
     * @return CompletableFuture with Claude's response
     */
    public CompletableFuture<String> sendMessage(List<Message> messages, String systemPrompt) {
        CompletableFuture<String> future = new CompletableFuture<>();

        String apiKey = plugin.getConfig().getString("claude.api-key", "");
        if (apiKey.isEmpty()) {
            future.completeExceptionally(new IllegalStateException("Claude API key not configured"));
            return future;
        }

        // Build request JSON
        JsonObject requestBody = new JsonObject();
        requestBody.addProperty("model", plugin.getConfig().getString("claude.model"));
        requestBody.addProperty("max_tokens", plugin.getConfig().getInt("claude.max-tokens", 1024));
        requestBody.addProperty("system", systemPrompt);

        // Add messages
        JsonArray messagesArray = new JsonArray();
        for (Message msg : messages) {
            JsonObject messageObj = new JsonObject();
            messageObj.addProperty("role", msg.getRole());
            messageObj.addProperty("content", msg.getContent());
            messagesArray.add(messageObj);
        }
        requestBody.add("messages", messagesArray);

        // Create HTTP request
        RequestBody body = RequestBody.create(
                requestBody.toString(),
                MediaType.parse("application/json")
        );

        Request request = new Request.Builder()
                .url(API_URL)
                .header("x-api-key", apiKey)
                .header("anthropic-version", API_VERSION)
                .header("content-type", "application/json")
                .post(body)
                .build();

        // Execute async
        httpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                plugin.getLogger().warning("Claude API request failed: " + e.getMessage());
                future.completeExceptionally(e);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                try (ResponseBody responseBody = response.body()) {
                    if (!response.isSuccessful()) {
                        String error = responseBody != null ? responseBody.string() : "Unknown error";
                        plugin.getLogger().warning("Claude API error (" + response.code() + "): " + error);
                        future.completeExceptionally(new IOException("API error: " + response.code()));
                        return;
                    }

                    if (responseBody == null) {
                        future.completeExceptionally(new IOException("Empty response"));
                        return;
                    }

                    String responseStr = responseBody.string();
                    JsonObject responseJson = gson.fromJson(responseStr, JsonObject.class);

                    // Extract text from response
                    JsonArray content = responseJson.getAsJsonArray("content");
                    if (content != null && content.size() > 0) {
                        String text = content.get(0).getAsJsonObject().get("text").getAsString();
                        future.complete(text);
                    } else {
                        future.completeExceptionally(new IOException("No content in response"));
                    }
                } catch (Exception e) {
                    plugin.getLogger().warning("Error parsing Claude response: " + e.getMessage());
                    future.completeExceptionally(e);
                }
            }
        });

        return future;
    }

    public void close() {
        httpClient.dispatcher().executorService().shutdown();
        httpClient.connectionPool().evictAll();
    }

    /**
     * Message class for conversation history
     */
    public static class Message {
        private final String role;
        private final String content;

        public Message(String role, String content) {
            this.role = role;
            this.content = content;
        }

        public String getRole() {
            return role;
        }

        public String getContent() {
            return content;
        }
    }
}
