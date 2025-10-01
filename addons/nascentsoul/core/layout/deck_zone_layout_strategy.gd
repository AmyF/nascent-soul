extends ZoneLayoutStrategy
class_name DeckZoneLayoutStrategy

@export var card_spacing: float = 2.0
@export var stack_offset: Vector2 = Vector2(1, -1)
@export var max_visible_cards: int = 3

func calculate_transforms(objs: Array[Control], zone: Zone) -> Array[Dictionary]:
	var transforms: Array[Dictionary] = []
	
	if objs.is_empty():
		return transforms
	
	var container_size = zone.target_container.size
	var base_position = Vector2(container_size.x * 0.5, container_size.y * 0.5)
	
	for i in range(objs.size()):
		var obj = objs[i]
		var card_index = objs.size() - 1 - i  # 最新的卡在顶部
		
		# 只显示顶部几张卡
		var visible_offset = min(card_index, max_visible_cards - 1)
		
		var position = base_position + stack_offset * visible_offset
		position.x -= obj.size.x * 0.5
		position.y -= obj.size.y * 0.5
		
		transforms.append({
			"position": position,
			"rotation": 0.0,
			"scale": Vector2.ONE,
			"z_index": card_index
		})
	
	return transforms

func get_drop_index_at_position(objs: Array[Control], zone: Zone, position: Vector2) -> int:
	# 卡组通常只允许放在顶部
	return objs.size()
