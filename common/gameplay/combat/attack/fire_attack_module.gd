class_name FireAttackModule
extends Node2D

@export var attack_cooldown: float = 0.5

var cooldown_timer: Timer
var locked := false


# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _setup_timer()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(func(): locked = false)
    add_child(cooldown_timer)


# -------------------------
# Common API
# -------------------------


func can_attack() -> bool:
    return not locked


## Locks the module and dispatches to the subclass implementation.
func execute_attack(target_position: Vector2, data: AttackData) -> void:
    if locked:
        return

    if data == null:
        push_error("FireAttackModule: data is null")
        return

    locked = true
    _execute_attack_logic(target_position, data)


## Start the cooldown. Call immediately after execute_attack for auto-end,
## or defer to an animation_finished signal for animation-driven flow.
func end_attack() -> void:
    if cooldown_timer.is_stopped():
        cooldown_timer.start()


# -------------------------
# Internal — override in subclasses
# -------------------------


func _execute_attack_logic(_target_position: Vector2, _data: AttackData) -> void:
    pass
