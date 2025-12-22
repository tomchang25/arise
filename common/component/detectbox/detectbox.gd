@tool
class_name Detectbox
extends Area2D

signal targets_changed(current_targets: Array[Node])

@export var radius: float = 50.0:
    set(value):
        radius = value
        if is_node_ready():
            set_collision_radius(radius)

var collision_shape_2d: CollisionShape2D

var entities_in_range: Array[Node] = []

# --- GDScript Lifecycle ---


func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

    # set_collision_radius(radius)
    _setup_collision_shape()


func _setup_collision_shape() -> void:
    for child in get_children():
        if child is CollisionShape2D:
            collision_shape_2d = child
            break

    set_collision_radius(radius)


# --- Signal Handlers for Array Management ---
func _on_area_entered(body: Node2D) -> void:
    add_node(body)


func _on_area_exited(body: Node2D) -> void:
    remove_node(body)


# --- Utility Functions ---


func set_collision_radius(new_radius: float) -> void:
    if collision_shape_2d and collision_shape_2d.shape:
        var shape_resource = collision_shape_2d.shape
        if shape_resource is CircleShape2D:
            (shape_resource as CircleShape2D).radius = new_radius
        else:
            print_debug("Detectbox requires a CircleShape2D resource to set the radius property.")


func add_node(body: Node2D) -> void:
    if not entities_in_range.has(body):
        entities_in_range.append(body)

        if not body.tree_exited.is_connected(remove_node):
            body.tree_exited.connect(remove_node.bind(body))

        targets_changed.emit(entities_in_range)


func remove_node(body: Node2D) -> void:
    var index = entities_in_range.find(body)
    if index != -1:
        entities_in_range.remove_at(index)
        if body.tree_exited.is_connected(remove_node):
            body.tree_exited.disconnect(remove_node.bind(body))
        targets_changed.emit(entities_in_range)
