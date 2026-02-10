@tool
class_name Enemy
extends CharacterBody2D

signal navigation_finished

@export var hurtbox: Hurtbox

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
@export var health := 10:
    set(value):
        health = value

        if is_node_ready() and health_component:
            health_component.health = value

@export var max_health := 10:
    set(value):
        health = value

        if is_node_ready() and health_component:
            health_component.max_health = value

@export var base_max_health: int = 100
@export var base_defense: int = 10
@export var base_attack: int = 10

# ------ Module ------
@onready var sprite := $Sprite
@onready var health_component: Health = $HealthComponent
@onready var movement: BaseMovement = $Movement
@onready var animation: BaseAnimation = $Animation
@onready var attack_handler: BaseAttack = $ProjectileAttack
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var enemy_scanner: EnemyScanner = $EnemyScanner
@onready var state_machine: StateMachine = $StateMachine

# # ------ Utilities ------


class AnimationState:
    const IDLE = "Idle"
    const MOVE = "Move"
    const ATTACK = "Attack"


var animation_states := [AnimationState.IDLE, AnimationState.MOVE, AnimationState.ATTACK]

# var attack_speed: float = 10
var wander_speed: float = 50
var back_speed: float = 50
var chase_speed: float = 100

# var leader: Enemy

var start_position: Vector2
var next_position: Vector2

var offset: Vector2


func _ready() -> void:
    _setup_enemy_scanner()
    _setup_health_component()
    _setup_hurtbox()

    pathfinding.navigation_agent.navigation_finished.connect(_on_navigation_finished)


func _setup_enemy_scanner() -> void:
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range


func _setup_health_component() -> void:
    health_component.max_health = health
    health_component.health = health
    health_component.reset()

    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)


func _setup_hurtbox() -> void:
    hurtbox.get_hit.connect(_on_damaged)


func _on_damaged(attack_info: AttackInfo) -> void:
    health_component.apply_damage(attack_info)


func _on_health_changed(new_health: float) -> void:
    if new_health <= 0:
        return

    if sprite.material:
        var overlay_ratio = (1 - (new_health / health_component.max_health)) * 0.5
        sprite.material.set_shader_parameter("overlay_amount", overlay_ratio)


func _on_health_depleted() -> void:
    queue_free()


func _on_navigation_finished() -> void:
    navigation_finished.emit()


# ------ High-Level Public API (Refactored) ------


## Moves the enemy toward a global position using pathfinding
func move_to_position(target_pos: Vector2, speed: float, arrive_dist: float = 5.0) -> void:
    pathfinding.set_target_position(target_pos)
    pathfinding.set_speed(speed)
    pathfinding.set_arrive_distance(arrive_dist)

    var velocity_output = pathfinding.get_velocity()
    movement.set_velocity(velocity_output)


## Sets the animation direction based on a vector
func set_facing_direction(direction: Vector2, state_name: String) -> void:
    animation.set_animation_direction(direction, state_name)


## Plays a specific animation state
func play_animation(state_name: String, time_scale: float = 1.0) -> void:
    animation.travel_to_state(state_name)
    animation.set_time_scale(time_scale)


## Stops all movement
func stop_movement() -> void:
    movement.stop()


## Attack Logic
func perform_attack(target_pos: Vector2) -> void:
    if attack_handler.can_attack():
        attack_handler.start_attack(target_pos)


## Pathfinding Status
# func is_navigation_finished() -> bool:
#     return pathfinding.navigation_agent.is_navigation_finished()


## Scanner Proxies
func is_target_tracked() -> bool:
    return get_tracked_targets().size() > 0


func is_target_attackable() -> bool:
    return get_attackable_targets().size() > 0


func get_tracked_targets() -> Array:
    return enemy_scanner.get_enemies_in_range(visible_range)


func get_attackable_targets() -> Array:
    return enemy_scanner.get_enemies_in_range(attack_range)


func get_nearest_attackable_target() -> Node2D:
    return enemy_scanner.get_nearest_in_range(attack_range)


func get_nearest_tracked_target() -> Node2D:
    return enemy_scanner.get_nearest_in_range(visible_range)


## State Machine
func get_current_state() -> ArmyState:
    return state_machine.current_state


## --- Unique Functions ---
func get_distance_to_start() -> float:
    return global_position.distance_to(start_position)
