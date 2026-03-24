class_name SummonHUD
extends Control

@export var summon_manager: SummonManager

@export_group("Nodes")
@export var souls_label: Label
@export var cards_container: HBoxContainer
@export var group_cards_container: HBoxContainer

var _cards: Array[SummonCard] = []
var _group_panels: Array[PanelContainer] = []
var _group_count_labels: Array[Label] = []
var _group_styles: Array[StyleBoxFlat] = []


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
    summon_manager.active_group_changed.connect(_on_active_group_changed)
    summon_manager.group_count_changed.connect(_on_group_count_changed)

    _build_groups()
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
    if summon_manager.active_group_changed.is_connected(_on_active_group_changed):
        summon_manager.active_group_changed.disconnect(_on_active_group_changed)
    if summon_manager.group_count_changed.is_connected(_on_group_count_changed):
        summon_manager.group_count_changed.disconnect(_on_group_count_changed)


func _build_groups() -> void:
    if group_cards_container == null:
        return

    for child in group_cards_container.get_children():
        child.queue_free()
    _group_panels.clear()
    _group_count_labels.clear()
    _group_styles.clear()

    for i in 4:
        var result := _create_group_indicator(i)
        var panel: PanelContainer = result[0]
        var count_lbl: Label = result[1]
        var style: StyleBoxFlat = result[2]
        group_cards_container.add_child(panel)
        _group_panels.append(panel)
        _group_count_labels.append(count_lbl)
        _group_styles.append(style)

    var active := summon_manager.get_active_group() if summon_manager else 0
    _update_group_highlight(active)


func _create_group_indicator(group_index: int) -> Array:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(54, 46)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.06, 0.12, 0.85)
    style.border_color = Color(0.4, 0.4, 0.5, 1)
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    panel.add_theme_stylebox_override("panel", style)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 5)
    margin.add_theme_constant_override("margin_right", 5)
    margin.add_theme_constant_override("margin_top", 4)
    margin.add_theme_constant_override("margin_bottom", 4)
    panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    margin.add_child(vbox)

    var key_lbl := Label.new()
    key_lbl.add_theme_font_size_override("font_size", 7)
    key_lbl.modulate = Color(1, 1, 1, 0.5)
    key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    key_lbl.text = "[%d]" % (group_index + 1)
    vbox.add_child(key_lbl)

    var name_lbl := Label.new()
    name_lbl.add_theme_font_size_override("font_size", 8)
    name_lbl.modulate = Color(0.8, 0.8, 0.9, 1)
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.text = "G%d" % (group_index + 1)
    vbox.add_child(name_lbl)

    var count_lbl := Label.new()
    count_lbl.add_theme_font_size_override("font_size", 9)
    count_lbl.modulate = Color(1, 1, 1, 1)
    count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_lbl.text = "0"
    vbox.add_child(count_lbl)

    return [panel, count_lbl, style]


func _update_group_highlight(active_index: int) -> void:
    for i in _group_styles.size():
        var style: StyleBoxFlat = _group_styles[i]
        if i == active_index:
            style.bg_color = Color(0.15, 0.15, 0.3, 0.9)
            style.border_color = Color(0.9, 0.85, 1.0, 1)
            style.border_width_left = 2
            style.border_width_right = 2
            style.border_width_top = 2
            style.border_width_bottom = 2
        else:
            style.bg_color = Color(0.06, 0.06, 0.12, 0.85)
            style.border_color = Color(0.4, 0.4, 0.5, 1)
            style.border_width_left = 1
            style.border_width_right = 1
            style.border_width_top = 1
            style.border_width_bottom = 1


func _build_cards() -> void:
    if cards_container == null or summon_manager == null:
        return

    for child in cards_container.get_children():
        child.queue_free()
    _cards.clear()

    var hotkeys := ["F1", "F2", "F3", "F4"]
    for i in summon_manager.army_types.size():
        var army_type: SummonType = summon_manager.army_types[i]
        var hotkey: String = hotkeys[i] if i < hotkeys.size() else "F%d" % (i + 1)
        var card := _create_card(army_type)
        cards_container.add_child(card)
        card.setup(army_type, hotkey)
        _cards.append(card)


func _create_card(army_type: SummonType) -> SummonCard:
    var card := SummonCard.new()
    card.custom_minimum_size = Vector2(66, 74)

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
    margin.add_theme_constant_override("margin_left", 5)
    margin.add_theme_constant_override("margin_right", 5)
    margin.add_theme_constant_override("margin_top", 5)
    margin.add_theme_constant_override("margin_bottom", 5)
    card.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 2)
    margin.add_child(vbox)

    var key_lbl := Label.new()
    key_lbl.name = "KeyLabel"
    key_lbl.add_theme_font_size_override("font_size", 7)
    key_lbl.modulate = Color(1, 1, 1, 0.6)
    key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(key_lbl)

    var name_lbl := Label.new()
    name_lbl.name = "NameLabel"
    name_lbl.add_theme_font_size_override("font_size", 9)
    name_lbl.modulate = army_type.color
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(name_lbl)

    var cost_lbl := Label.new()
    cost_lbl.name = "CostLabel"
    cost_lbl.add_theme_font_size_override("font_size", 7)
    cost_lbl.modulate = Color(0.8, 0.6, 1.0, 1.0)
    cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(cost_lbl)

    var count_lbl := Label.new()
    count_lbl.name = "CountLabel"
    count_lbl.add_theme_font_size_override("font_size", 8)
    count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(count_lbl)

    return card


func _refresh_all() -> void:
    if souls_label and summon_manager:
        souls_label.text = str(summon_manager.get_souls())

    if summon_manager:
        _update_group_highlight(summon_manager.get_active_group())
        for i in 4:
            if i < _group_count_labels.size():
                _group_count_labels[i].text = str(summon_manager.get_group_count(i))

    for i in _cards.size():
        _refresh_card(i)


func _refresh_card(type_index: int) -> void:
    if type_index >= _cards.size() or summon_manager == null:
        return
    _cards[type_index].update_count(
        summon_manager.get_count(type_index),
        summon_manager.get_max(type_index),
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


func _on_active_group_changed(group_index: int) -> void:
    _update_group_highlight(group_index)


func _on_group_count_changed(group_index: int, count: int) -> void:
    if group_index < _group_count_labels.size():
        _group_count_labels[group_index].text = str(count)


func _refresh_affordability() -> void:
    if summon_manager == null:
        return
    for i in _cards.size():
        var can_afford := summon_manager.get_souls() >= summon_manager.get_cost(i)
        _cards[i].set_affordable(can_afford)
