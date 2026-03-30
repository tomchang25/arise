class_name SummonCard
extends PanelContainer
## SummonCard holds direct Label references instead of @onready path lookups
## because the card's child nodes are built programmatically by SummonHUD
## BEFORE the card is added to the scene tree.

var _key_label: Label
var _name_label: Label
var _cost_label: Label
var _count_label: Label
var _icon_rect: TextureRect

var _army_type: SummonType
var _hotkey: String
var _cooldown_ratio: float = 0.0


## Called by SummonHUD after building child nodes, before add_child().
func init_labels(
        key_lbl: Label,
        name_lbl: Label,
        cost_lbl: Label,
        count_lbl: Label,
        icon_rect: TextureRect = null,
) -> void:
    _key_label = key_lbl
    _name_label = name_lbl
    _cost_label = cost_lbl
    _count_label = count_lbl
    _icon_rect = icon_rect


func setup(army_type: SummonType, hotkey: String) -> void:
    _army_type = army_type
    _hotkey = hotkey

    if _key_label:
        _key_label.text = hotkey
    if _name_label:
        _name_label.text = army_type.label
    if _cost_label:
        _cost_label.text = "%d" % army_type.soul_cost
    if _count_label:
        _count_label.text = "0/%d" % army_type.max_count
    if _icon_rect and army_type.get("icon"):
        _icon_rect.texture = army_type.icon


func update_count(current: int, max_count: int) -> void:
    if _count_label:
        _count_label.text = "%d/%d" % [current, max_count]


func set_disabled_state(can_afford: bool, at_limit: bool) -> void:
    if at_limit:
        modulate = Color(0.4, 0.4, 0.4, 0.6)
    elif not can_afford:
        modulate = Color(1.0, 1.0, 1.0, 0.5)
    else:
        modulate = Color(1.0, 1.0, 1.0, 1.0)


func set_cooldown(remaining: float, total: float) -> void:
    _cooldown_ratio = remaining / total if total > 0.0 else 0.0
    queue_redraw()


func _draw() -> void:
    if _cooldown_ratio <= 0.0:
        return
    # Cooldown overlay — fills from bottom up as cooldown drains
    var h := size.y * _cooldown_ratio
    var y := size.y - h
    draw_rect(Rect2(0, y, size.x, h), Color(1.0, 1.0, 1.0, 0.35))
