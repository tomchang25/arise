class_name SlashDelivery
extends AttackDelivery

func setup(ctx: EffectContext) -> void:
    super(ctx)
    trigger()
    arm()


func reset() -> void:
    super.reset()


func set_enabled(value: bool) -> void:
    super.set_enabled(value)
