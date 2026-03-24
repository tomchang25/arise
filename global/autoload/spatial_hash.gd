extends Node
## Autoload: SpatialHash
## Lightweight O(1) spatial partitioning for SoftCollision.
## Replaces Area2D overlap detection so the physics engine never touches these shapes.
##
## Cell size is driven by SoftCollision.min_distance, so cells stay small enough
## that a pixel-art character (16x16) won't crowd a single bucket.

# cell_size is set at runtime by the first SoftCollision that registers.
# All SoftCollisions must share the same min_distance for this to be accurate.
var cell_size: float = 16.0

# _cells maps Vector2i → Array[CharacterBody2D]
var _cells: Dictionary = { }

# Maps each registered character to its current cell key so we can remove it cheaply.
var _char_to_cell: Dictionary = { }

var _char_to_layer: Dictionary = { }

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Register a character so it can be found by neighbours.
## Call once from SoftCollision._ready().
func register(character: CharacterBody2D, collision_layer: int = 0) -> void:
    var key := _cell_key(character.global_position)
    _insert(character, key)
    _char_to_cell[character] = key
    _char_to_layer[character] = collision_layer


## Unregister a character (e.g. on enemy death / queue_free).
## Call from SoftCollision._exit_tree() or the enemy's _exit_tree().
func unregister(character: CharacterBody2D) -> void:
    if not _char_to_cell.has(character):
        return
    var key: Vector2i = _char_to_cell[character]
    _remove(character, key)
    _char_to_cell.erase(character)
    _char_to_layer.erase(character)


## Update a character's position in the hash.
## Call every physics frame from SoftCollision._physics_process().
func move(character: CharacterBody2D, new_pos: Vector2) -> void:
    if not _char_to_cell.has(character):
        return
    var old_key: Vector2i = _char_to_cell[character]
    var new_key := _cell_key(new_pos)
    if old_key == new_key:
        return
    _remove(character, old_key)
    _insert(character, new_key)
    _char_to_cell[character] = new_key


## Return all characters whose cell overlaps a circle of the given radius.
## Results include characters in the same cell and all adjacent cells.
## The caller is responsible for distance-filtering the results.
func query_nearby(pos: Vector2, radius: float, max_results: int = 4) -> Array:
    var results: Array = []
    var r := ceili(radius / cell_size)
    var center := _cell_key(pos)

    # ring = 0 corresponds to the cell itself，ring = 1 corresponds to adjacent cells
    for ring in range(0, r + 1):
        for dx in range(-ring, ring + 1):
            for dy in range(-ring, ring + 1):
                # only process cells on the circle
                if abs(dx) != ring and abs(dy) != ring:
                    continue
                var key := Vector2i(center.x + dx, center.y + dy)
                if _cells.has(key):
                    results.append_array(_cells[key])
                    if results.size() >= max_results:
                        return results
    return results


## Returns the stored collision_layer for a character, or 0xFFFFFFFF if not found.
func get_layer(character: CharacterBody2D) -> int:
    return _char_to_layer.get(character, 0xFFFFFFFF)


func get_directional_density(pos: Vector2, move_dir: Vector2) -> float:
    var center := _cell_key(pos)
    var dir := move_dir.normalized()
    var density := 0.0

    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var key := Vector2i(center.x + dx, center.y + dy)
            if not _cells.has(key):
                continue

            var count: int = _cells[key].size()
            if count <= 0:
                continue

            var offset := Vector2(dx, dy)
            var weight := 0.35

            if offset != Vector2.ZERO:
                weight += max(offset.normalized().dot(dir), 0.0)

            density += count * weight

    return density
# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


func _cell_key(pos: Vector2) -> Vector2i:
    return Vector2i(floori(pos.x / cell_size), floori(pos.y / cell_size))


func _insert(character: CharacterBody2D, key: Vector2i) -> void:
    if not _cells.has(key):
        _cells[key] = []
    _cells[key].append(character)


func _remove(character: CharacterBody2D, key: Vector2i) -> void:
    if not _cells.has(key):
        return
    _cells[key].erase(character)
    if _cells[key].is_empty():
        _cells.erase(key)
