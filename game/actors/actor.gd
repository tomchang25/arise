## Shared base class for all character actors (Army, Enemy, etc.).
## Consolidates the common module exports, animation constants, runtime state,
## and public API that was previously duplicated between Army and Enemy.
@tool
class_name Actor
extends CharacterBody2D

signal attack_finished
signal navigation_finished
signal died(info)

# -------------------------
# Exports — Visuals
# -------------------------

@export_group("Visuals")
@export var sprite: Sprite2D

# -------------------------
# Exports — Modules
# -------------------------

@export_group("Modules — Combat")
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var damage_number: DamageNumberModule
@export var health_bar: HealthBarModule
@export var combat_module: CombatModule

@export_group("Modules — Perception")
@export var reach_detection: DetectionModule
@export var aggro_detection: DetectionModule
@export var deaggro_detection: DetectionModule

@export_group("Modules — Movement")
@export var movement_module: MovementModule
@export var navigation_module: NavigationModule
@export var animation_module: AnimationModule

@export_group("Modules — AI")
@export var state_machine: StateMachine

# -------------------------
# Animation state constants
# -------------------------

const ANIM_IDLE: StringName = &"Idle"
const ANIM_MOVE: StringName = &"Move"
const ANIM_ATTACK: StringName = &"Attack"

# -------------------------
# Runtime state
# -------------------------

## Runtime stats — duplicated from data at spawn time so each instance is independent.
var stats: Stats

## Absolute world position that this actor considers its "home" or "formation slot".
## Managed externally by the owning group (ArmyHandler / EnemyGroup).
var anchor_position: Vector2 = Vector2.ZERO

var dormant := false

# -------------------------
# Lifecycle
# -------------------------


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire_nodes()
        _bind_modules()


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()


## Wire child nodes to exports when the node names match the expected names.
## Subclasses should call super._auto_wire_nodes() then wire their own extras.
func _auto_wire_nodes() -> void:
    if not sprite:
        sprite = find_child("Sprite", true, false) as Sprite2D
    if not hurtbox:
        hurtbox = find_child("Hurtbox", true, false) as Hurtbox
    if not damage_receiver:
        damage_receiver = find_child("DamageReceiverModule", true, false) as DamageReceiverModule
    if not hit_feedback:
        hit_feedback = find_child("HitFeedbackModule", true, false) as HitFeedbackModule
    if not damage_number:
        damage_number = find_child("DamageNumberModule", true, false) as DamageNumberModule
    if not health_bar:
        health_bar = find_child("HealthBar", true, false) as HealthBarModule
    if not combat_module:
        combat_module = find_child("CombatModule", true, false) as CombatModule
    if not reach_detection:
        reach_detection = find_child("ReachDetection", true, false) as DetectionModule
    if not aggro_detection:
        aggro_detection = find_child("AggroDetection", true, false) as DetectionModule
    if not deaggro_detection:
        deaggro_detection = find_child("DeaggroDetection", true, false) as DetectionModule
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule
    if not navigation_module:
        navigation_module = find_child("NavigationModule", true, false) as NavigationModule
    if not animation_module:
        animation_module = find_child("AnimationModule", true, false) as AnimationModule
    if not state_machine:
        state_machine = find_child("StateMachine", true, false) as StateMachine


## Override in subclasses to load data into stats and module parameters.
func _apply_data() -> void:
    pass


func _bind_modules() -> void:
    # --- Combat ---
    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox

        if not Engine.is_editor_hint():
            if not damage_receiver.died.is_connected(_on_died):
                damage_receiver.died.connect(_on_died)

    if hit_feedback:
        hit_feedback.stats = stats
        hit_feedback.damage_receiver = damage_receiver
        hit_feedback.movement_module = movement_module

    if damage_number:
        damage_number.damage_receiver = damage_receiver

    if health_bar:
        health_bar.bind(stats)

    # --- Perception: reach radius from weapon 0 attack 0 range ---
    if not Engine.is_editor_hint():
        _bind_reach_detection()

    # --- Movement ---
    if movement_module:
        movement_module.character = self

    if navigation_module:
        navigation_module.character = self
        navigation_module.movement = movement_module

        if not Engine.is_editor_hint():
            if not navigation_module.navigation_finished.is_connected(navigation_finished.emit):
                navigation_module.navigation_finished.connect(navigation_finished.emit)

    # --- Animation signals ---
    if animation_module and not animation_module.animation_finished.is_connected(_on_animation_finished):
        animation_module.animation_finished.connect(_on_animation_finished)


## Reads weapon 0 attack 0 range from the combat module and applies it to
## reach_detection. Override in subclasses that set reach from data directly.
func _bind_reach_detection() -> void:
    if reach_detection == null:
        return

    if combat_module == null:
        push_warning(name + ": reach_detection present but combat_module is null — radius not set.")
        return

    var attack_range := combat_module.get_attack_range(0, 0)
    if attack_range > 0.0:
        reach_detection.set_collision_radius(attack_range)
    else:
        push_warning(name + ": attack range returned 0 — reach_detection radius not set.")

# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_died(info) -> void:
    died.emit(info)
    queue_free()


func _on_animation_finished(anim_name: StringName) -> void:
    if String(ANIM_ATTACK) in String(anim_name):
        attack_finished.emit()

# -------------------------
# Public API — movement
# -------------------------


func move_to_position(target_pos: Vector2, speed: float, arrive_dist: float = 10.0) -> void:
    if navigation_module == null:
        return
    navigation_module.set_speed(speed)
    navigation_module.set_arrive_distance(arrive_dist)
    navigation_module.set_target_position(target_pos)


func stop_movement() -> void:
    if navigation_module:
        navigation_module.stop()
    if movement_module:
        movement_module.stop_all_motion()


func get_path_velocity() -> Vector2:
    if movement_module == null:
        return Vector2.ZERO
    return movement_module.path_velocity

# -------------------------
# Public API — combat
# -------------------------


## Perform a fire-and-forget attack toward target_pos.
## Defaults to weapon 0, attack 0 — the primary attack of the default weapon.
func perform_attack(target_pos: Vector2, weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return
    combat_module.perform_attack(weapon_index, attack_index, target_pos)


## Signal the combat module that an animation-driven attack has finished.
func end_attack(weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return
    combat_module.end_attack(weapon_index, attack_index)


## Returns true if the given weapon/attack is off cooldown and ready to fire.
func can_attack(weapon_index: int = 0, attack_index: int = 0) -> bool:
    if combat_module == null:
        return false
    return combat_module.can_attack(weapon_index, attack_index)


## Activate a persistent (ATTACHED) hitbox weapon.
func activate_attack(weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return
    combat_module.perform_attack(weapon_index, attack_index, Vector2.ZERO)


## Deactivate a persistent (ATTACHED) hitbox weapon.
func deactivate_attack(weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return
    combat_module.end_attack(weapon_index, attack_index)


## Enable or disable an entire weapon by index.
func set_weapon_enabled(weapon_index: int, value: bool) -> void:
    if combat_module == null:
        return
    combat_module.set_weapon_enabled(weapon_index, value)


## Returns the effective attack range for a given weapon/attack.
func get_attack_range(weapon_index: int = 0, attack_index: int = 0) -> float:
    if combat_module == null:
        return 0.0
    return combat_module.get_attack_range(weapon_index, attack_index)

# -------------------------
# Public API — animation
# -------------------------


func play_animation(state_name: StringName, time_scale: float = 1.0, force_restart: bool = false) -> void:
    if animation_module == null:
        return
    animation_module.travel(state_name, force_restart)
    animation_module.set_time_scale(time_scale)


func set_facing_direction(direction: Vector2, state_name: StringName) -> void:
    if animation_module == null:
        return
    animation_module.face_direction(direction)
    animation_module.set_blend_position(direction, state_name)


func get_facing_direction() -> Vector2:
    if animation_module == null:
        return Vector2.RIGHT
    return animation_module.get_last_direction()

# -------------------------
# Public API — perception (reach-based, shared by all actors)
# -------------------------


## True when the aggro detection zone has at least one target.
func is_aggro_active() -> bool:
    if aggro_detection == null:
        return false
    return aggro_detection.get_target_count(false) > 0


## True when the deaggro detection zone has NO targets (target has left the zone).
## Use this as the chase exit condition to prevent oscillation.
func is_deaggro_active() -> bool:
    if deaggro_detection == null:
        return true
    return deaggro_detection.get_target_count(false) == 0


## Returns the closest target in the aggro detection zone, or null.
func get_nearest_aggro_target() -> Node2D:
    if aggro_detection == null:
        return null
    return aggro_detection.get_closest_target(false)


## True when there is at least one target within the reach (attack) detection zone.
func is_target_in_reach() -> bool:
    if reach_detection == null:
        return false
    return reach_detection.get_target_count(false) > 0


## Returns the closest target within the reach detection zone, or null.
func get_nearest_reachable_target() -> Node2D:
    if reach_detection == null:
        return null
    return reach_detection.get_closest_target(false)

# -------------------------
# Public API — state machine
# -------------------------


func get_current_state() -> State:
    if state_machine == null:
        return null
    return state_machine.current_state

# -------------------------
# Public API — misc
# -------------------------


## Distance from this actor's current position to its anchor position.
func get_distance_to_anchor() -> float:
    return global_position.distance_to(anchor_position)
