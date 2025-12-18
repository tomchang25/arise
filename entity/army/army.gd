@tool
class_name Army
extends CharacterBody2D

@export var attack_range: float = 50:
    set(value):
        attack_range = value

        if is_node_ready() and attack_handler:
            attack_handler.attack_range = value

@export var enemy_check_range: float = 100:
    set(value):
        enemy_check_range = value

        if is_node_ready() and enemy_check_detectbox:
            enemy_check_detectbox.range = value

# ------ Components ------
@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var attack_handler: ProjectileAttack = $ProjectileAttack
@onready var enemy_check_detectbox: Detectbox = $EnemyCheckDetectbox
@onready var pathfinding: Pathfinding = $Pathfinding

# ------ Properties ------

var enemies_in_range: Array = []:
    get:
        return enemies_in_range.filter(func(area): return is_instance_valid(area))

var player: Player
var grid_position: Vector2 = Vector2.ZERO

## --- GDScript Lifecycle ---


func _ready() -> void:
    attack_handler.attack_range = attack_range
    enemy_check_detectbox.radius = enemy_check_range

    enemy_check_detectbox.detected.connect(_on_enemies_detected)

    player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
    move_and_slide()


func _on_enemies_detected(nodes_in_range: Array) -> void:
    enemies_in_range = nodes_in_range.filter(func(node): return node.get_owner() is Enemy)


## --- Public API ---


func is_enemy_visible() -> bool:
    return enemies_in_range.size() > 0


func is_enemy_attackable() -> bool:
    for enemy in enemies_in_range:
        if attack_handler.is_in_range(enemy.global_position):
            return true

    return false


func get_distance_to_player() -> float:
    var start_point = player.global_position + grid_position

    return start_point.distance_to(self.global_position)


func get_nearest_enemy() -> Node2D:
    var nearest_enemy: Node2D = null

    for enemy in enemies_in_range:
        if nearest_enemy == null:
            nearest_enemy = enemy
            continue

        if nearest_enemy.global_position.distance_to(self.global_position) > enemy.global_position.distance_to(self.global_position):
            nearest_enemy = enemy

    return nearest_enemy


func get_current_state() -> ArmyState:
    return $ArmyStateMachine.current_state


func update_grid_position() -> void:
    var new_position = player.global_position + grid_position

    set_target_position(new_position)


func set_target_position(new_position: Vector2) -> void:
    pathfinding.set_target_position(new_position)

## --- Private ---
