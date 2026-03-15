class_name PlayerMoveState
extends State

@export var actor: Player
@export var walk_speed: float = 180.0
@export var run_speed: float = 240.0
@export var idle_grace_time: float = 0.08

var _idle_timer := 0.0


func _ready() -> void:
    state_id = Player.StateId.MOVE


func _enter() -> void:
    _idle_timer = 0.0

    if not actor:
        return

    actor.play_actor_animation(Player.AnimationState.Move, actor.animation_module.get_last_direction() if actor.animation_module else Vector2.DOWN)


func _physics_update(delta: float) -> void:
    if not actor:
        return

    var input_dir := actor.get_move_input()
    var speed := run_speed if actor.is_run_pressed() else walk_speed

    if actor.movement_module:
        actor.movement_module.set_manual_mode()
        actor.movement_module.set_manual_velocity(input_dir.normalized() * speed)

    if input_dir != Vector2.ZERO:
        if actor.animation_module:
            actor.animation_module.face_direction(input_dir)
            actor.animation_module.set_blend_position(input_dir, Player.AnimationState.Move)
        _idle_timer = 0.0
    else:
        _idle_timer += delta


func _update(_delta: float) -> void:
    if not actor:
        return

    if actor.consume_dodge_request():
        change_state(Player.StateId.ROLL)
        return

    if not actor.is_run_pressed():
        if actor.consume_attack_request() or actor.has_auto_attack_target():
            change_state(Player.StateId.ATTACK)
            return

    if _idle_timer >= idle_grace_time:
        change_state(Player.StateId.IDLE)


func _exit() -> void:
    if actor and actor.movement_module:
        actor.movement_module.stop_manual_motion()
