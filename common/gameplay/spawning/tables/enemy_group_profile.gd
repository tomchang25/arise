class_name EnemyGroupProfile
extends Resource

enum GroupRole { CLOSED, RANGED }

@export_group("Role")
## Every profile must declare its combat role.
## CLOSED groups occupy the closed lane; RANGED groups occupy the ranged lane.
@export var role: GroupRole = GroupRole.CLOSED

@export_group("Group Scene")
@export var group_scene: PackedScene

@export_group("Members")
@export var entries: Array[GroupMemberEntry] = []

@export_group("Group Size")
@export var min_total: int = 1
@export var max_total: int = 10

@export_group("Spawn Scatter")
@export var spawn_radius: float = 30.0

@export_group("Formation")
## Formation layout to apply when the group is spawned.
## NONE keeps the random scatter positions; RECTANGULAR and CIRCULAR use slot-based grids.
@export var formation_type: EnemyGroup.FormationType = EnemyGroup.FormationType.NONE


func is_valid() -> bool:
    if group_scene == null:
        return false

    if entries.is_empty():
        return false

    for entry in entries:
        if entry != null and entry.is_valid():
            return true

    return false
