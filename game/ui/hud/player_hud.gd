class_name PlayerHUD
extends Control

# -------------------------
# Exports
# -------------------------

@export var stats: Stats

@export_group("Bars")
@export var hp_bar:   ResourceBarModule
@export var mana_bar: ResourceBarModule

@export_group("Labels")
@export var hp_label:   Label
@export var mana_label: Label
@export var gold_label: Label

@export_group("Debug Buttons")
@export var btn_damage: Button
@export var btn_mana:   Button
@export var btn_reset:  Button

@export_group("Debug Settings")
@export var debug_damage_amount: float = 150.0
@export var debug_mana_cost:     float = 25.0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _connect_buttons()

    if stats:
        bind(stats)
    else:
        _refresh_all()


func _exit_tree() -> void:
    _unbind()


# -------------------------
# Public API
# -------------------------


func bind(target_stats: Stats) -> void:
    _unbind()
    stats = target_stats

    if not stats:
        _refresh_all()
        return

    stats.health_changed.connect(_on_health_changed)
    stats.mana_changed.connect(_on_mana_changed)
    stats.gold_changed.connect(_on_gold_changed)
    stats.stats_recalculated.connect(_on_stats_recalculated)

    _force_sync_all()


# -------------------------
# Internal
# -------------------------


func _unbind() -> void:
    if not stats:
        return
    if stats.health_changed.is_connected(_on_health_changed):
        stats.health_changed.disconnect(_on_health_changed)
    if stats.mana_changed.is_connected(_on_mana_changed):
        stats.mana_changed.disconnect(_on_mana_changed)
    if stats.gold_changed.is_connected(_on_gold_changed):
        stats.gold_changed.disconnect(_on_gold_changed)
    if stats.stats_recalculated.is_connected(_on_stats_recalculated):
        stats.stats_recalculated.disconnect(_on_stats_recalculated)


func _connect_buttons() -> void:
    if btn_damage and not btn_damage.pressed.is_connected(_on_btn_damage):
        btn_damage.pressed.connect(_on_btn_damage)
    if btn_mana and not btn_mana.pressed.is_connected(_on_btn_mana):
        btn_mana.pressed.connect(_on_btn_mana)
    if btn_reset and not btn_reset.pressed.is_connected(_on_btn_reset):
        btn_reset.pressed.connect(_on_btn_reset)


func _force_sync_all() -> void:
    if stats and hp_bar:
        hp_bar.force_sync(stats.health, stats.current_max_health)
    if stats and mana_bar:
        mana_bar.force_sync(stats.mana, stats.current_max_mana)
    _refresh_labels()


func _refresh_all() -> void:
    if stats and hp_bar:
        hp_bar.set_value(stats.health, stats.current_max_health)
    if stats and mana_bar:
        mana_bar.set_value(stats.mana, stats.current_max_mana)
    _refresh_labels()


func _refresh_labels() -> void:
    if not stats:
        return
    var max_hp := max(1.0, stats.current_max_health)
    var max_mp := max(1.0, stats.current_max_mana)
    if hp_label:
        hp_label.text = "%d / %d" % [int(clamp(stats.health, 0, max_hp)), int(max_hp)]
    if mana_label:
        mana_label.text = "%d / %d" % [int(clamp(stats.mana, 0, max_mp)), int(max_mp)]
    if gold_label:
        gold_label.text = str(stats.gold)


# -------------------------
# Signal Callbacks
# -------------------------


func _on_health_changed(_v: float) -> void:
    if not stats or not hp_bar:
        return
    hp_bar.set_value(stats.health, stats.current_max_health)
    if hp_label:
        var max_hp := max(1.0, stats.current_max_health)
        hp_label.text = "%d / %d" % [int(clamp(stats.health, 0, max_hp)), int(max_hp)]


func _on_mana_changed(_v: float) -> void:
    if not stats or not mana_bar:
        return
    mana_bar.set_value(stats.mana, stats.current_max_mana)
    if mana_label:
        var max_mp := max(1.0, stats.current_max_mana)
        mana_label.text = "%d / %d" % [int(clamp(stats.mana, 0, max_mp)), int(max_mp)]


func _on_gold_changed(_v: int) -> void:
    if gold_label and stats:
        gold_label.text = str(stats.gold)


func _on_stats_recalculated() -> void:
    _force_sync_all()


# -------------------------
# Debug Button Handlers
# -------------------------


func _on_btn_damage() -> void:
    if not stats:
        return
    stats.take_damage(debug_damage_amount)


func _on_btn_mana() -> void:
    if not stats:
        return
    stats.spend_mana(debug_mana_cost)


func _on_btn_reset() -> void:
    if not stats:
        return
    stats.reset_runtime_resources()
    _force_sync_all()
