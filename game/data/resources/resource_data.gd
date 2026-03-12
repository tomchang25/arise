class_name ResourceData
extends Resource

enum ResourceKind {
    HEALTH,
    MANA,
    SOUL,
    GOLD,
}

@export_group("Identity")
@export var id: StringName = &""
@export var kind: ResourceKind = ResourceKind.HEALTH
@export var sprite: Texture2D
@export var label: String = ""
@export_multiline var description: String = ""

@export_group("Value")
@export var amount_per_unit: float = 1.0


func is_valid() -> bool:
    return id != StringName() and amount_per_unit > 0.0
