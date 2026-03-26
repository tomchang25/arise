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

# _cell_layer_counts maps Vector2i → Dictionary[int, int]  (layer_bit → body_count).
# Maintained in sync with _cells so get_directional_density can count masked bodies
# in O(1) per cell instead of iterating every body.
var _cell_layer_counts: Dictionary = { }

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

    # ring = 0 corresponds to the cell itself, ring = 1 corresponds to adjacent cells
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


## Returns a weighted density of nearby bodies in the given movement direction.
## Uses pre-computed per-cell layer counts — O(1) per cell, O(9) total (fixed 3×3 grid).
func get_directional_density(pos: Vector2, move_dir: Vector2, mask: int = 0) -> float:
    var center := _cell_key(pos)
    var dir := move_dir.normalized()
    var density := 0.0

    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var key := Vector2i(center.x + dx, center.y + dy)

            # Use layer count table when available; fall back to cell size for mask == 0.
            var count := 0
            if mask == 0:
                if not _cells.has(key):
                    continue
                count = _cells[key].size()
            else:
                if not _cell_layer_counts.has(key):
                    continue
                count = _count_masked(key, mask)
                if count == 0:
                    continue

            var weight := 0.35
            var offset := Vector2(dx, dy)
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

    # Update layer count table.
    var layer: int = _char_to_layer.get(character, 0)
    if layer != 0:
        if not _cell_layer_counts.has(key):
            _cell_layer_counts[key] = { }
        var counts: Dictionary = _cell_layer_counts[key]
        counts[layer] = counts.get(layer, 0) + 1


func _remove(character: CharacterBody2D, key: Vector2i) -> void:
    if not _cells.has(key):
        return
    _cells[key].erase(character)
    if _cells[key].is_empty():
        _cells.erase(key)

    # Update layer count table.
    var layer: int = _char_to_layer.get(character, 0)
    if layer != 0 and _cell_layer_counts.has(key):
        var counts: Dictionary = _cell_layer_counts[key]
        var new_count: int = counts.get(layer, 1) - 1
        if new_count <= 0:
            counts.erase(layer)
        else:
            counts[layer] = new_count
        if counts.is_empty():
            _cell_layer_counts.erase(key)


## Sum the body counts for all layer bits that overlap [mask]. O(unique layers in cell).
## In practice a cell holds at most 2-3 distinct layer values, so this is effectively O(1).
func _count_masked(key: Vector2i, mask: int) -> int:
    var counts: Dictionary = _cell_layer_counts[key]
    var total := 0
    for layer: int in counts:
        if (layer & mask) != 0:
            total += counts[layer]
    return total
