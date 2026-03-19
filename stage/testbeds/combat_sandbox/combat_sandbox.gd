class_name CombatSandbox
extends Node2D

# -------------------------
# Actions (auto-registered if missing)
# -------------------------

const ACTION_RESET_ALL := &"test_reset_all"
const ACTION_HEAL_ALL := &"test_heal_all"
const ACTION_KILL_GROUP := &"test_kill_group"
const ACTION_TOGGLE_INVULN := &"test_toggle_invuln"

# -------------------------
# Exports
# -------------------------

@export_group("Scene References")
@export var actor: CombatTestActor
@export var solo_dummy: Dummy
@export var dummy_group_root: Node2D
@export var actor_spawn: Marker2D
@export var debug_label: Label

@export_group("Dummy Group Spawn")
@export var dummy_scene: PackedScene
@export var group_count: int = 6
@export var group_radius: float = 60.0
@export var group_center: Marker2D

@export_group("Dummy Stats")
@export var dummy_max_health: float = 1000.0
@export var dummy_defense: float = 0.0
@export var dummy_invuln_time: float = 0.0

# -------------------------
# Runtime state
# -------------------------

var _invuln_enabled: bool = false
var _group_dummies: Array[Dummy] = []

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _ensure_actions()
    _apply_spawn_positions()
    _spawn_dummy_group()


func _process(_delta: float) -> void:
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_RESET_ALL):
        _reset_all()
        get_viewport().set_input_as_handled()

    elif event.is_action_pressed(ACTION_HEAL_ALL):
        _heal_all()
        get_viewport().set_input_as_handled()

    elif event.is_action_pressed(ACTION_KILL_GROUP):
        _kill_group()
        get_viewport().set_input_as_handled()

    elif event.is_action_pressed(ACTION_TOGGLE_INVULN):
        _toggle_invuln()
        get_viewport().set_input_as_handled()

# -------------------------
# Testbed controls
# -------------------------


func _reset_all() -> void:
    if actor and actor_spawn:
        actor.reset_position(actor_spawn.global_position)

    _reset_dummy(solo_dummy)

    for dummy in _group_dummies:
        if is_instance_valid(dummy):
            dummy.reset_dummy()


func _heal_all() -> void:
    _heal_dummy(solo_dummy)

    for dummy in _group_dummies:
        if is_instance_valid(dummy):
            dummy.heal(dummy_max_health)


func _kill_group() -> void:
    for dummy in _group_dummies:
        if is_instance_valid(dummy) and dummy.stats:
            dummy.stats.health = 0.0


func _toggle_invuln() -> void:
    _invuln_enabled = not _invuln_enabled
    var invuln := dummy_invuln_time if not _invuln_enabled else 99999.0

    _set_dummy_invuln(solo_dummy, invuln)

    for dummy in _group_dummies:
        if is_instance_valid(dummy) and dummy.stats:
            dummy.stats.invuln_time = invuln

# -------------------------
# Dummy setup
# -------------------------


func _spawn_dummy_group() -> void:
    if dummy_scene == null or dummy_group_root == null:
        return

    _group_dummies.clear()

    var center := group_center.global_position if group_center else dummy_group_root.global_position

    for i in range(group_count):
        var angle := TAU * i / float(group_count)
        var offset := Vector2(cos(angle), sin(angle)) * group_radius

        var dummy := dummy_scene.instantiate() as Dummy
        if dummy == null:
            push_error("CombatSandbox: dummy_scene does not instantiate to Dummy")
            continue

        dummy_group_root.add_child(dummy)
        dummy.global_position = center + offset
        _group_dummies.append(dummy)


func _apply_spawn_positions() -> void:
    if actor and actor_spawn:
        actor.global_position = actor_spawn.global_position


func _reset_dummy(dummy: Dummy) -> void:
    if dummy == null:
        return
    dummy.reset_dummy()


func _heal_dummy(dummy: Dummy) -> void:
    if dummy == null:
        return
    dummy.heal(dummy_max_health)


func _set_dummy_invuln(dummy: Dummy, value: float) -> void:
    if dummy == null or dummy.stats == null:
        return
    dummy.stats.invuln_time = value

# -------------------------
# HUD
# -------------------------


func _update_debug_label() -> void:
    if debug_label == null:
        return

    var solo_hp := "—"
    if solo_dummy and solo_dummy.stats:
        solo_hp = "%.0f / %.0f" % [solo_dummy.stats.health, solo_dummy.stats.current_max_health]

    var group_alive := _group_dummies.filter(func(d): return is_instance_valid(d) and d.stats and d.stats.health > 0).size()

    var charge_state := ""
    if actor:
        charge_state = "ON" if actor._charge_active else "off"

    debug_label.text = (
        "\n".join(
            [
                "[R]   Reset all",
                "[H]   Heal all",
                "[K]   Kill group",
                "[I]   Toggle invuln  (%s)" % ("ON" if _invuln_enabled else "off"),
                "",
                "LMB   Slash attack",
                "RMB   Projectile attack",
                "[Hold R]  Charge attack  (%s)" % charge_state,
                "        Contact attack always active",
                "",
                "Solo dummy HP:  %s" % solo_hp,
                "Group alive:    %d / %d" % [group_alive, group_count],
            ],
        )
    )

# -------------------------
# Action registration
# -------------------------


func _ensure_actions() -> void:
    _ensure_key_action(ACTION_RESET_ALL, KEY_T)
    _ensure_key_action(ACTION_HEAL_ALL, KEY_H)
    _ensure_key_action(ACTION_KILL_GROUP, KEY_K)
    _ensure_key_action(ACTION_TOGGLE_INVULN, KEY_I)


func _ensure_key_action(action: StringName, keycode: Key) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)
