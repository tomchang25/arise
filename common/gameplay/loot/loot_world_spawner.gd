class_name LootWorldSpawner
extends Node

@export_group("Spawn")
@export var world_root: Node
@export var scatter_radius: float = 20.0
@export var randomize_z_index := false

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


func spawn_entry(source: Node2D, entry: LootDropEntry, amount: int) -> Node:
    if source == null:
        _debug_invalid("source is null")
        return null

    if entry == null:
        _debug_invalid("entry is null")
        return null

    if not entry.is_valid():
        _debug_invalid("entry is invalid")
        return null

    if entry.pickup_scene == null:
        _debug_invalid("pickup_scene is null")
        return null

    var parent := world_root if world_root != null else source.get_parent()
    if parent == null:
        _debug_invalid("spawn parent is null")
        return null

    var instance := entry.pickup_scene.instantiate()
    if instance == null:
        _debug_invalid("failed to instantiate pickup scene")
        return null

    parent.add_child(instance)

    if instance is Node2D:
        var node_2d := instance as Node2D
        node_2d.global_position = _get_scatter_position(source.global_position)

        if randomize_z_index and node_2d is CanvasItem:
            (node_2d as CanvasItem).z_index = _rng.randi_range(0, 3)

    if entry is ResourceDropEntry:
        var resource_entry := entry as ResourceDropEntry
        if instance.has_method("setup_resource"):
            instance.setup_resource(resource_entry.resource_data, amount)
        else:
            _debug_invalid("pickup scene missing setup_resource()")
            instance.queue_free()
            return null

    elif entry is ItemDropEntry:
        var item_entry := entry as ItemDropEntry
        if instance.has_method("setup_item"):
            instance.setup_item(item_entry.item_data, amount)
        else:
            _debug_invalid("pickup scene missing setup_item()")
            instance.queue_free()
            return null

    else:
        _debug_invalid("unsupported entry type")
        instance.queue_free()
        return null

    return instance


# -------------------------
# Internal Helpers
# -------------------------


func _get_scatter_position(origin: Vector2) -> Vector2:
    var angle := _rng.randf_range(0.0, TAU)
    var distance := _rng.randf_range(0.0, scatter_radius)
    return origin + Vector2.RIGHT.rotated(angle) * distance


func _debug_invalid(message: String) -> void:
    if print_debug_log:
        push_warning("LootWorldSpawner: %s" % message)
