@tool
class_name Enemy
extends CharacterBody2D

signal navigation_finished

# -------------------------
# Exports
# -------------------------

@export var data: EnemyData

@export_group("Visuals")
@export var sprite: Sprite2D

@export_group("Modules — Combat")
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var damage_number: DamageNumberModule
@export var health_bar: HealthBarModule
@export var combat_module: CombatModule

@export_group("Modules — Perception")
@export var aggro_detection: DetectionModule
@export var deaggro_detection: DetectionModule
@export var reach_detection: DetectionModule

@export_group("Modules — Movement")
@export var movement_module: MovementModule
@export var navigation_module: NavigationModule
@export var animation_module: AnimationModule

@export_group("Modules — Gameplay")
@export var loot_drop: LootDropModule

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

var stats: Stats
var home_position: Vector2

# -------------------------
# Lifecycle
# -------------------------


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire_nodes()
        _bind_modules()


func _ready() -> void:
    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    if home_position == Vector2.ZERO:
        push_error("Enemy: home_position not set. Assign it at spawn time.")
    else:
        global_position = home_position


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
    if not aggro_detection:
        aggro_detection = find_child("AggroDetection", true, false) as DetectionModule
    if not deaggro_detection:
        deaggro_detection = find_child("DeaggroDetection", true, false) as DetectionModule
    if not reach_detection:
        reach_detection = find_child("ReachDetection", true, false) as DetectionModule
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule
    if not navigation_module:
        navigation_module = find_child("NavigationModule", true, false) as NavigationModule
    if not animation_module:
        animation_module = find_child("AnimationModule", true, false) as AnimationModule
    if not loot_drop:
        loot_drop = find_child("LootDropModule", true, false) as LootDropModule
    if not state_machine:
        state_machine = find_child("StateMachine", true, false) as StateMachine


func _apply_data() -> void:
    if data == null:
        push_error("Enemy: no EnemyData assigned — using fallback stats.")
        stats = Stats.new()
        stats.faction = Stats.Faction.ENEMY
        stats.base_max_health = 100.0
        stats.base_defense = 0.0
        stats.base_damage = 10.0
        stats.setup_stats()
        return

    # Duplicate so each instance owns its own runtime stats
    stats = data.stats.duplicate() as Stats
    stats.setup_stats()

    if aggro_detection and data.aggro_range > 0.0:
        aggro_detection.set_collision_radius(data.aggro_range)

    if deaggro_detection and data.deaggro_range > 0.0:
        deaggro_detection.set_collision_radius(data.deaggro_range)


func _bind_modules() -> void:
    # --- Combat ---
    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox

        if not Engine.is_editor_hint():
            damage_receiver.damaged.connect(_on_damaged)
            damage_receiver.died.connect(_on_died)

    if hit_feedback:
        hit_feedback.stats = stats
        hit_feedback.damage_receiver = damage_receiver
        hit_feedback.movement_module = movement_module

    if damage_number:
        damage_number.damage_receiver = damage_receiver

    if health_bar:
        health_bar.bind(stats)

    if combat_module:
        combat_module.stats = stats

    # --- Perception: reach radius is derived from attack range, never manual ---
    if not Engine.is_editor_hint():
        _bind_reach_detection()

    # --- Movement ---
    if movement_module:
        movement_module.character = self

    if navigation_module:
        navigation_module.character = self
        navigation_module.movement = movement_module

        if not Engine.is_editor_hint():
            navigation_module.navigation_finished.connect(_on_navigation_finished)

    # --- Loot ---
    if loot_drop:
        loot_drop.owner_node = self
        if data and data.drop_profile:
            loot_drop.drop_profile = data.drop_profile


func _bind_reach_detection() -> void:
    if reach_detection == null:
        return

    if combat_module == null:
        push_warning("Enemy: reach_detection present but combat_module is null — radius not set.")
        return

    var attack_range := combat_module.get_attack_range(Stats.AttackSlot.PRIMARY)
    if attack_range > 0.0:
        reach_detection.set_collision_radius(attack_range)
    else:
        push_warning("Enemy: attack range returned 0 — reach_detection radius not set.")


# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_damaged(_amount: float, _new_health: float, _info: AttackData) -> void:
    if sprite and sprite.material and stats:
        var ratio := (1.0 - (stats.health / stats.current_max_health)) * 0.5
        sprite.material.set_shader_parameter("overlay_amount", ratio)


func _on_died(_info: AttackData) -> void:
    if loot_drop:
        loot_drop.drop_loot()
    queue_free()


func _on_navigation_finished() -> void:
    navigation_finished.emit()


# -------------------------
# Public API — movement
# -------------------------


func move_to_position(target_pos: Vector2, speed: float, arrive_dist: float = 5.0) -> void:
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


## Perform a primary attack toward target_pos via CombatModule.
## Uses reach_detection.global_position as origin so the range check
## matches the detection zone, avoiding false out-of-range warnings.
func perform_attack(target_pos: Vector2) -> void:
    if combat_module == null:
        return

    var origin := reach_detection.global_position if reach_detection else global_position
    var attack_range := combat_module.get_attack_range(Stats.AttackSlot.PRIMARY)
    if origin.distance_to(target_pos) > attack_range:
        return

    combat_module.perform_attack(Stats.AttackSlot.PRIMARY, target_pos)


# -------------------------
# Public API — animation
# -------------------------


func play_animation(state_name: StringName, time_scale: float = 1.0) -> void:
    if animation_module == null:
        return
    animation_module.travel(state_name)
    animation_module.set_time_scale(time_scale)


func set_facing_direction(direction: Vector2, state_name: StringName) -> void:
    if animation_module == null:
        return
    animation_module.face_direction(direction)
    animation_module.set_blend_position(direction, state_name)


# -------------------------
# Public API — perception proxies
# -------------------------


## True when the player is inside aggro range (line-of-sight checked)
func is_player_in_aggro_range() -> bool:
    if aggro_detection == null:
        return false

    return aggro_detection.get_target_count(true) > 0


## True when the player has moved OUTSIDE the deaggro zone
## Use this as the chase exit condition to prevent oscillation
func is_player_outside_deaggro_range() -> bool:
    if deaggro_detection == null:
        return true

    return deaggro_detection.get_target_count(false) == 0


## True when the player is close enough to attack
func is_player_in_reach() -> bool:
    if reach_detection == null:
        return false
    return reach_detection.get_target_count(false) > 0


func get_nearest_aggro_target() -> Node2D:
    if aggro_detection == null:
        return null
    return aggro_detection.get_closest_target(true)


func get_nearest_reachable_target() -> Node2D:
    if reach_detection == null:
        return null
    return reach_detection.get_closest_target(false)


# -------------------------
# Public API — misc
# -------------------------


func get_distance_to_home() -> float:
    return global_position.distance_to(home_position)
