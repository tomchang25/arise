extends EnemyState

## How long the enemy pauses and telegraphs before charging.
@export var windup_duration: float = 0.6

## Animation state to play during windup.
@export var animation_state: StringName = &"ChargeWindup"

var _timer: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT


func _init() -> void:
    state_id = EnemyStateId.CHARGE_WINDUP


func _enter() -> void:
    _timer = windup_duration

    # Lock in the direction toward the player right now — charge fires this way.
    var target := enemy.get_nearest_aggro_target()
    if target:
        _charge_direction = enemy.global_position.direction_to(target.global_position)
    else:
        _charge_direction = enemy.get_facing_direction()

    enemy.stop_movement()
    enemy.set_facing_direction(_charge_direction, animation_state)
    enemy.play_animation(animation_state)


func _update(delta: float) -> void:
    _timer -= delta

    if _timer <= 0.0:
        change_state(EnemyStateId.CHARGE)
