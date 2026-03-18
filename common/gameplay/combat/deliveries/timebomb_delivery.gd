class_name TimebombDelivery
extends AttackDelivery

@export var trigger_timer: Timer


func setup(data: AttackData) -> void:
    _wait_for_effect = true
    super(data)

    if trigger_timer:
        trigger_timer.connect("timeout", trigger)
