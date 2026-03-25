class_name LineBeamDelivery
extends AttackDelivery
## Delivery for the Line Beam attack type.
##
## Spawned at the target position, immediately triggers the phase sequence
## (telegraph → beam hitbox) and starts the lifetime failsafe timer.
## The delivery is rotated by PlaceAttackModule to face the aimed direction,
## so phase effects draw their rectangle in the correct orientation.

func setup(ctx: EffectContext) -> void:
    super(ctx)
    trigger()
    arm()


func reset() -> void:
    super.reset()


func set_enabled(value: bool) -> void:
    super.set_enabled(value)
