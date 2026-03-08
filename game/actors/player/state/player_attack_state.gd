class_name PlayerAttackState
extends State

@export var actor: Player
@export var attack_move_speed: float = 40.0
@export var attack_slot: Stats.AttackSlot = Stats.AttackSlot.PRIMARY

var _attack_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
    state_id = Player.StateId.ATTACK


func _enter() -> void:
    if not actor:
        return

    var target_pos := actor.get_attack_target_position()
    _attack_direction = target_pos - actor.global_position

    if _attack_direction == Vector2.ZERO:
        _attack_direction = actor.get_aim_direction()

    if _attack_direction == Vector2.ZERO:
        _attack_direction = Vector2.DOWN

    _attack_direction = _attack_direction.normalized()

    if not actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.connect(_on_attack_finished)

    actor.play_actor_animation(Player.AnimationState.Attack, _attack_direction)

    if actor.combat_module:
        actor.combat_module.perform_attack(attack_slot, target_pos)


func _physics_update(_delta: float) -> void:
    if not actor or not actor.movement_module:
        return

    var input_dir := actor.get_move_input().normalized()
    actor.movement_module.set_manual_mode()
    actor.movement_module.set_manual_velocity(input_dir * attack_move_speed)


func _exit() -> void:
    if actor and actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.disconnect(_on_attack_finished)

    if actor and actor.movement_module:
        actor.movement_module.stop_manual_motion()


func _on_attack_finished() -> void:
    if not actor:
        change_state(Player.StateId.IDLE)
        return

    if actor.get_move_input() != Vector2.ZERO:
        change_state(Player.StateId.MOVE)
    else:
        change_state(Player.StateId.IDLE)
