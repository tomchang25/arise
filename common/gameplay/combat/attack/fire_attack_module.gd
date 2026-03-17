class_name FireAttackModule
extends Node2D

## When false, can_attack() returns false and execute_attack() is a no-op.
## Set by CombatModule or a buff/debuff system to suppress this executor
## without tearing down the weapon entirely.
var enabled: bool = true

## Cooldown is set by CombatModule at spawn time from AttackDefinition.cooldown.
## Do not export this — it is not configured in the inspector.
var attack_cooldown: float = 0.5

var cooldown_timer: Timer
var locked := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _setup_timer()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = max(attack_cooldown, 0.01)
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(func(): locked = false)
    add_child(cooldown_timer)


# -------------------------
# Setup
# -------------------------


## Called by CombatModule after instantiation to inject the cooldown value.
func setup(cooldown: float) -> void:
    attack_cooldown = max(cooldown, 0.01)
    if cooldown_timer:
        cooldown_timer.wait_time = attack_cooldown


# -------------------------
# Common API
# -------------------------


func can_attack() -> bool:
    return enabled and not locked


## Locks the module and dispatches to the subclass implementation.
func execute_attack(target_position: Vector2, data: AttackData) -> void:
    if not enabled:
        return

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
