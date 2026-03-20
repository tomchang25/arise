class_name DetachedAttackModule
extends AttackModule
## Base for detached (fire-and-forget) attack modules (Place, Projectile, Trap, etc.).
##
## Owns the cooldown timer, locked state, def reference, and stats reference.
## Subclasses override _execute_attack_logic() to implement delivery-specific behaviour.
##
## AttackData is built inside _execute_attack_logic() using the stored def + stats,
## so CombatModule never needs to build or pass data for detached types.
##
## Overrides execute_attack, end_attack, can_attack from AttackModule.
## activate_attack / deactivate_attack are not overridden — calls to those
## on a detached module will warn via the AttackModule base.

var attack_def: AttackDefinition = null
var owner_stats: Stats = null

var cooldown_timer: Timer
var locked := false


# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
    _setup_timer()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = _cooldown()
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(
        func():
            locked = false
    )
    add_child(cooldown_timer)


# -------------------------
# Setup
# -------------------------
## Called by WeaponExecutor after instantiation.
func setup(def: AttackDefinition, stats: Stats) -> void:
    attack_def = def
    owner_stats = stats
    if cooldown_timer:
        cooldown_timer.wait_time = _cooldown()


# -------------------------
# AttackModule overrides
# -------------------------
func can_attack() -> bool:
    return enabled and not locked


## Locks the module and dispatches to the subclass implementation.
func execute_attack(target_position: Vector2) -> void:
    if not enabled:
        return

    if locked:
        return

    if attack_def == null:
        push_error("%s: attack_def is null — was setup() called?" % get_class())
        return

    if owner_stats == null:
        push_error("%s: owner_stats is null — was setup() called?" % get_class())
        return

    locked = true
    _execute_attack_logic(target_position)


## Start the cooldown. Call immediately after execute_attack for auto-end,
## or defer to an animation_finished signal for animation-driven flow.
func end_attack() -> void:
    if cooldown_timer.is_stopped():
        cooldown_timer.start()


# -------------------------
# Internal — override in subclasses
# -------------------------
func _execute_attack_logic(_target_position: Vector2) -> void:
    pass


func _cooldown() -> float:
    if attack_def is DetachedAttackDefinition:
        return max((attack_def as DetachedAttackDefinition).cooldown, 0.01)
    return 0.5
