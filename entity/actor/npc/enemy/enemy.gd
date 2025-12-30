@tool
class_name Enemy
extends CharacterBody2D

signal damaged(attack: Attack)

@export_category("Scanner")
@export var visible_range: float = 100:
    set(value):
        visible_range = value

        if is_node_ready() and enemy_scanner:
            _setup_enemy_scanner()

@export var attack_range: float = 50:
    set(value):
        attack_range = value

        if is_node_ready() and enemy_scanner:
            _setup_enemy_scanner()

@export_category("Actor Properties")
@export var health := 10

# ------ Core ------
@onready var sprite := $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var health_component: Health = $HealthComponent

# ------ Components ------
@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var attack_handler: BaseAttack = $ProjectileAttack
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var enemy_scanner: EnemyScanner = $EnemyScanner

# ------ Utilities ------
@onready var wait_timer: Timer = $WaitTimer

var leader: Enemy

var start_position: Vector2
var next_position: Vector2


func _ready() -> void:
    _setup_enemy_scanner()

    hitbox.damaged.connect(_on_damaged)

    health_component.max_health = health
    health_component.reset()

    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)

    if start_position == Vector2.ZERO:
        start_position = global_position


func _on_damaged(attack: Attack) -> void:
    print("Enemy damaged by attack: ", attack.damage)
    health_component.health -= attack.damage

    damaged.emit(attack)


func _on_health_changed(new_health: float) -> void:
    var overlay_ratio = (1 - (new_health / health_component.max_health)) * 0.5
    sprite.material.set_shader_parameter("overlay_amount", overlay_ratio)


func _on_health_depleted() -> void:
    queue_free()


func _setup_enemy_scanner() -> void:
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range


## --- Public API ---


func get_distance_to_start() -> float:
    return global_position.distance_to(start_position)


func generate_random_wander_position(wander_range: float = 250) -> void:
    var random_angle = randf() * TAU
    var random_dist = randf_range(0, wander_range)

    var travel_vector = Vector2.UP.rotated(random_angle) * random_dist
    var candidate_position = start_position + travel_vector

    next_position = candidate_position
