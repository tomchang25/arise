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


## Weighted selection restricted to entries whose profile matches the requested role.
## Returns null when no matching entry exists.
func pick_group_by_role(role: EnemyGroupProfile.GroupRole, rng: RandomNumberGenerator = null) -> EnemyGroupProfile:
    if entries.is_empty():
        return null

    var filtered: Array[EncounterGroupEntry] = []
    for entry in entries:
        if entry != null and entry.is_valid() and entry.group_profile.role == role:
            filtered.append(entry)

    if filtered.is_empty():
        return null

    var picked := RandomUtils.pick_weighted_entry(filtered, rng) as EncounterGroupEntry
    if picked == null:
        return null

    return picked.group_profile


func is_valid() -> bool:
    for entry in entries:
        if entry != null and entry.is_valid():
            return true
    return false
