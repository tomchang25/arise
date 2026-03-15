class_name DamageNumberModule
extends Node

@export var enabled: bool = true

@export_group("Dependencies")
@export var damage_receiver: DamageReceiverModule
@export var world_anchor: Node2D

@export_group("Spawn")
@export var damage_number_scene: PackedScene
@export var spawn_group: String = "damage_number"

@export_group("Position")
@export var height_offset: float = 18.0
@export var random_x_offset: float = 8.0

@export_group("Filtering")
@export var minimum_damage_to_show: float = 1.0
@export var show_zero_damage: bool = false

@export_group("Throttling")
@export var enabled_throttle := true
@export var max_spawns_per_frame := 6
@export var max_active_numbers := 40

var _spawned_this_frame: int = 0
var _last_spawn_frame: int = -1

var _spawn_action: SpawnPackedSceneAction


func _ready() -> void:
    if damage_number_scene == null:
        push_warning("DamageNumberModule: damage_number_scene is not assigned.")
        return

    _spawn_action = SpawnPackedSceneAction.new()
    _spawn_action.scene = damage_number_scene
    _spawn_action.use_anchor_position = true
    _spawn_action.use_anchor_rotation = false

    if damage_receiver and not damage_receiver.damaged.is_connected(_on_damaged):
        damage_receiver.damaged.connect(_on_damaged)


func _on_damaged(amount: float, _new_health: float, info: AttackData) -> void:
    if not enabled:
        return

    if not _should_show(amount):
        return

    if enabled_throttle and not _can_spawn_now():
        return

    spawn_damage_number(amount, info)


func spawn_damage_number(amount: float, info: AttackData = null) -> void:
    if not enabled:
        return

    if _spawn_action == null:
        return

    var spawn_parent := SpawnContext.resolve_spawn_parent(spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_warning("DamageNumberModule: could not resolve a valid spawn parent.")
        return

    var ctx := SpawnContext.new()
    ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(_spawn_action, _get_spawn_position(), ctx)

    var result := await request.execute()
    if not result.success:
        return

    var number := result.spawned_node as DamageNumber
    if number == null:
        push_warning("DamageNumberModule: spawned node is not a DamageNumber.")
        return

    var is_crit := info.is_crit if info != null else false
    number.setup(amount, is_crit)

    _register_spawn()


# -------------------------
# Internal
# -------------------------


func _should_show(amount: float) -> bool:
    if show_zero_damage and amount <= 0.0:
        return true
    return amount >= minimum_damage_to_show


func _can_spawn_now() -> bool:
    _sync_frame_counter()

    if _spawned_this_frame >= max_spawns_per_frame:
        return false

    var spawn_parent := SpawnContext.resolve_spawn_parent(spawn_group, self)
    if is_instance_valid(spawn_parent) and spawn_parent.get_child_count() >= max_active_numbers:
        return false

    return true


func _register_spawn() -> void:
    _sync_frame_counter()
    _spawned_this_frame += 1


func _sync_frame_counter() -> void:
    var current_frame := Engine.get_process_frames()
    if current_frame != _last_spawn_frame:
        _last_spawn_frame = current_frame
        _spawned_this_frame = 0


func _get_spawn_position() -> Vector2:
    var anchor := _get_world_anchor()
    var base := anchor.global_position if anchor else (owner as Node2D).global_position if owner is Node2D else Vector2.ZERO
    return base + Vector2(randf_range(-random_x_offset, random_x_offset), -height_offset)


func _get_world_anchor() -> Node2D:
    if world_anchor != null:
        return world_anchor

    if owner is Node2D:
        return owner as Node2D

    return null
