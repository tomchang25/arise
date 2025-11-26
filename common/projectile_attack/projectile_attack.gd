class_name ProjectileAttack
extends Node2D

@export var bullet_scene: PackedScene

@export var attack_cooldown: float = 0.5
@export var max_targets: int = 1

var cooldown_timer: Timer

var locked := false
var targets_hit_count: int = 0


func _ready():
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true
    cooldown_timer.autostart = false
    cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
    add_child(cooldown_timer)


func aim_at(global: Vector2):
    var direction_vector: Vector2 = (self.global_position - global).normalized()
    var angle: float = direction_vector.angle()
    self.global_rotation = angle


func start_attack():
    if locked:
        return

    targets_hit_count = 0

    locked = true


func end_attack():
    cooldown_timer.start()


func can_attack() -> bool:
    return not locked


# func _on_enemy_hit():
#     targets_hit_count += 1

#     if targets_hit_count >= max_targets:
#         hurtbox.enabled = false


func _on_cooldown_timer_timeout():
    locked = false
