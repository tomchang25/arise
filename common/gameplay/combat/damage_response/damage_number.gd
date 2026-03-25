class_name DamageNumber
extends Node2D

@export var label_path: NodePath = ^"Label"

@export_group("Motion")
@export var lifetime: float = 0.65
@export var float_distance: float = 26.0
@export var drift_x_range: float = 12.0
@export var pop_scale: float = 1.2

@export_group("Normal Style")
@export var normal_color: Color = Color(1, 1, 1, 1)
@export var normal_outline_color: Color = Color(0, 0, 0, 1)
@export var normal_font_size: int = 14
@export var normal_outline_size: int = 2

@export_group("Crit Style")
@export var crit_color: Color = Color(1.0, 0.85, 0.2, 1.0)
@export var crit_outline_color: Color = Color(0.35, 0.05, 0.05, 1.0)
@export var crit_font_size: int = 18
@export var crit_outline_size: int = 3
@export var crit_pop_scale: float = 1.35

var _label: Label
var _tween: Tween


func _ready() -> void:
    _label = get_node_or_null(label_path) as Label
    if _label == null:
        push_warning("DamageNumber: Label not found at path: %s" % [label_path])
        return

    if _label.label_settings == null:
        _label.label_settings = LabelSettings.new()

    modulate = Color(1, 1, 1, 1)


func setup(amount: float, is_crit: bool = false) -> void:
    if _label == null:
        _label = get_node_or_null(label_path) as Label
        if _label == null:
            queue_free()
            return

    _label.text = str(max(0, int(round(amount))))
    _apply_style(is_crit)
    _play_anim(is_crit)


func reset() -> void:
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = null
    scale = Vector2.ONE
    modulate = Color(1, 1, 1, 1)
    rotation = 0.0
    global_position = Vector2.ZERO
    visible = true


func set_enabled(value: bool) -> void:
    if not value:
        if _tween and _tween.is_valid():
            _tween.kill()
        _tween = null
        visible = false


func _on_tween_finished() -> void:
    NodeRegistry.release(self)


func _apply_style(is_crit: bool) -> void:
    var settings := _label.label_settings
    if settings == null:
        settings = LabelSettings.new()
        _label.label_settings = settings

    if is_crit:
        settings.font_color = crit_color
        settings.outline_color = crit_outline_color
        settings.font_size = crit_font_size
        settings.outline_size = crit_outline_size
    else:
        settings.font_color = normal_color
        settings.outline_color = normal_outline_color
        settings.font_size = normal_font_size
        settings.outline_size = normal_outline_size


func _play_anim(is_crit: bool) -> void:
    if _tween and _tween.is_valid():
        _tween.kill()

    var start_pos := position
    var end_pos := start_pos + Vector2(randf_range(-drift_x_range, drift_x_range), -float_distance)
    var start_scale := Vector2.ONE
    var peak_scale := Vector2.ONE * (crit_pop_scale if is_crit else pop_scale)

    scale = start_scale
    modulate.a = 1.0
    rotation = deg_to_rad(randf_range(-4.0, 4.0))

    _tween = create_tween()
    _tween.set_parallel(true)

    _tween.tween_property(
        self,
        "position",
        end_pos,
        lifetime,
    ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    _tween.tween_property(
        self,
        "scale",
        peak_scale,
        0.12,
    ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    _tween.tween_property(
        self,
        "scale",
        Vector2.ONE,
        lifetime - 0.12,
    ).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    _tween.tween_property(
        self,
        "modulate:a",
        0.0,
        lifetime * 0.55,
    ).set_delay(lifetime * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    _tween.finished.connect(_on_tween_finished)
