class_name ZoneDragSession extends RefCounted

var source_zone: Node = null
var items: Array[ZoneItemControl] = []
var anchor_item: ZoneItemControl = null
var drag_offset: Vector2 = Vector2.ZERO
var cursor_proxy: Control = null
var hover_zone: Node = null
var requested_target: ZonePlacementTarget = ZonePlacementTarget.invalid()
var preview_target: ZonePlacementTarget = ZonePlacementTarget.invalid()

func _init(p_source_zone: Node = null, p_items: Array[ZoneItemControl] = [], p_anchor_item: ZoneItemControl = null, p_drag_offset: Vector2 = Vector2.ZERO, p_cursor_proxy: Control = null) -> void:
	source_zone = p_source_zone
	items = p_items.duplicate()
	anchor_item = p_anchor_item if is_instance_valid(p_anchor_item) else items[0] if not items.is_empty() else null
	drag_offset = p_drag_offset
	cursor_proxy = p_cursor_proxy

func cleanup() -> void:
	if is_instance_valid(cursor_proxy):
		cursor_proxy.queue_free()
	cursor_proxy = null
	anchor_item = null
	hover_zone = null
	requested_target = ZonePlacementTarget.invalid()
	preview_target = ZonePlacementTarget.invalid()

func prune_invalid_items() -> bool:
	var valid_items: Array[ZoneItemControl] = []
	for item in items:
		if is_instance_valid(item):
			valid_items.append(item)
	var changed = valid_items.size() != items.size()
	items = valid_items
	if not is_instance_valid(anchor_item) or anchor_item not in items:
		var next_anchor = items[0] if not items.is_empty() else null
		if anchor_item != next_anchor:
			changed = true
		anchor_item = next_anchor
	return changed
