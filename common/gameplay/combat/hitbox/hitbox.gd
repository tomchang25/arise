class_name Hitbox
extends Area2D

signal hit_enemy

@export var enabled = true:
    set(value):
        enabled = value
        set_deferred("monitoring", value)
        if not value:
            _hit_times.clear()

## Seconds between repeated hits on the same victim.
## 0 = hit once on enter only, never repeat.
@export var damage_interval: float = 0.0

@export var clear_records_on_exit := true

## Identifier used by CombatModule to bind this hitbox to an AttachedAttackDefinition.
## Set this in the inspector to match the slot_id on the corresponding definition.
@export var slot_id: StringName = ""

var collision_node: CollisionShape2D

var attack_info: AttackData:
    set(value):
        attack_info = value
        if is_inside_tree():
            _setup_collision_layers()

var shape: Shape2D:
    set(value):
        shape = value
        if is_inside_tree():
            _setup_collision_shape()

## Tracks the last hit time per victim. Key = Area2D, value = time in seconds.
var _hit_times: Dictionary = {}


func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)
    monitorable = false
    monitoring = enabled

    _setup_collision_shape()
    _setup_collision_layers()


func _process(_delta: float) -> void:
    if not enabled or damage_interval <= 0.0:
        return

    # Purge stale records for victims that left the tree without triggering area_exited.
    for area in _hit_times.keys():
        if not is_instance_valid(area):
            _hit_times.erase(area)

    # Re-hit victims still inside the hitbox if their interval has elapsed.
    for area in get_overlapping_areas():
        _try_hit(area)


# -------------------------
# Signals
# -------------------------


func _on_area_entered(area: Area2D) -> void:
    if not enabled:
        return
    _try_hit(area)


func _on_area_exited(area: Area2D) -> void:
    if not enabled or not clear_records_on_exit:
        return

    _hit_times.erase(area)


# -------------------------
# Internal
# -------------------------


func _try_hit(area: Area2D) -> void:
    if not is_instance_valid(area):
        return

    var now := Time.get_ticks_msec() / 1000.0

    if _hit_times.has(area):
        # Victim already hit — only re-hit if interval has elapsed.
        if damage_interval <= 0.0:
            return
        if now - _hit_times[area] < damage_interval:
            return

    _hit_times[area] = now
    _apply_hit(area)


func _apply_hit(area: Area2D) -> void:
    if area.has_method("receive_hit"):
        area.receive_hit(attack_info)
        hit_enemy.emit()


# -------------------------
# Setup
# -------------------------


func _setup_collision_shape() -> void:
    if not collision_node:
        for child in get_children():
            if child is CollisionShape2D:
                collision_node = child
                break

        if not collision_node:
            collision_node = CollisionShape2D.new()
            add_child(collision_node)

    # Only overwrite the shape if one was explicitly injected via the shape setter.
    # If shape is null, the CollisionShape2D keeps whatever was authored in the scene.
    if shape != null:
        collision_node.shape = shape


func _setup_collision_layers() -> void:
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)

    collision_mask = 0
    if attack_info:
        for faction in attack_info.target_factions:
            match faction:
                Stats.Faction.PLAYER:
                    set_collision_mask_value(Global.PLAYER_HURTBOX, true)
                Stats.Faction.ENEMY:
                    set_collision_mask_value(Global.ENEMY_HURTBOX, true)
