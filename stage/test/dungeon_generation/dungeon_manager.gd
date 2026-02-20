extends Node2D

const DOWNSAMPLE_FACTOR = 4.0

@export_group("UI")
@export var minimap_display: TextureRect  # Assign your UI Minimap here
@export var minimap_icon_container: Control  # A Control node sized 40x40 on top of the minimap
# @export var player_icon_scene: PackedScene  # A small Sprite2D or ColorRect
# @export var enemy_icon_scene: PackedScene  # A small red Sprite2D or ColorRect

@export_group("Assets")
@export var tilemap: TileMapLayer
@export var player_scene: PackedScene
@export var spawner_scene: PackedScene

@export_group("Dungeon Settings")
@export var map_width: int = 160
@export var map_height: int = 160
@export var room_count: int = 40
@export var room_min_size: Vector2i = Vector2i(10, 10)
@export var room_max_size: Vector2i = Vector2i(40, 40)
@export var corridor_width: int = 2
@export var tile_size: int = 16  # Pixel size of your tiles (e.g. 16x16)

@export_group("Gameplay")
@export var floor_spawn_table: WeightedSpawnTable
@export var respawn_delay: float = 10.0

var generator = DungeonGenerator.new()

var player_ref: Node2D
var player_icon: ColorRect
var enemy_icons: Dictionary = {}  # Key: EnemyGroup, Value: ColorRect


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

    # Generate the minimap texture
    _generate_minimap(data.grid)


func _process(_delta: float):
    if player_ref:
        player_icon.position = _world_to_minimap(player_ref.global_position)

    _update_enemy_icons()


func _render_tilemap(grid: Array):
    tilemap.clear()
    # Use the dynamic width/height, not static constants
    for y in range(map_height):
        for x in range(map_width):
            match grid[y][x]:
                DungeonGenerator.TileType.FLOOR:
                    tilemap.set_cell(Vector2i(x, y), 0, Vector2i(8, 1))
                DungeonGenerator.TileType.CORRIDOR:
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

    player_ref = player

    # Create the player's icon on the minimap
    player_icon = ColorRect.new()
    player_icon.color = Color.GREEN
    player_icon.size = Vector2(2, 2)  # 2x2 pixels on the minimap
    player_icon.z_index = 1  # Keep player on top of enemies
    minimap_icon_container.add_child(player_icon)


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


## Minimap
func _generate_minimap(grid: Array):
    var downsample_factor = DOWNSAMPLE_FACTOR
    var mini_w = map_width / downsample_factor
    var mini_h = map_height / downsample_factor
    var img = Image.create(mini_w, mini_h, false, Image.FORMAT_RGBA8)

    for my in range(mini_h):
        for mx in range(mini_w):
            # 1. Count every tile type in the 4x4 block
            var counts = {
                DungeonGenerator.TileType.EMPTY: 0, DungeonGenerator.TileType.WALL: 0, DungeonGenerator.TileType.FLOOR: 0, DungeonGenerator.TileType.CORRIDOR: 0
            }

            for dy in range(downsample_factor):
                for dx in range(downsample_factor):
                    var gx = (mx * downsample_factor) + dx
                    var gy = (my * downsample_factor) + dy

                    if gy < map_height and gx < map_width:
                        var type = grid[gy][gx]
                        counts[type] += 1

            # 2. Determine the "Winner" (Highest Count)
            var winner = DungeonGenerator.TileType.EMPTY
            var max_count = -1

            # Priority tie-breaker: Rooms and Corridors are checked first
            # so they win ties against Walls or Empty space.
            var priority_check = [
                DungeonGenerator.TileType.CORRIDOR, DungeonGenerator.TileType.FLOOR, DungeonGenerator.TileType.WALL, DungeonGenerator.TileType.EMPTY
            ]

            for type in priority_check:
                if counts[type] > max_count:
                    max_count = counts[type]
                    winner = type

            # 3. Assign color based on the winning type
            var pixel_color = Color(0, 0, 0, 0)
            match winner:
                DungeonGenerator.TileType.FLOOR:
                    pixel_color = Color.DARK_GRAY
                DungeonGenerator.TileType.CORRIDOR:
                    pixel_color = Color.DARK_GRAY
                DungeonGenerator.TileType.EMPTY:
                    pixel_color = Color.BLACK
                DungeonGenerator.TileType.WALL:
                    pixel_color = Color.BLACK

            img.set_pixel(mx, my, pixel_color)

    var tex = ImageTexture.create_from_image(img)
    minimap_display.texture = tex


## Logic to convert coordinates
func _world_to_minimap(world_pos: Vector2) -> Vector2:
    var grid_pos = world_pos / tile_size  # Convert to 0-160 range
    return grid_pos / DOWNSAMPLE_FACTOR  # Convert to 0-40 range


## Logic to track and move enemy groups
func _update_enemy_icons():
    # for child in get_children():
    #     if child is EnemyGroup:
    #         if not enemy_icons.has(child):
    #             # Create Enemy Icon via Code
    #             var new_icon = ColorRect.new()
    #             new_icon.color = Color.RED
    #             new_icon.size = Vector2(1, 1)  # 1x1 pixel
    #             minimap_icon_container.add_child(new_icon)
    #             enemy_icons[child] = new_icon

    #         # Update position (using the conversion function from before)
    #         enemy_icons[child].position = _world_to_minimap(child.global_position)

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not enemy_icons.has(enemy):
            # Create Enemy Icon via Code
            var new_icon = ColorRect.new()
            new_icon.color = Color.RED
            new_icon.size = Vector2(1, 1)  # 1x1 pixel
            minimap_icon_container.add_child(new_icon)
            enemy_icons[enemy] = new_icon

        # Update position (using the conversion function from before)
        enemy_icons[enemy].position = _world_to_minimap(enemy.global_position)

    # Cleanup dead groups
    for group in enemy_icons.keys():
        if not is_instance_valid(group):
            enemy_icons[group].queue_free()
            enemy_icons.erase(group)


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
