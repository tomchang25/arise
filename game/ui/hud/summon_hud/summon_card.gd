class_name SummonCard
extends PanelContainer

@onready var key_label: Label = $Margin/VBox/KeyLabel
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var cost_label: Label = $Margin/VBox/CostLabel
@onready var count_label: Label = $Margin/VBox/CountLabel

var _army_type: SummonType
var _hotkey: String


func setup(army_type: SummonType, hotkey: String) -> void:
    _army_type = army_type
    _hotkey = hotkey

    if key_label:
        key_label.text = "[%s]" % hotkey
    if name_label:
        name_label.text = army_type.label
    if cost_label:
        cost_label.text = "%d souls" % army_type.soul_cost
    if count_label:
        count_label.text = "0 / %d" % army_type.max_count


func update_count(current: int, max_count: int) -> void:
    if count_label:
        count_label.text = "%d / %d" % [current, max_count]


func set_affordable(can_afford: bool) -> void:
    modulate.a = 1.0 if can_afford else 0.5
