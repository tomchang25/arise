class_name AttackDelivery
extends CharacterBody2D

var lifetime_timer: Timer

var _data: AttackData
var _attack_effect: AttackEffect

## If true, stopping the lifetime timer on trigger and wait for
## _attack_effect to emit "finished" before freeing this delivery.
var _wait_for_effect: bool = false


func setup(data: AttackData) -> void:
    _data = data
    _init_lifetime_timer(data.attack_lifetime)


func _init_lifetime_timer(duration: float) -> void:
    lifetime_timer = Timer.new()
    lifetime_timer.one_shot = true
    lifetime_timer.wait_time = duration
    lifetime_timer.connect("timeout", _on_timeout)
    add_child(lifetime_timer)
    lifetime_timer.start()


func trigger() -> void:
    _attack_effect = _data.attack_effect_scene.instantiate()
    if _attack_effect == null:
        push_error("attack_effect_scene failed to instantiate in: " + name)
        return

    add_child(_attack_effect)
    _attack_effect.setup(_data)
    _attack_effect.play()

    if _wait_for_effect:
        lifetime_timer.stop()
        _attack_effect.connect("finished", queue_free)


func _on_timeout() -> void:
    queue_free()
