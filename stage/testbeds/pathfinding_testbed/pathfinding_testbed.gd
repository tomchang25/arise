@tool
extends Node2D

const KEY_STOP := KEY_O
const KEY_RESET := KEY_R
const KEY_FOLLOW := KEY_F
const KEY_MOVE := KEY_G
const KEY_GATHER := KEY_H

@export var dummies_root: Node
@export var dummies: Array[PathfindingTestDummy] = []
@export var moving_target: Node2D

@export_group("Move Settings")
@export var move_speed := 120.0
@export var arrive_distance := 8.0

@export_group("Group Test")
@export var auto_collect_from_group := true
@export var dummy_group_name := "dummies"
@export var use_destination_offsets := true
@export var destination_offset_radius := 36.0
@export var maintain_formation_from_center := false

@export_group("Moving Target")
@export var auto_move_target := true
@export var target_move_radius := 180.0
@export var target_move_speed := 1.0

var _target_center := Vector2.ZERO
var _time := 0.0
var _spawn_positions: Dictionary = {}


func _ready() -> void:
    _collect_dummies()

    if moving_target:
        _target_center = moving_target.global_position

    _cache_spawn_positions()


func _process(delta: float) -> void:
    _time += delta

    if auto_move_target and moving_target:
        var offset := Vector2.RIGHT.rotated(_time * target_move_speed) * target_move_radius
        moving_target.global_position = _target_center + offset

    if Input.is_key_pressed(KEY_MOVE):
        _command_move_group(get_global_mouse_position())

    if Input.is_key_pressed(KEY_FOLLOW):
        _command_follow_group()

    if Input.is_key_pressed(KEY_STOP):
        _command_stop_group()

    if Input.is_key_pressed(KEY_RESET):
        _command_reset_group()

    if Input.is_key_pressed(KEY_GATHER):
        _command_gather_to_center()


func _collect_dummies() -> void:
    dummies.clear()

    if dummies_root:
        _collect_dummies_from_node(dummies_root)

    if auto_collect_from_group:
        for node in get_tree().get_nodes_in_group(dummy_group_name):
            if node is PathfindingTestDummy and not dummies.has(node):
                dummies.append(node)

    # fallback: find any child dummy under this testbed
    if dummies.is_empty():
        _collect_dummies_from_node(self)


func _collect_dummies_from_node(root: Node) -> void:
    if root == null:
        return

    for child in root.get_children():
        if child is PathfindingTestDummy and not dummies.has(child):
            dummies.append(child)

        _collect_dummies_from_node(child)


func _cache_spawn_positions() -> void:
    _spawn_positions.clear()

    for dummy in dummies:
        if is_instance_valid(dummy):
            _spawn_positions[dummy] = dummy.global_position


func _command_move_group(world_position: Vector2) -> void:
    if dummies.is_empty():
        return

    if maintain_formation_from_center:
        _command_move_group_keep_relative(world_position)
        return

    var count := dummies.size()
    for i in range(count):
        var dummy := dummies[i]
        if not is_instance_valid(dummy):
            continue

        var target_pos := world_position

        if use_destination_offsets:
            target_pos += _get_ring_offset(i, count, destination_offset_radius)

        dummy.move_to(target_pos, move_speed, arrive_distance)


func _command_move_group_keep_relative(world_position: Vector2) -> void:
    if dummies.is_empty():
        return

    var center := _get_group_center()
    var delta := world_position - center

    for dummy in dummies:
        if not is_instance_valid(dummy):
            continue

        dummy.move_to(dummy.global_position + delta, move_speed, arrive_distance)


func _command_follow_group() -> void:
    if moving_target == null:
        return

    var count := dummies.size()
    for i in range(count):
        var dummy := dummies[i]
        if not is_instance_valid(dummy):
            continue

        if use_destination_offsets:
            var target_pos := moving_target.global_position + _get_ring_offset(i, count, destination_offset_radius)
            dummy.move_to(target_pos, move_speed, arrive_distance)
        else:
            dummy.follow_node(moving_target, move_speed, arrive_distance)


func _command_stop_group() -> void:
    for dummy in dummies:
        if is_instance_valid(dummy):
            dummy.stop_pathing()


func _command_reset_group() -> void:
    for dummy in dummies:
        if not is_instance_valid(dummy):
            continue

        if _spawn_positions.has(dummy):
            dummy.global_position = _spawn_positions[dummy]
        else:
            dummy.reset_dummy()

        dummy.stop_pathing()

    if moving_target:
        moving_target.global_position = _target_center


func _command_gather_to_center() -> void:
    var center := _get_group_center()
    _command_move_group(center)


func _get_group_center() -> Vector2:
    var total := Vector2.ZERO
    var count := 0

    for dummy in dummies:
        if not is_instance_valid(dummy):
            continue
        total += dummy.global_position
        count += 1

    if count <= 0:
        return global_position

    return total / float(count)


func _get_ring_offset(index: int, count: int, radius: float) -> Vector2:
    if count <= 1:
        return Vector2.ZERO

    var angle := TAU * float(index) / float(count)
    return Vector2.RIGHT.rotated(angle) * radius
