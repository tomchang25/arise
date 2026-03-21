class_name DebugHUD
extends Control

# -------------------------
# Exports
# -------------------------

@export var stats: Stats

@export_group("Buttons")
@export var btn_hp_restore: Button
@export var btn_hp_damage:  Button
@export var btn_mp_restore: Button
@export var btn_mp_spend:   Button
@export var btn_soul_add:   Button
@export var btn_soul_remove: Button

@export_group("Debug Settings")
@export var debug_damage_amount: float = 150.0
@export var debug_mana_cost:     float = 25.0
@export var debug_soul_amount:   int   = 10

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
	_connect_buttons()
	if stats:
		bind(stats)


func _exit_tree() -> void:
	pass


# -------------------------
# Public API
# -------------------------


func bind(target_stats: Stats) -> void:
	stats = target_stats


# -------------------------
# Internal
# -------------------------


func _connect_buttons() -> void:
	if btn_hp_restore and not btn_hp_restore.pressed.is_connected(_on_hp_restore):
		btn_hp_restore.pressed.connect(_on_hp_restore)
	if btn_hp_damage and not btn_hp_damage.pressed.is_connected(_on_hp_damage):
		btn_hp_damage.pressed.connect(_on_hp_damage)
	if btn_mp_restore and not btn_mp_restore.pressed.is_connected(_on_mp_restore):
		btn_mp_restore.pressed.connect(_on_mp_restore)
	if btn_mp_spend and not btn_mp_spend.pressed.is_connected(_on_mp_spend):
		btn_mp_spend.pressed.connect(_on_mp_spend)
	if btn_soul_add and not btn_soul_add.pressed.is_connected(_on_soul_add):
		btn_soul_add.pressed.connect(_on_soul_add)
	if btn_soul_remove and not btn_soul_remove.pressed.is_connected(_on_soul_remove):
		btn_soul_remove.pressed.connect(_on_soul_remove)


# -------------------------
# Button Handlers
# -------------------------


func _on_hp_restore() -> void:
	if stats:
		stats.recover_health(stats.current_max_health)


func _on_hp_damage() -> void:
	if stats:
		stats.take_damage(debug_damage_amount)


func _on_mp_restore() -> void:
	if stats:
		stats.add_mana(stats.current_max_mana)


func _on_mp_spend() -> void:
	if stats:
		stats.spend_mana(debug_mana_cost)


func _on_soul_add() -> void:
	if stats:
		stats.add_souls(debug_soul_amount)


func _on_soul_remove() -> void:
	if stats:
		stats.spend_souls(debug_soul_amount)
