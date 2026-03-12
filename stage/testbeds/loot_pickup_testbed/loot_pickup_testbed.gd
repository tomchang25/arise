extends Node2D

const ACTION_KILL_DUMMY := "test_kill_dummy"
const ACTION_RESET_DUMMY := "test_reset_dummy"
const ACTION_CLEAR_PICKUPS := "test_clear_pickups"
const ACTION_RESET_PLAYER := "test_reset_player"

@export_group("Scene References")
@export var dummy: LootTestDummy
@export var player: LootTestPlayer
@export var pickups_root: Node2D
@export var world_root: Node2D
@export var dummy_spawn: Marker2D
@export var player_spawn: Marker2D
@export var debug_label: Label
@export var loot_world_spawner: LootWorldSpawner

@export_group("Debug")
@export var print_hotkey_log := true

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _ensure_test_actions()
    _apply_start_positions()
    _setup_player()
    _setup_dummy()
    _update_debug_text()


func _process(_delta: float) -> void:
    _update_debug_text()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_KILL_DUMMY):
        _on_kill_dummy_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_DUMMY):
        _on_reset_dummy_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_CLEAR_PICKUPS):
        _on_clear_pickups_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_PLAYER):
        _on_reset_player_pressed()
        get_viewport().set_input_as_handled()
        return


# -------------------------
# Testbed Control
# -------------------------


func _on_kill_dummy_pressed() -> void:
    if dummy == null:
        Debug.invalid("Dummy is null")
        return

    dummy.kill_dummy()

    if print_hotkey_log:
        Debug.log("Kill dummy")

    dummy.visible = false


func _on_reset_dummy_pressed() -> void:
    if dummy == null:
        return

    dummy.reset_dummy()

    if dummy_spawn != null:
        dummy.global_position = dummy_spawn.global_position

    if print_hotkey_log:
        Debug.log("Dummy reset")


func _on_clear_pickups_pressed() -> void:
    if pickups_root == null:
        return

    for child in pickups_root.get_children():
        if is_instance_valid(child):
            child.queue_free()

    if print_hotkey_log:
        Debug.log("Pickups cleared")


func _on_reset_player_pressed() -> void:
    if player == null:
        return

    player.reset_test_state()

    if player_spawn != null:
        player.global_position = player_spawn.global_position

    if print_hotkey_log:
        Debug.log("Player reset")


# -------------------------
# Internal Helpers
# -------------------------


func _setup_player() -> void:
    if player == null:
        return

    player._wire_modules()


func _setup_dummy() -> void:
    if dummy == null:
        return

    if dummy.loot_drop_module == null:
        Debug.log("[loot_pickup_testbed] dummy.loot_drop_module is null")
        return

    dummy.loot_drop_module.owner_node = dummy
    dummy.loot_drop_module.world_spawner = loot_world_spawner

    if loot_world_spawner != null and pickups_root != null:
        loot_world_spawner.world_root = pickups_root


func _apply_start_positions() -> void:
    if dummy != null and dummy_spawn != null:
        dummy.global_position = dummy_spawn.global_position

    if player != null and player_spawn != null:
        player.global_position = player_spawn.global_position


func _update_debug_text() -> void:
    if debug_label == null:
        return

    var dummy_state := "Alive"
    if dummy != null and not dummy.alive:
        dummy_state = "Dead"

    var pickup_count := 0
    if pickups_root != null:
        pickup_count = pickups_root.get_child_count()

    var player_text := ""
    if player != null:
        player_text = player.get_debug_text()

    debug_label.text = (
        "\n"
        . join(
            [
                "[K] Kill Dummy",
                "[R] Reset Dummy",
                "[C] Clear Pickups",
                "[P] Reset Player",
                "",
                "Dummy: %s" % dummy_state,
                "Pickups: %s" % pickup_count,
                "",
                player_text,
            ]
        )
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_KILL_DUMMY, KEY_K)
    _ensure_key_action(ACTION_RESET_DUMMY, KEY_R)
    _ensure_key_action(ACTION_CLEAR_PICKUPS, KEY_C)
    _ensure_key_action(ACTION_RESET_PLAYER, KEY_P)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)

    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)
