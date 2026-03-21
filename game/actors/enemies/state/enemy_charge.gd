extends EnemyState

## Maximum time the enemy can charge before recovery is forced.
@export var charge_duration: float = 1.0

## Movement speed during the charge.
@export var charge_speed: float = 400.0

## Animation state to play during the charge.
@export var animation_state: StringName = &"Charge"

## Which weapon holds the charge attack (index into CombatModule.weapons).
@export var weapon_index: int = 0

## Which attack within that weapon is the charge hitbox (index into WeaponData.attacks).
@export var attack_index: int = 0

var _timer: float = 0.0
var _direction: Vector2 = Vector2.RIGHT


func _init() -> void:
	state_id = EnemyStateId.CHARGE


func _enter() -> void:
	_timer = charge_duration

	# Pull the locked direction from the windup state via the enemy's facing.
	_direction = enemy.get_facing_direction()

	enemy.play_animation(animation_state)
	enemy.stop_movement()

	# Enable the charge hitbox.
	enemy.activate_attack(weapon_index, attack_index)


func _exit() -> void:
	# Always disable the hitbox when leaving, regardless of exit reason.
	enemy.deactivate_attack(weapon_index, attack_index)


func _physics_update(delta: float) -> void:
	_timer -= delta

	if _timer <= 0.0:
		change_state(EnemyStateId.CHARGE_RECOVERY)
		return

	# Drive movement manually — ignore navigation, charge in a fixed direction.
	if enemy.movement_module:
		enemy.movement_module.set_manual_mode()
		enemy.movement_module.set_manual_velocity(_direction * charge_speed)

	# End early on wall collision.
	if enemy.is_on_wall():
		change_state(EnemyStateId.CHARGE_RECOVERY)
