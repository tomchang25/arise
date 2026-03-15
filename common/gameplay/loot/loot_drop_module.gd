class_name LootDropModule
extends Node

signal loot_dropped

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_state()

@export_group("Dependencies")
@export var owner_node: Node2D
@export var drop_profile: LootDropProfile

@export_group("Spawn Target")
@export var spawn_parent_group: String = "loot_root"

var _rng := RandomNumberGenerator.new()

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()

    if owner_node == null:
        owner_node = owner as Node2D
        if owner_node == null:
            Debug.warn("LootDropModule: owner_node is null and owner is not Node2D — wire it manually")


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


func drop_loot() -> void:
    if not enabled:
        return

    if not is_inside_tree():
        Debug.warn("LootDropModule: drop_loot called while not in tree — skipping")
        return

    if owner_node == null:
        Debug.invalid("owner_node is null")
        return

    if drop_profile == null:
        Debug.invalid("drop_profile is null")
        return

    if drop_profile.tables.is_empty():
        Debug.invalid("drop_profile has no tables")
        return

    if not drop_profile.has_valid_tables():
        Debug.invalid("drop_profile has no valid tables")
        return

    var spawn_ctx := _build_spawn_context()
    if spawn_ctx == null:
        Debug.invalid("failed to build spawn context")
        return

    var did_spawn := false

    for table in drop_profile.tables:
        if table == null:
            Debug.invalid("table is null")
            continue

        if table.rolls <= 0:
            Debug.invalid("table rolls <= 0")
            continue

        if table.entries.is_empty():
            Debug.invalid("table has no entries")
            continue

        if not table.has_valid_entries():
            Debug.invalid("table has no valid entries")
            continue

        var valid_entries := _get_valid_entries(table.entries)
        if valid_entries.is_empty():
            Debug.invalid("no valid entries after filtering")
            continue

        for _i in range(table.rolls):
            var entry := _pick_weighted_entry(valid_entries)
            if entry == null:
                continue

            if _rng.randf() > clampf(entry.chance, 0.0, 1.0):
                continue

            var amount := _roll_entry_amount(entry)
            if amount <= 0:
                continue

            var spawned := _spawn_entry(entry, amount, spawn_ctx)
            if spawned != null:
                did_spawn = true

    if did_spawn:
        loot_dropped.emit()


# -------------------------
# Internal Helpers
# -------------------------


func _build_spawn_context() -> SpawnContext:
    var parent := SpawnContext.resolve_spawn_parent(spawn_parent_group, self)
    if parent == null:
        return null

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(parent, 0, owner_node, {"spawn_reason": "loot_drop"})
    return spawn_ctx


func _get_valid_entries(entries: Array[LootDropEntry]) -> Array[LootDropEntry]:
    var valid_entries: Array[LootDropEntry] = []

    for entry in entries:
        if entry == null:
            Debug.invalid("entry is null")
            continue

        if not entry.is_valid():
            Debug.invalid("invalid entry detected")
            continue

        valid_entries.append(entry)

    return valid_entries


func _pick_weighted_entry(entries: Array[LootDropEntry]) -> LootDropEntry:
    var total_weight := 0

    for entry in entries:
        total_weight += max(entry.weight, 0)

    if total_weight <= 0:
        Debug.invalid("total_weight <= 0")
        return null

    var roll := _rng.randi_range(1, total_weight)
    var cumulative := 0

    for entry in entries:
        cumulative += max(entry.weight, 0)
        if roll <= cumulative:
            return entry

    return null


func _roll_entry_amount(entry: LootDropEntry) -> int:
    var min_amount: int = min(entry.min_amount, entry.max_amount)
    var max_amount: int = max(entry.min_amount, entry.max_amount)

    if max_amount <= 0:
        Debug.invalid("_roll_entry_amount: max_amount <= 0 — entry should have been filtered by is_valid()")
        return 0

    return _rng.randi_range(max(1, min_amount), max_amount)


func _spawn_entry(entry: LootDropEntry, amount: int, spawn_ctx: SpawnContext) -> Node:
    if entry.pickup_scene == null:
        Debug.invalid("entry.pickup_scene is null")
        return null

    var spawn_action := SpawnPackedSceneAction.new()
    spawn_action.scene = entry.pickup_scene
    spawn_action.use_anchor_position = true
    spawn_action.use_anchor_rotation = false
    spawn_action.random_rotation = false
    spawn_action.local_offset = Vector2.ZERO
    spawn_action.scatter_radius = maxf(entry.scatter_radius, 0.0)

    var instance := SpawnExecutor.execute_at_node(spawn_action, owner_node, spawn_ctx)
    if instance == null:
        Debug.invalid("failed to spawn loot pickup instance")
        return null

    if not _setup_spawned_loot_instance(instance, entry, amount):
        instance.queue_free()
        return null

    return instance


func _setup_spawned_loot_instance(instance: Node, entry: LootDropEntry, amount: int) -> bool:
    if entry is ResourceDropEntry:
        var resource_entry := entry as ResourceDropEntry
        if not instance.has_method("setup_resource"):
            Debug.invalid("pickup scene missing setup_resource()")
            return false

        instance.setup_resource(resource_entry.resource_data, amount)
        return true

    if entry is ItemDropEntry:
        var item_entry := entry as ItemDropEntry
        if not instance.has_method("setup_item"):
            Debug.invalid("pickup scene missing setup_item()")
            return false

        instance.setup_item(item_entry.item_data, amount)
        return true

    Debug.invalid("unsupported entry type")
    return false


func _stop_runtime_state() -> void:
    pass  # Loot drop is one-shot — no timers or ongoing processes to cancel
