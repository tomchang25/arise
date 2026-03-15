class_name ChargeAttackModule
extends PersistentAttackModule

## The hitbox placed on the actor's front face. Wired by the actor in _wire_modules().
## Shape and offset should be authored along Vector2.RIGHT in the scene.
@export var hitbox: Hitbox

## When true, the hitbox is rotated to match facing_direction on each activate call.
@export var track_facing: bool = true

## Set by the actor or CombatModule before calling activate_attack.
var facing_direction: Vector2 = Vector2.RIGHT

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
