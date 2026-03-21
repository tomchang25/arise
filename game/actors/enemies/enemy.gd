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
# Lifecycle
# -------------------------


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    if anchor_position == Vector2.ZERO:
        push_warning("Enemy: anchor_position not set. Assign it at spawn time.")
    else:
        global_position = anchor_position


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

    if aggro_detection and data.aggro_range > 0.0:
        aggro_detection.set_collision_radius(data.aggro_range)

    if deaggro_detection and data.deaggro_range > 0.0:
        deaggro_detection.set_collision_radius(data.deaggro_range)

    # Initialize combat module — stats and weapons must always be set together.
    if combat_module:
        combat_module.setup(stats, data.weapons)


func _bind_modules() -> void:
    super._bind_modules()

    # --- Loot ---
    if loot_drop:
        loot_drop.owner_node = self
        if data and data.drop_profile:
            loot_drop.drop_profile = data.drop_profile

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
