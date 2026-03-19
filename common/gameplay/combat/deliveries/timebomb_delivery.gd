class_name TimebombDelivery
extends AttackDelivery
## Delivery that detonates after a countdown rather than immediately.
##
## trigger_timer (exported, authored in the scene) controls when detonation
## happens.  The inherited lifetime failsafe starts at spawn via arm() and
## acts as an absolute ceiling — the delivery will always be freed even if
## trigger_timer never fires (e.g. scene tree paused during countdown).
##
## Dormant trap / landmine pattern (Step 4 preview)
## ─────────────────────────────────────────────────
## If you want the fuse to start only after something activates the trap,
## remove arm() from setup() here and instead call arm() from whatever
## activation signal you wire in Step 4 (TriggerComponent).

@export var trigger_timer: Timer


func setup(ctx: EffectContext) -> void:
    _wait_for_effect = true
    super(ctx)
    arm()

    if trigger_timer:
        trigger_timer.connect("timeout", trigger)
