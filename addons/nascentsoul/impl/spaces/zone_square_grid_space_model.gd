@tool
class_name ZoneSquareGridSpaceModel extends ZoneSpaceModel

@export var columns: int = 6
@export var rows: int = 4
@export var cell_size: Vector2 = Vector2(120, 120)
@export var cell_spacing: Vector2 = Vector2(16, 16)
@export var padding: Vector2 = Vector2(16, 16)

func resolve_hover_target(_zone: Node, runtime, _items: Array[Control], global_position: Vector2, local_position: Vector2) -> ZonePlacementTarget:
	var column = int(floor((local_position.x - padding.x) / (cell_size.x + cell_spacing.x)))
	var row = int(floor((local_position.y - padding.y) / (cell_size.y + cell_spacing.y)))
	var target = ZonePlacementTarget.square(column, row, _make_cell_id(column, row), global_position, local_position)
	return normalize_target(_zone, runtime, target, [])

func normalize_target(_zone: Node, runtime, target: ZonePlacementTarget, _items: Array[Control]) -> ZonePlacementTarget:
	if target == null:
		return ZonePlacementTarget.invalid()
	var coordinates = target.coordinates
	if coordinates.x < 0 or coordinates.y < 0 or coordinates.x >= columns or coordinates.y >= rows:
		return ZonePlacementTarget.invalid().with_positions(target.global_position, target.local_position)
	var normalized = ZonePlacementTarget.square(coordinates.x, coordinates.y, _make_cell_id(coordinates.x, coordinates.y), target.global_position, target.local_position, target.metadata)
	return normalized

func resolve_add_target(zone: Node, runtime, item: Control, hint = null) -> ZonePlacementTarget:
	if hint is ZonePlacementTarget:
		var normalized = normalize_target(zone, runtime, hint as ZonePlacementTarget, [])
		if normalized.is_valid():
			return normalized
	return get_first_open_target(zone, runtime, item)

func resolve_render_target(_zone: Node, runtime, item: Control, _fallback_index: int) -> ZonePlacementTarget:
	if is_instance_valid(item) and item.has_meta("zone_placement_target"):
		var existing = item.get_meta("zone_placement_target")
		if existing is ZonePlacementTarget and (existing as ZonePlacementTarget).is_valid():
			return (existing as ZonePlacementTarget).duplicate_target()
	return ZonePlacementTarget.invalid()

func resolve_layout_hint(target: ZonePlacementTarget):
	return target.duplicate_target() if target != null else ZonePlacementTarget.invalid()

func resolve_item_position(_zone: Node, _runtime, target: ZonePlacementTarget, _container_size: Vector2, item_size: Vector2) -> Vector2:
	if target == null or not target.is_valid():
		return Vector2.ZERO
	var origin = Vector2(
		padding.x + target.coordinates.x * (cell_size.x + cell_spacing.x),
		padding.y + target.coordinates.y * (cell_size.y + cell_spacing.y)
	)
	return origin + (cell_size - item_size) * 0.5

func resolve_target_size(_zone: Node, _runtime, _target: ZonePlacementTarget) -> Vector2:
	return cell_size

func resolve_target_anchor(_zone: Node, _runtime, target: ZonePlacementTarget) -> Vector2:
	if target == null or not target.is_valid():
		return Vector2.ZERO
	var global_offset = (_zone as Control).global_position if _zone is Control else Vector2.ZERO
	return global_offset + _cell_origin(target.coordinates.x, target.coordinates.y) + cell_size * 0.5

func is_target_valid(zone: Node, runtime, target: ZonePlacementTarget) -> bool:
	return normalize_target(zone, runtime, target, []).is_valid()

func get_first_open_target(zone: Node, runtime, _item: Control) -> ZonePlacementTarget:
	for row in range(rows):
		for column in range(columns):
			var target = ZonePlacementTarget.square(column, row, _make_cell_id(column, row))
			if runtime == null or runtime.get_items_at_target(target).is_empty():
				return target
	return ZonePlacementTarget.invalid()

func _make_cell_id(column: int, row: int) -> StringName:
	return StringName("sq_%d_%d" % [column, row])

func _cell_origin(column: int, row: int) -> Vector2:
	return Vector2(
		padding.x + column * (cell_size.x + cell_spacing.x),
		padding.y + row * (cell_size.y + cell_spacing.y)
	)
