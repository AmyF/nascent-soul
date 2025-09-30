extends ZoneLayoutStrategy
class_name HandCardZoneLayoutStrategy

@export var card_size: Vector2 = Vector2(100, 150)
@export var hover_offset: Vector2 = Vector2(0, -20)
@export var _selected_offset: Vector2 = Vector2(0, -20)

func calculate_transforms(cards: Array[Control], zone: Zone) -> Array[Dictionary]:
	var transforms: Array[Dictionary] = []

	if cards.is_empty():
		return transforms

	var card_count = cards.size()
	var card_all_width = card_size.x * card_count
	var hand_width = zone.target_container.size.x
	var width_diff = max(0, card_all_width - hand_width)
	var offset_per_card = 0 if card_count == 1 else width_diff / (card_count - 1)
	
	for i in range(card_count):
		var card = cards[i]
		var scale = card_size / card.size
		var offset_x = card_size.x * i - offset_per_card * i

		var offset_y = 0
		if zone.get_hovered_obj() == card:
			offset_y = hover_offset.y

		if card in zone.get_selected_objs():
			offset_y = _selected_offset.y

		transforms.append({
			"position": Vector2(offset_x, offset_y),
			"rotation": 0,
			"scale": scale,
			"z_index": i,
		})

	
	return transforms
