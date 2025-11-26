class_name PlayerStateMachine
extends StateMachine

@onready var player: Player = self.owner


func _ready() -> void:
    if not player.is_node_ready():
        await player.ready

    super._ready()
