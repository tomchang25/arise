class_name PlayerIdleState
extends State

@export var actor: Player


func _ready() -> void:
    state_id = Player.StateId.IDLE


func _enter() -> void:
    if not actor:
        return

    if actor.movement_module:
        actor.movement_module.stop_manual_motion()

    actor.play_actor_animation(Player.AnimationState.Idle, actor.animation_module.get_last_direction() if actor.animation_module else Vector2.DOWN)


func _update(_delta: float) -> void:
    if not actor:
        return

    if actor.consume_attack_request():
        change_state(Player.StateId.ATTACK)
        return

    if actor.consume_dodge_request():
        change_state(Player.StateId.ROLL)
        return

    if actor.get_move_input() != Vector2.ZERO:
        change_state(Player.StateId.MOVE)
