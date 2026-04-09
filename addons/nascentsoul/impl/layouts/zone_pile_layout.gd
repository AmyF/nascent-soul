@tool
class_name ZonePileLayout extends ZoneLayoutPolicy

@export var overlap_x: float = 26.0
@export var overlap_y: float = 0.0
@export var padding_left: float = 18.0
@export var padding_top: float = 18.0

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	var ghost_index = ghost_hint as int if ghost_hint is int else -1
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	var placements: Array[ZonePlacement] = []
	var effective_overlap = _resolve_effective_overlap(render_items, container_size)
	for i in range(render_items.size()):
		var item = render_items[i]
		var pos = Vector2(
			padding_left + i * effective_overlap.x,
			padding_top + i * effective_overlap.y
		)
		placements.append(ZonePlacement.new(item, pos, 0.0, Vector2.ONE, i, item == ghost_item))
	return placements

func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int:
	var effective_overlap = _resolve_effective_overlap(items, container_size)
	for i in range(items.size()):
		var x = padding_left + i * effective_overlap.x
		var width = resolve_item_size(items[i]).x
		if mouse_pos.x < x + width / 2.0:
			return i
	return items.size()

func would_escape_container(container_size: Vector2, item_count: int = 5, sample_item_size: Vector2 = Vector2(120, 180)) -> bool:
	if container_size == Vector2.ZERO or item_count <= 0:
		return false
	var requested_width = padding_left * 2.0 + sample_item_size.x + max(0, item_count - 1) * abs(overlap_x)
	var requested_height = padding_top * 2.0 + sample_item_size.y + max(0, item_count - 1) * abs(overlap_y)
	return requested_width > container_size.x or requested_height > container_size.y

func _resolve_effective_overlap(items: Array, container_size: Vector2) -> Vector2:
	if items.is_empty():
		return Vector2(overlap_x, overlap_y)
	var max_item_size = Vector2.ZERO
	for item in items:
		var size = resolve_item_size(item)
		max_item_size.x = max(max_item_size.x, size.x)
		max_item_size.y = max(max_item_size.y, size.y)
	var count = items.size()
	var effective_x = overlap_x
	if count > 1 and overlap_x > 0.0:
		var available_x = max(0.0, container_size.x - padding_left * 2.0 - max_item_size.x)
		effective_x = min(overlap_x, available_x / float(count - 1))
	var effective_y = overlap_y
	if count > 1 and overlap_y > 0.0:
		var available_y = max(0.0, container_size.y - padding_top * 2.0 - max_item_size.y)
		effective_y = min(overlap_y, available_y / float(count - 1))
	return Vector2(effective_x, effective_y)
