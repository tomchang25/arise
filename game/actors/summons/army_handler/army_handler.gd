class_name ArmyHandler
extends Node2D

signal unit_grid_changed

enum FormationType { RECTANGULAR, CIRCULAR }

@export var size := 100
@export var grid_size := 12
@export var formation_type: FormationType = FormationType.RECTANGULAR

@onready var debug_timer: Timer = $DebugTimer

var units: Array[Node]

## Player reference — resolved at _ready(). ArmyHandler is the single source of
## truth for each unit's anchor_position and updates it every physics frame.
var _player: Node2D

## Per-unit grid offsets in world units, keyed by the unit node.
## Populated in add_unit(), cleared in remove_unit().
var _unit_offsets: Dictionary = {}

## --- GDScript Lifecycle ---


func _ready():
	debug_timer.timeout.connect(_on_check_timer_timeout)

	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

	reset_units()

	_player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	# Propagate anchor_position for every active unit so states can read it directly.
	for unit in get_all_units():
		var offset: Vector2 = _unit_offsets.get(unit, Vector2.ZERO)
		unit.anchor_position = _player.global_position + offset


func _on_child_entered_tree(child: Node):
	if child is CharacterBody2D:
		add_unit(child)


func _on_child_exiting_tree(child: Node):
	if child is CharacterBody2D:
		remove_unit(child)


func _on_check_timer_timeout():
	var armies_state = { &"Follow": 0, &"Chase": 0, &"Idle": 0, &"Attack": 0 }
	for army in get_children():
		if army is not CharacterBody2D:
			continue

		var army_current_state = army.get_current_state()
		if army_current_state == null:
			continue
		if army_current_state.name not in armies_state:
			armies_state[army_current_state.name] = 1
		else:
			armies_state[army_current_state.name] += 1

	# print(armies_state)


## --- Public API ---


func add_unit(unit: Node) -> bool:
	var index = get_first_empty_slot()

	if index == -1:
		return false

	var grid := _convert_index_to_grid(index)
	var offset := grid * grid_size
	_unit_offsets[unit] = offset

	# Set initial anchor_position immediately so the unit starts at the right spot.
	if _player:
		unit.anchor_position = _player.global_position + offset

	units[index] = unit
	unit_grid_changed.emit()

	return true


func remove_unit(unit: Node) -> bool:
	var index = units.find(unit)

	if index == -1:
		return false

	units[index] = null
	_unit_offsets.erase(unit)
	unit_grid_changed.emit()

	return true


func reset_units():
	units.clear()
	_unit_offsets.clear()

	for i in range(size):
		units.append(null)

	unit_grid_changed.emit()


func get_first_empty_slot() -> int:
	for i in range(size):
		if units[i] == null:
			return i

	return -1


func get_all_units() -> Array[Node]:
	var temp = units.filter(func(unit): return unit != null)
	return temp


func is_grid_full() -> bool:
	return get_first_empty_slot() == -1


## Changes the active formation type and re-assigns grid positions for all
## current units so the formation takes effect immediately.
func set_formation_type(type: FormationType) -> void:
	formation_type = type
	_rebuild_formation()

## --- Private ---


## Re-assigns grid positions for all active units using the current formation_type.
func _rebuild_formation() -> void:
	var all_units := get_all_units()
	for i in range(size):
		units[i] = null
	_unit_offsets.clear()

	for unit in all_units:
		var index := get_first_empty_slot()
		if index == -1:
			break
		var grid := _convert_index_to_grid(index)
		var offset := grid * grid_size
		_unit_offsets[unit] = offset
		if _player:
			unit.anchor_position = _player.global_position + offset
		units[index] = unit

	unit_grid_changed.emit()


func _convert_index_to_grid(index: int) -> Vector2:
	match formation_type:
		FormationType.CIRCULAR:
			return _convert_index_to_circular(index)
		_:
			return _convert_index_to_rectangular(index)


## Rectangular (spiral) formation — original algorithm.
## Positions units in a square spiral expanding outward from the centre.
func _convert_index_to_rectangular(index: int) -> Vector2:
	index += 1
	if index <= 0:
		return Vector2.ZERO

	# Determine ring (layer)
	var k = int(ceil((sqrt(index + 1) - 1) / 2))
	var side_len = 2 * k
	var max_index = (2 * k + 1) * (2 * k + 1) - 1
	var offset = max_index - index

	# Right side (going down)
	if offset < side_len:
		return Vector2(k, -k + offset)

	offset -= side_len
	# Bottom side (going left)
	if offset < side_len:
		return Vector2(k - offset, k)

	offset -= side_len
	# Left side (going up)
	if offset < side_len:
		return Vector2(-k, k - offset)

	offset -= side_len
	# Top side (going right)
	return Vector2(-k + offset, -k)


## Circular (ring-based) formation — new algorithm.
## Places the first unit at the centre, then fills concentric rings of 6·k
## evenly-spaced slots at radius k, expanding outward.
##
## Ring 0: 1 slot  (index 0)
## Ring 1: 6 slots (indices 1-6)
## Ring 2: 12 slots (indices 7-18)
## Ring k: 6·k slots; total through ring k = 1 + 3·k·(k+1)
##
## Returned coordinates are in grid-cell units; multiply by grid_size for
## world-space offsets.
func _convert_index_to_circular(index: int) -> Vector2:
	if index == 0:
		return Vector2.ZERO

	# Find the ring number k (smallest k where total slots through ring k > index).
	# Total T(k) = 1 + 3·k·(k+1).  Solving T(k) > index:
	#   3k² + 3k > index - 1  →  k > (-3 + sqrt(9 + 12·(index-1))) / 6
	var k := int(floor((-3.0 + sqrt(9.0 + 12.0 * float(index - 1))) / 6.0)) + 1

	# First slot index of ring k.
	var ring_start := 1 + 3 * (k - 1) * k
	var pos_in_ring := index - ring_start

	# Evenly distribute within the ring.
	var angle := pos_in_ring * TAU / float(6 * k)
	return Vector2(cos(angle) * k, sin(angle) * k)
