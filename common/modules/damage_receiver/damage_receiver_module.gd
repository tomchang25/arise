class_name DamageReceiverModule
extends Node

signal damaged(amount: float, new_health: float, info: AttackInfo)
signal died(info: AttackInfo)

@export var enabled: bool = true
@export var stats: Stats
@export var hurtbox: Hurtbox

@export_group("Rules")
@export var defense_scaling: float = 1.0
@export var clamp_min_damage: float = 0.0


func _ready() -> void:
    _auto_wire()


func _auto_wire() -> void:
    if not stats and owner and owner.get("stats") is Stats:
        stats = owner.stats

    if not hurtbox and owner:
        hurtbox = owner.find_child("Hurtbox", true, false) as Hurtbox

    if hurtbox:
        if not hurtbox.get_hit.is_connected(_on_hurtbox_hit):
            hurtbox.get_hit.connect(_on_hurtbox_hit)


func _on_hurtbox_hit(info: AttackInfo) -> void:
    if not enabled or not stats or not info:
        print_debug("DamageReceiverModule: _on_hurtbox_hit: invalid arguments")
        return

    # 1) faction filter
    if info.target_factions.size() > 0 and not info.target_factions.has(stats.faction):
        print_debug("DamageReceiverModule: _on_hurtbox_hit: invalid target factions")
        return

    # 2) compute damage (snapshot damage from AttackInfo)
    var raw := info.damage
    var final_damage := raw - (stats.current_defense * defense_scaling)
    final_damage = max(final_damage, clamp_min_damage)

    if final_damage != 0.0:
        stats.take_damage(final_damage)
        print_debug("DamageReceiverModule: _on_hurtbox_hit: %s took %s damage, remaining: %s" % [owner.name, final_damage, stats.health])

    damaged.emit(final_damage, stats.health, info)

    if stats.health <= 0.0:
        died.emit(info)
