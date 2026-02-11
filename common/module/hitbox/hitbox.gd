class_name Hitbox
extends Area2D

signal hit_enemy
# signal max_targets_reached

@export var damage_interval: float = 0.0  # 0 = once, > 0 = repeat damage

var interval_timer: Timer

var attack_info: AttackInfo:
    set(value):
        attack_info = value
        if is_inside_tree():
            _setup_collision_layers()

var shape: Shape2D:
    set(value):
        shape = value
        if is_inside_tree():
            _setup_collision_shape()
            
var enabled = true:
    set(value):
        enabled = value
        set_deferred("monitoring", value)
        if interval_timer:
            if value and damage_interval > 0:
                interval_timer.start()
            else:
                interval_timer.stop()


func _ready() -> void:
    area_entered.connect(on_area_entered)
    monitorable = false
    monitoring = enabled

    _setup_collision_shape()
    _setup_damage_interval()
    _setup_collision_layers()


func _setup_collision_shape() -> void:
    # Check if a CollisionShape2D already exists in children
    var has_shape := false
    for child in get_children():
        if child is CollisionShape2D:
            has_shape = true
            break

    # If no shape found but a resource is provided, create it
    if not has_shape and shape:
        var collision_shape = CollisionShape2D.new()
        collision_shape.shape = shape
        add_child(collision_shape)


func _setup_collision_layers() -> void:
    set_collision_layer_value(1, false)
    set_collision_mask_value(1, false)

    collision_mask = 0
    if attack_info:
        for faction in attack_info.target_factions:
            match faction:
                Stats.Faction.PLAYER:
                    set_collision_mask_value(Global.PLAYER_HURTBOX, true)
                Stats.Faction.ENEMY:
                    set_collision_mask_value(Global.ENEMY_HURTBOX, true)


func _setup_damage_interval() -> void:
    if damage_interval > 0:
        interval_timer = Timer.new()
        interval_timer.wait_time = damage_interval
        interval_timer.autostart = enabled
        interval_timer.one_shot = false
        interval_timer.timeout.connect(_on_interval_timeout)
        add_child(interval_timer)


func on_area_entered(area: Area2D) -> void:
    if not enabled:
        return

    # Initial hit when entering
    _apply_hit(area)


func _on_interval_timeout() -> void:
    if not enabled:
        return

    # Pulse damage to everyone currently overlapping
    for area in get_overlapping_areas():
        _apply_hit(area)


func _apply_hit(area: Area2D) -> void:
    if area.has_method("receive_hit"):
        area.receive_hit(attack_info)
        hit_enemy.emit()
