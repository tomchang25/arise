## Formation Testbed
## Interactively tests the ArmyHandler formation system.
##
## Hotkeys
## -------
##   [S] — Spawn one NinjaGreen unit into the formation
##   [C] — Remove all units from the formation
##   [1] — Switch to RECTANGULAR formation
##   [2] — Switch to CIRCULAR formation
extends Node2D

const ACTION_SPAWN := "formation_test_spawn"
const ACTION_CLEAR := "formation_test_clear"
const ACTION_FORMATION_RECT := "formation_test_rect"
const ACTION_FORMATION_CIRC := "formation_test_circ"

@export_group("Scene References")
@export var army_handler: ArmyHandler
@export var spawn_origin: Node2D
@export var debug_label: Label

@export_group("Spawn Data")
@export var unit_scene: PackedScene
@export var unit_data: ArmyData


func _ready() -> void:
	_ensure_test_actions()
	_update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_SPAWN):
		_spawn_unit()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(ACTION_CLEAR):
		_clear_units()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(ACTION_FORMATION_RECT):
		_set_formation(ArmyHandler.FormationType.RECTANGULAR)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(ACTION_FORMATION_CIRC):
		_set_formation(ArmyHandler.FormationType.CIRCULAR)
		get_viewport().set_input_as_handled()
		return


func _process(_delta: float) -> void:
	_update_debug_label()


# -------------------------
# Actions
# -------------------------


func _spawn_unit() -> void:
	if army_handler == null:
		push_warning("FormationTestbed: army_handler is null")
		return

	if army_handler.is_grid_full():
		push_warning("FormationTestbed: formation grid is full")
		return

	if unit_scene == null:
		push_warning("FormationTestbed: unit_scene is null")
		return

	var unit := unit_scene.instantiate() as Army
	if unit == null:
		push_warning("FormationTestbed: unit_scene did not instantiate as Army")
		return

	if unit_data != null:
		unit.data = unit_data

	var origin := spawn_origin.global_position if spawn_origin else Vector2.ZERO
	unit.global_position = origin

	# Adding as child of ArmyHandler triggers add_unit via child_entered_tree.
	army_handler.add_child(unit)


func _clear_units() -> void:
	if army_handler == null:
		return

	for child in army_handler.get_children():
		if child is CharacterBody2D:
			child.queue_free()


func _set_formation(type: ArmyHandler.FormationType) -> void:
	if army_handler == null:
		return

	army_handler.set_formation_type(type)
	_update_debug_label()


# -------------------------
# UI
# -------------------------


func _update_debug_label() -> void:
	if debug_label == null:
		return

	var unit_count := 0
	var formation_name := "—"

	if army_handler != null:
		unit_count = army_handler.get_all_units().size()
		formation_name = (
			"Rectangular"
			if army_handler.formation_type == ArmyHandler.FormationType.RECTANGULAR
			else "Circular"
		)

	debug_label.text = "\n".join([
		"[S]  Spawn unit",
		"[C]  Clear all units",
		"[1]  Rectangular formation",
		"[2]  Circular formation",
		"",
		"Formation : %s" % formation_name,
		"Units     : %d" % unit_count,
	])


# -------------------------
# Setup
# -------------------------


func _ensure_test_actions() -> void:
	_ensure_key_action(ACTION_SPAWN, KEY_S)
	_ensure_key_action(ACTION_CLEAR, KEY_C)
	_ensure_key_action(ACTION_FORMATION_RECT, KEY_1)
	_ensure_key_action(ACTION_FORMATION_CIRC, KEY_2)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)

	var input_event := InputEventKey.new()
	input_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, input_event)
