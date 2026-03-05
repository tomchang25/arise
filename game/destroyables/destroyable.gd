@tool
class_name Destroyable
extends Node2D

@export var stats: Stats
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule

@export_group("Destroyable")
@export var auto_free_on_death := true


func _ready() -> void:
    _auto_wire_nodes()
    _ensure_stats()
    _bind_modules()


func _auto_wire_nodes() -> void:
    if not hurtbox:
        hurtbox = find_child("Hurtbox", true, false) as Hurtbox
    if not damage_receiver:
        damage_receiver = find_child("DamageReceiverModule", true, false) as DamageReceiverModule


func _ensure_stats() -> void:
    if stats:
        stats.setup_stats()
        # Force destroyable rules even if user assigned a Stats resource
        _apply_destroyable_defaults()
        return

    stats = Stats.new()
    _apply_destroyable_defaults()
    stats.setup_stats()


func _apply_destroyable_defaults() -> void:
    stats.faction = Stats.Faction.NEUTRAL
    stats.base_max_health = 1.0
    stats.base_defense = 0.0
    stats.base_damage = 0.0


func _bind_modules() -> void:
    # Hurtbox uses owner_stats (commonly for collision layers/masks)
    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox
        if not damage_receiver.died.is_connected(_on_died):
            damage_receiver.died.connect(_on_died)


func _on_died(_info: AttackInfo) -> void:
    # Optional: play animation / particles here, then free
    if auto_free_on_death:
        queue_free()
