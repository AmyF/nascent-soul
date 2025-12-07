class_name ZoneVBoxLayout extends ZoneLayout

@export var item_spacing: float = 10.0
@export var padding_top: float = 10.0

func calculate(items: Array[Control], container_size: Vector2, ghost_index: int = -1, ghost_size: Vector2 = Vector2.ZERO, ghost_instance: Control = null) -> Dictionary:
	var result = {}
	var current_y = padding_top
	
	var total_count = items.size()
	if ghost_index != -1: total_count += 1
	
	var item_iter = 0
	
	for i in range(total_count):
		var is_ghost_slot = (i == ghost_index)
		var pos = Vector2(0, current_y)
		var size_y = 0.0
		
		if is_ghost_slot:
			size_y = ghost_size.y
			if is_instance_valid(ghost_instance):
				result[ghost_instance] = {
					"pos": pos,
					"rot": 0.0,
					"scale": Vector2.ONE,
					"z_index": 0
				}
		else:
			if item_iter < items.size():
				var item = items[item_iter]
				if is_instance_valid(item):
					result[item] = {
						"pos": pos,
						"rot": 0.0,
						"scale": Vector2.ONE,
						"z_index": 0
					}
					size_y = item.size.y
				item_iter += 1
		
		current_y += size_y + item_spacing
		
	return result

func get_insertion_index(items: Array[Control], container_size: Vector2, mouse_pos: Vector2) -> int:
	var current_y = padding_top
	var count = items.size()
	
	for i in range(count):
		if not is_instance_valid(items[i]): continue
		var h = items[i].size.y
		var center_y = current_y + h / 2.0
		
		if mouse_pos.y < center_y:
			return i
		
		current_y += h + item_spacing
		
	return count
