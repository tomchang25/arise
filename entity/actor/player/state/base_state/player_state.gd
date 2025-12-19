class_name PlayerState
extends State

enum PlayerStateId { NULL = -1, IDLE = 0, MOVE = 1, ROLL = 2, ATTACK = 3 }

@export var animation_state: String

var player: Player


func _ready() -> void:
    if owner is not Player:
        push_error("PlayerState owner must be a Player")

    player = owner

    if not player.is_node_ready():
        await player.ready

    player.animation.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(_anim_name: StringName) -> void:
    pass
