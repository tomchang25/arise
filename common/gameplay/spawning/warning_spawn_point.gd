class_name WarningSpawnPoint
extends SpawnPoint

@export_group("Warning")
@export var warning_time: float = 1.0
@export var warning_vfx_scene: PackedScene
@export var warning_sign_path: NodePath

var _warning_sign: CanvasItem
var _warning_timer: Timer


func _ready() -> void:
    if warning_sign_path != NodePath():
        _warning_sign = get_node_or_null(warning_sign_path) as CanvasItem
        if _warning_sign != null:
            _warning_sign.visible = false

    _warning_timer = get_node_or_null("WarningTimer") as Timer
    if _warning_timer == null:
        _warning_timer = Timer.new()
        _warning_timer.name = "WarningTimer"
        _warning_timer.one_shot = true
        add_child(_warning_timer)


func start() -> Node:
    await _play_warning()
    return execute()


func _play_warning() -> void:
    if warning_vfx_scene != null:
        var warning_vfx := warning_vfx_scene.instantiate()
        if warning_vfx != null:
            add_child(warning_vfx)

    if _warning_sign != null:
        _warning_sign.visible = true

    if warning_time > 0.0:
        _warning_timer.start(warning_time)
        await _warning_timer.timeout

    if _warning_sign != null:
        _warning_sign.visible = false
