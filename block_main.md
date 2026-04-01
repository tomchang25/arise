# Block Main — Task Tracker

## Identity Layer System

Replaces `VeiledType`, `ItemData.clues`, and the binary veil/unveil model with a
tiered inspection-gate system.

### Done

- [x] `LayerUnlockAction` resource definition (`data/_definitions/layer_unlock_action.gd`)
- [x] `IdentityLayer` resource definition (`data/_definitions/identity_layer.gd`)
- [x] `CategoryData` resource definition (`data/_definitions/category_data.gd`)
- [x] `ItemData` migration: removed old fields (`clues`, `veiled_types`, `true_value`, `super_category`, `category`, `weight`, `grid_size`, `id`, `label`, `description`, `sprite`); added `item_id`, `identity_layers`, `category_data`
- [x] `ItemEntry` migration: added `layer_index`, `active_layer()`, `next_unlock_action()`, `is_veiled()`, `is_at_final_layer()`
- [x] `ClueEvaluator` remove — did not exist; no action required
- [x] `KnowledgeManager` stub — flat `get_level()` interface (`global/autoload/knowledge_manager.gd`)
- [x] `data/categories/` folder created
- [x] `data/identity_layers/` folder created

### Soon

- [ ] Inspection scene: layer advance check via `next_unlock_action()` + `KnowledgeManager.get_level()`
- [ ] Appraisal reveal: show Layer 1 identity on items still at layer 0 at settlement
- [ ] Auction pricing: lerp `rolled_price` between NPC min/max skill layer `base_value`
- [ ] Register `KnowledgeManager` as autoload in `project.godot`
- [ ] Author `.tres` assets for existing items under new `ItemData` schema
- [ ] Delete `data/veiled_types/` after migration (folder did not exist — confirm with designer)

### Notes

- `ItemData.item_id` replaces the old `ItemData.id` (`StringName` → `String`). Update any
  `.tres` assets and scenes that reference the old field.
- `ItemData.is_valid()` now requires `category_data != null` and at least one `IdentityLayer`.
- `KnowledgeManager._set_level()` is a dev helper only; it will be replaced by the full
  knowledge system during the auction + knowledge overhaul.
