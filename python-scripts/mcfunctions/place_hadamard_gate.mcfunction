# hadamard_gate
# Hadamard gate - creates superposition, includes measurement
# Dimensions: (15, 5, 10)
# Block count: 12

setblock ~5 ~0 ~3 minecraft:chest
setblock ~6 ~0 ~3 minecraft:comparator[facing=east,mode=compare]
setblock ~9 ~0 ~3 minecraft:chest
setblock ~8 ~0 ~3 minecraft:comparator[facing=west,mode=compare]
setblock ~7 ~2 ~3 minecraft:stone
setblock ~7 ~1 ~3 minecraft:dropper[facing=down]
setblock ~7 ~2 ~4 minecraft:stone
setblock ~7 ~2 ~3 minecraft:stone_button[face=wall,facing=south]
setblock ~6 ~0 ~3 minecraft:hopper[facing=down]
setblock ~8 ~0 ~3 minecraft:hopper[facing=down]
setblock ~6 ~0 ~2 minecraft:comparator[facing=south,mode=compare]
setblock ~8 ~0 ~2 minecraft:comparator[facing=south,mode=compare]