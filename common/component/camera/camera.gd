extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 2.0
@export var zoom_duration: float = 0.2  # How long the smoothing takes

var target_zoom: float = 0.2


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            add_zoom(zoom_speed)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            add_zoom(-zoom_speed)


func add_zoom(delta: float) -> void:
    # Update the target value
    target_zoom = clamp(target_zoom + delta, min_zoom, max_zoom)

    # Create a tween to animate 'zoom' property to the target
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)  # Mathematical curve for easing
    tween.set_ease(Tween.EASE_OUT)  # Slows down as it reaches the target
    tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), zoom_duration)
