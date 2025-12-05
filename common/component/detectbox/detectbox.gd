@tool
class_name Detectbox
extends Area2D

signal detected(nodes_in_range: Array)
# signal last_node_left

@export var scan_interval: float = 0.2
@export var radius: float = 50.0:  # NEW CODE: Exported radius variable
    set(value):
        radius = value
        if is_node_ready():
            set_collision_radius(radius)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var scan_timer: Timer

var entities_in_range: Array[Node] = []


func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

    scan_timer = Timer.new()
    scan_timer.wait_time = scan_interval
    scan_timer.autostart = true
    scan_timer.one_shot = false
    scan_timer.timeout.connect(_on_scan_timer_timeout)
    add_child(scan_timer)

    set_collision_radius(radius)


func set_collision_radius(new_radius: float) -> void:
    if collision_shape_2d and collision_shape_2d.shape:
        var shape_resource = collision_shape_2d.shape
        if shape_resource is CircleShape2D:
            (shape_resource as CircleShape2D).radius = new_radius
        else:
            print_debug("Detectbox requires a CircleShape2D resource to set the radius property.")


# --- Signal Handlers for Array Management ---
func _on_area_entered(body: Node2D) -> void:
    if scan_timer.is_stopped():
        scan_timer.start()

    if not entities_in_range.has(body):
        entities_in_range.append(body)


func _on_area_exited(body: Node2D) -> void:
    var index = entities_in_range.find(body)
    if index != -1:
        entities_in_range.remove_at(index)

        if entities_in_range.is_empty():
            detected.emit([])
            scan_timer.stop()


# --- Periodic Scan Logic ---
func _on_scan_timer_timeout() -> void:
    # Iterate in reverse to safely remove elements
    for i in range(entities_in_range.size() - 1, -1, -1):
        var entity = entities_in_range[i]

        if not is_instance_valid(entity):
            entities_in_range.remove_at(i)

    detected.emit(entities_in_range)

    if entities_in_range.is_empty():
        scan_timer.stop()
