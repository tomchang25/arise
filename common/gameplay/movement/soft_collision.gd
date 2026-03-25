@tool
class_name SoftCollision
extends Node2D
## Soft collision/separation module that prevents units from overlapping by
## injecting a distance-based separation force into MovementModule.knockback_velocity.
##
## Uses SpatialHash (Autoload) instead of Area2D — zero physics-engine overhead.
## The node type is Node2D so it still has global_position, but no CollisionShape
## is ever created, so Godot's broadphase/narrowphase never runs on these objects.
##
## Setup:
##   1. Add SpatialHash.gd as an Autoload named "SpatialHash".
##   2. Replace the old Area2D SoftCollision node with this Node2D version.
##   3. Make sure min_distance matches across all unit types, or set cell_size
##      manually on the SpatialHash autoload before the first enemy spawns.

@export var enabled := true:
    set = set_enabled

@export var character: CharacterBody2D
@export var movement_module: MovementModule

@export_group("Separation")

## The group this unit belongs to (e.g. "enemy", "player", "army").
## Automatically converts to a collision_layer bitmask via CollisionMaskManager.
@export var layer_name: StringName = &"":
    set(value):
        layer_name = value
        collision_layer = CollisionMaskManager.layer(value)

## The groups this unit pushes. Each entry is a group name (e.g. &"enemy", &"army").
@export var mask_names: Array[StringName] = []:
    set(value):
        mask_names = value
        collision_mask = CollisionMaskManager.mask(mask_names)

## Divides the received separation force. Higher mass = harder to push.
@export var mass: float = 1.0
## Base separation force applied at full overlap (dist = 0).
@export var separation_force: float = 100.0
## Maximum separation distance expressed in *cells* (cell = SpatialHash.CELL_SIZE pixels).
## e.g. 0.75 cells = 0.75 × 16 = 12 px. Keep consistent across all unit types.
@export var min_distance: float = 0.75:
    set(value):
        min_distance = max(value, 0.0)

## Maximum number of overlapping neighbours processed per physics frame.
@export var max_neighbours: int = 4

@export var crowd_block_start: float = 2.0
@export var crowd_block_range: float = 5.0

## Which group this unit belongs to. Use CollisionMaskManager.layer(&"group_name").
@export var collision_layer: int = 0
## Which groups this unit pushes. Use CollisionMaskManager.mask([...]).
@export var collision_mask: int = 0

@export_group("Tick Update")

## When enabled, separation is only recalculated every [tick_interval] seconds.
## The SpatialHash position update still runs every physics frame so other units
## can query this unit accurately; only the force calculation is throttled.
@export var tick_enabled: bool = true

## How often (in seconds) to recalculate separation force when tick_enabled is true.
## e.g. 0.1 = 10 Hz, 0.5 = 2 Hz.
@export_range(0.016, 5.0, 0.016, "suffix:s") var tick_interval: float = 0.05

## Stagger tick phases across units so they don't all recalculate on the same frame.
## When true, each unit starts with a random phase offset within [0, tick_interval).
@export var tick_stagger: bool = true

var _enabled: bool = true

# Cached results written on each tick and applied every physics frame.
var _cached_separation: Vector2 = Vector2.ZERO
var _cached_crowd_block: float = 0.0

# Accumulated time since the last tick recalculation.
var _tick_accumulator: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
    if Engine.is_editor_hint() or character == null:
        return

    SpatialHash.register(character, collision_layer)

    # Spread tick phases so units don't all fire on the same frame.
    if tick_stagger:
        _tick_accumulator = randf_range(0.0, tick_interval)


func _exit_tree() -> void:
    if Engine.is_editor_hint() or character == null:
        return
    SpatialHash.unregister(character)


func reset() -> void:
    enabled = true
    _enabled = true
    _cached_separation = Vector2.ZERO
    _cached_crowd_block = 0.0
    _tick_accumulator = 0.0
    if movement_module:
        movement_module.set_separation(Vector2.ZERO)
        movement_module.set_crowd_block_ratio(0.0)


func set_enabled(value: bool) -> void:
    enabled = value
    _enabled = value
    set_physics_process(value)
    if not value and movement_module:
        movement_module.set_separation(Vector2.ZERO)
        movement_module.set_crowd_block_ratio(0.0)


func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint() or not _enabled or movement_module == null or character == null:
        return

    # Always keep the hash position current so neighbours query correctly.
    SpatialHash.move(character, character.global_position)

    if tick_enabled:
        _tick_accumulator += delta
        if _tick_accumulator >= tick_interval:
            _tick_accumulator -= tick_interval
            _recalculate_separation()
        # Apply the most recently cached values every frame for smooth motion.
        movement_module.set_separation(_cached_separation)
        movement_module.set_crowd_block_ratio(_cached_crowd_block)
    else:
        # Original behaviour: recalculate every physics frame.
        _recalculate_separation()
        movement_module.set_separation(_cached_separation)
        movement_module.set_crowd_block_ratio(_cached_crowd_block)

# ---------------------------------------------------------------------------
# Separation calculation (shared by both tick and non-tick paths)
# ---------------------------------------------------------------------------


func _recalculate_separation() -> void:
    # min_distance is in cells; convert to pixels for all distance comparisons.
    var min_dist_px := min_distance * SpatialHash.CELL_SIZE
    var candidates := SpatialHash.query_nearby(character.global_position, min_distance, max_neighbours)
    var count := 0
    var total_separation := Vector2.ZERO

    for body in candidates:
        if count >= max_neighbours:
            break

        # Skip self.
        if body == character:
            continue

        if collision_mask != 0:
            var body_layer := SpatialHash.get_layer(body)
            if (collision_mask & body_layer) == 0:
                continue

        var diff: Vector2 = character.global_position - body.global_position
        var dist: float = diff.length()

        if dist >= min_dist_px:
            continue

        var direction: Vector2
        if dist > 0.0:
            direction = diff / dist
        else:
            # Exact overlap: push in a random direction to break symmetry.
            direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

        var t := 1.0 - (dist / min_dist_px)
        var force := separation_force * t / mass

        total_separation += direction * force
        count += 1

    var crowd_block_ratio := 0.0

    var desired_move := movement_module.manual_velocity
    if desired_move == Vector2.ZERO:
        desired_move = movement_module.path_velocity

    if desired_move != Vector2.ZERO:
        var density := SpatialHash.get_directional_density(
            character.global_position,
            desired_move,
            collision_mask,
        )

        crowd_block_ratio = clamp((density - crowd_block_start) / crowd_block_range, 0.0, 1.0)
        crowd_block_ratio = crowd_block_ratio * crowd_block_ratio * (3.0 - 2.0 * crowd_block_ratio)

    _cached_separation = total_separation.limit_length(separation_force / mass)
    _cached_crowd_block = crowd_block_ratio
