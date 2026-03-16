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

## Assign a callable from outside to resolve spawn positions.
## Signature: func() -> Variant  (returns Vector2 or null)
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
func end() -> void:
    _state = EncounterState.IDLE
    _config = null
    _spawn_timer = 0.0
    _groups_to_kill = 0
    _groups_killed = 0
    _clear_all_groups()


func is_active() -> bool:
    return _state == EncounterState.ROUND_ACTIVE


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

    var active := _active_groups.size()

    if active >= _config.target_active_groups:
        return

    # Budget exhausted — wait for remaining groups to be killed
    if _is_kill_budget_exhausted():
        return

    var needed := _config.target_active_groups - active
    var budget_left := _kill_budget_remaining()
    var count := mini(needed, _config.max_spawn_per_tick)

    if budget_left >= 0:
        count = mini(count, budget_left)

    for _i in range(count):
        _request_spawn()


func _is_kill_budget_exhausted() -> bool:
    if _groups_to_kill < 0:
        return false
    # Stop spawning once (killed + currently active) reaches the budget
    return (_groups_killed + _active_groups.size()) >= _groups_to_kill


func _kill_budget_remaining() -> int:
    if _groups_to_kill < 0:
        return -1
    return _groups_to_kill - (_groups_killed + _active_groups.size())


func _check_round_cleared() -> void:
    if _state != EncounterState.ROUND_ACTIVE:
        return

    # Endless round — never clears naturally
    if _groups_to_kill < 0:
        return

    # Round clears only when required kills are reached AND no active groups remain
    if _groups_killed < _groups_to_kill:
        return

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

    _spawn_group(profile)


func _spawn_group(group_profile: EnemyGroupProfile) -> void:
    if warning_point_scene == null:
        Debug.warn("EncounterController: warning_point_scene is null — assign it in the editor")
        return

    if not is_instance_valid(enemies_root):
        Debug.warn("EncounterController: enemies_root is null or freed")
        return

    var position: Variant = _resolve_spawn_position()
    if position == null:
        Debug.warn("EncounterController: could not resolve spawn position")
        return

    var action := SpawnEnemyGroupAction.new()
    action.profile = group_profile

    var ctx := SpawnContext.new()
    ctx.setup(enemies_root, _rng.randi(), self)

    var spawned := await SpawnWarningExecutor.execute_at_position(warning_point_scene, action, position, ctx)

    if not is_instance_valid(self):
        return

    var group := spawned as EnemyGroup
    if group == null:
        Debug.warn("EncounterController: warning spawn did not return an EnemyGroup")
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
    _active_groups = _active_groups.filter(func(g): return is_instance_valid(g))


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
