@tool
class_name Enemy
extends CharacterBody2D

signal damaged(attack: Attack)

@export var visible_range: float = 100:
    set(value):
        visible_range = value

        if is_node_ready() and enemy_scanner:
            enemy_scanner.visible_range = value
            enemy_scanner.detectbox_radius = value

@export var attack_range: float = 50:
    set(value):
        attack_range = value

        if is_node_ready() and enemy_scanner:
            enemy_scanner.attack_range = value

# @export var max_distance_to_start := 250.0
@export var wander_range := 250

@export var health := 10

@onready var sprite := $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var health_component: Health = $Health
@onready var health_label: Label = $HealthLabel

@onready var wait_timer: Timer = $WaitTimer

@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var enemy_scanner: EnemyScanner = $EnemyScanner
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var attack_handler: BaseAttack = $ProjectileAttack

var start_position: Vector2
var next_position: Vector2


func _ready() -> void:
    enemy_scanner.detectbox_radius = visible_range
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range

    health_component.max_health = health
    health_component.reset()

    hitbox.damaged.connect(_on_damaged)

    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)

    health_label.text = "HP: " + str(health_component.health)

    if start_position == Vector2.ZERO:
        start_position = global_position


func _on_damaged(attack: Attack) -> void:
    damaged.emit(attack)


func _on_health_changed(new_health: float) -> void:
    var overlay_ratio = (1 - (new_health / health_component.max_health)) * 0.5
    sprite.material.set_shader_parameter("overlay_amount", overlay_ratio)
    health_label.text = "HP: " + str(health_component.health)


func _on_health_depleted() -> void:
    queue_free()


## --- Public API ---


func get_distance_to_start() -> float:
    return global_position.distance_to(start_position)


# func is_too_far_from_start() -> bool:
#     return global_position.distance_to(start_position) > max_distance_to_start


func generate_random_wander_position() -> void:
    var random_angle = randf() * TAU
    var random_dist = randf_range(0, wander_range)

    var travel_vector = Vector2.UP.rotated(random_angle) * random_dist
    var candidate_position = start_position + travel_vector

    next_position = candidate_position

    print((next_position - global_position).length(), "   ", (next_position - start_position).length())
