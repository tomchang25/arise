extends Node2D

enum TileType { EMPTY, FLOOR, WALL }

const DUNGEON_WIDTH = 80
const DUNGEON_HEIGHT = 80

@export var tilemap: TileMapLayer
@export var player_scene: PackedScene

var dungeon_grid = []


func _ready():
    create_dungeon()


func generate_dungeon():
    dungeon_grid = []
    for y in DUNGEON_HEIGHT:
        dungeon_grid.append([])
        for x in DUNGEON_WIDTH:
            dungeon_grid[y].append(TileType.EMPTY)

    var rooms: Array[Rect2] = []
    var max_attempts = 100
    var tries = 0

    while rooms.size() < 10 and tries < max_attempts:
        var w = randi_range(8, 16)
        var h = randi_range(8, 16)
        var x = randi_range(1, DUNGEON_WIDTH - w - 1)
        var y = randi_range(1, DUNGEON_HEIGHT - h - 1)
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
                    dungeon_grid[iy][ix] = TileType.FLOOR
            if rooms.size() > 1:
                var prev = rooms[rooms.size() - 2].get_center()
                var curr = room.get_center()
                carve_corridor(prev, curr)

        tries += 1

    return rooms


func carve_corridor(from: Vector2, to: Vector2, width: int = 2):
    var min_width = -width / 2
    var max_width = width / 2

    if randf() < 0.5:
        for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
            for offset in range(min_width, max_width + 1):
                var y = from.y + offset
                if is_in_bounds(x, y):
                    dungeon_grid[y][x] = TileType.FLOOR

        for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
            for offset in range(min_width, max_width + 1):
                var x = to.x + offset
                if is_in_bounds(x, y):
                    dungeon_grid[y][x] = TileType.FLOOR
    else:
        for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
            for offset in range(min_width, max_width + 1):
                var x = from.x + offset
                if is_in_bounds(x, y):
                    dungeon_grid[y][x] = TileType.FLOOR

        for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
            for offset in range(min_width, max_width + 1):
                var y = to.y + offset
                if is_in_bounds(x, y):
                    dungeon_grid[y][x] = TileType.FLOOR


func is_in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < DUNGEON_WIDTH and y < DUNGEON_HEIGHT


func add_walls():
    for y in range(DUNGEON_HEIGHT):
        for x in range(DUNGEON_WIDTH):
            if dungeon_grid[y][x] == TileType.FLOOR:
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        var nx = x + dx
                        var ny = y + dy
                        if nx >= 0 and ny >= 0 and nx < DUNGEON_WIDTH and ny < DUNGEON_HEIGHT:
                            if dungeon_grid[ny][nx] == TileType.EMPTY:
                                dungeon_grid[ny][nx] = TileType.WALL


func render_dungeon():
    tilemap.clear()
    for y in range(DUNGEON_HEIGHT):
        for x in range(DUNGEON_WIDTH):
            var tile = dungeon_grid[y][x]
            match tile:
                TileType.FLOOR:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(8, 1))
                TileType.WALL:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))


func create_dungeon():
    place_player(generate_dungeon())
    add_walls()
    render_dungeon()


func place_player(rooms: Array[Rect2]):
    var player = player_scene.instantiate()
    add_child(player)

    player.position = rooms.pick_random().get_center() * 16
