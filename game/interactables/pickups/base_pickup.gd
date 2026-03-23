class_name BasePickup
extends Area2D

signal collected(collector: Node, pickup_collector_module: PickupCollectorModule)
signal despawned

# Inspector proxy — delegates to set_enabled() so both runtime and editor use the same path.
@export var enabled: bool = true:
    set(value):
        set_enabled(value)

@export_group("Collection")
@export var collect_delay: float = 0.0

@export_group("Magnet")
@export var magnet_enabled := true
@export var magnet_speed: float = 160.0
@export var collect_distance: float = 10.0

@export_group("Lifetime")
@export var use_lifetime := false
@export var lifetime: float = 10.0
@export var despawn_on_timeout := true

@export_group("Dependencies")
@export var collect_audio_event: AudioEvent

var _enabled: bool = true

var _can_collect: bool
var _is_collecting: bool
var _is_collected: bool
var _lifetime_left: float
var _magnet_target: PickupCollectorModule

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not area_entered.is_connected(_on_area_entered):
        area_entered.connect(_on_area_entered)

    _init_runtime_state()
    _refresh_runtime_state()


func _physics_process(delta: float) -> void:
    if not _enabled:
        return
    if _is_collected:
        return

    if use_lifetime:
        _update_lifetime(delta)
        if _is_collected:
            return

    if magnet_enabled:
        _update_magnet(delta)

# -------------------------
# Runtime state
# -------------------------


func _init_runtime_state() -> void:
    _can_collect = collect_delay <= 0.0
    _is_collecting = false
    _is_collected = false
    _lifetime_left = lifetime if use_lifetime else 0.0
    _magnet_target = null


func _refresh_runtime_state() -> void:
    set_physics_process(_enabled and (magnet_enabled or use_lifetime))


func _stop_runtime_state() -> void:
    _is_collecting = false
    _magnet_target = null
    set_physics_process(false)

# -------------------------
# Common API
# -------------------------


func reset() -> void:
    _init_runtime_state()
    set_enabled(true)


func set_enabled(value: bool) -> void:
    if _enabled == value:
        return
    _enabled = value
    if not _enabled:
        _stop_runtime_state()
    _refresh_runtime_state()


func is_enabled() -> bool:
    return _enabled

# -------------------------
# Pickup Control
# -------------------------


func try_collect(candidate: Node) -> void:
    if not _enabled:
        return
    if not _can_collect:
        return
    if _is_collecting or _is_collected:
        return
    if candidate == null:
        return
    if not _validate_configuration():
        return

    var pickup_collector_module := _resolve_pickup_collector_module(candidate)
    if pickup_collector_module == null:
        return
    if not pickup_collector_module.is_enabled():
        return

    var collector := pickup_collector_module.owner_body
    if collector == null:
        return
    if not _can_collect_from(collector, pickup_collector_module):
        return

    _is_collecting = true

    if _apply_to_collector(collector, pickup_collector_module):
        _finish_collect(collector, pickup_collector_module)
    else:
        _is_collecting = false


func begin_magnet_pull(pickup_collector_module: PickupCollectorModule) -> void:
    if not _enabled:
        return
    if not magnet_enabled:
        return
    if _is_collected:
        return
    if pickup_collector_module == null:
        return
    if not pickup_collector_module.can_collect_pickup(self):
        return

    _magnet_target = pickup_collector_module


func clear_magnet_target(source: PickupCollectorModule = null) -> void:
    if source == null:
        _magnet_target = null
        return

    if _magnet_target == source:
        _magnet_target = null

# -------------------------
# Internal Helpers
# -------------------------


func _resolve_pickup_collector_module(candidate: Node) -> PickupCollectorModule:
    if candidate is PickupCollectorModule:
        return candidate

    if candidate.has_method("get_pickup_collector_module"):
        var result: Variant = candidate.get_pickup_collector_module()
        if result is PickupCollectorModule:
            return result

    return null


func _validate_configuration() -> bool:
    return true


func _can_collect_from(_collector: Node, _pickup_collector_module: PickupCollectorModule) -> bool:
    return true


func _apply_to_collector(_collector: Node, _pickup_collector_module: PickupCollectorModule) -> bool:
    return false


func _finish_collect(collector: Node, pickup_collector_module: PickupCollectorModule) -> void:
    _is_collected = true
    _is_collecting = false
    _magnet_target = null

    if collect_audio_event != null and AudioManager != null:
        AudioManager.play_event(collect_audio_event, global_position)

    if pickup_collector_module != null:
        pickup_collector_module.pickup_collected.emit(self)

    collected.emit(collector, pickup_collector_module)
    queue_free()


func _despawn() -> void:
    if _is_collected:
        return

    _is_collected = true
    _is_collecting = false
    _magnet_target = null
    despawned.emit()
    queue_free()


func _update_lifetime(delta: float) -> void:
    _lifetime_left -= delta
    if _lifetime_left <= 0.0 and despawn_on_timeout:
        _despawn()


func _update_magnet(delta: float) -> void:
    if _magnet_target == null or not is_instance_valid(_magnet_target):
        _magnet_target = null
        return

    if not _magnet_target.has_pickup_in_range(self):
        _magnet_target = null
        return

    var target_position := _magnet_target.global_position
    if global_position.distance_to(target_position) <= collect_distance:
        try_collect(_magnet_target)
        return

    global_position = global_position.move_toward(target_position, magnet_speed * delta)

# -------------------------
# Signals / Callbacks
# -------------------------


func _on_body_entered(body: Node) -> void:
    if _is_collected:
        return

    try_collect(body)


func _on_area_entered(area: Area2D) -> void:
    if _is_collected:
        return

    try_collect(area)
