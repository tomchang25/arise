class_name DamageNumberModule
extends Node

@export var enabled: bool = true:
    set = set_enabled

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
@export var minimum_damage_to_show: float = 10.0
@export var show_zero_damage: bool = false

var _enabled: bool = true
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


func reset() -> void:
    _enabled = true


func set_enabled(value: bool) -> void:
    _enabled = value
    if not _enabled:
        _stop_runtime_state()


func is_enabled() -> bool:
    return _enabled


func _stop_runtime_state() -> void:
    pass


func _on_damaged(amount: float, _new_health: float, info: EffectContext) -> void:
    if not _enabled:
        return

    if not _should_show(amount):
        return

    SpawnThrottle.enqueue(&"damage_number", spawn_damage_number.bind(amount, info))


func spawn_damage_number(amount: float, info: EffectContext = null) -> void:
    if not _enabled:
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

    if not is_instance_valid(self):
        return

    if not result.success:
        return

    var number := result.spawned_node as DamageNumber
    if number == null:
        push_warning("DamageNumberModule: spawned node is not a DamageNumber.")
        return

    var is_crit := false
    if info != null and info.source_stats != null and info.definition != null:
        is_crit = randf() < clamp(info.source_stats.current_crit_chance + info.definition.crit_bonus, 0.0, 1.0)
    number.setup(amount, is_crit)

# -------------------------
# Internal
# -------------------------


func _should_show(amount: float) -> bool:
    if show_zero_damage and amount <= 0.0:
        return true
    return amount >= minimum_damage_to_show


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
