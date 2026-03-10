extends Node2D

const ACTION_KILL_DUMMY := "test_kill_dummy"
const ACTION_NEXT_TABLE := "test_next_loot_table"
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

@export_group("Loot Tables")
@export var loot_tables: Array[LootDropTable] = []
@export var start_table_index: int = 0

@export_group("Debug")
@export var print_hotkey_log := true

var _current_table_index := 0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _ensure_test_actions()
    _apply_start_positions()
    _setup_dummy()
    _set_table_index(start_table_index)
    _update_debug_text()


func _process(_delta: float) -> void:
    _update_debug_text()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_KILL_DUMMY):
        _on_kill_dummy_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_NEXT_TABLE):
        _on_next_loot_table_pressed()
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
        push_warning("[loot_pickup_testbed] dummy is null")
        return

    var results := dummy.kill_dummy()

    if print_hotkey_log:
        print("[loot_pickup_testbed] kill dummy -> %s result(s)" % results.size())
        for i in range(results.size()):
            var r := results[i]
            if r == null:
                print("  [%s] null" % i)
                continue

            print("  [%s] kind=%s amount=%s resource_type=%s item_id=%s" % [i, str(r.reward_kind), r.amount, String(r.resource_type), String(r.item_id)])

    dummy.visible = false


func _on_next_loot_table_pressed() -> void:
    if loot_tables.is_empty():
        push_warning("[loot_pickup_testbed] loot_tables is empty")
        return

    var next_index := (_current_table_index + 1) % loot_tables.size()
    _set_table_index(next_index)

    if print_hotkey_log:
        print("[loot_pickup_testbed] switched loot table -> index %s" % _current_table_index)


func _on_reset_dummy_pressed() -> void:
    if dummy == null:
        return

    dummy.reset_dummy()

    if dummy_spawn:
        dummy.global_position = dummy_spawn.global_position

    if print_hotkey_log:
        print("[loot_pickup_testbed] dummy reset")


func _on_clear_pickups_pressed() -> void:
    if pickups_root == null:
        return

    for child in pickups_root.get_children():
        if is_instance_valid(child):
            child.queue_free()

    if print_hotkey_log:
        print("[loot_pickup_testbed] pickups cleared")


func _on_reset_player_pressed() -> void:
    if player == null:
        return

    player.reset_test_state()

    if player_spawn:
        player.global_position = player_spawn.global_position

    if print_hotkey_log:
        print("[loot_pickup_testbed] player reset")


# -------------------------
# Internal Helpers
# -------------------------


func _setup_dummy() -> void:
    if dummy == null:
        return

    if dummy.loot_drop_module == null:
        push_warning("[loot_pickup_testbed] dummy.loot_drop_module is null")
        return

    dummy.loot_drop_module.owner_node = dummy

    if dummy.loot_drop_module.spawn_context == null:
        dummy.loot_drop_module.spawn_context = SpawnContext.new()

    if world_root != null:
        dummy.loot_drop_module.spawn_context.spawn_root = world_root

    if pickups_root != null:
        dummy.loot_drop_module.spawn_parent_mode = LootSpawnAction.ParentMode.NODEPATH_FROM_SPAWN_POINT
        dummy.loot_drop_module.spawn_parent_path = ^"../PickupsRoot"


func _set_table_index(index: int) -> void:
    if loot_tables.is_empty():
        _current_table_index = 0
        if dummy:
            dummy.set_drop_table(null)
        return

    _current_table_index = clampi(index, 0, loot_tables.size() - 1)

    if dummy:
        dummy.set_drop_table(loot_tables[_current_table_index])


func _apply_start_positions() -> void:
    if dummy and dummy_spawn:
        dummy.global_position = dummy_spawn.global_position

    if player and player_spawn:
        player.global_position = player_spawn.global_position


func _update_debug_text() -> void:
    if debug_label == null:
        return

    var table_name := "None"
    if not loot_tables.is_empty():
        var table := loot_tables[_current_table_index]
        table_name = table.resource_path.get_file() if table != null and table.resource_path != "" else "LootTable[%s]" % _current_table_index

    var dummy_state := "Alive"
    if dummy and not dummy.alive:
        dummy_state = "Dead"

    var player_text := ""
    if player:
        player_text = player.get_debug_text()

    debug_label.text = "\n".join(
        [
            "[K] Kill Dummy",
            "[T] Next Loot Table",
            "[R] Reset Dummy",
            "[C] Clear Pickups",
            "[P] Reset Player",
            "",
            "Dummy: %s" % dummy_state,
            "Loot Table Index: %s" % _current_table_index,
            "Loot Table: %s" % table_name,
            "",
            player_text
        ]
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_KILL_DUMMY, KEY_K)
    _ensure_key_action(ACTION_NEXT_TABLE, KEY_T)
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
