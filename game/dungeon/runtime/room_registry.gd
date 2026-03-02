class_name RoomRegistry
extends RefCounted

var tile_size: int = 16

# room_id -> data
# data: { "bounds": Rect2i, "center_tile": Vector2, "center_world": Vector2, "cell_indices": PackedInt32Array }
var rooms: Dictionary = {}
var start_room_id: int = -1


func add_room(room_id: int, bounds: Rect2i, center_tile: Vector2, cell_indices: PackedInt32Array) -> void:
    var center_world := center_tile * float(tile_size)
    rooms[room_id] = {
        "bounds": bounds,
        "center_tile": center_tile,
        "center_world": center_world,
        "cell_indices": cell_indices,
    }


func get_room_ids() -> Array:
    return rooms.keys()


func get_center_world(room_id: int) -> Vector2:
    if not rooms.has(room_id):
        return Vector2.ZERO
    return rooms[room_id]["center_world"]


func get_center_tile(room_id: int) -> Vector2:
    if not rooms.has(room_id):
        return Vector2.ZERO
    return rooms[room_id]["center_tile"]


func get_random_floor_world(room_id: int, width: int, rng: RandomNumberGenerator) -> Vector2:
    if not rooms.has(room_id):
        return Vector2.ZERO
    var indices: PackedInt32Array = rooms[room_id]["cell_indices"]
    if indices.is_empty():
        return get_center_world(room_id)

    var idx := indices[rng.randi_range(0, indices.size() - 1)]
    var x := idx % width
    var y := int(idx as float / width)
    return Vector2(x, y) * float(tile_size)
