class_name ProjectileAttackDelivery
extends AttackDelivery

## Concrete delivery for straight-line projectile attacks.
##
## Extends AttackDelivery (which owns lifetime and origin_source).
## This class adds straight-line motion and wall collision on top.
##
## Called by ProjectileAttackModule after add_child and position assignment:
##   delivery.setup(data, source)   ← inherited, handles lifetime + effect
##   delivery.launch(dir, speed)    ← sets motion in motion

# -------------------------
# Runtime state
# -------------------------

var _speed: float = 500.0
var _direction: Vector2 = Vector2.RIGHT

# -------------------------
# Setup
# -------------------------


## Injected by ProjectileAttackModule after setup().
func set_speed(speed: float) -> void:
    _speed = speed


## Called by ProjectileAttackModule to set travel direction and kick off movement.
## Direction is taken from data.knockback_dir, which is already baked at fire time.
func launch(direction: Vector2, speed: float) -> void:
    _direction = direction.normalized()
    _speed = speed
    rotation = _direction.angle()


# -------------------------
# Motion
# -------------------------


func _physics_process(delta: float) -> void:
    var collision := move_and_collide(_direction * _speed * delta)
    if collision:
        _on_wall_hit()


# -------------------------
# Wall hit
# -------------------------


func _on_wall_hit() -> void:
    _speed = 0.0

    if _attack_effect and _attack_effect.hitbox:
        _attack_effect.hitbox.enabled = false

    # Hand lifetime over to a short freeze, then despawn.
    set_physics_process(false)
    get_tree().create_timer(0.3).timeout.connect(queue_free)
