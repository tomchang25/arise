class_name LootDropModule
extends Node

signal loot_dropped(results: Array[LootDropResult])

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_state()

@export_group("Dependencies")
@export var owner_node: Node2D
@export var drop_table: LootDropTable
@export var spawn_context: SpawnContext

@export_group("Spawn")
@export var spawn_parent_mode: LootSpawnAction.ParentMode = LootSpawnAction.ParentMode.CTX_SPAWN_ROOT
@export var spawn_parent_path: NodePath
@export var spawn_parent_group: String = "world"
@export var scatter_radius: float = 20.0

@export_group("Debug")
@export var print_debug_log := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    pass


# -------------------------
# Common API
# -------------------------


func set_enabled(value: bool) -> void:
    enabled = value


func is_enabled() -> bool:
    return enabled


# -------------------------
# Loot Drop
# -------------------------


func drop_loot() -> Array[LootDropResult]:
    if not enabled:
        return []
    if owner_node == null:
        return []
    if drop_table == null:
        return []

    var results := _roll_drop_table(drop_table)
    _spawn_results(results)

    if print_debug_log:
        print("LootDropModule: dropped %s result(s)" % results.size())

    loot_dropped.emit(results)
    return results


# -------------------------
# Internal Helpers
# -------------------------


func _roll_drop_table(table: LootDropTable) -> Array[LootDropResult]:
    var results: Array[LootDropResult] = []
    var rng := _ensure_rng()

    for _i in range(max(0, table.rolls)):
        var entry := _pick_weighted_entry(table.entries, rng)
        if entry == null:
            continue

        if rng.randf() > clampf(entry.chance, 0.0, 1.0):
            continue

        var result := LootDropResult.new()
        result.reward_kind = entry.reward_kind
        result.pickup_scene = entry.pickup_scene
        result.amount = rng.randi_range(entry.min_amount, entry.max_amount)

        result.resource_type = entry.resource_type
        result.item_id = entry.item_id
        result.item_resource = entry.item_resource

        results.append(result)

    return results


func _pick_weighted_entry(entries: Array[LootDropEntry], rng: RandomNumberGenerator) -> LootDropEntry:
    var total_weight := 0

    for entry in entries:
        if entry == null:
            continue
        total_weight += max(0, entry.weight)

    if total_weight <= 0:
        return null

    var roll := rng.randi_range(1, total_weight)
    var acc := 0

    for entry in entries:
        if entry == null:
            continue

        acc += max(0, entry.weight)
        if roll <= acc:
            return entry

    return null


func _spawn_results(results: Array[LootDropResult]) -> void:
    if owner_node == null:
        return

    for result in results:
        if result == null:
            continue

        var action := LootSpawnAction.new()
        action.drop_result = result
        action.parent_mode = spawn_parent_mode
        action.parent_path = spawn_parent_path
        action.parent_group = spawn_parent_group
        action.spawn_position = _get_scatter_position()

        action.execute(owner_node, spawn_context)


func _get_scatter_position() -> Vector2:
    var rng := _ensure_rng()
    var angle := rng.randf() * TAU
    var dist := rng.randf_range(4.0, scatter_radius)
    return owner_node.global_position + Vector2.RIGHT.rotated(angle) * dist


func _ensure_rng() -> RandomNumberGenerator:
    if spawn_context != null:
        return spawn_context.ensure_rng()

    var rng := RandomNumberGenerator.new()
    rng.randomize()
    return rng


func _stop_runtime_state() -> void:
    pass
