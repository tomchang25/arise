@tool
class_name DetectionModule
extends Area2D

## --- Configuration ---
@export var obstacle_mask: int = 4  # Walls/Static obstacles

## --- Internal State ---
var _entities_in_range: Array[Node2D] = []

## --- Public API ---


## Adds the ability to update range from the Enemy script
func set_collision_radius(radius: float) -> void:
    for child in get_children():
        if child is CollisionShape2D:
            if child.shape is CircleShape2D:
                # Duplicate to ensure we don't change other enemies' ranges
                if not child.shape.is_local_to_scene():
                    child.shape = child.shape.duplicate()
                child.shape.radius = radius
            break


## Returns true if a specific entity is within this physical range
func contains_entity(entity: Node2D) -> bool:
    return _entities_in_range.has(entity)


## Returns true if the entity is in range AND not behind a wall
func can_see_entity(entity: Node2D) -> bool:
    if not contains_entity(entity) or not is_instance_valid(entity):
        return false
    return _has_line_of_sight(entity)


## Returns the closest entity, optionally checking line-of-sight
func get_closest_target(must_be_visible: bool = false) -> Node2D:
    var targets = _entities_in_range.filter(func(e): return is_instance_valid(e))

    if must_be_visible:
        targets = targets.filter(func(e): return _has_line_of_sight(e))

    if targets.is_empty():
        return null

    var closest_target: Node2D = null
    var min_dist = INF  # Initialize with infinity

    for target in targets:
        var dist_sq = global_position.distance_squared_to(target.global_position)
        if dist_sq < min_dist:
            min_dist = dist_sq
            closest_target = target

    return closest_target


## Returns the count of entities currently inside
func get_target_count(must_be_visible: bool = false) -> int:
    var targets = _entities_in_range.filter(func(e): return is_instance_valid(e))

    if must_be_visible:
        targets = targets.filter(func(e): return _has_line_of_sight(e))

    return targets.size()


## --- Internal Logic ---


func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox:
        var entity = area.owner
        if entity and entity != owner and not _entities_in_range.has(entity):
            _entities_in_range.append(entity)
            if not entity.tree_exited.is_connected(_on_entity_freed):
                entity.tree_exited.connect(_on_entity_freed.bind(entity))


func _on_area_exited(area: Area2D) -> void:
    if area is Hurtbox:
        _on_entity_freed(area.owner)


func _on_entity_freed(entity: Node2D) -> void:
    if _entities_in_range.has(entity):
        _entities_in_range.erase(entity)
        if entity.tree_exited.is_connected(_on_entity_freed):
            entity.tree_exited.disconnect(_on_entity_freed.bind(entity))


func _has_line_of_sight(target: Node2D) -> bool:
    var space_state = get_world_2d().direct_space_state
    # var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position, obstacle_mask, [get_rid(), owner.get_rid()])
    var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position, obstacle_mask, [get_rid(), owner.get_rid(), target.get_rid()])
    var result = space_state.intersect_ray(query)

    # if not result.is_empty():
    #     print(result)

    return result.is_empty()
