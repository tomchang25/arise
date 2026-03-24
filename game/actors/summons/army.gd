@tool
class_name Army
extends Actor

# -------------------------
# Exports — Army-specific
# -------------------------

@export var data: ArmyData

# -------------------------
# Group-driven aggro state
# Set by ArmyGroup — units do not run their own detection.
# -------------------------

var group_aggroed: bool = false
var group_target: Node2D = null

# -------------------------
# Public API — Base
# --------------------------


func get_data() -> ArmyData:
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


func _apply_data() -> void:
    if data == null:
        push_error("Army: no ArmyData assigned.")
        return

    stats = data.stats.duplicate() as Stats
    stats.setup_stats()

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


func set_enabled(value: bool) -> void:
    super.set_enabled(value)

# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_died(_info) -> void:
    # Army units do not emit died or drop loot.
    queue_free()

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


func is_target_in_reach() -> bool:
    if group_target == null:
        return false
    var reach := get_attack_range()
    return reach > 0.0 and global_position.distance_to(group_target.global_position) <= reach



# -------------------------
# Public API — state machine
# -------------------------


func get_current_state() -> State:
    if state_machine == null:
        return null
    return state_machine.current_state
