@tool
class_name ZoneLinearSpaceModel extends ZoneSpaceModel

func resolve_hover_target(context: ZoneContext, items: Array[ZoneItemControl], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	var zone = context.zone if context != null else null
	var index = items.size()
	if zone is Zone:
		var layout_policy = context.get_layout_policy()
		if layout_policy != null:
			index = layout_policy.get_insertion_index(items, (zone as Zone).size, local_position)
	index = clampi(index, 0, items.size())
	return ZonePlacementTarget.linear(index, global_position, local_position)

func normalize_target(context: ZoneContext, target: ZonePlacementTarget, _items: Array[ZoneItemControl]) -> ZonePlacementTarget:
	var fallback_count = context.get_item_count() if context != null else 0
	if target == null or not target.is_valid():
		return ZonePlacementTarget.linear(fallback_count)
	var slot = clampi(target.linear_index, 0, fallback_count)
	return ZonePlacementTarget.linear(slot, target.global_position, target.local_position)

func resolve_add_target(context: ZoneContext, _item: ZoneItemControl, hint = null) -> ZonePlacementTarget:
	if hint is ZonePlacementTarget and (hint as ZonePlacementTarget).is_linear():
		var empty_items: Array[ZoneItemControl] = []
		return normalize_target(context, hint as ZonePlacementTarget, empty_items)
	if hint is int:
		return ZonePlacementTarget.linear(clampi(hint as int, 0, context.get_item_count()))
	return ZonePlacementTarget.linear(context.get_item_count())

func resolve_render_target(_context: ZoneContext, _item: ZoneItemControl, fallback_index: int) -> ZonePlacementTarget:
	return ZonePlacementTarget.linear(fallback_index)

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.get_linear_index() if target != null else -1

func resolve_target_anchor(context: ZoneContext, target: ZonePlacementTarget) -> Vector2:
	if context == null or context.zone is not Zone:
		return super.resolve_target_anchor(context, target)
	var resolved_zone := context.zone as Zone
	var items = context.get_items()
	if items.is_empty():
		return resolved_zone.global_position + resolved_zone.size * 0.5
	var layout_policy = context.get_layout_policy()
	if layout_policy == null:
		return resolved_zone.global_position + resolved_zone.size * 0.5
	var placements = layout_policy.calculate(context, items, resolved_zone.size, null, null)
	if placements.is_empty():
		return resolved_zone.global_position + resolved_zone.size * 0.5
	var slot = target.get_linear_index(items.size()) if target != null else items.size()
	if slot <= 0:
		var first_item = placements[0].item
		var first_size = layout_policy.resolve_item_size(first_item)
		return resolved_zone.global_position + placements[0].position + first_size * 0.5
	if slot >= placements.size():
		var last_placement = placements[placements.size() - 1]
		var last_size = layout_policy.resolve_item_size(last_placement.item)
		return resolved_zone.global_position + last_placement.position + last_size * 0.5
	var previous = placements[slot - 1]
	var next = placements[slot]
	var previous_size = layout_policy.resolve_item_size(previous.item)
	var next_size = layout_policy.resolve_item_size(next.item)
	var previous_center = previous.position + previous_size * 0.5
	var next_center = next.position + next_size * 0.5
	return resolved_zone.global_position + previous_center.lerp(next_center, 0.5)
