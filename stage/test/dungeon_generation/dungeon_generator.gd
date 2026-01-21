class_name DungeonGenerator
extends Node

enum TileType { EMPTY, FLOOR, WALL }

const WIDTH = 80
const HEIGHT = 80


func generate() -> Dictionary:
    var grid = []
    for y in HEIGHT:
        grid.append([])
        for x in WIDTH:
            grid[y].append(TileType.EMPTY)

    var rooms: Array[Rect2] = []
    var max_attempts = 100
    var tries = 0

    while rooms.size() < 10 and tries < max_attempts:
        var w = randi_range(8, 16)
        var h = randi_range(8, 16)
        var x = randi_range(1, WIDTH - w - 1)
        var y = randi_range(1, HEIGHT - h - 1)
        var room = Rect2(x, y, w, h)

        var overlaps = false
        for other in rooms:
            if room.grow(1).intersects(other):
                overlaps = true
                break

        if !overlaps:
            rooms.append(room)
            for iy in range(y, y + h):
                for ix in range(x, x + w):
                    grid[iy][ix] = TileType.FLOOR

            if rooms.size() > 1:
                var prev = rooms[rooms.size() - 2].get_center()
                var curr = room.get_center()
                _carve_corridor(grid, prev, curr)
        tries += 1

    _add_walls(grid)
    return {"grid": grid, "rooms": rooms}


func _carve_corridor(grid: Array, from: Vector2, to: Vector2):
    var width = 2
    var min_w = -width / 2
    var max_w = width / 2

    var horizontal_first = randf() < 0.5
    if horizontal_first:
        for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
            for offset in range(min_w, max_w + 1):
                if _is_in_bounds(x, from.y + offset):
                    grid[int(from.y + offset)][x] = TileType.FLOOR
        for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
            for offset in range(min_w, max_w + 1):
                if _is_in_bounds(to.x + offset, y):
                    grid[y][int(to.x + offset)] = TileType.FLOOR
    else:
        for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
            for offset in range(min_w, max_w + 1):
                if _is_in_bounds(from.x + offset, y):
                    grid[y][int(from.x + offset)] = TileType.FLOOR
        for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
            for offset in range(min_w, max_w + 1):
                if _is_in_bounds(x, to.y + offset):
                    grid[int(to.y + offset)][x] = TileType.FLOOR


func _add_walls(grid: Array):
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if grid[y][x] == TileType.FLOOR:
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        var nx = x + dx
                        var ny = y + dy
                        if _is_in_bounds(nx, ny) and grid[ny][nx] == TileType.EMPTY:
                            grid[ny][nx] = TileType.WALL


func _is_in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT
