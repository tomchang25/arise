class_name RpgDelivery
extends AttackDelivery

var _speed: float = 500.0
var _direction: Vector2 = Vector2.RIGHT
var _travel_distance: float = 0.0


func setup(ctx: EffectContext) -> void:
    _wait_for_effect = true
    super(ctx)
    arm()


func launch(direction: Vector2, speed: float, travel_distance: float) -> void:
    _direction = direction.normalized()
    _speed = speed
    _travel_distance = travel_distance
    rotation = _direction.angle()


func trigger() -> void:
    super.trigger()
    set_physics_process(false)


func _physics_process(delta: float) -> void:
    var collision := move_and_collide(_direction * _speed * delta)
    if collision:
        _on_wall_hit()
        return

    _travel_distance -= (_direction * _speed * delta).length()
    if _travel_distance <= 0.0:
        NodeRegistry.release(self)


func _on_wall_hit() -> void:
    trigger()


func reset() -> void:
    super.reset()
    _speed = 500.0
    _direction = Vector2.RIGHT
    _travel_distance = 0.0


func set_enabled(value: bool) -> void:
    super.set_enabled(value)
