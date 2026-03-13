extends Node2D

@export_group("Debug")
@export var move_speed: float = 0.0
@export var rotate_speed: float = 0.0
@export var lifetime: float = 0.0
@export var label: Label

var _life_left: float = 0.0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _life_left = lifetime
    _update_label()


func _process(delta: float) -> void:
    if rotate_speed != 0.0:
        rotation += rotate_speed * delta

    if move_speed != 0.0:
        global_position += Vector2.RIGHT.rotated(global_rotation) * move_speed * delta

    if _life_left > 0.0:
        _life_left -= delta
        if _life_left <= 0.0:
            queue_free()


# -------------------------
# Debug
# -------------------------


func set_debug_text(text: String) -> void:
    if label == null:
        return

    label.text = text


func _update_label() -> void:
    if label == null:
        return

    label.text = name
