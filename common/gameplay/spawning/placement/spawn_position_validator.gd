class_name SpawnPositionValidator
extends RefCounted

var world_2d: World2D

var play_area_rect: Rect2
var use_play_area_rect: bool = false

var arena_center: Vector2 = Vector2.ZERO
var arena_radius: float = 0.0
var use_arena_circle: bool = false

var excluded_center: Vector2 = Vector2.ZERO
var excluded_radius: float = 0.0
var use_excluded_radius: bool = false

var screen_exclusion_rect: Rect2
var use_screen_exclusion_rect: bool = false

var collision_mask: int = 1
var footprint_shape: Shape2D
var footprint_radius: float = 0.0

var collide_with_bodies: bool = true
var collide_with_areas: bool = false


func is_valid(global_position: Vector2) -> bool:
    if not _is_inside_bounds(global_position):
        return false

    if not _is_outside_excluded_radius(global_position):
        return false

    if not _is_outside_screen_exclusion(global_position):
        return false

    if _overlaps_blocking(global_position):
        return false

    return true


func _is_inside_bounds(global_position: Vector2) -> bool:
    if use_play_area_rect and not play_area_rect.has_point(global_position):
        return false

    if use_arena_circle and arena_radius > 0.0:
        if global_position.distance_to(arena_center) > arena_radius:
            return false

    return true


func _is_outside_excluded_radius(global_position: Vector2) -> bool:
    if not use_excluded_radius:
        return true

    return global_position.distance_to(excluded_center) >= excluded_radius


func _is_outside_screen_exclusion(global_position: Vector2) -> bool:
    if not use_screen_exclusion_rect:
        return true

    return not screen_exclusion_rect.has_point(global_position)


func _overlaps_blocking(global_position: Vector2) -> bool:
    if world_2d == null:
        return false

    var shape := _resolve_query_shape()
    if shape == null:
        return false

    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = Transform2D(0.0, global_position)
    query.collision_mask = collision_mask
    query.collide_with_bodies = collide_with_bodies
    query.collide_with_areas = collide_with_areas

    var results := world_2d.direct_space_state.intersect_shape(query, 1)
    return not results.is_empty()


func _resolve_query_shape() -> Shape2D:
    if footprint_shape != null:
        return footprint_shape

    if footprint_radius > 0.0:
        var circle := CircleShape2D.new()
        circle.radius = footprint_radius
        return circle

    return null
