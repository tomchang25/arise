extends EnemyState

## Maximum time the enemy can charge before recovery is forced.
@export var charge_duration: float = 1.0

## Movement speed during the charge.
@export var charge_speed: float = 400.0

## Animation state to play during the charge.
@export var animation_state: StringName = &"Charge"

## Attack slot wired to the ChargeAttackModule.
@export var attack_slot: Stats.AttackSlot = Stats.AttackSlot.PRIMARY

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
	if enemy.combat_module:
		enemy.combat_module.activate_attack(attack_slot, _direction)


func _exit() -> void:
	# Always disable the hitbox when leaving, regardless of exit reason.
	if enemy.combat_module:
		enemy.combat_module.deactivate_attack(attack_slot)


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
