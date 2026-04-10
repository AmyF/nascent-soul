@tool
class_name ZoneDragVisualFactory extends Resource

func create_group_ghost(context: ZoneContext, source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	var resolved_anchor = anchor_item if is_instance_valid(anchor_item) else source_items[0] if not source_items.is_empty() else null
	if not is_instance_valid(resolved_anchor):
		return null
	return create_ghost(context, resolved_anchor)

func create_ghost(_context: ZoneContext, _source_item: ZoneItemControl) -> Control:
	return null

func create_group_drag_proxy(context: ZoneContext, source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	var resolved_anchor = anchor_item if is_instance_valid(anchor_item) else source_items[0] if not source_items.is_empty() else null
	if not is_instance_valid(resolved_anchor):
		return null
	return create_drag_proxy(context, resolved_anchor)

func create_drag_proxy(_context: ZoneContext, _source_item: ZoneItemControl) -> Control:
	return null
