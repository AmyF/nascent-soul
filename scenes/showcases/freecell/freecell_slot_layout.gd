@tool
class_name FreeCellSlotLayout extends ZoneLayoutPolicy

@export var padding_left: float = 1.0
@export var padding_top: float = 1.0

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], _container_size: Vector2, ghost_item: Control = null, _ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	if is_instance_valid(ghost_item):
		render_items.append(ghost_item)
	var placements: Array[ZonePlacement] = []
	var position := Vector2(padding_left, padding_top)
	for index in range(render_items.size()):
		var item = render_items[index]
		placements.append(ZonePlacement.new(item, position, 0.0, Vector2.ONE, index, item == ghost_item))
	return placements

func get_insertion_index(items: Array[ZoneItemControl], _container_size: Vector2, _mouse_pos: Vector2) -> int:
	return items.size()
