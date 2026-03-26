class_name GroupCursorOverlay
extends Node2D
## World-space overlay that draws a colored cursor at each ArmyGroup's center.
##
## Per group (sorted by group_id, colored red/green/blue/purple):
##   - A hollow square marks the group's current center position.
##   - While _rallying is active: a circle marks the target position and a line
##     connects the square to the circle. Both are removed when rallying ends.

const GROUP_COLORS: Array[Color] = [
	Color(1.0, 0.25, 0.25, 0.9),  # Group 1 — red
	Color(0.2, 1.0, 0.3, 0.9),    # Group 2 — green
	Color(0.25, 0.55, 1.0, 0.9),  # Group 3 — blue
	Color(0.75, 0.2, 1.0, 0.9),   # Group 4 — purple
]

const SQUARE_HALF: float = 5.0
const CIRCLE_RADIUS: float = 8.0

## Seconds between redraws.
@export var update_interval: float = 0.05

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		queue_redraw()


func _draw() -> void:
	var groups := _get_sorted_groups()
	for entry in groups:
		var i: int = entry[0]
		var ag: ArmyGroup = entry[1]
		if ag.get_unit_count() == 0:
			continue
		var color: Color = GROUP_COLORS[i] if i < GROUP_COLORS.size() else Color.WHITE
		var center: Vector2 = ag.global_position

		# Hollow square at group center.
		draw_rect(
			Rect2(center - Vector2(SQUARE_HALF, SQUARE_HALF), Vector2(SQUARE_HALF * 2.0, SQUARE_HALF * 2.0)),
			color, false, 1.5
		)

		# Rally indicator: line to target + circle at target.
		if ag.is_rallying():
			var target: Vector2 = ag.target_position
			draw_line(center, target, color, 1.0)
			draw_arc(target, CIRCLE_RADIUS, 0.0, TAU, 24, color, 1.5)


func _get_sorted_groups() -> Array:
	var nodes: Array = get_tree().get_nodes_in_group("army_group")
	nodes.sort_custom(func(a, b): return a.group_id < b.group_id)
	var result: Array = []
	for i in nodes.size():
		var ag := nodes[i] as ArmyGroup
		if ag != null:
			result.append([i, ag])
	return result
