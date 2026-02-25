class_name DungeonManager
extends Node2D

signal dungeon_built(layout: DungeonLayout, registry: RoomRegistry)

const DOWNSAMPLE_FACTOR := 4.0

@export_group("UI")
@export var minimap_display: TextureRect
@export var minimap_icon_container: Control  # should be 40x40 overlay

@export_group("Dungeon Nodes")
@export var dungeon_builder: DungeonBuilder
@export var tilemap: TileMapLayer  # optional if builder already has it

@export_group("Assets")
@export var player_scene: PackedScene
@export var spawner_scene: PackedScene

@export_group("Dungeon Settings")
@export var map_width: int = 160
@export var map_height: int = 160
@export var room_count: int = 40
@export var room_min_size: Vector2i = Vector2i(10, 10)
@export var room_max_size: Vector2i = Vector2i(40, 40)
@export var corridor_width: int = 2
@export var tile_size: int = 16

@export_group("Generation")
@export var algorithm_seed: int = 0  # 0 = random
@export var algorithm: DungeonGenerator.Algorithm = DungeonGenerator.Algorithm.LEGACY_MST

@export_group("Gameplay")
# @export var floor_spawn_table: WeightedSpawnTable
@export var encounter_table: WeightedEncounterTable
@export var respawn_delay: float = 10.0

# runtime refs
var player_ref: Node2D
var player_icon: ColorRect
var enemy_icons: Dictionary = {}  # enemy node -> ColorRect

var _generator: DungeonGenerator
var _layout: DungeonLayout
var _registry: RoomRegistry
var _run_rng: RandomNumberGenerator


func _ready() -> void:
    # ---- validate ----
    if dungeon_builder == null:
        push_error("DungeonManager: dungeon_builder is not assigned.")
        return

    # Optional: allow assigning tilemap either on builder or manager
    if dungeon_builder.tilemap == null and tilemap != null:
        dungeon_builder.tilemap = tilemap
    dungeon_builder.tile_size = tile_size

    # Seed RNG for this run (used by encounter selection)
    _run_rng = RandomNumberGenerator.new()
    var run_seed := algorithm_seed
    if run_seed == 0:
        run_seed = randi()
    _run_rng.seed = run_seed

    # Init generator (RefCounted)
    _generator = DungeonGenerator.new()
    _generator.width = map_width
    _generator.height = map_height
    _generator.room_count = room_count
    _generator.room_min_size = room_min_size
    _generator.room_max_size = room_max_size
    _generator.corridor_width = corridor_width

    # Generate + build
    _layout = _generator.generate(run_seed, algorithm)
    _registry = dungeon_builder.build(_layout)

    _setup_entities_from_registry(_registry)
    _generate_minimap(_layout.grid)

    dungeon_built.emit(_layout, _registry)


func _process(_delta: float) -> void:
    if player_ref and is_instance_valid(player_ref):
        player_icon.position = _world_to_minimap(player_ref.global_position)

    _update_enemy_icons()


# ---------------------------
# Spawning / Entities
# ---------------------------


func _setup_entities_from_registry(registry: RoomRegistry) -> void:
    if registry == null:
        return

    var room_ids := registry.get_room_ids()
    if room_ids.is_empty():
        return

    # Put player in start room
    var start_id := registry.start_room_id
    if start_id < 0:
        start_id = int(room_ids[0])

    var player := player_scene.instantiate()
    add_child(player)
    player.global_position = registry.get_center_world(start_id)
    player_ref = player

    # Create player icon on minimap
    if minimap_icon_container != null:
        player_icon = ColorRect.new()
        player_icon.color = Color.GREEN
        player_icon.size = Vector2(2, 2)
        player_icon.z_index = 1
        minimap_icon_container.add_child(player_icon)

    # Spawners in other rooms (simple version)
    for rid in room_ids:
        if int(rid) == start_id:
            continue
        _spawn_sequence(registry.get_center_world(int(rid)))


func _spawn_sequence(pos: Vector2) -> void:
    if spawner_scene == null or encounter_table == null:
        return

    var spawner := spawner_scene.instantiate() as MobSpawner
    add_child(spawner)
    spawner.global_position = pos
    spawner.setup_spawner(encounter_table, _run_rng)

    # Old-but-working: when spawner exits, search for spawned group near pos
    spawner.tree_exited.connect(_on_spawner_spawned_group.bind(pos))
    spawner.start_spawn_sequence()


func _on_spawner_spawned_group(pos: Vector2) -> void:
    await get_tree().process_frame

    for child in get_children():
        if child is EnemyGroup and child.global_position.distance_to(pos) < 5.0:
            if not child.group_depleted.is_connected(_on_group_died):
                child.group_depleted.connect(_on_group_died.bind(pos))


func _on_group_died(pos: Vector2) -> void:
    await get_tree().create_timer(respawn_delay).timeout
    _spawn_sequence(pos)


# ---------------------------
# Minimap (same as your old logic)
# ---------------------------


func _generate_minimap(grid: Array) -> void:
    if minimap_display == null:
        return

    var downsample_factor := int(DOWNSAMPLE_FACTOR)
    var mini_w := int(map_width as float / downsample_factor)
    var mini_h := int(map_height as float / downsample_factor)
    var img := Image.create(mini_w, mini_h, false, Image.FORMAT_RGBA8)

    for my in range(mini_h):
        for mx in range(mini_w):
            var counts := {
                DungeonGenerator.TileType.EMPTY: 0,
                DungeonGenerator.TileType.WALL: 0,
                DungeonGenerator.TileType.FLOOR: 0,
                DungeonGenerator.TileType.CORRIDOR: 0,
            }

            for dy in range(downsample_factor):
                for dx in range(downsample_factor):
                    var gx := (mx * downsample_factor) + dx
                    var gy := (my * downsample_factor) + dy
                    if gy < map_height and gx < map_width:
                        var t: int = grid[gy][gx]
                        counts[t] += 1

            var winner := DungeonGenerator.TileType.EMPTY
            var max_count := -1

            var priority_check := [
                DungeonGenerator.TileType.CORRIDOR,
                DungeonGenerator.TileType.FLOOR,
                DungeonGenerator.TileType.WALL,
                DungeonGenerator.TileType.EMPTY,
            ]

            for t in priority_check:
                if counts[t] > max_count:
                    max_count = counts[t]
                    winner = t

            var pixel_color := Color(0, 0, 0, 0)
            match winner:
                DungeonGenerator.TileType.FLOOR, DungeonGenerator.TileType.CORRIDOR:
                    pixel_color = Color.DARK_GRAY
                DungeonGenerator.TileType.WALL, DungeonGenerator.TileType.EMPTY:
                    pixel_color = Color.BLACK

            img.set_pixel(mx, my, pixel_color)

    minimap_display.texture = ImageTexture.create_from_image(img)


func _world_to_minimap(world_pos: Vector2) -> Vector2:
    var grid_pos := world_pos / float(tile_size)
    return grid_pos / float(DOWNSAMPLE_FACTOR)


func _update_enemy_icons() -> void:
    if minimap_icon_container == null:
        return

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not enemy_icons.has(enemy):
            var new_icon := ColorRect.new()
            new_icon.color = Color.RED
            new_icon.size = Vector2(1, 1)
            minimap_icon_container.add_child(new_icon)
            enemy_icons[enemy] = new_icon

        enemy_icons[enemy].position = _world_to_minimap(enemy.global_position)

    # cleanup
    for enemy in enemy_icons.keys():
        if not is_instance_valid(enemy):
            enemy_icons[enemy].queue_free()
            enemy_icons.erase(enemy)
