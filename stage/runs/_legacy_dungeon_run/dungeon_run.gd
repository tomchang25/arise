class_name DungeonRun
extends Node

@export var dungeon_manager: DungeonManager
@export var mission_manager: Node  # later replace with your MissionManager type


func _ready() -> void:
    if dungeon_manager == null:
        push_error("DungeonRun: dungeon_manager not assigned.")
        return

    dungeon_manager.dungeon_built.connect(_on_dungeon_built)


func _on_dungeon_built(layout: DungeonLayout, registry: RoomRegistry) -> void:
    # This is where the mission system will start.
    # For now, just print a sanity check.
    print("Dungeon built. Rooms:", registry.get_room_ids().size(), " Start:", registry.start_room_id)

    # Later:
    # if mission_manager:
    #     mission_manager.start_run(layout, registry)
