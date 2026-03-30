class_name SummonHUD
extends Control
## Bottom HUD bar — compact layout for 1280×720.
## Left side:  group indicators  [1] [2] [3] [4]
## Center:     summon cards      F1  F2  F3  F4
## Right side: souls counter     ♦ 99

@export var summon_manager: SummonManager

@export_group("Nodes")
@export var souls_label: Label
@export var cards_container: HBoxContainer
@export var group_cards_container: HBoxContainer

# Card size: wide enough for name + count, short enough to stay slim
const CARD_SIZE := Vector2(62, 64)
const GROUP_SIZE := Vector2(40, 42)
const CARD_GAP := 4
const GROUP_GAP := 3

const GROUP_COLORS: Array[Color] = [
    Color(1.0, 0.25, 0.25, 1.0), # Group 1 — red
    Color(0.2, 1.0, 0.3, 1.0), # Group 2 — green
    Color(0.25, 0.55, 1.0, 1.0), # Group 3 — blue
    Color(0.75, 0.2, 1.0, 1.0), # Group 4 — purple
]

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
    summon_manager.cooldown_changed.connect(_on_cooldown_changed)

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
    if summon_manager.cooldown_changed.is_connected(_on_cooldown_changed):
        summon_manager.cooldown_changed.disconnect(_on_cooldown_changed)


func _build_groups() -> void:
    if group_cards_container == null or summon_manager == null:
        return

    for child in group_cards_container.get_children():
        child.queue_free()
    _group_panels.clear()
    _group_count_labels.clear()
    _group_styles.clear()

    group_cards_container.add_theme_constant_override("separation", GROUP_GAP)

    for i in summon_manager.group_count:
        var result := _create_group_indicator(i)
        var panel: PanelContainer = result[0]
        var count_lbl: Label = result[1]
        var style: StyleBoxFlat = result[2]
        group_cards_container.add_child(panel)
        _group_panels.append(panel)
        _group_count_labels.append(count_lbl)
        _group_styles.append(style)

    _update_group_highlight(summon_manager.get_active_group() if summon_manager else 0)


func _create_group_indicator(group_index: int) -> Array:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = GROUP_SIZE

    var color: Color = GROUP_COLORS[group_index] if group_index < GROUP_COLORS.size() else Color.WHITE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(color.r * 0.08, color.g * 0.08, color.b * 0.08, 0.85)
    style.border_color = Color(color.r * 0.45, color.g * 0.45, color.b * 0.45, 0.7)
    _set_border_width(style, 1)
    _set_corner_radius(style, 3)
    panel.add_theme_stylebox_override("panel", style)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 4)
    margin.add_theme_constant_override("margin_right", 4)
    margin.add_theme_constant_override("margin_top", 3)
    margin.add_theme_constant_override("margin_bottom", 3)
    panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 1)
    margin.add_child(vbox)

    # Key hint  [1]
    var key_lbl := Label.new()
    key_lbl.add_theme_font_size_override("font_size", 8)
    key_lbl.modulate = Color(1, 1, 1, 0.45)
    key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    key_lbl.text = "[%d]" % (group_index + 1)
    vbox.add_child(key_lbl)

    # Live unit count
    var count_lbl := Label.new()
    count_lbl.add_theme_font_size_override("font_size", 11)
    count_lbl.modulate = color
    count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_lbl.text = "0"
    vbox.add_child(count_lbl)

    return [panel, count_lbl, style]


func _update_group_highlight(active_index: int) -> void:
    for i in _group_styles.size():
        var style: StyleBoxFlat = _group_styles[i]
        var color: Color = GROUP_COLORS[i] if i < GROUP_COLORS.size() else Color.WHITE
        if i == active_index:
            style.bg_color = Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.92)
            style.border_color = color
            _set_border_width(style, 2)
        else:
            style.bg_color = Color(color.r * 0.08, color.g * 0.08, color.b * 0.08, 0.85)
            style.border_color = Color(color.r * 0.45, color.g * 0.45, color.b * 0.45, 0.7)
            _set_border_width(style, 1)


func _build_cards() -> void:
    if cards_container == null or summon_manager == null:
        return

    for child in cards_container.get_children():
        child.queue_free()
    _cards.clear()

    cards_container.add_theme_constant_override("separation", CARD_GAP)

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
    card.custom_minimum_size = CARD_SIZE

    # Card background — tinted by unit color
    var c := army_type.color
    var style := StyleBoxFlat.new()
    style.bg_color = Color(c.r * 0.15, c.g * 0.15, c.b * 0.15, 0.88)
    style.border_color = c
    _set_border_width(style, 2)
    _set_corner_radius(style, 4)
    card.add_theme_stylebox_override("panel", style)

    var margin := MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 5)
    margin.add_theme_constant_override("margin_right", 5)
    margin.add_theme_constant_override("margin_top", 4)
    margin.add_theme_constant_override("margin_bottom", 4)
    card.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "VBox"
    vbox.add_theme_constant_override("separation", 1)
    margin.add_child(vbox)

    # Hotkey badge  F1
    var key_lbl := Label.new()
    key_lbl.name = "KeyLabel"
    key_lbl.add_theme_font_size_override("font_size", 8)
    key_lbl.modulate = Color(1, 1, 1, 0.5)
    key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    vbox.add_child(key_lbl)

    # Unit name
    var name_lbl := Label.new()
    name_lbl.name = "NameLabel"
    name_lbl.add_theme_font_size_override("font_size", 10)
    name_lbl.modulate = army_type.color
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.clip_contents = true
    vbox.add_child(name_lbl)

    # Separator — thin divider line
    var sep := HSeparator.new()
    sep.modulate = Color(1, 1, 1, 0.12)
    vbox.add_child(sep)

    # Cost  ♦ 20
    var cost_lbl := Label.new()
    cost_lbl.name = "CostLabel"
    cost_lbl.add_theme_font_size_override("font_size", 9)
    cost_lbl.modulate = Color(0.85, 0.65, 1.0, 1.0)
    cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(cost_lbl)

    # Count  2/8
    var count_lbl := Label.new()
    count_lbl.name = "CountLabel"
    count_lbl.add_theme_font_size_override("font_size", 9)
    count_lbl.modulate = Color(0.9, 0.9, 0.9, 0.85)
    count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(count_lbl)

    card.init_labels(key_lbl, name_lbl, cost_lbl, count_lbl)
    return card


func _refresh_all() -> void:
    if souls_label and summon_manager:
        souls_label.text = str(summon_manager.get_souls())

    if summon_manager:
        _update_group_highlight(summon_manager.get_active_group())
        for i in _group_count_labels.size():
            _group_count_labels[i].text = str(summon_manager.get_group_count(i))

    for i in _cards.size():
        _refresh_card(i)


func _refresh_card(type_index: int) -> void:
    if type_index >= _cards.size() or summon_manager == null:
        return
    var current := summon_manager.get_count(type_index)
    var max_count := summon_manager.get_max(type_index)
    _cards[type_index].update_count(current, max_count)
    var can_afford := summon_manager.get_souls() >= summon_manager.get_cost(type_index)
    var at_limit := max_count >= 0 and current >= max_count
    _cards[type_index].set_disabled_state(can_afford, at_limit)

# -------------------------
# Helpers
# -------------------------


func _set_border_width(style: StyleBoxFlat, w: int) -> void:
    style.border_width_left = w
    style.border_width_right = w
    style.border_width_top = w
    style.border_width_bottom = w


func _set_corner_radius(style: StyleBoxFlat, r: int) -> void:
    style.corner_radius_top_left = r
    style.corner_radius_top_right = r
    style.corner_radius_bottom_left = r
    style.corner_radius_bottom_right = r

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


func _on_cooldown_changed(type_index: int, remaining: float, total: float) -> void:
    if type_index < _cards.size():
        _cards[type_index].set_cooldown(remaining, total)


func _refresh_affordability() -> void:
    if summon_manager == null:
        return
    for i in _cards.size():
        var can_afford := summon_manager.get_souls() >= summon_manager.get_cost(i)
        var current := summon_manager.get_count(i)
        var max_count := summon_manager.get_max(i)
        var at_limit := max_count >= 0 and current >= max_count
        _cards[i].set_disabled_state(can_afford, at_limit)
