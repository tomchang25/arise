class_name DungeonLayout
extends RefCounted

enum TileType { EMPTY, FLOOR, WALL, CORRIDOR }

# Basic map data
var width: int
var height: int
var grid: Array  # Array[Array[int]] of TileType


# Merged rooms (big rooms after overlap merge)
class RoomInfo:
    var id: int
    var bounds: Rect2i
    var center: Vector2
    var cell_count: int
    var cell_indices: PackedInt32Array  # each is (y * width + x)

    func _init(_id: int, _bounds: Rect2i, _center: Vector2, _cell_count: int, _cell_indices: PackedInt32Array) -> void:
        id = _id
        bounds = _bounds
        center = _center
        cell_count = _cell_count
        cell_indices = _cell_indices


var rooms: Array[RoomInfo] = []  # index aligned to room.id

# optional “special” ids
var start_room_id: int = -1


func is_in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < width and y < height


func get_room(room_id: int) -> RoomInfo:
    if room_id < 0 or room_id >= rooms.size():
        return null
    return rooms[room_id]


func get_random_floor_point_in_room(room_id: int, rng: RandomNumberGenerator) -> Vector2i:
    var r := get_room(room_id)
    if r == null or r.cell_indices.is_empty():
        return Vector2i(r.bounds.get_center()) if r != null else Vector2i.ZERO

    var idx := r.cell_indices[rng.randi_range(0, r.cell_indices.size() - 1)]
    var x := idx % width
    var y: int = floor(idx as float / width)

    return Vector2i(x, y)
