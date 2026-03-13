class_name ExtractionPoint
extends Area2D

signal extracted(player: Node)

@export var required_seconds: float = 3.0
@export var player_group: StringName = &"player"

var _timer: Timer
var _player_inside := false
var _done := false
var _player_ref: Node = null


func _ready() -> void:
    _timer = Timer.new()
    _timer.one_shot = true
    _timer.wait_time = maxf(0.01, required_seconds)
    _timer.timeout.connect(_on_timer_timeout)
    add_child(_timer)

    # Prefer body signals if Player is a PhysicsBody2D (CharacterBody2D, etc.)
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
    if _done:
        return
    if body != null and body.is_in_group(player_group):
        _start_progress(body)


func _on_body_exited(body: Node2D) -> void:
    if _done:
        return
    if body != null and body.is_in_group(player_group):
        _reset_progress()


func _start_progress(player: Node) -> void:
    if _player_inside:
        return
    _player_inside = true
    _player_ref = player

    _timer.stop()
    _timer.wait_time = maxf(0.01, required_seconds)
    _timer.start()

    print("[ExtractionPoint] Player entered. Holding for ", required_seconds, "s...")


func _reset_progress() -> void:
    if not _player_inside:
        return
    _player_inside = false
    _player_ref = null

    _timer.stop()  # stopping resets the countdown; next enter starts fresh
    print("[ExtractionPoint] Player left early. Timer reset.")


func _on_timer_timeout() -> void:
    if _done or not _player_inside:
        return

    _done = true
    print("[ExtractionPoint] Extraction complete!")
    extracted.emit(_player_ref)

    queue_free()
