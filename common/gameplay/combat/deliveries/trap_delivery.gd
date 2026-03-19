class_name TrapDelivery
extends AttackDelivery
## Delivery for traps and landmines that detonate on hurtbox proximity.
##
## Previously owned a bespoke trigger_area + body_entered wiring.
## Now delegates all trigger logic to a TriggerComponent child node in the scene,
## which is auto-wired by AttackDelivery.setup().
##
## Scene setup
## ───────────
## Add a TriggerComponent node as a child of the TrapDelivery scene and set:
##   mode              = HURTBOX_PROXIMITY
##   detection_radius  = desired trigger radius
##   fuse_time         = 0 (proximity only) or > 0 (proximity OR countdown)
##
## arm() is called immediately in setup() so the trap is live from the moment
## it is placed.  For a dormant trap that only arms after a separate activation
## event, remove the arm() call here and wire it externally instead.

func setup(ctx: EffectContext) -> void:
    _wait_for_effect = true
    super(ctx)
    arm()
