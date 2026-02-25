# res://game/dungeon/runtime/dungeon_builder.gd
class_name DungeonBuilder
extends Node

@export var tilemap: TileMapLayer
@export var tile_size: int = 16

# Adjust these atlas coords to match your tileset
@export var floor_atlas: Vector2i = Vector2i(8, 1)
@export var wall_atlas: Vector2i = Vector2i(1, 0)
@export var source_id: int = 0


func build(layout: DungeonLayout) -> RoomRegistry:
    if tilemap == null:
        push_error("DungeonBuilder: tilemap is not assigned.")
        return null

    _render_tilemap(layout)

    var registry := RoomRegistry.new()
    registry.tile_size = tile_size
    registry.start_room_id = layout.start_room_id

    for r in layout.rooms:
        registry.add_room(r.id, r.bounds, r.center, r.cell_indices)

    return registry


func _render_tilemap(layout: DungeonLayout) -> void:
    tilemap.clear()

    for y in range(layout.height):
        for x in range(layout.width):
            var t: int = layout.grid[y][x]
            match t:
                DungeonLayout.TileType.FLOOR, DungeonLayout.TileType.CORRIDOR:
                    tilemap.set_cell(Vector2i(x, y), source_id, floor_atlas)
                DungeonLayout.TileType.WALL:
                    tilemap.set_cell(Vector2i(x, y), source_id, wall_atlas)
                _:
                    pass
