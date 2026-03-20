@tool
class_name Army
extends CharacterBody2D

signal attack_finished

# -------------------------
# Exports
# -------------------------

@export var data: ArmyData

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
@export var track_detection: DetectionModule
@export var reach_detection: DetectionModule

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

var stats: Stats
var player: Node2D
var grid_position: Vector2 = Vector2.ZERO

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

	player = get_tree().get_first_node_in_group("player")


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
	if not track_detection:
		track_detection = find_child("TrackDetection", true, false) as DetectionModule
	if not reach_detection:
		reach_detection = find_child("ReachDetection", true, false) as DetectionModule
	if not movement_module:
		movement_module = find_child("MovementModule", true, false) as MovementModule
	if not navigation_module:
		navigation_module = find_child("NavigationModule", true, false) as NavigationModule
	if not animation_module:
		animation_module = find_child("AnimationModule", true, false) as AnimationModule
	if not state_machine:
		state_machine = find_child("StateMachine", true, false) as StateMachine


func _apply_data() -> void:
	if data == null:
		push_error("Army: no ArmyData assigned.")
		return

	stats = data.stats.duplicate() as Stats
	stats.setup_stats()

	if track_detection and data.track_range > 0.0:
		track_detection.set_collision_radius(data.track_range)

	if reach_detection and data.attack_range > 0.0:
		reach_detection.set_collision_radius(data.attack_range)

	if combat_module:
		combat_module.setup(stats, data.weapons)


func _bind_modules() -> void:
	if hurtbox:
		hurtbox.owner_stats = stats

	if damage_receiver:
		damage_receiver.stats = stats
		damage_receiver.hurtbox = hurtbox

		if not Engine.is_editor_hint():
			if not damage_receiver.damaged.is_connected(_on_damaged):
				damage_receiver.damaged.connect(_on_damaged)
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

	if movement_module:
		movement_module.character = self

	if navigation_module:
		navigation_module.character = self
		navigation_module.movement = movement_module

	if animation_module and not animation_module.animation_finished.is_connected(_on_animation_finished):
		animation_module.animation_finished.connect(_on_animation_finished)

# -------------------------
# Lifecycle callbacks
# -------------------------


func _on_damaged(_amount: float, _new_health: float, _info) -> void:
	if sprite and sprite.material and stats:
		var ratio := (1.0 - (stats.health / stats.current_max_health)) * 0.5
		sprite.material.set_shader_parameter("overlay_amount", ratio)


func _on_died(_info) -> void:
	queue_free()


func _on_animation_finished(anim_name: StringName) -> void:
	if String(ANIM_ATTACK) in String(anim_name):
		attack_finished.emit()

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


func is_navigation_finished() -> bool:
	if navigation_module == null:
		return true
	return navigation_module.is_path_finished()


func get_path_velocity() -> Vector2:
	if movement_module == null:
		return Vector2.ZERO
	return movement_module.path_velocity

# -------------------------
# Public API — combat
# -------------------------


func perform_attack(target_pos: Vector2, weapon_index: int = 0, attack_index: int = 0) -> void:
	if combat_module == null:
		return
	combat_module.perform_attack(weapon_index, attack_index, target_pos)


func end_attack(weapon_index: int = 0, attack_index: int = 0) -> void:
	if combat_module == null:
		return
	combat_module.end_attack(weapon_index, attack_index)


func can_attack(weapon_index: int = 0, attack_index: int = 0) -> bool:
	if combat_module == null:
		return false
	return combat_module.can_attack(weapon_index, attack_index)

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
# Public API — perception proxies
# -------------------------


func is_target_tracked() -> bool:
	if track_detection == null:
		return false
	return track_detection.get_target_count(false) > 0


func is_target_attackable() -> bool:
	if reach_detection == null:
		return false
	return reach_detection.get_target_count(false) > 0


func get_nearest_tracked_target() -> Node2D:
	if track_detection == null:
		return null
	return track_detection.get_closest_target(false)


func get_nearest_attackable_target() -> Node2D:
	if reach_detection == null:
		return null
	return reach_detection.get_closest_target(false)

# -------------------------
# Public API — state machine
# -------------------------


func get_current_state() -> State:
	return state_machine.current_state

# -------------------------
# Public API — misc
# -------------------------


func get_distance_to_player() -> float:
	if player == null:
		return INF
	var target_pos := player.global_position + grid_position
	return target_pos.distance_to(global_position)
