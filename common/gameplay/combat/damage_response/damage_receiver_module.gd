class_name DamageReceiverModule
extends Node

signal damaged(amount: float, new_health: float, context: EffectContext)
signal blocked(context: EffectContext)
signal died(context: EffectContext)

@export var enabled: bool = true:
    set = set_enabled

@export var stats: Stats
@export var hurtbox: Hurtbox

@export_group("Rules")
@export var defense_scaling: float = 1.0
@export var clamp_min_damage: float = 0.0

var _enabled: bool = true

var _invuln_until_msec: int = 0


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


func _on_hurtbox_hit(ctx: EffectContext) -> void:
    if not _enabled:
        return

    if not stats or not ctx:
        push_warning("DamageReceiverModule: _on_hurtbox_hit: invalid arguments")
        return

    if stats.health <= 0.0:
        return

    if is_invulnerable():
        blocked.emit(ctx)
        return

    # Faction filter — resolved at spawn time and stored on the context.
    if ctx.target_factions.size() > 0 and not ctx.target_factions.has(stats.faction):
        push_warning("DamageReceiverModule: _on_hurtbox_hit: faction mismatch, ignoring hit")
        return

    # Damage calculation — reads live source_stats so buffs are always current.
    # TODO: replace with DamageCalculator.evaluate(ctx, stats) when that class exists.
    var raw := _calculate_damage(ctx)
    var final_damage := raw - (stats.current_defense * defense_scaling)
    final_damage = max(final_damage, clamp_min_damage)

    if final_damage > 0.0:
        stats.take_damage(final_damage)
        set_invulnerable_for(stats.invuln_time)
        damaged.emit(final_damage, stats.health, ctx)

        if stats.health <= 0.0:
            died.emit(ctx)
    else:
        blocked.emit(ctx)


## Temporary inline damage calculation.
## Reads live source_stats at hit time so any buffs applied after spawn are reflected.
## Replace this body with a DamageCalculator call once that class is introduced.
func _calculate_damage(ctx: EffectContext) -> float:
    if ctx.source_stats == null or ctx.definition == null:
        push_warning("DamageReceiverModule: _calculate_damage: missing source_stats or definition")
        return 0.0

    var base := ctx.source_stats.current_damage * ctx.definition.damage_multiplier
    var variance := ctx.definition.damage_variance
    var offset := 0.0
    if variance > 0.0:
        offset = randf_range(-base * variance, base * variance)

    var dmg := base + offset
    var is_crit: bool = randf() < clamp(ctx.source_stats.current_crit_chance + ctx.definition.crit_bonus, 0.0, 1.0)
    if is_crit:
        dmg *= ctx.source_stats.current_crit_multiplier

    return dmg


func reset() -> void:
    _enabled = true
    _invuln_until_msec = 0


func set_enabled(value: bool) -> void:
    _enabled = value
    if not _enabled:
        _stop_runtime_state()


func is_enabled() -> bool:
    return _enabled


func _stop_runtime_state() -> void:
    pass


func is_invulnerable() -> bool:
    return Time.get_ticks_msec() < _invuln_until_msec


func set_invulnerable_for(seconds: float) -> void:
    if seconds <= 0.0:
        return

    _invuln_until_msec = max(_invuln_until_msec, Time.get_ticks_msec() + int(seconds * 1000.0))
