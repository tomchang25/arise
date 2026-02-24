class_name WeightedSpawnTable
extends Resource

@export var entries: Array[SpawnEntry]


func get_random_mob() -> Resource:
    var total_weight = 0
    for entry in entries:
        total_weight += entry.weight

    var roll = randi_range(1, total_weight)
    var current_sum = 0

    for entry in entries:
        current_sum += entry.weight
        if roll <= current_sum:
            return entry.mob_scene  # This can now be a .tscn or a .tres

    return null
