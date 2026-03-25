## delivery_attack_testbed.gd
## stage/testbeds/delivery_attack_testbed/delivery_attack_testbed.gd
##
## Scene tree:
##   Node2D                        ← root, this script
##     TestActor (Node2D)          ($TestActor) at (0, 0)
##     Dummies   (Node2D)          ($Dummies)
##       SoloDummy                 Dummy at (-180, 0)
##       DummyGroup (Node2D)       at (180, 0)
##         Dummy1…DummyN           cluster of dummies
##     AttacksLayer (Node2D)       group "attacks" — spawn parent for deliveries
##     Camera2D
##
## Controls
##   1  →  Line Beam  at mouse position
##   2  →  Heavy Swing at mouse position
##   R  →  Reset all dummies
extends Node2D

@onready var dummies_container: Node2D = $Dummies


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return

    if event.keycode == KEY_R:
        _reset_dummies()


func _reset_dummies() -> void:
    for child in dummies_container.get_children():
        if child is Dummy:
            child.reset_dummy()
        elif child is Node2D:
            for sub in child.get_children():
                if sub is Dummy:
                    sub.reset_dummy()
