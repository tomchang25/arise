class_name SpawnAction
extends Resource

enum ParentMode { CTX_SPAWN_PARENT, ANCHOR_PARENT, NODEPATH_FROM_ANCHOR, GROUP_NAME }


func execute(_anchor: Node2D, _ctx: SpawnContext) -> Node:
    return null


func resolve_parent(anchor: Node2D, ctx: SpawnContext, parent_mode: ParentMode, parent_path: NodePath = NodePath(), parent_group: String = "") -> Node:
    match parent_mode:
        ParentMode.CTX_SPAWN_PARENT:
            if ctx != null and ctx.spawn_parent != null:
                return ctx.spawn_parent
            if anchor != null:
                return anchor.get_parent()
            return null

        ParentMode.ANCHOR_PARENT:
            if anchor != null:
                return anchor.get_parent()
            return null

        ParentMode.NODEPATH_FROM_ANCHOR:
            if anchor == null:
                return null
            if parent_path == NodePath():
                return null
            return anchor.get_node_or_null(parent_path)

        ParentMode.GROUP_NAME:
            if anchor == null:
                return null
            if parent_group.is_empty():
                return null

            var tree := anchor.get_tree()
            if tree == null:
                return null

            return tree.get_first_node_in_group(parent_group)

    return null
