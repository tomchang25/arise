class_name DungeonPlacementPass
extends Node

@export_group("Required")
@export var spawn_point_scene: PackedScene

@export_group("Spawn Root")
@export var spawn_root_group: String = "world"

@export_group("Grid Info")
@export var grid_width: int = 160

@export_group("Static Placement - Buttons")
@export var button_scene: PackedScene
@export var button_count: int = 2
@export var button_blacklist_start_room: bool = true

@export_group("Static Placement - Destroyables")
@export var destroyable_scene: PackedScene
@export var destroyable_count: int = 10

@export_group("Static Placement - Extraction")
@export var extraction_scene: PackedScene
@export var place_extraction: bool = true
@export var extraction_room_id: int = 0  # 0 = auto non-start

@export_group("SpawnPoint Behavior")
@export var buildtime_warning_time: float = 0.0

# Optional: If you want runtime spawnpoints to show warning
@export var runtime_warning_time: float = 1.5

# Keep references so you can debug/cleanup if needed
var _world: Node
var _registry: RoomRegistry
var _difficulty: int
var _rng: RandomNumberGenerator
# var _rng_seed: int

# -------------------------
# Public API
# -------------------------


func bind(world: Node, registry: RoomRegistry, rng_seed: int, difficulty: int) -> void:
    _world = world
    _registry = registry
    _difficulty = difficulty
    # _rng_seed = rng_seed

    _rng = RandomNumberGenerator.new()
    if rng_seed == 0:
        _rng.randomize()
    else:
        _rng.seed = int(rng_seed) ^ 0xA17E551


func execute_static() -> void:
    # Call this after bind(), when dungeon is built but before gameplay starts.
    if not _ensure_bound():
        return

    if spawn_point_scene == null:
        push_error("DungeonPlacementPass: spawn_point_scene is not assigned")
        return

    var ctx := _make_ctx()

    if button_scene != null and button_count > 0:
        _place_buttons(ctx, button_count)

    if destroyable_scene != null and destroyable_count > 0:
        _place_destroyables(ctx, destroyable_count)

    if place_extraction and extraction_scene != null:
        _place_extraction(ctx)


# Runtime / dynamic spawn entry:
# Use this from room-enter triggers, mission events, summon, etc.
func spawn_dynamic_at_global(pos: Vector2, action: SpawnAction, room_id: int = -1) -> SpawnPoint:
    if not _ensure_bound():
        return null
    if spawn_point_scene == null:
        push_error("DungeonPlacementPass: spawn_point_scene is not assigned")
        return null

    var ctx := _make_ctx()
    ctx.room_id = room_id

    var sp := _spawn_point(pos, action, ctx, runtime_warning_time)
    return sp


func spawn_dynamic_in_room_center(room_id: int, action: SpawnAction) -> SpawnPoint:
    if not _ensure_bound():
        return null
    var pos := _registry.get_center_world(room_id)
    return spawn_dynamic_at_global(pos, action, room_id)


func spawn_dynamic_in_room_random(room_id: int, action: SpawnAction) -> SpawnPoint:
    if not _ensure_bound():
        return null
    var pos := _pick_room_floor_pos(room_id, _rng)
    return spawn_dynamic_at_global(pos, action, room_id)


# -------------------------
# Static placement (internal)
# -------------------------


func _place_buttons(ctx: SpawnContext, count: int) -> void:
    var candidates := _get_candidate_rooms(button_blacklist_start_room)
    if candidates.is_empty():
        push_warning("DungeonPlacementPass: no candidate rooms for buttons")
        return

    for i in range(count):
        var room_id := candidates[_rng.randi_range(0, candidates.size() - 1)]
        var pos := _pick_room_floor_pos(room_id, _rng)

        var action := SpawnPackedSceneAction.new()
        action.scene = button_scene
        action.parent_mode = SpawnPackedSceneAction.ParentMode.CTX_SPAWN_ROOT
        action.set_global_position = true

        _spawn_buildtime(pos, action, ctx, room_id)


func _place_destroyables(ctx: SpawnContext, count: int) -> void:
    var room_ids: Array = _registry.get_room_ids()
    if room_ids.is_empty():
        return

    for i in range(count):
        var room_id := int(room_ids[_rng.randi_range(0, room_ids.size() - 1)])
        var pos := _pick_room_floor_pos(room_id, _rng)

        var action := SpawnPackedSceneAction.new()
        action.scene = destroyable_scene
        action.parent_mode = SpawnPackedSceneAction.ParentMode.CTX_SPAWN_ROOT
        action.set_global_position = true

        _spawn_buildtime(pos, action, ctx, room_id)


func _place_extraction(ctx: SpawnContext) -> void:
    var room_id := extraction_room_id
    if room_id == 0:
        var candidates := _get_candidate_rooms(true)
        room_id = (candidates[_rng.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() else _registry.start_room_id)

    var pos := _registry.get_center_world(room_id)

    var action := SpawnPackedSceneAction.new()
    action.scene = extraction_scene
    action.parent_mode = SpawnPackedSceneAction.ParentMode.CTX_SPAWN_ROOT
    action.set_global_position = true

    _spawn_buildtime(pos, action, ctx, room_id)
    print(pos)


# -------------------------
# Spawn helpers
# -------------------------


func _spawn_buildtime(pos: Vector2, action: SpawnAction, base_ctx: SpawnContext, room_id: int) -> void:
    # Use a copy-like ctx so room_id doesn't leak across spawns
    var ctx := _clone_ctx(base_ctx)
    ctx.room_id = room_id

    var sp := _spawn_point(pos, action, ctx, buildtime_warning_time)
    # Build-time: usually immediate placement
    sp.start()


func _spawn_point(pos: Vector2, action: SpawnAction, ctx: SpawnContext, warning_time: float) -> SpawnPoint:
    var sp := spawn_point_scene.instantiate() as SpawnPoint
    if sp == null:
        push_error("DungeonPlacementPass: spawn_point_scene is not a SpawnPoint")
        return null

    # Put spawnpoint in world (or under ctx.spawn_root if you prefer)
    _world.add_child(sp)
    sp.global_position = pos

    # configure
    sp.warning_time = warning_time
    sp.spawn_root_group = spawn_root_group

    sp.setup(action, ctx)
    return sp


func _make_ctx() -> SpawnContext:
    var ctx := SpawnContext.new()
    ctx.difficulty = _difficulty
    ctx.rng = _rng
    ctx.spawn_root = _resolve_spawn_root()
    return ctx


func _clone_ctx(src: SpawnContext) -> SpawnContext:
    var ctx := SpawnContext.new()
    ctx.room_id = src.room_id
    ctx.difficulty = src.difficulty
    ctx.rng_seed = src.rng_seed
    ctx.rng = src.rng
    ctx.spawn_root = src.spawn_root
    return ctx


func _resolve_spawn_root() -> Node:
    var tree := get_tree()
    if tree != null and spawn_root_group != "":
        var n := tree.get_first_node_in_group(spawn_root_group)
        if n != null:
            return n
    return _world


func _pick_room_floor_pos(room_id: int, rng: RandomNumberGenerator) -> Vector2:
    if grid_width <= 0:
        return _registry.get_center_world(room_id)

    var p := _registry.get_random_floor_world(room_id, grid_width, rng)
    if p == Vector2.ZERO:
        return _registry.get_center_world(room_id)
    return p


func _get_candidate_rooms(blacklist_start: bool) -> Array[int]:
    var out: Array[int] = []
    for rid in _registry.get_room_ids():
        var id := int(rid)
        if blacklist_start and id == _registry.start_room_id:
            continue
        out.append(id)
    return out


func _ensure_bound() -> bool:
    if _world == null or _registry == null:
        push_warning("DungeonPlacementPass: call bind(world, registry, seed, difficulty) first.")
        return false
    return true
