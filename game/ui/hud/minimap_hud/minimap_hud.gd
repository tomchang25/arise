class_name MinimapHUD
extends Control
## Minimap HUD — 160×160 pixel overlay fixed to the top-right of the screen.
## Polls the scene tree every [member update_interval] seconds and redraws
## the player (cyan), enemy groups (red), and army groups (green).

# -------------------------
# Constants
# -------------------------

const MAP_SIZE := Vector2(80.0, 80.0)
const WORLD_MIN := Vector2(-800.0, -800.0)
const WORLD_SIZE := Vector2(1600.0, 1600.0)

const COLOR_BG := Color(0.0, 0.0, 0.0, 0.6)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.3)
const COLOR_PLAYER := Color.CYAN
const COLOR_ENEMY := Color.RED
const COLOR_ARMY := Color.GREEN

# -------------------------
# Exports
# -------------------------

## Seconds between full redraws of all tracked entities.
@export var update_interval: float = 0.5

# -------------------------
# Internal state
# -------------------------

var _timer: float = 0.0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    custom_minimum_size = MAP_SIZE
    queue_redraw()


func _process(delta: float) -> void:
    _timer += delta
    if _timer >= update_interval:
        _timer = 0.0
        queue_redraw()

# -------------------------
# Drawing
# -------------------------


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), COLOR_BG)
    draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), COLOR_BORDER, false)

    _draw_player()
    _draw_enemy_groups()
    _draw_army_groups()


func _draw_player() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if player == null:
        return
    var px := _world_to_map(player.global_position)
    draw_rect(Rect2(px, Vector2.ONE), COLOR_PLAYER)


func _draw_enemy_groups() -> void:
    for node in get_tree().get_nodes_in_group("enemy_group"):
        var eg := node as EnemyGroup
        if eg == null:
            continue
        var alive := eg.get_alive_members()
        if alive.is_empty():
            continue
        var center := eg.get_center()
        var px := _world_to_map(center)
        if alive.size() >= 10:
            draw_rect(Rect2(px - Vector2.ONE, Vector2(2.0, 2.0)), COLOR_ENEMY)
        else:
            draw_rect(Rect2(px, Vector2.ONE), COLOR_ENEMY)


func _draw_army_groups() -> void:
    for node in get_tree().get_nodes_in_group("army_group"):
        var ag := node as ArmyGroup
        if ag == null:
            continue
        var units := ag.get_all_units()
        if units.is_empty():
            continue
        var center := ag.global_position
        var px := _world_to_map(center)
        if units.size() >= 10:
            draw_rect(Rect2(px - Vector2.ONE, Vector2(2.0, 2.0)), COLOR_ARMY)
        else:
            draw_rect(Rect2(px, Vector2.ONE), COLOR_ARMY)

# -------------------------
# Internal
# -------------------------


## Maps a world-space position to a minimap pixel coordinate.
## World bounds (-800, -800)→(800, 800) map to pixel (0, 0)→(160, 160).
func _world_to_map(world_pos: Vector2) -> Vector2:
    return (world_pos - WORLD_MIN) / WORLD_SIZE * MAP_SIZE
