class_name LootDropTable
extends Resource

@export_range(1, 99, 1) var rolls: int = 1
@export var entries: Array[LootDropEntry] = []


func has_valid_entries() -> bool:
    for entry in entries:
        if entry != null and entry.is_valid():
            return true
    return false
