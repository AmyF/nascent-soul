@tool
class_name ZoneSpaceModel extends Resource

func resolve_hover_target(_zone: Node, _runtime, _items: Array[Control], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	return ZonePlacementTarget.invalid().with_positions(global_position, local_position)

func normalize_target(_zone: Node, _runtime, target: ZonePlacementTarget, _items: Array[Control]) -> ZonePlacementTarget:
	if target == null:
		return ZonePlacementTarget.invalid()
	return target.duplicate_target()

func resolve_add_target(zone: Node, runtime, _item: Control, _hint = null) -> ZonePlacementTarget:
	var index = runtime.get_item_count() if runtime != null else 0
	return ZonePlacementTarget.linear(index, zone.global_position if zone is Control else Vector2.ZERO, Vector2.ZERO)

func resolve_render_target(_zone: Node, _runtime, item: Control, fallback_index: int) -> ZonePlacementTarget:
	return ZonePlacementTarget.linear(fallback_index, item.global_position if is_instance_valid(item) else Vector2.ZERO, item.position if is_instance_valid(item) else Vector2.ZERO)

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.slot if target != null and target.is_linear() else -1

func resolve_item_position(_zone: Node, _runtime, _target: ZonePlacementTarget, _container_size: Vector2, _item_size: Vector2) -> Vector2:
	return Vector2.ZERO

func resolve_target_size(_zone: Node, _runtime, _target: ZonePlacementTarget) -> Vector2:
	return Vector2.ZERO

func resolve_target_anchor(zone: Node, _runtime, target: ZonePlacementTarget) -> Vector2:
	if zone is Control:
		return (zone as Control).global_position + (zone as Control).size * 0.5
	if target != null:
		return target.global_position
	return Vector2.ZERO

func is_target_valid(_zone: Node, _runtime, target: ZonePlacementTarget) -> bool:
	return target != null and target.is_valid()

func targets_match(a: ZonePlacementTarget, b: ZonePlacementTarget) -> bool:
	if a == null or b == null:
		return false
	return a.matches(b)

func get_first_open_target(zone: Node, runtime, item: Control) -> ZonePlacementTarget:
	return resolve_add_target(zone, runtime, item)
