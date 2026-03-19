class_name TimebombDelivery
extends AttackDelivery

@export var trigger_timer: Timer


func setup(ctx: EffectContext) -> void:
    _wait_for_effect = true
    super(ctx)

    if trigger_timer:
        trigger_timer.connect("timeout", trigger)
