extends Node2D

const ACTION_SPAWN_FROM_POINT := "test_spawn_from_point"
const ACTION_SPAWN_FROM_WARNING_POINT := "test_spawn_from_warning_point"
const ACTION_SPAWN_FROM_EXECUTOR := "test_spawn_from_executor"
const ACTION_SPAWN_FROM_WEIGHTED_TABLE := "test_spawn_from_weighted_table"
const ACTION_ROLL_ENCOUNTER := "test_roll_encounter"
const ACTION_CLEAR_SPAWNED := "test_clear_spawned"
const ACTION_RESET_COUNTERS := "test_reset_spawn_counters"

@export_group("Scene References")
@export var world_root: Node2D
@export var spawned_root: Node2D
@export var spawn_point: SpawnPoint
@export var warning_spawn_point: WarningSpawnPoint
@export var warning_spawn_point_scene: PackedScene
@export var debug_label: Label

@export_group("Spawn Data")
@export var direct_spawn_scene: PackedScene
@export var weighted_scene_table: WeightedSceneTable
@export var encounter_table: WeightedEncounterTable

@export_group("Debug")
@export var auto_wire_scene_refs := true
@export var print_hotkey_log := true
@export var default_seed: int = 12345
@export var direct_scatter_radius: float = 24.0
@export var weighted_scatter_radius: float = 48.0
@export var executor_scatter_radius: float = 12.0

var _spawn_count_point: int = 0
var _spawn_count_warning: int = 0
var _spawn_count_executor: int = 0
var _spawn_count_weighted: int = 0
var _last_encounter_text := "n/a"
var _last_mouse_position := Vector2.ZERO

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _ensure_test_actions()

    if auto_wire_scene_refs:
        _auto_wire_scene_refs()

    _wire_spawn_points()
    _update_debug_text()


func _process(_delta: float) -> void:
    _last_mouse_position = get_global_mouse_position()
    _update_debug_text()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_SPAWN_FROM_POINT):
        _on_spawn_from_point_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_SPAWN_FROM_WARNING_POINT):
        _on_spawn_from_warning_point_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_SPAWN_FROM_EXECUTOR):
        _on_spawn_from_executor_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_SPAWN_FROM_WEIGHTED_TABLE):
        _on_spawn_from_weighted_table_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_ROLL_ENCOUNTER):
        _on_roll_encounter_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_CLEAR_SPAWNED):
        _on_clear_spawned_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_COUNTERS):
        _on_reset_counters_pressed()
        get_viewport().set_input_as_handled()
        return


# -------------------------
# Spawn Tests
# -------------------------


func _on_spawn_from_point_pressed() -> void:
    if spawn_point == null:
        Debug.invalid("spawn_point is null")
        return

    var action := _build_direct_action(direct_scatter_radius, false)
    if action == null:
        return

    var ctx := _build_context(default_seed + _spawn_count_point, {"mode": "spawn_point"})

    var spawned := SpawnExecutor.execute_at_node(action, spawn_point, ctx)
    _apply_spawn_debug(spawned, "point_%s" % _spawn_count_point)

    _spawn_count_point += 1

    if print_hotkey_log:
        Debug.log("Spawn from SpawnPoint via SpawnExecutor")


func _on_spawn_from_warning_point_pressed() -> void:
    if spawned_root == null:
        Debug.invalid("spawned_root is null")
        return

    var action := _build_direct_action(direct_scatter_radius, true)
    if action == null:
        return

    var ctx := _build_context(default_seed + 1000 + _spawn_count_warning, {"mode": "warning_spawn_point"})

    var spawned := await _spawn_from_runtime_warning_point(get_global_mouse_position(), action, ctx)
    _apply_spawn_debug(spawned, "warning_%s" % _spawn_count_warning)

    _spawn_count_warning += 1

    if print_hotkey_log:
        Debug.log("Spawn from warning flow")


func _on_spawn_from_executor_pressed() -> void:
    if spawned_root == null:
        Debug.invalid("spawned_root is null")
        return

    var spawn_position := get_global_mouse_position()
    var action := _build_direct_action(executor_scatter_radius, true)
    if action == null:
        return

    var ctx := _build_context(
        default_seed + 2000 + _spawn_count_executor,
        {
            "mode": "executor",
            "mouse_position": spawn_position,
        }
    )

    var spawned := SpawnExecutor.execute_at_position(action, spawn_position, spawned_root, ctx)
    _apply_spawn_debug(spawned, "executor_%s" % _spawn_count_executor)

    _spawn_count_executor += 1

    if print_hotkey_log:
        Debug.log("Spawn from executor at mouse: %s" % spawn_position)


func _on_spawn_from_weighted_table_pressed() -> void:
    if spawn_point == null:
        Debug.invalid("spawn_point is null")
        return

    if weighted_scene_table == null:
        Debug.invalid("weighted_scene_table is null")
        return

    var action := SpawnFromWeightedTableAction.new()
    action.table = weighted_scene_table
    action.parent_mode = SpawnAction.ParentMode.CTX_SPAWN_PARENT
    action.use_anchor_position = true
    action.use_anchor_rotation = false
    action.random_rotation = true
    action.scatter_radius = weighted_scatter_radius

    var ctx := _build_context(default_seed + 3000 + _spawn_count_weighted, {"mode": "weighted_table"})

    var spawned := SpawnExecutor.execute_at_node(action, spawn_point, ctx)
    _apply_spawn_debug(spawned, "weighted_%s" % _spawn_count_weighted)

    _spawn_count_weighted += 1

    if print_hotkey_log:
        Debug.log("Spawn from WeightedSceneTable via SpawnExecutor")


func _on_roll_encounter_pressed() -> void:
    if encounter_table == null:
        Debug.invalid("encounter_table is null")
        _last_encounter_text = "encounter_table=null"
        return

    var ctx := _build_context(default_seed + 4000 + Time.get_ticks_msec(), {})

    var encounter := encounter_table.pick_encounter(ctx.get_rng())
    if encounter == null:
        _last_encounter_text = "roll=null"
    else:
        _last_encounter_text = (
            "size=%s-%s radius=%s unit_entries=%s"
            % [
                encounter.min_size,
                encounter.max_size,
                encounter.spawn_radius,
                encounter.unit_entries.size(),
            ]
        )

    if print_hotkey_log:
        Debug.log("Roll encounter -> %s" % _last_encounter_text)


func _on_clear_spawned_pressed() -> void:
    if spawned_root == null:
        return

    for child in spawned_root.get_children():
        if is_instance_valid(child):
            child.queue_free()

    if print_hotkey_log:
        Debug.log("Spawned cleared")


func _on_reset_counters_pressed() -> void:
    _spawn_count_point = 0
    _spawn_count_warning = 0
    _spawn_count_executor = 0
    _spawn_count_weighted = 0
    _last_encounter_text = "n/a"

    if print_hotkey_log:
        Debug.log("Spawn counters reset")


# -------------------------
# Internal Helpers
# -------------------------


func _auto_wire_scene_refs() -> void:
    if world_root == null:
        world_root = get_node_or_null("WorldRoot") as Node2D

    if spawned_root == null:
        if world_root != null:
            spawned_root = world_root.get_node_or_null("SpawnedRoot") as Node2D
        if spawned_root == null:
            spawned_root = get_node_or_null("WorldRoot/SpawnedRoot") as Node2D

    if spawn_point == null:
        if world_root != null:
            spawn_point = world_root.get_node_or_null("SpawnPoint") as SpawnPoint
        if spawn_point == null:
            spawn_point = get_node_or_null("WorldRoot/SpawnPoint") as SpawnPoint

    if warning_spawn_point == null:
        if world_root != null:
            warning_spawn_point = world_root.get_node_or_null("WarningSpawnPoint") as WarningSpawnPoint
        if warning_spawn_point == null:
            warning_spawn_point = get_node_or_null("WorldRoot/WarningSpawnPoint") as WarningSpawnPoint

    if debug_label == null:
        debug_label = get_node_or_null("UI/DebugLabel") as Label

    if print_hotkey_log:
        (
            Debug
            . log(
                (
                    "SpawnSystemTestbed auto wire -> world_root=%s spawned_root=%s spawn_point=%s warning_spawn_point=%s warning_spawn_point_scene=%s debug_label=%s"
                    % [
                        world_root != null,
                        spawned_root != null,
                        spawn_point != null,
                        warning_spawn_point != null,
                        warning_spawn_point_scene != null,
                        debug_label != null,
                    ]
                )
            )
        )


func _wire_spawn_points() -> void:
    if spawn_point != null:
        spawn_point.spawn_parent = spawned_root


func _build_direct_action(scatter_radius: float, enable_random_rotation: bool) -> SpawnPackedSceneAction:
    if direct_spawn_scene == null:
        Debug.invalid("direct_spawn_scene is null")
        return null

    var action := SpawnPackedSceneAction.new()
    action.scene = direct_spawn_scene
    action.parent_mode = SpawnAction.ParentMode.CTX_SPAWN_PARENT
    action.use_anchor_position = true
    action.use_anchor_rotation = false
    action.random_rotation = enable_random_rotation
    action.scatter_radius = scatter_radius
    return action


func _build_context(ctx_seed: int, extra_metadata: Dictionary) -> SpawnContext:
    var ctx := SpawnContext.new()
    ctx.setup(spawned_root, ctx_seed, self, extra_metadata)
    return ctx


func _spawn_from_runtime_warning_point(target_global_position: Vector2, action: SpawnAction, ctx: SpawnContext) -> Node:
    if warning_spawn_point_scene != null:
        return await SpawnWarningExecutor.execute_at_position(warning_spawn_point_scene, action, target_global_position, spawned_root, ctx)

    var runtime_point := _instantiate_runtime_warning_point()
    if runtime_point == null:
        Debug.invalid("warning_spawn_point_scene and warning_spawn_point are both invalid")
        return null

    spawned_root.add_child(runtime_point)
    runtime_point.global_position = target_global_position
    runtime_point.spawn_parent = spawned_root
    runtime_point.setup(action, ctx)

    return await runtime_point.start()


func _instantiate_runtime_warning_point() -> WarningSpawnPoint:
    if warning_spawn_point == null:
        return null

    if not is_instance_valid(warning_spawn_point):
        return null

    var duplicated := warning_spawn_point.duplicate() as WarningSpawnPoint
    if duplicated == null:
        Debug.warn("SpawnSystemTestbed: failed to duplicate warning_spawn_point")
        return null

    duplicated.name = "%sRuntime" % warning_spawn_point.name
    return duplicated


func _apply_spawn_debug(spawned: Node, debug_name: String) -> void:
    if spawned == null:
        return

    spawned.name = debug_name

    if spawned.has_method("set_debug_text"):
        spawned.call("set_debug_text", debug_name)


func _update_debug_text() -> void:
    if debug_label == null:
        return

    var spawned_count := 0
    if spawned_root != null:
        spawned_count = spawned_root.get_child_count()

    debug_label.text = (
        "\n"
        . join(
            [
                "[1] Spawn from SpawnPoint",
                "[2] Spawn from Warning flow",
                "[3] Spawn from Executor (mouse global position)",
                "[4] Spawn from WeightedSceneTable",
                "[5] Roll WeightedEncounterTable",
                "[C] Clear Spawned",
                "[R] Reset Counters",
                "",
                "mouse_global=%s" % _last_mouse_position,
                "spawned_count=%s" % spawned_count,
                "point_spawns=%s" % _spawn_count_point,
                "warning_spawns=%s" % _spawn_count_warning,
                "executor_spawns=%s" % _spawn_count_executor,
                "weighted_spawns=%s" % _spawn_count_weighted,
                "last_encounter=%s" % _last_encounter_text,
            ]
        )
    )


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_SPAWN_FROM_POINT, KEY_1)
    _ensure_key_action(ACTION_SPAWN_FROM_WARNING_POINT, KEY_2)
    _ensure_key_action(ACTION_SPAWN_FROM_EXECUTOR, KEY_3)
    _ensure_key_action(ACTION_SPAWN_FROM_WEIGHTED_TABLE, KEY_4)
    _ensure_key_action(ACTION_ROLL_ENCOUNTER, KEY_5)
    _ensure_key_action(ACTION_CLEAR_SPAWNED, KEY_C)
    _ensure_key_action(ACTION_RESET_COUNTERS, KEY_R)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)

    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action_name, input_event)
