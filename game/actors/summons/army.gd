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


func reset() -> void:
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
# Public API — state machine
# -------------------------


func get_current_state() -> State:
    if state_machine == null:
        return null
    return state_machine.current_state
