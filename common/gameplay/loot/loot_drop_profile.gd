class_name LootDropProfile
extends Resource

@export var tables: Array[LootDropTable] = []


func has_valid_tables() -> bool:
    for table in tables:
        if table != null and table.has_valid_entries() and table.rolls > 0:
            return true
    return false
