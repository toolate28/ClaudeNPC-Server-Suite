#!/usr/bin/env python3
"""
Quantum Redstone Circuit Generator
Version: 0.1.0
Author: Hope&&Sauced Collaborative

Generates NBT-compatible structure data for Minecraft quantum gate circuits.
Output can be converted to Litematica .litematic or WorldEdit .schem format.
"""

import json
import math
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional
from enum import Enum

# ============================================================================
# MATHEMATICAL FOUNDATIONS
# ============================================================================

def cos_squared(phi: float) -> float:
    """Compute cos²(φ)"""
    return math.cos(phi) ** 2

def sin_squared(phi: float) -> float:
    """Compute sin²(φ)"""
    return math.sin(phi) ** 2

def verify_conservation(alpha: int, omega: int) -> bool:
    """Verify ALPHA + OMEGA = 15"""
    return alpha + omega == 15

def phase_to_signals(phi: float, max_signal: int = 15) -> Tuple[int, int]:
    """
    Convert phase φ to discrete ALPHA/OMEGA signals.
    
    Returns (ALPHA, OMEGA) where ALPHA + OMEGA = max_signal
    """
    alpha_raw = max_signal * cos_squared(phi)
    alpha = round(alpha_raw)
    omega = max_signal - alpha  # Guarantee conservation
    return alpha, omega

def generate_lookup_table(steps: int = 16) -> List[Dict]:
    """
    Generate the full phase lookup table.
    
    Returns list of dicts with:
        - step: step number (0 to steps-1)
        - phi: phase angle in radians
        - cos_sq: cos²(φ) exact value
        - sin_sq: sin²(φ) exact value  
        - alpha: discrete ALPHA signal (0-15)
        - omega: discrete OMEGA signal (0-15)
        - chest_items: number of items for chest (for signal level)
        - is_viviani: True if this is a Viviani crossing point
    """
    table = []
    for k in range(steps):
        phi = k * math.pi / (steps // 2)  # Full 2π rotation
        cos_sq = cos_squared(phi)
        sin_sq = sin_squared(phi)
        alpha, omega = phase_to_signals(phi)
        
        # Items needed in chest for given signal level
        # Signal = floor(1 + 14 * fill_fraction) for fill > 0
        # For single stack: ~4 items per signal level
        chest_items = alpha * 4
        
        # Viviani crossings occur when cos²(φ) ≈ sin²(φ) ≈ 0.5
        is_viviani = abs(cos_sq - 0.5) < 0.1
        
        table.append({
            'step': k,
            'phi': phi,
            'phi_fraction': f"{k}pi/{steps//2}" if k > 0 else "0",
            'phi_fraction_unicode': f"{k}π/{steps//2}" if k > 0 else "0",
            'cos_sq': cos_sq,
            'sin_sq': sin_sq,
            'alpha': alpha,
            'omega': omega,
            'chest_items': chest_items,
            'is_viviani': is_viviani,
            'conservation_check': verify_conservation(alpha, omega)
        })
    
    return table


# ============================================================================
# BLOCK DEFINITIONS
# ============================================================================

class BlockFacing(Enum):
    NORTH = "north"
    SOUTH = "south"
    EAST = "east"
    WEST = "west"
    UP = "up"
    DOWN = "down"

@dataclass
class Block:
    """Minecraft block with position and properties"""
    x: int
    y: int
    z: int
    block_id: str
    properties: Optional[Dict] = None
    nbt: Optional[Dict] = None
    
    def to_dict(self) -> Dict:
        result = {
            'pos': [self.x, self.y, self.z],
            'block': self.block_id
        }
        if self.properties:
            result['properties'] = self.properties
        if self.nbt:
            result['nbt'] = self.nbt
        return result

@dataclass  
class Circuit:
    """A Redstone circuit with blocks and metadata"""
    name: str
    description: str
    blocks: List[Block]
    dimensions: Tuple[int, int, int]  # x, y, z
    
    def to_dict(self) -> Dict:
        return {
            'name': self.name,
            'description': self.description,
            'dimensions': {
                'x': self.dimensions[0],
                'y': self.dimensions[1],
                'z': self.dimensions[2]
            },
            'block_count': len(self.blocks),
            'blocks': [b.to_dict() for b in self.blocks]
        }


# ============================================================================
# CIRCUIT GENERATORS
# ============================================================================

def generate_state_preparation() -> Circuit:
    """
    Circuit 1: State Preparation

    Prepares |0> or |1> based on lever state.
    Lever ON -> |0> (ALPHA=15, OMEGA=0)
    Lever OFF -> |1> (ALPHA=0, OMEGA=15)
    """
    blocks = []
    
    # Lever
    blocks.append(Block(0, 1, 1, "minecraft:lever", 
                       properties={"face": "floor", "facing": "east"}))
    
    # ALPHA rail (lever → output)
    for x in range(1, 7):
        blocks.append(Block(x, 0, 1, "minecraft:redstone_wire"))
    
    # Inverter block for OMEGA
    blocks.append(Block(1, 0, 0, "minecraft:stone"))
    blocks.append(Block(1, 1, 0, "minecraft:redstone_torch",
                       properties={"facing": "up"}))
    
    # OMEGA rail (inverted)
    for x in range(2, 7):
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))
    
    # Output markers (glass for visibility)
    blocks.append(Block(7, 0, 1, "minecraft:green_stained_glass"))  # ALPHA out
    blocks.append(Block(7, 0, 0, "minecraft:blue_stained_glass"))   # OMEGA out
    
    return Circuit(
        name="state_preparation",
        description="Prepares basis states |0⟩ or |1⟩",
        blocks=blocks,
        dimensions=(10, 3, 3)
    )


def generate_pauli_x() -> Circuit:
    """
    Circuit 2: Pauli-X Gate (NOT / Bit Flip)

    Swaps ALPHA <-> OMEGA rails.
    """
    blocks = []
    
    # ALPHA input rail (y=2, z=4)
    for x in range(4):
        blocks.append(Block(x, 2, 4, "minecraft:redstone_wire"))
    
    # OMEGA input rail (y=0, z=0)  
    for x in range(4):
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))
    
    # Crossover structure
    # ALPHA drops down
    blocks.append(Block(4, 2, 4, "minecraft:stone"))
    blocks.append(Block(4, 1, 4, "minecraft:redstone_torch",
                       properties={"facing": "down"}))
    
    # Crossover level
    blocks.append(Block(4, 1, 2, "minecraft:redstone_wire"))
    blocks.append(Block(5, 1, 2, "minecraft:redstone_wire"))
    
    # OMEGA rises up
    blocks.append(Block(4, 0, 0, "minecraft:stone"))
    blocks.append(Block(4, 1, 0, "minecraft:redstone_torch",
                       properties={"facing": "up"}))
    
    # ALPHA output (was OMEGA input level)
    for x in range(5, 10):
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))
    
    # OMEGA output (was ALPHA input level)
    for x in range(5, 10):
        blocks.append(Block(x, 2, 4, "minecraft:redstone_wire"))
    
    # Note: This is simplified - actual crossing needs repeaters
    # to maintain signal strength and proper double-inversion
    
    return Circuit(
        name="pauli_x_gate",
        description="Pauli-X (NOT) gate - swaps ALPHA and OMEGA",
        blocks=blocks,
        dimensions=(10, 4, 5)
    )


def generate_pauli_z() -> Circuit:
    """
    Circuit 3: Pauli-Z Gate (Phase Flip)
    
    Toggles PHASE rail without affecting ALPHA/OMEGA.
    """
    blocks = []
    
    # ALPHA rail (pass-through)
    for x in range(10):
        blocks.append(Block(x, 0, 2, "minecraft:redstone_wire"))
    
    # OMEGA rail (pass-through via comparators)
    for x in range(10):
        facing = "east" if x % 2 == 0 else "west"
        blocks.append(Block(x, 0, 1, "minecraft:comparator",
                           properties={"facing": facing, "mode": "compare"}))
    
    # PHASE rail with inverter
    for x in range(3):
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))
    
    blocks.append(Block(3, 0, 0, "minecraft:stone"))
    blocks.append(Block(3, 1, 0, "minecraft:redstone_torch"))
    
    for x in range(4, 10):
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))
    
    return Circuit(
        name="pauli_z_gate", 
        description="Pauli-Z (phase flip) gate - toggles PHASE rail",
        blocks=blocks,
        dimensions=(10, 3, 3)
    )


def generate_hadamard() -> Circuit:
    """
    Circuit 4: Hadamard Gate
    
    Creates superposition from basis states.
    Includes measurement apparatus (dropper randomizer).
    """
    blocks = []
    
    # ===== SUPERPOSITION STAGE =====
    # Fixed output chests (the "averager")
    # Chest with 32 items → signal 8
    blocks.append(Block(5, 0, 3, "minecraft:chest",
                       nbt={"Items": [{"Slot": 0, "id": "minecraft:cobblestone", "Count": 32}]}))
    blocks.append(Block(6, 0, 3, "minecraft:comparator",
                       properties={"facing": "east", "mode": "compare"}))
    
    # Chest with 28 items → signal 7
    blocks.append(Block(9, 0, 3, "minecraft:chest",
                       nbt={"Items": [{"Slot": 0, "id": "minecraft:cobblestone", "Count": 28}]}))
    blocks.append(Block(8, 0, 3, "minecraft:comparator",
                       properties={"facing": "west", "mode": "compare"}))
    
    # ===== MEASUREMENT STAGE =====
    # Dropper with single item
    blocks.append(Block(7, 2, 3, "minecraft:stone"))  # Support
    blocks.append(Block(7, 1, 3, "minecraft:dropper",
                       properties={"facing": "down"},
                       nbt={"Items": [{"Slot": 4, "id": "minecraft:diamond", "Count": 1}]}))
    
    # Button to trigger measurement
    blocks.append(Block(7, 2, 4, "minecraft:stone"))
    blocks.append(Block(7, 2, 3, "minecraft:stone_button",
                       properties={"face": "wall", "facing": "south"}))
    
    # Hoppers to catch item
    blocks.append(Block(6, 0, 3, "minecraft:hopper",
                       properties={"facing": "down"}))
    blocks.append(Block(8, 0, 3, "minecraft:hopper",
                       properties={"facing": "down"}))
    
    # Comparators reading hoppers
    blocks.append(Block(6, 0, 2, "minecraft:comparator",
                       properties={"facing": "south", "mode": "compare"}))
    blocks.append(Block(8, 0, 2, "minecraft:comparator",
                       properties={"facing": "south", "mode": "compare"}))
    
    # Output routing (simplified)
    # Path A: Item in hopper 6 → ALPHA=15
    # Path B: Item in hopper 8 → OMEGA=15
    
    return Circuit(
        name="hadamard_gate",
        description="Hadamard gate - creates superposition, includes measurement",
        blocks=blocks,
        dimensions=(15, 5, 10)
    )


def generate_cnot() -> Circuit:
    """
    Circuit 5: CNOT Gate

    Two-qubit gate: target flips if control is |1>.
    Uses piston-based conditional swap.
    """
    blocks = []
    
    # Control qubit rails (pass-through)
    for x in range(20):
        blocks.append(Block(x, 4, 14, "minecraft:redstone_wire"))  # ALPHA_C
        blocks.append(Block(x, 4, 13, "minecraft:redstone_wire"))  # OMEGA_C (tapped)
    
    # Threshold detector (is control |1⟩?)
    blocks.append(Block(10, 4, 12, "minecraft:comparator",
                       properties={"facing": "south", "mode": "compare"}))
    blocks.append(Block(10, 4, 11, "minecraft:stone"))
    blocks.append(Block(10, 4, 10, "minecraft:redstone_wire"))  # ENABLE signal
    
    # Target qubit input rails
    for x in range(8):
        blocks.append(Block(x, 0, 7, "minecraft:redstone_wire"))  # ALPHA_T
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))  # OMEGA_T
    
    # Piston swap mechanism (simplified representation)
    # When ENABLE=15: pistons extend, swap paths
    # When ENABLE=0: pistons retracted, straight through
    
    blocks.append(Block(8, 0, 7, "minecraft:sticky_piston",
                       properties={"facing": "south"}))
    blocks.append(Block(8, 0, 0, "minecraft:sticky_piston",
                       properties={"facing": "north"}))
    
    # Enable signal routing to pistons
    blocks.append(Block(10, 3, 10, "minecraft:redstone_wire"))
    blocks.append(Block(10, 2, 10, "minecraft:redstone_wire"))
    blocks.append(Block(10, 1, 10, "minecraft:redstone_wire"))
    blocks.append(Block(10, 0, 10, "minecraft:redstone_wire"))
    blocks.append(Block(9, 0, 10, "minecraft:redstone_wire"))
    blocks.append(Block(8, 0, 10, "minecraft:redstone_wire"))
    
    # Target qubit output rails
    for x in range(12, 20):
        blocks.append(Block(x, 0, 7, "minecraft:redstone_wire"))  # ALPHA_T out
        blocks.append(Block(x, 0, 0, "minecraft:redstone_wire"))  # OMEGA_T out
    
    return Circuit(
        name="cnot_gate",
        description="CNOT gate - entangles two qubits",
        blocks=blocks,
        dimensions=(20, 6, 15)
    )


def generate_phase_engine(lookup_table: List[Dict]) -> Circuit:
    """
    Circuit 6: Phase Evolution Engine

    Cycles through 16 phase states with cos^2/sin^2 outputs.
    """
    blocks = []
    
    # ===== RING COUNTER (16 hoppers in a square) =====
    hopper_positions = [
        # Top row (left to right)
        (0, 0, 0), (2, 0, 0), (4, 0, 0), (6, 0, 0),
        # Right column (top to bottom)
        (6, 0, 2), (6, 0, 4), (6, 0, 6),
        # Bottom row (right to left)
        (6, 0, 8), (4, 0, 8), (2, 0, 8), (0, 0, 8),
        # Left column (bottom to top)
        (0, 0, 6), (0, 0, 4), (0, 0, 2),
        # Extra positions to make 16
        (2, 0, 4), (4, 0, 4)
    ]
    
    for i, (x, y, z) in enumerate(hopper_positions[:16]):
        # Determine hopper facing based on position in ring
        facing = "east"  # Simplified - would need proper ring logic
        blocks.append(Block(x + 10, y, z + 10, "minecraft:hopper",
                           properties={"facing": facing}))
        
        # Comparator to read hopper
        blocks.append(Block(x + 10, 0, z + 11, "minecraft:comparator",
                           properties={"facing": "south", "mode": "compare"}))
    
    # ===== LOOKUP TABLE CHESTS =====
    for entry in lookup_table:
        step = entry['step']
        items = entry['chest_items']
        
        # Position chests in a row
        chest_x = 20 + (step % 8) * 2
        chest_z = 10 + (step // 8) * 4
        
        blocks.append(Block(chest_x, 0, chest_z, "minecraft:chest",
                           nbt={"Items": [{"Slot": 0, "id": "minecraft:cobblestone", 
                                          "Count": items}] if items > 0 else []}))
        
        # Comparator reading chest
        blocks.append(Block(chest_x + 1, 0, chest_z, "minecraft:comparator",
                           properties={"facing": "east", "mode": "compare"}))
    
    # ===== OUTPUT RAILS =====
    # ALPHA output (combined from lookup)
    for x in range(36, 40):
        blocks.append(Block(x, 0, 12, "minecraft:redstone_wire"))
    
    # OMEGA output (complementary)
    for x in range(36, 40):
        blocks.append(Block(x, 0, 14, "minecraft:redstone_wire"))
    
    # ===== VISUALIZATION LAMPS =====
    for i in range(15):
        blocks.append(Block(40 + i, 1, 12, "minecraft:redstone_lamp"))  # ALPHA
        blocks.append(Block(40 + i, 1, 14, "minecraft:redstone_lamp"))  # OMEGA
    
    return Circuit(
        name="phase_evolution_engine",
        description="16-step phase evolution with cos²/sin² lookup",
        blocks=blocks,
        dimensions=(60, 4, 20)
    )


def generate_conservation_verifier() -> Circuit:
    """
    Circuit 9: Conservation Verifier
    
    Checks ALPHA + OMEGA = 15 and signals error if violated.
    """
    blocks = []
    
    # ALPHA input
    blocks.append(Block(0, 0, 2, "minecraft:redstone_wire"))
    blocks.append(Block(1, 0, 2, "minecraft:redstone_wire"))
    
    # OMEGA input  
    blocks.append(Block(0, 0, 0, "minecraft:redstone_wire"))
    blocks.append(Block(1, 0, 0, "minecraft:redstone_wire"))
    
    # Fixed signal 15 source
    blocks.append(Block(2, 0, 4, "minecraft:redstone_block"))
    
    # Compute 15 - OMEGA using comparator subtraction
    blocks.append(Block(2, 0, 1, "minecraft:comparator",
                       properties={"facing": "east", "mode": "subtract"}))
    # Side input from OMEGA
    blocks.append(Block(2, 0, 0, "minecraft:redstone_wire"))
    # Rear input from fixed 15
    blocks.append(Block(2, 0, 2, "minecraft:redstone_wire"))
    
    # Compare (15-OMEGA) with ALPHA
    blocks.append(Block(4, 0, 1, "minecraft:comparator",
                       properties={"facing": "east", "mode": "compare"}))
    
    # If equal (output 0), constraint holds
    # Invert for positive verification signal
    blocks.append(Block(6, 0, 1, "minecraft:stone"))
    blocks.append(Block(6, 1, 1, "minecraft:redstone_torch"))
    
    # Verification output
    blocks.append(Block(7, 0, 1, "minecraft:redstone_wire"))
    
    # Status lamps
    blocks.append(Block(8, 0, 1, "minecraft:lime_stained_glass"))  # VALID
    blocks.append(Block(8, 1, 1, "minecraft:redstone_lamp"))
    
    return Circuit(
        name="conservation_verifier",
        description="Verifies ALPHA + OMEGA = 15 constraint",
        blocks=blocks,
        dimensions=(10, 3, 5)
    )


# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

def export_to_json(circuits: List[Circuit], filepath: str):
    """Export circuits to JSON format for further processing"""
    data = {
        'version': '0.1.0',
        'author': 'Hope&&Sauced Collaborative',
        'description': 'Quantum Redstone Circuit Definitions',
        'circuits': [c.to_dict() for c in circuits]
    }
    
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Exported {len(circuits)} circuits to {filepath}")


def export_lookup_table(table: List[Dict], filepath: str):
    """Export phase lookup table to JSON"""
    with open(filepath, 'w') as f:
        json.dump({
            'version': '0.1.0',
            'description': 'Phase Evolution Lookup Table',
            'max_signal': 15,
            'steps': len(table),
            'entries': table
        }, f, indent=2)
    
    print(f"Exported lookup table ({len(table)} entries) to {filepath}")


def generate_mcfunction(circuit: Circuit, namespace: str = "quantum") -> str:
    """
    Generate Minecraft function file for placing circuit blocks.
    
    Usage in-game: /function quantum:place_<circuit_name>
    """
    lines = [
        f"# {circuit.name}",
        f"# {circuit.description}",
        f"# Dimensions: {circuit.dimensions}",
        f"# Block count: {len(circuit.blocks)}",
        ""
    ]
    
    for block in circuit.blocks:
        props = ""
        if block.properties:
            props = "[" + ",".join(f"{k}={v}" for k, v in block.properties.items()) + "]"
        
        # Use ~ for relative positioning
        cmd = f"setblock ~{block.x} ~{block.y} ~{block.z} {block.block_id}{props}"
        lines.append(cmd)
    
    return "\n".join(lines)


# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    print("=" * 60)
    print("Quantum Redstone Circuit Generator v0.1.0")
    print("Hope&&Sauced Collaborative")
    print("=" * 60)
    print()
    
    # Generate lookup table
    print("Generating phase lookup table...")
    lookup_table = generate_lookup_table(16)
    
    # Print table for verification
    print("\nPhase Evolution Lookup Table:")
    print("-" * 70)
    print(f"{'Step':>4} {'phi':>10} {'cos^2(phi)':>12} {'sin^2(phi)':>12} {'ALPHA':>6} {'OMEGA':>6} {'Viviani':>8}")
    print("-" * 70)
    for entry in lookup_table:
        viviani = "  *  " if entry['is_viviani'] else ""
        print(f"{entry['step']:>4} {entry['phi_fraction']:>10} {entry['cos_sq']:>12.4f} {entry['sin_sq']:>12.4f} {entry['alpha']:>6} {entry['omega']:>6} {viviani:>8}")
    print("-" * 70)
    print()

    # Verify conservation
    all_valid = all(entry['conservation_check'] for entry in lookup_table)
    print(f"Conservation constraint (ALPHA + OMEGA = 15): {'OK VERIFIED' if all_valid else 'FAILED'}")
    print()
    
    # Generate circuits
    print("Generating circuits...")
    circuits = [
        generate_state_preparation(),
        generate_pauli_x(),
        generate_pauli_z(),
        generate_hadamard(),
        generate_cnot(),
        generate_phase_engine(lookup_table),
        generate_conservation_verifier()
    ]
    
    for circuit in circuits:
        print(f"  - {circuit.name}: {len(circuit.blocks)} blocks, {circuit.dimensions}")
    
    print()
    
    # Export (use current directory on Windows)
    import os
    output_dir = os.path.dirname(os.path.abspath(__file__))

    export_to_json(circuits, os.path.join(output_dir, 'quantum_circuits.json'))
    export_lookup_table(lookup_table, os.path.join(output_dir, 'phase_lookup_table.json'))

    # Generate mcfunction files
    print("\nGenerating mcfunction files...")
    mcfunc_dir = os.path.join(output_dir, 'mcfunctions')
    os.makedirs(mcfunc_dir, exist_ok=True)
    for circuit in circuits:
        mcfunc = generate_mcfunction(circuit)
        filepath = os.path.join(mcfunc_dir, f'place_{circuit.name}.mcfunction')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(mcfunc)
        print(f"  - {filepath}")
    
    print()
    print("=" * 60)
    print("Generation complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
