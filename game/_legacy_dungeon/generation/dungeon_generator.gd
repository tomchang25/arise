class_name DungeonGenerator
extends RefCounted

enum Algorithm { LEGACY_MST, OVERLAP_MERGE }
enum TileType { EMPTY, FLOOR, WALL, CORRIDOR }

# Parameters (you can wire these from DungeonManager or a config resource)
var width: int = 160
var height: int = 160
var room_count: int = 40
var room_min_size: Vector2i = Vector2i(10, 10)
var room_max_size: Vector2i = Vector2i(40, 40)
var corridor_width: int = 2

# Legacy extras
var corridor_max_length: int = 50
var merge_threshold: int = 3

# New algorithm tuning (overlap merge)
var max_attempts: int = 300
var allow_rooms_touch_border: bool = false


func generate(generator_seed: int = randi(), algorithm: Algorithm = Algorithm.LEGACY_MST) -> DungeonLayout:
    var rng := RandomNumberGenerator.new()
    rng.seed = generator_seed

    match algorithm:
        Algorithm.OVERLAP_MERGE:
            return _generate_overlap_merge(rng)
        _:
            return _generate_legacy_mst(rng)


# ============================================================
# Common helpers
# ============================================================


func _make_empty_grid() -> Array:
    var g := []
    g.resize(height)
    for y in range(height):
        var row := []
        row.resize(width)
        for x in range(width):
            row[x] = TileType.EMPTY
        g[y] = row
    return g


func _is_in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < width and y < height


func _paint_room_floor(grid: Array, r: Rect2i) -> void:
    for y in range(r.position.y, r.end.y):
        for x in range(r.position.x, r.end.x):
            if _is_in_bounds(x, y):
                grid[y][x] = TileType.FLOOR


func _add_walls(grid: Array) -> void:
    for y in range(height):
        for x in range(width):
            var t = grid[y][x]
            if t == TileType.FLOOR or t == TileType.CORRIDOR:
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        var nx := x + dx
                        var ny := y + dy
                        if _is_in_bounds(nx, ny) and grid[ny][nx] == TileType.EMPTY:
                            grid[ny][nx] = TileType.WALL


func _carve_corridor(grid: Array, from: Vector2i, to: Vector2i, rng: RandomNumberGenerator) -> void:
    var half_w := int(corridor_width / 2.0)

    var x1 := from.x
    var y1 := from.y
    var x2 := to.x
    var y2 := to.y

    # L-shape; randomize direction for variety
    if rng.randf() < 0.5:
        _carve_line(grid, x1, y1, x2, y1, half_w)
        _carve_line(grid, x2, y1, x2, y2, half_w)
    else:
        _carve_line(grid, x1, y1, x1, y2, half_w)
        _carve_line(grid, x1, y2, x2, y2, half_w)


func _carve_line(grid: Array, x1: int, y1: int, x2: int, y2: int, half_w: int) -> void:
    var start_x = min(x1, x2)
    var end_x = max(x1, x2)
    var start_y = min(y1, y2)
    var end_y = max(y1, y2)

    for y in range(start_y - half_w, end_y + half_w + 1):
        for x in range(start_x - half_w, end_x + half_w + 1):
            if _is_in_bounds(x, y):
                # don't overwrite floors (keeps room identity nice)
                if grid[y][x] == TileType.EMPTY or grid[y][x] == TileType.WALL:
                    grid[y][x] = TileType.CORRIDOR


# Union-find for MST
func _get_group_root(groups: Array, index: int) -> int:
    while groups[index] != index:
        index = groups[index]
    return index


func _union_groups(groups: Array, root_a: int, root_b: int) -> void:
    groups[root_b] = root_a


# ============================================================
# Algorithm A: Legacy (your current style)
# ============================================================


func _generate_legacy_mst(rng: RandomNumberGenerator) -> DungeonLayout:
    var grid := _make_empty_grid()
    var rooms: Array[Rect2i] = []

    var attempts := 0
    while rooms.size() < room_count and attempts < max_attempts:
        var w := rng.randi_range(room_min_size.x, room_max_size.x)
        var h := rng.randi_range(room_min_size.y, room_max_size.y)

        var margin := 1
        var x_min := margin
        var y_min := margin
        var x_max := width - w - margin
        var y_max := height - h - margin

        if allow_rooms_touch_border:
            x_min = 0
            y_min = 0
            x_max = width - w
            y_max = height - h

        if x_max < x_min or y_max < y_min:
            break

        var x := rng.randi_range(x_min, x_max)
        var y := rng.randi_range(y_min, y_max)
        var new_room := Rect2i(x, y, w, h)

        var overlaps := false
        for other in rooms:
            if new_room.grow(1).intersects(other):
                overlaps = true
                break
        if not overlaps:
            rooms.append(new_room)
            _paint_room_floor(grid, new_room)

        attempts += 1

    # MST connect room centers
    var groups := []
    groups.resize(rooms.size())
    for i in range(rooms.size()):
        groups[i] = i

    var connections := []
    for i in range(rooms.size()):
        for j in range(i + 1, rooms.size()):
            var ca := Vector2(rooms[i].get_center())
            var cb := Vector2(rooms[j].get_center())
            var dist := ca.distance_to(cb)
            connections.append({"a": i, "b": j, "dist": dist})

    connections.sort_custom(func(a, b): return a.dist < b.dist)

    for conn in connections:
        var ra := _get_group_root(groups, conn.a)
        var rb := _get_group_root(groups, conn.b)
        if ra == rb:
            continue

        # legacy constraint: skip too-far unless needed
        if conn.dist > corridor_max_length:
            # if skipping would isolate forever, you could relax this—keeping legacy behavior simple:
            pass

        var a_center := Vector2i(rooms[conn.a].get_center())
        var b_center := Vector2i(rooms[conn.b].get_center())

        # legacy “merge-ish” if close
        if conn.dist < (max(rooms[conn.a].size.x, rooms[conn.b].size.x) + merge_threshold):
            var min_x = min(a_center.x, b_center.x)
            var max_x = max(a_center.x, b_center.x)
            var min_y = min(a_center.y, b_center.y)
            var max_y = max(a_center.y, b_center.y)
            for y in range(min_y - 1, max_y + 2):
                for x in range(min_x - 1, max_x + 2):
                    if _is_in_bounds(x, y):
                        grid[y][x] = TileType.FLOOR
        else:
            _carve_corridor(grid, a_center, b_center, rng)

        _union_groups(groups, ra, rb)

    _add_walls(grid)

    # Legacy returns "rooms" as-is (Rect2i list). Convert them into merged-like RoomInfos without indices.
    var layout := DungeonLayout.new()
    layout.width = width
    layout.height = height
    layout.grid = grid

    layout.rooms = []
    for i in range(rooms.size()):
        var r := rooms[i]
        var center := Vector2(r.get_center())
        layout.rooms.append(DungeonLayout.RoomInfo.new(i, r, center, r.size.x * r.size.y, PackedInt32Array()))
    layout.start_room_id = 0 if layout.rooms.size() > 0 else -1
    return layout


# ============================================================
# Algorithm B: Overlap → merge connected → connect big rooms
# ============================================================


func _generate_overlap_merge(rng: RandomNumberGenerator) -> DungeonLayout:
    var grid := _make_empty_grid()

    # Step 1: generate N overlapping rooms (rects) and paint floors
    var rects: Array[Rect2i] = []
    var attempts := 0
    while rects.size() < room_count and attempts < max_attempts:
        var w := rng.randi_range(room_min_size.x, room_max_size.x)
        var h := rng.randi_range(room_min_size.y, room_max_size.y)

        var margin := 1
        var x_min := margin
        var y_min := margin
        var x_max := width - w - margin
        var y_max := height - h - margin
        if allow_rooms_touch_border:
            x_min = 0
            y_min = 0
            x_max = width - w
            y_max = height - h

        if x_max < x_min or y_max < y_min:
            break

        var x := rng.randi_range(x_min, x_max)
        var y := rng.randi_range(y_min, y_max)
        var r := Rect2i(x, y, w, h)

        rects.append(r)
        _paint_room_floor(grid, r)
        attempts += 1

    # Step 2: connected components on FLOOR (4-neighbor) => merged big rooms
    var rooms := _extract_rooms_from_floor_components(grid)

    # If no rooms, still return layout
    var layout := DungeonLayout.new()
    layout.width = width
    layout.height = height
    layout.grid = grid
    layout.rooms = rooms
    layout.start_room_id = 0 if rooms.size() > 0 else -1

    # Step 3: connect big rooms with corridors (MST on centers)
    _connect_big_rooms_mst(grid, rooms, rng)

    # Step 4: add walls
    _add_walls(grid)

    return layout


func _extract_rooms_from_floor_components(grid: Array) -> Array[DungeonLayout.RoomInfo]:
    var visited := []
    visited.resize(height)
    for y in range(height):
        var row := PackedByteArray()
        row.resize(width)
        visited[y] = row

    var rooms: Array[DungeonLayout.RoomInfo] = []
    var room_id := 0

    for y in range(height):
        for x in range(width):
            if visited[y][x] == 1:
                continue
            if grid[y][x] != TileType.FLOOR:
                continue

            # BFS flood fill
            var q: Array[Vector2i] = [Vector2i(x, y)]
            visited[y][x] = 1

            var min_x := x
            var max_x := x
            var min_y := y
            var max_y := y
            var sum := Vector2.ZERO
            var count := 0
            var indices := PackedInt32Array()

            while q.size() > 0:
                var p: Vector2i = q.pop_back()
                count += 1
                sum += Vector2(p)
                indices.append(p.y * width + p.x)

                min_x = min(min_x, p.x)
                max_x = max(max_x, p.x)
                min_y = min(min_y, p.y)
                max_y = max(max_y, p.y)

                # 4-neighbor
                var neighbors := [
                    Vector2i(p.x + 1, p.y),
                    Vector2i(p.x - 1, p.y),
                    Vector2i(p.x, p.y + 1),
                    Vector2i(p.x, p.y - 1),
                ]
                for n in neighbors:
                    if not _is_in_bounds(n.x, n.y):
                        continue
                    if visited[n.y][n.x] == 1:
                        continue
                    if grid[n.y][n.x] != TileType.FLOOR:
                        continue
                    visited[n.y][n.x] = 1
                    q.append(n)

            var bounds := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
            var center: Vector2 = sum / max(1, count)

            rooms.append(DungeonLayout.RoomInfo.new(room_id, bounds, center, count, indices))
            room_id += 1

    return rooms


func _connect_big_rooms_mst(grid: Array, rooms: Array[DungeonLayout.RoomInfo], rng: RandomNumberGenerator) -> void:
    if rooms.size() <= 1:
        return

    var groups := []
    groups.resize(rooms.size())
    for i in range(rooms.size()):
        groups[i] = i

    var connections := []
    for i in range(rooms.size()):
        for j in range(i + 1, rooms.size()):
            var ca := rooms[i].center
            var cb := rooms[j].center
            var dist := ca.distance_to(cb)
            connections.append({"a": i, "b": j, "dist": dist})

    connections.sort_custom(func(a, b): return a.dist < b.dist)

    for conn in connections:
        var ra := _get_group_root(groups, conn.a)
        var rb := _get_group_root(groups, conn.b)
        if ra == rb:
            continue

        var a_center := Vector2i(round(rooms[conn.a].center.x), round(rooms[conn.a].center.y))
        var b_center := Vector2i(round(rooms[conn.b].center.x), round(rooms[conn.b].center.y))

        _carve_corridor(grid, a_center, b_center, rng)
        _union_groups(groups, ra, rb)
