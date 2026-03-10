class_name BasePickup
extends Area2D

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_state()

@export_group("Collection")
@export var collector_group: StringName = &"player"
@export var collect_delay: float = 0.0

var _can_collect := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    body_entered.connect(_on_body_entered)

    if collect_delay <= 0.0:
        _can_collect = true
    else:
        await get_tree().create_timer(collect_delay).timeout
        _can_collect = true


# -------------------------
# Common API
# -------------------------


func set_enabled(value: bool) -> void:
    enabled = value


func is_enabled() -> bool:
    return enabled


# -------------------------
# Pickup Setup
# -------------------------


func setup_from_drop_result(_result: LootDropResult) -> void:
    pass


func try_collect(collector: Node) -> void:
    if not enabled:
        return
    if not _can_collect:
        return
    if collector == null:
        return

    if _apply_to_collector(collector):
        queue_free()


# -------------------------
# Internal Helpers
# -------------------------


func _apply_to_collector(_collector: Node) -> bool:
    return false


func _stop_runtime_state() -> void:
    _can_collect = false


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_body_entered(body: Node) -> void:
    if not body.is_in_group(collector_group):
        return

    try_collect(body)
