class_name SummonHUD
extends Control

@export var summon_manager: SummonManager

@export_group("Nodes")
@export var souls_label: Label
@export var cards_container: HBoxContainer

var _cards: Array[SummonCard] = []


func _ready() -> void:
    if summon_manager:
        bind(summon_manager)
    else:
        var found := get_tree().get_first_node_in_group("summon_manager")
        if found is SummonManager:
            bind(found as SummonManager)


func _exit_tree() -> void:
    _unbind()


# -------------------------
# Public API
# -------------------------


func bind(manager: SummonManager) -> void:
    _unbind()
    summon_manager = manager

    if not summon_manager:
        return

    summon_manager.counts_changed.connect(_on_counts_changed)
    summon_manager.souls_changed.connect(_on_souls_changed)

    _build_cards()
    _refresh_all()


# -------------------------
# Internal
# -------------------------


func _unbind() -> void:
    if not summon_manager:
        return
    if summon_manager.counts_changed.is_connected(_on_counts_changed):
        summon_manager.counts_changed.disconnect(_on_counts_changed)
    if summon_manager.souls_changed.is_connected(_on_souls_changed):
        summon_manager.souls_changed.disconnect(_on_souls_changed)


func _build_cards() -> void:
    if cards_container == null or summon_manager == null:
        return

    for child in cards_container.get_children():
        child.queue_free()
    _cards.clear()

    var hotkeys := ["1", "2", "3", "4"]
    for i in summon_manager.army_types.size():
        var army_type: SummonType = summon_manager.army_types[i]
        var card := _create_card(army_type, hotkeys[i] if i < hotkeys.size() else str(i + 1))
        cards_container.add_child(card)
        _cards.append(card)


func _create_card(army_type: SummonType, hotkey: String) -> SummonCard:
    var card := SummonCard.new()
    card.custom_minimum_size = Vector2(80, 90)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(army_type.color.r * 0.2, army_type.color.g * 0.2, army_type.color.b * 0.2, 0.85)
    style.border_color = army_type.color
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    card.add_theme_stylebox_override("panel", style)

    var margin := MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 6)
    margin.add_theme_constant_override("margin_right", 6)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_bottom", 6)
    card.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 3)
    margin.add_child(vbox)

    var key_lbl := Label.new()
    key_lbl.name = "KeyLabel"
    key_lbl.add_theme_font_size_override("font_size", 8)
    key_lbl.modulate = Color(1, 1, 1, 0.6)
    key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(key_lbl)

    var name_lbl := Label.new()
    name_lbl.name = "NameLabel"
    name_lbl.add_theme_font_size_override("font_size", 10)
    name_lbl.modulate = army_type.color
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(name_lbl)

    var cost_lbl := Label.new()
    cost_lbl.name = "CostLabel"
    cost_lbl.add_theme_font_size_override("font_size", 8)
    cost_lbl.modulate = Color(0.8, 0.6, 1.0, 1.0)
    cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(cost_lbl)

    var count_lbl := Label.new()
    count_lbl.name = "CountLabel"
    count_lbl.add_theme_font_size_override("font_size", 9)
    count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(count_lbl)

    card.setup(army_type, hotkey)
    return card


func _refresh_all() -> void:
    if souls_label and summon_manager:
        souls_label.text = str(summon_manager.get_souls())

    for i in _cards.size():
        _refresh_card(i)


func _refresh_card(type_index: int) -> void:
    if type_index >= _cards.size() or summon_manager == null:
        return
    _cards[type_index].update_count(
        summon_manager.get_count(type_index),
        summon_manager.get_max(type_index)
    )
    var can_afford := summon_manager.get_souls() >= summon_manager.get_cost(type_index)
    _cards[type_index].set_affordable(can_afford)


# -------------------------
# Signal Callbacks
# -------------------------


func _on_counts_changed(type_index: int, current: int, max_count: int) -> void:
    if type_index < _cards.size():
        _cards[type_index].update_count(current, max_count)
    _refresh_affordability()


func _on_souls_changed(souls: int) -> void:
    if souls_label:
        souls_label.text = str(souls)
    _refresh_affordability()


func _refresh_affordability() -> void:
    if summon_manager == null:
        return
    for i in _cards.size():
        var can_afford := summon_manager.get_souls() >= summon_manager.get_cost(i)
        _cards[i].set_affordable(can_afford)
