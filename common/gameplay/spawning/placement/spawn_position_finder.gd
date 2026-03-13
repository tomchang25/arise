class_name SpawnPositionFinder
extends RefCounted


static func find_position_in_radius(
    center: Vector2, radius: float, validator: SpawnPositionValidator, rng: RandomNumberGenerator = null, max_attempts: int = 24
) -> Variant:
    if radius <= 0.0:
        if validator == null or validator.is_valid(center):
            return center
        return null

    for _i in range(max_attempts):
        var candidate := SpatialRandomUtils.random_point_in_circle(center, radius, rng)
        if validator == null or validator.is_valid(candidate):
            return candidate

    return null


static func find_position_in_annulus(
    center: Vector2, min_radius: float, max_radius: float, validator: SpawnPositionValidator, rng: RandomNumberGenerator = null, max_attempts: int = 24
) -> Variant:
    if max_radius < min_radius:
        var temp := min_radius
        min_radius = max_radius
        max_radius = temp

    min_radius = maxf(0.0, min_radius)
    max_radius = maxf(0.0, max_radius)

    if max_radius <= 0.0:
        if validator == null or validator.is_valid(center):
            return center
        return null

    for _i in range(max_attempts):
        var candidate := SpatialRandomUtils.random_point_in_annulus(center, min_radius, max_radius, rng)

        if validator == null or validator.is_valid(candidate):
            return candidate

    return null
