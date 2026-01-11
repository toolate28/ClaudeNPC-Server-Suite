# state_preparation
# Prepares basis states |0⟩ or |1⟩
# Dimensions: (10, 3, 3)
# Block count: 16

setblock ~0 ~1 ~1 minecraft:lever[face=floor,facing=east]
setblock ~1 ~0 ~1 minecraft:redstone_wire
setblock ~2 ~0 ~1 minecraft:redstone_wire
setblock ~3 ~0 ~1 minecraft:redstone_wire
setblock ~4 ~0 ~1 minecraft:redstone_wire
setblock ~5 ~0 ~1 minecraft:redstone_wire
setblock ~6 ~0 ~1 minecraft:redstone_wire
setblock ~1 ~0 ~0 minecraft:stone
setblock ~1 ~1 ~0 minecraft:redstone_torch[facing=up]
setblock ~2 ~0 ~0 minecraft:redstone_wire
setblock ~3 ~0 ~0 minecraft:redstone_wire
setblock ~4 ~0 ~0 minecraft:redstone_wire
setblock ~5 ~0 ~0 minecraft:redstone_wire
setblock ~6 ~0 ~0 minecraft:redstone_wire
setblock ~7 ~0 ~1 minecraft:green_stained_glass
setblock ~7 ~0 ~0 minecraft:blue_stained_glass