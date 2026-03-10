class_name SpawnPoint
extends Node2D

signal placed(node: Node)

@export_group("Root")
@export var spawn_root_path: NodePath
@export var spawn_root_group: String = "world"

@export_group("Warning")
@export var warning_time: float = 2.0
@export var warning_vfx_scene: PackedScene  # optional (spawn a VFX node)
@export var use_child_warning_sign: bool = true # if you have a WarningSign node

@onready var _warning_sign: CanvasItem = get_node_or_null("WarningSign")
@onready var _timer: Timer = get_node_or_null("SpawnTimer")

var _action: SpawnAction
var _ctx: SpawnContext

func setup(action: SpawnAction, ctx: SpawnContext) -> void:
    _action = action
    _ctx = ctx

    # Resolve spawn_root into ctx if not set
    if _ctx != null and _ctx.spawn_root == null:
        _ctx.spawn_root = _resolve_spawn_root()

func start() -> void:
    if _action == null:
        push_warning("SpawnPoint: action is null")
        queue_free()
        return

    await _play_warning()
    var node := _action.execute(self, _ctx)
    if node != null:
        placed.emit(node)

    queue_free()

func _play_warning() -> void:
    # Optional: instance a warning VFX
    if warning_vfx_scene != null:
        var vfx := warning_vfx_scene.instantiate()
        add_child(vfx)

    # Optional: animate a child WarningSign if present
    if use_child_warning_sign and _warning_sign != null:
        _warning_sign.visible = true
        if _warning_sign.has_method("set_modulate"):
            _warning_sign.modulate.a = 0.0

        var tween := create_tween()
        tween.tween_property(_warning_sign, "modulate:a", 1.0, max(0.01, warning_time * 0.5))
        tween.tween_property(_warning_sign, "scale", Vector2(1.25, 1.25), max(0.01, warning_time))

    # Timer wait
    if warning_time <= 0.0:
        return

    if _timer == null:
        _timer = Timer.new()
        _timer.one_shot = true
        add_child(_timer)

    _timer.start(warning_time)
    await _timer.timeout

    if use_child_warning_sign and _warning_sign != null:
        _warning_sign.visible = false

func _resolve_spawn_root() -> Node:
    # 1) explicit nodepath
    if spawn_root_path != NodePath():
        var n := get_node_or_null(spawn_root_path)
        if n != null:
            return n

    # 2) group fallback
    var tree := get_tree()
    if tree != null and spawn_root_group != "":
        var g := tree.get_first_node_in_group(spawn_root_group)
        if g != null:
            return g

    # 3) last fallback: parent
    return get_parent()
