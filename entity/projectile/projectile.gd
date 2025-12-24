class_name Projectile
extends CharacterBody2D

@export var speed := 150.0
@export var damage := 5.0:
    set(value):
        damage = value

        if is_node_ready() and hurtbox:
            hurtbox.attack_data.base_damage = value

@export var max_pierce := 1:
    set(value):
        max_pierce = value

@export var max_distance := 200.0

var hurtbox: Hurtbox
var current_pierce_count := 0
var distance_traveled := 0.0


func _ready():
    for child in get_children():
        if child is Hurtbox:
            hurtbox = child
            continue

    if hurtbox == null:
        push_error("MeleeAttack must have a Hurtbox child")
        return

    hurtbox.attack_data.base_damage = damage
    hurtbox.hit_enemy.connect(_on_enemy_hit)


func _physics_process(delta: float) -> void:
    var direction = Vector2.RIGHT.rotated(global_rotation)
    var motion = direction * speed * delta
    velocity = direction * speed

    var collision := move_and_collide(velocity * delta)
    if collision:
        queue_free()
        return

    distance_traveled += motion.length()
    if distance_traveled >= max_distance:
        queue_free()
        return


func _on_enemy_hit():
    current_pierce_count += 1

    if current_pierce_count >= max_pierce:
        queue_free()
