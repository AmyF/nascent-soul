@tool
class_name ZoneSpaceModel extends Resource

func resolve_hover_target(_context: ZoneContext, _items: Array[ZoneItemControl], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	return ZonePlacementTarget.invalid().with_positions(global_position, local_position)

func normalize_target(_context: ZoneContext, target: ZonePlacementTarget, _items: Array[ZoneItemControl]) -> ZonePlacementTarget:
	if target == null:
		return ZonePlacementTarget.invalid()
	return target.duplicate_target()

func resolve_add_target(context: ZoneContext, _item: ZoneItemControl, _hint = null) -> ZonePlacementTarget:
	var zone = context.zone if context != null else null
	var index = context.get_item_count() if context != null else 0
	return ZonePlacementTarget.linear(index, zone.global_position if zone is Control else Vector2.ZERO, Vector2.ZERO)

func resolve_render_target(_context: ZoneContext, item: ZoneItemControl, fallback_index: int) -> ZonePlacementTarget:
	return ZonePlacementTarget.linear(fallback_index, item.global_position if is_instance_valid(item) else Vector2.ZERO, item.position if is_instance_valid(item) else Vector2.ZERO)

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.get_linear_index() if target != null else -1

func resolve_item_position(_context: ZoneContext, _target: ZonePlacementTarget, _container_size: Vector2, _item_size: Vector2) -> Vector2:
	return Vector2.ZERO

func resolve_target_size(_context: ZoneContext, _target: ZonePlacementTarget) -> Vector2:
	return Vector2.ZERO

func resolve_target_anchor(context: ZoneContext, target: ZonePlacementTarget) -> Vector2:
	var zone = context.zone if context != null else null
	if zone is Control:
		return (zone as Control).global_position + (zone as Control).size * 0.5
	if target != null:
		return target.global_position
	return Vector2.ZERO

func is_target_valid(_context: ZoneContext, target: ZonePlacementTarget) -> bool:
	return target != null and target.is_valid()

func targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	if a == null or b == null:
		return false
	return a.matches(b)

func get_first_open_target(context: ZoneContext, item: ZoneItemControl) -> ZonePlacementTarget:
	return resolve_add_target(context, item)
