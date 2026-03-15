extends EnemyState

## How long the enemy is stunned after the charge ends.
@export var recovery_duration: float = 0.8

## Animation state to play during recovery.
@export var animation_state: StringName = &"ChargeRecovery"

var _timer: float = 0.0


func _init() -> void:
	state_id = EnemyStateId.CHARGE_RECOVERY


func _enter() -> void:
	_timer = recovery_duration

	enemy.stop_movement()
	enemy.play_animation(animation_state)

	# Kill any remaining manual velocity from the charge.
	if enemy.movement_module:
		enemy.movement_module.stop_manual_motion()


func _update(delta: float) -> void:
	_timer -= delta

	if _timer > 0.0:
		return

	# Recovery done — resume normal behaviour.
	if enemy.is_player_in_aggro_range():
		change_state(EnemyStateId.CHASE)
	else:
		change_state(EnemyStateId.BACK)
