class_name AttachedAttackDefinition
extends AttackDefinition
## Persistent hitbox that lives on the actor and is toggled on/off externally.
##
## The hitbox node is pre-authored in the scene and registered in CombatModule.hitbox_slots.
## Geometry and orientation are driven by AnimationPlayer — this definition
## carries the shared damage scaling from AttackDefinition plus its own hit config.
##
## Hit config lives here (not on EffectPhaseDefinition) because attached attacks
## have no phases — they are toggled directly and have a single persistent hitbox.
##
## Use for: contact damage bodies, charge hitboxes, aura effects, beam weapons.
##
## hitbox_slot_id must match the slot_id on the intended Hitbox node in the scene.
## CombatModule searches hitbox_slots by slot_id at setup time — no ordering required.

@export_group("Hitbox Binding")
## Must match the slot_id set on the target Hitbox node in the inspector (case-sensitive).
@export var hitbox_slot_id: StringName = ""

@export_group("Hit")
@export var knockback_force: float = 40.0
@export var max_targets: int = 1

## Seconds between repeated hits on the same victim while they remain inside the hitbox.
## 0 = hit on enter only, never repeat while inside.
@export var damage_interval: float = 0.0

## If true, the victim's hit record is cleared when they exit the hitbox —
## re-entering will trigger a hit again.
## If false, a victim hit once is immune for the entire hitbox lifetime.
@export var clear_records_on_exit: bool = false
