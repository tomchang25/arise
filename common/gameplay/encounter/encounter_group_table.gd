class_name EncounterGroupTable
extends Resource

@export var entries: Array[EncounterGroupEntry] = []


func pick_group(rng: RandomNumberGenerator = null) -> EnemyGroupProfile:
	if entries.is_empty():
		return null

	var picked := RandomUtils.pick_weighted_entry(entries, rng) as EncounterGroupEntry
	if picked == null:
		return null

	return picked.group_profile


func is_valid() -> bool:
	for entry in entries:
		if entry != null and entry.is_valid():
			return true
	return false
