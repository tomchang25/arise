extends Node2D

# -------------------------
# Actions
# -------------------------

const ACTION_TEST_KILL_QUOTA := "test_obj_kill_quota"
const ACTION_TEST_KILL_BOSS := "test_obj_kill_boss"
const ACTION_TEST_EXTRACTION := "test_obj_extraction"
const ACTION_SIMULATE_KILL := "test_obj_simulate_kill"
const ACTION_SIMULATE_BOSS_DEATH := "test_obj_simulate_boss_death"
const ACTION_CLEAR_OBJECTIVE := "test_obj_clear"

# -------------------------
# Exports
# -------------------------

@export_group("Scene References")
@export var objective_manager: ObjectiveManager
@export var extraction_point: ExtractionPoint
@export var debug_label: Label
@export var hud_label: Label

@export_group("Kill Quota Settings")
@export var kill_quota_target: int = 5

@export_group("Debug")
@export var print_hotkey_log := true

# -------------------------
# State
# -------------------------

var _simulated_kills: int = 0
var _simulated_boss_deaths: int = 0
var _boss_nodes: Array[Node] = []
var _last_event: String = "none"
var _objective_label_text: String = "none"
var _status_text: String = "idle"

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _ensure_test_actions()
    _wire_event_bus()
    _wire_manager()
    _update_debug_text()


func _process(_delta: float) -> void:
    _poll_objective_text()
    _update_debug_text()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_TEST_KILL_QUOTA):
        _on_test_kill_quota_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_TEST_KILL_BOSS):
        _on_test_kill_boss_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_TEST_EXTRACTION):
        _on_test_extraction_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_SIMULATE_KILL):
        _on_simulate_kill_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_SIMULATE_BOSS_DEATH):
        _on_simulate_boss_death_pressed()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_CLEAR_OBJECTIVE):
        _on_clear_objective_pressed()
        get_viewport().set_input_as_handled()
        return


# -------------------------
# Objective Tests
# -------------------------


func _on_test_kill_quota_pressed() -> void:
    _simulated_kills = 0
    _boss_nodes.clear()

    var objective := KillQuotaObjective.new()
    objective.target_count = kill_quota_target
    objective_manager.register(objective)

    _status_text = "KillQuota active (target: %d)" % kill_quota_target
    _last_event = "registered KillQuotaObjective"

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: registered KillQuotaObjective target=%d" % kill_quota_target)


func _on_test_kill_boss_pressed() -> void:
    _simulated_kills = 0
    _simulated_boss_deaths = 0

    # Create 2 dummy boss nodes to track
    _boss_nodes.clear()
    for i in range(2):
        var dummy := Node.new()
        dummy.name = "DummyBoss_%d" % i
        add_child(dummy)
        _boss_nodes.append(dummy)

    var objective := KillBossObjective.new()
    objective.register_bosses(_boss_nodes)
    objective_manager.register(objective)

    _status_text = "KillBoss active (bosses: %d)" % _boss_nodes.size()
    _last_event = "registered KillBossObjective"

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: registered KillBossObjective bosses=%d" % _boss_nodes.size())


func _on_test_extraction_pressed() -> void:
    _simulated_kills = 0
    _boss_nodes.clear()

    if extraction_point == null:
        Debug.invalid("ObjectiveTestbed: extraction_point is not assigned")
        _status_text = "ERROR: extraction_point not assigned"
        return

    var objective := ExtractionObjective.new()
    objective.setup(extraction_point)
    objective_manager.register(objective)

    _status_text = "Extraction active — walk into the zone and hold"
    _last_event = "registered ExtractionObjective"

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: registered ExtractionObjective")


# -------------------------
# Simulation Actions
# -------------------------


func _on_simulate_kill_pressed() -> void:
    _simulated_kills += 1
    _last_event = "enemy_killed #%d" % _simulated_kills

    # Emit with a placeholder node — quota objective only needs the count
    EventBus.enemy_killed.emit(self)

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: simulated enemy_killed #%d" % _simulated_kills)


func _on_simulate_boss_death_pressed() -> void:
    if _boss_nodes.is_empty():
        _last_event = "no boss nodes (start KillBoss first)"
        if print_hotkey_log:
            Debug.log("ObjectiveTestbed: no boss nodes to kill")
        return

    # Free the next alive boss
    for i in range(_boss_nodes.size()):
        var boss := _boss_nodes[i]
        if is_instance_valid(boss):
            _simulated_boss_deaths += 1
            _last_event = "boss died (%d remaining)" % (_boss_nodes.size() - _simulated_boss_deaths)
            boss.queue_free()

            if print_hotkey_log:
                Debug.log("ObjectiveTestbed: simulated boss death #%d" % _simulated_boss_deaths)
            return

    _last_event = "all bosses already dead"


func _on_clear_objective_pressed() -> void:
    objective_manager.clear()
    _boss_nodes.clear()
    _simulated_kills = 0
    _simulated_boss_deaths = 0
    _status_text = "idle"
    _last_event = "cleared"

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: objective cleared")


# -------------------------
# Internal Helpers
# -------------------------


func _wire_event_bus() -> void:
    EventBus.objective_completed.connect(_on_objective_completed)


func _wire_manager() -> void:
    if objective_manager == null:
        push_warning("ObjectiveTestbed: objective_manager is not assigned")
        return

    objective_manager.objective_changed.connect(_on_objective_changed)
    objective_manager.objective_completed.connect(_on_objective_completed_manager)


func _poll_objective_text() -> void:
    if objective_manager == null:
        return

    var obj := objective_manager.current_objective
    if obj == null:
        _objective_label_text = "—"
    else:
        _objective_label_text = obj.get_objective_text()

    if hud_label != null:
        hud_label.text = _objective_label_text


func _update_debug_text() -> void:
    if debug_label == null:
        return

    var manager_state := "null"
    if objective_manager != null:
        manager_state = "has objective" if objective_manager.current_objective != null else "empty"

    debug_label.text = (
        "\n"
        . join(
            [
                "[1] Register KillQuotaObjective (target: %d)" % kill_quota_target,
                "[2] Register KillBossObjective (2 dummy bosses)",
                "[3] Register ExtractionObjective",
                "[K] Simulate enemy_killed",
                "[B] Simulate boss death",
                "[C] Clear objective",
                "",
                "status: %s" % _status_text,
                "manager: %s" % manager_state,
                "objective: %s" % _objective_label_text,
                "last_event: %s" % _last_event,
                "kills_simulated: %d" % _simulated_kills,
                "boss_deaths_simulated: %d" % _simulated_boss_deaths,
            ]
        )
    )


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_objective_changed(objective: Objective) -> void:
    if objective == null:
        _last_event = "objective_changed → null"
    else:
        _last_event = "objective_changed → %s" % objective.get_class()


func _on_objective_completed(_objective: Objective) -> void:
    _status_text = "COMPLETED ✓"
    _last_event = "objective_completed (EventBus)"

    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: objective_completed received from EventBus")


func _on_objective_completed_manager(_objective: Objective) -> void:
    if print_hotkey_log:
        Debug.log("ObjectiveTestbed: objective_completed received from manager signal")


# -------------------------
# Setup
# -------------------------


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_TEST_KILL_QUOTA, KEY_1)
    _ensure_key_action(ACTION_TEST_KILL_BOSS, KEY_2)
    _ensure_key_action(ACTION_TEST_EXTRACTION, KEY_3)
    _ensure_key_action(ACTION_SIMULATE_KILL, KEY_K)
    _ensure_key_action(ACTION_SIMULATE_BOSS_DEATH, KEY_B)
    _ensure_key_action(ACTION_CLEAR_OBJECTIVE, KEY_C)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return

    InputMap.add_action(action_name)

    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)
