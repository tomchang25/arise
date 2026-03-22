@tool
class_name SoftCollision
extends Area2D
## Soft collision/separation module that prevents units from overlapping by
## injecting a distance-based separation force into MovementModule.knockback_velocity.
##
## Uses get_overlapping_areas() — the neighbour only needs a SoftCollision (Area2D),
## no CharacterBody2D CollisionShape required.
##
## Default configurations by entity type:
##   player  → ignored_pushers = ["armies"]
##   army    → ignored_pushers = []
##   enemy   → ignored_pushers = []

@export var character: CharacterBody2D
@export var movement_module: MovementModule

@export_group("Separation")
## Divides the received separation force. Higher mass = harder to push.
@export var mass: float = 1.0
## Base separation force applied at full overlap (dist = 0).
@export var separation_force: float = 200.0
## Maximum distance at which force is applied. Shape radius is kept in sync.
@export var min_distance: float = 10.0:
    set(value):
        min_distance = max(value, 0.0)

## Maximum number of overlapping neighbours processed per physics frame.
@export var max_neighbours: int = 4

# -------------------------
# Lifecycle
# -------------------------


func _init() -> void:
    monitorable = true
    monitoring = true


func _physics_process(_delta: float) -> void:
    if movement_module == null or character == null:
        return

    var areas := get_overlapping_areas()
    var count := 0

    var total_separation := Vector2.ZERO
    for area in areas:
        if count >= max_neighbours:
            break

        # Only interact with other SoftCollision areas
        if not area is SoftCollision:
            continue

        var neighbour := area as SoftCollision

        # Skip self (shouldn't happen but guard anyway)
        if neighbour.character == character:
            continue

        var neighbour_body := neighbour.character
        # Use character positions for accurate center-to-center distance
        var source_pos := neighbour_body.global_position if neighbour_body != null else area.global_position
        var diff: Vector2 = character.global_position - source_pos
        var dist: float = diff.length()

        if dist >= min_distance:
            count += 1
            continue

        var direction: Vector2
        if dist > 0.0:
            direction = diff / dist
        else:
            # Exact overlap: push in a random direction to break symmetry
            direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

        var t := 1.0 - (dist / min_distance)
        var force := separation_force * (t * t) / mass

        total_separation += direction * force
        count += 1

    movement_module.set_separation(total_separation)
