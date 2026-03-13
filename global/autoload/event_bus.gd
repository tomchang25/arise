extends Node

# -------------------------
# Combat
# -------------------------

signal enemy_killed(enemy: Node)

# -------------------------
# Objectives
# -------------------------

signal objective_changed(objective: Objective)
signal objective_completed(objective: Objective)
signal extraction_completed
