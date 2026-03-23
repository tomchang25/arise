@tool
class_name HealthBarModule
extends Control

@export var stats: Stats

@export_group("Bars")
@export var under_bar: TextureProgressBar
@export var damage_bar: TextureProgressBar
@export var full_bar: TextureProgressBar

@export_group("Display")
@export var hide_when_full := false
@export var hide_when_dead := true

@export_group("Damage Animation")
@export var delay_after_damage: float = 0.25
@export var damage_bar_tween_duration: float = 0.35
@export var heal_bar_tween_duration: float = 0.15 # when HP increases, how fast damage bar catches up

var _damage_delay_timer: Timer
var _damage_tween: Tween


func _ready() -> void:
    # Auto-find children if not assigned
    if not under_bar:
        under_bar = find_child("UnderBar", true, false) as TextureProgressBar
    if not damage_bar:
        damage_bar = find_child("DamageBar", true, false) as TextureProgressBar
    if not full_bar:
        full_bar = find_child("FullBar", true, false) as TextureProgressBar

    _ensure_timer()

    if stats:
        bind(stats)
    else:
        _refresh(true)


func _exit_tree() -> void:
    _unbind()


func reset() -> void:
    _stop_damage_anim()
    if stats:
        _refresh(true)


func set_enabled(value: bool) -> void:
    visible = value
    if not value:
        _stop_damage_anim()


func is_enabled() -> bool:
    return visible


func bind(target_stats: Stats) -> void:
    _unbind()
    stats = target_stats

    if not stats:
        _refresh(true)
        return

    stats.health_changed.connect(_on_health_changed)
    stats.stats_recalculated.connect(_on_stats_recalculated)

    _refresh(true)


func _unbind() -> void:
    if not stats:
        return

    if stats.health_changed.is_connected(_on_health_changed):
        stats.health_changed.disconnect(_on_health_changed)

    if stats.stats_recalculated.is_connected(_on_stats_recalculated):
        stats.stats_recalculated.disconnect(_on_stats_recalculated)


func _ensure_timer() -> void:
    if _damage_delay_timer and is_instance_valid(_damage_delay_timer):
        return

    _damage_delay_timer = Timer.new()
    _damage_delay_timer.name = "DamageDelayTimer"
    _damage_delay_timer.one_shot = true
    _damage_delay_timer.wait_time = max(0.0, delay_after_damage)
    _damage_delay_timer.timeout.connect(_on_damage_delay_timeout)
    add_child(_damage_delay_timer)


func _on_health_changed(_new_health: float) -> void:
    _refresh(false)


func _on_stats_recalculated() -> void:
    # max health can change; keep bars consistent
    _refresh(false)


func _refresh(force_sync_damage: bool) -> void:
    if not stats or not full_bar:
        return

    _ensure_timer()

    var max_hp: float = max(1.0, stats.current_max_health)
    var hp: float = clamp(stats.health, 0.0, max_hp)

    # Update ranges
    _apply_range(full_bar, max_hp)
    _apply_range(damage_bar, max_hp)
    _apply_range(under_bar, max_hp)

    # Display rules
    if hide_when_dead and hp <= 0.0:
        visible = false
        return
    if hide_when_full and hp >= max_hp:
        visible = false
        return
    visible = true

    # --- Core behavior ---
    # FullBar updates immediately
    full_bar.value = hp

    if force_sync_damage:
        _stop_damage_anim()
        if damage_bar:
            damage_bar.value = hp
        return

    # Damage animation logic
    if damage_bar:
        # HP decreased: FullBar drops now; DamageBar drops after delay
        if hp < damage_bar.value:
            _stop_damage_tween_only()

            _damage_delay_timer.wait_time = max(0.0, delay_after_damage)
            _damage_delay_timer.start()

        # HP increased or stayed: DamageBar should catch up (usually quickly)
        else:
            _damage_delay_timer.stop()
            _tween_damage_bar_to(hp, heal_bar_tween_duration)


func _apply_range(bar: TextureProgressBar, max_hp: float) -> void:
    if not bar:
        return
    bar.min_value = 0.0
    bar.max_value = max_hp
    # UnderBar is usually full background
    if bar == under_bar:
        bar.value = max_hp


func _on_damage_delay_timeout() -> void:
    if not damage_bar or not full_bar:
        return
    _tween_damage_bar_to(full_bar.value, damage_bar_tween_duration)


func _tween_damage_bar_to(target_value: float, duration: float) -> void:
    if not damage_bar:
        return

    _stop_damage_tween_only()

    _damage_tween = create_tween()
    _damage_tween.set_ease(Tween.EASE_OUT)
    _damage_tween.set_trans(Tween.TRANS_QUART)
    _damage_tween.tween_property(damage_bar, "value", target_value, max(0.0, duration))


func _stop_damage_tween_only() -> void:
    if _damage_tween and is_instance_valid(_damage_tween):
        _damage_tween.kill()
    _damage_tween = null


func _stop_damage_anim() -> void:
    if _damage_delay_timer:
        _damage_delay_timer.stop()
    _stop_damage_tween_only()
