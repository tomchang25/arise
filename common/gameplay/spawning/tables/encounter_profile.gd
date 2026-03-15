class_name EncounterProfile
extends Resource

@export var groups: Array[EnemyGroupProfile] = []


func is_valid() -> bool:
    if groups.is_empty():
        return false

    for group in groups:
        if group != null and group.is_valid():
            return true

    return false


func get_valid_groups() -> Array[EnemyGroupProfile]:
    var result: Array[EnemyGroupProfile] = []
    for group in groups:
        if group != null and group.is_valid():
            result.append(group)
    return result
