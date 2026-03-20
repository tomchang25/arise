extends Node2D

# -------------------------
# Hotkeys
# -------------------------

const ACTION_FORCE_SPAWN := "demo_force_spawn"
const ACTION_CLEAR := "demo_clear"
const ACTION_RESET_PLAYER := "demo_reset_player"
const ACTION_TOGGLE := "demo_toggle"

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
@export var wave_defense_controller: WaveDefenseController

@export_group("Encounter")
@export var encounter_config: EncounterConfig

@export_group("HUD")
@export var wave_hud: WaveHUD

@export_group("Spawn Placement")
@export var min_spawn_distance := 120.0
@export var max_spawn_distance := 480.0
@export var placement_attempts := 12
@export var use_rect_bounds := true
@export var world_rect := Rect2(Vector2(-800.0, -800.0), Vector2(1600.0, 1600.0))
@export var exclude_near_player := true
@export var player_safe_radius := 160.0

@export_group("Debug")
@export var auto_wire := true
@export var print_hotkey_log := true

# -------------------------
# Internal State
# -------------------------

var _rng := RandomNumberGenerator.new()

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _rng.randomize()
    _ensure_test_actions()

    if auto_wire:
        _auto_wire()

    if encounter_controller != null:
        encounter_controller.group_spawned.connect(_on_group_spawned)
        encounter_controller.encounter_started.connect(_on_encounter_started)

    _update_debug_label()

    if encounter_controller != null:
        encounter_controller.spawn_position_resolver = _find_spawn_position

    if wave_defense_controller != null:
        # Wave defense mode: WaveDefenseController drives the encounter.
        if wave_hud != null:
            wave_hud.bind(wave_defense_controller)
        wave_defense_controller.start()
    elif encounter_config != null and encounter_controller != null:
        # Fallback: plain encounter without wave management.
        encounter_controller.start(encounter_config)


func _process(_delta: float) -> void:
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_FORCE_SPAWN):
        _on_force_spawn_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_CLEAR):
        _on_clear_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_PLAYER):
        _on_reset_player_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_TOGGLE):
        _on_toggle_pressed()
        get_viewport().set_input_as_handled()
        return

# -------------------------
# Hotkey Handlers
# -------------------------


func _on_force_spawn_pressed() -> void:
    if encounter_controller == null:
        return
    encounter_controller.force_tick()

    if print_hotkey_log:
        Debug.log("Demo: force spawn")


func _on_clear_pressed() -> void:
    if encounter_controller != null:
        encounter_controller.end()

    if print_hotkey_log:
        Debug.log("Demo: cleared")


func _on_reset_player_pressed() -> void:
    if player == null or player_spawn == null:
        return
    player.global_position = player_spawn.global_position

    if print_hotkey_log:
        Debug.log("Demo: player reset")


func _on_toggle_pressed() -> void:
    if wave_defense_controller != null:
        if encounter_controller != null and encounter_controller.is_active():
            wave_defense_controller.stop()
            if print_hotkey_log:
                Debug.log("Demo: wave defense stopped")
        else:
            wave_defense_controller.start()
            if print_hotkey_log:
                Debug.log("Demo: wave defense started")
        return

    if encounter_controller == null:
        return

    if encounter_controller.is_active():
        encounter_controller.end()
        if print_hotkey_log:
            Debug.log("Demo: encounter stopped")
    else:
        encounter_controller.start(encounter_config)
        if print_hotkey_log:
            Debug.log("Demo: encounter started")

# -------------------------
# Encounter Signals
# -------------------------


func _on_encounter_started() -> void:
    if print_hotkey_log:
        Debug.log("Demo: encounter started")


func _on_group_spawned(group: EnemyGroup) -> void:
    # Register with despawn controller as soon as a group lands
    if despawn_controller != null:
        despawn_controller.register_spawned(group)

    if print_hotkey_log:
        Debug.log("Demo: group spawned — members=%s" % group.get_member_count())

# -------------------------
# Placement
# -------------------------


func _find_spawn_position() -> Variant:
    if player == null:
        return null

    var validator := _build_spawn_validator()

    return SpawnPositionFinder.find_position_in_annulus(player.global_position, min_spawn_distance, max_spawn_distance, validator, _rng, placement_attempts)


func _build_spawn_validator() -> SpawnPositionValidator:
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

    if wave_defense_controller == null:
        wave_defense_controller = get_node_or_null("World/WaveDefenseController") as WaveDefenseController

    if debug_label == null:
        debug_label = get_node_or_null("UI/DebugLabel") as Label

    if wave_hud == null:
        wave_hud = get_node_or_null("UI/WaveHUD") as WaveHUD


func _update_debug_label() -> void:
    if debug_label == null:
        return

    var active_groups := 0
    var active_members := 0
    var groups_killed := 0
    var groups_to_kill := -1

    if encounter_controller != null:
        active_groups = encounter_controller.get_active_group_count()
        active_members = encounter_controller.get_active_member_count()
        groups_killed = encounter_controller._groups_killed
        groups_to_kill = encounter_controller._groups_to_kill

    var budget_str := "%s" % groups_to_kill if groups_to_kill >= 0 else "∞"

    debug_label.text = (
        "\n".join(
            [
                "[F] Force Spawn",
                "[C] Clear",
                "[R] Reset Player",
                "[T] Toggle",
                "",
                "active_groups=%s" % active_groups,
                "active_members=%s" % active_members,
                "killed=%s / budget=%s" % [groups_killed, budget_str],
            ],
        )
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_FORCE_SPAWN, KEY_F)
    _ensure_key_action(ACTION_CLEAR, KEY_C)
    _ensure_key_action(ACTION_RESET_PLAYER, KEY_R)
    _ensure_key_action(ACTION_TOGGLE, KEY_T)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)
    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action_name, input_event)
