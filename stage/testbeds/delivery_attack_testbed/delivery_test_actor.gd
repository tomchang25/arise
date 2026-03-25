## delivery_test_actor.gd
## stage/testbeds/delivery_attack_testbed/delivery_test_actor.gd
##
## Simple stationary actor that fires delivery-based attacks toward the mouse.
##
## Controls
##   1  →  Line Beam  (5 s telegraph → 5 s continuous beam)
##   2  →  Heavy Swing (5 s telegraph → 0.2 s sector burst)
##
## The actor sits at (0, 0) in the testbed. It has no movement — its sole role
## is to own the PlaceAttackModules and provide the attacker_source reference
## that effects use to draw their direction lines.
extends Node2D

@export var stats: Stats
@export var line_beam_def: PlaceAttackDefinition
@export var heavy_swing_def: PlaceAttackDefinition

var _line_beam: PlaceAttackModule
var _heavy_swing: PlaceAttackModule


func _ready() -> void:
    _line_beam = PlaceAttackModule.new()
    _line_beam.setup(line_beam_def, stats)
    add_child(_line_beam)

    _heavy_swing = PlaceAttackModule.new()
    _heavy_swing.setup(heavy_swing_def, stats)
    add_child(_heavy_swing)


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return

    var mouse := get_global_mouse_position()

    match event.keycode:
        KEY_1:
            if _line_beam.can_attack():
                _line_beam.execute_attack(mouse)
                _line_beam.end_attack()
        KEY_2:
            if _heavy_swing.can_attack():
                _heavy_swing.execute_attack(mouse)
                _heavy_swing.end_attack()
