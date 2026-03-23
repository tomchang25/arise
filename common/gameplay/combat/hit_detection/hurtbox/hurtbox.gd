@tool
class_name Hurtbox
extends Area2D

signal get_hit(context: EffectContext)

@export var enabled: bool = true:
    set = set_enabled

var _enabled: bool = true

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

    set_deferred("monitorable", _enabled)
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


func reset() -> void:
    _enabled = true
    set_deferred("monitorable", true)


func set_enabled(value: bool) -> void:
    _enabled = value
    set_deferred("monitorable", _enabled)
    if not _enabled:
        _stop_runtime_state()


func is_enabled() -> bool:
    return _enabled


func _stop_runtime_state() -> void:
    pass


func receive_hit(context: EffectContext) -> void:
    if not _enabled:
        return
    get_hit.emit(context)
