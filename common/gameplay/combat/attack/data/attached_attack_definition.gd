class_name AttachedAttackDefinition
extends AttackDefinition

## Persistent hitbox that lives on the actor and is toggled on/off externally.
## The hitbox node is pre-authored in the scene and wired via CombatModule.hitbox_slots.
## Geometry and orientation are driven by AnimationPlayer — this definition
## only carries the shared damage/hit fields from AttackDefinition.
##
## Use for: contact damage bodies, charge hitboxes, aura effects, beam weapons.
