class_name DungeonGenerator
extends Node

enum TileType { EMPTY, FLOOR, WALL }

# 1. & 2. Generalized Parameters
@export var grid_width: int = 80
@export var grid_height: int = 80
@export var room_count: int = 15
@export var room_min_size: Vector2i = Vector2i(6, 6)
@export var room_max_size: Vector2i = Vector2i(14, 14)

# 3a. Corridor Settings
@export var corridor_width: int = 2
@export var corridor_max_length: int = 50  # Avoid connecting very far rooms if possible

# 4. Merge Settings
@export var merge_threshold: int = 3  # If distance is less than this, merge rooms


func generate() -> Dictionary:
    var grid = []
    # Initialize Grid
    for y in range(grid_height):
        grid.append([])
        for x in range(grid_width):
            grid[y].append(TileType.EMPTY)

    var rooms: Array[Rect2i] = []
    var max_attempts = 200
    var attempts = 0

    # --- Step 1: Place Rooms ---
    while rooms.size() < room_count and attempts < max_attempts:
        var w = randi_range(room_min_size.x, room_max_size.x)
        var h = randi_range(room_min_size.y, room_max_size.y)
        var x = randi_range(1, grid_width - w - 1)
        var y = randi_range(1, grid_height - h - 1)
        var new_room = Rect2i(x, y, w, h)

        var overlaps = false
        for other in rooms:
            # Grow by 1 to ensure at least 1 wall separates distinct rooms
            if new_room.grow(1).intersects(other):
                overlaps = true
                break

        if not overlaps:
            rooms.append(new_room)
            _paint_room(grid, new_room)

        attempts += 1

    # --- Step 2: Connect Rooms (MST / Kruskal's) ---
    # We map which "group" a room belongs to. Initially, every room is its own group.
    var room_groups = range(rooms.size())
    var connections = []  # Stores pairs of (room_index_a, room_index_b, distance)

    # Calculate all possible distances
    for i in range(rooms.size()):
        for j in range(i + 1, rooms.size()):
            var center_a = Vector2(rooms[i].get_center())
            var center_b = Vector2(rooms[j].get_center())
            var dist = center_a.distance_to(center_b)
            connections.append({"a": i, "b": j, "dist": dist})

    # Sort by distance (closest rooms first)
    connections.sort_custom(func(a, b): return a.dist < b.dist)

    for conn in connections:
        var root_a = _get_group_root(room_groups, conn.a)
        var root_b = _get_group_root(room_groups, conn.b)

        # 3. No more than one path: Only connect if they are in different groups
        if root_a != root_b:
            # Check constraint 3a (Max Length) - skip if too far, unless regions are totally isolated
            if conn.dist > corridor_max_length and _are_groups_sustainable(room_groups):
                continue

            _connect_rooms_logic(grid, rooms[conn.a], rooms[conn.b], conn.dist)

            # Merge the groups
            _union_groups(room_groups, root_a, root_b)

    # --- Step 3: Add Walls ---
    _add_walls(grid)
    return {"grid": grid, "rooms": rooms}


# Helper for Union-Find logic (MST)
func _get_group_root(groups: Array, index: int) -> int:
    while groups[index] != index:
        index = groups[index]
    return index


func _union_groups(groups: Array, root_a: int, root_b: int):
    groups[root_b] = root_a


func _are_groups_sustainable(groups: Array) -> bool:
    # Optional check: returns true if we still have unconnected distinct islands
    var unique_roots = []
    for i in range(groups.size()):
        var root = _get_group_root(groups, i)
        if not root in unique_roots:
            unique_roots.append(root)
    return unique_roots.size() == 1


# Logic to choose between a corridor or a merge
func _connect_rooms_logic(grid: Array, room_a: Rect2i, room_b: Rect2i, dist: float):
    var center_a = room_a.get_center()
    var center_b = room_b.get_center()

    # 4. Merge logic
    # We calculate the distance between edges roughly.
    # If centers are very close (relative to size) or raw distance is low.
    if dist < (max(room_a.size.x, room_b.size.x) + merge_threshold):
        # Merge: Fill the rectangle defined by the two centers
        var min_x = min(center_a.x, center_b.x)
        var max_x = max(center_a.x, center_b.x)
        var min_y = min(center_a.y, center_b.y)
        var max_y = max(center_a.y, center_b.y)

        # Fill strictly between them with a bit of width
        for y in range(min_y - 1, max_y + 2):
            for x in range(min_x - 1, max_x + 2):
                if _is_in_bounds(x, y):
                    grid[y][x] = TileType.FLOOR
    else:
        # Standard Corridor
        _carve_corridor(grid, center_a, center_b)


func _paint_room(grid: Array, r: Rect2i):
    for y in range(r.position.y, r.end.y):
        for x in range(r.position.x, r.end.x):
            grid[y][x] = TileType.FLOOR


func _carve_corridor(grid: Array, from: Vector2, to: Vector2):
    # 3a. Corridor Width application
    var half_w = int(corridor_width / 2.0)

    var x1 = int(from.x)
    var y1 = int(from.y)
    var x2 = int(to.x)
    var y2 = int(to.y)

    # L-Shape Logic
    if randf() < 0.5:
        _carve_line(grid, x1, y1, x2, y1, half_w)  # Horizontal
        _carve_line(grid, x2, y1, x2, y2, half_w)  # Vertical
    else:
        _carve_line(grid, x1, y1, x1, y2, half_w)  # Vertical
        _carve_line(grid, x1, y2, x2, y2, half_w)  # Horizontal


func _carve_line(grid: Array, x1: int, y1: int, x2: int, y2: int, half_w: int):
    var start_x = min(x1, x2)
    var end_x = max(x1, x2)
    var start_y = min(y1, y2)
    var end_y = max(y1, y2)

    for y in range(start_y - half_w, end_y + half_w + 1):
        for x in range(start_x - half_w, end_x + half_w + 1):
            if _is_in_bounds(x, y):
                grid[y][x] = TileType.FLOOR


func _add_walls(grid: Array):
    for y in range(grid_height):
        for x in range(grid_width):
            if grid[y][x] == TileType.FLOOR:
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        var nx = x + dx
                        var ny = y + dy
                        if _is_in_bounds(nx, ny) and grid[ny][nx] == TileType.EMPTY:
                            grid[ny][nx] = TileType.WALL


func _is_in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < grid_width and y < grid_height
