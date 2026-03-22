class_name EnemyGroupProfile
extends Resource

@export_group("Group Scene")
@export var group_scene: PackedScene

@export_group("Members")
@export var entries: Array[GroupMemberEntry] = []

@export_group("Group Size")
@export var min_total: int = 1
@export var max_total: int = 10

@export_group("Spawn Scatter")
@export var spawn_radius: float = 60.0


func is_valid() -> bool:
    if group_scene == null:
        return false

    if entries.is_empty():
        return false

    for entry in entries:
        if entry != null and entry.is_valid():
            return true

    return false
