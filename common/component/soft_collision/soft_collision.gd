class_name SoftCollision
extends Area2D

@export var enabled := true
@export var push_force := 100.0
@export var push_distance := 20.0
@export var soft_push_velocity_min := 1

@export var overlapping_max_count = 10
var overlapping_areas_set = {}

var soft_push_velocity: Vector2


func _ready():
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D):
    if overlapping_areas_set.size() >= overlapping_max_count:
        return

    if area is SoftCollision:
        overlapping_areas_set[area] = true


func _on_area_exited(area: Area2D):
    if not overlapping_areas_set.has(area):
        return

    if area is SoftCollision:
        overlapping_areas_set.erase(area)


func _physics_process(_delta: float) -> void:
    if not enabled:
        return

    var total_push_vector = Vector2.ZERO

    for area in overlapping_areas_set.keys():
        if area is SoftCollision:
            var push_direction = global_position - area.global_position
            var distance = push_direction.length()

            if distance <= 1.0:
                push_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
                distance = push_direction.length()

            var overlap_amount = max(0.0, push_distance - distance)

            var push_magnitude = overlap_amount / (distance*distance)

            var push_vector = push_direction.normalized() * push_magnitude
            total_push_vector += push_vector

    if overlapping_areas_set.size() > 0:
        # soft_push_velocity = total_push_vector.normalized() * push_force
        var push_power = push_force * (1.0 - (min(total_push_vector.length(), push_distance) / push_distance))
        soft_push_velocity = total_push_vector.normalized() * push_power
    else:
        soft_push_velocity = lerp(soft_push_velocity, Vector2.ZERO, 1)

    if soft_push_velocity.length() < soft_push_velocity_min:
        soft_push_velocity = Vector2.ZERO
