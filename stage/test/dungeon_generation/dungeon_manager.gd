extends Node2D

@export_group("Assets")
@export var tilemap: TileMapLayer
@export var player_scene: PackedScene
@export var spawner_scene: PackedScene

@export_group("Dungeon Settings")
@export var map_width: int = 160
@export var map_height: int = 160
@export var room_count: int = 20
@export var room_min_size: Vector2i = Vector2i(20, 20)
@export var room_max_size: Vector2i = Vector2i(40, 40)
@export var corridor_width: int = 2
@export var tile_size: int = 16  # Pixel size of your tiles (e.g. 16x16)

@export_group("Gameplay")
@export var floor_spawn_table: WeightedSpawnTable
@export var respawn_delay: float = 10.0

var generator = DungeonGenerator.new()


func _ready():
    # 1. Configure the generator instance with our Manager's exports
    generator.grid_width = map_width
    generator.grid_height = map_height
    generator.room_count = room_count
    generator.room_min_size = room_min_size
    generator.room_max_size = room_max_size
    generator.corridor_width = corridor_width

    # 2. Generate
    var data = generator.generate()
    _render_tilemap(data.grid)
    _setup_entities(data.rooms)


func _render_tilemap(grid: Array):
    tilemap.clear()
    # Use the dynamic width/height, not static constants
    for y in range(map_height):
        for x in range(map_width):
            match grid[y][x]:
                DungeonGenerator.TileType.FLOOR:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(8, 1))
                DungeonGenerator.TileType.WALL:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))


func _setup_entities(rooms: Array):
    if rooms.is_empty():
        return

    # Place Player in the center of the first room
    # Rect2i.get_center() returns a Vector2, so we can multiply directly
    var player = player_scene.instantiate()
    add_child(player)
    player.global_position = rooms[0].get_center() * tile_size

    # Place Spawners in the remaining rooms
    for i in range(1, rooms.size()):
        _spawn_sequence(rooms[i].get_center() * tile_size)


func _spawn_sequence(pos: Vector2):
    if not spawner_scene or not floor_spawn_table:
        return

    var spawner := spawner_scene.instantiate()
    add_child(spawner)
    spawner.global_position = pos
    spawner.setup_spawner(floor_spawn_table)

    # Track when the spawner turns into an EnemyGroup
    spawner.tree_exited.connect(_on_spawner_spawned_group.bind(pos))
    spawner.start_spawn_sequence()


func _on_spawner_spawned_group(pos: Vector2):
    await get_tree().process_frame  # Wait for EnemyGroup to enter tree

    for child in get_children():
        # Using class_name check provided in original code
        if child is EnemyGroup and child.global_position.distance_to(pos) < 5.0:
            if not child.group_depleted.is_connected(_on_group_died):
                child.group_depleted.connect(_on_group_died.bind(pos))


func _on_group_died(pos: Vector2):
    await get_tree().create_timer(respawn_delay).timeout
    _spawn_sequence(pos)
