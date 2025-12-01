class_name SoftCollision
extends Area2D

@export var push_force := 100.0
@export var push_distance := 50.0
@export var soft_push_velocity_limit := 30

var target: CharacterBody2D
var soft_push_velocity: Vector2


func _ready():
    if owner is CharacterBody2D:
        target = owner


func _physics_process(_delta: float) -> void:
    var overlap_count = 0
    var total_push_vector = Vector2.ZERO

    var overlapping_areas = get_overlapping_areas()

    for area in overlapping_areas:
        if area is SoftCollision:
            overlap_count += 1

            var push_direction = global_position - area.global_position

            if push_direction == Vector2.ZERO:
                push_direction = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))

            var push_vector = push_direction.normalized()
            total_push_vector += push_vector

    if overlap_count > 0:
        var push_power = push_force * (1.0 - (min(total_push_vector.length(), push_distance) / push_distance))
        soft_push_velocity = total_push_vector.normalized() * push_power
    else:
        soft_push_velocity = lerp(soft_push_velocity, Vector2.ZERO, 1)

    if soft_push_velocity.length() < soft_push_velocity_limit:
        soft_push_velocity = Vector2.ZERO
