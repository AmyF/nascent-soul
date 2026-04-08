@tool
class_name ZoneLayoutPolicy extends Resource

func calculate(items: Array[Control], container_size: Vector2, ghost_item: Control = null, ghost_index: int = -1) -> Array[ZonePlacement]:
	return []

func get_insertion_index(items: Array[Control], container_size: Vector2, mouse_pos: Vector2) -> int:
	return items.size()

func resolve_item_size(item: Control) -> Vector2:
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)
