@tool
class_name Army
extends Actor

# -------------------------
# Exports — Army-specific
# -------------------------

@export var data: ArmyData

# -------------------------
# Runtime state — Army-specific
# -------------------------

var player: Node2D

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    player = get_tree().get_first_node_in_group("player")


func _apply_data() -> void:
    if data == null:
        push_error("Army: no ArmyData assigned.")
        return

    stats = data.stats.duplicate() as Stats
    stats.setup_stats()

    if aggro_detection and data.aggro_range > 0.0:
        aggro_detection.set_collision_radius(data.aggro_range)

    if reach_detection and data.attack_range > 0.0:
        reach_detection.set_collision_radius(data.attack_range)

    if combat_module:
        combat_module.setup(stats, data.weapons)


## Army sets reach_detection radius directly from data.attack_range in _apply_data(),
## so skip the combat_module lookup that the base class would otherwise perform.
func _bind_reach_detection() -> void:
    pass

# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_died(_info) -> void:
    # Army units do not emit died or drop loot.
    queue_free()

# -------------------------
# Public API — perception proxies (Army-specific)
# -------------------------


## Compatibility alias — prefer is_aggro_active() from Actor base.
func is_target_tracked() -> bool:
    return is_aggro_active()


## Compatibility alias — prefer get_nearest_aggro_target() from Actor base.
func get_nearest_tracked_target() -> Node2D:
    return get_nearest_aggro_target()


## Compatibility alias — prefer is_target_in_reach() from Actor base.
func is_target_attackable() -> bool:
    return is_target_in_reach()


## Compatibility alias — prefer get_nearest_reachable_target() from Actor base.
func get_nearest_attackable_target() -> Node2D:
    return get_nearest_reachable_target()

# -------------------------
# Public API — state machine
# -------------------------


func get_current_state() -> State:
    if state_machine == null:
        return null
    return state_machine.current_state

# -------------------------
# Public API — misc
# -------------------------


## Distance from this unit to its formation slot (anchor_position).
## anchor_position is updated each frame by ArmyHandler.
func get_distance_to_player() -> float:
    return get_distance_to_anchor()
