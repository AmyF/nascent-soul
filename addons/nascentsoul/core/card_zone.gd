@tool
class_name CardZone extends Zone

func move_item_to_index(item: Control, target_zone: Zone, index: int = -1) -> bool:
	return move_item_to(item, target_zone, ZonePlacementTarget.linear(index) if index >= 0 else null)

func reorder_item_to_index(item: Control, index: int) -> bool:
	return reorder_item(item, ZonePlacementTarget.linear(index))
