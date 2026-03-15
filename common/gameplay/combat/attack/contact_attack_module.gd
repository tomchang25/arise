class_name ContactAttackModule
extends PersistentAttackModule

## The hitbox covering the actor's body. Wired by the actor in _wire_modules().
@export var hitbox: Hitbox

## If true, the actor's own hurtbox also receives the hit on each contact.
@export var hurt_self: bool = false

## The actor's own hurtbox. Only needed when hurt_self is true.
## Wired by the actor in _wire_modules().
@export var owner_hurtbox: Hurtbox

var _active_data: AttackData = null

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if hitbox:
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
