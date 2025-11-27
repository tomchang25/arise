class_name MeleeAttack
extends Node2D

@export var attack_cooldown: float = 0.5
@export var max_targets: int = 1

var hurtbox: Hurtbox
var cooldown_timer: Timer

var locked := false
var targets_hit_count: int = 0


func _ready():
    for child in get_children():
        if child is Hurtbox:
            hurtbox = child
            continue

    if hurtbox == null:
        push_error("MeleeAttack must have a Hurtbox child")
        return

    hurtbox.hit_enemy.connect(_on_enemy_hit)

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
    hurtbox.enabled = true


func end_attack():
    hurtbox.enabled = false
    cooldown_timer.start()


func can_attack() -> bool:
    return not locked


func _on_enemy_hit():
    targets_hit_count += 1

    if targets_hit_count >= max_targets:
        hurtbox.enabled = false


func _on_cooldown_timer_timeout():
    locked = false
