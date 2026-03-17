class_name ChargeAttackModule
extends PersistentAttackModule

## Assigned by CombatModule at setup time from the actor's HitboxSlots.
## Not exported — do not wire in the inspector.
var hitbox: Hitbox = null

## When true, the hitbox is rotated to match facing_direction on each activate call.
## AnimationPlayer handles positional offsets; this only covers the rotation snap
## needed when the AnimationPlayer is NOT driving rotation (e.g. pure code-driven charge).
var track_facing: bool = false

## Set by the AI / state machine before calling activate_attack if track_facing is true.
var facing_direction: Vector2 = Vector2.RIGHT

# -------------------------
# Setup
# -------------------------


## Called by CombatModule after instantiation to inject the hitbox reference.
func setup(assigned_hitbox: Hitbox) -> void:
    hitbox = assigned_hitbox


# -------------------------
# Internal — persistent delivery
# -------------------------


func _activate_logic(data: AttackData) -> void:
    if hitbox == null:
        push_error("ChargeAttackModule: hitbox is not set")
        return

    if track_facing:
        _orient_hitbox()

    hitbox.attack_info = data
    hitbox.enabled = true


func _deactivate_logic() -> void:
    if hitbox:
        hitbox.enabled = false


# -------------------------
# Internal Helpers
# -------------------------


func _orient_hitbox() -> void:
    if facing_direction.length_squared() <= 0.0001:
        return
    hitbox.rotation = facing_direction.angle()
