## ResourceBarModule
## A generalized animated progress bar for any resource (HP, MP, Stamina, etc.)
##
## Modes:
##   THREE_LAYER — under + damage-delay + fill  (designed for HP)
##   TWO_LAYER   — under + fill with smooth tween (designed for MP / any drainable resource)
##
## Usage:
##   1. Add as a child Control, set custom_minimum_size to match your bar texture size.
##   2. Assign under_bar, fill_bar (and damage_bar for THREE_LAYER mode) in the inspector.
##   3. Call set_value(current, maximum) any time the resource changes.
##      Or use bind_hp(stats) / bind_mana(stats) for automatic Stats wiring.
@tool
class_name ResourceBarModule
extends Control

enum Mode { THREE_LAYER, TWO_LAYER }

# -------------------------
# Exports
# -------------------------

@export var mode: Mode = Mode.THREE_LAYER

@export_group("Bars")
@export var under_bar:  TextureProgressBar
@export var damage_bar: TextureProgressBar   ## Only used in THREE_LAYER mode
@export var fill_bar:   TextureProgressBar

@export_group("Tween")
@export var fill_tween_duration:   float = 0.15  ## How fast fill_bar catches up on heal / MP change
@export var damage_delay:          float = 0.25  ## THREE_LAYER: seconds before damage_bar starts shrinking
@export var damage_tween_duration: float = 0.35  ## THREE_LAYER: duration of damage_bar shrink tween

# -------------------------
# Internal
# -------------------------

var _current_value: float = 100.0
var _max_value:     float = 100.0

var _damage_delay_timer: Timer
var _damage_tween:       Tween
var _fill_tween:         Tween

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _auto_wire()
    _ensure_timer()
    _apply_range()
    _sync_all()


func _exit_tree() -> void:
    _stop_all_anims()


# -------------------------
# Public API
# -------------------------


## Set a new value, triggering the appropriate animation.
func set_value(current: float, maximum: float) -> void:
    var old_value := _current_value
    _max_value    = max(1.0, maximum)
    _current_value = clamp(current, 0.0, _max_value)
    _apply_range()
    _animate(old_value)


## Force-sync all bars to current value with no animation (e.g. on first bind).
func force_sync(current: float, maximum: float) -> void:
    _max_value     = max(1.0, maximum)
    _current_value = clamp(current, 0.0, _max_value)
    _apply_range()
    _stop_all_anims()
    _sync_all()


# -------------------------
# Internal — Wiring
# -------------------------


func _auto_wire() -> void:
    if not under_bar:
        under_bar  = find_child("UnderBar",  true, false) as TextureProgressBar
    if not damage_bar:
        damage_bar = find_child("DamageBar", true, false) as TextureProgressBar
    if not fill_bar:
        fill_bar   = find_child("FillBar",   true, false) as TextureProgressBar


func _ensure_timer() -> void:
    if _damage_delay_timer and is_instance_valid(_damage_delay_timer):
        return
    _damage_delay_timer = Timer.new()
    _damage_delay_timer.name     = "DamageDelayTimer"
    _damage_delay_timer.one_shot = true
    _damage_delay_timer.timeout.connect(_on_damage_delay_timeout)
    add_child(_damage_delay_timer)


# -------------------------
# Internal — Range + Sync
# -------------------------


func _apply_range() -> void:
    _set_bar_range(under_bar,  _max_value)
    _set_bar_range(damage_bar, _max_value)
    _set_bar_range(fill_bar,   _max_value)
    # UnderBar is always the full dark trough
    if under_bar:
        under_bar.value = _max_value


func _set_bar_range(bar: TextureProgressBar, max_v: float) -> void:
    if not bar:
        return
    bar.min_value = 0.0
    bar.max_value = max_v


func _sync_all() -> void:
    if fill_bar:
        fill_bar.value = _current_value
    if damage_bar:
        damage_bar.value = _current_value


# -------------------------
# Internal — Animation
# -------------------------


func _animate(old_value: float) -> void:
    match mode:
        Mode.THREE_LAYER:
            _animate_three_layer(old_value)
        Mode.TWO_LAYER:
            _animate_two_layer()


func _animate_three_layer(old_value: float) -> void:
    if not fill_bar:
        return

    # fill_bar snaps immediately
    if _fill_tween and is_instance_valid(_fill_tween):
        _fill_tween.kill()
    fill_bar.value = _current_value

    if not damage_bar:
        return

    if _current_value < old_value:
        # Damage: stop any running shrink, restart delay
        _stop_damage_tween()
        _damage_delay_timer.wait_time = max(0.0, damage_delay)
        _damage_delay_timer.start()
    else:
        # Heal: damage bar catches up quickly
        _damage_delay_timer.stop()
        _tween_damage_bar_to(_current_value, fill_tween_duration)


func _animate_two_layer() -> void:
    if not fill_bar:
        return
    if _fill_tween and is_instance_valid(_fill_tween):
        _fill_tween.kill()
    _fill_tween = create_tween()
    _fill_tween.set_ease(Tween.EASE_OUT)
    _fill_tween.set_trans(Tween.TRANS_QUART)
    _fill_tween.tween_property(fill_bar, "value", _current_value, max(0.0, fill_tween_duration))


func _tween_damage_bar_to(target: float, duration: float) -> void:
    _stop_damage_tween()
    _damage_tween = create_tween()
    _damage_tween.set_ease(Tween.EASE_OUT)
    _damage_tween.set_trans(Tween.TRANS_QUART)
    _damage_tween.tween_property(damage_bar, "value", target, max(0.0, duration))


func _stop_damage_tween() -> void:
    if _damage_tween and is_instance_valid(_damage_tween):
        _damage_tween.kill()
    _damage_tween = null


func _stop_all_anims() -> void:
    if _damage_delay_timer and is_instance_valid(_damage_delay_timer):
        _damage_delay_timer.stop()
    _stop_damage_tween()
    if _fill_tween and is_instance_valid(_fill_tween):
        _fill_tween.kill()
    _fill_tween = null


# -------------------------
# Signal Callbacks
# -------------------------


func _on_damage_delay_timeout() -> void:
    if fill_bar:
        _tween_damage_bar_to(fill_bar.value, damage_tween_duration)
