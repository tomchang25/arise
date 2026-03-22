@tool
class_name SoftCollision
extends Area2D

## Soft collision/separation module that prevents CharacterBody2D nodes from
## overlapping by injecting a distance-based separation force into their
## MovementModule.knockback_velocity each physics frame.
##
## Default configurations by entity type:
##   player  → ignored_pushers = ["armies"]
##   army    → ignored_pushers = []
##   enemy   → ignored_pushers = []

@export var character: CharacterBody2D
@export var movement_module: MovementModule

@export_group("Separation")
## Divides the received separation force. Higher mass = harder to push.
@export var mass: float = 1.0
## Base separation force applied at distance 0 between two bodies.
@export var separation_force: float = 200.0
## Maximum distance at which force is applied. Also sets the detection radius.
@export var min_distance: float = 30.0:
	set(value):
		min_distance = max(value, 0.0)
		if is_node_ready():
			_update_shape_radius()
## Maximum number of overlapping neighbours processed per physics frame.
@export var max_neighbours: int = 10

@export_group("Filtering")
## Bodies belonging to any of these groups are ignored and will not push this body.
@export var ignored_pushers: Array[StringName] = []

var _collision_shape: CollisionShape2D

# -------------------------
# Lifecycle
# -------------------------


func _init() -> void:
	monitorable = false


func _ready() -> void:
	_setup_collision_shape()
	_update_shape_radius()


func _physics_process(_delta: float) -> void:
	if movement_module == null or character == null:
		return

	var bodies := get_overlapping_bodies()
	var count := 0

	for body in bodies:
		if count >= max_neighbours:
			break

		if not body is CharacterBody2D:
			continue

		if body == character:
			continue

		var skip := false
		for group in ignored_pushers:
			if body.is_in_group(group):
				skip = true
				break
		if skip:
			continue

		var diff: Vector2 = character.global_position - body.global_position
		var dist: float = diff.length()

		if dist >= min_distance:
			count += 1
			continue

		var direction: Vector2
		if dist > 0.0:
			direction = diff / dist
		else:
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

		var force: float = separation_force * (1.0 - dist / min_distance) / mass
		movement_module.knockback_velocity += direction * force
		count += 1

# -------------------------
# Internal Helpers
# -------------------------


func _setup_collision_shape() -> void:
	if _collision_shape:
		return

	for child in get_children():
		if child is CollisionShape2D:
			_collision_shape = child
			return

	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	add_child(_collision_shape)


func _update_shape_radius() -> void:
	if not _collision_shape:
		return
	if not (_collision_shape.shape is CircleShape2D):
		return
	(_collision_shape.shape as CircleShape2D).radius = min_distance
