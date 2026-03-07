class_name PlayerRollState
extends State

@export var actor: Player
@export var roll_speed: float = 240.0

var _roll_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
    state_id = Player.StateId.ROLL


func _enter() -> void:
    if not actor:
        return

    _roll_direction = actor.get_move_input()
    if _roll_direction == Vector2.ZERO and actor.animation_module:
        _roll_direction = actor.animation_module.get_last_direction()
    if _roll_direction == Vector2.ZERO:
        _roll_direction = Vector2.DOWN

    _roll_direction = _roll_direction.normalized()

    if not actor.roll_finished.is_connected(_on_roll_finished):
        actor.roll_finished.connect(_on_roll_finished)

    if actor.movement_module:
        actor.movement_module.set_manual_mode()
        actor.movement_module.set_manual_velocity(_roll_direction * roll_speed)

    actor.play_actor_animation(Player.AnimationState.Roll, _roll_direction, 2.0)


func _physics_update(_delta: float) -> void:
    if not actor or not actor.movement_module:
        return

    actor.movement_module.set_manual_velocity(_roll_direction * roll_speed)


func _exit() -> void:
    if actor and actor.roll_finished.is_connected(_on_roll_finished):
        actor.roll_finished.disconnect(_on_roll_finished)

    if actor and actor.movement_module:
        actor.movement_module.stop_manual_motion()


func _on_roll_finished() -> void:
    if not actor:
        change_state(Player.StateId.IDLE)
        return

    if actor.get_move_input() != Vector2.ZERO:
        change_state(Player.StateId.MOVE)
        return
    else:
        change_state(Player.StateId.IDLE)
        return
