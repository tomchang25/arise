class_name ArmyState
extends State

enum ArmyStateId { NULL = -1, IDLE = 0, FOLLOW = 1, CHASE = 2, RETREAT = 3, ATTACK = 4 }

@export var animation_state: String
var target: Army


func _ready() -> void:
    if owner == null:
        push_error("ArmyState must have an owner")
        return

    if not owner.is_node_ready():
        await owner.ready

    if owner is not Army:
        push_error("ArmyState owner must be an Army")
        return

    target = owner
