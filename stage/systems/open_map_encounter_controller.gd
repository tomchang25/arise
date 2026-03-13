class_name OpenMapEncounterController
extends Node2D

signal encounter_spawned(spawned_nodes: Array[Node])
signal spawn_blocked
signal pacing_tick

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_state()

@export_group("Dependencies")
@export var player: Node2D
@export var spawn_parent: Node
@export var despawn_manager: StageSpawnDespawnManager

@export_group("Spawn")
@export var spawn_action: SpawnAction

@export_group("Pacing")
@export var auto_start := true
@export var target_active_count := 100
@export var max_active_count := 200
@export var max_spawn_per_tick := 4
@export var spawn_interval := 1.5
@export var initial_spawn_cooldown := 0.25
@export var respawn_when_below_target := true

@export_group("Spawn Placement")
@export var min_spawn_distance := 120.0
@export var max_spawn_distance := 480.0
@export var placement_attempts_per_enemy := 12
@export var use_rect_bounds := true
@export var world_rect := Rect2(Vector2(-800.0, -800.0), Vector2(1600.0, 1600.0))
@export var use_collision_check := false
@export var collision_mask := 1
@export var spawn_footprint_radius := 12.0

@export_group("Player Exclusion")
@export var exclude_near_player := true
@export var player_safe_radius := 160.0

@export_group("Optional Scaling")
@export var scale_target_count_over_time := false
@export var target_count_ramp_interval := 30.0
@export var target_count_ramp_step := 1
@export var target_count_ramp_max := 40

@export_group("Debug")
@export var print_debug_log := false
@export var draw_debug := false

var _rng := RandomNumberGenerator.new()
var _spawn_registry := SpawnRegistry.new()
var _spawn_timer := 0.0
var _ramp_timer := 0.0
var _started := false
var _pending_spawn_count := 0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()
    _spawn_timer = initial_spawn_cooldown
    _ramp_timer = target_count_ramp_interval

    if auto_start:
        start()

    queue_redraw()


func _process(delta: float) -> void:
    if not enabled:
        return

    if not _started:
        return

    if player == null:
        return

    _cleanup_tracked_spawned()

    if scale_target_count_over_time:
        _tick_target_ramp(delta)

    _spawn_timer -= delta
    if _spawn_timer > 0.0:
        if draw_debug:
            queue_redraw()
        return

    _spawn_timer = maxf(spawn_interval, 0.01)
    _run_pacing_tick()

    if draw_debug:
        queue_redraw()


func _draw() -> void:
    if not draw_debug:
        return

    if player == null:
        return

    var local_center := player.global_position

    draw_arc(local_center, min_spawn_distance, 0.0, TAU, 64, Color.YELLOW, 2.0)
    draw_arc(local_center, max_spawn_distance, 0.0, TAU, 64, Color.ORANGE, 2.0)

    if exclude_near_player and player_safe_radius > 0.0:
        draw_arc(local_center, player_safe_radius, 0.0, TAU, 64, Color.RED, 2.0)

    if use_rect_bounds:
        draw_rect(Rect2(to_local(world_rect.position), world_rect.size), Color.CYAN, false, 2.0)


# -------------------------
# Common API
# -------------------------


func set_enabled(value: bool) -> void:
    enabled = value


func is_enabled() -> bool:
    return enabled


func start() -> void:
    if not enabled:
        return

    _started = true
    _spawn_timer = initial_spawn_cooldown
    _ramp_timer = target_count_ramp_interval


func stop() -> void:
    _started = false


func is_running() -> bool:
    return _started


# -------------------------
# Encounter Control
# -------------------------


func force_spawn_once(count: int = 1) -> void:
    if not enabled:
        return

    if not _can_spawn():
        spawn_blocked.emit()
        return

    _schedule_spawn_batch(maxi(count, 0))


func get_active_count() -> int:
    _cleanup_tracked_spawned()
    return _spawn_registry.get_valid_count()


func get_pending_count() -> int:
    return _pending_spawn_count


func get_total_reserved_count() -> int:
    return get_active_count() + _pending_spawn_count


func clear_tracked_invalid() -> void:
    _cleanup_tracked_spawned()


# -------------------------
# Internal Helpers
# -------------------------


func _run_pacing_tick() -> void:
    pacing_tick.emit()

    if not respawn_when_below_target:
        return

    if not _can_spawn():
        spawn_blocked.emit()
        return

    var reserved_count := get_total_reserved_count()
    if reserved_count >= max_active_count:
        if print_debug_log:
            print("[OpenMapEncounterController] blocked: reserved_count >= max_active_count")
        spawn_blocked.emit()
        return

    if reserved_count >= target_active_count:
        return

    var needed_count := target_active_count - reserved_count
    var allowed_count := max_active_count - reserved_count
    var spawn_count: int = min(needed_count, allowed_count, max_spawn_per_tick)

    if spawn_count <= 0:
        return

    var scheduled_count := _schedule_spawn_batch(spawn_count)
    if scheduled_count <= 0:
        spawn_blocked.emit()


func _can_spawn() -> bool:
    if player == null:
        Debug.invalid("OpenMapEncounterController: player is null")
        return false

    if spawn_parent == null:
        Debug.invalid("OpenMapEncounterController: spawn_parent is null")
        return false

    if spawn_action == null:
        Debug.invalid("OpenMapEncounterController: spawn_action is null")
        return false

    return true


func _schedule_spawn_batch(count: int) -> int:
    var scheduled_count := 0

    for _i in range(count):
        var spawn_position_variant = _find_spawn_position()
        if spawn_position_variant == null:
            if print_debug_log:
                print("[OpenMapEncounterController] failed to find spawn position")
            continue

        var spawn_position := spawn_position_variant as Vector2
        _pending_spawn_count += 1
        scheduled_count += 1
        _spawn_with_warning(spawn_position)

    return scheduled_count


func _spawn_with_warning(spawned_global_position: Vector2) -> void:
    var request := SpawnRequest.new()
    request.action = spawn_action
    request.global_position = spawned_global_position
    request.spawn_parent = spawn_parent
    request.use_warning_spawn = true
    request.source_node = self
    request.rng_seed = _rng.randi()
    request.metadata = {
        "player": player,
        "spawn_position": spawned_global_position,
        "controller": self,
    }

    var result := await request.execute()

    _pending_spawn_count = maxi(_pending_spawn_count - 1, 0)

    if not is_instance_valid(self):
        return

    if not result.success:
        if print_debug_log:
            print("[OpenMapEncounterController] warning spawn failed: %s" % result.blocked_reason)
        return

    if not result.has_node():
        if print_debug_log:
            print("[OpenMapEncounterController] spawn result success but node is invalid")
        return

    _register_spawn_result(result)
    encounter_spawned.emit([result.spawned_node])


func _find_spawn_position() -> Variant:
    if player == null:
        return null

    var validator := _build_spawn_position_validator()

    return SpawnPositionFinder.find_position_in_annulus(
        player.global_position, min_spawn_distance, max_spawn_distance, validator, _rng, placement_attempts_per_enemy
    )


func _build_spawn_position_validator() -> SpawnPositionValidator:
    var validator := SpawnPositionValidator.new()

    if is_inside_tree():
        validator.world_2d = get_world_2d()

    validator.use_play_area_rect = use_rect_bounds
    validator.play_area_rect = world_rect

    validator.use_excluded_radius = exclude_near_player and player != null and player_safe_radius > 0.0
    if player != null:
        validator.excluded_center = player.global_position
    validator.excluded_radius = player_safe_radius

    validator.collision_mask = collision_mask
    validator.collide_with_bodies = true
    validator.collide_with_areas = false

    if use_collision_check and spawn_footprint_radius > 0.0:
        validator.footprint_radius = spawn_footprint_radius

    return validator


func _register_spawn_result(result: SpawnResult) -> void:
    if result == null:
        return

    if not result.has_node():
        return

    var node := result.spawned_node
    _spawn_registry.register_node(node)

    if despawn_manager != null:
        despawn_manager.register_spawned(node)


func _cleanup_tracked_spawned() -> void:
    _spawn_registry.cleanup_invalid()


func _tick_target_ramp(delta: float) -> void:
    if target_count_ramp_interval <= 0.0:
        return

    _ramp_timer -= delta
    if _ramp_timer > 0.0:
        return

    _ramp_timer = target_count_ramp_interval
    target_active_count = min(target_active_count + target_count_ramp_step, target_count_ramp_max)


func _stop_runtime_state() -> void:
    _started = false
    _spawn_timer = initial_spawn_cooldown
    _ramp_timer = target_count_ramp_interval
    _pending_spawn_count = 0
    _cleanup_tracked_spawned()
