extends Node2D

@export_group("Assets")
@export var tilemap: TileMapLayer
@export var player_scene: PackedScene
@export var spawner_scene: PackedScene

@export_group("Gameplay")
@export var floor_spawn_table: WeightedSpawnTable
@export var respawn_delay: float = 10.0

var generator = DungeonGenerator.new()


func _ready():
    var data = generator.generate()
    _render_tilemap(data.grid)
    _setup_entities(data.rooms)


func _render_tilemap(grid: Array):
    tilemap.clear()
    for y in range(DungeonGenerator.HEIGHT):
        for x in range(DungeonGenerator.WIDTH):
            match grid[y][x]:
                DungeonGenerator.TileType.FLOOR:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(8, 1))
                DungeonGenerator.TileType.WALL:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))


func _setup_entities(rooms: Array[Rect2]):
    # Place Player in first room
    var player = player_scene.instantiate()
    add_child(player)
    player.global_position = rooms[0].get_center() * 16

    # Place Spawners in other rooms
    for i in range(1, rooms.size()):
        _spawn_sequence(rooms[i].get_center() * 16)


func _spawn_sequence(pos: Vector2):
    if not spawner_scene or not floor_spawn_table:
        return

    var spawner = spawner_scene.instantiate()
    add_child(spawner)
    spawner.global_position = pos
    spawner.setup_spawner(floor_spawn_table)

    # Track when the spawner turns into an EnemyGroup
    spawner.tree_exited.connect(_on_spawner_spawned_group.bind(pos))
    spawner.start_spawn_sequence()


func _on_spawner_spawned_group(pos: Vector2):
    await get_tree().process_frame  # Wait for EnemyGroup to enter tree

    for child in get_children():
        if child is EnemyGroup and child.global_position.distance_to(pos) < 5.0:
            if not child.group_depleted.is_connected(_on_group_died):
                child.group_depleted.connect(_on_group_died.bind(pos))


func _on_group_died(pos: Vector2):
    await get_tree().create_timer(respawn_delay).timeout
    _spawn_sequence(pos)
