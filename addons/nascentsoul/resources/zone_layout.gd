class_name ZoneLayout extends Resource

func calculate(items: Array[Control], container_size: Vector2, ghost_index: int = -1, ghost_size: Vector2 = Vector2.ZERO, ghost_instance: Control = null) -> Dictionary:
	return {}

func get_insertion_index(items: Array[Control], container_size: Vector2, mouse_pos: Vector2) -> int:
	return items.size()