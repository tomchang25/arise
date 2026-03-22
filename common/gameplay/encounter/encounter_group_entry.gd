class_name EncounterGroupEntry
extends Resource

@export var group_profile: EnemyGroupProfile
@export_range(1, 100) var weight: int = 10


func is_valid() -> bool:
    return group_profile != null and group_profile.is_valid()
