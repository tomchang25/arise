class_name SlashAttackEffect
extends AttackEffect

@export_group("Slash Settings")
@export var radius: float = 45.0
@export var arc_angle: float = 90.0
@export var slash_width: float = 10.0
@export var segments: int = 20

@onready var line_2d: Line2D = $Line2D

@export_group("SFX")
@export var slash_audio: AudioEvent = null

# @export var swing_sfx_key: StringName = &"swing"
# @export var swing_sfx_stream: AudioStream
# @export var swing_sfx_volume_db: float = 0.0
# @export var swing_sfx_limited := true
# @export var swing_sfx_max_per_window := 4
# @export var swing_sfx_window_sec := 0.05


func setup(info: AttackInfo) -> void:
    super.setup(info)

    if hitbox:
        _generate_capsule_shape()

    _play_slash_vfx()
    _play_slash_sfx()


func _generate_capsule_shape() -> void:
    if hitbox.shape != null:
        return

    var capsule = CapsuleShape2D.new()

    var theta = deg_to_rad(arc_angle)
    var chord_length = 2 * radius * sin(theta / 2.0)

    capsule.radius = slash_width
    capsule.height = chord_length + (slash_width * 2)

    hitbox.shape = capsule


func _play_slash_vfx() -> void:
    line_2d.clear_points()
    line_2d.width = slash_width * 1.5

    var tween = create_tween()
    tween.tween_method(_update_slash_points, 0.0, 1.0, attack_lifetime * 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    tween.parallel().tween_property(line_2d, "width", 0.0, attack_lifetime * 0.6).set_delay(attack_lifetime * 0.4).set_trans(Tween.TRANS_SINE)


func _play_slash_sfx() -> void:
    AudioManager.play_event(slash_audio, global_position)


func _update_slash_points(progress: float) -> void:
    line_2d.clear_points()

    var current_total_arc = deg_to_rad(arc_angle) * progress
    var start_angle = -current_total_arc / 2.0

    for i in range(segments + 1):
        var t = float(i) / segments
        var angle = start_angle + (current_total_arc * t)

        var point_pos = (Vector2.from_angle(angle) * radius) - Vector2(radius, 0)
        line_2d.add_point(point_pos)
