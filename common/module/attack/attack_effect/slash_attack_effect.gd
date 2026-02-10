class_name SlashAttackEffect
extends AttackEffect

@export_group("Slash Settings")
@export var radius: float = 45.0  # 弧線的彎曲半徑
@export var arc_angle: float = 90.0  # 揮砍總角度
@export var slash_width: float = 10.0  # 物理判定寬度
@export var segments: int = 20

@onready var line_2d: Line2D = $Line2D


func setup(info: AttackInfo) -> void:
    super.setup(info)

    # 1. 產生與弧線範圍匹配的物理形狀
    if hitbox:
        _generate_capsule_shape()

    # 2. 啟動動畫
    _play_slash_vfx()


func _generate_capsule_shape() -> void:
    if hitbox.shape != null:
        return

    var capsule = CapsuleShape2D.new()

    # 計算弦長 (弧線兩端的直線距離) 作為膠囊體的高度
    var theta = deg_to_rad(arc_angle)
    var chord_length = 2 * radius * sin(theta / 2.0)

    capsule.radius = slash_width
    capsule.height = chord_length + (slash_width * 2)

    hitbox.shape = capsule
    hitbox._setup_collision_shape()


func _play_slash_vfx() -> void:
    line_2d.clear_points()
    line_2d.width = slash_width * 1.5

    var tween = create_tween()
    tween.tween_method(_update_slash_points, 0.0, 1.0, attack_lifetime * 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    tween.parallel().tween_property(line_2d, "width", 0.0, attack_lifetime * 0.6).set_delay(attack_lifetime * 0.4).set_trans(Tween.TRANS_SINE)


func _update_slash_points(progress: float) -> void:
    line_2d.clear_points()

    var current_total_arc = deg_to_rad(arc_angle) * progress
    var start_angle = -current_total_arc / 2.0

    for i in range(segments + 1):
        var t = float(i) / segments
        var angle = start_angle + (current_total_arc * t)

        var point_pos = (Vector2.from_angle(angle) * radius) - Vector2(radius, 0)
        line_2d.add_point(point_pos)
