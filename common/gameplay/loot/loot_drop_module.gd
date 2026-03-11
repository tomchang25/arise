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
@export var world_spawner: LootWorldSpawner
@export var drop_profile: LootDropProfile

@export_group("Debug")
@export var print_debug_log := false

var _rng := RandomNumberGenerator.new()

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()


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

    if owner_node == null:
        _debug_invalid("owner_node is null")
        return

    if world_spawner == null:
        _debug_invalid("world_spawner is null")
        return

    if drop_profile == null:
        _debug_invalid("drop_profile is null")
        return

    if drop_profile.tables.is_empty():
        _debug_invalid("drop_profile has no tables")
        return

    if not drop_profile.has_valid_tables():
        _debug_invalid("drop_profile has no valid tables")
        return

    var did_spawn := false

    for table in drop_profile.tables:
        if table == null:
            _debug_invalid("table is null")
            continue

        if table.rolls <= 0:
            _debug_invalid("table rolls <= 0")
            continue

        if table.entries.is_empty():
            _debug_invalid("table has no entries")
            continue

        if not table.has_valid_entries():
            _debug_invalid("table has no valid entries")
            continue

        var valid_entries := _get_valid_entries(table.entries)
        if valid_entries.is_empty():
            _debug_invalid("no valid entries after filtering")
            continue

        for _i in range(table.rolls):
            var entry := _pick_weighted_entry(valid_entries)
            if entry == null:
                continue

            if _rng.randf() > clampf(entry.chance, 0.0, 1.0):
                continue

            var amount := _rng.randi_range(entry.min_amount, entry.max_amount)
            var spawned := world_spawner.spawn_entry(owner_node, entry, amount)
            if spawned != null:
                did_spawn = true

    if did_spawn:
        loot_dropped.emit()


# -------------------------
# Internal Helpers
# -------------------------


func _get_valid_entries(entries: Array[LootDropEntry]) -> Array[LootDropEntry]:
    var valid_entries: Array[LootDropEntry] = []

    for entry in entries:
        if entry == null:
            _debug_invalid("entry is null")
            continue

        if not entry.is_valid():
            _debug_invalid("invalid entry detected")
            continue

        valid_entries.append(entry)

    return valid_entries


func _pick_weighted_entry(entries: Array[LootDropEntry]) -> LootDropEntry:
    var total_weight := 0

    for entry in entries:
        total_weight += max(entry.weight, 0)

    if total_weight <= 0:
        _debug_invalid("total_weight <= 0")
        return null

    var roll := _rng.randi_range(1, total_weight)
    var cumulative := 0

    for entry in entries:
        cumulative += max(entry.weight, 0)
        if roll <= cumulative:
            return entry

    return null


func _debug_invalid(message: String) -> void:
    if print_debug_log:
        push_warning("LootDropModule: %s" % message)


func _stop_runtime_state() -> void:
    pass
