class_name TrapDelivery
extends AttackDelivery

@export var trigger_area: Area2D


func setup(ctx: EffectContext) -> void:
    _wait_for_effect = true
    super(ctx)

    if trigger_area:
        trigger_area.connect("body_entered", _on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
    trigger_area.disconnect("body_entered", _on_body_entered)
    trigger()
