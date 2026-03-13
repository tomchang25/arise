class_name DamageNumberModule
extends Node

@export var damage_receiver: DamageReceiverModule
@export var damage_number_scene: PackedScene

@export_group("Spawn Target")
@export var spawn_root_path: NodePath
@export var world_anchor_path: NodePath
@export var height_offset: float = 18.0
@export var random_x_offset: float = 8.0

@export_group("Filtering")
@export var minimum_damage_to_show: float = 1.0
@export var show_zero_damage: bool = false

@export_group("Simple Throttling")
@export var enabled_throttle := true
@export var max_spawns_per_frame := 6
@export var max_active_numbers := 40

var _spawned_this_frame: int = 0
var _last_spawn_frame: int = -1


func _ready() -> void:
    if damage_receiver == null:
        damage_receiver = owner.find_child("DamageReceiverModule", true, false) as DamageReceiverModule

    if damage_number_scene == null:
        push_warning("DamageNumberModule: damage_number_scene is not assigned.")

    if damage_receiver and not damage_receiver.damaged.is_connected(_on_damaged):
        damage_receiver.damaged.connect(_on_damaged)


func _on_damaged(amount: float, _new_health: float, info: AttackInfo) -> void:
    if not _should_show(amount):
        return

    if enabled_throttle and not _can_spawn_now():
        return

    spawn_damage_number(amount, info)


func spawn_damage_number(amount: float, info: AttackInfo = null) -> void:
    if damage_number_scene == null:
        return

    var root := _get_spawn_root()
    if root == null:
        return

    var number := damage_number_scene.instantiate() as DamageNumber
    if number == null:
        push_warning("DamageNumberModule: damage_number_scene must instantiate a DamageNumber.")
        return

    root.add_child(number)
    number.global_position = _get_spawn_position()

    number.setup(amount, info.is_crit)

    _register_spawn()


func _should_show(amount: float) -> bool:
    if show_zero_damage and amount <= 0.0:
        return true
    return amount >= minimum_damage_to_show


func _can_spawn_now() -> bool:
    var current_frame := Engine.get_process_frames()
    if current_frame != _last_spawn_frame:
        _last_spawn_frame = current_frame
        _spawned_this_frame = 0

    if _spawned_this_frame >= max_spawns_per_frame:
        return false

    var root := _get_spawn_root()
    if root and root.get_child_count() >= max_active_numbers:
        return false

    return true


func _register_spawn() -> void:
    var current_frame := Engine.get_process_frames()
    if current_frame != _last_spawn_frame:
        _last_spawn_frame = current_frame
        _spawned_this_frame = 0

    _spawned_this_frame += 1


func _get_spawn_root() -> Node:
    if spawn_root_path != NodePath():
        var custom_root := get_node_or_null(spawn_root_path)
        if custom_root:
            return custom_root

    var tree := get_tree()
    if tree == null:
        return null

    return tree.current_scene


func _get_spawn_position() -> Vector2:
    var anchor := _get_world_anchor()
    if anchor:
        return anchor.global_position + Vector2(randf_range(-random_x_offset, random_x_offset), -height_offset)

    if owner is Node2D:
        var owner_2d := owner as Node2D
        return owner_2d.global_position + Vector2(randf_range(-random_x_offset, random_x_offset), -height_offset)

    return Vector2.ZERO


func _get_world_anchor() -> Node2D:
    if world_anchor_path != NodePath():
        var custom_anchor := get_node_or_null(world_anchor_path) as Node2D
        if custom_anchor:
            return custom_anchor

    if owner == null:
        return null

    var visuals := owner.get_node_or_null(^"Visuals") as Node2D
    if visuals:
        return visuals

    return owner as Node2D
