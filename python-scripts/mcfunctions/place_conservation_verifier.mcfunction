# conservation_verifier
# Verifies ALPHA + OMEGA = 15 constraint
# Dimensions: (10, 3, 5)
# Block count: 14

setblock ~0 ~0 ~2 minecraft:redstone_wire
setblock ~1 ~0 ~2 minecraft:redstone_wire
setblock ~0 ~0 ~0 minecraft:redstone_wire
setblock ~1 ~0 ~0 minecraft:redstone_wire
setblock ~2 ~0 ~4 minecraft:redstone_block
setblock ~2 ~0 ~1 minecraft:comparator[facing=east,mode=subtract]
setblock ~2 ~0 ~0 minecraft:redstone_wire
setblock ~2 ~0 ~2 minecraft:redstone_wire
setblock ~4 ~0 ~1 minecraft:comparator[facing=east,mode=compare]
setblock ~6 ~0 ~1 minecraft:stone
setblock ~6 ~1 ~1 minecraft:redstone_torch
setblock ~7 ~0 ~1 minecraft:redstone_wire
setblock ~8 ~0 ~1 minecraft:lime_stained_glass
setblock ~8 ~1 ~1 minecraft:redstone_lamp