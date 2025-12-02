class_name Spawner
extends Area2D

@export var sprite: Sprite2D

@export var spawn_blueprint: PackedScene

@export var spawn_time: float = 3.0
@export var spawn_number: int = 1

@onready var progress_ui: ProgressBar = $ProgressBar

var enabled := true
var is_active := false

var spawn_progress: float = 0.0


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _on_body_entered(body: PhysicsBody2D):
    if body is Player:
        is_active = true


func _on_body_exited(body: PhysicsBody2D):
    if body is Player:
        is_active = false


func _process(delta):
    if not enabled or not is_active:
        _reset_progress()
        return

    if Input.is_action_pressed("spawn"):
        spawn_progress = min(spawn_progress + delta, spawn_time)
        if spawn_progress >= spawn_time:
            for _i in range(spawn_number):
                spawn()

        _update_progress_ui()
    else:
        _reset_progress()


func _update_progress_ui():
    if progress_ui:
        var normalized_progress = spawn_progress / spawn_time * 100
        progress_ui.value = normalized_progress


func _reset_progress():
    # Progress remains, only reset the internal spawning state
    _update_progress_ui()


func spawn():
    if not enabled or not is_active:
        return

    var spawn_instance = spawn_blueprint.instantiate() as CharacterBody2D
    spawn_instance.global_position = global_position
    get_tree().get_first_node_in_group("army_handler").call_deferred("add_child", spawn_instance)

    spawn_progress = 0.0
    _update_progress_ui()

    queue_free()
