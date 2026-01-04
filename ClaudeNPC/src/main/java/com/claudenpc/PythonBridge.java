package com.claudenpc;

import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.block.Block;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

/**
 * Python Bridge - Enables ClaudeNPC to execute Python scripts for building structures
 *
 * The "Python Brush" Concept:
 * - NPCs generate Python code via Claude API
 * - Code is executed safely in controlled environment
 * - Output is parsed as block placement instructions
 * - Structures materialize in Minecraft world
 *
 * Primary use case: Building quantum Redstone circuits via conversation
 */
public class PythonBridge {

    private final ClaudeNPC plugin;
    private final Logger logger;
    private final Path pythonExecutable;
    private final Path scriptsDirectory;
    private final Path tempDirectory;
    private final int executionTimeoutSeconds;

    public PythonBridge(ClaudeNPC plugin) {
        this.plugin = plugin;
        this.logger = plugin.getLogger();

        // Configure paths from config.yml
        String pythonPath = plugin.getConfig().getString("python.executable", "python");
        this.pythonExecutable = Paths.get(pythonPath);

        String scriptsPath = plugin.getConfig().getString("python.scripts_directory",
                            plugin.getDataFolder().getAbsolutePath() + "/python-scripts");
        this.scriptsDirectory = Paths.get(scriptsPath);

        this.tempDirectory = Paths.get(plugin.getDataFolder().getAbsolutePath() + "/temp");
        this.executionTimeoutSeconds = plugin.getConfig().getInt("python.timeout_seconds", 30);

        // Ensure directories exist
        try {
            Files.createDirectories(scriptsDirectory);
            Files.createDirectories(tempDirectory);
            logger.info("Python bridge initialized: " + scriptsDirectory);
        } catch (IOException e) {
            logger.severe("Failed to create Python directories: " + e.getMessage());
        }
    }

    /**
     * Execute Python code and return stdout as string
     */
    public String executePythonCode(String code) throws Exception {
        return executePythonCode(code, new HashMap<>());
    }

    /**
     * Execute Python code with environment variables
     */
    public String executePythonCode(String code, Map<String, String> environment) throws Exception {
        // Create temporary script file
        Path tempScript = tempDirectory.resolve("script_" + System.currentTimeMillis() + ".py");

        try {
            // Write code to file
            Files.writeString(tempScript, code);

            // Build process
            ProcessBuilder processBuilder = new ProcessBuilder(
                pythonExecutable.toString(),
                tempScript.toString()
            );

            // Set environment variables
            Map<String, String> env = processBuilder.environment();
            env.putAll(environment);

            // Set working directory to scripts folder
            processBuilder.directory(scriptsDirectory.toFile());

            // Start process
            Process process = processBuilder.start();

            // Capture output
            StringBuilder output = new StringBuilder();
            StringBuilder errors = new StringBuilder();

            try (BufferedReader outReader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));
                 BufferedReader errReader = new BufferedReader(
                    new InputStreamReader(process.getErrorStream()))) {

                String line;
                while ((line = outReader.readLine()) != null) {
                    output.append(line).append("\n");
                }

                while ((line = errReader.readLine()) != null) {
                    errors.append(line).append("\n");
                }
            }

            // Wait for completion with timeout
            boolean completed = process.waitFor(executionTimeoutSeconds, TimeUnit.SECONDS);

            if (!completed) {
                process.destroyForcibly();
                throw new Exception("Python execution timed out after " + executionTimeoutSeconds + " seconds");
            }

            int exitCode = process.exitValue();

            if (exitCode != 0) {
                throw new Exception("Python execution failed with exit code " + exitCode +
                                  "\nErrors: " + errors.toString());
            }

            return output.toString().trim();

        } finally {
            // Cleanup temp file
            try {
                Files.deleteIfExists(tempScript);
            } catch (IOException e) {
                logger.warning("Failed to delete temp script: " + e.getMessage());
            }
        }
    }

    /**
     * Execute Python script from scripts directory
     */
    public String executeScript(String scriptName, Map<String, String> args) throws Exception {
        Path scriptPath = scriptsDirectory.resolve(scriptName);

        if (!Files.exists(scriptPath)) {
            throw new FileNotFoundException("Script not found: " + scriptPath);
        }

        // Build command with arguments
        ProcessBuilder processBuilder = new ProcessBuilder();
        processBuilder.command().add(pythonExecutable.toString());
        processBuilder.command().add(scriptPath.toString());

        // Add arguments
        for (Map.Entry<String, String> entry : args.entrySet()) {
            processBuilder.command().add("--" + entry.getKey());
            processBuilder.command().add(entry.getValue());
        }

        processBuilder.directory(scriptsDirectory.toFile());

        Process process = processBuilder.start();

        // Capture output
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }

        boolean completed = process.waitFor(executionTimeoutSeconds, TimeUnit.SECONDS);
        if (!completed) {
            process.destroyForcibly();
            throw new Exception("Script execution timed out");
        }

        return output.toString().trim();
    }

    /**
     * Build structure from Python-generated block list
     *
     * Expected JSON format:
     * [
     *   {"x": 0, "y": 1, "z": 2, "material": "REDSTONE_WIRE", "properties": {...}},
     *   ...
     * ]
     */
    public int buildStructureFromPython(String pythonCode, Location origin) throws Exception {
        // Execute Python code
        String jsonOutput = executePythonCode(pythonCode);

        // Parse JSON
        JSONParser parser = new JSONParser();
        JSONArray blocks = (JSONArray) parser.parse(jsonOutput);

        // Place blocks
        int placedCount = 0;

        for (Object obj : blocks) {
            JSONObject blockData = (JSONObject) obj;

            // Extract coordinates (relative to origin)
            long x = (Long) blockData.get("x");
            long y = (Long) blockData.get("y");
            long z = (Long) blockData.get("z");

            // Calculate absolute location
            Location blockLocation = origin.clone().add(x, y, z);
            Block block = blockLocation.getBlock();

            // Get material
            String materialName = (String) blockData.get("material");
            materialName = materialName.toUpperCase().replace("MINECRAFT:", "");

            try {
                Material material = Material.valueOf(materialName);
                block.setType(material);

                // TODO: Handle block properties (facing, powered, etc.)
                // JSONObject properties = (JSONObject) blockData.get("properties");

                placedCount++;

            } catch (IllegalArgumentException e) {
                logger.warning("Unknown material: " + materialName);
            }
        }

        logger.info("Placed " + placedCount + " blocks from Python-generated structure");
        return placedCount;
    }

    /**
     * Build quantum circuit using quantum_circuit_generator.py
     *
     * @param circuitName One of: state_preparation, pauli_x_gate, pauli_z_gate,
     *                    hadamard_gate, cnot_gate, phase_evolution_engine, conservation_verifier
     */
    public int buildQuantumCircuit(String circuitName, Location origin) throws Exception {
        logger.info("Building quantum circuit: " + circuitName + " at " +
                   origin.getBlockX() + "," + origin.getBlockY() + "," + origin.getBlockZ());

        // Python code to generate circuit
        String pythonCode = String.format(
            "import json\n" +
            "import sys\n" +
            "sys.path.insert(0, '%s')\n" +
            "\n" +
            "from quantum_circuit_generator import *\n" +
            "\n" +
            "# Generate circuit\n" +
            "if '%s' == 'state_preparation':\n" +
            "    circuit = generate_state_preparation()\n" +
            "elif '%s' == 'pauli_x_gate':\n" +
            "    circuit = generate_pauli_x()\n" +
            "elif '%s' == 'pauli_z_gate':\n" +
            "    circuit = generate_pauli_z()\n" +
            "elif '%s' == 'hadamard_gate':\n" +
            "    circuit = generate_hadamard()\n" +
            "elif '%s' == 'cnot_gate':\n" +
            "    circuit = generate_cnot()\n" +
            "elif '%s' == 'phase_evolution_engine':\n" +
            "    lookup_table = generate_lookup_table(16)\n" +
            "    circuit = generate_phase_engine(lookup_table)\n" +
            "elif '%s' == 'conservation_verifier':\n" +
            "    circuit = generate_conservation_verifier()\n" +
            "else:\n" +
            "    raise ValueError('Unknown circuit: %s')\n" +
            "\n" +
            "# Convert to JSON\n" +
            "blocks = []\n" +
            "for block in circuit.blocks:\n" +
            "    block_dict = {\n" +
            "        'x': block.x,\n" +
            "        'y': block.y,\n" +
            "        'z': block.z,\n" +
            "        'material': block.block_id\n" +
            "    }\n" +
            "    if block.properties:\n" +
            "        block_dict['properties'] = block.properties\n" +
            "    blocks.append(block_dict)\n" +
            "\n" +
            "print(json.dumps(blocks))\n",
            scriptsDirectory.toString().replace("\\", "\\\\"),
            circuitName, circuitName, circuitName, circuitName, circuitName,
            circuitName, circuitName, circuitName
        );

        return buildStructureFromPython(pythonCode, origin);
    }

    /**
     * Check if Python is available
     */
    public boolean isPythonAvailable() {
        try {
            ProcessBuilder pb = new ProcessBuilder(pythonExecutable.toString(), "--version");
            Process process = pb.start();
            boolean completed = process.waitFor(5, TimeUnit.SECONDS);
            return completed && process.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get Python version string
     */
    public String getPythonVersion() {
        try {
            ProcessBuilder pb = new ProcessBuilder(pythonExecutable.toString(), "--version");
            Process process = pb.start();

            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()))) {
                return reader.readLine();
            }
        } catch (Exception e) {
            return "Unknown";
        }
    }
}
