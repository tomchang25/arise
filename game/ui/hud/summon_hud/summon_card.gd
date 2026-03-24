class_name SummonCard
extends PanelContainer
## SummonCard holds direct Label references instead of @onready path lookups
## because the card's child nodes are built programmatically by SummonHUD
## BEFORE the card is added to the scene tree — @onready would fire too early
## and return null for every label.

var _key_label: Label
var _name_label: Label
var _cost_label: Label
var _count_label: Label

var _army_type: SummonType
var _hotkey: String


## Called by SummonHUD immediately after building the card's child nodes,
## so all label references are valid before setup() runs.
func init_labels(key_lbl: Label, name_lbl: Label, cost_lbl: Label, count_lbl: Label) -> void:
    _key_label = key_lbl
    _name_label = name_lbl
    _cost_label = cost_lbl
    _count_label = count_lbl


func setup(army_type: SummonType, hotkey: String) -> void:
    _army_type = army_type
    _hotkey = hotkey

    if _key_label:
        _key_label.text = "[%s]" % hotkey
    if _name_label:
        _name_label.text = army_type.label
    if _cost_label:
        _cost_label.text = "%d souls" % army_type.soul_cost
    if _count_label:
        _count_label.text = "0 / %d" % army_type.max_count


func update_count(current: int, max_count: int) -> void:
    if _count_label:
        _count_label.text = "%d / %d" % [current, max_count]


func set_affordable(can_afford: bool) -> void:
    modulate.a = 1.0 if can_afford else 0.5
