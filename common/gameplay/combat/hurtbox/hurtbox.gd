@tool
class_name Hurtbox
extends Area2D

signal get_hit(attack_info: AttackData)

@export var enabled = true:
    set(value):
        enabled = value
        set_deferred("monitorable", value)

var owner_stats: Stats:
    set(value):
        owner_stats = value
        if is_inside_tree():
            _setup_collision_layers()


func _init() -> void:
    monitoring = false


func _ready() -> void:
    if not owner_stats and owner.get("stats"):
        owner_stats = owner.stats

    set_deferred("monitorable", enabled)
    _setup_collision_layers()

    _setup_collision_layers()


func _setup_collision_layers() -> void:
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)

    if not owner_stats:
        return

    match owner_stats.faction:
        Stats.Faction.PLAYER:
            set_collision_layer_value(Global.PLAYER_HURTBOX, true)
        Stats.Faction.ENEMY:
            set_collision_layer_value(Global.ENEMY_HURTBOX, true)


func receive_hit(attack_info: AttackData) -> void:
    if not enabled:
        return
    get_hit.emit(attack_info)
