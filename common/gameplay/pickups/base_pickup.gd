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

@export_group("Debug")
@export var print_debug_log := false

var _can_collect := false
var _is_collecting := false
var _is_collected := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    body_entered.connect(_on_body_entered)

    if not _validate_configuration():
        _debug_invalid("invalid pickup configuration")
        return

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


func try_collect(collector: Node) -> void:
    if not enabled:
        return

    if not _can_collect:
        return

    if _is_collecting or _is_collected:
        return

    if collector == null:
        _debug_invalid("collector is null")
        return

    if not _validate_configuration():
        _debug_invalid("pickup configuration invalid")
        return

    if not _validate_receiver(collector):
        _debug_invalid("collector is incompatible")
        return

    _is_collecting = true

    var success := _apply_to_collector(collector)
    if success:
        _is_collected = true
        queue_free()
    else:
        _is_collecting = false
        _debug_invalid("apply_to_collector failed")


# -------------------------
# Internal Helpers
# -------------------------


func _validate_configuration() -> bool:
    return true


func _validate_receiver(_collector: Node) -> bool:
    return true


func _apply_to_collector(_collector: Node) -> bool:
    return false


func _debug_invalid(message: String) -> void:
    if print_debug_log:
        push_warning("%s: %s" % [name, message])


func _stop_runtime_state() -> void:
    _can_collect = false
    _is_collecting = false


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_body_entered(body: Node) -> void:
    if _is_collected:
        return

    if not body.is_in_group(collector_group):
        return

    try_collect(body)
