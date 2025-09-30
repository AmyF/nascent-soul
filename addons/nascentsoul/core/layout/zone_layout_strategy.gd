extends Node
class_name ZoneLayoutStrategy

func calculate_transforms(objs: Array[Control], zone: Zone) -> Array[Dictionary]:
	var transforms: Array[Dictionary] = []

	for obj in objs:
		transforms.append({
			"position": obj.position,
			"rotation": obj.rotation,
			"scale": obj.scale,
			"z_index": obj.z_index
		})

	return transforms
	

func get_drop_index_at_position(objs: Array[Control], zone: Zone, position: Vector2) -> int:
	if objs.is_empty():
		return 0
	
	var local_pos = zone.target_container.get_global_transform().affine_inverse() * position
	
	var best_index = -1
	var closest_distance = INF

	for i in range(objs.size()):
		var obj = objs[i]
		if obj == zone._dragging_obj:
			continue

		var obj_center = obj.position + obj.size * 0.5
		var distance = local_pos.distance_to(obj_center)

		if distance < closest_distance:
			closest_distance = distance
			if local_pos.x < obj_center.x:
				best_index = i
			else:
				best_index = i + 1

	if best_index == -1:
		var first_obj_x = objs[0].position.x + objs[0].size.x * 0.5
		var last_obj_x = objs[objs.size() - 1].position.x + objs[objs.size() - 1].size.x * 0.5

		if local_pos.x < first_obj_x:
			return 0
		elif local_pos.x > last_obj_x:
			return objs.size()
	
	return clamp(best_index, 0, objs.size())
