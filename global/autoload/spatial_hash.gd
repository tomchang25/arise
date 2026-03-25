extends Node
## Autoload: SpatialHash
## Lightweight O(1) spatial partitioning for SoftCollision and Pickup detection.
## Replaces Area2D overlap detection so the physics engine never touches these shapes.
##
## Cell size is a fixed constant (CELL_SIZE pixels per cell).
## SoftCollision.min_distance is expressed in cells, not pixels.
## Pickup positions are tracked in a separate bucket so character and pickup
## queries never interfere with each other.

## Fixed cell size in pixels. All callers must convert pixel distances to cells
## by dividing by CELL_SIZE before passing to query_nearby / query_nearby_pickups.
const CELL_SIZE: float = 16.0

# _cells maps Vector2i → Array[CharacterBody2D]  (character separation)
var _cells: Dictionary = {}

# Maps each registered character to its current cell key so we can remove it cheaply.
var _char_to_cell: Dictionary = {}

var _char_to_layer: Dictionary = {}

# ---------------------------------------------------------------------------
# Pickup-specific storage (separate buckets — never mixed with characters)
# ---------------------------------------------------------------------------

# _pickup_cells maps Vector2i → Array[Node2D]  (BasePickup instances)
var _pickup_cells: Dictionary = {}

# Maps each registered pickup to its current cell key.
var _pickup_to_cell: Dictionary = {}

# ---------------------------------------------------------------------------
# Public API — Characters (used by SoftCollision)
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
## [param radius_cells] is the search radius expressed in *cells* (not pixels).
## Divide a pixel radius by CELL_SIZE before calling.
## Results include characters in the same cell and all adjacent cells within
## the radius. The caller is responsible for exact distance-filtering the results.
func query_nearby(pos: Vector2, radius_cells: float, max_results: int = 4) -> Array:
	var results: Array = []
	var r := ceili(radius_cells)
	var center := _cell_key(pos)

	for ring in range(0, r + 1):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
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


func get_directional_density(pos: Vector2, move_dir: Vector2, mask: int = 0) -> float:
	var center := _cell_key(pos)
	var dir := move_dir.normalized()
	var density := 0.0

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(center.x + dx, center.y + dy)
			if not _cells.has(key):
				continue

			var weight := 0.35
			var offset := Vector2(dx, dy)
			if offset != Vector2.ZERO:
				weight += max(offset.normalized().dot(dir), 0.0)

			var count := 0
			for body in _cells[key]:
				if mask == 0 or (_char_to_layer.get(body, 0) & mask) != 0:
					count += 1

			density += count * weight

	return density

# ---------------------------------------------------------------------------
# Public API — Pickups (used by BasePickup and PickupCollectorModule)
# ---------------------------------------------------------------------------


## Register a pickup node so collectors can find it via query_nearby_pickups.
## Call once from BasePickup._ready().
func register_pickup(pickup: Node2D) -> void:
	var key := _cell_key(pickup.global_position)
	_insert_pickup(pickup, key)
	_pickup_to_cell[pickup] = key


## Unregister a pickup (called from BasePickup._exit_tree()).
func unregister_pickup(pickup: Node2D) -> void:
	if not _pickup_to_cell.has(pickup):
		return
	var key: Vector2i = _pickup_to_cell[pickup]
	_remove_pickup(pickup, key)
	_pickup_to_cell.erase(pickup)


## Update a pickup's position in the hash.
## Call every physics frame from BasePickup._physics_process() when the pickup moves.
func move_pickup(pickup: Node2D, new_pos: Vector2) -> void:
	if not _pickup_to_cell.has(pickup):
		return
	var old_key: Vector2i = _pickup_to_cell[pickup]
	var new_key := _cell_key(new_pos)
	if old_key == new_key:
		return
	_remove_pickup(pickup, old_key)
	_insert_pickup(pickup, new_key)
	_pickup_to_cell[pickup] = new_key


## Return all pickup nodes whose cell overlaps a circle of the given radius.
## [param radius_cells] is the search radius expressed in *cells* (not pixels).
## Divide a pixel radius by CELL_SIZE before calling.
func query_nearby_pickups(pos: Vector2, radius_cells: float, max_results: int = 64) -> Array:
	var results: Array = []
	var r := ceili(radius_cells)
	var center := _cell_key(pos)

	for ring in range(0, r + 1):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if abs(dx) != ring and abs(dy) != ring:
					continue
				var key := Vector2i(center.x + dx, center.y + dy)
				if _pickup_cells.has(key):
					results.append_array(_pickup_cells[key])
					if results.size() >= max_results:
						return results
	return results

# ---------------------------------------------------------------------------
# Internal helpers — characters
# ---------------------------------------------------------------------------


func _cell_key(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))


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

# ---------------------------------------------------------------------------
# Internal helpers — pickups
# ---------------------------------------------------------------------------


func _insert_pickup(pickup: Node2D, key: Vector2i) -> void:
	if not _pickup_cells.has(key):
		_pickup_cells[key] = []
	_pickup_cells[key].append(pickup)


func _remove_pickup(pickup: Node2D, key: Vector2i) -> void:
	if not _pickup_cells.has(key):
		return
	_pickup_cells[key].erase(pickup)
	if _pickup_cells[key].is_empty():
		_pickup_cells.erase(key)
