@tool
class_name DetectionModule
extends Area2D

signal target_entered(target: Node2D)
signal target_exited(target: Node2D)
signal targets_changed(targets: Array[Node2D])

@export var enabled: bool = true:
    set = set_enabled

@export var obstacle_mask: int = 4

@export var radius: float = 100.0:
    set(value):
        radius = max(value, 0.0)
        if is_node_ready():
            _setup_collision_shape()
            _set_collision_radius(radius)

var _enabled: bool = true

var _collision_shape: CollisionShape2D
var _entities_in_range: Array[Node2D] = []


func _init() -> void:
    monitorable = false


func _ready() -> void:
    _setup_collision_shape()
    _set_collision_radius(radius)

    if not area_entered.is_connected(_on_area_entered):
        area_entered.connect(_on_area_entered)
    if not area_exited.is_connected(_on_area_exited):
        area_exited.connect(_on_area_exited)


func _setup_collision_shape() -> void:
    if _collision_shape:
        return

    for child in get_children():
        if child is CollisionShape2D:
            _collision_shape = child
            break

    if not _collision_shape:
        _collision_shape = CollisionShape2D.new()
        add_child(_collision_shape)

    if not _collision_shape.shape:
        _collision_shape.shape = CircleShape2D.new()
    elif not _collision_shape.shape.is_local_to_scene():
        _collision_shape.shape = _collision_shape.shape.duplicate()


func _set_collision_radius(new_radius: float) -> void:
    if not _collision_shape:
        return

    if not (_collision_shape.shape is CircleShape2D):
        push_warning("DetectionModule requires CircleShape2D for radius editing.")
        return

    (_collision_shape.shape as CircleShape2D).radius = new_radius


func reset() -> void:
    _enabled = true
    _entities_in_range.clear()
    set_monitoring(true)


func set_enabled(value: bool) -> void:
    _enabled = value
    set_monitoring(value)
    if not value:
        _entities_in_range.clear()


func is_enabled() -> bool:
    return _enabled


func set_collision_radius(new_radius: float) -> void:
    radius = new_radius


func contains_entity(entity: Node2D) -> bool:
    return _entities_in_range.has(entity)


func get_targets(must_be_visible: bool = false) -> Array[Node2D]:
    var targets: Array[Node2D] = []

    for entity in _entities_in_range:
        if not is_instance_valid(entity):
            continue
        if must_be_visible and not _has_line_of_sight(entity):
            continue
        targets.append(entity)

    if must_be_visible:
        push_warning("DetectionModule: Raycasts are pretty heavy, only use when needed.")

    return targets


func get_target_count(must_be_visible: bool = false) -> int:
    return get_targets(must_be_visible).size()


func can_see_entity(entity: Node2D) -> bool:
    if not contains_entity(entity) or not is_instance_valid(entity):
        return false
    return _has_line_of_sight(entity)


func get_closest_target(must_be_visible: bool = false) -> Node2D:
    var targets := get_targets(must_be_visible)
    if targets.is_empty():
        return null

    var closest_target: Node2D = null
    var min_dist_sq := INF

    for target in targets:
        var dist_sq := global_position.distance_squared_to(target.global_position)
        if dist_sq < min_dist_sq:
            min_dist_sq = dist_sq
            closest_target = target

    return closest_target


func _on_area_entered(area: Area2D) -> void:
    if not area is Hurtbox:
        return

    var entity := area.owner as Node2D
    if not entity or entity == owner:
        return

    if _entities_in_range.has(entity):
        return

    _entities_in_range.append(entity)

    var exit_callable := Callable(self, "_on_entity_tree_exited").bind(entity)
    if not entity.tree_exited.is_connected(exit_callable):
        entity.tree_exited.connect(exit_callable)

    target_entered.emit(entity)
    targets_changed.emit(get_targets(false))


func _on_area_exited(area: Area2D) -> void:
    if not area is Hurtbox:
        return

    var entity := area.owner as Node2D
    if not entity:
        return

    _remove_entity(entity)


func _on_entity_tree_exited(entity: Node2D) -> void:
    _remove_entity(entity)


func _remove_entity(entity: Node2D) -> void:
    if not _entities_in_range.has(entity):
        return

    _entities_in_range.erase(entity)

    if is_instance_valid(entity):
        var exit_callable := Callable(self, "_on_entity_tree_exited").bind(entity)
        if entity.tree_exited.is_connected(exit_callable):
            entity.tree_exited.disconnect(exit_callable)

    target_exited.emit(entity)
    targets_changed.emit(get_targets(false))


func _has_line_of_sight(target: Node2D) -> bool:
    if not is_instance_valid(target):
        return false

    var space_state := get_world_2d().direct_space_state
    var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, obstacle_mask, [get_rid(), owner.get_rid(), target.get_rid()])

    var result := space_state.intersect_ray(query)
    return result.is_empty()
