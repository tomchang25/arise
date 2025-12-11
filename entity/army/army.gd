@tool
class_name Army
extends CharacterBody2D

@export var attack_range: float = 50:
    set(value):
        if not is_node_ready():
            return

        attack_range = value
        attack_handler.attack_range = value

@export var enemy_check_range: float = 75:
    set(value):
        if not is_node_ready():
            return

        enemy_check_range = value
        enemy_check_detectbox.radius = value

# @export var follow_threshold: float = 50.0

@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation

@onready var attack_handler: ProjectileAttack = $ProjectileAttack
@onready var enemy_check_detectbox: Detectbox = $EnemyCheckDetectbox

@onready var pathfinding: Pathfinding = $Pathfinding

@onready var soft_collision: SoftCollision = $SoftCollision

var enemies_in_range: Array = []:
    get:
        return enemies_in_range.filter(func(area): return is_instance_valid(area))

var player: Player


func _ready() -> void:
    enemy_check_detectbox.detected.connect(_on_enemies_detected)

    player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
    move_and_slide()


func is_enemy_visible() -> bool:
    return enemies_in_range.size() > 0


func is_enemy_attackable() -> bool:
    for enemy in enemies_in_range:
        if attack_handler.is_in_range(enemy.global_position):
            return true

    return false


# func is_too_far_from_player() -> bool:
#     return player.global_position.distance_to(self.global_position) > follow_threshold


func get_current_state() -> ArmyState:
    return $ArmyStateMachine.current_state


func _on_enemies_detected(nodes_in_range: Array) -> void:
    enemies_in_range = nodes_in_range.filter(func(node): return node.get_owner() is Enemy)
