class_name Player
extends CharacterBody2D
@onready var movement: BaseMovement = $PlayerMovement
@onready var animation: BaseAnimation = $PlayerAnimationddddddd
@onready var player_input: PlayerInput = $PlayerInput

@onready var melee_attack: MeleeAttack = $MeleeAttack
@onready var auto_attack_detectbox: Detectbox = $AutoAttackDetectbox

@onready var state_machine := $PlayerStateMachine

var nearest_enemy: Enemy = null


func _ready() -> void:
    auto_attack_detectbox.detected.connect(_on_enemies_detected)
    # animation.animation_finished.connect(_on_animation_finished)


func _on_enemies_detected(nodes_in_range: Array) -> void:
    if nodes_in_range.is_empty():
        nearest_enemy = null

    for node in nodes_in_range:
        if node.get_owner() is not Enemy:
            continue

        var enemy: Enemy = node.get_owner()
        var distance: float = enemy.global_position.distance_to(self.global_position)

        if nearest_enemy == null or distance < nearest_enemy.global_position.distance_to(self.global_position):
            nearest_enemy = enemy


# func _on_animation_finished(anim_name: String) -> void:
#     if animation.ANIMATION_STATE_ATTACK in anim_name:
#         melee_attack.end_attack()


func attack(target_position: Vector2) -> void:
    melee_attack.aim_at(target_position)
    melee_attack.start_attack()
