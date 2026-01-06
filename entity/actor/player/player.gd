@tool
class_name Player
extends CharacterBody2D

signal damaged(attack: Attack)

signal roll_finished
signal attack_finished

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
            health_component.max_health = value

# ------ Core ------
@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var health_component: Health = $HealthComponent

# ------ Components ------

# TODO: Remove later
@onready var enemy_scanner: EnemyScanner = $EnemyScanner

@onready var attack_handler: BaseAttack = $MeleeAttack

@onready var movement: BaseMovement = $PlayerMovement
@onready var animation: BaseAnimation = $PlayerAnimation

@onready var state_machine := $PlayerStateMachine
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

# ------ Properties ------


class AnimationState:
    const IDLE = "Idle"
    const MOVE = "Move"
    const ROLL = "Roll"
    const ATTACK = "Attack"


var animation_states := [AnimationState.IDLE, AnimationState.MOVE, AnimationState.ROLL, AnimationState.ATTACK]

var run_speed: float = 150
var walk_speed: float = 100
var roll_speed: float = 500
var attack_speed: float = 50
# var nearest_enemy: Enemy = null

## --- GDScript Lifecycle ---


func _ready() -> void:
    _setup_enemy_scanner()
    hitbox.damaged.connect(_on_damaged)

    health_component.max_health = health
    health_component.reset()
    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)

    animation.animation_finished.connect(_on_animation_finished)

    perform_movement(Vector2.DOWN, 0.0, false)
    set_facing_direction(Vector2.DOWN)


func _on_animation_finished(anim_name: StringName) -> void:
    if AnimationState.ROLL in anim_name:
        roll_finished.emit()

    if AnimationState.ATTACK in anim_name:
        attack_finished.emit()


func _setup_enemy_scanner() -> void:
    enemy_scanner.visible_range = visible_range
    enemy_scanner.attack_range = attack_range


func _on_health_changed(new_health: float) -> void:
    if new_health <= 0:
        return

    if sprite.material != null:
        var overlay_ratio = (1 - (new_health / health_component.max_health)) * 0.5
        sprite.material.set_shader_parameter("overlay_amount", overlay_ratio)


func _on_health_depleted() -> void:
    queue_free()


func _on_damaged(attack_info: Attack) -> void:
    health_component.health -= attack_info.damage

    damaged.emit(attack_info)


# ------ General ------


func get_last_direction() -> Vector2:
    return movement.get_last_direction()


func perform_movement(direction: Vector2, speed: float, avoidance: bool = true) -> void:
    movement.set_direction(direction)
    movement.set_speed(speed)
    navigation_agent_2d.avoidance_enabled = avoidance


func get_attack_target_direction() -> Vector2:
    var target = get_nearest_attackable_enemy()
    var target_pos = target.global_position if target else get_global_mouse_position()
    return global_position.direction_to(target_pos)


func set_facing_direction(direction: Vector2) -> void:
    if direction == Vector2.ZERO:
        return
    # Force the animation direction for all states (or specifically the Attack state)
    if direction != Vector2.ZERO:
        for state in animation_states:
            animation.set_animation_direction(direction, state)


func play_animation(state_name: String, time_scale: float = 1.0) -> void:
    animation.travel_to_state(state_name)
    animation.set_time_scale(time_scale)


func start_attack_logic(target_pos: Vector2) -> void:
    attack_handler.start_attack(target_pos)


func end_attack_logic() -> void:
    attack_handler.end_attack()


## --- Public API ---


func get_attackable_enemies() -> Array:
    return enemy_scanner.get_enemies_in_range(attack_range)


func get_nearest_attackable_enemy() -> Node2D:
    return enemy_scanner.get_nearest_in_range(attack_range)


# ------ Player Unique ------
# --- Player Input ---


func get_movement_input() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_attack_pressed() -> bool:
    return Input.is_action_pressed("attack")


func is_run_pressed() -> bool:
    return Input.is_action_pressed("run")


func is_roll_pressed() -> bool:
    return Input.is_action_pressed("roll")


func is_attack_triggered() -> bool:
    if not attack_handler.can_attack():
        return false

    return is_attack_pressed() or get_attackable_enemies().size() > 0
