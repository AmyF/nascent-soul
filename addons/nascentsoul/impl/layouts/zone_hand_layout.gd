class_name ZoneHandLayout extends ZoneLayout

@export var arch_angle_deg: float = 30.0
@export var arch_height: float = 20.0
@export var card_spacing_angle: float = 5.0
@export var center_offset_y: float = 500.0

func calculate(items: Array[Control], container_size: Vector2, ghost_index: int = -1, ghost_size: Vector2 = Vector2.ZERO, ghost_instance: Control = null) -> Dictionary:
	var result = {}
	
	var total_items = items.size()
	if ghost_index != -1: total_items += 1
	if total_items == 0: return {}
	
	var center = Vector2(container_size.x / 2.0, container_size.y + center_offset_y)
	var radius = center_offset_y - arch_height
	
	var total_spread = (total_items - 1) * card_spacing_angle
	total_spread = min(total_spread, arch_angle_deg * 2)
	var start_angle = deg_to_rad(-90 - total_spread / 2.0)
	var step = 0
	if total_items > 1:
		step = deg_to_rad(total_spread / (total_items - 1))
	
	var item_iter = 0
	for i in range(total_items):
		var angle = start_angle + i * step
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var rot = angle + PI/2
		
		if i == ghost_index:
			if is_instance_valid(ghost_instance):
				result[ghost_instance] = {
					"pos": pos - ghost_size / 2.0,
					"rot": rot,
					"scale": Vector2.ONE,
					"z_index": i
				}
		else:
			if item_iter < items.size():
				var item = items[item_iter]
				if is_instance_valid(item):
					result[item] = {
						"pos": pos - item.size / 2.0,
						"rot": rot,
						"scale": Vector2.ONE,
						"z_index": i
					}
				item_iter += 1
				
	return result

func get_insertion_index(items: Array[Control], container_size: Vector2, mouse_pos: Vector2) -> int:
	var count = items.size()
	if count == 0: return 0
	
	var center = Vector2(container_size.x / 2.0, container_size.y + center_offset_y)
	var vec = mouse_pos - center
	var angle = vec.angle()
	
	var total_spread = count * card_spacing_angle
	total_spread = min(total_spread, arch_angle_deg * 2)
	var start_angle = deg_to_rad(-90 - total_spread / 2.0)
	var end_angle = deg_to_rad(-90 + total_spread / 2.0)
	
	if angle < start_angle: return 0
	if angle > end_angle: return count
	
	var t = (angle - start_angle) / (end_angle - start_angle)
	return int(round(t * count))
