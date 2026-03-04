class_name Projectile
extends CharacterBody2D

var speed: float
var direction: Vector2
var attack_effect: AttackEffect


func setup(info: AttackInfo, new_dir: Vector2, new_speed: float) -> void:
    speed = new_speed
    direction = new_dir.normalized()
    rotate(direction.angle())

    attack_effect = $ProjectileAttackEffect
    attack_effect.setup(info)


func _physics_process(delta):
    velocity = direction * speed
    var collision = move_and_collide(velocity * delta)
    if collision:
        queue_free()
        # if collision.get_collider().is_in_group("environment"):
        #     queue_free()
