class_name TriggerComponent
extends Node2D
## Composable trigger node that lives inside an AttackDelivery scene.
##
## Emits `triggered` when the delivery's detonation condition is met.
## AttackDelivery.setup() auto-wires this component if it finds one as a child,
## connecting `triggered` → `trigger()` and delegating arm() responsibility here.
##
## Three trigger modes
## ───────────────────
## IMMEDIATE
##   Emits `triggered` the moment arm() is called.
##   Use for: deliveries that fire the instant they are placed (slash, slam).
##   Note: SlashDelivery and PlaceDelivery call trigger() directly and don't need
##   TriggerComponent — this mode exists for completeness and testing.
##
## TIMER
##   Emits `triggered` after fuse_time seconds.  arm() starts the fuse.
##   Use for: countdown bombs, timed mines.
##   Replaces TimebombDelivery's exported trigger_timer pattern.
##
## HURTBOX_PROXIMITY
##   Emits `triggered` when a Hurtbox whose faction matches the delivery's
##   target_factions enters the detection area.  arm() enables monitoring.
##   Use for: proximity mines, tripwires, contact-triggered traps.
##   Replaces TrapDelivery's trigger_area / body_entered pattern.
##   Collision mask is set from EffectContext.target_factions at arm() time,
##   so the mine only reacts to the correct faction without hardcoding layers.
##
## Combining modes
## ───────────────
## TriggerComponent fires on the FIRST condition that is satisfied.
## To get "timer OR proximity", set mode = HURTBOX_PROXIMITY and also set
## fuse_time > 0.  Both the detection area and the fuse timer are armed
## simultaneously; whichever fires first wins and calls _fire().
##
## Dormant vs live
## ───────────────
## arm() is the boundary between dormant and live.
## AttackDelivery.setup() registers the component but does NOT call arm().
## The delivery subclass calls arm() when the delivery becomes active:
##   • Immediately in setup() → live from spawn (same as current subclasses).
##   • On an external event   → dormant until that event (new landmine pattern).

signal triggered

enum Mode {
    ## Fire immediately when arm() is called.
    IMMEDIATE,
    ## Fire after fuse_time seconds.
    TIMER,
    ## Fire when a matching Hurtbox enters the detection radius.
    ## Optionally also fires after fuse_time if fuse_time > 0.
    HURTBOX_PROXIMITY,
}

@export var mode: Mode = Mode.IMMEDIATE

## Seconds before the fuse fires.
## Used by TIMER mode.
## Also used as a fallback timeout in HURTBOX_PROXIMITY mode when > 0.
@export var fuse_time: float = 3.0

## Radius of the proximity detection area (HURTBOX_PROXIMITY only).
@export var detection_radius: float = 32.0

## Set by AttackDelivery.setup() before arm() is called.
## Used to configure collision mask in HURTBOX_PROXIMITY mode.
var target_factions: Array = []

var _armed: bool = false
var _fired: bool = false

var _detection_area: Area2D
var _fuse_timer: Timer

# -------------------------
# Public API
# -------------------------


## Make the trigger live. Call once — subsequent calls are no-ops.
## AttackDelivery calls this when the delivery is ready to activate.
func arm() -> void:
    if _armed:
        return
    _armed = true

    match mode:
        Mode.IMMEDIATE:
            _fire()
        Mode.TIMER:
            _start_fuse()
        Mode.HURTBOX_PROXIMITY:
            _setup_detection_area()
            if fuse_time > 0.0:
                _start_fuse()

# -------------------------
# Internal
# -------------------------


func _fire() -> void:
    if _fired:
        return
    _fired = true
    _cleanup()
    triggered.emit.call_deferred()


func _start_fuse() -> void:
    _fuse_timer = Timer.new()
    _fuse_timer.one_shot = true
    _fuse_timer.wait_time = max(fuse_time, 0.01)
    _fuse_timer.timeout.connect(_fire)
    add_child(_fuse_timer)
    _fuse_timer.start()


func _setup_detection_area() -> void:
    _detection_area = Area2D.new()
    _detection_area.monitorable = false
    _detection_area.monitoring = true

    # Build collision mask from the delivery's resolved target_factions.
    # This reuses the same faction→layer mapping as Hitbox and Hurtbox so
    # the mine only wakes up for the correct side without hardcoding layers.
    _detection_area.collision_mask = 0
    for faction in target_factions:
        match faction:
            Stats.Faction.PLAYER:
                _detection_area.set_collision_mask_value(Global.PLAYER_HURTBOX, true)
            Stats.Faction.ENEMY:
                _detection_area.set_collision_mask_value(Global.ENEMY_HURTBOX, true)

    var shape_node := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = detection_radius
    shape_node.shape = circle
    _detection_area.add_child(shape_node)

    _detection_area.area_entered.connect(_on_hurtbox_entered)
    add_child(_detection_area)


func _on_hurtbox_entered(area: Area2D) -> void:
    if area is Hurtbox:
        _fire()


func _cleanup() -> void:
    # Disable detection area and fuse so neither fires a second time.
    if is_instance_valid(_detection_area):
        _detection_area.set_deferred("monitoring", false)
    if is_instance_valid(_fuse_timer):
        _fuse_timer.stop()
