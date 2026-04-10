@tool
extends ZoneLayoutPolicy

@export var reveal_y: float = 18.0
@export var padding_left: float = 1.0
@export var padding_top: float = 1.0

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	var ghost_index = ghost_hint as int if ghost_hint is int else -1
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	var placements: Array[ZonePlacement] = []
	var effective_reveal = _resolve_reveal(render_items, container_size)
	var current_y = padding_top
	for index in range(render_items.size()):
		var item = render_items[index]
		var item_size = resolve_item_size(item)
		var x = padding_left + max(0.0, (container_size.x - padding_left * 2.0 - item_size.x) * 0.5)
		placements.append(ZonePlacement.new(item, Vector2(x, current_y), 0.0, Vector2.ONE, index, item == ghost_item))
		current_y += effective_reveal
	return placements

func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int:
	var effective_reveal = _resolve_reveal(items, container_size)
	var current_y = padding_top
	for index in range(items.size()):
		var item = items[index]
		var item_size = resolve_item_size(item)
		var cutoff = current_y + minf(item_size.y, effective_reveal) * 0.5
		if mouse_pos.y < cutoff:
			return index
		current_y += effective_reveal
	return items.size()

func _resolve_reveal(items: Array, container_size: Vector2) -> float:
	if items.size() <= 1:
		return reveal_y
	var max_height = 0.0
	for item in items:
		max_height = max(max_height, resolve_item_size(item).y)
	var available = max(0.0, container_size.y - padding_top * 2.0 - max_height)
	if available <= 0.0:
		return reveal_y
	return minf(reveal_y, available / float(items.size() - 1))
