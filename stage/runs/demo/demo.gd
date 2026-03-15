extends Node2D

# -------------------------
# Hotkeys
# -------------------------

const ACTION_FORCE_SPAWN := "demo_force_spawn"
const ACTION_CLEAR_GROUPS := "demo_clear_groups"
const ACTION_RESET_PLAYER := "demo_reset_player"
const ACTION_TOGGLE_SPAWN := "demo_toggle_spawn"

# -------------------------
# Exports
# -------------------------

@export_group("Scene References")
@export var player: Node2D
@export var player_spawn: Marker2D
@export var enemies_root: Node2D
@export var debug_label: Label

@export_group("Controllers")
@export var encounter_controller: EncounterController
@export var despawn_controller: DespawnController

@export_group("Encounter")
@export var encounter_table: WeightedEncounterTable

@export_group("Pacing")
@export var auto_start := true
@export var target_active_count := 10
@export var max_active_count := 20
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

@export_group("Player Exclusion")
@export var exclude_near_player := true
@export var player_safe_radius := 160.0

@export_group("Debug")
@export var auto_wire := true
@export var print_hotkey_log := true

# -------------------------
# Internal State
# -------------------------

var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _started := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()
    _spawn_timer = initial_spawn_cooldown

    _ensure_test_actions()

    if auto_wire:
        _auto_wire()

    if encounter_controller != null:
        encounter_controller.group_spawned.connect(_on_group_spawned)
        encounter_controller.encounter_cleared.connect(_on_encounter_cleared)

    if auto_start:
        _started = true

    _update_debug_label()


func _process(delta: float) -> void:
    _tick_spawning(delta)
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_FORCE_SPAWN):
        _on_force_spawn_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_CLEAR_GROUPS):
        _on_clear_groups_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_PLAYER):
        _on_reset_player_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_TOGGLE_SPAWN):
        _on_toggle_spawn_pressed()
        get_viewport().set_input_as_handled()
        return


# -------------------------
# Hotkey Handlers
# -------------------------


func _on_force_spawn_pressed() -> void:
    _run_pacing_tick(true)

    if print_hotkey_log:
        Debug.log("Demo: force spawn triggered")


func _on_clear_groups_pressed() -> void:
    if encounter_controller != null:
        encounter_controller.clear_all_groups()

    if print_hotkey_log:
        Debug.log("Demo: cleared all groups")


func _on_reset_player_pressed() -> void:
    if player == null or player_spawn == null:
        return

    player.global_position = player_spawn.global_position

    if print_hotkey_log:
        Debug.log("Demo: player reset")


func _on_toggle_spawn_pressed() -> void:
    _started = not _started

    if print_hotkey_log:
        Debug.log("Demo: spawning %s" % ("started" if _started else "stopped"))


# -------------------------
# Encounter Signals
# -------------------------


func _on_group_spawned(group: EnemyGroup) -> void:
    if print_hotkey_log:
        Debug.log("Demo: group spawned — members=%s" % group.get_member_count())


func _on_encounter_cleared() -> void:
    if print_hotkey_log:
        Debug.log("Demo: encounter cleared")


# -------------------------
# Pacing
# -------------------------


func _tick_spawning(delta: float) -> void:
    if not _started or player == null:
        return

    _spawn_timer -= delta
    if _spawn_timer > 0.0:
        return

    _spawn_timer = maxf(spawn_interval, 0.01)
    _run_pacing_tick(false)


func _run_pacing_tick(force: bool) -> void:
    if not _can_spawn():
        return

    var active_count := _get_active_count()

    if not force:
        if not respawn_when_below_target:
            return
        if active_count >= max_active_count:
            return
        if active_count >= target_active_count:
            return

    var needed := target_active_count - active_count
    var allowed := max_active_count - active_count
    var spawn_count := mini(mini(needed, allowed), max_spawn_per_tick)

    if force:
        spawn_count = max_spawn_per_tick

    if spawn_count <= 0:
        return

    _schedule_spawn_batch(spawn_count)


func _can_spawn() -> bool:
    if player == null:
        Debug.invalid("Demo: player is null")
        return false

    if encounter_controller == null:
        Debug.invalid("Demo: encounter_controller is null")
        return false

    if encounter_table == null:
        Debug.invalid("Demo: encounter_table is null")
        return false

    return true


func _get_active_count() -> int:
    if encounter_controller == null:
        return 0
    return encounter_controller.get_active_group_count()


# -------------------------
# Placement
# -------------------------


func _schedule_spawn_batch(count: int) -> void:
    for _i in range(count):
        var spawn_pos_variant: Variant = _find_spawn_position()
        if spawn_pos_variant == null:
            if print_hotkey_log:
                Debug.log("Demo: failed to find spawn position")
            continue

        _spawn_encounter_at(spawn_pos_variant as Vector2)


func _spawn_encounter_at(spawn_position: Vector2) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = _rng.randi()

    var profile := encounter_table.pick_encounter(rng)
    if profile == null:
        if print_hotkey_log:
            Debug.log("Demo: encounter roll returned null")
        return

    var valid_groups := profile.get_valid_groups()
    var positions: Array[Vector2] = []
    for _i in range(valid_groups.size()):
        positions.append(spawn_position)

    encounter_controller.spawn_encounter(profile, spawn_position, positions)


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

    return validator


# -------------------------
# Internal Helpers
# -------------------------


func _auto_wire() -> void:
    if player == null:
        player = get_node_or_null("World/Player") as Node2D

    if player_spawn == null:
        player_spawn = get_node_or_null("World/PlayerSpawn") as Marker2D

    if enemies_root == null:
        enemies_root = get_node_or_null("World/EnemiesRoot") as Node2D

    if encounter_controller == null:
        encounter_controller = get_node_or_null("World/EncounterController") as EncounterController

    if despawn_controller == null:
        despawn_controller = get_node_or_null("World/DespawnController") as DespawnController

    if debug_label == null:
        debug_label = get_node_or_null("UI/DebugLabel") as Label


func _update_debug_label() -> void:
    if debug_label == null:
        return

    var active_groups := 0
    var active_members := 0
    if encounter_controller != null:
        active_groups = encounter_controller.get_active_group_count()
        active_members = encounter_controller.get_active_member_count()

    debug_label.text = (
        "\n"
        . join(
            [
                "[F] Force Spawn",
                "[C] Clear Groups",
                "[R] Reset Player",
                "[T] Toggle Spawning",
                "",
                "spawning=%s" % ("on" if _started else "off"),
                "active_groups=%s" % active_groups,
                "active_members=%s" % active_members,
                "active=%s / target=%s" % [active_groups, target_active_count],
            ]
        )
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_FORCE_SPAWN, KEY_F)
    _ensure_key_action(ACTION_CLEAR_GROUPS, KEY_C)
    _ensure_key_action(ACTION_RESET_PLAYER, KEY_R)
    _ensure_key_action(ACTION_TOGGLE_SPAWN, KEY_T)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)

    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action_name, input_event)
