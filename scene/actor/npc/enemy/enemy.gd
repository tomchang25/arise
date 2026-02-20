@tool
class_name Enemy
extends CharacterBody2D

signal navigation_finished

@export var stats: Stats
@export var hurtbox: Hurtbox

@export_category("Modules")
@export var vision_detection_module: DetectionModule
@export var reach_detection_module: DetectionModule
@export var communication_module: CommunicationModule
@export var attack_module: AttackModule

@export_group("Movement Settings")
@export var wander_speed: float = 50.0
@export var wander_range: float = 150.0
@export var back_speed: float = 50
@export var chase_speed: float = 100

@export_category("Scanner Settings")
@export var vision_range: float = 200.0:
    set(value):
        vision_range = value

        if is_inside_tree():
            _setup_detection_radius()

@export var reach_range: float = 50.0:
    set(value):
        reach_range = value

        if is_inside_tree():
            _setup_detection_radius()

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
@onready var pathfinding: Pathfinding = $Pathfinding
@onready var state_machine: StateMachine = $StateMachine

# @onready var enemy_scanner: EnemyScanner = $EnemyScanner

# # ------ Utilities ------


class AnimationState:
    const IDLE = "Idle"
    const MOVE = "Move"
    const ATTACK = "Attack"


var animation_states := [AnimationState.IDLE, AnimationState.MOVE, AnimationState.ATTACK]

# var attack_speed: float = 10

# var leader: Enemy

# var start_position: Vector2
# var next_position: Vector2
# var offset: Vector2

var home_position: Vector2


func _ready() -> void:
    _setup_modules()

    if attack_module:
        attack_module.initialize(stats)

    # if next_position == Vector2.ZERO:
    #     next_position = global_position

    # if start_position == Vector2.ZERO:
    #     start_position = global_position
    if home_position == Vector2.ZERO:
        home_position = global_position

    pathfinding.navigation_agent.navigation_finished.connect(_on_navigation_finished)


func _setup_modules() -> void:
    _setup_detection_radius()
    _setup_health_component()
    _setup_hurtbox()


func _setup_detection_radius() -> void:
    if vision_detection_module:
        vision_detection_module.set_collision_radius(vision_range)

    if reach_detection_module:
        reach_detection_module.set_collision_radius(reach_range)


# func _setup_enemy_scanner() -> void:
#     enemy_scanner.visible_range = visible_range
#     enemy_scanner.attack_range = attack_range


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
    if attack_module.can_attack():
        attack_module.start_attack(target_pos)
        attack_module.end_attack()


## Scanner Proxies
func is_target_tracked() -> bool:
    return vision_detection_module.get_target_count(true) > 0


func is_target_attackable() -> bool:
    return reach_detection_module.get_target_count(false) > 0


func get_nearest_tracked_target() -> Node2D:
    return vision_detection_module.get_closest_target(true)


func get_nearest_attackable_target() -> Node2D:
    return reach_detection_module.get_closest_target(false)


## State Machine
func get_current_state() -> ArmyState:
    return state_machine.current_state


## --- Unique Functions ---
func get_distance_to_start() -> float:
    return global_position.distance_to(home_position)
