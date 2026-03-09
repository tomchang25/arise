@tool
class_name PathfindingTestDummy
extends CharacterBody2D

@export var movement: MovementModule
@export var pathfinding: PathfindingModule
@export var sprite: Node2D

@export_group("Debug")
@export var enable_path_debug := true
@export var face_by_velocity := true

var _spawn_pos := Vector2.ZERO


func _ready() -> void:
    _spawn_pos = global_position
    _auto_wire()

    if movement:
        movement.character = self

    if pathfinding:
        pathfinding.character = self
        pathfinding.movement = movement
        pathfinding.debug_draw = enable_path_debug


func _enter_tree() -> void:
    _auto_wire()
    if movement:
        movement.character = self

    if pathfinding:
        pathfinding.character = self
        pathfinding.movement = movement


func _auto_wire() -> void:
    if not movement:
        movement = find_child("MovementModule", true, false) as MovementModule
    if not pathfinding:
        pathfinding = find_child("PathfindingModule", true, false) as PathfindingModule
    if not sprite:
        sprite = find_child("Sprite2D", true, false) as Node2D


func _physics_process(_delta: float) -> void:
    if face_by_velocity and sprite and velocity.length() > 0.1:
        sprite.rotation = velocity.angle()


func move_to(world_position: Vector2, speed: float = -1.0, arrive_dist: float = -1.0) -> void:
    if not pathfinding:
        return

    if speed >= 0.0:
        pathfinding.set_speed(speed)
    if arrive_dist >= 0.0:
        pathfinding.set_arrive_distance(arrive_dist)

    pathfinding.set_target_position(world_position)


func follow_node(target: Node2D, speed: float = -1.0, arrive_dist: float = -1.0) -> void:
    if not pathfinding:
        return

    if speed >= 0.0:
        pathfinding.set_speed(speed)
    if arrive_dist >= 0.0:
        pathfinding.set_arrive_distance(arrive_dist)

    pathfinding.follow_target_node(target)


func stop_pathing() -> void:
    if pathfinding:
        pathfinding.stop()

    if movement:
        movement.stop_all_motion()


func reset_dummy() -> void:
    global_position = _spawn_pos
    stop_pathing()


func set_avoidance_enabled(value: bool) -> void:
    if pathfinding:
        pathfinding.set_avoidance_enabled(value)


func set_avoidance_priority(value: float) -> void:
    if pathfinding:
        pathfinding.set_avoidance_priority(value)
