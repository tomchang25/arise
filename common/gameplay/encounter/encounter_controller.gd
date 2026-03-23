class_name EncounterController
extends Node

# -------------------------
# Signals
# -------------------------

signal encounter_started
signal round_started
signal round_cleared
signal group_spawned(group: EnemyGroup)
signal group_depleted(group: EnemyGroup)
signal group_removed(group: EnemyGroup)

# -------------------------
# Dependencies
# -------------------------

@export_group("Dependencies")
@export var enemies_root: Node2D
@export var enemies_container: Node2D

@export_group("Warning Spawn")
@export var warning_point_scene: PackedScene = preload("res://common/gameplay/spawning/points/warning_spawn_point.tscn")

@export_group("Debug")
@export var print_debug_log := false

# -------------------------
# Internal State
# -------------------------

enum EncounterState { IDLE, ROUND_ACTIVE, ROUND_CLEARED }

var _state: EncounterState = EncounterState.IDLE
var _config: EncounterConfig = null
var _active_groups: Array[EnemyGroup] = []
var _groups_to_kill: int = 0
var _groups_killed: int = 0
var _spawn_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

var _pending_spawns: int = 0
var _force_kill_pending: bool = false

## Assign a callable from outside to resolve spawn positions.
## Signature: func() -> Variant
##   Returns Vector2, or a Dictionary with keys "position" (Vector2) and
##   optionally "validator" (SpawnPositionValidator), or null on failure.
## Example: encounter_controller.spawn_position_resolver = _find_spawn_position
var spawn_position_resolver: Callable = Callable()

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()


func _process(delta: float) -> void:
    if _state != EncounterState.ROUND_ACTIVE:
        return

    _spawn_timer -= delta
    if _spawn_timer > 0.0:
        return

    _spawn_timer = maxf(_config.spawn_interval, 0.01)
    _run_pacing_tick()

# -------------------------
# Public API
# -------------------------


func start(config: EncounterConfig) -> void:
    if not _validate_config(config):
        return

    end()

    _config = config
    _rng.randomize()

    encounter_started.emit()
    _begin_round()


## Called by the caller when ready to start the next round.
## Only valid when in ROUND_CLEARED state.
func start_next_round() -> void:
    if _state != EncounterState.ROUND_CLEARED:
        Debug.warn("EncounterController: start_next_round() called but not in ROUND_CLEARED state")
        return

    _begin_round()


## Force-stops the encounter and cleans up all active groups.
func end(need_cleanup: bool = false) -> void:
    SpawnThrottle.clear(&"encounter_enemy")
    _state = EncounterState.IDLE
    _config = null
    _spawn_timer = 0.0
    _groups_to_kill = 0
    _groups_killed = 0
    _pending_spawns = 0
    _force_kill_pending = false

    if need_cleanup:
        _clear_all_groups()


func is_active() -> bool:
    return _state == EncounterState.ROUND_ACTIVE


## Force-kills all active groups and any group still under a warning spawn point.
## Safe to call at any time — does not affect round state or kill counts.
func force_kill_all() -> void:
    _cleanup_invalid()
    for group in _active_groups:
        group.force_kill()
    _active_groups.clear()

    # If spawns are mid-warning, mark them so they self-destruct on arrival.
    if _pending_spawns > 0:
        _force_kill_pending = true

    if print_debug_log:
        Debug.log("EncounterController: force_kill_all — active cleared, pending=%s" % _pending_spawns)


## Forces an immediate pacing tick regardless of the spawn timer.
func force_tick() -> void:
    if _state != EncounterState.ROUND_ACTIVE:
        return
    _run_pacing_tick()


func get_active_group_count() -> int:
    _cleanup_invalid()
    return _active_groups.size()


func get_active_member_count() -> int:
    _cleanup_invalid()
    var total := 0
    for group in _active_groups:
        if is_instance_valid(group):
            total += group.get_member_count()
    return total

# -------------------------
# Internal — Round
# -------------------------


func _begin_round() -> void:
    _groups_to_kill = _config.groups_per_round
    _groups_killed = 0
    _spawn_timer = _config.initial_spawn_cooldown
    _state = EncounterState.ROUND_ACTIVE
    round_started.emit()

    if print_debug_log:
        Debug.log("EncounterController: round started — to_kill=%s" % _groups_to_kill)


func _run_pacing_tick() -> void:
    _cleanup_invalid()

    var active := _active_groups.size() + _pending_spawns
    if _is_kill_budget_exhausted():
        return

    # Within budget: only spawn if below the concurrent cap.
    if active >= _config.target_active_groups:
        return

    var needed := _config.target_active_groups - active
    var budget_left := _kill_budget_remaining()
    var count := mini(needed, _config.max_spawn_per_tick)

    # In wave mode, never queue more groups than the remaining budget allows.
    if budget_left >= 0:
        count = mini(count, budget_left)

    for i in range(count):
        _pending_spawns += 1
        _request_spawn()


func _is_kill_budget_exhausted() -> bool:
    if _groups_to_kill < 0:
        # Endless round — never exhausted.
        return false

    if _config.spawn_beyond_budget:
        # Extermination mode: keep spawning past the budget so enemies are always
        # available to kill. Only stop once kills strictly exceed the budget.
        return _groups_killed >= _groups_to_kill

    # Wave mode: hard stop once (killed + active) reaches the budget.
    # Player must clear remaining stragglers themselves.
    return (_groups_killed + _active_groups.size() + _pending_spawns) >= _groups_to_kill


func _kill_budget_remaining() -> int:
    if _groups_to_kill < 0:
        return -1
    if _config.spawn_beyond_budget:
        # Extermination mode: budget is soft — remaining is unbounded.
        return -1
    return _groups_to_kill - (_groups_killed + _active_groups.size())


func _check_round_cleared() -> void:
    if _state != EncounterState.ROUND_ACTIVE:
        return

    # Endless round — never clears naturally
    if _groups_to_kill < 0:
        return

    if not _is_kill_budget_exhausted():
        return

    if _config.spawn_beyond_budget:
        # Extermination mode: kills exceeded the budget — signal immediately.
        # Caller decides whether to clean up remaining active groups via force_kill_all().
        pass
    else:
        # Wave mode: budget is reached but player must clear remaining stragglers.
        _cleanup_invalid()
        if not _active_groups.is_empty():
            return

    _state = EncounterState.ROUND_CLEARED
    round_cleared.emit()

    if print_debug_log:
        Debug.log("EncounterController: round cleared — killed=%s" % _groups_killed)

# -------------------------
# Internal — Spawning
# -------------------------


func _request_spawn() -> void:
    var profile := _config.group_table.pick_group(_rng)
    if profile == null:
        Debug.warn("EncounterController: group table returned null profile")
        return

    SpawnThrottle.enqueue(&"encounter_enemy", _spawn_group.bind(profile), 0.1)


func _spawn_group(group_profile: EnemyGroupProfile) -> void:
    if warning_point_scene == null:
        Debug.warn("EncounterController: warning_point_scene is null — assign it in the editor")
        return

    if not is_instance_valid(enemies_root):
        Debug.warn("EncounterController: enemies_root is null or freed")
        return

    if not is_instance_valid(enemies_container):
        Debug.warn("EncounterController: enemies_container is null or freed")
        return

    var resolved: Variant = _resolve_spawn_position()
    if resolved == null:
        Debug.warn("EncounterController: could not resolve spawn position")
        return

    var position: Vector2
    var spawn_validator: SpawnPositionValidator = null
    if resolved is Dictionary:
        position = resolved.get("position", Vector2.ZERO)
        spawn_validator = resolved.get("validator") as SpawnPositionValidator
    else:
        position = resolved as Vector2

    var action := SpawnEnemyGroupAction.new()
    action.profile = group_profile
    action.enemies_container = enemies_container

    var ctx := SpawnContext.create(enemies_root)
    ctx.rng_seed = _rng.randi()
    ctx.source_node = self
    ctx.validator = spawn_validator

    var spawned := await SpawnWarningExecutor.execute_at_position(warning_point_scene, action, position, ctx)

    _pending_spawns -= 1

    if not is_instance_valid(self):
        return

    var group := spawned as EnemyGroup
    if group == null:
        Debug.warn("EncounterController: warning spawn did not return an EnemyGroup")
        return

    # A force_kill_all() was called while this spawn was mid-warning — kill on arrival.
    if _force_kill_pending:
        group.force_kill()
        if _pending_spawns == 0:
            _force_kill_pending = false
        return

    _active_groups.append(group)
    group.group_depleted.connect(_on_group_depleted.bind(group))
    group.group_removed.connect(_on_group_removed.bind(group))

    group_spawned.emit(group)

    if print_debug_log:
        Debug.log("EncounterController: spawned group '%s' at %s" % [group_profile.resource_name, position])


func _resolve_spawn_position() -> Variant:
    if not spawn_position_resolver.is_valid():
        Debug.warn("EncounterController: spawn_position_resolver is not set")
        return null
    return spawn_position_resolver.call()

# -------------------------
# Internal — Group Lifecycle
# -------------------------


func _on_group_depleted(group: EnemyGroup) -> void:
    _active_groups.erase(group)
    _groups_killed += 1

    group_depleted.emit(group)

    if print_debug_log:
        Debug.log("EncounterController: group depleted — killed=%s to_kill=%s active=%s" % [_groups_killed, _groups_to_kill, _active_groups.size()])

    _check_round_cleared()


func _on_group_removed(group: EnemyGroup) -> void:
    _active_groups.erase(group)

    group_removed.emit(group)

    if print_debug_log:
        Debug.log("EncounterController: group removed (not killed) — active=%s" % _active_groups.size())

    # Intentionally does NOT call _check_round_cleared.
    # Despawned groups do not count as kills and do not advance the round.


func _clear_all_groups() -> void:
    for group in _active_groups:
        if is_instance_valid(group):
            group.queue_free()
    _active_groups.clear()


func _cleanup_invalid() -> void:
    for i in range(_active_groups.size() - 1, -1, -1):
        if not is_instance_valid(_active_groups[i]):
            _active_groups.remove_at(i)

# -------------------------
# Validation
# -------------------------


func _validate_config(config: EncounterConfig) -> bool:
    if config == null:
        Debug.warn("EncounterController: config is null")
        return false

    if not config.is_valid():
        Debug.warn("EncounterController: config is invalid — check group_table")
        return false

    return true
