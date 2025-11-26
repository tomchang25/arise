class_name Projectile
extends CharacterBody2D

@export var speed := 150.0
@export var damage := 5.0
@export var max_pierce := 1

var hurtbox: Hurtbox
var current_pierce_count := 0


func _ready():
    for child in get_children():
        if child is Hurtbox:
            hurtbox = child
            continue

    if hurtbox == null:
        push_error("MeleeAttack must have a Hurtbox child")
        return

    hurtbox.hit_enemy.connect(_on_enemy_hit)


func _physics_process(delta: float) -> void:
    var direction = Vector2.RIGHT.rotated(global_rotation)

    velocity = direction * speed

    var collision := move_and_collide(velocity * delta)

    if collision:
        queue_free()


func _on_enemy_hit():
    current_pierce_count += 1

    if current_pierce_count >= max_pierce:
        queue_free()
