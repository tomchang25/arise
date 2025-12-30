@tool
class_name Army
extends CharacterBody2D

signal damaged(attack: Attack)

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

@export var health := 10

# ------ Core ------
@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var health_component: Health = $HealthComponent

# ------ Common Components ------
@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var attack_handler: BaseAttack = $ProjectileAttack
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var enemy_scanner: EnemyScanner = $EnemyScanner

# ------ State Machine ------
var state_machine: StateMachine

# ------ Properties ------

var player: Player
var grid_position: Vector2 = Vector2.ZERO

## --- GDScript Lifecycle ---


func _ready() -> void:
    _setup_enemy_scanner()
    _setup_health_component()
    _setup_hitbox()
    _setup_state_machine()

    player = get_tree().get_first_node_in_group("player")


func _setup_enemy_scanner() -> void:
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range


func _setup_health_component() -> void:
    health_component.max_health = health
    health_component.health = health
    health_component.reset()

    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)


func _setup_hitbox() -> void:
    hitbox.damaged.connect(_on_damaged)


func _setup_state_machine() -> void:
    for child in get_children():
        if child is StateMachine:
            state_machine = child
            return

    push_error("Actor must have a StateMachine child")


func _on_damaged(_attack: Attack) -> void:
    pass


func _on_health_changed(_new_health: float) -> void:
    pass


func _on_health_depleted() -> void:
    pass


## --- Public API ---


func get_distance_to_player() -> float:
    var start_point = player.global_position + grid_position

    return start_point.distance_to(self.global_position)


func get_current_state() -> ArmyState:
    return state_machine.current_state


func update_grid_position() -> void:
    var new_position = player.global_position + grid_position

    pathfinding.set_target_position(new_position)

## --- Private ---
