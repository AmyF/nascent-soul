@tool
class_name ZoneLayoutPolicy extends Resource

## Returns placements for items, plus an optional ghost_item hinted by ghost_hint, in zone-local coordinates.
func calculate(context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	return []

## Returns the linear insertion index to preview for mouse_pos within the current container.
func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int:
	return items.size()

## Returns the size layouts should use for item, falling back to actual or minimum size when unset.
func resolve_item_size(item: Control) -> Vector2:
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)
