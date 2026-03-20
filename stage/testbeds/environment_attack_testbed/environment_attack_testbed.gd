## environment_attack_testbed.gd
## stage/testbeds/environment_attack/environment_attack_testbed.gd
##
## Scene tree:
##   Node2D                  ← root, this script
##     EnvironmentSpawner    ($EnvironmentSpawner)
##     Dummies               ($Dummies) Node2D — place Dummy instances as children
##     Camera2D
##
## Controls
##   1  →  aoe_burst   at mouse position
##   2  →  toxic_cloud at mouse position
##   R  →  reset all dummies inside $Dummies
extends Node2D

@onready var spawner: EnvironmentSpawner = $EnvironmentSpawner
@onready var dummies_container: Node2D = $Dummies


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return

    var mouse := get_global_mouse_position()

    match event.keycode:
        KEY_1:
            spawner.fire(0, mouse)
        KEY_2:
            spawner.fire(1, mouse)
        KEY_R:
            for dummy in dummies_container.get_children():
                if dummy is Dummy:
                    dummy.reset_dummy()
