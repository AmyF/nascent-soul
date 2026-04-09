class_name ZoneDragSession extends RefCounted

var source_zone: Node = null
var items: Array[Control] = []
var drag_offset: Vector2 = Vector2.ZERO
var cursor_proxy: Control = null
var hover_zone: Node = null
var requested_target: ZonePlacementTarget = ZonePlacementTarget.invalid()
var preview_target: ZonePlacementTarget = ZonePlacementTarget.invalid()

var requested_index: int:
	get:
		return requested_target.slot if requested_target != null and requested_target.is_linear() else -1
	set(value):
		requested_target = ZonePlacementTarget.linear(value) if value >= 0 else ZonePlacementTarget.invalid()

var preview_index: int:
	get:
		return preview_target.slot if preview_target != null and preview_target.is_linear() else -1
	set(value):
		preview_target = ZonePlacementTarget.linear(value) if value >= 0 else ZonePlacementTarget.invalid()

func _init(p_source_zone: Node = null, p_items: Array[Control] = [], p_drag_offset: Vector2 = Vector2.ZERO, p_cursor_proxy: Control = null) -> void:
	source_zone = p_source_zone
	items = p_items.duplicate()
	drag_offset = p_drag_offset
	cursor_proxy = p_cursor_proxy

func cleanup() -> void:
	if is_instance_valid(cursor_proxy):
		cursor_proxy.queue_free()
	cursor_proxy = null
	hover_zone = null
	requested_target = ZonePlacementTarget.invalid()
	preview_target = ZonePlacementTarget.invalid()

func prune_invalid_items() -> bool:
	var valid_items: Array[Control] = []
	for item in items:
		if is_instance_valid(item):
			valid_items.append(item)
	var changed = valid_items.size() != items.size()
	items = valid_items
	return changed
