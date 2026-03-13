class_name WeightedEncounterTable
extends Resource

@export var entries: Array[WeightedEncounterEntry] = []


func pick_encounter(rng: RandomNumberGenerator = null) -> EnemyEncounterProfile:
    if entries.is_empty():
        return null

    var picked_entry := RandomUtils.pick_weighted_entry(entries, rng) as WeightedEncounterEntry
    if picked_entry == null:
        return null

    return picked_entry.encounter
