class_name Projectile
extends CharacterBody2D

@export_group("Despawn")

## Maximum travel distance before despawning. 0 = disabled.
@export var max_distance: float = 0.0

## How long the projectile stays frozen after hitting a wall before despawning.
@export var wall_hit_freeze_duration: float = 1.0

# -------------------------
# Runtime state
# -------------------------

var speed: float
var direction: Vector2
var attack_effect: AttackEffect

var _origin: Vector2
var _lifetime_timer: float = 0.0
var _frozen: bool = false

# -------------------------
# Lifecycle
# -------------------------


func setup(data: AttackData, new_dir: Vector2, new_speed: float) -> void:
    speed = new_speed
    direction = new_dir.normalized()
    rotate(direction.angle())

    _origin = global_position
    _lifetime_timer = data.attack_lifetime
    max_distance = data.travel_distance  # ← add this

    attack_effect = $ProjectileAttackEffect
    attack_effect.setup(data)


func _physics_process(delta: float) -> void:
    if _frozen:
        return

    # Tick lifetime
    _lifetime_timer -= delta
    if _lifetime_timer <= 0.0:
        queue_free()
        return

    # Distance check
    if max_distance > 0.0 and global_position.distance_to(_origin) >= max_distance:
        queue_free()
        return

    # Move
    velocity = direction * speed
    var collision := move_and_collide(velocity * delta)

    if collision:
        _on_wall_hit()


# -------------------------
# Internal Helpers
# -------------------------


func _on_wall_hit() -> void:
    _frozen = true
    velocity = Vector2.ZERO

    # Disable hitbox immediately so it can't deal damage while frozen.
    if attack_effect and attack_effect.hitbox:
        attack_effect.hitbox.enabled = false

    get_tree().create_timer(wall_hit_freeze_duration).timeout.connect(queue_free)
