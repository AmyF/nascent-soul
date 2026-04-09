@tool
class_name ZoneHexGridSpaceModel extends ZoneSpaceModel

@export var columns: int = 5
@export var rows: int = 4
@export var cell_size: Vector2 = Vector2(116, 100)
@export var cell_spacing_x: float = 10.0
@export var row_spacing: float = 10.0
@export var padding: Vector2 = Vector2(20, 20)

func resolve_hover_target(context: ZoneContext, _items: Array[ZoneItemControl], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	var resolved = _pick_closest_target(local_position)
	if resolved == null:
		return ZonePlacementTarget.invalid().with_positions(global_position, local_position)
	resolved.global_position = global_position
	resolved.local_position = local_position
	return normalize_target(context, resolved, [])

func normalize_target(_context: ZoneContext, target: ZonePlacementTarget, _items: Array[ZoneItemControl]) -> ZonePlacementTarget:
	if target == null:
		return ZonePlacementTarget.invalid()
	var coordinates = target.coordinates
	if coordinates.x < 0 or coordinates.y < 0 or coordinates.x >= columns or coordinates.y >= rows:
		return ZonePlacementTarget.invalid().with_positions(target.global_position, target.local_position)
	return ZonePlacementTarget.hex(coordinates.x, coordinates.y, _make_cell_id(coordinates.x, coordinates.y), target.global_position, target.local_position, target.metadata)

func resolve_add_target(context: ZoneContext, item: ZoneItemControl, hint = null) -> ZonePlacementTarget:
	if hint is ZonePlacementTarget:
		var normalized = normalize_target(context, hint as ZonePlacementTarget, [])
		if normalized.is_valid():
			return normalized
	return get_first_open_target(context, item)

func resolve_render_target(_context: ZoneContext, _item: ZoneItemControl, _fallback_index: int) -> ZonePlacementTarget:
	return ZonePlacementTarget.invalid()

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.duplicate_target() if target != null else ZonePlacementTarget.invalid()

func resolve_item_position(_context: ZoneContext, target: ZonePlacementTarget, _container_size: Vector2, item_size: Vector2) -> Vector2:
	if target == null or not target.is_valid():
		return Vector2.ZERO
	var cell_origin = _cell_origin(target.coordinates.x, target.coordinates.y)
	return cell_origin + (cell_size - item_size) * 0.5

func resolve_target_size(_context: ZoneContext, _target: ZonePlacementTarget) -> Vector2:
	return cell_size

func resolve_target_anchor(context: ZoneContext, target: ZonePlacementTarget) -> Vector2:
	if target == null or not target.is_valid():
		return Vector2.ZERO
	var zone = context.zone if context != null else null
	var global_offset = zone.global_position if zone is Control else Vector2.ZERO
	return global_offset + _cell_origin(target.coordinates.x, target.coordinates.y) + cell_size * 0.5

func is_target_valid(context: ZoneContext, target: ZonePlacementTarget) -> bool:
	return normalize_target(context, target, []).is_valid()

func get_first_open_target(context: ZoneContext, _item: ZoneItemControl) -> ZonePlacementTarget:
	for row in range(rows):
		for column in range(columns):
			var target = ZonePlacementTarget.hex(column, row, _make_cell_id(column, row))
			if context == null or context.get_items_at_target(target).is_empty():
				return target
	return ZonePlacementTarget.invalid()

func _pick_closest_target(local_position: Vector2) -> ZonePlacementTarget:
	var best_target: ZonePlacementTarget = null
	var best_distance := INF
	for row in range(rows):
		for column in range(columns):
			var center = _cell_origin(column, row) + cell_size * 0.5
			var distance = center.distance_squared_to(local_position)
			if distance < best_distance:
				best_distance = distance
				best_target = ZonePlacementTarget.hex(column, row, _make_cell_id(column, row))
	return best_target

func _cell_origin(column: int, row: int) -> Vector2:
	var offset_x = (cell_size.x * 0.5) if row % 2 == 1 else 0.0
	return Vector2(
		padding.x + column * (cell_size.x + cell_spacing_x) + offset_x,
		padding.y + row * (cell_size.y * 0.75 + row_spacing)
	)

func _make_cell_id(column: int, row: int) -> StringName:
	return StringName("hex_%d_%d" % [column, row])
