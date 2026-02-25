class_name WeightedEncounterTable
extends Resource

@export var entries: Array[WeightedEncounterEntry] = []


func pick(rng: RandomNumberGenerator = null) -> EnemyEncounterProfile:
    if entries.is_empty():
        push_warning("WeightedEncounterTable: entries is empty")
        return null

    var total := 0
    for e in entries:
        total += max(0, e.weight)

    if total <= 0:
        push_warning("WeightedEncounterTable: total weight <= 0")
        return null

    var roll := (rng if rng else _fallback_rng()).randi_range(1, total)
    var acc := 0
    for e in entries:
        acc += max(0, e.weight)
        if roll <= acc:
            return e.encounter

    return null


func _fallback_rng() -> RandomNumberGenerator:
    var r := RandomNumberGenerator.new()
    r.randomize()
    return r

# func get_random_mob(rng: RandomNumberGenerator = null) -> Resource:
#     if entries.is_empty():
#         push_warning("WeightedSpawnTable: entries is empty")
#         return null

#     var total_weight := 0
#     for e in entries:
#         total_weight += max(0, e.weight)

#     if total_weight <= 0:
#         push_warning("WeightedSpawnTable: total_weight <= 0")
#         return null

#     var roll := 0
#     if rng:
#         roll = rng.randi_range(1, total_weight)
#     else:
#         roll = randi_range(1, total_weight)

#     var sum := 0
#     for e in entries:
#         sum += max(0, e.weight)
#         if roll <= sum:
#             return e.mob_scene

#     return null
