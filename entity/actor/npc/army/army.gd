@tool
class_name Army
extends CharacterBody2D

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

# ------ Components ------
@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var attack_handler: ProjectileAttack = $ProjectileAttack
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var enemy_scanner: EnemyScanner = $EnemyScanner

# ------ Properties ------

# var enemies_in_range: Array = []:
#     get:
#         return enemies_in_range.filter(func(area): return is_instance_valid(area))

var player: Player
var grid_position: Vector2 = Vector2.ZERO

## --- GDScript Lifecycle ---


func _ready() -> void:
    _setup_enemy_scanner()

    player = get_tree().get_first_node_in_group("player")


func _setup_enemy_scanner() -> void:
    enemy_scanner.detectbox_radius = visible_range
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range


func _physics_process(_delta: float) -> void:
    move_and_slide()


## --- Public API ---


func get_distance_to_player() -> float:
    var start_point = player.global_position + grid_position

    return start_point.distance_to(self.global_position)


func get_current_state() -> ArmyState:
    return $ArmyStateMachine.current_state


func update_grid_position() -> void:
    var new_position = player.global_position + grid_position

    set_target_position(new_position)


func set_target_position(new_position: Vector2) -> void:
    pathfinding.set_target_position(new_position)

## --- Private ---
