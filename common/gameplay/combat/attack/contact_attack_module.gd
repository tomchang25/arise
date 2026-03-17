class_name ContactAttackModule
extends PersistentAttackModule

## Assigned by CombatModule at setup time from the actor's HitboxSlots.
## Not exported — do not wire in the inspector.
var hitbox: Hitbox = null

## If true, the actor's own hurtbox also receives the hit on each contact.
## Wired by CombatModule if needed.
var hurt_self: bool = false

## Only needed when hurt_self is true. Assigned by CombatModule.
var owner_hurtbox: Hurtbox = null

var _active_data: AttackData = null

# -------------------------
# Setup
# -------------------------


## Called by CombatModule after instantiation to inject the hitbox reference.
func setup(assigned_hitbox: Hitbox) -> void:
    hitbox = assigned_hitbox
    if hitbox and not hitbox.hit_enemy.is_connected(_on_hit):
        hitbox.hit_enemy.connect(_on_hit)


# -------------------------
# Internal — persistent delivery
# -------------------------


func _activate_logic(data: AttackData) -> void:
    if hitbox == null:
        push_error("ContactAttackModule: hitbox is not set")
        return

    _active_data = data
    hitbox.attack_info = data
    hitbox.enabled = true


func _deactivate_logic() -> void:
    _active_data = null

    if hitbox:
        hitbox.enabled = false


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_hit() -> void:
    if not hurt_self:
        return

    if owner_hurtbox == null:
        push_warning("ContactAttackModule: hurt_self is true but owner_hurtbox is not set")
        return

    if _active_data:
        owner_hurtbox.receive_hit(_active_data)
