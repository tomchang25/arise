class_name WeightedSceneTable
extends Resource

@export var entries: Array[WeightedSceneEntry] = []


func pick_scene(rng: RandomNumberGenerator = null) -> PackedScene:
    if entries.is_empty():
        return null

    var picked_entry := RandomUtils.pick_weighted_entry(entries, rng) as WeightedSceneEntry
    if picked_entry == null:
        return null

    return picked_entry.scene
