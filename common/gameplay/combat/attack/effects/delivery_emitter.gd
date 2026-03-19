class_name DeliveryEmitter
extends PhaseEffect
## A PhaseEffect that fires one or more independent AttackDeliveries instead of
## hosting a Hitbox.
##
## Use this as the effect_scene on an EffectPhaseDefinition when a phase should
## spawn new deliveries rather than directly damage enemies. Examples:
##
##   Arrow  → mines: an arrow's phase uses a DeliveryEmitter with
##             emit_interval > 0 to drop a mine at the arrow's world position
##             every few seconds while the phase is active.
##
##   Mine   → bullets: a mine's phase uses a DeliveryEmitter with
##             emit_interval = 0 (fire once on play) and bullet_count > 1 to
##             burst bullets in a fan when the mine triggers.
##
##   RPG    → RPG: set reuse_parent_definition = true so the emitter re-fires
##             the same definition that produced this delivery, with no circular
##             resource reference required. spawn_depth stops the chain at
##             MAX_SPAWN_DEPTH.
##
## Child deliveries are fire-and-forget
## ─────────────────────────────────────
## Spawned deliveries are parented into the world tree (spawn_group), not into
## this node. They own their own lifetime. The emitter never tracks them after
## the spawn call returns.
##
## Depth guard
## ────────────
## EffectContext.spawn_depth is incremented for every child context built here
## and capped at MAX_SPAWN_DEPTH. DeliveryEmitter refuses to spawn when the
## incoming context's spawn_depth has already reached the cap. This means a
## recursive chain terminates cleanly — the last generation simply skips the
## emitter phase rather than crashing.
##
## Projectile launch
## ─────────────────
## When the resolved definition is a ProjectileAttackDefinition, the spawned
## delivery may require launch() to be called (e.g. RpgDelivery).
## DeliveryEmitter calls launch() automatically if the delivery responds to it.
##
## Direction fan
## ─────────────
## When bullet_count = 1:  the child fires in the parent context's knockback_dir.
## When bullet_count > 1:  children are spread evenly across spread_angle_degrees,
##                         centred on knockback_dir. 360° = full circle burst.
##
## Authoring
## ─────────
## Option A — explicit child (arrow → mine, mine → bullet):
##   Set child_definition to the target AttackDefinition.
##   Leave reuse_parent_definition = false.
##
## Option B — recursive (RPG → RPG):
##   Set reuse_parent_definition = true.
##   Leave child_definition empty.
##   No circular resource reference needed.

const MAX_SPAWN_DEPTH: int = 3

# -------------------------
# Exports
# -------------------------

@export_group("Child Delivery")

## If true, re-fires the same AttackDefinition that produced this delivery.
## Use this for recursive chains (RPG → RPG) to avoid circular resource refs.
## When true, child_definition is ignored.
@export var reuse_parent_definition: bool = false

## The AttackDefinition used to build each spawned child delivery.
## Ignored when reuse_parent_definition = true.
## Must be a PlaceAttackDefinition or ProjectileAttackDefinition.
@export var child_definition: AttackDefinition = null

## Seconds between successive spawns while this phase is active.
## Set to 0 to fire exactly once when play() is called.
@export var emit_interval: float = 0.0

@export_group("Direction")

## Number of child deliveries spawned per emit.
## 1 = single shot in knockback_dir.
## >1 = fan spread centred on knockback_dir.
@export var bullet_count: int = 1

## Total angle of the fan spread in degrees.
## 0   = all bullets fire in knockback_dir (no spread).
## 90  = 45° either side of knockback_dir.
## 360 = full circle burst, evenly spaced.
## Ignored when bullet_count = 1.
@export_range(0.0, 360.0, 1.0) var spread_angle_degrees: float = 0.0

# -------------------------
# Private state
# -------------------------

var _parent_ctx: EffectContext

# -------------------------
# PhaseEffect overrides
# -------------------------


func setup(ctx: EffectContext) -> void:
    _parent_ctx = ctx


## Runs the emitter for `duration` seconds, then emits finished.
## Fires once immediately if emit_interval = 0, or on a repeating timer otherwise.
func play(duration: float = 0.0) -> void:
    if _parent_ctx == null:
        push_error("DeliveryEmitter: setup() was not called before play()")
        finished.emit()
        queue_free()
        return

    # Resolve which definition to use before the depth check so we can validate it.
    var resolved_def := _resolve_definition()
    if resolved_def == null:
        push_error("DeliveryEmitter: no definition available (set child_definition or enable reuse_parent_definition)")
        finished.emit()
        queue_free()
        return

    # Depth guard — refuse to spawn if we are already at the ceiling.
    # The last generation still runs its other phases (burst, burn, scorch)
    # it just skips this emitter phase, waiting out the lifetime so the
    # PhaseSequencer can advance normally.
    if _parent_ctx.spawn_depth >= MAX_SPAWN_DEPTH:
        push_warning(
            "DeliveryEmitter: spawn_depth %d >= MAX_SPAWN_DEPTH %d — skipping spawn" \
            % [_parent_ctx.spawn_depth, MAX_SPAWN_DEPTH],
        )
        if duration > 0.0:
            await get_tree().create_timer(duration).timeout
        finished.emit()
        queue_free()
        return

    if emit_interval <= 0.0:
        # Fire once immediately, then wait out the full lifetime before finishing.
        _emit_burst(resolved_def)
        if duration > 0.0:
            await get_tree().create_timer(duration).timeout
    else:
        # Fire immediately, then on a repeating interval for the duration.
        _emit_burst(resolved_def)
        var elapsed := 0.0
        while elapsed + emit_interval < duration:
            await get_tree().create_timer(emit_interval).timeout
            elapsed += emit_interval
            if not is_inside_tree():
                break
            _emit_burst(resolved_def)

    finished.emit()
    queue_free()

# -------------------------
# Internal
# -------------------------


## Returns the definition to use for spawning. Centralises the
## reuse_parent_definition / child_definition choice in one place.
func _resolve_definition() -> AttackDefinition:
    if reuse_parent_definition:
        if _parent_ctx.definition == null:
            push_error("DeliveryEmitter: reuse_parent_definition is true but parent ctx.definition is null")
            return null
        return _parent_ctx.definition
    return child_definition


## Spawns one burst of bullet_count child deliveries at the current world position.
func _emit_burst(def: AttackDefinition) -> void:
    if not is_inside_tree() or not is_instance_valid(get_parent()):
        return

    var spawn_origin: Vector2 = global_position
    var base_dir: Vector2 = _parent_ctx.knockback_dir

    for dir in _compute_directions(base_dir):
        _spawn_child_delivery(def, spawn_origin, dir)


## Returns an array of normalised direction vectors for this burst.
func _compute_directions(base_dir: Vector2) -> Array[Vector2]:
    var dirs: Array[Vector2] = []

    if bullet_count <= 1 or spread_angle_degrees <= 0.0:
        dirs.append(base_dir)
        return dirs

    var half_spread := deg_to_rad(spread_angle_degrees * 0.5)
    var base_angle := base_dir.angle()

    for i in range(bullet_count):
        var t: float = float(i) / float(bullet_count - 1) if bullet_count > 1 else 0.0
        var angle: float = base_angle + lerp(-half_spread, half_spread, t)
        dirs.append(Vector2.from_angle(angle))

    return dirs


## Builds a child EffectContext and spawns a single AttackDelivery for `dir`.
func _spawn_child_delivery(def: AttackDefinition, origin: Vector2, dir: Vector2) -> void:
    var spawn_group := _parent_ctx.spawn_group
    var spawn_parent := SpawnContext.resolve_spawn_parent(spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("DeliveryEmitter: could not resolve spawn parent for group '%s'" % spawn_group)
        return

    var child_ctx := EffectContext.build_for_emitted_child(
        def,
        _parent_ctx.source_stats,
        origin,
        dir,
        _parent_ctx.target_factions,
        _parent_ctx.spawn_depth + 1,
    )
    if child_ctx == null:
        push_error("DeliveryEmitter: failed to build child EffectContext")
        return

    if child_ctx.attack_scene == null:
        push_error("DeliveryEmitter: resolved definition has no attack_scene")
        return

    var action := SpawnPackedSceneAction.new()
    action.scene = child_ctx.attack_scene
    action.use_anchor_position = true
    action.use_anchor_rotation = false

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, origin, spawn_ctx)

    _fire_and_setup(request, child_ctx, def, dir)


## Async helper: executes the spawn request, sets up the delivery, and calls
## launch() when the delivery and definition support it.
## Called without await from _spawn_child_delivery so the emitter is not blocked.
func _fire_and_setup(
        request: SpawnRequest,
        child_ctx: EffectContext,
        def: AttackDefinition,
        dir: Vector2,
) -> void:
    var result: SpawnResult = await request.execute()
    if not result.success:
        push_error("DeliveryEmitter: spawn failed — %s" % result.blocked_reason)
        return

    var delivery := result.spawned_node as AttackDelivery
    if delivery == null:
        push_error("DeliveryEmitter: spawned node is not AttackDelivery")
        return

    if not delivery.is_node_ready():
        await delivery.ready

    delivery.rotation = dir.angle()
    delivery.setup(child_ctx)

    # Projectile deliveries (ProjectileDelivery, RpgDelivery) require launch()
    # to initialise direction, speed, and travel distance. The module normally
    # calls this, but since we bypass the module we call it here.
    if delivery.has_method("launch") and def is ProjectileAttackDefinition:
        var proj_def := def as ProjectileAttackDefinition
        delivery.launch(dir, proj_def.projectile_speed, proj_def.travel_distance)
