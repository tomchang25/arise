class_name WeightedSceneTable
extends Resource

@export var entries: Array[WeightedSceneEntry] = []

func pick_scene(rng: RandomNumberGenerator = null) -> PackedScene:
    if entries.is_empty():
        push_error("WeightedSceneTable: entries is empty")
        return null

    var total := 0
    for e in entries:
        if e == null:
            continue
        total += max(0, e.weight)

    if total <= 0:
        push_error("WeightedSceneTable: total weight <= 0")
        return null

    var r := rng if rng != null else _fallback_rng()
    var roll := r.randi_range(1, total)

    var acc := 0
    for e in entries:
        if e == null:
            continue
        acc += max(0, e.weight)
        if roll <= acc:
            if e.scene == null:
                push_error("WeightedSceneTable: picked entry has null scene")
                return null
            return e.scene

    # Should never happen, but safe fallback
    push_error("WeightedSceneTable: pick fell through (unexpected)")
    return null

func _fallback_rng() -> RandomNumberGenerator:
    var r := RandomNumberGenerator.new()
    r.randomize()
    return r
