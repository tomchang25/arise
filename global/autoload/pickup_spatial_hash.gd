extends Node
## Autoload: PickupSpatialHash
## Lightweight spatial hash for pickup discovery.
## Replaces Area2D overlap detection so the physics engine never touches pickup shapes.
##
## cell_size should be at least as large as the largest expected magnet_range so that
## a single-ring neighbour search covers all candidates.

var cell_size: float = 64.0

# _cells maps Vector2i → Array[Node2D]
var _cells: Dictionary = {}

# Maps each registered pickup to its current cell key for cheap removal.
var _pickup_to_cell: Dictionary = {}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Register a pickup so it can be discovered by collectors.
## Call once from BasePickup._ready().
func register(pickup: Node2D) -> void:
    var key := _cell_key(pickup.global_position)
    _insert(pickup, key)
    _pickup_to_cell[pickup] = key


## Unregister a pickup (on collection or despawn).
## Call from BasePickup._exit_tree().
func unregister(pickup: Node2D) -> void:
    if not _pickup_to_cell.has(pickup):
        return
    var key: Vector2i = _pickup_to_cell[pickup]
    _remove(pickup, key)
    _pickup_to_cell.erase(pickup)


## Update a pickup's position in the hash.
## Call each physics frame from BasePickup when the pickup is moving.
func move(pickup: Node2D, new_pos: Vector2) -> void:
    if not _pickup_to_cell.has(pickup):
        return
    var old_key: Vector2i = _pickup_to_cell[pickup]
    var new_key := _cell_key(new_pos)
    if old_key == new_key:
        return
    _remove(pickup, old_key)
    _insert(pickup, new_key)
    _pickup_to_cell[pickup] = new_key


## Return all pickups whose cell overlaps a circle of the given radius.
## Results include the center cell and all neighbouring cells within the radius.
## The caller is responsible for exact distance-filtering.
func query_nearby(pos: Vector2, radius: float) -> Array:
    var results: Array = []
    var r := ceili(radius / cell_size)
    var center := _cell_key(pos)

    for ring in range(0, r + 1):
        for dx in range(-ring, ring + 1):
            for dy in range(-ring, ring + 1):
                if abs(dx) != ring and abs(dy) != ring:
                    continue
                var key := Vector2i(center.x + dx, center.y + dy)
                if _cells.has(key):
                    results.append_array(_cells[key])

    return results


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


func _cell_key(pos: Vector2) -> Vector2i:
    return Vector2i(floori(pos.x / cell_size), floori(pos.y / cell_size))


func _insert(pickup: Node2D, key: Vector2i) -> void:
    if not _cells.has(key):
        _cells[key] = []
    _cells[key].append(pickup)


func _remove(pickup: Node2D, key: Vector2i) -> void:
    if not _cells.has(key):
        return
    _cells[key].erase(pickup)
    if _cells[key].is_empty():
        _cells.erase(key)
