extends Node


func pick_weighted_index(weights: Array[int], rng: RandomNumberGenerator = null) -> int:
    if weights.is_empty():
        return -1

    var total_weight := 0
    for weight in weights:
        total_weight += max(weight, 0)

    if total_weight <= 0:
        return -1

    var resolved_rng := rng if rng != null else _create_fallback_rng()
    var roll := resolved_rng.randi_range(1, total_weight)

    var cumulative := 0
    for i in range(weights.size()):
        cumulative += max(weights[i], 0)
        if roll <= cumulative:
            return i

    return -1


func pick_weighted_entry(entries: Array, rng: RandomNumberGenerator = null):
    if entries.is_empty():
        return null

    var weights: Array[int] = []
    weights.resize(entries.size())

    for i in range(entries.size()):
        var entry = entries[i]
        if entry == null:
            weights[i] = 0
        elif "weight" in entry:
            weights[i] = max(entry.weight, 0)
        else:
            weights[i] = 0

    var picked_index := pick_weighted_index(weights, rng)
    if picked_index < 0 or picked_index >= entries.size():
        return null

    return entries[picked_index]


func random_point_in_radius(radius: float, rng: RandomNumberGenerator = null) -> Vector2:
    if radius <= 0.0:
        return Vector2.ZERO

    var resolved_rng := rng if rng != null else _create_fallback_rng()
    var angle := resolved_rng.randf_range(0.0, TAU)
    var distance := sqrt(resolved_rng.randf()) * radius
    return Vector2.RIGHT.rotated(angle) * distance


static func _create_fallback_rng() -> RandomNumberGenerator:
    var new_rng := RandomNumberGenerator.new()
    new_rng.randomize()
    return new_rng
