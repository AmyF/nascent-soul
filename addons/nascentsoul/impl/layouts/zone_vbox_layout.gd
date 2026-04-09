@tool
class_name ZoneVBoxLayout extends ZoneLayoutPolicy

@export var item_spacing: float = 10.0
@export var padding_top: float = 10.0

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	var ghost_index = ghost_hint as int if ghost_hint is int else -1
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	var placements: Array[ZonePlacement] = []
	var current_y = _resolve_start_y(render_items, container_size)
	for i in range(render_items.size()):
		var item = render_items[i]
		var size = resolve_item_size(item)
		var x = max(0.0, (container_size.x - size.x) * 0.5)
		placements.append(ZonePlacement.new(item, Vector2(x, current_y), 0.0, Vector2.ONE, i, item == ghost_item))
		current_y += size.y + item_spacing
	return placements

func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int:
	var current_y = _resolve_start_y(items, container_size)
	var count = items.size()
	for i in range(count):
		if not is_instance_valid(items[i]):
			continue
		var h = resolve_item_size(items[i]).y
		var center_y = current_y + h / 2.0
		if mouse_pos.y < center_y:
			return i
		current_y += h + item_spacing
	return count

func _resolve_start_y(items: Array, container_size: Vector2) -> float:
	var total_height = 0.0
	for i in range(items.size()):
		total_height += resolve_item_size(items[i]).y
		if i > 0:
			total_height += item_spacing
	var available_height = max(0.0, container_size.y - padding_top * 2.0)
	return padding_top + max(0.0, (available_height - total_height) * 0.5)
