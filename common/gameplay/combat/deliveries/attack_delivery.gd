class_name AttackDelivery
extends CharacterBody2D

var lifetime_timer: Timer

var _context: EffectContext
var _attack_effect: AttackEffect

## If true, stop the lifetime timer on trigger and wait for
## _attack_effect to emit "finished" before freeing this delivery.
var _wait_for_effect: bool = false


func setup(ctx: EffectContext) -> void:
    _context = ctx
    _init_lifetime_timer(ctx.attack_lifetime)


func _init_lifetime_timer(duration: float) -> void:
    lifetime_timer = Timer.new()
    lifetime_timer.one_shot = true
    lifetime_timer.wait_time = duration
    lifetime_timer.connect("timeout", _on_timeout)
    add_child(lifetime_timer)
    lifetime_timer.start()


func trigger() -> void:
    if _context == null or _context.attack_effect_scene == null:
        push_error("AttackDelivery.trigger: no attack_effect_scene in context for '%s'" % name)
        return

    _attack_effect = _context.attack_effect_scene.instantiate() as AttackEffect
    if _attack_effect == null:
        push_error("AttackDelivery.trigger: attack_effect_scene did not instantiate to AttackEffect in '%s'" % name)
        return

    add_child(_attack_effect)
    _attack_effect.setup(_context)
    _attack_effect.play()

    if _wait_for_effect:
        lifetime_timer.stop()
        _attack_effect.connect("finished", queue_free)


func _on_timeout() -> void:
    queue_free()
