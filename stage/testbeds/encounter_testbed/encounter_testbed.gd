extends Node2D

# -------------------------
# Hotkeys
# -------------------------

const ACTION_SPAWN_ENCOUNTER := "test_spawn_encounter"
const ACTION_CLEAR_GROUPS := "test_clear_groups"
const ACTION_RESET_PLAYER := "test_reset_player"

# -------------------------
# Exports
# -------------------------

@export_group("Scene References")
@export var player: Node2D
@export var player_spawn: Marker2D
@export var enemies_root: Node2D
@export var debug_label: Label

@export_group("Encounter")
@export var encounter_table: WeightedEncounterTable
@export var encounter_controller: EncounterController

@export_group("Spawn Placement")
@export var spawn_origin: Marker2D
@export var min_spawn_distance: float = 120.0
@export var max_spawn_distance: float = 400.0
@export var placement_attempts: int = 12

@export_group("Debug")
@export var auto_wire := true
@export var print_hotkey_log := true

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
        encounter_controller.encounter_cleared.connect(_on_encounter_cleared)

    _update_debug_label()


func _process(_delta: float) -> void:
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_SPAWN_ENCOUNTER):
        _on_spawn_encounter_pressed()
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


# -------------------------
# Hotkey Handlers
# -------------------------


func _on_spawn_encounter_pressed() -> void:
    if encounter_table == null:
        Debug.invalid("EncounterTestbed: encounter_table is null")
        return

    if encounter_controller == null:
        Debug.invalid("EncounterTestbed: encounter_controller is null")
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = _rng.randi()

    var profile := encounter_table.pick_encounter(rng)
    if profile == null:
        Debug.warn("EncounterTestbed: encounter roll returned null")
        return

    var valid_groups := profile.get_valid_groups()
    var positions: Array[Vector2] = []
    for _i in range(valid_groups.size()):
        positions.append(_pick_spawn_position())

    encounter_controller.spawn_encounter(profile, _get_origin(), positions)

    if print_hotkey_log:
        Debug.log("EncounterTestbed: spawning encounter with %s groups" % valid_groups.size())


func _on_clear_groups_pressed() -> void:
    if encounter_controller != null:
        encounter_controller.clear_all_groups()

    if print_hotkey_log:
        Debug.log("EncounterTestbed: cleared all groups")


func _on_reset_player_pressed() -> void:
    if player == null or player_spawn == null:
        return

    player.global_position = player_spawn.global_position

    if print_hotkey_log:
        Debug.log("EncounterTestbed: player reset")


# -------------------------
# Encounter Signals
# -------------------------


func _on_group_spawned(group: EnemyGroup) -> void:
    if print_hotkey_log:
        Debug.log("EncounterTestbed: group spawned — members=%s" % group.get_member_count())


func _on_encounter_cleared() -> void:
    if print_hotkey_log:
        Debug.log("EncounterTestbed: encounter cleared")


# -------------------------
# Internal Helpers
# -------------------------


func _get_origin() -> Vector2:
    if spawn_origin != null:
        return spawn_origin.global_position
    if player != null:
        return player.global_position
    return Vector2.ZERO


func _pick_spawn_position() -> Vector2:
    var origin := _get_origin()

    if player != null:
        var validator := SpawnPositionValidator.new()
        if is_inside_tree():
            validator.world_2d = get_world_2d()
        validator.use_excluded_radius = true
        validator.excluded_center = player.global_position
        validator.excluded_radius = min_spawn_distance

        var found: Variant = SpawnPositionFinder.find_position_in_annulus(origin, min_spawn_distance, max_spawn_distance, validator, _rng, placement_attempts)
        if found != null:
            return found as Vector2

    return origin + SpatialRandomUtils.random_point_in_circle(Vector2.ZERO, max_spawn_distance, _rng)


func _auto_wire() -> void:
    if player == null:
        player = get_node_or_null("World/Player") as Node2D

    if player_spawn == null:
        player_spawn = get_node_or_null("World/PlayerSpawn") as Marker2D

    if enemies_root == null:
        enemies_root = get_node_or_null("World/EnemiesRoot") as Node2D

    if spawn_origin == null:
        spawn_origin = get_node_or_null("World/SpawnOrigin") as Marker2D

    if encounter_controller == null:
        encounter_controller = get_node_or_null("World/EncounterController") as EncounterController

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
                "[1] Spawn Encounter",
                "[C] Clear Groups",
                "[R] Reset Player",
                "",
                "active_groups=%s" % active_groups,
                "active_members=%s" % active_members,
            ]
        )
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_SPAWN_ENCOUNTER, KEY_1)
    _ensure_key_action(ACTION_CLEAR_GROUPS, KEY_C)
    _ensure_key_action(ACTION_RESET_PLAYER, KEY_R)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)

    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action_name, input_event)
