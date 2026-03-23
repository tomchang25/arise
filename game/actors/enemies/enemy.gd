@tool
class_name Enemy
extends Actor

# -------------------------
# Actor type enum
# -------------------------

enum ActorType {
    UNKNOWN = 0,
    BLUE_SLIME = 1,
    RED_NINJA = 2,
    BLUE_SKULL = 3,
}

# -------------------------
# Exports — Enemy-specific
# -------------------------

@export var data: EnemyData

@export_group("Actor")
@export var actor_type: ActorType = ActorType.UNKNOWN

@export_group("Modules — Gameplay")
@export var loot_drop: LootDropModule

# -------------------------
# Group-driven aggro state
# Set by EnemyGroup — enemies do not run their own detection.
# -------------------------

var group_aggroed: bool = false
var group_target: Node2D = null

# -------------------------
# Abstract API — implementations
# -------------------------


func get_data() -> ActorData:
    return data

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()


func _auto_wire_nodes() -> void:
    super._auto_wire_nodes()
    if not loot_drop:
        loot_drop = find_child("LootDropModule", true, false) as LootDropModule


func _apply_data() -> void:
    if data == null:
        push_error("Enemy: no EnemyData assigned.")
        return

    # Duplicate so each instance owns its own runtime stats.
    stats = data.stats.duplicate() as Stats
    stats.setup_stats()

    # Initialize combat module — stats and weapons must always be set together.
    if combat_module:
        combat_module.setup(stats, data.weapons)


func reset() -> void:
    group_aggroed = false
    group_target = null

    if data:
        stats = data.stats.duplicate() as Stats
        stats.setup_stats()
        if hurtbox:
            hurtbox.owner_stats = stats
        if damage_receiver:
            damage_receiver.stats = stats
        if hit_feedback:
            hit_feedback.stats = stats
        if health_bar:
            health_bar.bind(stats)
        if combat_module:
            combat_module.setup(stats, data.weapons)
    super.reset()
    if loot_drop:
        loot_drop.reset()


func set_enabled(value: bool) -> void:
    super.set_enabled(value)
    if loot_drop:
        loot_drop.set_enabled(value)


func _bind_modules() -> void:
    super._bind_modules()

    # --- Loot ---
    if loot_drop:
        loot_drop.owner_node = self
        if data and data.drop_profile:
            loot_drop.drop_profile = data.drop_profile

    if navigation_module:
        navigation_module.enable_navigation_agent = false

# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_died(info) -> void:
    died.emit(info)
    if loot_drop:
        loot_drop.drop_loot()
    queue_free()


func _on_animation_finished(anim_name: StringName) -> void:
    if String(ANIM_ATTACK) in String(anim_name):
        attack_finished.emit()
# -------------------------
# Public API — perception
# -------------------------


func is_aggro_active() -> bool:
    return group_aggroed


func is_deaggro_active() -> bool:
    return not group_aggroed


func get_nearest_aggro_target() -> Node2D:
    return group_target


func has_deaggro() -> bool:
    return data.has_deaggro if data else false


func get_leash_distance() -> float:
    return data.leash_distance if data else 0.0
