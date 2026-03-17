class_name ContactAttackModule
extends PersistentAttackModule

## Assigned by CombatModule at setup time from the actor's HitboxSlots.
## Not exported — do not wire in the inspector.
var hitbox: Hitbox = null

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
        push_error("ContactAttackModule: hitbox is not set")
        return

    hitbox.attack_info = data
    hitbox.damage_interval = data.damage_interval
    hitbox.clear_records_on_exit = data.clear_records_on_exit
    hitbox.enabled = true


func _deactivate_logic() -> void:
    if hitbox:
        hitbox.enabled = false

# -------------------------
# Signals / Callbacks
# -------------------------
