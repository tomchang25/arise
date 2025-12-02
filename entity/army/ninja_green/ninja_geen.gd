class_name NinjaGreen
extends CharacterBody2D

@onready var attack_handler: ProjectileAttack = $ProjectileAttack
@onready var auto_attack_detectbox: Detectbox = $AutoAttackDetectbox
@onready var enemy_check_detectbox: Detectbox = $EnemyCheckDetectbox

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@onready var follow_player: FollowPlayer = $FollowPlayer
@onready var soft_collision: SoftCollision = $SoftCollision

var nearest_enemy: Enemy = null
var player: Player

var check_player_timer: float = 0

var prev_player_position: Vector2


func _ready() -> void:
    auto_attack_detectbox.detected.connect(_on_enemies_detected)
    auto_attack_detectbox.last_node_left.connect(_on_last_enemy_left)

    player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
    check_player_timer += delta
    if check_player_timer > 0.05:
        check_player_timer = 0
        if prev_player_position != player.global_position:
            prev_player_position = player.global_position
            follow_player.set_target(player.global_position)

    var movement_vector: Vector2 = follow_player.movement_vector
    var soft_push_velocity: Vector2 = soft_collision.soft_push_velocity

    # if not navigation_agent_2d.is_navigation_finished():
    if movement_vector != Vector2.ZERO:
        soft_collision.enabled = false
        velocity = movement_vector
    else:
        soft_collision.enabled = true
        velocity = soft_push_velocity

    # soft_collision.enabled = true
    # velocity = soft_push_velocity

    # print(movement_vector, " - ", soft_push_velocity, " - ", velocity)

    move_and_slide()


func _on_enemies_detected(nodes_in_range: Array) -> void:
    for node in nodes_in_range:
        if node.get_owner() is not Enemy:
            continue

        var enemy: Enemy = node.get_owner()
        var distance: float = enemy.global_position.distance_to(self.global_position)

        if nearest_enemy == null or distance < nearest_enemy.global_position.distance_to(self.global_position):
            nearest_enemy = enemy

    if attack_handler.can_attack():
        attack_handler.attack(nearest_enemy.hitbox.global_position)


func _on_last_enemy_left() -> void:
    nearest_enemy = null
