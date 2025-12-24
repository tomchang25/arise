class_name Player
extends CharacterBody2D

# ------ Core ------
@onready var skin: Sprite2D = $Skin
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

# ------ Components ------

@onready var enemy_detectbox: Detectbox = $EnemyDetectbox
@onready var melee_attack: MeleeAttack = $MeleeAttack

@onready var movement: BaseMovement = $PlayerMovement
@onready var animation: BaseAnimation = $PlayerAnimation
@onready var player_input: PlayerInput = $PlayerInput
@onready var hitbox: Hitbox = $Hitbox

@onready var state_machine := $PlayerStateMachine

# ------ Properties ------

var nearest_enemy: Enemy = null

## --- GDScript Lifecycle ---


func _ready() -> void:
    enemy_detectbox.targets_changed.connect(_on_enemies_detected)
    # animation.animation_finished.connect(_on_animation_finished)

    hitbox.damaged.connect(_on_damaged)


func _on_enemies_detected(nodes_in_range: Array) -> void:
    if nodes_in_range.is_empty():
        nearest_enemy = null

    for node in nodes_in_range:
        if node is not Enemy:
            continue

        var enemy: Enemy = node
        var distance: float = enemy.global_position.distance_to(self.global_position)

        if nearest_enemy == null or distance < nearest_enemy.global_position.distance_to(self.global_position):
            nearest_enemy = enemy


func _on_damaged(attack_info: Attack) -> void:
    print("Player damaged by attack: ", attack_info.damage)

## --- Public API ---

# func attack(target_position: Vector2) -> void:
#     melee_attack.aim_at(target_position)
#     melee_attack.start_attack(target_position)
