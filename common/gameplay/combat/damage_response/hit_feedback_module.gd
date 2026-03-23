class_name HitFeedbackModule
extends Node

@export var stats: Stats
@export var damage_receiver: DamageReceiverModule
@export var movement_module: MovementModule

@export_group("Knockback")
@export var enabled_knockback := true
@export var knockback_scale := 1.0
@export var knockback_velocity_cap := 1200.0
@export var minimum_knockback_force := 0.0

@export_group("Flash")
@export var enabled_flash := true
@export var flash_step := 0.5
@export var flash_white := Color(1, 1, 1, 1)
@export var flash_red := Color(1, 0.25, 0.25, 1)
@export var flash_color := flash_red

@export_group("Visual Targets")
@export var visuals: Node
@export var hit_shader: Shader = preload("res://common/rendering/shaders/hit_overlay_flash.gdshader")

@export_group("Particles")
@export var enabled_particles := true

## Assign a PackedScene that is a GPUParticles2D or CPUParticles2D (one-shot style).
@export var hit_particles_scene: PackedScene
@export var death_particles_scene: PackedScene

## Colors (blood / dirt / pottery etc.)
@export var hit_particles_color: Color = Color(0.8, 0.0, 0.0, 1.0)
@export var death_particles_color: Color = Color(0.8, 0.0, 0.0, 1.0)

## "Size" control: scales the whole particles node (easy + reliable)
@export var hit_particles_scale := 1.0
@export var death_particles_scale := 2.0

## Optional offset if you want it to spawn slightly above feet, etc.
@export var particles_offset: Vector2 = Vector2.ZERO

## Where to attach particles (owner is usually fine). If you want them above everything, set to current_scene.
@export var particles_attach_to_owner := true

@export_group("Audio")
@export var enabled_sfx := true
@export var damaged_audio: SpatialAudioEvent
@export var blocked_audio: SpatialAudioEvent
@export var died_audio: SpatialAudioEvent

var enabled: bool = true

var _flash_tween: Tween
var _cached_targets: Array[CanvasItem] = []


func _ready() -> void:
    if not damage_receiver:
        damage_receiver = owner.find_child("DamageReceiverModule", true, false) as DamageReceiverModule

    if not movement_module:
        movement_module = owner.find_child("MovementModule", true, false) as MovementModule

    if not stats and owner and owner.get("stats") is Stats:
        stats = owner.stats

    if damage_receiver:
        if not damage_receiver.damaged.is_connected(_on_damaged):
            damage_receiver.damaged.connect(_on_damaged)
        if not damage_receiver.blocked.is_connected(_on_blocked):
            damage_receiver.blocked.connect(_on_blocked)
        if not damage_receiver.died.is_connected(_on_died):
            damage_receiver.died.connect(_on_died)


func reset() -> void:
    enabled = true
    if _flash_tween and _flash_tween.is_valid():
        _flash_tween.kill()
    _flash_tween = null


func set_enabled(value: bool) -> void:
    enabled = value
    if not enabled:
        if _flash_tween and _flash_tween.is_valid():
            _flash_tween.kill()
        _flash_tween = null


func _get_flash_time_from_invuln() -> float:
    var t := stats.invuln_time
    return min(t * 1.2, t + 0.1)


func _on_damaged(_amount: float, _new_hp: float, info: EffectContext) -> void:
    if not enabled:
        return
    if not info:
        return

    if enabled_knockback:
        _apply_knockback(info)

    if enabled_flash:
        _play_flash(_get_flash_time_from_invuln())

    if enabled_particles:
        _spawn_hit_particles(info)

    if enabled_sfx and damaged_audio:
        _play_audio_event(damaged_audio)


func _on_blocked(_info: EffectContext) -> void:
    if not enabled:
        return
    if enabled_sfx and blocked_audio:
        _play_audio_event(blocked_audio)


func _on_died(info: EffectContext) -> void:
    if not enabled:
        return
    if enabled_particles:
        _spawn_death_particles(info)

    if enabled_sfx and died_audio:
        _play_audio_event(died_audio)

# -------------------------
# Particles
# -------------------------


func _spawn_hit_particles(info: EffectContext) -> void:
    _spawn_particles(hit_particles_scene, hit_particles_color, hit_particles_scale, info)


func _spawn_death_particles(info: EffectContext) -> void:
    _spawn_particles(death_particles_scene, death_particles_color, death_particles_scale, info, true)


func _spawn_particles(
        scene: PackedScene,
        color: Color,
        scale_amount: float,
        info: EffectContext,
        force_world: bool = false,
) -> void:
    if scene == null:
        return

    var node := scene.instantiate()

    if not node is CPUParticles2D:
        push_warning("HitFeedbackModule: particle scene must be CPUParticles2D")
        node.queue_free()
        return

    var particles := node as CPUParticles2D

    # Attach
    var parent: Node = null
    if force_world:
        parent = get_tree().current_scene
    else:
        parent = owner if particles_attach_to_owner else get_tree().current_scene

    if parent == null:
        # last resort fallback
        parent = get_tree().current_scene
    if parent == null:
        # ultra fallback: can't spawn anywhere
        particles.queue_free()
        return

    parent.add_child(particles)

    # Position
    if owner is Node2D:
        particles.global_position = owner.global_position + particles_offset

    # Size + color
    particles.scale = Vector2.ONE * max(scale_amount, 0.01)
    particles.color = color

    # Rotate by attack direction (so emission points "forward")
    var dir := _resolve_hit_dir(info)
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    particles.direction = Vector2.RIGHT
    particles.global_rotation = dir.angle()

    # Emit once
    particles.one_shot = true
    particles.emitting = true

    if not particles.finished.is_connected(particles.queue_free):
        particles.finished.connect(particles.queue_free)

# -------------------------
# Knockback
# -------------------------


func _apply_knockback(info: EffectContext) -> void:
    if info == null:
        return

    var force := info.knockback_force * knockback_scale
    if force <= minimum_knockback_force:
        return

    var dir := _resolve_hit_dir(info)
    if dir == Vector2.ZERO:
        return

    var impulse := dir * force

    if movement_module:
        movement_module.apply_knockback(impulse, knockback_velocity_cap)
        return

    if owner.has_method("apply_knockback"):
        owner.call("apply_knockback", impulse)
        return

    if owner is RigidBody2D:
        (owner as RigidBody2D).apply_impulse(impulse)

# -------------------------
# Flash
# -------------------------


func _play_flash(duration: float) -> void:
    if duration <= 0.0:
        return
    if _cached_targets.is_empty():
        _cache_visual_targets()
        if _cached_targets.is_empty():
            return

    if _flash_tween and _flash_tween.is_valid():
        _flash_tween.kill()

    _flash_tween = create_tween()

    var mats: Array[ShaderMaterial] = []
    for t in _cached_targets:
        var sm := t.material as ShaderMaterial
        if sm and sm.shader == hit_shader:
            mats.append(sm)

    if mats.is_empty():
        return

    for m in mats:
        m.set_shader_parameter("overlay_color", flash_color)
        m.set_shader_parameter("overlay_amount", 1.0)

    _flash_tween.tween_method(func(v: float) -> void: for m in mats:m.set_shader_parameter("overlay_amount", v), 1.0, 0.0, duration)

    _flash_tween.tween_callback(
        func():
            for m in mats:
                m.set_shader_parameter("overlay_amount", 0.0)
    )


func _cache_visual_targets() -> void:
    _cached_targets.clear()

    if visuals == null:
        visuals = owner.find_child("Visuals", true, false)

    if visuals == null:
        return

    _cached_targets = _collect_sprite_items(visuals)

    for t in _cached_targets:
        _ensure_hit_shader_material(t)


func _collect_sprite_items(root: Node) -> Array[CanvasItem]:
    var out: Array[CanvasItem] = []
    if root is Sprite2D or root is AnimatedSprite2D:
        out.append(root as CanvasItem)

    for child in root.get_children():
        if child is Sprite2D or child is AnimatedSprite2D:
            out.append(child as CanvasItem)
        if child.get_child_count() > 0:
            out.append_array(_collect_sprite_items(child))
    return out


func _ensure_hit_shader_material(ci: CanvasItem) -> void:
    if hit_shader == null:
        return

    var sm: ShaderMaterial = null

    if ci.material is ShaderMaterial and (ci.material as ShaderMaterial).shader == hit_shader:
        sm = ci.material as ShaderMaterial
    else:
        sm = ShaderMaterial.new()
        sm.shader = hit_shader
        ci.material = sm

    sm.resource_local_to_scene = true

# -------------------------
# SFX
# -------------------------


func _play_audio_event(ev: AudioEvent) -> void:
    if ev == null:
        return

    AudioManager.play_event(ev, owner.global_position)

# -------------------------
# Internal
# -------------------------


## Resolve knockback direction, respecting the phase's KnockbackMode.
##
## FIXED (default):
##   • knockback_source valid → victim − source (contact/attached attacks).
##   • knockback_dir set      → baked travel direction (projectile/melee).
##
## OUTWARD:
##   Push victim away from the effect center (knockback_source = AttackEffect node).
##   Direction = victim − source.
##
## INWARD:
##   Pull victim toward the effect center (knockback_source = AttackEffect node).
##   Direction = source − victim (negated OUTWARD).
func _resolve_hit_dir(info: EffectContext) -> Vector2:
    if info == null:
        return Vector2.ZERO

    if not owner is Node2D:
        return Vector2.ZERO

    var victim_pos := (owner as Node2D).global_position

    match info.knockback_mode:
        EffectPhaseDefinition.KnockbackMode.OUTWARD:
            if is_instance_valid(info.knockback_source):
                var dir := (victim_pos - info.knockback_source.global_position).normalized()
                if dir != Vector2.ZERO:
                    return dir
        EffectPhaseDefinition.KnockbackMode.INWARD:
            if is_instance_valid(info.knockback_source):
                var dir := (info.knockback_source.global_position - victim_pos).normalized()
                if dir != Vector2.ZERO:
                    return dir
        EffectPhaseDefinition.KnockbackMode.FIXED, _:
            if is_instance_valid(info.knockback_source):
                var dir := (victim_pos - info.knockback_source.global_position).normalized()
                if dir != Vector2.ZERO:
                    return dir

            if info.knockback_dir != Vector2.ZERO:
                return info.knockback_dir.normalized()

    return Vector2.ZERO
