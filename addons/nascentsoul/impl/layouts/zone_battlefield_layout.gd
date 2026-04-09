@tool
class_name ZoneBattlefieldLayout extends ZoneLayoutPolicy

func calculate(context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var placements: Array[ZonePlacement] = []
	var render_items: Array = []
	for item in items:
		render_items.append(item)
	var ghost_target = ghost_hint as ZonePlacementTarget if ghost_hint is ZonePlacementTarget else null
	if is_instance_valid(ghost_item) and ghost_target != null and ghost_target.is_valid():
		render_items.append(ghost_item)
	for index in range(render_items.size()):
		var item = render_items[index]
		var target: ZonePlacementTarget = null
		if item == ghost_item:
			target = ghost_target
		elif context != null and item is ZoneItemControl:
			target = context.get_item_target(item as ZoneItemControl)
		var item_size = resolve_item_size(item)
		var position = Vector2.ZERO
		var scale = Vector2.ONE
		var z_index = index
		if context != null:
			var target_size = context.resolve_target_size(target)
			var scaled_size = item_size
			if target_size.x > 0.0 and target_size.y > 0.0 and item_size.x > 0.0 and item_size.y > 0.0:
				var uniform_scale = minf(1.0, minf(target_size.x / item_size.x, target_size.y / item_size.y))
				scale = Vector2.ONE * uniform_scale
				scaled_size = item_size * uniform_scale
			position = context.resolve_target_position(target, container_size, scaled_size)
			if target != null and target.is_valid():
				z_index = target.coordinates.y * 100 + target.coordinates.x
		placements.append(ZonePlacement.new(item, position, 0.0, scale, z_index, item == ghost_item))
	return placements
