class_name ProjectileAttack
extends Node2D

@export var projectile_scene: PackedScene

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


func attack(target_position: Vector2):
    if locked:
        return

    targets_hit_count = 0

    locked = true

    var spawned_projectile: Projectile = projectile_scene.instantiate()
    get_tree().root.add_child(spawned_projectile)

    spawned_projectile.global_position = global_position

    var aim_direction := target_position - global_position
    spawned_projectile.rotation = aim_direction.angle()

    cooldown_timer.start()


func can_attack() -> bool:
    return not locked


func _on_cooldown_timer_timeout():
    locked = false
