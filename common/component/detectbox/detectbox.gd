class_name Detectbox
extends Area2D

signal detected(nodes_in_range: Array)
signal last_node_left

@export var scan_interval: float = 0.2

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


# --- Signal Handlers for Array Management ---
func _on_area_entered(body: Node2D) -> void:
    if not entities_in_range.has(body):
        entities_in_range.append(body)


func _on_area_exited(body: Node2D) -> void:
    var index = entities_in_range.find(body)
    if index != -1:
        entities_in_range.remove_at(index)

        if entities_in_range.is_empty():
            last_node_left.emit()


# --- Periodic Scan Logic ---
func _on_scan_timer_timeout() -> void:
    var removed_count = 0

    # Iterate in reverse to safely remove elements
    for i in range(entities_in_range.size() - 1, -1, -1):
        var entity = entities_in_range[i]

        if not is_instance_valid(entity):
            entities_in_range.remove_at(i)
            removed_count += 1

    if not entities_in_range.is_empty():
        detected.emit(entities_in_range)

    # Check if the array became empty due to invalid instances
    if removed_count > 0 and entities_in_range.is_empty():
        last_node_left.emit()

    # print("--- Scan complete. Emitting array of " + str(entities_in_range.size()) + " entities. ---")
