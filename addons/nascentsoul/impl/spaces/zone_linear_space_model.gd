@tool
class_name ZoneLinearSpaceModel extends ZoneSpaceModel

func resolve_hover_target(zone: Node, runtime, items: Array[Control], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	var index = items.size()
	if zone is Zone:
		var layout_policy = (zone as Zone).get_layout_policy_resource()
		if layout_policy != null:
			index = layout_policy.get_insertion_index(items, (zone as Zone).size, local_position)
	index = clampi(index, 0, items.size())
	return ZonePlacementTarget.linear(index, global_position, local_position)

func normalize_target(_zone: Node, runtime, target: ZonePlacementTarget, _items: Array[Control]) -> ZonePlacementTarget:
	var fallback_count = runtime.get_item_count() if runtime != null else 0
	if target == null or not target.is_valid():
		return ZonePlacementTarget.linear(fallback_count)
	var slot = clampi(target.slot, 0, fallback_count)
	return ZonePlacementTarget.linear(slot, target.global_position, target.local_position)

func resolve_add_target(_zone: Node, runtime, _item: Control, hint = null) -> ZonePlacementTarget:
	if hint is ZonePlacementTarget and (hint as ZonePlacementTarget).is_linear():
		return normalize_target(_zone, runtime, hint as ZonePlacementTarget, [])
	if hint is int:
		return ZonePlacementTarget.linear(clampi(hint as int, 0, runtime.get_item_count()))
	return ZonePlacementTarget.linear(runtime.get_item_count())

func resolve_render_target(_zone: Node, _runtime, _item: Control, fallback_index: int) -> ZonePlacementTarget:
	return ZonePlacementTarget.linear(fallback_index)

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.slot if target != null and target.is_linear() else -1
