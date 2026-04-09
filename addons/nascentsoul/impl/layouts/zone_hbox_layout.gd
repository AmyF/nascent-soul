@tool
class_name ZoneHBoxLayout extends ZoneLayoutPolicy

@export var item_spacing: float = 18.0
@export var padding_left: float = 16.0
@export var padding_top: float = 16.0

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	var ghost_index = ghost_hint as int if ghost_hint is int else -1
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	var placements: Array[ZonePlacement] = []
	var current_x = _resolve_start_x(render_items, container_size)
	for i in range(render_items.size()):
		var item = render_items[i]
		var size = resolve_item_size(item)
		var available_height = max(0.0, container_size.y - padding_top * 2.0)
		var y = padding_top + max(0.0, (available_height - size.y) * 0.5)
		placements.append(ZonePlacement.new(item, Vector2(current_x, y), 0.0, Vector2.ONE, i, item == ghost_item))
		current_x += size.x + item_spacing
	return placements

func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int:
	var current_x = _resolve_start_x(items, container_size)
	for i in range(items.size()):
		var width = resolve_item_size(items[i]).x
		if mouse_pos.x < current_x + width / 2.0:
			return i
		current_x += width + item_spacing
	return items.size()

func _resolve_start_x(items: Array, container_size: Vector2) -> float:
	var total_width = 0.0
	for i in range(items.size()):
		total_width += resolve_item_size(items[i]).x
		if i > 0:
			total_width += item_spacing
	var available_width = max(0.0, container_size.x - padding_left * 2.0)
	return padding_left + max(0.0, (available_width - total_width) * 0.5)
