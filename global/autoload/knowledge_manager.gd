extends Node

# Flat key-value skill registry.
# Keys are free-form skill IDs matching LayerUnlockAction.required_skill values.
# Full skill system design is deferred to the knowledge system overhaul.
var _levels: Dictionary = {}


# Returns the player's current level in the given skill.
# Returns 0 for unknown or unlearned skills.
func get_level(skill_id: String) -> int:
	return _levels.get(skill_id, 0)


# Sets the player's level for a skill. Internal use only during development.
func _set_level(skill_id: String, level: int) -> void:
	_levels[skill_id] = level
